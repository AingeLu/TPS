require "UnLua"

local UIMatchReadyTips_C = Class()
local UIMatchBattleTypeEnums = require "UI/UIMatch/UIMatchBattleTypeEnums"

function UIMatchReadyTips_C:Initialize(Initializer)
end

function UIMatchReadyTips_C:PreConstruct(IsDesignTime)
end

function UIMatchReadyTips_C:Construct()

    --------------------------------
    --- 控件
    --------------------------------
    self.IconSlotMax = 3
    self.IconSlotTb =
    {
        [1] = self.Icon1_Img ,
        [2] = self.Icon2_Img ,
        [3] = self.Icon3_Img ,
    }


    ----------------------------------------------
    --- 数据
    ----------------------------------------------
    self.CurrState = UIMatchBattleTypeEnums.ReadyTipsState.None

    self.MatchStartTime = 0.0
    self.bMatch = false

    self.Cancel_Btn.OnClicked:Add(self, UIMatchReadyTips_C.OnClicked_Cancel_Btn)

    LUIManager:RegisterMsg("UIMatchReadyTips", Ds_UIMsgDefine.UI_SYSTEM_BEGIN_MATCH,
            function(...) self:OnGameCountDown(...) end)

    LUIManager:RegisterMsg("UIMatchReadyTips",Ds_UIMsgDefine.UI_SYSTEM_MATCH_CANCEL,
            function(...) self:OnCancelMatch(...) end)

    LUIManager:RegisterMsg("UIMatchReadyTips",Ds_UIMsgDefine.UI_SYSTEM_CHOOSE_HERO,
            function(...) self:OnEnterChooseHero(...) end)

    LUIManager:RegisterMsg("UIMatchReadyTips",Ds_UIMsgDefine.UI_SYSTEM_QUIT_MATCH_BATTLETYPE,
            function(...) self:OnQuitUIMatchBattleType(...) end)

    LUIManager:RegisterMsg("UIMatchReadyTips",Ds_UIMsgDefine.UI_SYSTEM_ENTER_MATCH_BATTLETYPE,
            function(...) self:OnEnterUIMatchBattleType(...) end)
end

function UIMatchReadyTips_C:Tick(MyGeometry, InDeltaTime)
    if self.bMatch then

        local uworld = self:GetWorld()
        if uworld == nil then
            return
        end

        --local currTime = uworld:GetTimeSeconds()
        local currTime = UE4.UGameplayStatics.GetTimeSeconds(self)

        local currCD = (currTime - self.MatchStartTime)

        currCD = math.modf(currCD)

        if currCD <= 0 then
            currCD = 0
        end

        if self.MatchCD_Text ~= nil then
            self.MatchCD_Text:SetText(currCD)
        end

        if self.MatchCD2_Text ~= nil then
            self.MatchCD2_Text:SetText(currCD)
        end
    end
end

----------------------------------------------
--- UI Event Callback
----------------------------------------------
function UIMatchReadyTips_C:OnClicked_Cancel_Btn()
    if self.bMatch then
        --GameLogicNetWorkMgr.GetNetLogicMsgHandler():OnC2sMatchCancelReq();
        LUAPlayerDataMgr:GetMatchDataMgr():OnC2sMatchCancelReq()
    else
        LUAPlayerDataMgr:GetMatchDataMgr():OnC2sTeamQuitReq()

        LUIManager:DestroyUI("UIMatchBattleType")

        LUIManager:DestroyUI("UIMatchReadyTips")
    end
end

----------------------------------------------
--- UI Mgs Callback
----------------------------------------------
function UIMatchReadyTips_C:OnEnterChooseHero()
    print("OnEnterChooseHero ... ")
    LUIManager:DestroyUI("UIMatchReadyTips")
    LUIManager:DestroyUI("UIMatchBattleType")
end

function UIMatchReadyTips_C:OnCancelMatch()
    print("OnCancelMatch ... ")
    LUIManager:DestroyUI("UIMatchReadyTips")

    if not LUIManager:IsInViewport("UIMatchBattleType") then
        print("IsInViewport DestroyUI UIMatchBattleType ...")
        LUIManager:DestroyUI("UIMatchBattleType")
    end
end

function UIMatchReadyTips_C:OnGameCountDown()
    print("OnGameCountDown ... ")

    local uworld = self:GetWorld()
    if uworld == nil then
        return
    end

    self.MatchStartTime = UE4.UGameplayStatics.GetTimeSeconds(self)
    --self.MatchStartTime = uworld:GetTimeSeconds()

    self.bMatch = true

    self:OnChangeState(UIMatchBattleTypeEnums.ReadyTipsState.InMatchBattleType)
end

function UIMatchReadyTips_C:OnChangeState(nextState)

    if self.CurrState == nextState then
        print("Change State Failed . nextState same to currState , self.CurrState :" , self.CurrState)
        return
    end

    self.CurrState = nextState

    if self.CurrState == UIMatchBattleTypeEnums.ReadyTipsState.InMatchBattleType then
        self:OnReflashCountDownMatchTips()
    elseif self.CurrState == UIMatchBattleTypeEnums.ReadyTipsState.OutMatchBattleType then
        self:OnReflashTeamGroupMatchTips()
    end
end

function UIMatchReadyTips_C:OnReflashCountDownMatchTips()
    self.TeamGroup_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.MatchCD_Text:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible);
end

function UIMatchReadyTips_C:OnReflashTeamGroupMatchTips()
    print("OnReflashTeamGroupMatchTips ...")
    self.TeamGroup_Cvs:SetVisibility(UE4.ESlateVisibility.Visible);
    self.MatchCD_Text:SetVisibility(UE4.ESlateVisibility.Hidden);

    self:OnReflashTeamGroup()
end

function UIMatchReadyTips_C:OnReflashTeamGroup()

    local aiconfig = LUAPlayerDataMgr:GetMatchDataMgr():GetPlayerSelectedLegion()

    local isHunter = Ds_BattleActorType.ACTORTYPE_SHOOTER == aiconfig

    if isHunter then
        local teamCtn = LUAPlayerDataMgr:GetMatchDataMgr():GetMatchTeamGroupPlayerCtn()
        local startPos = 1
        for i = 1, teamCtn do
            if i > 0 and i <= self.IconSlotMax then
                self.IconSlotTb[i].IconImg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)

                startPos = startPos + 1
            end
        end

        if startPos <= self.IconSlotMax then
            for i = startPos, self.IconSlotMax do
                self.IconSlotTb[i].IconImg:SetVisibility(UE4.ESlateVisibility.Hidden)
            end
        end

        if self.bMatch then
            self.StateDesc_Text:SetText("匹配中 ...")
            self.MatchCD2_Text:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
            self.StateDesc_Text:SetText("组队中 ...")
            self.MatchCD2_Text:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    else
        --- 怪物单独一人 ， 没有队伍
        local teamCtn = 1
        local startPos = 1
        for i = 1, teamCtn do
            if i > 0 and i <= self.IconSlotMax then
                self.IconSlotTb[i].IconImg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)

                startPos = startPos + 1
            end
        end

        if startPos <= self.IconSlotMax then
            for i = startPos, self.IconSlotMax do
                self.IconSlotTb[i].IconImg:SetVisibility(UE4.ESlateVisibility.Hidden)
            end
        end

        if self.bMatch then
            self.StateDesc_Text:SetText("匹配中 ...")
            self.MatchCD2_Text:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
            self.StateDesc_Text:SetText("组队中 ...")
            self.MatchCD2_Text:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    end
end

return UIMatchReadyTips_C
