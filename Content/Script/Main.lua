require("GlobalFunctions")

require("Common/macros")
require("Common/enums")
require("Common/functions")
require("Common/class")
require("Common/MathUtils")
require("Common/ResourceMgr")

require("Res/GameResMgr")

require("Gameplay/Public/GamePlayDefine")

require("Net/GameLogic/GameLogicNetWorkMgr")

require("UI/PlayerData/PlayerDataMgr")

require("UI/UIManager")


GameRealTimeSinceStartup = 0

function Main_Init()
    print("Main Init Start");

    ResourceMgr:OnInit();
    GameResMgr:OnInit();
    
    LUAPlayerDataMgr:OnInit();

    LUIManager:OnInit();

    GameLogicNetWorkMgr:OnInit();

    print("Main Init End");
end

function Main_UnInit()
    print("Main UnInit Start");

    LUIManager:UnInit();

    GameLogicNetWorkMgr:UnInit();

    LUAPlayerDataMgr:UnInit();

    GameResMgr:UnInit();
    ResourceMgr:UnInit();

    print("Main UnInit End");
end

function Main_Tick(deltaSeconds)
    GameLogicNetWorkMgr:Tick(deltaSeconds)
end

--TODO delete
function Main_PostMsg(mgsId,...)
   LUIManager:PostMsg(mgsId,...);
end


-- function Main_NetMsg(type, msg, sz)
--    NetWorkMgr.Dispatch(type, msg, sz)
-- end