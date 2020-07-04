require "UnLua"

---@type UUserWidget
local UIBattleTopMid_C = class()

function UIBattleTopMid_C:OnInitialized(ownerWidget)
    self.ownerWidget = ownerWidget
    
    
    --self.DebugBtn.OnClicked:Add(self, BP_Test_C.OnClicked_TestBtn)
    -- 持续击杀时间
    self.ContinueKillTime = 0
    -- 持续杀敌数
    self.ContinueKillNum = 0
    -- 当前显示的击杀图标数
    self.CurKillIconNum = 0
end

function UIBattleTopMid_C:PreConstruct(IsDesignTime)
end

function UIBattleTopMid_C:Construct()

    ----------------------------------------------------------------------
    --- UI 控件
    ----------------------------------------------------------------------
    --- 红蓝队伍存活人数 UI
    self.TeamBlueAliveGlow_Tb = {}
    self.TeamRedAliveGlow_Tb = {}
    self.MaxTeamNum = 5
    for i = 1, self.MaxTeamNum do
        self.TeamBlueAliveGlow_Tb[i] =  self.ownerWidget:GetWidgetFromName("TeamBlueAliveGlow_"..i.."_Image")
        self.TeamRedAliveGlow_Tb[i] =  self.ownerWidget:GetWidgetFromName("TeamRedAliveGlow_"..i.."_Image")
    end

    ----------------------------------------------------------------------
    --- 初始化 UI
    ----------------------------------------------------------------------
    --- 重生状态
    self.bRespawnAction = false

    ----------------------------------------------------------------------
    --- 初始化 UI
    ----------------------------------------------------------------------
    --------------------------------------
    --- 控件
    --------------------------------------
    ----- 武器装备 UI 控件

    ----------------------------------------------------------------------
    --- UI 控件
    ----------------------------------------------------------------------
    self.MaxKillIconNum = 4
    self.KillIconTb = {}
    for i = 1, self.MaxKillIconNum do
        self.KillIconTb[i] = {}
        self.KillIconTb[i].UIjisha = self.ownerWidget:GetWidgetFromName("UIjisha_"..i)
        self.KillIconTb[i].CurShowTime = 0
        self.KillIconTb[i].Visible = false
        self.KillIconTb[i].Index = 0
    end

    -- UI动画表
    self.AnimTb = {[1] = 0,[2] = 2,[3] = 3,[4] = 1,[5] = 4,[6] = 5}

end

function UIBattleTopMid_C:Destruct()
    self.TeamBlueAliveGlow_Tb = nil
    self.TeamRedAliveGlow_Tb = nil
    self.KillIconTb = nil
    self.AnimTb = nil
end

function UIBattleTopMid_C:Tick(MyGeometry, InDeltaTime)

    ----- 击杀刷新数据有些延迟暂时放这
    --self:OnRefreshPlayerBeKill()

    --- 重生 UI刷新
    self:OnRefreshPlayerRespawnUI()

    --- 击败 UI刷新
    self:OnRefreshKillIconShowNum() 
    --self:OnRefreshPlayerAliveNum()

end

function UIBattleTopMid_C:TickPerSec(MyGeometry, InDeltaTime)
    self:OnRefreshMatchCountDown()

    self:OnRefreshKillIconShowTime()

    self:OnRefreshContinueKill()

end

function UIBattleTopMid_C:OnShowWindow()
    self:OnRefreshPlayerAliveNum()
end

function UIBattleTopMid_C:OnHideWindow()

end


---------------------------------------------------
--- UI Event
---------------------------------------------------
function UIBattleTopMid_C:BattleGamePlayStart()
    print("UIBattleTopMid_C:BattleGamePlayStart() UI_BATTLE_LEVEL_START ...")
    self:OnRefreshGamePlayMatchInfo()
end

function UIBattleTopMid_C:OnBattleLevelMatchDataChange()
    self:OnRefreshMatchScore()
    self:OnRefreshPlayerBeKill()
end

function UIBattleTopMid_C:OnBattleCharacterRespawn()
    self.bRespawnAction = false
    print("|| OnBattleCharacterRespawn ...")
    self:OnRefreshPlayerAliveNum()
    self:OnRefreshPlayerBeKill()
end

function UIBattleTopMid_C:OnPlayerBeKillDown(KillerPlayerState, BeKillerPlayerState)
    print("|| OnPlayerBeKillDown ... ...")

    if KillerPlayerState ~= nil and BeKillerPlayerState ~= nil then
        self:OnPlayKillSound(KillerPlayerState, BeKillerPlayerState)
        self:OnPopUpDefeatMsg(KillerPlayerState, BeKillerPlayerState)
    end

    self:OnRefreshPlayerAliveNum()

end

---------------------------------------------------
--- 辅助函数
---------------------------------------------------
--- 刷新计时
function UIBattleTopMid_C:OnRefreshMatchCountDown()
    if self.ownerWidget == nil then
        return
    end

    local gameState = self.ownerWidget:GetPlayerGameState()
    if gameState == nil then
        print("Warning:UIBattleTopMid_C:OnRefreshMatchCountDown() gameState is nil .")
        return
    end

    local currTime = UE4.UGameplayStatics.GetTimeSeconds(self.ownerWidget)
    local remainTime = gameState:GetRemainTime()

    local remainMinTime = math.modf(remainTime / 60)
    local remainSecTime = math.modf(math.fmod(remainTime  ,60))

    remainMinTime = self:AddTimerZero(remainMinTime)
    remainSecTime = self:AddTimerZero(remainSecTime)

    self.ownerWidget.MatchTime_Text:SetText(remainMinTime .. ":" .. remainSecTime)
end

function UIBattleTopMid_C:OnRefreshPlayerAliveNum()
    if self.ownerWidget == nil then
        return
    end

    local myTeamID = self.ownerWidget:GetMyTeamID()
    local enemyTeamID = self.ownerWidget:GetEnemyID()

    local gameState = self.ownerWidget:GetPlayerGameState()
    if gameState == nil then
        return
    end

    self:OnRefreshRedAliveTeamUI(gameState:GetPlayerAliveByTeamID(enemyTeamID))
    self:OnRefreshBlueAliveTeamUI(gameState:GetPlayerAliveByTeamID(myTeamID))
end

--- 刷新比分
function UIBattleTopMid_C:OnRefreshMatchScore()
    if self.ownerWidget == nil then
        return
    end

    local gameState = self.ownerWidget:GetPlayerGameState()
    if gameState == nil then
        print("Warning:UIBattleTopMid_C:OnRefreshMatchScore() gameState is nil .")
        return
    end

    local myTeamData = gameState:GetTeamStateMatchDataByTeamID(self.ownerWidget:GetMyTeamID())
    local EnemyTeamData = gameState:GetTeamStateMatchDataByTeamID(self.ownerWidget:GetEnemyID())

    if myTeamData ~= nil then
        self.ownerWidget.MyTeamScore_Text:SetText(myTeamData.Score)
    end

    if EnemyTeamData ~= nil then
        self.ownerWidget.EnemyScore_Text:SetText(EnemyTeamData.Score)
    end
end

--- 刷新上方得分计数
function UIBattleTopMid_C:OnRefreshGamePlayMatchInfo()
    self:OnRefreshMatchCountDown()
    self:OnRefreshMatchScore()
end

--- 存活人数 蓝队 UI
function UIBattleTopMid_C:OnRefreshBlueAliveTeamUI(num)
    if num < 0 then
        return
    end

    if self.MaxTeamNum < num then
        num = self.MaxTeamNum
    end

    for i = 1, #self.TeamBlueAliveGlow_Tb do
        if i <= num then
            self.TeamBlueAliveGlow_Tb[i]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
            self.TeamBlueAliveGlow_Tb[i]:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    end
end

--- 存活人数 红队 UI
function UIBattleTopMid_C:OnRefreshRedAliveTeamUI(num)
    if num < 0 then
        return
    end

    if self.MaxTeamNum < num then
        num = self.MaxTeamNum
    end

    for i = 1, #self.TeamRedAliveGlow_Tb do
        if i <= num then
            self.TeamRedAliveGlow_Tb[i]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
            self.TeamRedAliveGlow_Tb[i]:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    end

end


--- 角色被杀 【操作面板开关】
function UIBattleTopMid_C:OnRefreshPlayerBeKill()

    if self.ownerWidget ~= nil then
        local runAttrData = self.ownerWidget:GetMyRuntimeAttrData()
        if runAttrData ~= nil then
            if runAttrData.CharacterStatus == ECharacterStatus.ECharacterStatus_DYING then
                self.bRespawnAction = true
                self.ownerWidget:SetBattleMainControlPanelEnable(false)
            elseif runAttrData.CharacterStatus == ECharacterStatus.ECharacterStatus_ALIVE then
                self.bRespawnAction = false
                self.ownerWidget:SetBattleMainControlPanelEnable(true)
            end
        end
    end
end

--- 角色复活
function UIBattleTopMid_C:OnRefreshPlayerRespawnUI()

    if self.ownerWidget ~= nil then
        local playState = self.ownerWidget:GetPlayerState()
        local myPlayerID = self.ownerWidget:GetMyPlayerID()

        if playState ~= nil and myPlayerID == playState:GetPlayerID() then
            local runAttrData = playState:GetRuntimeAttrData()
            if runAttrData ~= nil then
                self:OnRefreshRespawnUI(playState , self.bRespawnAction)
            end
        end
    end
end

--- 刷新重生进度条
function UIBattleTopMid_C:OnRefreshRespawnUI(playState , isRespawn)
    if playState == nil then
        return
    end

    if isRespawn then
        self.ownerWidget.RespawnPanel_CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
        self.ownerWidget.RespawnPanel_CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
        return
    end

    local deadTime = playState:GetLastDeadTime()
    local currTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self.ownerWidget)
    local respawnTime = playState:GetRespawnNeedTime()
    local timeDisplay = math.modf(currTime - deadTime)

    self.ownerWidget.RespawnTimeNum_Text:SetText(timeDisplay)

    self.ownerWidget.RespawnTime_ProgressBar:SetPercent((currTime - deadTime) / respawnTime)
end

--- 添加 0字符
function UIBattleTopMid_C:AddTimerZero(time)
    if time < 10 then
        return "0" .. time
    end

    return time
end

function UIBattleTopMid_C:OnPlayKillSound(KillerPlayerState, BeKillerPlayerState)
    if KillerPlayerState:GetPlayerID() == self.ownerWidget:GetMyPlayerID() then  
        self.ownerWidget:PlayKillSound()
    end
end

---弹出击败消息
function UIBattleTopMid_C:OnPopUpDefeatMsg(KillerPlayerState, BeKillerPlayerState)  
    
    if KillerPlayerState:GetPlayerID() == self.ownerWidget:GetMyPlayerID() then
        
        for i = 1, self.MaxKillIconNum do
            if self.KillIconTb[i].Visible == true then
                self.KillIconTb[i].Index  = UE4.math.min(self.MaxKillIconNum,self.KillIconTb[i].Index + 1 )
                local index = self.AnimTb[self.KillIconTb[i].Index]
                self.KillIconTb[i].UIjisha:OnStartPlayAnimationFowardByIndex(index)
            end
        end

        self:RefreshNewKillIcon()
    end
end

function UIBattleTopMid_C:RefreshNewKillIcon()

    if self.ownerWidget == nil then
        return
    end

    local gameState = self.ownerWidget:GetPlayerGameState()
    if gameState == nil then
        print("Warning:UIBattleTopMid_C:CreatNewKillIcon() gameState is nil .")
        return
    end

    local myTeamData = gameState:GetTeamStateMatchDataByTeamID(self.ownerWidget:GetMyTeamID())
    local EnemyTeamData = gameState:GetTeamStateMatchDataByTeamID(self.ownerWidget:GetEnemyID())
    ---myTeamData.Score,EnemyTeamData.Score

    for i = 1, self.MaxKillIconNum do
        if self.KillIconTb[i].Visible == false then
            self.KillIconTb[i].UIjisha:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            local count = self:CalculateKillCount()
            self.KillIconTb[i].Visible = true
            self.KillIconTb[i].Index  = UE4.math.min(self.MaxKillIconNum,self.KillIconTb[i].Index + 1 )
            local index = self.AnimTb[self.KillIconTb[i].Index]
            self.KillIconTb[i].UIjisha:OnStartPlayAnimationFowardByIndex(index)
            self.CurKillIconNum = self.CurKillIconNum + 1

            self.ownerWidget:PlayKillIconStartSound()
            self.KillIconTb[i].UIjisha.StartEffect_flibook:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.KillIconTb[i].UIjisha.StartEffect_flibook:PlayAnimation(false,true)
            return
        end  
    end
end

-- 刷新击杀图标显示时间 
function UIBattleTopMid_C:OnRefreshKillIconShowTime()
    for i = 1, self.MaxKillIconNum do  
        if self.KillIconTb[i].Visible == true and self.KillIconTb[i].CurShowTime == 3 then
            self.KillIconTb[i].CurShowTime = 0
            self.KillIconTb[i].Visible = false    
            local index = self.AnimTb[UE4.math.min(6,self.KillIconTb[i].Index + 3)]
            self.KillIconTb[i].UIjisha:OnStartPlayAnimationFowardByIndex(index)
            self.KillIconTb[i].Index = 0
            self.CurKillIconNum = self.CurKillIconNum - 1
            self.ownerWidget:PlayKillIconEndSound()
            self.KillIconTb[i].UIjisha.EndEffect_flibook:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.KillIconTb[i].UIjisha.EndEffect_flibook:PlayAnimation(false,true)
        elseif self.KillIconTb[i].Visible then
            self.KillIconTb[i].CurShowTime = self.KillIconTb[i].CurShowTime + 1
        end
    end
end

-- 刷新击杀图标显示数量
function UIBattleTopMid_C:OnRefreshKillIconShowNum()
    if self.CurKillIconNum == self.MaxKillIconNum then
        for i = 1, self.MaxKillIconNum do
            if self.KillIconTb[i].Visible == true and self.KillIconTb[i].Index == self.MaxKillIconNum then
                self.KillIconTb[i].UIjisha:OnStartPlayAnimationFowardByIndex(5)
                self.KillIconTb[i].CurShowTime = 0
                self.KillIconTb[i].Visible = false
                self.KillIconTb[i].Index = 0
                self.CurKillIconNum = self.CurKillIconNum - 1
            end
        end
    end
end 

function UIBattleTopMid_C:CalculateKillCount()
    self.ContinueKillTime = 0
    if self.ContinueKillTime <= 5 then
        self.ContinueKillNum = self.ContinueKillNum + 1
    end
    return self.ContinueKillNum
end

--刷新持续击杀
function UIBattleTopMid_C:OnRefreshContinueKill()
    self.ContinueKillTime = self.ContinueKillTime + 1 
    if self.ContinueKillTime > 5 then
        self.ContinueKillNum = 0
    end
end

return UIBattleTopMid_C