"""Keep Git runtime dependencies; exclude local historical/source asset payloads.

No assets are deleted. Scan all scene/resource/GDScript files, including test and
historical preview preloads, so a clean checkout can still import and run checks.
Offline Python art experiments may need their excluded original inputs locally.
"""
from pathlib import Path
import argparse
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
START = '# BEGIN managed local-only art payloads (tools/audit_git_assets.py)'
END = '# END managed local-only art payloads'


def audit():
    required = set()
    prefixes = set()
    for folder in ('app', 'battle', 'content', 'core', 'definitions', 'input',
                   'loadout', 'presentation', 'profile', 'session', 'tests', 'tools', 'ui'):
        for path in (ROOT / folder).rglob('*'):
            if path.suffix not in ('.gd', '.tscn', '.tres', '.gdshader'):
                continue
            text = path.read_text(errors='replace')
            if folder == 'tools':
                # Historic offline load()/output paths are local-only. Preloads must still import.
                refs = re.findall(r'preload\("res://([^"]+)"\)', text)
            else:
                refs = re.findall(r'res://([^\s"\'\)]+)', text)
            for ref in refs:
                if not ref.startswith('assets/'):
                    continue
                if '%' in ref:
                    prefixes.add(ref.split('%', 1)[0])
                elif ref.endswith('/'):
                    prefixes.add(ref)
                else:
                    required.add(ref)
    # Current reproducible source chain and source sheets stay in Git.
    prefixes.update(('assets/generated/vfx/toon-fx-v1/',
                     'assets/derived/mechanical-sample-v1/',
                     'assets/derived/mechanical-production-v1/',
                     'assets/derived/mechanical-family-v2/',
                     'assets/derived/blender-family-v1/',
                     'assets/derived/bubble-armored-v1/',
                     'assets/generated/model-reference-cards-v1/'))
    excluded, kept = [], []
    binary = {'.png', '.jpg', '.jpeg', '.webp', '.glb', '.gltf', '.zip', '.blend', '.bin'}
    for path in sorted((ROOT / 'assets').rglob('*')):
        if not path.is_file():
            continue
        name = path.relative_to(ROOT).as_posix()
        source = name[:-7] if name.endswith('.import') else name
        is_payload = Path(source).suffix.lower() in binary
        if not is_payload:
            continue
        entry = {'path': name, 'bytes': path.stat().st_size}
        if source in required or any(source.startswith(p) for p in prefixes):
            kept.append(entry)
        else:
            excluded.append(entry)
    return {'excluded_bytes': sum(x['bytes'] for x in excluded),
            'kept_asset_bytes': sum(x['bytes'] for x in kept),
            'excluded': excluded, 'kept': kept}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--write-ignore', action='store_true')
    args = parser.parse_args()
    result = audit()
    if args.write_ignore:
        path = ROOT / '.gitignore'
        original = path.read_text()
        if START in original:
            before, tail = original.split(START, 1)
            _, after = tail.split(END, 1)
            original = before.rstrip() + '\n' + after.lstrip('\n')
        block = '\n'.join('/' + x['path'] for x in result['excluded'])
        path.write_text(original.rstrip() + '\n\n' + START + '\n' + block + '\n' + END + '\n')
    output = ROOT / 'artifacts/git-assets-audit.json'
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    listed = subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=ROOT)
    files = [ROOT / p.decode() for p in listed.split(b'\0') if p]
    total = sum(p.stat().st_size for p in files if p.is_file())
    print(json.dumps({'excluded_local_payload_MiB': round(result['excluded_bytes']/2**20, 2),
                      'kept_asset_MiB': round(result['kept_asset_bytes']/2**20, 2),
                      'git_candidate_MiB': round(total/2**20, 2),
                      'excluded_file_count': len(result['excluded'])}, indent=2))


if __name__ == '__main__':
    main()
