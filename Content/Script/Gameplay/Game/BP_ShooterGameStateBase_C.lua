require "UnLua"

local BP_ShooterGameStateBase_C = Class()

function BP_ShooterGameStateBase_C:Initialize(Initializer)
    -------------------------------------------------------------------------
    --- Blueprint中定义的变量
    -------------------------------------------------------------------------
	-- self.TeamStateStatistics
	-- self.MatchData
	
	--分数规则
	self.MatchKillScore = 1;
	self.MatchTotalScore = 50;
end

function BP_ShooterGameStateBase_C:ReceiveBeginPlay()

end

function BP_ShooterGameStateBase_C:ReceiveTick(DeltaSeconds)

end

--游戏开始
function BP_ShooterGameStateBase_C:OnGameStarted(CurMapID, GameCreateConfig)

	local ResSceneDesc = GameResMgr:GetGameResDataByResID("SceneDesc_Res", CurMapID)
	if ResSceneDesc then
		self.RemainingTime = ResSceneDesc.RoundTime / 1000.0;
		self.MatchKillScore = ResSceneDesc.KillScore;
		self.MatchTotalScore = ResSceneDesc.TotalScore;
		self.MinRespawnTime = ResSceneDesc.ReSpawnTime / 1000.0;
	end

	self:InitTeamStateStatistics(GameCreateConfig)
end

--游戏结束
function BP_ShooterGameStateBase_C:OnGameEnded()
	
end

--==========================RPC===============

--比赛数据改变
function BP_ShooterGameStateBase_C:OnRep_MatchData()
	LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_LEVEL_MATCHDATACHANGE)
end

--===========================通知=====================
--击杀单位通知
function BP_ShooterGameStateBase_C:OnKillPlayerNoitfy(KillerPlayerState, BeKillerPlayerState)

	local KillerTeamID = KillerPlayerState:GetTeamID();

	local TeamNum = self.MatchData.TeamStateMatchDataArray:Length()
	for i = 1, TeamNum do
		local TeamStateMatchData = self.MatchData.TeamStateMatchDataArray:GetRef(i)
		if (TeamStateMatchData.TeamID == KillerTeamID) then

			TeamStateMatchData.Score = TeamStateMatchData.Score + self.MatchKillScore;

			print("OnKillPlayerNoitfy team Add Score:",TeamStateMatchData.Score, ",teamID:",KillerTeamID)

			--比赛结果
			if TeamStateMatchData.Score >= self.MatchTotalScore then
				self.MatchData.MatchResult = KillerTeamID;
			end

			LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_LEVEL_MATCHDATACHANGE)
		end
	end
end


--超时检查比赛结果
function BP_ShooterGameStateBase_C:DetermineMatchWinner()

	if self.MatchData.MatchResult ~= Ds_BattleRusult.RESULT_NONE then
		return;
	end

	local BestScore = MATH_INT32_MINVAL;
	local BestTeam = -1;
	local HasSameScore = false;

	local TeamNum = self.MatchData.TeamStateMatchDataArray:Length()
	for i = 1, TeamNum do
		local TeamStateMatchData = self.MatchData.TeamStateMatchDataArray:GetRef(i)

		if (TeamStateMatchData.Score == BestTeam) then
			HasSameScore = true;
			break;
		elseif (TeamStateMatchData.Score > BestTeam) then
			BestScore = TeamStateMatchData.Score;
			BestTeam = i;
		end

	end

	if HasSameScore then
		self.MatchData.MatchResult = Ds_BattleRusult.NO_WIN;
	else
		self.MatchData.MatchResult = BestTeam;
	end

	print("DetermineMatchWinner MatchResult:", self.MatchData.MatchResult)

end


--初始化队伍统计数据
function BP_ShooterGameStateBase_C:InitTeamStateStatistics(GameCreateConfig)
	local TeamNums = GameCreateConfig:GetTeamNum();

	self.TeamStateStatistics:Resize(TeamNums)

	self.MatchData.MatchResult = 0
	self.MatchData.TeamStateMatchDataArray:Resize(TeamNums)

	local TeamIndex = 0;
	local TeamListConfig = GameCreateConfig:GetAllTeamListConfig();
	
	for TeamID, teamConfig in pairs(TeamListConfig) do

		TeamIndex = TeamIndex + 1

		local TeamStateMatchData = self.MatchData.TeamStateMatchDataArray:GetRef(TeamIndex)
		TeamStateMatchData.TeamID = TeamID
		TeamStateMatchData.Score = 0

		local PlayerCnt = #teamConfig.PlayerList;

		local StateStatistics = self.TeamStateStatistics:GetRef(TeamIndex)
		StateStatistics.TeamID = TeamID
		StateStatistics.PlayerStateStatisticsArray:Resize(PlayerCnt)

		for i, PlayerConfig in pairs(teamConfig.PlayerList) do

			local PlayerStateStatistics = StateStatistics.PlayerStateStatisticsArray:GetRef(i)
			PlayerStateStatistics.RuntimeHeader.PlayerID = PlayerConfig.PlayerID
			PlayerStateStatistics.RuntimeHeader.TeamID = PlayerConfig.TeamID
			PlayerStateStatistics.RuntimeHeader.PlayerIndex = PlayerConfig.PlayerIndex
			PlayerStateStatistics.RuntimeHeader.RoleResID = PlayerConfig.RoleResID
			PlayerStateStatistics.RuntimeHeader.PlayerName = PlayerConfig.PlayerName
		end

	end	
end

--同步队伍统计数据
function BP_ShooterGameStateBase_C:UpdateTeamStateStatistics(RuntimeHeader, RuntimeStatisticsData)
	local TeamNum = self.TeamStateStatistics:Length()
	for i = 1, TeamNum do
		local TeamStateStatisticOne = self.TeamStateStatistics:GetRef(i)
		if (TeamStateStatisticOne.TeamID == RuntimeHeader.TeamID) then

			local PlayerNum = TeamStateStatisticOne.PlayerStateStatisticsArray:Length()
			for j=1, PlayerNum do

				local PlayerStateStatisticsOne = TeamStateStatisticOne.PlayerStateStatisticsArray:GetRef(j)
				if PlayerStateStatisticsOne.RuntimeHeader.PlayerIndex == RuntimeHeader.PlayerIndex then
					PlayerStateStatisticsOne.RuntimeStatisticsData = RuntimeStatisticsData;
				end
			end

		end
	end
end


--比赛是否结束
function BP_ShooterGameStateBase_C:IsMatchOver()
	if  self.MatchData.MatchResult == Ds_BattleRusult.RESULT_NONE then
		return false;
	end
	return true;
end

function BP_ShooterGameStateBase_C:IsWinner(PlayerState)

	if self.MatchData.MatchResult == Ds_BattleRusult.RESULT_NONE then
		return false;
	end

	if self.MatchData.MatchResult == Ds_BattleRusult.NO_WIN then
		return true;
	end
	
	if PlayerState then
		return  (PlayerState:GetTeamID() == self.MatchData.MatchResult) and true or false;
	end

	return false;
end

--=============获取数据=======================

--获取比赛剩余时间s
function BP_ShooterGameStateBase_C:GetRemainTime()
	return self.RemainingTime;
end

function BP_ShooterGameStateBase_C:GetMinRespawnTime()
	return self.MinRespawnTime;
end

--根据队伍ID获取比赛数据s
function BP_ShooterGameStateBase_C:GetTeamStateMatchDataByTeamID(TeamID)
	local Num = self.MatchData.TeamStateMatchDataArray:Length()
	for i = 1, Num do
		local TeamStateMatchData = self.MatchData.TeamStateMatchDataArray:GetRef(i)
		if (TeamStateMatchData.TeamID == TeamID) then
			return TeamStateMatchData;
		end
	end

	return nil;
end

--获取统计数据
function BP_ShooterGameStateBase_C:GetTeamStateStatistics(TeamID)
	local Num = self.TeamStateStatistics:Length()
	for i = 1, Num do
		local StateStatistics = self.TeamStateStatistics:GetRef(i)
		if (StateStatistics.TeamID == TeamID) then
			return StateStatistics
		end
	end
end

function BP_ShooterGameStateBase_C:GetPlayerStateStatisticsByID(PlayerID)
	local Num = self.TeamStateStatistics:Length()
	for i = 1, Num do
		local StateStatistics = self.TeamStateStatistics:GetRef(i)
		local PlayerStateStatisticsArray = StateStatistics.PlayerStateStatisticsArray
		local PlayerNum = PlayerStateStatisticsArray:Length()
		for j = 1, PlayerNum do
			local PlayerStateStatistics = PlayerStateStatisticsArray:GetRef(j)
			if (PlayerStateStatistics.RuntimeHeader.PlayerID == PlayerID) then
				return PlayerStateStatistics
			end
		end
	end
end

function BP_ShooterGameStateBase_C:GetPlayerStateStatisticsByIndex(TeamID, PlayerIndex)
	local Num = self.TeamStateStatistics:Length()
	for i = 1, Num do
		local StateStatistics = self.TeamStateStatistics:GetRef(i)
		local PlayerStateStatisticsArray = StateStatistics.PlayerStateStatisticsArray
		local PlayerNum = PlayerStateStatisticsArray:Length()
		for j = 1, PlayerNum do
			local PlayerStateStatistics = PlayerStateStatisticsArray:GetRef(j)
			if (PlayerStateStatistics.RuntimeHeader.PlayerIndex == PlayerIndex) then
				return PlayerStateStatistics
			end
		end
	end
end

function BP_ShooterGameStateBase_C:GetPlayerStateByIndex(index)
	if self.PlayerArray == nil then
		return nil
	end

	local len = self.PlayerArray:Length()
	if index < 1 or index > len then
		return nil
	end

	return self.PlayerArray:GetRef(index)
end

function BP_ShooterGameStateBase_C:GetPlayerStateLength()
	if self.PlayerArray == nil then
		return 0
	end

	return self.PlayerArray:Length()
end

--- 获取队伍存活人数 【运行时】
function BP_ShooterGameStateBase_C:GetPlayerAliveByTeamID(teamID)
	local playerStateCtn = self:GetPlayerStateLength()
	if teamID <= 0 or teamID > playerStateCtn then
		return 0
	end

	local aliveNum = 0
	for i = 1, playerStateCtn do
		local playState = self:GetPlayerStateByIndex(i)
		if playState ~= nil then

			local shooterPlayState = playState:Cast(UE4.ABP_ShooterPlayerStateBase_C)
			if shooterPlayState ~= nil then
				local tid = shooterPlayState:GetTeamID()

				if tid == teamID then
					if shooterPlayState:GetPlayerCharacterStatus() == ECharacterStatus.ECharacterStatus_ALIVE then
						aliveNum = aliveNum + 1
					end
				end
			end
		end
	end

	return aliveNum
end

return BP_ShooterGameStateBase_C
