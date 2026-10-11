# Generated VFX assets

Created on 2026-10-11 using the built-in image generation tool. Original game assets;
no proprietary screenshot pixels, logos or third-party textures were imported.

- `explosion-source.png`: single isolated cartoon explosion, golden yellow core,
  orange curled flame lobes, smoky perimeter, triangular sparks, frontal billboard
  view, centered transparent background, no text/scene/tank/sheet.
- `electric-source.png`: single cyan electric impact, white blue central spark,
  angular cyan forks, purple energy wisps, diamond sparks, transparent background,
  front billboard view, readable at small scale, no text/scene/sheet.

These descriptions record the final prompt set. Sources preserve generated alpha.
`tools/prepare_effects.py` deterministically creates the 512-pixel runtime textures
`explosion-v1.png` and `electric-v1.png` and validates nonempty alpha with transparent pixels.
Runtime animation uses Sprite3D billboards, scale expansion and alpha fade; generated
images are not animation sheets. Geometric particles and warning circles are original code.
