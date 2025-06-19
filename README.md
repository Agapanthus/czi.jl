# czi

[![Build Status](https://github.com/Agapanthus/czi.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Agapanthus/czi.jl/actions/workflows/CI.yml?query=branch%3Amain)

A [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) wrapper for [libczi](https://github.com/ZEISS/libczi).

The c++ wrapper can be found in [libczi_julia.jll](https://github.com/Agapanthus/libczi_julia) and is automatically build using [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil).

To manually build the dependencies run `julia +1.7 build_tarballs.jl --debug`.
