if GameCenterNetWorkMgr ~= nil then
	return GameCenterNetWorkMgr
end

local pb = require "Net/GcClient/Pbc/protobuf"
local service = require("Net/GcClient/Pbc/service")
local pbu = require "Net/GcClient/Pbc/pbunity"

local packet = NetPack


function GameCenterNetWorkMgr:OnInit()
	local path = FPaths.ProjectContentDir()
	pb.register_file(path.."Data/Proto/gcproto.pb")
	packet.init_proto(pb.get_pbenv())
	pbu.parser(path.."Data/Proto", "bs2gc.protolist")
	service.enable(path.."Script/Net/GcClient/Service", "gc2bs")
end

function GameCenterNetWorkMgr:UnInit()
	
end


function GameCenterNetWorkMgr:Connected(ip, port)
	
end

function GameCenterNetWorkMgr:Close()
	
end

local function send_invoke(msg, sz, message)
	local data, datelen = packet.pack_type(message.id, message.id, msg, sz)
	assert(data)
	local ret = NetMgr.Instance():SendMsg(data, datelen)
	packet.free_data(data)
	return ret
end

function GameCenterNetWorkMgr:SendMsg(type, parm)
	return service.invoke(type, parm, send_invoke)
end

function GameCenterNetWorkMgr:Dispatch(msg, sz)
	local type, session, data, datelen = packet.unpack_type(msg, sz)
	assert(type > 0)
	service.dispatch(type, data, datelen)
end


return GameCenterNetWorkMgr