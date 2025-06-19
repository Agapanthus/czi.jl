module czi

using ColorTypes, CxxWrap, UUIDs

module Cpp
	using CxxWrap
	const libpath = joinpath(dirname(@__DIR__), "deps", "build", "lib", "liblibczi_julia")
	@wrapmodule () -> libpath :define_julia_module
	function __init__()
		@initcxx
	end
end

const CZIFile             = Cpp.CziFile
const CompressionMode     = Cpp.CompressionMode
const SubBlockPyramidType = Cpp.SubBlockPyramidType
const PixelType           = Cpp.PixelType

export CZIFile, CZISubblockInfo, CZIAttachmentInfo, CZIHeader,
	open_czi, dimension_ranges, metadata, subblocks, subblocks_all,
	subblock_meta, bitmap, image, attachments, attachment_data,
	header, PixelType, CompressionMode, SubBlockPyramidType

"""
	CZISubblockInfo

Immutable mirror of the C++ `MySubblockInfo`.

**Fields**

| field           | meaning (see *libCZI* docs)                           |
|-----------------|-------------------------------------------------------|
| `logical_size`  | `(w,h)` in specimen pixel space                       |
| `logical_pos`   | `(x,y)` upper-left corner in specimen pixel space     |
| `physical`      | physical size `(w,h)` of the tile                     |
| `ptype`         | pixel type (`PixelType` enum)                         |
| `index`         | sub-block index inside the CZI                        |
| `file_pos`      | byte offset inside the file (`typemax(UInt64)` if N/A) |
| `compression`   | compression mode (`CompressionMode`)                 |
| `pyramid_type`  | pyramid level information (`SubBlockPyramidType`)     |
| `z,c,t,r,s,i,h,v,b,m` | dimension indices (−1 if not present)           |
"""
struct CZISubblockInfo
	logical_size :: NTuple{2, Int32}
	logical_pos  :: NTuple{2, Int32}
	physical     :: NTuple{2, Int32}
	ptype        :: PixelType
	index        :: Int32
	file_pos     :: UInt64
	compression  :: CompressionMode
	pyramid_type :: SubBlockPyramidType
	z            :: Int32;
	c            :: Int32;
	t            :: Int32;
	r            :: Int32;
	s            :: Int32
	i            :: Int32;
	h            :: Int32;
	v            :: Int32;
	b            :: Int32;
	m            :: Int32
end

@cxxdereference function _subblock_copy(sb::Cpp.SubblockInfo)::CZISubblockInfo
	(x, y, w, h) = Cpp.logical(sb)
	CZISubblockInfo(
		(w, h),
		(x, y),
		Cpp.physical(sb),
		Cpp.type(sb),
		Cpp.index(sb),
		Cpp.file_pos(sb),
		Cpp.compression(sb),
		Cpp.pyramid_type(sb),
		Cpp.z_index(sb),
		Cpp.c_index(sb),
		Cpp.t_index(sb),
		Cpp.r_index(sb),
		Cpp.s_index(sb),
		Cpp.i_index(sb),
		Cpp.h_index(sb),
		Cpp.v_index(sb),
		Cpp.b_index(sb),
		Cpp.m_index(sb),
	)
end

"""
	CZIAttachmentInfo

Mirror of C++ `MyAttachmentInfo`. Use together with [`attachment_data`](@ref).

| field              | description                                   |
|--------------------|-----------------------------------------------|
| `content_guid`     | unique identifier of the attachment content   |
| `content_file_type`| 8-char type code (e.g. `"JPG"`)              |
| `name`             | descriptive attachment name                   |
| `index`            | zero-based index used to retrieve the data    |
"""
struct CZIAttachmentInfo
	content_guid      :: UUIDs.UUID
	content_file_type :: String
	name              :: String
	index             :: Int32
end

@cxxdereference _guid_to_uuid(guid::Cpp.GUID) = UUIDs.UUID(Cpp.to_string(guid))


@cxxdereference function _attachment_info_copy(ai::Cpp.AttachmentInfo)::CZIAttachmentInfo
	CZIAttachmentInfo(
		_guid_to_uuid(Cpp.get_content_guid(ai)),
		Cpp.get_content_file_type(ai),
		Cpp.get_name(ai),
		Cpp.get_index(ai),
	)
end

"""
	CZIHeader

File header as returned by [`header`](@ref).

* `file_guid` - unique file identifier
* `major_version`, `minor_version` - *libCZI* format version numbers
"""
struct CZIHeader
	file_guid::UUIDs.UUID
	major_version::Int32
	minor_version::Int32
end

"""
	open_czi(path) -> CZIFile

Open *path* read-only and return an opaque `CZIFile` handle. Closing is
automatic via Julia's GC.
"""
open_czi(path::AbstractString) = Cpp.CziFile(String(path))

"""
	dimension_ranges(f) -> Dict{Char, UnitRange{Int}}

Inclusive ranges for each dimension present in *f* (see ZEISS convention:
<https://zeiss.github.io/libczi/pages/image_document_concept.html>).

- Z: z-focus (Plane is from a different Z-plane)
- C: Channel (Different modality)
- T: Time (Different point in time)
- R: Rotation
- S: Scene (collection of sub-blocks)
- I: Illumination (Used in SPIM for different directions of illumination)
- H: Phase (Distinguishes the different phases in a SIM-acquisition)
- V: View (Used in SPIM for different views)
- B: Block (deprecated)
- X: Width (of the bounding box of the scene in channel 0)
- Y: Height (of the bounding box of the scene in channel 0)
- M: Mosaic Index (to reference tiles (=stacks of sub-blocks) in a (mosaic-)scene)

If you want to know for sure what exists in your czi file, you'll have to iterate all sub-blocks using `subblocks`.
"""
@cxxdereference function dimension_ranges(f::CZIFile)::Dict{Char, UnitRange{Int}}
	d = Dict{Char, UnitRange{Int}}()
	for (dim, lo, hi) in Cpp.dimension_ranges(f)   # C++ gives [lo,hi)
		d[Char(dim)] = lo:(hi-1)                 # Julia uses inclusive end
	end
	d
end

"""
	metadata(f) -> String

Return the XML *ImageDocument* metadata.
"""
@cxxdereference metadata(f::CZIFile) = Cpp.metadata(f)

"""
	subblocks(f) -> Vector{CZISubblockInfo}

Level-0 (non-pyramid) sub-blocks.
"""
@cxxdereference subblocks(f::CZIFile) = [_subblock_copy(sb) for sb in Cpp.subblocks_level0(f)]

"""
	subblocks_all(f) -> Vector{CZISubblockInfo}

Enumerate **all** sub-blocks, including pyramid levels.
"""
@cxxdereference subblocks_all(f::CZIFile) = [_subblock_copy(sb) for sb in Cpp.subblocks(f)]

"""
	subblock_meta(f, idx_or_info) -> String

Per-sub-block XML metadata fragment.
"""
@cxxdereference function subblock_meta(f::CZIFile, idx::Integer)
	Cpp.meta(Cpp.subblock(f, Int32(idx)))
end
@cxxdereference subblock_meta(f::CZIFile, sb::CZISubblockInfo) = subblock_meta(f, sb.index)

"""
	bitmap(f, idx_or_info) -> Vector{UInt8}

Raw pixel buffer (interleaved, **no** colour conversion). Use
[`image`](@ref) for a decoded array.
"""
@cxxdereference function bitmap(f::CZIFile, idx::Integer)
	Cpp.bitmap(Cpp.subblock(f, Int32(idx)))
end
@cxxdereference bitmap(f::CZIFile, sb::CZISubblockInfo) = bitmap(f, sb.index)

"""
	image(f, sbinfo) -> AbstractArray

Return a colourant array for the given sub-block. Supported `PixelType`s:
`Gray8`, `Gray16`, `Gray32Float`, `Gray64Float`, `Bgr24`, `Bgr48`,
`Bgr96Float`, `Bgra32`. Returns `nothing` for unsupported formats.
"""
function image(f::CZIFile, sb::CZISubblockInfo)
	(w, h) = Int.(sb.logical_size)
	bytes  = bitmap(f, sb)

	if sb.ptype == Cpp.PixelTypeGray8
		reshape(reinterpret(Gray{ColorTypes.N0f8}, bytes), h, w)
	elseif sb.ptype == Cpp.PixelTypeGray16
		reshape(reinterpret(Gray{ColorTypes.N0f16}, bytes), h, w)
	elseif sb.ptype == Cpp.PixelTypeGray32Float
		reshape(reinterpret(Gray{Float32}, bytes), h, w)
	elseif sb.ptype == Cpp.PixelTypeGray64Float
		reshape(reinterpret(Gray{Float64}, bytes), h, w)

	elseif sb.ptype == Cpp.PixelTypeBgr24
		reshape(reinterpret(BGR{ColorTypes.N0f8}, bytes), h, w)
	elseif sb.ptype == Cpp.PixelTypeBgr48
		reshape(reinterpret(BGR{ColorTypes.N0f16}, bytes), h, w)
	elseif sb.ptype == Cpp.PixelTypeBgr96Float
		reshape(reinterpret(BGR{Float32}, bytes), h, w)

	elseif sb.ptype == Cpp.PixelTypeBgra32
		reshape(reinterpret(BGRA{ColorTypes.N0f8}, bytes), h, w)

	else
		nothing   # unsupported / exotic pixel format
	end
end

"""
	attachments(f) -> Vector{CZIAttachmentInfo}

Enumerate file-level attachments (thumbnails, custom blobs, …).
"""
@cxxdereference attachments(f::CZIFile) = [_attachment_info_copy(ai) for ai in Cpp.attachments(f)]

"""
	attachment_data(f, idx_or_info) -> Vector{UInt8}

Raw attachment payload. Inspect `content_file_type` to interpret.
"""
@cxxdereference function attachment_data(f::CZIFile, idx::Integer)
	Cpp.attachment(f, Int32(idx))
end

"""
	attachment_string(f, idx_or_info) -> String

Return attachment data as a UTF-8 string. Use with attachments that
are known to be text files (e.g. `content_file_type == "TXT"`).
"""
@cxxdereference function attachment_string(f::CZIFile, idx::Integer)
	String(reinterpret(UInt8, attachment_data(f, idx)))
end

@cxxdereference attachment_data(f::CZIFile, ai::CZIAttachmentInfo) = attachment_data(f, ai.index)

@cxxdereference attachment_string(f::CZIFile, ai::CZIAttachmentInfo) = attachment_string(f, ai.index)

"""
	header(f) -> CZIHeader

Return file header (`GUID` + format version).
"""
@cxxdereference function header(f::CZIFile)::CZIHeader
	(g, maj, min) = Cpp.header(f)
	CZIHeader(_guid_to_uuid(g), maj, min)
end

Base.show(io::IO, h::CZIHeader) = print(io, "CZI v$(h.major_version).$(h.minor_version) (", h.file_guid, ")")

end
