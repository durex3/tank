# 131 战斗特效纹理提示词（重写版 v2）

用途：替换当前"调试线框"式的地面指示，统一枪口焰、命中、车体反馈。
输出目录：`assets/generated/vfx/combat-fx-v2/`
只生成 PNG 纹理，不生成坦克、界面、文字。参考目录只读，不复制对方素材。

本轮修正上一版初稿暴露的问题：
- 轮廓出现红色/深色描边 → 明确禁止任何 outline。
- 地面图出现 3D 挤出侧面和透视 → 明确严格俯视、正视，无厚度。
- 出现四层以上色带和高光渐变 → 限定每形状最多 3 个纯色带。
- 长条图首尾被裁断无法平铺 → 明确要求 seamless，主体不触边。

---

## 0. 通用段落（每次先贴）

```
Flat 2D game VFX sprite, orthographic view, no perspective, no thickness.
CEL-SHADED FLAT COLOR ONLY: each shape uses exactly 3 solid flat color bands
(dark band, main band, hot core band). Every band is one pure color, no gradient inside it.
TRUE TRANSPARENT background (RGBA PNG). No background scene, no ground plane, no tank,
no weapon, no text, no logo, no watermark, no frame.

HARD NEGATIVES (must all be absent):
NO outline, NO border, NO dark rim, NO stroke around any shape;
NO 3D extrusion, NO side faces, NO bevel, NO depth, NO isometric view;
NO gradients, NO glow halo, NO blur, NO soft shadow, NO drop shadow;
NO more than 3 color bands per shape;
NO noise, NO speckles, NO semi-transparent fringe wider than 2 pixels.

Silhouette: hand-cut geometric shapes with intentional broken gaps and asymmetrical edges,
but the alpha edge itself must be crisp and clean. Readable at 24-50 screen pixels.
Keep the shape inside the central 70 percent of the canvas with transparent margin.

Palette (use these exact values):
warm dark #b95425, warm main #ffad32, warm hot #fff3d4
water dark #39aab9, water main #83e0e2, water hot #e9fff8
dust dark #737873, dust main #aeb3a6, dust hot #dedfcf
guard dark #2d5d9e, guard main #74baff, guard hot #eaf4ff
escape dark #2f9e74, escape main #7ef5bf, escape hot #e6fff4
storm dark #b95425, storm main #ffab51, storm hot #fff3d4
```

如果模型只能生成不透明背景，请生成纯黑背景版本，文件名后加 `-black`，由接入脚本做亮度抠底。

---

## P0 地面指示（严格俯视平铺，优先）

### 1. `ground_lane.png` — 蓄力/贯穿指示带
Canvas: 1024x256, horizontal strip. **STRICTLY TOP-DOWN**, seamless tileable left to right.
A straight projected light lane: two thin parallel rails in warm main #ffad32 with warm dark
#b95425 underside segments, short chunky chevrons pointing RIGHT repeated at even spacing,
warm hot #fff3d4 only at chevron tips. Broken segments with small gaps. Flat decal only:
no rails standing up, no side faces, no shadow.
Seamless: the pattern must continue exactly across the left and right edges.
No end caps, no arrows at the ends, no text.

### 2. `ground_sector.png` — 震地/扇形范围指示
Canvas: 1024x1024, **STRICTLY TOP-DOWN**. Wide fan ground decal opening toward the top,
apex at bottom center. Three concentric segmented arc bands: outer band warm dark #b95425,
middle warm main #ffad32, inner hot #fff3d4 only as short ticks near the apex.
Flat on the ground, no vertical faces, no glow, no fill haze. Inner area mostly transparent.
No text, no center icon.

### 3. `ground_ring.png` — 范围/烟区地面圈
Canvas: 1024x1024, **STRICTLY TOP-DOWN**. Circular ring decal made of thick uneven arc segments
with clear gaps, warm main #ffab51 body, warm dark #b95425 underside band, a few small
#fff3d4 highlight ticks. Inside the ring fully transparent. Flat decal, no thickness.
No text, no emblem.

### 4. `ground_guard_arc.png` — 正面格挡弧
Canvas: 1024x512, **STRICTLY TOP-DOWN**. A shield arc facing up, made of segmented plates:
guard main #74baff faces, guard dark #2d5d9e seams and underside, guard hot #eaf4ff
highlight edges at the ends. Visible seams between plates, small chunky end caps.
Inside the arc fully transparent. Flat decal, no bevel, no 3D thickness, no runes.

### 5. `ground_chevrons.png` — 冲锋方向箭头
Canvas: 1024x256, horizontal strip. **STRICTLY TOP-DOWN**, seamless tileable left to right.
One row of chunky chevron arrows pointing RIGHT, main #ffad32 with dark #b95425 underside
and #fff3d4 highlight strokes. Flat decal. The pattern must continue across both edges.
No text, no end caps.

### 6. `ground_chevrons_escape.png` — 逃生方向箭头
Same as #5, but escape palette: main #7ef5bf, dark #2f9e74, hot #e6fff4.
Same shape, same seamless requirement, strictly top-down.

### 7. `ground_smoke_stain.png` — 烟区地面污染
Canvas: 1024x1024, **STRICTLY TOP-DOWN**. Irregular broken circular stain of chunky torn lobes:
dust dark #737873 outer, dust main #aeb3a6 inner, dust hot #dedfcf only as small flat patches.
Several holes and cutout gaps, a few detached lobes. Center slightly emptier so units stay
readable. Flat decal, no fog, no gradient, no glow. No text.

### 8. `ground_heat_ring.png` — 红温/散热地面环
Canvas: 1024x1024, **STRICTLY TOP-DOWN**. A ring of cracked plates: dark #7a1c12 shadow band,
main #ff5533 body, thin #ffd8a0 hot seams, broken into uneven segments with dark gaps.
Flat decal, no glow halo, no thickness. No text.

---

## P1 枪口焰（朝向相机的平面 Sprite）

### 9. `muzzle_cannon.png`
1024x1024. Compact muzzle blast seen face-on: warm hot #fff3d4 center, thick warm main #ffad32
petals, warm dark #b95425 outer band. Three to five short irregular flame tongues with pointed
ends, chunky asymmetrical silhouette. Flat cel shapes, no outline, no 3D volume, no glow halo.

### 10. `muzzle_needle.png`
1024x1024. Small sharp four-point star burst: #fff3d4 core, #ffad32 mid band, short #b95425 tips.
Tight and dense, high contrast, small footprint. Flat, no outline.

### 11. `muzzle_scatter.png`
1024x1024. A wide low fan of six to eight separate chunky flame pellets leaving one point:
#ffad32 and #b95425, #fff3d4 only at the origin. Clear transparent gaps between pellets so it
reads as multiple projectiles. Flat shapes, no outline.

### 12. `muzzle_bubble.png`
1024x1024. Small bursting water ring: broken #83e0e2 ring with #39aab9 underside band,
five to seven detached droplets, #e9fff8 crisp highlights. Flat cel shapes, no glossy spheres,
no 3D bubbles, no outline.

### 13. `muzzle_storm.png`
1024x1024. Very compact rapid-fire flash: #fff3d4 core, one short #ffad32 tongue, two tiny
detached sparks. Almost no smoke. Must read at small size. Flat, no outline.

### 14. `muzzle_heavy.png`
1024x1024. Broad contained blast with a dark broken outer ring: #fff3d4 core, #ffad32 inner,
#47413c outer broken ring. Chunky layered pressure petals, short and wide, flat shapes.
No long beam, no outline, no 3D volume.

---

## P1 命中效果

### 15. `hit_cannon.png`
1024x1024. Armor impact seen face-on: white-hot #fff3d4 angular center, fan of five short thick
tapered #ffad32 shards, #b95425 underside, two tiny detached flecks. Strong directional burst,
irregular silhouette, flat cel shading. No outline, no circular blast, no glow halo.

### 16. `hit_needle.png`
1024x1024. Small dense spark: tiny #fff3d4 center, four short #ffad32 needles, #b95425 fringe.
Compact, readable at 20-30 pixels. Flat, no outline.

### 17. `hit_scatter.png`
1024x1024. Cluster of five to six separate rectangular pellet sparks with transparent gaps,
#ffad32 with #b95425 trailing edges. No central explosion, no smoke, flat, no outline.

### 18. `hit_heavy.png`
1024x1024. Heavy armor breach: large angular #fff2d6 core, thick dark metal #47413c fragments
with gray #746c5c faces, several chunky plates flying outward, two short #b85b23 streaks.
Flat cel shapes, no soft smoke ball, no circular blast, no outline.

### 19. `hit_guard.png`
1024x1024. Deflect spark on a shield: #74baff arc sliver, #eaf4ff impact point, fan of five short
white-blue sparks bouncing away, #2d5d9e underside. Flat, no text, no outline.

---

## P2 车体反馈

### 20. `hull_dust.png`
1024x1024. Ground-hugging dust kick: three to four chunky curled lobes in #737873 / #aeb3a6 /
#dedfcf, detached small puffs, clear gaps. Flat cel shapes, low height, no fog, no gradient.

### 21. `track_dust.png`
1024x1024. Elongated low dust trail with two separated lobes and small debris flecks, same dust
palette. Reads as motion, not an explosion. Flat, no outline.

---

## 生图自检（交给我之前先看一眼）

- [ ] 没有任何描边或深色外框。
- [ ] 地面图是纯俯视，看不到侧立面或厚度。
- [ ] 每条地面长图左右边缘能首尾相接。
- [ ] 每个形状只有三块纯色，没有渐变和光晕。
- [ ] 背景真透明，边缘没有细碎半透明毛刺。
- [ ] 缩到 48 像素仍能辨认轮廓。
