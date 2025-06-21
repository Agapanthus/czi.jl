# czi

[![Build Status](https://github.com/Agapanthus/czi.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Agapanthus/czi.jl/actions/workflows/CI.yml?query=branch%3Amain)

A [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) wrapper for [libczi](https://github.com/ZEISS/libczi).

The c++ wrapper can be found in [libczi_julia.jll](https://github.com/Agapanthus/libczi_julia) and is automatically build using [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil).

To manually build the dependencies run `julia +1.7 build_tarballs.jl  --deploy=Agapanthus/Libczi_julia_jll.jl`.

## Getting Started

Install using `Pkg.add("CZI")`, then use it in your code:

```julia
using CZI
f = CZI.open_czi("path/to/file.czi")

# to find out how many scenes, timepoints, z-slices etc. there are:
@show CZI.dimension_ranges(f)

# Return a vector of all the subblocks in the file
blocks = CZI.subblocks(f)
@show blocks[1]

# Read subblock images in an Images.jl-compatible way:
img = CZI.image(f, findfirst(b -> b.s == 2 && b.z == 0 && b.t == 0, blocks))

# You can also read arbitrary volumes from the file by providing ranges.
# The resulting array will have just as many dimensions as you provide ranges.
# Dimension order is always (S, T, C, M, Z, X, Y).
# Mosaic scenes will be (crudely) stitched together if you don't provide M and X or Y span multiple tiles.
# Provide the optional parameter `stitch = true` to apply an accurate but slow stitching algorithm.
vol = CZI.volume(f; S = 0, T = 1:2:42, C = 0, Z = 1:10, X = 10000:11000, Y = 1:1000)

# You can parse metadata:
meta = CZI.metadata(f)
@show CZI.pixel_size(meta)
@show CZI.detector_gain(meta)
```

See `test/pluto.jl` for more detailed + runable examples in a [Pluto.jl](https://plutojl.org/) notebook.
