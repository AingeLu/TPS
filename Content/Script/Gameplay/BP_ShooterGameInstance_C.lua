require "UnLua"
require "Main"

local GameCreateConfig = require("GamePlay/Public/GameCreateConfig")

local BP_ShooterGameInstance_C = Class()

--- 状态配置
BP_ShooterGameInstance_C.ShooterGameInstanceState =
{
	None = "None",
	MainMenu = "MainMenu",
}

--- 地图配置
BP_ShooterGameInstance_C.MapConfig =
{
	WelcomeScreenMap = "/Game/Maps/Entrance" ,
	MainMenuMap = "/Game/Maps/MainMenu" ,
}

ShooterGameInstance = nil

function ShooterGameInstance_ReceiveInit(self)

end

--- 改用全局函数 ，会在ShooterGameInstance.cpp 对应周期中进行调用
function ShooterGameInstance_ReceiveShutdown()
	Main_UnInit();
end

--Release模式启动
function ShooterGameInstance_ReceiveStartGameInstance(strDataFilePath)

	print("ShooterGameInstance_ReceiveStartGameInstance start, strDataFilePath:",strDataFilePath)
	
	local Config = CJson.load(strDataFilePath)
	ShooterGameInstance.GameCreateConfig = GameCreateConfig.new(Config)
end

--编辑器启动
function ShooterGameInstance_ReceiveStartPlayInEditorGameInstance()

	local strDataFile = FPaths.ProjectContentDir() .. "Data/Config/Ds_data.txt"
	local Config = CJson.load(strDataFile)

	ShooterGameInstance.GameCreateConfig = GameCreateConfig.new(Config)
end

function ShooterGameInstance_ReceivePreLoadMap(MapName)
	print("ShooterGameInstance_ReceivePreLoadMap")
	if MapName == "/Game/Maps/BattleDebug" or MapName =="/Game/Maps/Training_Ground/Training_Ground" then  
		ShooterGameInstance:SetLoadingScreenEnable(true)
	end
end

function ShooterGameInstance_ReceivePostLoadMap()
	print("ShooterGameInstance_ReceivePostLoadMap")
	
end

function ShooterGameInstance_ReceiveTick(DeltaSeconds)

	if ShooterGameInstance ~= nil then
		ShooterGameInstance:CheckGameSceneStateChange()
	end

	Main_Tick(DeltaSeconds)
end

function BP_ShooterGameInstance_C:Initialize(Initializer)

	ShooterGameInstance = self

	self.CurrentState = BP_ShooterGameInstance_C.ShooterGameInstanceState.None

	Main_Init()
end

-------------------------------------
--- 辅助接口
-------------------------------------
function BP_ShooterGameInstance_C:CheckGameSceneStateChange()

	if self.PendingState ~= self.CurrentState and self.PendingState ~= BP_ShooterGameInstance_C.ShooterGameInstanceState.None then
		print("|| CheckGameSceneStateChange ... " , self.CurrentState , " to " , self.PendingState)

		self:EndGameState()

		self:BeginNewGameState(self.PendingState)

		--- 清除
		self.PendingState = BP_ShooterGameInstance_C.ShooterGameInstanceState.None
	end
end

function BP_ShooterGameInstance_C:EndGameState()
	-- 离开状态
	if self.CurrentState == BP_ShooterGameInstance_C.ShooterGameInstanceState.None then
		self:EndMainMenu()
	end

	self.CurrentState = BP_ShooterGameInstance_C.ShooterGameInstanceState.None
end

function BP_ShooterGameInstance_C:BeginNewGameState(newState)

	if newState == BP_ShooterGameInstance_C.ShooterGameInstanceState.MainMenu then
		self:BeginMainMenu()
	end

	self.CurrentState = newState
end

-------------------------------------
--- Begin GameScene State
-------------------------------------
function BP_ShooterGameInstance_C:BeginMainMenu()

	self:LoadMap(self.MapConfig.MainMenuMap)
end

--退出返回大厅
function BP_ShooterGameInstance_C:RequestFinishAndExitToMainMenu()

	print("BP_ShooterGameInstance_C RequestFinishAndExitToMainMenu");

	--如果是服务器模式 优先退出玩家
	local CurGameMode = UE4.UGameplayStatics.GetGameMode(self:GetWorld()); --self.AuthorityGameMode
	if CurGameMode then
		CurGameMode = CurGameMode and CurGameMode:Cast(UE4.ABP_ShooterGameModeBase_C) or nil;
		if CurGameMode then
			CurGameMode:RequestFinishAndExitToMainMenu()
		end
	end

	--返回大厅
	self:C_ReturnToMainMenu();
end

-------------------------------------
--- End GameScene State
-------------------------------------
function BP_ShooterGameInstance_C:EndMainMenu()
end

return BP_ShooterGameInstance_C
