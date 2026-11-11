# Ground v1: image-generation record

Tool: built-in `image_gen.imagegen`. Model and random seed are not exposed.

Native outputs are preserved unchanged. Heights: nearest samples to 32×32, matching opposite-edge pairs averaged (no repainting), quantized to eight gray levels, enlarged with nearest to a 1024 master and BOX averaged to 128. Reference sheets: nearest samples to 64×64, nearest enlargement to a 1024 master and BOX average to 512; references never enter runtime assets.

Each height is accepted only with matching opposite edges and Pearson correlation ≥0.55 against periodic 3×3-blurred sRGB albedo luminance at 128×128. Rejected candidates remain source artifacts; runtime computes its luminance fallback. Solid textures always use their own luminance fallback.

## height: grass

Native SHA-256: `945e8db87eb6af811dac4988f35581fd711d20b37958fb70bb267e4071367175`; master SHA-256: `f8e1851aeb3efc8d5c34e0c9e81d7c4cadbdb5698ed02a8f3ba557a934756db6`.

```text
Use case: texture-edit. Convert the attached top-down pixel-art ground texture into a grayscale height map of the same surface, pixel for pixel in the same place. Raised parts are bright (stones, grass clumps, pebbles), recessed parts are dark (mortar gaps, bare earth between tufts, cracks). Keep the same 32×32 chunky pixel grid and hard pixel edges, at most 8 gray levels, no shading, no shadows, no new shapes, no outline, no border, seamless tileable on all four edges. Output exactly one 1024×1024 image. Input is the grass albedo; preserve every clump's position exactly.
```

Correlation 0.850634; opposite edges match: True; accepted: True.

## height: dirt_path

Native SHA-256: `5b7bf34abaf4f096927f21148aaff78f39933e524f7eac0b3c847f216197a1ca`; master SHA-256: `c09269da334ed32cbc1e08642f11ecd23e60c881b93ba26539268b9a7d214ba3`.

```text
Use case: texture-edit. Convert the attached top-down pixel-art ground texture into a grayscale height map of the same surface, pixel for pixel in the same place. Raised parts are bright (stones, grass clumps, pebbles), recessed parts are dark (mortar gaps, bare earth between tufts, cracks). Keep the same 32×32 chunky pixel grid and hard pixel edges, at most 8 gray levels, no shading, no shadows, no new shapes, no outline, no border, seamless tileable on all four edges. Output exactly one 1024×1024 image. Input is the dirt_path albedo; preserve every shape's position exactly.
```

Correlation 0.823434; opposite edges match: True; accepted: True.

## height: cobble

Native SHA-256: `a7e4305a8a67697160c89e9126c0849c010a9fd93f2366aa3d004bc52f0be645`; master SHA-256: `ede2fc09f5143c4188150e4d38c2778d978e1c785e3268a7db849180da2136b3`.

```text
Use case: texture-edit. Convert the attached top-down pixel-art ground texture into a grayscale height map of the same surface, pixel for pixel in the same place. Raised parts are bright (stones, grass clumps, pebbles), recessed parts are dark (mortar gaps, bare earth between tufts, cracks). Keep the same 32×32 chunky pixel grid and hard pixel edges, at most 8 gray levels, no shading, no shadows, no new shapes, no outline, no border, seamless tileable on all four edges. Output exactly one 1024×1024 image. Input is the cobble albedo; preserve every shape's position exactly.
```

Correlation 0.887592; opposite edges match: True; accepted: True.

## height: soil

Native SHA-256: `815ae9f2c74c66ce671b085e47fadcdac1d65e1ff59d15ee36fdcbd522f5744d`; master SHA-256: `a3faa2786a80f828d43416fad17e1fbe7e2a8bb1c4d49492f17a6322ef903560`.

```text
Use case: texture-edit. Convert the attached top-down pixel-art ground texture into a grayscale height map of the same surface, pixel for pixel in the same place. Raised parts are bright (stones, grass clumps, pebbles), recessed parts are dark (mortar gaps, bare earth between tufts, cracks). Keep the same 32×32 chunky pixel grid and hard pixel edges, at most 8 gray levels, no shading, no shadows, no new shapes, no outline, no border, seamless tileable on all four edges. Output exactly one 1024×1024 image. Input is the soil albedo; preserve every shape's position exactly.
```

Correlation 0.870265; opposite edges match: True; accepted: True.

## height: pebbles

Native SHA-256: `f43969bce49f2af0d2b297d83cd5886b07dc72dcb749848ee2d9e8f6cb6daeef`; master SHA-256: `17e4ee2ee736a216b4c5884caeaef9255f4d7024ecdb2e10acebec2a9ec25786`.

```text
Use case: texture-edit. Convert the attached top-down pixel-art ground texture into a grayscale height map of the same surface, pixel for pixel in the same place. Raised parts are bright (stones, grass clumps, pebbles), recessed parts are dark (mortar gaps, bare earth between tufts, cracks). Keep the same 32×32 chunky pixel grid and hard pixel edges, at most 8 gray levels, no shading, no shadows, no new shapes, no outline, no border, seamless tileable on all four edges. Output exactly one 1024×1024 image. Input is the pebbles albedo; preserve every shape's position exactly.
```

Correlation 0.868678; opposite edges match: True; accepted: True.

## height: rock

Native SHA-256: `1002b1ae461763566819bbc2a8bedd8d4e5d48285369965914389959dcabe799`; master SHA-256: `9e602801ee3272bf33f422d43f82e8eb8f87315e42e699b687fe2a62ce274150`.

```text
Use case: texture-edit. Convert the attached top-down pixel-art ground texture into a grayscale height map of the same surface, pixel for pixel in the same place. Raised parts are bright (stones, grass clumps, pebbles), recessed parts are dark (mortar gaps, bare earth between tufts, cracks). Keep the same 32×32 chunky pixel grid and hard pixel edges, at most 8 gray levels, no shading, no shadows, no new shapes, no outline, no border, seamless tileable on all four edges. Output exactly one 1024×1024 image. Input is the rock albedo; preserve every shape's position exactly.
```

Correlation 0.877795; opposite edges match: True; accepted: True.

## ref: grass-dirt_path

Native SHA-256: `ce633be61fe2f0511703f9d64c4a1957f9a2dc9538ee930999cf6e92da3835a0`; master SHA-256: `0a3c131eea61f550f42d617da12235518cd5e6897a93adc8858daa8ade57e6b4`.

```text
Use case: stylized-concept. A top-down, hand-painted chunky pixel-art ground patch where grass meets dirt_path along a wandering, ragged, natural border: grass on one side, dirt_path on the other, a few pixels of each poking into the other, no straight lines, no soft gradient, crisp hard pixels on a 32×32 grid per tile, same warm saturated palette as the attached textures. Input image 1 is grass; input image 2 is dirt_path, both palette and surface references. No shadows, no perspective, no border, no text, no flowers, no props. Exactly one 512×512 image.
```

## ref: grass-cobble

Native SHA-256: `1d5b49b0bccf67e9e43deffe0eaa5315e06bcf63fb49ca17f2095669743dcda2`; master SHA-256: `fbbe65918ecce24c2bda42fc3899f6a6a16ab5045e1f9fe0da3ae6b31af0ce14`.

```text
Use case: stylized-concept. A top-down, hand-painted chunky pixel-art ground patch where grass meets cobble along a wandering, ragged, natural border: grass on one side, cobble on the other, a few pixels of each poking into the other, no straight lines, no soft gradient, crisp hard pixels on a 32×32 grid per tile, same warm saturated palette as the attached textures. Input image 1 is grass; input image 2 is cobble, both palette and surface references. No shadows, no perspective, no border, no text, no flowers, no props. Exactly one 512×512 image.
```

## ref: dirt_path-cobble

Native SHA-256: `8845756bbf4526d7ed91fe0f61851d2492149e0e1d3c309553fc704ffdec36af`; master SHA-256: `7266ae3eb986b147994a897ff6465aa57a3750553f5d04d487bae276b906bf23`.

```text
Use case: stylized-concept. A top-down, hand-painted chunky pixel-art ground patch where dirt_path meets cobble along a wandering, ragged, natural border: dirt_path on one side, cobble on the other, a few pixels of each poking into the other, no straight lines, no soft gradient, crisp hard pixels on a 32×32 grid per tile, same warm saturated palette as the attached textures. Input image 1 is dirt_path; input image 2 is cobble, both palette and surface references. No shadows, no perspective, no border, no text, no flowers, no props. Exactly one 512×512 image.
```

## ref: grass-soil

Native SHA-256: `aa103881144937ffc7b0874e9994f156edede7a438ecd1c16b0da73575688483`; master SHA-256: `8bbf64c1434f73c18724b5eec7a93cd610e85a1246eea675208ee56d73f4a84b`.

```text
Use case: stylized-concept. A top-down, hand-painted chunky pixel-art ground patch where grass meets soil along a wandering, ragged, natural border: grass on one side, soil on the other, a few pixels of each poking into the other, no straight lines, no soft gradient, crisp hard pixels on a 32×32 grid per tile, same warm saturated palette as the attached textures. Input image 1 is grass; input image 2 is soil, both palette and surface references. No shadows, no perspective, no border, no text, no flowers, no props. Exactly one 512×512 image.
```

## ref: dirt_path-pebbles

Native SHA-256: `9b208b4aaa20a22670d0f9906596cec21fcf4a322e2e3861ba5af8182dcf1790`; master SHA-256: `35e1a356acf3acc3a7831ceaebe44e4596ecedda8113dabd99e22ed9b7b1e068`.

```text
Use case: stylized-concept. A top-down, hand-painted chunky pixel-art ground patch where dirt_path meets pebbles along a wandering, ragged, natural border: dirt_path on one side, pebbles on the other, a few pixels of each poking into the other, no straight lines, no soft gradient, crisp hard pixels on a 32×32 grid per tile, same warm saturated palette as the attached textures. Input image 1 is dirt_path; input image 2 is pebbles, both palette and surface references. No shadows, no perspective, no border, no text, no flowers, no props. Exactly one 512×512 image.
```

## ref: cobble-pebbles

Native SHA-256: `678f13d869501ecac32a7fa6dbbd1bf31b699980a7c7fdc4551b557b75c0722e`; master SHA-256: `8d9bb5aa290da53b273e41ae54fe70485c78601c821f905e7b1a2cf8fd0ecebe`.

```text
Use case: stylized-concept. A top-down, hand-painted chunky pixel-art ground patch where cobble meets pebbles along a wandering, ragged, natural border: cobble on one side, pebbles on the other, a few pixels of each poking into the other, no straight lines, no soft gradient, crisp hard pixels on a 32×32 grid per tile, same warm saturated palette as the attached textures. Input image 1 is cobble; input image 2 is pebbles, both palette and surface references. No shadows, no perspective, no border, no text, no flowers, no props. Exactly one 512×512 image.
```
