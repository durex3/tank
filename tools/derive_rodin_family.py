"""Package inspected rigid BANG parts; retain original buffers and source assets."""
import copy
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/derived/rodin-family-v2"

def read(name):
    data = (ROOT / f"assets/imported/rodin-family-v2/{name}_bang.glb").read_bytes()
    length = struct.unpack_from("<I", data, 12)[0]
    return json.loads(data[20:20 + length]), data[28 + length:]

def write(name, doc, binary):
    encoded = json.dumps(doc, separators=(",", ":")).encode()
    encoded += b" " * (-len(encoded) % 4)
    data = struct.pack("<III", 0x46546C67, 2, 28 + len(encoded) + len(binary))
    data += struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
    data += struct.pack("<II", len(binary), 0x004E4942) + binary
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{name}.glb").write_bytes(data)

def turret(name, expected, body, barrels, scale, translation, muzzle):
    original, binary = read(name)
    assert len(original["meshes"]) == expected
    doc = copy.deepcopy(original)
    nodes = [{"name": name, "children": [1]},
             {"name": "Visual", "rotation": [0,1,0,0], "scale": scale,
              "translation": translation, "children": []}]
    for i in body:
        nodes[1]["children"].append(len(nodes))
        nodes.append({"name": "Body" if i == body[0] else f"Housing{i}", "mesh": i})
    pivot = len(nodes)
    nodes[1]["children"].append(pivot)
    nodes.append({"name": "RecoilPivot", "children": []})
    for i in barrels:
        nodes[pivot]["children"].append(len(nodes))
        nodes.append({"name": f"Barrel{i}", "mesh": i})
    nodes[pivot]["children"].append(len(nodes))
    nodes.append({"name": "VisualMuzzle", "translation": muzzle})
    doc["nodes"] = nodes
    doc["scenes"] = [{"nodes": [0]}]
    doc["scene"] = 0
    write(name, doc, binary)

def scout():
    doc, binary = read("scout_wheels")
    assert len(doc["meshes"]) == 6
    scale = .95
    offset_y = .40
    nodes = [{"name": "scout_wheels", "children": [1, 4]},
             {"name": "Visual", "rotation": [0,1,0,0], "scale": [scale]*3,
              "translation": [0,offset_y,0], "children": [2,3]},
             {"name": "Hull", "mesh": 2}, {"name": "Fender", "mesh": 3},
             {"name": "RunningGearParts", "children": []}]
    for i in [0,1,4,5]:
        a = doc["accessors"][doc["meshes"][i]["primitives"][0]["attributes"]["POSITION"]]
        center = [(x+y)*.5 for x,y in zip(a["min"], a["max"])]
        world = [-center[0]*scale, center[1]*scale+offset_y, -center[2]*scale]
        idx = len(nodes)
        nodes[4]["children"].append(idx)
        side = "Right" if world[0] < 0 else "Left"
        nodes.append({"name": f"Wheel{side}{i}", "translation": world, "children": [idx+1]})
        nodes.append({"name": f"CompleteWheel{i}", "mesh": i, "rotation": [0,1,0,0],
                      "scale": [scale]*3, "translation": [center[0]*scale,-center[1]*scale,center[2]*scale]})
    doc["nodes"] = nodes
    doc["scenes"] = [{"nodes": [0]}]
    doc["scene"] = 0
    write("scout_wheels", doc, binary)

def heavy():
    doc, binary = read("heavy_tracks")
    assert len(doc["meshes"]) == 7, "Inspect BANG layout before deriving hull"
    # BANG fused several wheels into belts. Keep only verified complete hull;
    # reconstruct running gear with the already validated closed TrackRig.
    doc["nodes"] = [{"name":"heavy_tracks", "children":[1]},
                    {"name":"Visual", "rotation":[0,1,0,0], "scale":[1.6,1.1,1.2],
                     "translation":[0,.382,0], "children":[2]},
                    {"name":"Hull", "mesh":5}]
    doc["scenes"] = [{"nodes":[0]}]
    doc["scene"] = 0
    write("heavy_tracks", doc, binary)

if __name__ == "__main__":
    turret("autocannon",3,[1],[0,2],[1.05,.75,.95],[0,.32,-.05],[0,.17,.95])
    turret("scatter",5,[0,1,2,3],[4],[1,.7,1],[0,.325,-.05],[.008,.205,.95])
    turret("bubble_cannon",3,[0,1],[2],[.85,.62,.85],[0,.339,-.05],[.095,.044,.95])
    scout()
    heavy()
    print("FAMILY PART PACKAGING PASS")
