
struct CZIMetadata
	xml::EzXML.Document
end

function CZIMetadata(xml_str::String)
	CZIMetadata(EzXML.parsexml(xml_str))
end

function find_parse(::Type{String}, xml::EzXML.Document, path::String)
	node = EzXML.findfirst(path, xml)
	isnothing(node) ? missing : node.content
end

function find_parse(::Type{T}, xml::EzXML.Document, path::String) where T
	node = EzXML.findfirst(path, xml)
	isnothing(node) ? missing : parse(T, node.content)
end

function czi_magnification(meta::CZIMetadata)
	find_parse(Float64, meta.xml, ".//HardwareSetting/ParameterCollection/TotalMagnification")
end

function czi_detector_gain(meta::CZIMetadata)
	find_parse(Float64, meta.xml, ".//HardwareSetting/ParameterCollection/DetectorGain") * u"V"
end

function czi_laser_power(meta::CZIMetadata)
	find_parse(Float64, meta.xml, ".//HardwareSetting/ParameterCollection/MaxPowerMilliWatts") * u"mW"
end

function czi_laser_time(meta::CZIMetadata)
	find_parse(Float64, meta.xml, ".//HardwareSetting/ParameterCollection/LaserEnableTime") * u"fs"
end

function czi_channel_names(meta::CZIMetadata)
	nodes = EzXML.findall(".//DisplaySetting/Channels/Channel", meta.xml)
	Dict(
		(id = n["Id"];
			name = n["Name"];
			id = startswith(id, "Channel:") ? id[9:end] : id;
			id => name) for n in nodes
	)
end

function czi_pixel_size(meta::CZIMetadata)
	x = find_parse(Float64, meta.xml, ".//Scaling/Items/Distance[@Id='X']/Value")
	y = find_parse(Float64, meta.xml, ".//Scaling/Items/Distance[@Id='Y']/Value")
	z = find_parse(Float64, meta.xml, ".//Scaling/Items/Distance[@Id='Z']/Value")
	(x, y, z)
end

function parse_nanotime(timestr::String)
	m = match(r"^(.*?\.)(\d{7})Z$", timestr)
	isnothing(m) && error("Invalid time format")
	main, frac = m.captures
	dt = DateTime(main * frac[1:3], dateformat"yyyy-mm-ddTHH:MM:SS.sss")
	nano = parse(Int, frac) * 100
	return dt, nano
end
