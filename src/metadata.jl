
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

"""
	Returns the total magnification factor of the microscope.
	Might return `missing` if the file wasn't created by ZEN Blue.
"""
function magnification(meta::CZIMetadata)
	find_parse(Float64, meta.xml, ".//HardwareSetting/ParameterCollection/TotalMagnification")
end

"""
	Returns the detector gain in volts.
	Might return `missing` if the file wasn't created by ZEN Blue.
"""
function detector_gain(meta::CZIMetadata)
	find_parse(Float64, meta.xml, ".//HardwareSetting/ParameterCollection/DetectorGain") * u"V"
end

"""
	Returns the laser power in milliwatts.
	Might return `missing` if the file wasn't created by ZEN Blue.
"""
function laser_power(meta::CZIMetadata)
	find_parse(Float64, meta.xml, ".//HardwareSetting/ParameterCollection/MaxPowerMilliWatts") * u"mW"
end

"""
	Returns the laser enable time in femtoseconds.
	Might return `missing` if the file wasn't created by ZEN Blue.
"""
function laser_time(meta::CZIMetadata)
	find_parse(Float64, meta.xml, ".//HardwareSetting/ParameterCollection/LaserEnableTime") * u"fs"
end

"""
	Returns a dictionary mapping channel IDs to names.
"""
function channel_names(meta::CZIMetadata)
	nodes = EzXML.findall(".//DisplaySetting/Channels/Channel", meta.xml)
	Dict(
		(id = n["Id"];
			name = n["Name"];
			id = startswith(id, "Channel:") ? id[9:end] : id;
			id => name) for n in nodes
	)
end

"""
	Returns a tuple of `(x, y, z)` pixel sizes in m.
"""
function pixel_size(meta::CZIMetadata)
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
