struct CZIMetadata
	xml::EzXML.Document
end

function CZIMetadata(xml_str::String)
	CZIMetadata(EzXML.parsexml(xml_str))
end

function find_parse(::Type{String}, xml, path::String)
	node = EzXML.findfirst(path, xml)
	isnothing(node) ? missing : strip(node.content)
end

function find_parse(::Type{DateTime}, xml, path::String)
	node = EzXML.findfirst(path, xml)
	if isnothing(node)
		missing
	else
		s = string(strip(node.content))
		if endswith(s, "Z")
			parse_nanotime(s)[1]
		else
			parse(DateTime, s)
		end
	end
end

function find_parse(::Type{T}, xml, path::String) where T
	node = EzXML.findfirst(path, xml)
	isnothing(node) ? missing : parse(T, node.content)
end

function find_attr(path::String, attr::String, node)
	found = CZI.EzXML.findfirst(path, node)
	if !isnothing(found) && haskey(found, attr)
		found[attr]
	else
		missing
	end
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

function channel_info(meta::CZIMetadata)
	Dict([
		parse(Int, chopprefix(strip(CZI.find_attr(".", "Id", ch)), "Channel:")) => Dict([
			"Id" => CZI.find_attr(".", "Id", ch),
			"Name" => CZI.find_attr(".", "Name", ch),
			"Fluor" => CZI.find_parse(String, ch, ".//Fluor"),
			"IlluminationType" => CZI.find_parse(String, ch, ".//IlluminationType"),
			"ContrastMethod" => CZI.find_parse(String, ch, ".//ContrastMethod"),
			"PinholeSize" => CZI.find_parse(Float64, ch, ".//PinholeSize") * u"μm",
			"PinholeSizeAiry" => CZI.find_parse(Float64, ch, ".//PinholeSizeAiry"),
			"TotalMagnification" => CZI.find_parse(Float64, ch, ".//MM.TotalMagnification"),
			"AcquisitionMode" => CZI.find_parse(String, ch, ".//AcquisitionMode"),
			"Detector" => Dict([
				"DetectionWavelength" => CZI.find_parse(String, ch, ".//DetectionWavelength"),
				"DigitalGain" => CZI.find_parse(Float64, ch, ".//DigitalGain"),
				"Voltage" => CZI.find_parse(Float64, ch, ".//DetectorSettings/Voltage") * u"V",
				"Offset" => CZI.find_parse(Float64, ch, ".//DetectorSettings/Offset"),
				"PhotonConversionFactor" => CZI.find_parse(Float64, ch, ".//PhotonConversionFactor"),
				"Id" => CZI.find_attr(".//Detector", "Id", ch),
			]),
			"LightSources" => [
				Dict([
					"Attenuation" => CZI.find_parse(Float64, light, ".//Attenuation"),
					"Transmission" => CZI.find_parse(Float64, light, ".//Transmission"),
					"Wavelength" => CZI.find_parse(Float64, light, ".//Wavelength") * u"nm",
					"Id" => CZI.find_attr(".//LightSource", "Id", light),
				]) for light in CZI.EzXML.findall(".//LightSourcesSettings/LightSourceSettings", ch)],
			"Averaging" => Dict([
				"Amount" => CZI.find_parse(Int64, ch, ".//Averaging"),
				"Method" => CZI.find_parse(String, ch, ".//AveragingMethod"),
			]),
			"Scan" => Dict([
				"FrameTime" => CZI.find_parse(Float64, ch, ".//FrameTime") * u"s",
				"PixelTime" => CZI.find_parse(Float64, ch, ".//PixelTime") * u"s",
				"Speed" => CZI.find_parse(Float64, ch, ".//ScanSpeed"),
				"Zoom" => (
					CZI.find_parse(Float64, ch, ".//ZoomX"),
					CZI.find_parse(Float64, ch, ".//ZoomY"),
				),
				"LineStep" => CZI.find_parse(Int64, ch, ".//LineStep"),
				"ScanningMode" => CZI.find_parse(String, ch, ".//ScanningMode"),
				"ScanDirection" => CZI.find_parse(String, ch, ".//ScanDirection"),
			]),
		])
		for ch in CZI.EzXML.findall(".//Image/Dimensions/Channels/Channel", meta.xml)])
end

#="""
	Returns a dictionary mapping channel IDs to names.
"""
function channel_names(meta::CZIMetadata)
	channels = EzXML.findall(".//DisplaySetting/Channels/Channel", meta.xml)
	Dict(
		(id = n["Id"];
			name = n["Name"];
			id = startswith(id, "Channel:") ? id[9:end] : id;
			id => name) for n in channels
	)
end=#

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
	nano = parse(Int, frac) * 100 * u"ns"
	return dt, nano
end


function acquisition_time(meta::CZIMetadata)
	CZI.find_parse(DateTime, meta.xml, ".//Image/AcquisitionDateAndTime")
end


function pixel_type(meta::CZIMetadata)
	CZI.find_parse(String, meta.xml, ".//Image/PixelType")
end