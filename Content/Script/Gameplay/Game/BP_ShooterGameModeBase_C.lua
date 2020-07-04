require "UnLua"

local BP_ShooterGameModeBase_C = Class()

local MatchState = 
{ 
	EnteringMap = "EnteringMap", 
	WaitingToStart = "WaitingToStart", 
	InProgress = "InProgress", 
	WaitingPostMatch = "WaitingPostMatch",
	LeavingMap = "LeavingMap",
	Aborted = "Aborted"
}

local ChoosePointMode =
{
    TEAM_FIXED_SPAWN = 0,
}

function BP_ShooterGameModeBase_C:Initialize(Initializer)
	
	-- 初始化引擎的变量
	self.bUseSeamlessTravel = true
	self.bDelayedStart = true

	self.AutoDebugPlayerIDIndex = 1
	self.TimerHandle = nil

	self.GameWaiteStartTime = 3.0;
	self.MinRespawnTime = 99999.0;
end

function BP_ShooterGameModeBase_C:ReceiveBeginPlay()

	print("BP_ShooterGameModeBase_C ReceiveBeginPlay")
	
	self.TimerHandle = UE4.UKismetSystemLibrary.K2_SetTimerDelegate({self, BP_ShooterGameModeBase_C.TickTimer}, 1.0, true)
end

function BP_ShooterGameModeBase_C:Receive_InitGame(MapName , Options)
	print("||BP_ShooterGameModeBase_C:Receive_InitGame ...")
end

function BP_ShooterGameModeBase_C:Receive_InitGameState()
	print("||BP_ShooterGameModeBase_C:Receive_InitGameState ...")
end

function BP_ShooterGameModeBase_C:Receive_PreLogin(Options, Address, UniqueNetId)
	
	print("||BP_ShooterGameModeBase_C:Receive_PreLogin ...")

	if ((self:GetMatchState() == MatchState.WaitingPostMatch) or (self:GetMatchState() == MatchState.LeavingMap)) then
		print ("BP_ShooterGameModeBase_C Receive_PreLogin WaitingPostMatch or LeavingMap");
		return
	end

	local strPlayerID = UE4.UGameplayStatics.ParseOption(Options, "playerId")
	local key = UE4.UGameplayStatics.ParseOption(Options, "key")
	local Options_Name = UE4.UGameplayStatics.ParseOption(Options, "Name")

	if (#strPlayerID == 0) then
		strPlayerID = tostring(self.AutoDebugPlayerIDIndex)
		self.AutoDebugPlayerIDIndex = self.AutoDebugPlayerIDIndex + 1
	end

	print ("BP_ShooterGameModeBase_C Receive_PreLogin, playerId:", strPlayerID, ",Options_Name:", Options_Name);

	local PlayerID = tonumber(strPlayerID)
	
	local BP_ShooterGameInstance = self:GetShooterGameInstance()
	if BP_ShooterGameInstance == nil then
		print("BP_ShooterGameModeBase_C Receive_PreLogin, BP_ShooterGameInstance is nil");
		return;
	end

	local bFind = false;
	local AllPlayerListConfig = BP_ShooterGameInstance.GameCreateConfig:GetAllPlayerListConfig()
	for _, Player in pairs(AllPlayerListConfig) do
		if (Player.PlayerID == PlayerID) then
			Player.Options_Name = Options_Name;
			bFind = true
			break
		end
	end

	--未找到列表playerID
	if not bFind then
		print("BP_ShooterGameModeBase_C:Receive_PreLogin not find playerID in List,PlayerID:", PlayerID)
	end

	return
end

function BP_ShooterGameModeBase_C:Receive_PostLogin(NewPlayer)
	print("||BP_ShooterGameModeBase_C:Receive_PostLogin ...")
	if NewPlayer == nil then
		print("BP_ShooterGameModeBase_C:Receive_PostLogin Error: NewPlayer is nil .")
		return
	end

	local PlayerContorller = NewPlayer:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
	if PlayerContorller ~= nil and self:IsMatchInProgress() then
		PlayerContorller:OnGameStarted()
	end
end

function BP_ShooterGameModeBase_C:Receive_InitNewPlayer(NewPlayerController, UniqueNetId, Options, Portal)

	print("|| BP_ShooterGameModeBase_C Receive_InitNewPlayer Options:" , Options , "Portal:" , Portal)

	local BP_ShooterGameInstance = self:GetShooterGameInstance()
	if BP_ShooterGameInstance == nil then
		print("BP_ShooterGameModeBase_C Receive_InitNewPlayer, BP_ShooterGameInstance is nil");
		return;
	end

	local Options_Name = UE4.UGameplayStatics.ParseOption(Options, "Name")
	local strPlayerID = UE4.UGameplayStatics.ParseOption(Options, "playerId")

	local AllPlayerListConfig = BP_ShooterGameInstance.GameCreateConfig:GetAllPlayerListConfig()

	if (#strPlayerID == 0) then
		local bFind = false;
		for _, Player in pairs(AllPlayerListConfig) do
			if (Player.Options_Name == Options_Name) then
				strPlayerID = ""..Player.PlayerID;
				bFind = true
				break
			end
		end

		if not bFind then
			print ("BP_ShooterGameModeBase_C Receive_InitNewPlayer not find player, Options_Name:", Options_Name);
			return;
		end
	end

	local PlayerID = tonumber(strPlayerID)

	print ("BP_ShooterGameModeBase_C Receive_InitNewPlayer, playerId:", strPlayerID, ",Options_Name:", Options_Name);

	local curPlayerController = NewPlayerController:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
	if curPlayerController == nil then
		print("BP_ShooterGameModeBase_C:Receive_InitNewPlayer Error: curPlayerController is nil .")
		return
	end

	local PlayerState = curPlayerController.PlayerState:Cast(UE4.ABP_ShooterPlayerStateBase_C);
	if PlayerState == nil then
		print("BP_ShooterGameModeBase_C:Receive_InitNewPlayer Error: PlayerState is nil .")
		return
	end

	local Standalone = UE4.UGameplayStatics.ParseOption(Options, "Standalone");

	if (Standalone == "1") then
		local PlayerConfig = AllPlayerListConfig[1]
		PlayerState:SetPlayerConfig(PlayerConfig)
	else
		for _, PlayerConfig in pairs(AllPlayerListConfig) do
			if (PlayerConfig.PlayerID == PlayerID) then
				PlayerState:SetPlayerConfig(PlayerConfig)
				break
			end
		end
	end

	return ""
end


function BP_ShooterGameModeBase_C:Receive_HandleStartingNewPlayer(NewPlayerController)
	print("||BP_ShooterGameModeBase_C:Receive_HandleStartingNewPlayer ...")
end

function BP_ShooterGameModeBase_C:Receive_Logout(NewPlayer)
	print("||BP_ShooterGameModeBase_C:Receive_Logout ...")
end


function BP_ShooterGameModeBase_C:K2_OnSetMatchState(NewState)
	print("|| NewState :" , NewState)
	if (NewState == MatchState.WaitingToStart) then
		self:HandleMatchIsWaitingToStart()
	elseif (NewState == MatchState.InProgress) then
		self:HandleMatchHasStarted()
	elseif (NewState == MatchState.WaitingPostMatch) then
		self:HandleMatchHasEnded()
	elseif (NewState == MatchState.LeavingMap) then
		self:HandleLeavingMap()
	elseif (NewState == MatchState.Aborted) then
		self:HandleMatchAborted()
	end
	
end

function BP_ShooterGameModeBase_C:K2_PostLogin(NewPlayer)

end


function BP_ShooterGameModeBase_C:K2_OnLogout(ExitingController)

end

--function BP_ShooterGameModeBase_C:K2_OnRestartPlayer(NewPlayer)
--	self.Overridden.K2_OnRestartPlayer(self , NewPlayer)
--end

--蓝图函数
---@param player type(AController)
function BP_ShooterGameModeBase_C:ChoosePlayerStart(player)

	print("BP_ShooterGameModeBase_C ChoosePlayerStart ...")

	local playerStartPoints = UE4.TArray(UE4.AActor)
	UE4.UGameplayStatics.GetAllActorsOfClass(self , UE4.ABP_TeamPawnStart_C , playerStartPoints)

    local playerSpawnPoint = self:GetChoosePlayerStartByMode(playerStartPoints, player , ChoosePointMode.TEAM_FIXED_SPAWN)
    if playerSpawnPoint ~= nil then
        return playerSpawnPoint
    end

    print("BP_ShooterGameModeBase_C:ChoosePlayerStart Error:  playerSpawnPoint is nil .")
	return self.Overridden.ChoosePlayerStart(self , player)
end

function BP_ShooterGameModeBase_C:HandleMatchIsWaitingToStart()

	print("BP_ShooterGameModeBase_C HandleMatchIsWaitingToStart");

	local ShooterGameState = self:GetShooterGameState()
	if ShooterGameState then
		ShooterGameState.RemainingTime = self.GameWaiteStartTime;
	end
end

function BP_ShooterGameModeBase_C:HandleMatchHasStarted()

	local BP_ShooterGameInstance = self:GetShooterGameInstance()
	if BP_ShooterGameInstance == nil then
		print("BP_ShooterGameModeBase_C HandleMatchHasStarted BP_ShooterGameInstance is nil");
		return;
	end

	local CurMapID = BP_ShooterGameInstance.GameCreateConfig.MapID;

	print("BP_ShooterGameModeBase_C HandleMatchHasStarted CurMapID:", CurMapID);

	local LevelItemPawnMgr = require "Gameplay/Game/Item/LevelItemPawnMgr"

	self.LevelItemPawnMgr  = LevelItemPawnMgr.new()
	self.LevelItemPawnMgr:OnInit(self);

	self.LevelItemPawnMgr:HandleMatchIsWaitingToStart();

	local ShooterGameState = self:GetShooterGameState()
	if ShooterGameState then
		ShooterGameState:OnGameStarted(CurMapID, BP_ShooterGameInstance.GameCreateConfig);
	end

	local AllPlayerControllers = UE4.UGameplayStatics.GetAllActorsOfClass(self, UE4.ABP_ShooterPlayerControllerBase_C)
    for i = 1, AllPlayerControllers:Length() do
        local PlayerController = AllPlayerControllers:GetRef(i)
		if PlayerController then
			PlayerController:OnGameStarted();
		end
	end

end

function BP_ShooterGameModeBase_C:HandleMatchHasEnded()

	print("BP_ShooterGameModeBase_C HandleMatchHasEnded");

	local ShooterGameState = self:GetShooterGameState()
	if ShooterGameState then
		ShooterGameState:DetermineMatchWinner();
		ShooterGameState:OnGameEnded();
	end

	--通知玩家游戏结束
	local AllPlayerControllers = UE4.UGameplayStatics.GetAllActorsOfClass(self, UE4.ABP_ShooterPlayerControllerBase_C)
    for i = 1, AllPlayerControllers:Length() do
		local PlayerController = AllPlayerControllers:GetRef(i)
		if PlayerController then
			local PlayerState = PlayerController.PlayerState:Cast(UE4.ABP_ShooterPlayerStateBase_C);		 
			PlayerController:C_GameHasEnded(nil, ShooterGameState and ShooterGameState:IsWinner(PlayerState) or false);
			PlayerController:OnGameEnded();
		end
	end

	
	local AllShooterCharacters = UE4.UGameplayStatics.GetAllActorsOfClass(self, UE4.ABP_ShooterCharacterBase_C)
    for i = 1, AllShooterCharacters:Length() do
        local ShooterCharacter = AllShooterCharacters:GetRef(i)
		ShooterCharacter:C_TurnOff()
    end

	--连接GameCenter

	if  UE4.UKismetSystemLibrary.IsDedicatedServer(self) then
		
		UE4.UKismetSystemLibrary.K2_SetTimerDelegate({self, BP_ShooterGameModeBase_C.RequestExitGame}, 5.0, false)
    end
end

function BP_ShooterGameModeBase_C:HandleLeavingMap()
	print("BP_ShooterGameModeBase_C HandleLeavingMap");
end

function BP_ShooterGameModeBase_C:HandleMatchAborted()
	print("BP_ShooterGameModeBase_C HandleMatchAborted");
end

function BP_ShooterGameModeBase_C:TickTimer()

	local ShooterGameState = self:GetShooterGameState()
	if ShooterGameState == nil then
		return;
	end

	if ShooterGameState.RemainingTime > 0 then

		ShooterGameState.RemainingTime = ShooterGameState.RemainingTime - 1.0;

		if ShooterGameState.RemainingTime <= 0.0 then

			if self:GetMatchState() == MatchState.WaitingPostMatch then
				self:RestartGame();
			elseif self:GetMatchState() == MatchState.InProgress then
				self:EndMatch();
			elseif self:GetMatchState() == MatchState.WaitingToStart then
				self:StartMatch();
			end

		else
			if self:GetMatchState() == MatchState.InProgress and ShooterGameState:IsMatchOver() then
				self:EndMatch();
			end
		end

	end
end

--退出进程
function BP_ShooterGameModeBase_C:RequestExitGame()
	print("AShooterGameMode RequestExitGame");
	self:RequestFinishAndExitToMainMenu();
	self:RequestExit(false)
end

--退出所有玩家
function BP_ShooterGameModeBase_C:RequestFinishAndExitToMainMenu()

	print("BP_ShooterGameModeBase_C RequestFinishAndExitToMainMenu");

	local AllPlayerControllers = UE4.UGameplayStatics.GetAllActorsOfClass(self, UE4.ABP_ShooterPlayerControllerBase_C)
    for i = 1, AllPlayerControllers:Length() do
        local PlayerController = AllPlayerControllers:GetRef(i)
		if PlayerController then
			if not PlayerController:IsLocalController() then
				PlayerController:ClientReturnToMainMenuWithTextReason("server-close");
			end
		end
	end

end


function BP_ShooterGameModeBase_C:GetLevelItemPawnMgr()
	return self.LevelItemPawnMgr
end

function BP_ShooterGameModeBase_C:GetShooterGameInstance()
	local GameInstance = self:GetWorld().OwningGameInstance
	return GameInstance:Cast(UE4.UBP_ShooterGameInstance_C)
end

function BP_ShooterGameModeBase_C:GetShooterGameState()
	local GameState = UE4.UGameplayStatics.GetGameState(self)
    if  GameState  then
		return GameState:Cast(UE4.ABP_ShooterGameStateBase_C)
	end
	return nil;
end


-------------------------------------------------------------
--- 通知
-------------------------------------------------------------
--击杀通知
function BP_ShooterGameModeBase_C:OnKillPlayerNoitfy(AC_Killer, AC_BeKiller)

	if AC_Killer == nil or AC_BeKiller == nil then
		return;
	end

	local KillerPlayerState =  AC_Killer.PlayerState:Cast(UE4.ABP_ShooterPlayerStateBase_C)
	local BeKillerPlayerState =  AC_BeKiller.PlayerState:Cast(UE4.ABP_ShooterPlayerStateBase_C)
	if KillerPlayerState == nil or BeKillerPlayerState == nil then
		print("BP_ShooterGameModeBase_C OnKilled PlayerState is nil")
		return;
	end

	local ShooterGameState = self:GetShooterGameState()
	if ShooterGameState then
		ShooterGameState:OnKillPlayerNoitfy(KillerPlayerState, BeKillerPlayerState);
	end

	if KillerPlayerState then
		KillerPlayerState:OnKillPlayerNoitfy();
	end

	if BeKillerPlayerState then
		BeKillerPlayerState:OnBeKillPlayerNoitfy(ShooterGameState:GetMinRespawnTime());
	end

	--通知客户端
	local AllPlayerControllers = UE4.UGameplayStatics.GetAllActorsOfClass(self, UE4.ABP_ShooterPlayerControllerBase_C)
    for i = 1, AllPlayerControllers:Length() do
        local PlayerController = AllPlayerControllers:GetRef(i)
		if PlayerController then
			PlayerController:ServerKillPlayerNotify(KillerPlayerState, BeKillerPlayerState);
			PlayerController:SendClientKillPlayer(KillerPlayerState, BeKillerPlayerState, BeKillerPlayerState:GetRuntimeAttrData());
		end
	end

end

--单位复活
function BP_ShooterGameModeBase_C:BeginRespawn(AC_PlayerrControl)

	local TeamID = AC_PlayerrControl:GetTeamID();
	local PlayerIndex = AC_PlayerrControl:GetPlayerIndex()

	local playerStartPoints = UE4.TArray(UE4.AActor)
	UE4.UGameplayStatics.GetAllActorsOfClass(self , UE4.ABP_TeamPawnStart_C , playerStartPoints)

	local spawnPointActor = nil
	for i = 1, playerStartPoints:Length() do
		local spawnPoint = playerStartPoints:GetRef(i)
		if spawnPoint.TeamID == TeamID and spawnPoint.PointIndex == PlayerIndex then
			spawnPointActor = spawnPoint
			break
		end
	end

	if spawnPointActor then
    	local SpawnTransform = UE4.FTransform(spawnPointActor:K2_GetActorRotation():ToQuat(), spawnPointActor:K2_GetActorLocation())
		self:RestartPlayerAtTransform(AC_PlayerrControl, SpawnTransform);
	else
		self:RestartPlayer(AC_PlayerrControl);
		print("BP_ShooterGameModeBase_C BeginRespawn not find spawnPoint,tamID:", TeamID, ",playerIndex:", PlayerIndex)
	end

	local playerState = AC_PlayerrControl:GetShooterPlayerState()
	if playerState ~= nil then
		playerState:RespawnPlayerState()

		--通知
		AC_PlayerrControl:ServerResPawnStartedNotify()
		AC_PlayerrControl:SendClientResPawnStarted(playerState:GetRuntimeAttrData())
	end
	
end


-------------------------------------------------------------
--- 辅助函数
-------------------------------------------------------------

--- 获取出生点
---@param playerStartPoints TArray(ABP_TeamPawnStart_C)
---@param playerController APlayerController
---@param mode ChoosePointMode
function BP_ShooterGameModeBase_C:GetChoosePlayerStartByMode(playerStartPoints ,playerController , mode)
	if mode == ChoosePointMode.TEAM_FIXED_SPAWN then
		return self:ChoosePlayerStartTeamFixedSpawnPoint(playerStartPoints , playerController)
	else
		print("BP_ShooterGameModeBase_C:GetChoosePlayerStartByMode Error: Can not Find the mode . Mode :" , mode)
		return nil
	end
end

--- 获取出生点 【同队内固定出生点】
---@param playerStartPoints TArray(ABP_TeamPawnStart_C)
---@param playerController APlayerController
function BP_ShooterGameModeBase_C:ChoosePlayerStartTeamFixedSpawnPoint(playerStartPoints , playerController)
    if playerController == nil then
        print("BP_ShooterGameModeBase_C:ChoosePlayerStartTeamFixedSpawnPoint Error: playerController is nil .")
        return nil;
    end

    local shooterPlayerController = playerController:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    if shooterPlayerController == nil then
        print("BP_ShooterGameModeBase_C:ChoosePlayerStartTeamFixedSpawnPoint Error: Cast Failed . shooterPlayerController is nil .")
        return nil
    end

	if playerStartPoints == nil or playerStartPoints:Length() <= 0  then
		print("BP_ShooterGameModeBase_C:ChoosePlayerStartTeamFixedSpawnPoint playerStartPoints length is 0")
		return nil;
	end

	local playerTeamID = shooterPlayerController:GetTeamID()
	
	local selectPointIndex = shooterPlayerController:GetPlayerIndex()
	selectPointIndex = selectPointIndex + 1

	if selectPointIndex <= 0 or selectPointIndex > playerStartPoints:Length() then
		print("BP_ShooterGameModeBase_C:ChoosePlayerStartTeamFixedSpawnPoint Error: selectPointIndex out of array . selectPointIndex :" , selectPointIndex)
		selectPointIndex = playerStartPoints:Length() - 1
	end

	local spawnPointActor = nil
	for i = 1, playerStartPoints:Length() do
		local spawnPoint = playerStartPoints:GetRef(i)
		if spawnPoint.TeamID == playerTeamID and spawnPoint.PointIndex == selectPointIndex then
			spawnPointActor = spawnPoint
			break
		end
	end

	if spawnPointActor == nil then
		print("BP_ShooterGameModeBase_C:ChoosePlayerStartTeamFixedSpawnPoint Error: Player TeamID : ", playerTeamID , "   selectPointIndex :" , selectPointIndex)
	end

	return spawnPointActor
end

function BP_ShooterGameModeBase_C:CanDealDamage(DamageInstigator, DamagedPlayer)

	if (DamageInstigator == nil) or (DamagedPlayer == nil) or (DamagedPlayer == DamageInstigator) then
		return false
	end

	local DamagedPlayerState = DamagedPlayer.PlayerState:Cast(UE4.ABP_ShooterPlayerStateBase_C)
	local InstigatorPlayerState = DamageInstigator.PlayerState:Cast(UE4.ABP_ShooterPlayerStateBase_C)
	if (DamagedPlayerState == nil) or (InstigatorPlayerState == nil) then
		return true
	end

	return  (DamagedPlayerState:GetTeamID() ~= InstigatorPlayerState:GetTeamID())
end

--- @param NewPlayerController AController
function BP_ShooterGameModeBase_C:ResetPlayerState(NewPlayerController)
	if NewPlayerController ~= nil then
		local playerState = NewPlayerController.PlayerState
		if playerState ~= nil and playerState:Cast(UE4.ABP_ShooterPlayerStateBase_C) ~= nil then
			playerState:Cast(UE4.ABP_ShooterPlayerStateBase_C):ResetPlayerState()
		end
	end
end


return BP_ShooterGameModeBase_C
