if GameLogicNetWorkMgr ~= nil then
	return GameLogicNetWorkMgr
end

local pb = require ("Net/GameLogic/Pbc/protobuf")
local service = require("Net/GameLogic/Pbc/service")
local pbu = require ("Net/GameLogic/Pbc/pbunity")
local GameLogicNetConnect = require("Net/GameLogic/GameLogicNetConnect")

local packet = NetPack

GameLogicNetWorkMgr = {}

function GameLogicNetWorkMgr:OnInit()
	--local path = FPaths.ProjectContentDir()
	pb.register_file("Data/Proto/proto.pb")
	packet.init_proto(pb.get_pbenv())
	pbu.parser("Data/Proto", "client.protolist")
	service.enable("Script/Net/GameLogic/Service", "server")

	GameLogicNetConnect:OnInit(self);
end

function GameLogicNetWorkMgr:UnInit()

	GameLogicNetConnect:UnInit();

end

function GameLogicNetWorkMgr:Tick(deltaSeconds)

	GameLogicNetConnect:Tick(deltaSeconds);
end


function GameLogicNetWorkMgr:SendMsg(type, parm)
	return service.invoke(type, parm, send_invoke)
end

function GameLogicNetWorkMgr:Dispatch(msg, sz)
	local type, session, data, datelen = packet.unpack_type(msg, sz)
	assert(type > 0)
	service.dispatch(type, data, datelen)
end


function send_invoke(msg, sz, message)
	local data, datelen = packet.pack_type(message.id, message.id, msg, sz)
	assert(data)
	local ret = NetMgr.Instance():SendMsg(data, datelen)
	packet.free_data(data)
	return ret
end

function GameLogicNetWorkMgr:GetGameLogicNetConnect()
	return GameLogicNetConnect;
end


return GameLogicNetWorkMgr