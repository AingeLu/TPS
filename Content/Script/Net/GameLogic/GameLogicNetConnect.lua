
local GameLogicNetConnect = {}

GameLogicNetConnect.LogicNetConnectStatus =
{
    NONE = 0,
    CONNECTING = 1,
    CONNECT_SUCC = 2,
    CONNECT_RETRY = 3,
    CONNECT_RETRY_END = 4,
}

GameLogicNetConnect.LogicNetLoginStatus =
{
    NONE = 0,
    LOGIN_SUCC = 1,
}

local GameRealTimeSinceStartup = 0;

function GameLogicNetConnect:OnInit()
    print("GameLogicNetConnect.Init succ")

    ---- 连接端口号
    self.LoginPort = 6666
    ---- 连接地址
    self.LoginAddress = TArray(0)
    self.LoginAddress:Add(192)
    self.LoginAddress:Add(168)
    self.LoginAddress:Add(0)
    self.LoginAddress:Add(193)

    self.PingTime = 0.033         -- ping值
    self.PingTimes = 0            -- ping的次数
    self.SendPingTime = 0         -- 发送ping的时间
    self.RecvPingTime = 0         -- 接收ping的时间
    self.SendPingInterval = 5     -- 发送ping的间隔时间
    self.RunPingTimeOut = 10      -- 超时的时间
    self.LogicReconnectCnt = 0    -- 重连次数

    self.LastUpdateTime = 0
    self.CurrUpdateTime = 0

    --- 连接状态
    self:OnChangeLogicNetConnectState(self.LogicNetConnectStatus.NONE)
    self:OnChangeLogicNetLoginStatus(self.LogicNetLoginStatus.NONE)
end

function GameLogicNetConnect:UnInit()
    print("LUANetConnMgr.UnInit succ")

    self.Owner = nil
    self:OnChangeLogicNetConnectState(self.LogicNetConnectStatus.NONE)
    self:OnChangeLogicNetLoginStatus(self.LogicNetLoginStatus.NONE)
end

function GameLogicNetConnect:Tick(deltaSeconds)

    GameRealTimeSinceStartup = GameRealTimeSinceStartup + deltaSeconds;

    if self.CurrLogicNetConnectStatus ~= self.LogicNetConnectStatus.CONNECT_SUCC then
        return
    end

    if self.CurrLogicNetLoginStatus == self.LogicNetLoginStatus.LOGIN_SUCC then
        if GameRealTimeSinceStartup - self.SendPingTime >= self.SendPingInterval then
            --- Do Ping
            self.SendPingTime = GameRealTimeSinceStartup
            self.PingTimes = self.PingTimes + 1
            if self.PingTimes <= 1 then
                self.RecvPingTime = GameRealTimeSinceStartup
            end

            self:OnC2sPingReq(math.modf(self.SendPingTime * 1000))
        end
    end
end

function GameLogicNetConnect:OnChangeLogicNetConnectState(NextState)
    --print("OnChangeLogicNetConnectState : " , self.CurrLogicNetLoginStatus , " => " , NextState)
    self.CurrLogicNetConnectStatus = NextState
end

function GameLogicNetConnect:OnChangeLogicNetLoginStatus(NextState)
    --print("OnChangeLogicNetLoginStatus : " , self.CurrLogicNetLoginStatus , " => " , NextState)
    self.CurrLogicNetLoginStatus = NextState
end


-----------------------------------------
--- 外部接口
-----------------------------------------
function GameLogicNetConnect:OnStartConnect(LoginAddress, LoginPort)
    if self.CurrLogicNetConnectStatus ~= self.LogicNetConnectStatus.CONNECT_RETRY then
        self:OnChangeLogicNetConnectState(self.LogicNetConnectStatus.CONNECTING)
    end

    local newTArray = TArray(0)
    for i = 1, LoginAddress:Length() do
        local tempData = LoginAddress:Get(i)
        newTArray:Add(tempData)
    end

    NetMgr.Instance():ConnectSocket(newTArray, LoginPort);
end

function GameLogicNetConnect:GetLoginAddress()
    return self.LoginAddress
end

function GameLogicNetConnect:GetLoginPort()
    return self.LoginPort
end


-----------------------------------------
--- Connect Callback
-----------------------------------------

--- 连接成功
function GameLogicNetConnect:OnConnectedSuccess()

    if self.CurrLogicNetConnectStatus == self.LogicNetConnectStatus.CONNECT_RETRY then
        --- 重新登录
        --self:OnC2sLogicLoginReq(LUAPlayerDataMgr.AccountID)
    else
        LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_NETCONNECT_RET , 0)
    end

    self.LogicReconnectCnt = 0
    self:OnChangeLogicNetConnectState(self.LogicNetConnectStatus.CONNECT_SUCC)
end

function GameLogicNetConnect:OnConnectedFailed()
    --- self.CurrLogicNetConnectStatus = self.LogicNetConnectStatus.CONNECT_RETRY
end

function GameLogicNetConnect:OnResetLogicPing()
    self.PingTime = 0
    self.PingTimes = 0
    self.SendPingTime = GameRealTimeSinceStartup
    self.RecvPingTime = GameRealTimeSinceStartup
end

--- 连接失败
function GameLogicNetConnect:OnConnectedClose()
    self:OnChangeLogicNetConnectState(self.LogicNetConnectStatus.NONE)
    self:OnChangeLogicNetLoginStatus(self.LogicNetLoginStatus.NONE)
end


----------------------------------------
--- C2S
----------------------------------------
function GameLogicNetConnect:OnC2sLogicLoginReq(AccountID)


    local platformMarco = LuaMarcoUtils.GetPlatform()

    local osType = 1
    if platformMarco == PLATFORM_WINDOWS then
        osType = 1
    elseif platformMarco == PLATFORM_IOS then
        osType = 1
    elseif platformMarco == PLATFORM_ANDROID then
        osType = 2
    end

    GameLogicNetWorkMgr:SendMsg("client.c2s_login_req" , {
        Platform = "weixin",
        OpenID = AccountID,
        Token = "",
        ReConnect = 4,
        OSType = osType,
        ClientVersion = "1.0.0.1",
        JsonData = "",
        DevId = 0,
        CpuFirmVersion = "geforce1060",
        GpuFirmVersion = "Intel(R) Core(TM) i5-8400 CPU @ 2.80GHz",
        ProtocolVersion = 1,
    })
end

--OnLogicCreatePlayerReq

function GameLogicNetConnect:OnLogicCreatePlayerReq(accountID, token, name, nationID, gender)

    local platformMarco = LuaMarcoUtils.GetPlatform()

    local osType = 1
    if platformMarco == PLATFORM_WINDOWS then
        osType = 1
    elseif platformMarco == PLATFORM_IOS then
        osType = 1
    elseif platformMarco == PLATFORM_ANDROID then
        osType = 2
    end

    GameLogicNetWorkMgr:SendMsg("client.c2s_create_player_req" , {
        Platform = "weixin",
        OpenID = accountID,
        Token = token,
        ReConnect = 0,
        OSType = osType,
        ClientVersion = "1.0.0.1",
        Name = name,
        Country = nationID,
        JsonData = "",
        DevId = 0,
        Gender = gender,
        ProtocolVersion = 1,
    })
end

function GameLogicNetConnect:OnC2sPingReq(PingTime)
    GameLogicNetWorkMgr:SendMsg("client.c2s_ping_req" , { PingTime = PingTime })
end





----------------------------------------
--- S2C
----------------------------------------

--- 登录成功
---@param playerData PlayerData [message PlayerData {}]
function GameLogicNetConnect:OnS2cLogicLoginRsp(RetCode , reason ,playerData)

    if RetCode == 0 then
        print("Login Success ... ")
        self:OnChangeLogicNetLoginStatus(self.LogicNetLoginStatus.LOGIN_SUCC)

        if playerData ~= nil then
            LUAPlayerDataMgr:SetPlayerID(playerData.uuid)
            LUAPlayerDataMgr:SetPlayerName(playerData.name)
        else
            print("GameLogicNetConnect:OnS2cLogicLoginRsp Error , PlayerData is nil .")
        end

    else
        print("GameLogicNetConnect:OnS2cLogicLoginRsp reason :" , reason)
    end

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_LOGIN_RET , RetCode, reason)
end

function GameLogicNetConnect:OnS2cPingRsp(PingTime)

    self.PingTime = GameRealTimeSinceStartup * 1000 - PingTime
    self.RecvPingTime = GameRealTimeSinceStartup
end



return GameLogicNetConnect