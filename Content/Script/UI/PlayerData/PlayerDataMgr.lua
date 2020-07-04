if LUAPlayerDataMgr ~= nil then
    return LUIPlayerDataMgr
end

LUAPlayerDataMgr = {}

local FriendDataMgr = require("UI/PlayerData/FriendDataMgr")
local MatchDataMgr = require("UI/PlayerData/MatchDataMgr")


-----------------------------------------
--- 数据
-----------------------------------------
function LUAPlayerDataMgr:OnInitData()
    self.AccountID = -1               -- 玩家账号ID
    self.PlayerRoleName = ""          -- 玩家角色名字
end


-----------------------------------------
--- 周期函数
-----------------------------------------
function LUAPlayerDataMgr:OnInit()
    self:OnInitData()

    if FriendDataMgr ~= nil then
        FriendDataMgr:OnInit(self)
    end

    if MatchDataMgr ~= nil then
        MatchDataMgr:OnInit(self)
    end

    print("LUIPlayerDataMgr.Init succ")
end

function LUAPlayerDataMgr:UnInit()

    if FriendDataMgr ~= nil then
        FriendDataMgr:UnInit()
    end

    if MatchDataMgr ~= nil then
        MatchDataMgr:UnInit()
    end

    print("LUIPlayerDataMgr.UnInit succ")
end

function LUAPlayerDataMgr:Tick(deltaSeconds)

    --if FriendDataMgr ~= nil then
    --    FriendDataMgr:Tick(deltaSeconds)
    --end

    --if MatchDataMgr ~= nil then
    --    MatchDataMgr:Tick(deltaSeconds)
    --end
end


------------------------------------------------
--- Getter 获取数据接口
------------------------------------------------
function LUAPlayerDataMgr:GetFriendDataMgr()
    return FriendDataMgr
end

function LUAPlayerDataMgr:GetMatchDataMgr()
    return MatchDataMgr
end

function LUAPlayerDataMgr:GetPlayerID()
    return self.AccountID
end

function LUAPlayerDataMgr:GetPlayerName()
    return self.PlayerRoleName
end


------------------------------------------------
--- Setter 设置数据接口
------------------------------------------------
function LUAPlayerDataMgr:SetPlayerID(playerID)
    self.AccountID = playerID
end

function LUAPlayerDataMgr:SetPlayerName(playerName)
    self.PlayerRoleName = playerName
end


return LUAPlayerDataMgr