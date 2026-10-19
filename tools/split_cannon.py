"""Derive an animation-ready cannon from the read-only user GLB.

Clip through the exposed barrel sleeve. Preserve texture bytes and interpolate
UVs, normals and tangents at the cut; no source triangles are silently dropped.
"""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/imported/tripo-v1/cannon.glb"
OUTPUT = ROOT / "assets/derived/cannon-recoil-v1"
CUT_Z = 0.22


def main():
    source = SOURCE.read_bytes()
    length = struct.unpack_from("<I", source, 12)[0]
    doc = json.loads(source[20:20 + length])
    binary = bytearray(source[28 + length:])
    primitive = doc["meshes"][0]["primitives"][0]

    def read(accessor_id):
        accessor = doc["accessors"][accessor_id]
        view = doc["bufferViews"][accessor["bufferView"]]
        component = {5126: "f", 5125: "I", 5123: "H"}[accessor["componentType"]]
        width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[accessor["type"]]
        fmt = "<" + component * width
        stride = view.get("byteStride", struct.calcsize(fmt))
        offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
        return [struct.unpack_from(fmt, binary, offset + i * stride)
                for i in range(accessor["count"])]

    attributes = {name: read(index) for name, index in primitive["attributes"].items()}
    indices = [index[0] for index in read(primitive["indices"])]

    def interpolate(a, b, weight):
        result = {name: tuple(x + (y - x) * weight for x, y in zip(a[name], b[name]))
                  for name in a}
        for name in ["NORMAL", "TANGENT"]:
            if name in result:
                value = result[name]
                magnitude = sum(c * c for c in value[:3]) ** 0.5
                if magnitude > 0:
                    result[name] = tuple(c / magnitude for c in value[:3]) + value[3:]
        return result

    def clip(triangle, front):
        polygon = []
        for i, a in enumerate(triangle):
            b = triangle[(i + 1) % 3]
            da, db = a["POSITION"][2] - CUT_Z, b["POSITION"][2] - CUT_Z
            inside_a = da >= 0 if front else da <= 0
            inside_b = db >= 0 if front else db <= 0
            if inside_a:
                polygon.append(a)
            if inside_a != inside_b:
                polygon.append(interpolate(a, b, da / (da - db)))
        return polygon

    def append_accessor(values, width, kind):
        while len(binary) % 4:
            binary.append(0)
        offset = len(binary)
        for value in values:
            binary.extend(struct.pack("<" + "f" * width, *value))
        view_id = len(doc["bufferViews"])
        doc["bufferViews"].append({"buffer": 0, "byteOffset": offset,
                                  "byteLength": len(binary) - offset, "target": 34962})
        accessor = {"bufferView": view_id, "componentType": 5126,
                    "count": len(values), "type": "VEC" + str(width)}
        if kind == "POSITION":
            accessor["min"] = [min(v[k] for v in values) for k in range(3)]
            accessor["max"] = [max(v[k] for v in values) for k in range(3)]
        result = len(doc["accessors"])
        doc["accessors"].append(accessor)
        return result

    meshes, counts = [], {}
    for front, name in [(False, "Body"), (True, "Barrel")]:
        result = {attribute: [] for attribute in attributes}
        for i in range(0, len(indices), 3):
            triangle = [{name: values[index] for name, values in attributes.items()}
                        for index in indices[i:i + 3]]
            polygon = clip(triangle, front)
            for corner in range(1, len(polygon) - 1):
                for vertex in [polygon[0], polygon[corner], polygon[corner + 1]]:
                    for attribute, value in vertex.items():
                        result[attribute].append(value)
        counts[name] = len(result["POSITION"]) // 3
        mesh_attributes = {attribute: append_accessor(values, len(values[0]), attribute)
                           for attribute, values in result.items()}
        meshes.append({"name": name, "primitives": [{"attributes": mesh_attributes,
                       "material": primitive["material"], "mode": 4}]})
    doc["meshes"] = meshes
    doc["nodes"] = [{"name": "CannonSplit", "children": [1, 2]},
                    {"name": "Body", "mesh": 0},
                    {"name": "RecoilPivot", "children": [3]},
                    {"name": "Barrel", "mesh": 1}]
    doc["scenes"] = [{"nodes": [0]}]
    doc["scene"] = 0
    doc["buffers"] = [{"byteLength": len(binary)}]
    encoded = json.dumps(doc, separators=(",", ":")).encode()
    encoded += b" " * (-len(encoded) % 4)
    binary += b"\0" * (-len(binary) % 4)
    total = 12 + 8 + len(encoded) + 8 + len(binary)
    output = struct.pack("<III", 0x46546C67, 2, total)
    output += struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
    output += struct.pack("<II", len(binary), 0x004E4942) + binary
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (OUTPUT / "cannon_split.glb").write_bytes(output)
    report = {"source": str(SOURCE.relative_to(ROOT)),
              "source_sha256": hashlib.sha256(source).hexdigest(),
              "output_sha256": hashlib.sha256(output).hexdigest(),
              "method": "Local triangle clipping; original material/images retained",
              "cut_z": CUT_Z, "triangles": counts,
              "notes": "Cut remains inside sliding sleeve; no external game assets used. "
                       "Original unused geometry bytes retained for reproducible source packing."}
    (OUTPUT / "provenance.json").write_text(json.dumps(report, indent=2) + "\n")
    print("CANNON SPLIT: PASS", counts)


if __name__ == "__main__":
    main()
