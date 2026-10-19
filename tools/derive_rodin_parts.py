"""Package Rodin BANG meshes without changing geometry, UVs or embedded textures."""
import copy
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/imported/rodin-v1/tank_bang_pbr.glb"
OUT = ROOT / "assets/derived/rodin-v1"


def main():
    source = SOURCE.read_bytes()
    length = struct.unpack_from("<I", source, 12)[0]
    original = json.loads(source[20:20 + length])
    binary = source[28 + length:]
    assert len(original["meshes"]) == 6, "Unexpected BANG layout; inspect before packaging"
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
        else:
            doc["nodes"][1]["children"] = [2, 3, 4]
            doc["nodes"].extend({"name": label, "mesh": idx} for idx, label in
                                 zip(ids, ["Hull", "RightTracks", "LeftTracks"]))
        doc["scenes"] = [{"nodes": [0]}]
        doc["scene"] = 0
        encoded = json.dumps(doc, separators=(",", ":")).encode()
        encoded += b" " * (-len(encoded) % 4)
        output = struct.pack("<III", 0x46546C67, 2, 28 + len(encoded) + len(binary))
        output += struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
        output += struct.pack("<II", len(binary), 0x004E4942) + binary
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / (name + ".glb")).write_bytes(output)
        counts[name] = sum(original["accessors"][p["indices"]]["count"] // 3
                           for idx in ids for p in original["meshes"][idx]["primitives"])
    report = {"source": str(SOURCE.relative_to(ROOT)),
              "source_sha256": hashlib.sha256(source).hexdigest(),
              "generation_id": "a2b536e9-d910-40d5-b536-b811e0d575b4",
              "triangles": counts, "method": "Lossless node grouping, embedded texture bytes retained",
              "limitations": "Unused source buffers retained. Tracks are not separate wheels. Visual muzzle alignment requires review."}
    (OUT / "provenance.json").write_text(json.dumps(report, indent=2) + "\n")
    print("RODIN PARTS PASS", counts)


if __name__ == "__main__":
    main()
