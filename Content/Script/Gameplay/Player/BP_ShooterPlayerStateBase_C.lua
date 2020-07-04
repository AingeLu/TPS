require "UnLua"

local BP_ShooterPlayerStateBase_C = Class()

function BP_ShooterPlayerStateBase_C:Initialize(Initializer)

end

function BP_ShooterPlayerStateBase_C:ReceiveBeginPlay()

end

function BP_ShooterPlayerStateBase_C:RespawnPlayerState()

	local ShooterCharacter = self:GetShooterCharacter();

	if ShooterCharacter then
		self.RuntimeAttrData.CharacterStatus = ShooterCharacter:GetCharacterStatus();
		self.RuntimeAttrData.HpPercent = math.floor(ShooterCharacter:GetHp() * 255 / ShooterCharacter:GetMaxHp());
		self.RuntimeAttrData.LastDeadTime = 0;
		self.RuntimeAttrData.ResPawnNeedTime = 0;
	end

end


function BP_ShooterPlayerStateBase_C:ReceiveTick(DeltaSeconds)
	
end

--击杀目标通知
function BP_ShooterPlayerStateBase_C:OnKillPlayerNoitfy()

	self.RuntimeStatisticsData.KillNums = self.RuntimeStatisticsData.KillNums + 1;

	self:SyncData2GameState();
end

--被击杀通知
function BP_ShooterPlayerStateBase_C:OnBeKillPlayerNoitfy(RespawnTime)

	local ShooterCharacter = self:GetShooterCharacter();
	if ShooterCharacter then
		self.RuntimeAttrData.CharacterStatus = ShooterCharacter:GetCharacterStatus();
		self.RuntimeAttrData.HpPercent = 0;
		self.RuntimeAttrData.LastDeadTime = math.modf(UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self))
		self.RuntimeAttrData.ResPawnNeedTime = RespawnTime;
	end

end


function BP_ShooterPlayerStateBase_C:SetPlayerConfig(PlayerConfig)
	self.RuntimeHeader.PlayerID = PlayerConfig.PlayerID
	self.RuntimeHeader.TeamID = PlayerConfig.TeamID
	self.RuntimeHeader.PlayerIndex = PlayerConfig.PlayerIndex
	self.RuntimeHeader.RoleResID = PlayerConfig.RoleResID
	self.RuntimeHeader.PlayerName = PlayerConfig.PlayerName

	self:C_SetPlayerName(PlayerConfig.PlayerName)
end

function BP_ShooterPlayerStateBase_C:SyncData2GameState()

	--将数据同步给GameState
	if UE4.UKismetSystemLibrary.IsServer(self) then
		local GameState = UE4.UGameplayStatics.GetGameState(self)
		if  GameState  then
			local ShooterGameState = GameState:Cast(UE4.ABP_ShooterGameStateBase_C)
			if ShooterGameState then
				ShooterGameState:UpdateTeamStateStatistics(self.RuntimeHeader, self.RuntimeStatisticsData);
			end
		end
	end
	
end

-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------
function BP_ShooterPlayerStateBase_C:GetShooterCharacter()
	local PlayerController = self:GetOwner():Cast(UE4.ABP_ShooterPlayerControllerBase_C)
	if PlayerController then
		return PlayerController:GetShooterCharacter()
	else --AI
		return nil;
	end
end

function BP_ShooterPlayerStateBase_C:GetPlayerID()
	return self.RuntimeHeader.PlayerID
end

function BP_ShooterPlayerStateBase_C:GetTeamID()
	return self.RuntimeHeader.TeamID
end

function BP_ShooterPlayerStateBase_C:GetPlayerIndex()
	return self.RuntimeHeader.PlayerIndex
end

function BP_ShooterPlayerStateBase_C:GetRoleResID()
	return self.RuntimeHeader.RoleResID
end

function BP_ShooterPlayerStateBase_C:GetRuntimeHeader()
	return self.RuntimeHeader
end

function BP_ShooterPlayerStateBase_C:GetRuntimeStatisticsData()
	return self.RuntimeStatisticsData
end

function BP_ShooterPlayerStateBase_C:GetRuntimeAttrData()
	return self.RuntimeAttrData
end

function BP_ShooterPlayerStateBase_C:GetRuntimePlayerName()
	if self.RuntimeHeader ~= nil then
		return self.RuntimeHeader.PlayerName
	end

	return ""
end

function BP_ShooterPlayerStateBase_C:GetLastDeadTime()
	if self.RuntimeAttrData ~= nil then
		return self.RuntimeAttrData.LastDeadTime
	end

	return 0.0
end

function BP_ShooterPlayerStateBase_C:GetRespawnNeedTime()
	if self.RuntimeAttrData ~= nil then
		return self.RuntimeAttrData.ResPawnNeedTime
	end

	return 0.0
end

--客户端主动改变数据
function BP_ShooterPlayerStateBase_C:Client_SetRuntimeAttrData(RuntimeAttrData)
	if self.RuntimeAttrData ~= nil and RuntimeAttrData ~= nil then
		self.RuntimeAttrData = RuntimeAttrData
	end
end

function BP_ShooterPlayerStateBase_C:GetPlayerCharacterStatus()
	if self.RuntimeAttrData ~= nil then
		return self.RuntimeAttrData.CharacterStatus
	end

	return ECharacterStatus.ECharacterStatus_ALIVE
end

function BP_ShooterPlayerStateBase_C:GetHpPercent()
	if self.RuntimeHeader ~= nil then
		return self.RuntimeHeader.HpPercent
	end

	return 0
end

return BP_ShooterPlayerStateBase_C
