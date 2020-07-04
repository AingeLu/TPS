
local protolist = {}

local function to_camel_case(name)
	local camel_case = ""
	for section in name:gmatch( "[^_]+" ) do
		camel_case = camel_case..section:sub( 1, 1 ):upper()..section:sub( 2 )
    end
    name = camel_case
    camel_case = ''
	for section in name:gmatch( "[^.]+" ) do
		camel_case = camel_case..'.'..section:sub( 1, 1 ):upper()..section:sub( 2 )
	end
	return camel_case:sub(2)
end

local function addprefix(str, prefix)
	if str:byte() == string.byte"." then
		str = str:sub(2)
	elseif prefix then
		str = 'proto.' .. prefix .. '.' .. to_camel_case(str)
	end
	return str
end

local function get_abs_name(class, name)
    return 'proto.' .. class .. '.' .. to_camel_case(name)
end

local function parser_field(field, ret, cs, prefix)
    if field.class then
        if prefix and prefix ~= '' then
            prefix = prefix .. '.' .. field.class
        else
            prefix = field.class
        end
        if field.fields then
            for _, f in pairs(field.fields) do
                parser_field(f, ret, cs, prefix)
            end
        end
    else
        field.normal_name = field.name
        if prefix and prefix ~= '' then
            field.name = prefix .. '.' .. field.name
        end
        field.class = prefix
        field.id = field.number
        assert(ret[field.name] == nil and ret[field.id] == nil, field.name)
        ret[field.name] = field
        ret[field.id] = field
    end
end

function protolist.parser(t,input,cs)
	local ret = {}
	cs = cs or 0

    assert(t)
    local root = {
        class = '',
        fields = t,
    }

    parser_field(root, ret, cs)

	for k,v in pairs(ret) do
		if type(k)=="number" then
			if v.input == nil or v.input == "" then
				v.input = get_abs_name(v.class, v.normal_name)
                if v.output == "" then
                    v.output = nil
				elseif v.output == nil then
					v.output = v.input .. ".Response"
                else
					v.output = addprefix(v.output, v.class)
				end
			else
				v.input = addprefix(v.input, v.class)
				if v.output == nil then
					v.output = v.input .. ".Response"
				elseif v.output == "" then
                    v.output = nil
                else
					v.output = addprefix(v.output, v.class)
				end
			end
		end
	end

    if input == nil then
		return ret
	else
		for k,v in pairs(ret) do
			if type(k) == "number" then
				assert(input[k]==nil , k)
			end
			input[k] = v
		end
	end
	t = nil 
    root = nil 
    collectgarbage() 
	return ret
end

return protolist
