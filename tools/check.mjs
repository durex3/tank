import { readdir, readFile, mkdir, writeFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const lock = JSON.parse(await readFile(resolve(root, 'toolchain.lock'), 'utf8'));
const executable = process.env.GODOT_BIN || resolve(root, lock.local_executable);
const hostData = resolve(root, "artifacts/host-data");
await mkdir(hostData, { recursive: true });
await writeFile(resolve(root, "artifacts/.gdignore"), "");
const childEnv = { ...process.env, APPDATA: hostData, LOCALAPPDATA: hostData };
const logs = [];
let failed = false;
function run(label, args, marker) {
  const result = spawnSync(executable, args, { cwd: root, env: childEnv, encoding: 'utf8', timeout: 60000 });
  const output = (result.stdout || '') + (result.stderr || '');
  // This restricted host cannot read Windows' CA store. Never hide other errors.
  const filtered = output.replace(/ERROR: Failed to read the root certificate store\.\r?\n\s+at: get_system_ca_certificates[^\n]*\n?/g, '');
  const ok = !result.error && result.status === 0 && !/SCRIPT ERROR:|ERROR:|Parse Error/.test(filtered) && (!marker || output.includes(marker));
  logs.push({ label, ok, exit_code: result.status, error: result.error?.message, output });
  console.log(label + ': ' + (ok ? 'PASS' : 'FAIL'));
  failed ||= !ok;
  return ok;
}
async function list(directory) {
  const entries = await readdir(resolve(root, directory), { withFileTypes: true });
  const result = [];
  for (const entry of entries) {
    const path = directory + '/' + entry.name;
    if (entry.isDirectory()) result.push(...await list(path));
    else if (entry.name.endsWith('.gd')) result.push(path);
  }
  return result;
}
const forbidden = {
  core: ['app', 'ui', 'presentation', 'input', 'battle', 'profile', 'network', 'platform'],
  definitions: ['app', 'ui', 'presentation', 'input', 'battle', 'profile', 'network', 'platform', 'loadout'],
  battle: ['app', 'session', 'ui', 'presentation', 'input', 'profile', 'network', 'platform'],
  input: ['app', 'session', 'ui', 'presentation', 'battle', 'profile', 'network'],
  loadout: ['app', 'ui', 'presentation', 'input', 'battle', 'profile', 'network', 'platform'],
};
const violations = [];
for (const [layer, banned] of Object.entries(forbidden)) {
  for (const path of await list(layer)) {
    const source = await readFile(resolve(root, path), 'utf8');
    for (const dependency of banned) {
      if (source.includes('res://' + dependency + '/')) violations.push(path + ' -> ' + dependency);
    }
    if (layer === 'battle' && /\bInput\./.test(source)) violations.push(path + ': raw device input in battle');
    if (['core', 'definitions', 'loadout'].includes(layer) && /\b(Input\.|get_tree\(|get_node\(|\$[A-Za-z])/.test(source)) violations.push(path + ': scene/device access in domain');
  }
}
logs.push({ label: 'architecture guard', ok: violations.length === 0, violations });
failed ||= violations.length !== 0;
console.log('architecture guard: ' + (violations.length ? 'FAIL ' + violations.join(', ') : 'PASS'));
run('locked Godot version', ['--version'], lock.engine_version);
if (run('script import', ['--headless', '--path', root, '--editor', '--import', '--quit'])) {
  run('domain tests', ['--headless', '--path', root, '--script', 'res://tests/domain/run_tests.gd'], 'DOMAIN TESTS: PASS');
  run('part catalog tests', ['--headless', '--path', root, '--script', 'res://tests/domain/part_catalog_tests.gd'], 'PART CATALOG TESTS: PASS');
  run('equipment profile tests', ['--headless', '--path', root, '--script', 'res://tests/domain/equipment_profile_tests.gd'], 'EQUIPMENT PROFILE TESTS: PASS');
  run('equipment growth tests', ['--headless', '--path', root, '--script', 'res://tests/domain/equipment_growth_tests.gd'], 'EQUIPMENT GROWTH TESTS: PASS');
  run('input tests', ['--headless', '--path', root, '--script', 'res://tests/input/run_tests.gd'], 'INPUT TESTS: PASS');
  run('movement tests', ['--headless', '--path', root, '--script', 'res://tests/battle/movement_tests.gd'], 'MOVEMENT TESTS: PASS');
  run('combat tests', ['--headless', '--path', root, '--script', 'res://tests/battle/combat_tests.gd'], 'COMBAT TESTS: PASS');
  run('ability tests', ['--headless', '--path', root, '--script', 'res://tests/battle/ability_tests.gd'], 'ABILITY TESTS: PASS');
  run('training lifecycle tests', ['--headless', '--path', root, '--script', 'res://tests/battle/training_lifecycle_tests.gd'], 'TRAINING LIFECYCLE TESTS: PASS');
  run('combat view tests', ['--headless', '--path', root, '--script', 'res://tests/presentation/combat_view_tests.gd'], 'COMBAT VIEW TESTS: PASS');
  run('ability vfx tests', ['--headless', '--path', root, '--script', 'res://tests/presentation/ability_vfx_tests.gd'], 'ABILITY VFX TESTS: PASS');
  run('tank parts tests', ['--headless', '--path', root, '--script', 'res://tests/presentation/tank_parts_tests.gd'], 'TANK PARTS TESTS: PASS');
  run('weapon variants tests', ['--headless', '--path', root, '--script', 'res://tests/battle/weapon_variants_tests.gd'], 'WEAPON VARIANTS TESTS: PASS');
  run('sparring tests', ['--headless', '--path', root, '--script', 'res://tests/battle/sparring_tests.gd'], 'SPARRING TESTS: PASS');
  run('match tests', ['--headless', '--path', root, '--script', 'res://tests/battle/match_tests.gd'], 'MATCH TESTS: PASS');
  run('hangar art tests', ['--headless', '--path', root, '--script', 'res://tests/presentation/hangar_art_tests.gd'], 'HANGAR ART TESTS: PASS');
  run('hangar growth tests', ['--headless', '--path', root, '--script', 'res://tests/presentation/hangar_growth_tests.gd'], 'HANGAR GROWTH TESTS: PASS');
  run('hangar directory tests', ['--headless', '--path', root, '--script', 'res://tests/presentation/hangar_directory_tests.gd'], 'HANGAR DIRECTORY TESTS: PASS');
  run('battle visual tests', ['--headless', '--path', root, '--script', 'res://tests/presentation/battle_visual_tests.gd'], 'BATTLE VISUAL TESTS: PASS');
  run('startup smoke', ['--headless', '--path', root, '--quit-after', '3']);
}
await mkdir(resolve(root, 'artifacts'), { recursive: true });
await writeFile(resolve(root, 'artifacts/check-report.json'), JSON.stringify({ date: new Date().toISOString(), passed: !failed, logs }, null, 2));
process.exitCode = failed ? 1 : 0;
