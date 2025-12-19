# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libczi_julia"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
	GitSource("https://github.com/Agapanthus/libczi_julia.git",
		"1cd9791c8d4bab776a6420d104663123daba37da"),
	GitSource("https://github.com/ZEISS/libczi.git",
		"474670909c741a51c71cf1a5bcace681d5aa4062"),
]

# Bash recipe for building across all platforms
# disable NEON for now, as it causes issues on aarch64 platforms
script = raw"""
cd $WORKSPACE/srcdir/libczi_julia/src
cmake . -B build \
	-DJulia_PREFIX="$prefix" \
	-DCMAKE_INSTALL_PREFIX="$prefix" \
	-DCMAKE_FIND_ROOT_PATH="$prefix" \
	-DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
	-D_UNALIGNED_ACCESS_RESULT=1 \
	-DCMAKE_CXX_STANDARD=17 \
	-DCMAKE_BUILD_TYPE=Release \
	-DENABLE_NEON=OFF \
	-D_NEON_INTRINSICS_RESULT_EXITCODE=0 \
	-D_NEON_INTRINSICS_RESULT_EXITCODE__TRYRUN_OUTPUT=""
cmake --build build --parallel ${nproc}
cmake --install build
install_license $WORKSPACE/srcdir/libczi_julia/COPYING
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# we have to use the same Julia versions as in libjulia_jll - otherwise cxxwrap cannot link against libjulia
#include("../../L/libjulia/common.jl")
include("libjulia/common.jl")

# - Remove versions below current LTS (1.10)
#filter!(x -> x >= v"1.10", julia_versions)
# TODO: only 1.12 for now
filter!(x -> x == v"1.12", julia_versions)

# platforms supported by libjulia
platforms = vcat(libjulia_platforms.(julia_versions)...)

# Disable Windows for now
#filter!(p -> os(p) in ["linux", "windows"], platforms)
filter!(p -> os(p) == "linux", platforms)

# Disable musl i686 and riscv64 builds 
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# Separate GCC 4 and GCC 5 builds based on BinaryBuilder Auditor recommendations
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
	LibraryProduct("libczi_julia", :libczi_julia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
	BuildDependency(PackageSpec(name = "libjulia_jll")),
	Dependency("libcxxwrap_julia_jll"; compat = "~0.14.7"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version = v"12.1.0")