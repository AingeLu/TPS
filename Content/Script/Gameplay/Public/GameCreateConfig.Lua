local GameCreateConfig = class("GameCreateConfig")


function GameCreateConfig:ctor(Config)
	self.BattleID = tonumber(Config.battleid)
	self.MapID = tonumber(Config.mapid)
	self.TeamCnt = tonumber(Config.teamcnt)
	self.GC_ServerIP = Config.gc_ip
	self.GC_ServerPort = tonumber(Config.gc_port)
	self.RoomAddr = tonumber(Config.room_addr)

	self.TeamList = {}
	self.PlayerList = {} 

	for _, Player in ipairs(Config.player) do
		local TeamID = tonumber(Player.teamid)
		if (not self.TeamList[TeamID]) then
			self.TeamList[TeamID] = {}
			self.TeamList[TeamID].PlayerList = {}
			self.TeamList[TeamID].TeamID = TeamID
		end

		local PlayerConfig = {}
		PlayerConfig.Options_Name = ""
		PlayerConfig.PlayerID = tonumber(Player.uid)
		PlayerConfig.PlayerName = Player.name
		PlayerConfig.RoleResID = tonumber(Player.roleresid)
		PlayerConfig.PlayerIndex = tonumber(Player.idx)
		PlayerConfig.AIType = tonumber(Player.ai)
		PlayerConfig.AIOwnerPlayerID = Player.aiowned
		PlayerConfig.AIBrithTime = Player.aibrithtime
		PlayerConfig.TeamID = TeamID
		
		table.insert(self.TeamList[TeamID].PlayerList, PlayerConfig)
		self.PlayerList[#self.PlayerList + 1] = PlayerConfig
	end

	dump(self.TeamList)
end

function GameCreateConfig:GetTeamNum()
	return #self.TeamList;
end

function GameCreateConfig:GetPlayerNum()
	return #self.PlayerList;
end

--获取所有玩家数据列表
function GameCreateConfig:GetAllPlayerListConfig()
	return self.PlayerList;
end

function GameCreateConfig:GetAllTeamListConfig()
	return self.TeamList;
end

function GameCreateConfig:GetAllPlayerListConfigByTeamID(TeamID)

	if self.TeamList[TeamID] == nil then
		return nil;
	end

	return self.TeamList[TeamID].PlayerList
end


return GameCreateConfig


