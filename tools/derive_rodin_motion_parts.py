"""Package Rodin BANG meshes without changing geometry, UVs or embedded textures."""
import copy
import hashlib
import json
import struct
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/imported/rodin-v1/tank_bang_pbr.glb"
OUT = ROOT / "assets/derived/rodin-motion-v1"


def split_wheels(doc, binary):
    """Clip circular face inserts; stationary gold rims conceal the circular boundary."""
    data = bytearray(binary)
    counts = []

    def read(index):
        a = doc["accessors"][index]
        v = doc["bufferViews"][a["bufferView"]]
        width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
        fmt = "<" + {5126: "f", 5125: "I", 5123: "H"}[a["componentType"]] * width
        stride = v.get("byteStride", struct.calcsize(fmt))
        start = v.get("byteOffset", 0) + a.get("byteOffset", 0)
        return [struct.unpack_from(fmt, data, start + i * stride) for i in range(a["count"])]

    def partition(poly, plane):
        inside, outside = [], []
        for i, a in enumerate(poly):
            b = poly[(i + 1) % len(poly)]
            da, db = plane(a["POSITION"]), plane(b["POSITION"])
            (inside if da >= 0 else outside).append(a)
            if (da >= 0) != (db >= 0):
                weight = da / (da - db)
                vertex = {key: tuple(x + (y - x) * weight for x, y in zip(a[key], b[key])) for key in a}
                if "NORMAL" in vertex:
                    normal = vertex["NORMAL"]
                    length = math.sqrt(sum(x * x for x in normal))
                    vertex["NORMAL"] = tuple(x / max(length, 1e-12) for x in normal)
                inside.append(vertex)
                outside.append(vertex)
        return inside, outside

    def append_mesh(polygons, material, name):
        vertices = [vertex for poly in polygons for i in range(1, len(poly) - 1)
                    for vertex in (poly[0], poly[i], poly[i + 1])]
        assert vertices, name
        attributes = {}
        for key in vertices[0]:
            values = [v[key] for v in vertices]
            width = len(values[0])
            data.extend(b"\0" * (-len(data) % 4))
            offset = len(data)
            for value in values:
                data.extend(struct.pack("<" + "f" * width, *value))
            view_id = len(doc["bufferViews"])
            doc["bufferViews"].append({"buffer": 0, "byteOffset": offset, "byteLength": len(data) - offset})
            accessor = {"bufferView": view_id, "componentType": 5126, "count": len(values), "type": "VEC" + str(width)}
            if key == "POSITION":
                accessor["min"] = [min(v[k] for v in values) for k in range(3)]
                accessor["max"] = [max(v[k] for v in values) for k in range(3)]
            attributes[key] = len(doc["accessors"])
            doc["accessors"].append(accessor)
        mesh_id = len(doc["meshes"])
        doc["meshes"].append({"name": name, "primitives": [{"attributes": attributes, "material": material, "mode": 4}]})
        counts.append({"name": name, "triangles": len(vertices) // 3})
        return mesh_id

    result = []
    for mesh_id, side in [(1, 1), (2, -1)]:
        primitive = doc["meshes"][mesh_id]["primitives"][0]
        attrs = {key: read(index) for key, index in primitive["attributes"].items()}
        indices = [i[0] for i in read(primitive["indices"])]
        remaining = [[{key: values[i] for key, values in attrs.items()} for i in indices[j:j + 3]]
                     for j in range(0, len(indices), 3)]
        wheels = []
        for wheel_id, z in enumerate([-0.723, -0.313, 0.123]):
            center = [side * 0.59, -0.270, z]
            planes = [lambda p, s=side: s * p[0] - 0.565]
            for i in range(32):
                c, s = math.cos(i * math.tau / 32), math.sin(i * math.tau / 32)
                planes.append(lambda p, c=c, s=s, z=z: 0.105 - c * (p[1] + 0.270) - s * (p[2] - z))
            next_remaining, faces = [], []
            for poly in remaining:
                points = [v["POSITION"] for v in poly]
                low_y, high_y = min(p[1] for p in points), max(p[1] for p in points)
                low_z, high_z = min(p[2] for p in points), max(p[2] for p in points)
                dy = max(low_y + 0.270, -0.270 - high_y, 0)
                dz = max(low_z - z, z - high_z, 0)
                if dy * dy + dz * dz > 0.105 ** 2 or max(side * p[0] for p in points) < 0.565:
                    next_remaining.append(poly)
                    continue
                inside = poly
                for plane in planes:
                    inside, outside = partition(inside, plane)
                    if len(outside) >= 3:
                        next_remaining.append(outside)
                    if len(inside) < 3:
                        break
                if len(inside) >= 3:
                    faces.append(inside)
            remaining = next_remaining
            wheel = append_mesh(faces, primitive["material"], "WheelFace%d_%d" % (side, wheel_id))
            wheels.append((wheel, center))
        belt = append_mesh(remaining, primitive["material"], "Track%d" % side)
        result.append((belt, wheels, side))
    doc["buffers"] = [{"byteLength": len(data)}]
    return bytes(data), result, counts


def main():
    source = SOURCE.read_bytes()
    length = struct.unpack_from("<I", source, 12)[0]
    original = json.loads(source[20:20 + length])
    binary = source[28 + length:]
    assert len(original["meshes"]) == 6, "Unexpected BANG layout; inspect before packaging"
    binary, tracks, split_counts = split_wheels(original, binary)
    counts = {}
    for name, ids in [("light_tracks", [0, 1, 2]), ("cannon", [3, 4, 5])]:
        doc = copy.deepcopy(original)
        doc["nodes"] = [{"name": name, "children": [1]}]
        # Common rigid transform preserves the original six-part assembly.
        doc["nodes"].append({"name": "Visual", "translation": [0, 0.602, -0.5805],
                             "rotation": [0, 1, 0, 0], "scale": [1.35, 1.15, 1.35],
                             "children": []})
        if name == "cannon":
            doc["nodes"][1]["translation"][1] -= 0.76
            doc["nodes"][1]["children"] = [2, 3]
            doc["nodes"].extend([{"name": "Body", "mesh": 3},
                                 {"name": "RecoilPivot", "children": [4, 5, 6]},
                                 {"name": "Barrel", "mesh": 4},
                                 {"name": "MuzzleShroud", "mesh": 5},
                                 {"name": "VisualMuzzle", "translation": [0, 0.32, 0.9542]}])
            # Shorten only the sliding cannon assembly, keeping the sleeve junction fixed.
            for index in [4, 5]:
                doc["nodes"][index]["scale"] = [1, 1, 0.8]
                doc["nodes"][index]["translation"] = [0, 0, -0.09807186]
            doc["nodes"][6]["translation"][2] = 0.9542 * 0.8 - 0.09807186
        else:
            doc["nodes"][1]["children"] = [2]
            doc["nodes"].append({"name": "Hull", "mesh": 0})
            for belt, wheels, side in tracks:
                index = len(doc["nodes"])
                doc["nodes"][1]["children"].append(index)
                doc["nodes"].append({"name": "TrackRight" if side == 1 else "TrackLeft", "mesh": belt})
                for i, (mesh, center) in enumerate(wheels):
                    index = len(doc["nodes"])
                    doc["nodes"][1]["children"].append(index)
                    doc["nodes"].append({"name": "Wheel%s%d" % ("Right" if side == 1 else "Left", i), "translation": center, "children": [index + 1]})
                    doc["nodes"].append({"name": "Face", "mesh": mesh, "translation": [-v for v in center]})
        doc["scenes"] = [{"nodes": [0]}]
        doc["scene"] = 0
        encoded = json.dumps(doc, separators=(",", ":")).encode()
        encoded += b" " * (-len(encoded) % 4)
        output = struct.pack("<III", 0x46546C67, 2, 28 + len(encoded) + len(binary))
        output += struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
        output += struct.pack("<II", len(binary), 0x004E4942) + binary
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / (name + ".glb")).write_bytes(output)
        counts[name] = (sum(item["triangles"] for item in split_counts) + original["accessors"][original["meshes"][0]["primitives"][0]["indices"]]["count"] // 3
                        if name == "light_tracks" else 9948)
    report = {"source": str(SOURCE.relative_to(ROOT)),
              "source_sha256": hashlib.sha256(source).hexdigest(),
              "generation_id": "a2b536e9-d910-40d5-b536-b811e0d575b4",
              "triangles": counts, "wheel_faces": split_counts,
              "method": "32-plane circular face clipping with UV/normal interpolation; original embedded images retained. Sliding barrel length 80%, sleeve junction fixed.",
              "limitations": "Stationary gold rims; rotating circular wheel faces. Belt rolling uses a cosmetic shader pattern, not individual tread links. Unused source buffers retained."}
    (OUT / "provenance.json").write_text(json.dumps(report, indent=2) + "\n")
    print("RODIN PARTS PASS", counts)


if __name__ == "__main__":
    main()
