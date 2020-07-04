

local plist = require "Net/GcClient/Pbc/protolist"

local unity = {}

-- local path = "./"

local proto_list = {}

local function trim(str)
	if str == nil then
	    return nil, "the string parameter is nil"
	end
	str = string.gsub(str, " ", "")
	return str
end

local client_protocol_id = 1
local server_protocol_id = 1000

local function convert_line(line)
	local line = trim(line)
	local pos = string.find(line, "package")
	if (pos == 1) then
		return ""
	end

	if (string.find(line, "//")) then
		return ""
	end	

	line = string.gsub(line, ";", "")
	line = string.gsub(line, "enum", "")

	if (string.find(line, "b2g")) then
		line = line.." = "..client_protocol_id
		client_protocol_id = client_protocol_id + 1
	end

	if (string.find(line, "g2b")) then
		line = line.." = "..server_protocol_id
		server_protocol_id = server_protocol_id + 1
	end

	return line
end

local function readfile(path, name)
	local fullname = path .. "/" .. name
	local f = assert(io.open(fullname , "r"))

	local result_buffer = ""
	local return_val_buffer = "local ret = {}\n"
	for line in f:lines() do
		
		local is_class = false
		if (string.find(line, "enum")) then
			is_class = true
		end

		local r = convert_line(line)
		if (is_class) then
			result_buffer = result_buffer.."\n".. "local " .. r .. " = "
			return_val_buffer = return_val_buffer .."ret.".. r .." = " .. r .."\n"
		else

			if (#r > 0) then
				if (r == "{" or r == "}") then
					result_buffer = result_buffer.."\n"..r
				else
					result_buffer = result_buffer.."\n"..r..","
				end
				
			end
		end

	    
	end
	
	f:close()

	if(#return_val_buffer > 0) then
		return_val_buffer = string.sub(return_val_buffer, 1, #return_val_buffer-1)
	end
	
	return result_buffer .. return_val_buffer .. "\nreturn ret"
end

function unity.lookup(v)
	return assert(proto_list[v],v)
end

function unity.parser(path, filename)
	local readbuffer = readfile(path, filename)
	local func = assert(load(readbuffer))
	local result = func()
	assert(result)

	local root = {}
	for name, class in pairs(result) do
		local tclass = {}
		tclass.class = name
		tclass.fields = {}
		for fieldname, val in pairs(class) do
			local tmp = {name = fieldname, number = val}
			table.insert(tclass.fields, tmp)
		end
		table.insert(root, tclass)
	end
	plist.parser(
		root,
		proto_list, 1)
end

-- parser("client_test.protolist")

return unity




