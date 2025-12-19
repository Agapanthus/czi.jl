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
	using PlutoLinks, Images, ImageTransformations, PlutoUI
end

# ╔═╡ c068730e-afdf-4587-bbd5-7f394e7cf1d8
# Automatically reload the CZI package under development whenever you change the implementation. When working in network drives, make sure to run your editor on the same machine as the Pluto server!
@revise using CZI

# ╔═╡ 9ed99643-2da7-4c7c-9edf-348a5b6f8057


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

# ╔═╡ b85cf9cd-2a94-4a3a-bd70-5ae01defca86
CZI.subblocks(f)[3000]

# ╔═╡ eb1fd4c4-59e5-4f08-bd14-938907943ac2
as = CZI.attachments(f)

# ╔═╡ caeddae4-4f87-4781-89a2-f6ec4c5e73d5
CZI.attachment(f, as[1]) * 10

# ╔═╡ 79f84af9-2ff9-450d-a216-c59cb587fc29
meta = CZI.metadata(f)

# ╔═╡ ad0523bd-c793-4853-85b8-4819717e119a
czi_pixel_size(meta)

# ╔═╡ 7c6b140b-9d4b-47c9-8ff7-aea6ddbd2c5f
czi_laser_time(meta)

# ╔═╡ 26abdd4a-5e00-4ab7-b25a-d8c7eb88c7ed
czi_channel_names(meta)

# ╔═╡ b0c57420-f372-4a40-8837-8e686e900e2b


# ╔═╡ a1e7d2f4-b7af-4bd0-b48e-4583752ebcc5


# ╔═╡ 05ed9913-157d-4a3a-983a-cc6ee1487e1b


# ╔═╡ d0b0c2a7-b4eb-4c6e-8324-3d480ef164bf


# ╔═╡ eb193ff1-a2d3-4ae6-a4a7-cac4f4df47c8


# ╔═╡ 44f3221b-110b-448c-a6e0-57e532f3d9d3


# ╔═╡ fe31eac5-d15d-43bb-887e-eee4df0056e7


# ╔═╡ 050a2656-a1e2-4639-84b2-4f613bc061d9


# ╔═╡ a97e7c31-8a17-414d-a2e1-36a25dc33724


# ╔═╡ 1f45e93a-ffce-4c6b-b219-4a80216c2949


# ╔═╡ ca648b41-a6ff-4350-9cc6-ef666c05eba5
[CZI.subblock_meta(f, sb) for sb in CZI.subblocks(f)[1:3]]

# ╔═╡ a0326e8e-71d4-4964-8631-815d881300c4
begin
	#local zstack = [] 
	sbs = [sb for sb in CZI.subblocks(f) 
		   if sb.m == 3 && sb.c == 0] # && sb.z in 0:4:100]
	avg = zeros(Gray{Float32}, sbs[1].logical_size)
	@progress for sb in sbs
		#local img = CZI.image(f, sb)
		avg .+= img
		push!(zstack, img)
	end
	
	#local vol1 = reshape(reduce(hcat, zstack), size(zstack[1])..., :)
	local mini, maxi = extrema(vol1)
	vol::Array{Float32, 3} = (vol1 .- mini) ./ (maxi - mini)	
	avg ./ maximum(avg) 
end

# ╔═╡ def40a3a-70b1-4cc9-ae40-9db07e4c8c84
function downsample_avg(vol::Array{Float32,3}, wx::Int, wy::Int, wz::Int)
    sx, sy, sz = size(vol)
    nx, ny, nz = div(sx, wx), div(sy, wy), div(sz, wz)
    vol2 = zeros(Float32, nx, ny, nz)

    @Threads.threads for tx in 1:nx
        x_start = (tx - 1) * wx + 1
        x_end = tx * wx
        for ty in 1:ny
            y_start = (ty - 1) * wy + 1
            y_end = ty * wy
            for tz in 1:nz
                z_start = (tz - 1) * wz + 1
                z_end = tz * wz
                s = 0.0f0
                @inbounds for x in x_start:x_end, y in y_start:y_end, z in z_start:z_end
                    s += vol[x, y, z]
                end
                vol2[tx, ty, tz] = s / (wx * wy * wz)
            end
        end
    end
    return vol2
end

# ╔═╡ 19942cdb-c5fc-4c79-b7ac-1058c45c8869
begin 
	@time vol2 = downsample_avg(vol, 4,4,2)
	size(vol2)
end

# ╔═╡ 74385288-db96-4169-975a-d901c646b0ea
begin
	local γ = 0.4  # or any γ ∈ (0, ∞), γ < 1 compresses, γ > 1 expands
	local knee = 0.05
	vol3 = max.(0.0, vol2 .- knee) .^ γ
	vol3 ./= maximum(vol3)
end;

# ╔═╡ ffac6ac0-12ce-481f-a4df-fb9f2ec3e73c
begin
	# Make a colormap, with the first value being transparent
	colormap = to_colormap(:plasma)
	colormap[1] = RGBAf(0,0,0,0)
	fig = Figure(size=(1500, 800))
	volume(fig[1,1], vol3, algorithm = :absorption, absorption=4f0, colormap=colormap, axis=(type=Axis3, title = "Absorption"))
	volume(fig[1, 2], vol3, algorithm = :mip, colormap=colormap, axis=(type=Axis3, title="Maximum Intensity Projection"))
	display(fig)
end

# ╔═╡ Cell order:
# ╠═ad7087eb-6626-422f-a73e-ea835a6d4600
# ╠═c068730e-afdf-4587-bbd5-7f394e7cf1d8
# ╠═9ed99643-2da7-4c7c-9edf-348a5b6f8057
# ╠═549323dc-4d4b-4186-9b08-f093c1f7ab1a
# ╠═3ed2f42f-1217-418c-a84b-120c89df799d
# ╟─c0f363b6-393b-4d92-9efa-1225597a9a91
# ╟─a248c884-208e-45b3-a41a-9269fd409256
# ╠═5eafa205-73a4-4372-881d-e51775e6cf7a
# ╠═4a549741-c592-43d9-a275-8c94312837c0
# ╠═b85cf9cd-2a94-4a3a-bd70-5ae01defca86
# ╠═eb1fd4c4-59e5-4f08-bd14-938907943ac2
# ╠═caeddae4-4f87-4781-89a2-f6ec4c5e73d5
# ╠═79f84af9-2ff9-450d-a216-c59cb587fc29
# ╠═ad0523bd-c793-4853-85b8-4819717e119a
# ╠═7c6b140b-9d4b-47c9-8ff7-aea6ddbd2c5f
# ╠═26abdd4a-5e00-4ab7-b25a-d8c7eb88c7ed
# ╠═b0c57420-f372-4a40-8837-8e686e900e2b
# ╠═a1e7d2f4-b7af-4bd0-b48e-4583752ebcc5
# ╠═05ed9913-157d-4a3a-983a-cc6ee1487e1b
# ╠═d0b0c2a7-b4eb-4c6e-8324-3d480ef164bf
# ╠═eb193ff1-a2d3-4ae6-a4a7-cac4f4df47c8
# ╠═44f3221b-110b-448c-a6e0-57e532f3d9d3
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
