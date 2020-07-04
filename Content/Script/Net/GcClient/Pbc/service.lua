
local pbu = require "Net/GcClient/Pbc/pbunity"
local pb = require "Net/GcClient/Pbc/protobuf"



local service = {}
local loaded_table = {}
local message_table = {}

local function get_params(f)
    local n = debug.getinfo(f, 'u').nparams
    local out = {}
    for i = 1, n do
        local name = debug.getlocal(f, i)
        table.insert(out,name)
    end
    return out
end

local function gen_unpack_f(f,typename)
	local param = get_params(f) -- from getparams
	local src = {}
	for _,name in ipairs(param) do
		if name == "_all" then
			table.insert(src , "param")
		elseif name == "_addr" then
			table.insert(src , "addr")
		elseif name == "_session" then
			table.insert(src , "session")
		else
			assert(pb.check(typename , name),typename .. "." .. name)
			table.insert(src , "param."..name)
        end
	end
	local temp = "return function(param , addr , session, typename) return " .. table.concat(src,",") .. " end"
	return assert(load(temp))()
end


local function make_callback(f, service_name)
	local message = pbu.lookup(service_name)
	assert(pb.check(message.input) , message.input)
	local unpack_f = gen_unpack_f(f,message.input)


	return function (param , addr , session)
		assert(param)
		local reply = f(unpack_f(param, addr , session, service_name))
        if (reply ~= nil) then
            print("reply is NOT NIL, type service name " .. service_name)
            assert(reply == nil)
        end
	end
end

local function _load_module(service_path, shortname)
	name = shortname .. ".lua"
    -- local realpath = SERVICE_PATH .. "service/" .. name
    local realpath = service_path .."/" .. name


	local message = setmetatable({}, { __index = _ENV })
	local routine, err = loadfile(realpath,  "bt" , message)

	assert(routine, err)()

	local tmp = {}

	local function make_cbs(t, prefix)
		for k,v in pairs(t) do
			local typename = prefix .. "." .. k
			if type(v) == 'function' then
				tmp[typename] = make_callback(v, typename)
			elseif type(v) == 'table' then
				make_cbs(v, typename)
			end
		end
	end

	make_cbs(message, shortname)
	return tmp
end

function service.enable(service_path, name)
    if loaded_table[name] then
        loaded_table[name] = nil
    end

    loaded_table[name] = { enable = false , message = _load_module(service_path, name) }

	if loaded_table[name].enable then
		return
	end

	loaded_table[name].enable = true

	for k,v in pairs(loaded_table[name].message) do
		message_table[k] = v
	end
end

function service.re_enable(name)
	package.loaded["pbunity"] = nil
	package.loaded[name] = nil
    pbu = require "pbunity"
    service.enable(name)
end

function service.dispatch(type, msg, sz)
	assert(type>0)
	local message = pbu.lookup(type)
	local data = pb.decode(message.input , msg, sz)
    local routine   =   message_table[message.name]
    
    if (routine == nil) then
    	print("routine not found:", message.name, data)
        return 
    end
    if DEBUG_DUMP == 1 then
	    dump(data, "gc server message : " .. message.name .."	" .. tostring(sz)) 
	end
	routine(data, address , session) 
end

function service.invoke(message_type, parm, func)
	local message = pbu.lookup(message_type)
	if DEBUG_DUMP == 1 then
		dump(data, "gc client message : " .. message.name) 
	end
	return pb.encode(message.input, parm, func, message)
end

return service
