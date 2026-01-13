### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ ad7087eb-6626-422f-a73e-ea835a6d4600
begin
	import Pkg
    # activate the shared project environment
    Pkg.activate(Base.current_project())
    # instantiate, i.e. make sure that all packages are downloaded
    Pkg.instantiate()
	Pkg.add(["PlutoLinks", "Images", "PlutoUI", "ImageTransformations"])
    #using LinearAlgebra, ImageAxes, Unitful, ColorSchemes, PlutoLinks
	using PlutoLinks, Images, ImageTransformations, PlutoUI, Dates, Unitful
end

# ╔═╡ c068730e-afdf-4587-bbd5-7f394e7cf1d8
# Automatically reload the CZI package under development whenever you change the implementation. When working in network drives, make sure to run your editor on the same machine as the Pluto server!
@revise using CZI

# ╔═╡ 549323dc-4d4b-4186-9b08-f093c1f7ab1a
f = CZI.open_czi("../data/small.czi")

# ╔═╡ 3ed2f42f-1217-418c-a84b-120c89df799d
CZI.dimension_ranges(f)

# ╔═╡ c0f363b6-393b-4d92-9efa-1225597a9a91
@bind z_pos PlutoUI.Slider(CZI.dimension_ranges(f)['Z'])

# ╔═╡ a248c884-208e-45b3-a41a-9269fd409256
@bind s_pos PlutoUI.Slider(CZI.dimension_ranges(f)['S'], show_value=true, default=40)

# ╔═╡ 5eafa205-73a4-4372-881d-e51775e6cf7a
tile = CZI.image(f, filter(b -> b.t == 0 && b.c == 2 && b.z == z_pos && b.s == s_pos, CZI.subblocks(f))[1])

# ╔═╡ 4a549741-c592-43d9-a275-8c94312837c0
@time length(CZI.subblocks(f))

# ╔═╡ 721cfda6-8104-4ecb-a2f6-fb7d3f8a5868
CZI.subblocks(f)[1]

# ╔═╡ b85cf9cd-2a94-4a3a-bd70-5ae01defca86
CZI.subblocks(f)[3000]

# ╔═╡ eb1fd4c4-59e5-4f08-bd14-938907943ac2
as = CZI.attachments(f)

# ╔═╡ caeddae4-4f87-4781-89a2-f6ec4c5e73d5
CZI.attachment(f, as[3]) * 10

# ╔═╡ 79f84af9-2ff9-450d-a216-c59cb587fc29
meta = CZI.metadata(f);

# ╔═╡ ad0523bd-c793-4853-85b8-4819717e119a
CZI.pixel_size(meta)

# ╔═╡ 7c6b140b-9d4b-47c9-8ff7-aea6ddbd2c5f
CZI.laser_time(meta)

# ╔═╡ b0c57420-f372-4a40-8837-8e686e900e2b
CZI.detector_gain(meta)

# ╔═╡ a1e7d2f4-b7af-4bd0-b48e-4583752ebcc5
CZI.magnification(meta)

# ╔═╡ d0b0c2a7-b4eb-4c6e-8324-3d480ef164bf
open("metadata.xml","w") do io
   println(io,CZI.metadata_str(f))
end

# ╔═╡ eb193ff1-a2d3-4ae6-a4a7-cac4f4df47c8
CZI.find_parse(Float64, meta.xml, ".//HardwareSetting/ParameterCollection/TotalMagnification")

# ╔═╡ 44f3221b-110b-448c-a6e0-57e532f3d9d3


# ╔═╡ 5c6de05f-1b83-4f07-870d-c17cf2e867c7
# ╠═╡ disabled = true
#=╠═╡
begin
	for track in CZI.EzXML.findall(".//Track[@IsActivated=\"true\"]", meta.xml) 

		@info "TRACK"
		@info "airy $(CZI.find_parse(Float64, track, ".//AiryUnits"))"
		for laser in CZI.EzXML.findall(".//TrackLaserSettings/ParameterCollection", track)
			if CZI.find_parse(Bool, laser, ".//IsEnabled")
				@info "$(laser["Id"]) @ $(CZI.find_parse(Float64, laser, ".//Intensity")*100)%"
			end				
		end	

		for channel in CZI.EzXML.findall(".//Channels/Channel", track)
			if channel["IsActivated"] == "true"
				@info "$(channel["Name"]) with dye $(CZI.find_parse(String, channel,".//Name")),  $(CZI.find_parse(Int, channel, ".//BitsPerPixel")) bits, range $(CZI.find_parse(Float64, channel, ".//DetectionRangeStart")) to $(CZI.find_parse(Float64, channel, ".//DetectionRangeEnd"))"
			end
		end
	end
end
  ╠═╡ =#

# ╔═╡ fe31eac5-d15d-43bb-887e-eee4df0056e7
CZI.channel_info(meta)

# ╔═╡ 050a2656-a1e2-4639-84b2-4f613bc061d9
CZI.acquisition_time(meta)

# ╔═╡ a97e7c31-8a17-414d-a2e1-36a25dc33724
CZI.pixel_type(meta)

# ╔═╡ 1f45e93a-ffce-4c6b-b219-4a80216c2949


# ╔═╡ ca648b41-a6ff-4350-9cc6-ef666c05eba5
[CZI.subblock_meta(f, sb) for sb in CZI.subblocks(f)[1:3]]

# ╔═╡ a0326e8e-71d4-4964-8631-815d881300c4


# ╔═╡ def40a3a-70b1-4cc9-ae40-9db07e4c8c84


# ╔═╡ 19942cdb-c5fc-4c79-b7ac-1058c45c8869


# ╔═╡ 74385288-db96-4169-975a-d901c646b0ea


# ╔═╡ ffac6ac0-12ce-481f-a4df-fb9f2ec3e73c


# ╔═╡ Cell order:
# ╠═ad7087eb-6626-422f-a73e-ea835a6d4600
# ╠═c068730e-afdf-4587-bbd5-7f394e7cf1d8
# ╠═549323dc-4d4b-4186-9b08-f093c1f7ab1a
# ╠═3ed2f42f-1217-418c-a84b-120c89df799d
# ╟─c0f363b6-393b-4d92-9efa-1225597a9a91
# ╟─a248c884-208e-45b3-a41a-9269fd409256
# ╠═5eafa205-73a4-4372-881d-e51775e6cf7a
# ╠═4a549741-c592-43d9-a275-8c94312837c0
# ╠═721cfda6-8104-4ecb-a2f6-fb7d3f8a5868
# ╠═b85cf9cd-2a94-4a3a-bd70-5ae01defca86
# ╠═eb1fd4c4-59e5-4f08-bd14-938907943ac2
# ╠═caeddae4-4f87-4781-89a2-f6ec4c5e73d5
# ╠═79f84af9-2ff9-450d-a216-c59cb587fc29
# ╠═ad0523bd-c793-4853-85b8-4819717e119a
# ╠═7c6b140b-9d4b-47c9-8ff7-aea6ddbd2c5f
# ╠═b0c57420-f372-4a40-8837-8e686e900e2b
# ╠═a1e7d2f4-b7af-4bd0-b48e-4583752ebcc5
# ╠═d0b0c2a7-b4eb-4c6e-8324-3d480ef164bf
# ╠═eb193ff1-a2d3-4ae6-a4a7-cac4f4df47c8
# ╠═44f3221b-110b-448c-a6e0-57e532f3d9d3
# ╠═5c6de05f-1b83-4f07-870d-c17cf2e867c7
# ╠═fe31eac5-d15d-43bb-887e-eee4df0056e7
# ╠═050a2656-a1e2-4639-84b2-4f613bc061d9
# ╠═a97e7c31-8a17-414d-a2e1-36a25dc33724
# ╠═1f45e93a-ffce-4c6b-b219-4a80216c2949
# ╠═ca648b41-a6ff-4350-9cc6-ef666c05eba5
# ╠═a0326e8e-71d4-4964-8631-815d881300c4
# ╠═def40a3a-70b1-4cc9-ae40-9db07e4c8c84
# ╠═19942cdb-c5fc-4c79-b7ac-1058c45c8869
# ╠═74385288-db96-4169-975a-d901c646b0ea
# ╠═ffac6ac0-12ce-481f-a4df-fb9f2ec3e73c
