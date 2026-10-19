import { writeFile } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
// Independent stylized meshes, inspired by the user's ivory/gold tank illustrations.
const palette = { armor:[.89,.90,.83], dark:[.045,.065,.075], metal:[.26,.32,.34], gold:[.91,.60,.13], green:[.31,.92,.28] };
const v = a => 'Vector3('+a.join(', ')+')';
function scene(id) {
  const resources=[], nodes=[], cache=new Map();
  for(const [name,rgb] of Object.entries(palette)) resources.push('[sub_resource type="StandardMaterial3D" id="'+name+'"]\nalbedo_color = Color('+rgb.join(', ')+', 1)\nroughness = '+(name==='gold'?'0.32':'0.65')+'\n'+(name==='gold'?'metallic = 0.55\n':'')+(name==='green'?'emission_enabled = true\nemission = Color(0.2, 0.7, 0.1, 1)\nemission_energy_multiplier = 0.5\n':''));
  function mesh(kind, dims, material) {
    const key=JSON.stringify([kind,dims,material]);
    if(cache.has(key))return cache.get(key);
    const mid='mesh'+cache.size; cache.set(key,mid);
    let props='';
    if(kind==='BoxMesh') props='size = '+v(dims);
    if(kind==='SphereMesh') props='radius = 0.5\nheight = 1.0\nradial_segments = 16\nrings = 8';
    if(kind==='CylinderMesh') props='top_radius = '+dims[0]+'\nbottom_radius = '+dims[0]+'\nheight = '+dims[1]+'\nradial_segments = 16';
    if(kind==='CapsuleMesh') props='radius = '+dims[0]+'\nheight = '+dims[1]+'\nradial_segments = 16\nrings = 4';
    resources.push('[sub_resource type="'+kind+'" id="'+mid+'"]\nmaterial = SubResource("'+material+'")\n'+props+'\n');return mid;
  }
  function part(name,kind,dims,pos,mat='armor',rotation=[0,0,0],scale=[1,1,1]) {
    const mid=mesh(kind,dims,mat);
    nodes.push('[node name="'+name+'" type="MeshInstance3D" parent="."]\nposition = '+v(pos)+'\nrotation = '+v(rotation)+'\nscale = '+v(kind==='SphereMesh'?dims:scale)+'\nmesh = SubResource("'+mid+'")\n');
  }
  return {part, save:async(socket,pos)=>{nodes.push('[node name="'+socket+'" type="Marker3D" parent="."]\nposition = '+v(pos)+'\n');await writeFile(resolve(root,'presentation/parts/'+id+'.tscn'),'[gd_scene load_steps='+(resources.length+1)+' format=3]\n\n'+resources.join('\n')+'\n[node name="'+id+'" type="Node3D"]\n\n'+nodes.join('\n'));}};
}
for(const id of ['light_tracks','heavy_tracks','scout_wheels']) {
  const s=scene(id), heavy=id==='heavy_tracks', wheels=id==='scout_wheels';
  s.part('Hull','SphereMesh',[heavy?1.12:1,.48,1.25],[0,.40,0]);
  s.part('LowerHull','BoxMesh',[.76,.28,1.05],[0,.31,0],'metal');
  s.part('Deck','SphereMesh',[.88,.22,1.08],[0,.61,0]);
  s.part('TurretRing','CylinderMesh',[.35,.09],[0,.70,0],'metal');
  s.part('FrontGrille','BoxMesh',[.32,.18,.035],[0,.43,-.61],'dark');
  for(let j=0;j<5;j++)s.part('GrilleSlat'+j,'BoxMesh',[.02,.15,.04],[-.12+j*.06,.43,-.635],'metal');
  for(const sign of [-1,1]) {
    const side=sign===-1?'L':'R', x=sign*(heavy?.55:.50);
    s.part('Fender'+side,'SphereMesh',[heavy?.44:.34,.16,1.18],[x,.58,0]);
    s.part('LampHousing'+side,'BoxMesh',[.15,.14,.065],[sign*.32,.48,-.59],'metal');
    s.part('Lamp'+side,'SphereMesh',[.08,.08,.035],[sign*.32,.49,-.63],'green');
    s.part('TowLoop'+side,'CylinderMesh',[.035,.10],[sign*.28,.58,-.48],'gold',[Math.PI/2,0,0]);
    if(!wheels) {
      s.part('TrackBelt'+side,'CapsuleMesh',[.26,heavy?1.54:1.38],[x,.29,0],'dark',[Math.PI/2,0,0],[1,1,.95]);
      for(let i=0;i<(heavy?4:3);i++) {
        const z=(heavy?-.51:-.42)+i*(heavy?.34:.42);
        s.part('RoadWheel'+side+i,'CylinderMesh',[.19,.12],[x+sign*.18,.28,z],'gold',[0,0,Math.PI/2]);
        s.part('WheelHub'+side+i,'CylinderMesh',[.12,.13],[x+sign*.20,.28,z],'metal',[0,0,Math.PI/2]);
      }
      for(let i=0;i<9;i++)for(const end of [-1,1])s.part('Tread'+side+i+'E'+end,'BoxMesh',[.30,.035,.075],[x,.29+end*.25,-.52+i*.13],'metal');
      for(const end of [-1,1])for(let i=0;i<4;i++)s.part('NoseTread'+side+end+'N'+i,'BoxMesh',[.32,.065,.035],[x,.12+i*.11,end*(heavy?.72:.65)],'metal');
    }else for(const end of [-1,1]) {
      s.part('Tyre'+side+end,'CylinderMesh',[.29,.26],[x+sign*.06,.29,end*.43],'dark',[0,0,Math.PI/2]);
      s.part('Rim'+side+end,'CylinderMesh',[.20,.28],[x+sign*.09,.29,end*.43],'gold',[0,0,Math.PI/2]);
      s.part('Hub'+side+end,'CylinderMesh',[.12,.29],[x+sign*.10,.29,end*.43],'armor',[0,0,Math.PI/2]);
      for(let i=0;i<10;i++){const a=i*Math.PI/5;s.part('Grip'+side+end+i,'BoxMesh',[.29,.055,.11],[x+sign*.06,.29+Math.cos(a)*.275,end*.43+Math.sin(a)*.275],'metal',[a,0,0]);}
    }
  }
  if(heavy)s.part('FrontReinforcement','BoxMesh',[.72,.12,.07],[0,.33,-.65],'gold');
  s.part('RearExhaust','BoxMesh',[.42,.12,.06],[0,.40,.64],'dark');
  await s.save('TurretSocket',[0,.76,0]);
}
for(const id of ['cannon','autocannon','scatter']) {
  const s=scene(id);
  s.part('Housing','SphereMesh',[.82,.43,.78],[0,.025,.04]);
  s.part('Mantlet','CylinderMesh',[.23,.15],[0,.02,-.32],'metal',[Math.PI/2,0,0]);
  s.part('Hatch','CylinderMesh',[.18,.055],[0,.25,.10],'gold');
  s.part('HatchLid','CylinderMesh',[.15,.055],[0,.275,.10],'armor');
  s.part('OpticBase','SphereMesh',[.17,.17,.20],[.27,.18,-.08],'gold');
  s.part('Optic','SphereMesh',[.10,.10,.08],[.27,.18,-.18],'green');
  for(const sign of [-1,1])for(let j=0;j<3;j++)s.part('SideVent'+sign+j,'BoxMesh',[.025,.06,.12],[sign*.39,-.02,.16-j*.13],'metal');
  const barrels=id==='cannon'?[0]:[-.17,.17];
  for(let i=0;i<barrels.length;i++) {
    const x=barrels[i], radius=id==='cannon'?.115:id==='scatter'?.13:.065;
    s.part('Barrel'+i,'CylinderMesh',[radius,.63],[x,.02,-.63],'metal',[Math.PI/2,0,0]);
    s.part('BarrelSleeve'+i,'CylinderMesh',[radius*1.3,.24],[x,.02,-.44],'armor',[Math.PI/2,0,0]);
    s.part('MuzzleRing'+i,'CylinderMesh',[radius*1.4,.13],[x,.02,-.96],'gold',[Math.PI/2,0,0]);
    s.part('Bore'+i,'CylinderMesh',[radius*.87,.006],[x,.02,-1.028],'dark',[Math.PI/2,0,0]);
  }
  if(id==='autocannon')for(let j=0;j<5;j++)s.part('Ammo'+j,'CylinderMesh',[.025,.14],[-.42,.10,.25-j*.10],'gold',[0,0,Math.PI/2]);
  await s.save('Muzzle',[0,.02,-1.05]);
}
console.log('Generated six modular ivory/gold 3D scenes; sockets unchanged.');
