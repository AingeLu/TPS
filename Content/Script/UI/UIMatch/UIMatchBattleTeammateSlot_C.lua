require "UnLua"
local UIMatchBattleTypeEnums = require "UI/Match/UIMatchBattleTypeEnums"

local UIMatchBattleTeammateSlot_C = Class()

--function UIMatchBattleTeammateSlot_C:Initialize(Initializer)
--end

--function UIMatchBattleTeammateSlot_C:PreConstruct(IsDesignTime)
--end

function UIMatchBattleTeammateSlot_C:Construct()
    ----------------------------------------------
    --- 控件
    ----------------------------------------------
    self.SlotFrameCvs_Tb = {}
    for i = 1, 4 do
        self.SlotFrameCvs_Tb[i] = self:GetWidgetFromName("SlotFrameCvs"..i);
    end

    --- 2 是房主用的面板
    --- 4 是非房主用的面板
    self.LastState = UIMatchBattleTypeEnums.TeamGroupSlotState.Empty
    self.CurrState = UIMatchBattleTypeEnums.TeamGroupSlotState.Empty

    self.bOpenMenu = false
    self.bEnableOpenMenu = true

    --[[--
        self.PlayerInfoData 中的数据

        message TeamInfo
        {
            required int32  uuid        = 1; // 玩家ID
            optional int32  pos         = 2; // 坐位号
            optional string name        = 3; // 名称
            optional bool   ready       = 4; // 准备标志
            optional bool   voice       = 5; // 是否开语音
            optional bool   mic         = 6; // 是否开麦克风
            optional int32  gender      = 7; // 性别
        }

        --LUAPlayerDataMgr:GetFriendDataMgr():OnC2sFetchNewFriendInfo()
    --]]

    self.PlayerInfoData = nil


    self.Invite_Btn.OnClicked:Add(self, UIMatchBattleTeammateSlot_C.OnClicked_Invite_Btn)
    self.OpenMenu_Btn.OnClicked:Add(self, UIMatchBattleTeammateSlot_C.OnClicked_OpenMenu_Btn)
    self.CloseMenu_Btn.OnClicked:Add(self, UIMatchBattleTeammateSlot_C.OnClicked_CloseMenu_Btn)
    self.CloseMenu2_Btn.OnClicked:Add(self, UIMatchBattleTeammateSlot_C.OnClicked_CloseMenu2_Btn)
    self.KickOutTeam_Btn.OnClicked:Add(self, UIMatchBattleTeammateSlot_C.OnClicked_KickOutTeam_Btn)
end

--function UIMatchBattleTeammateSlot_C:Tick(MyGeometry, InDeltaTime)
--end

function UIMatchBattleTeammateSlot_C:OnShowWindow(index)

    self.SlotIndex = index

    local TeamGroupData = LUAPlayerDataMgr:GetMatchDataMgr():GetMatchTeamGroupPlayerMembers()

    local myPlayerId = LUAPlayerDataMgr:GetPlayerID()

    local slotIndex = 1
    local bChangeState = false

    --- 不在队伍时候 , 清空所有槽位
    if TeamGroupData == nil then
        self:OnChangeState(UIMatchBattleTypeEnums.TeamGroupSlotState.Empty)
        return
    end

    for k, v in pairs(TeamGroupData) do
        if v.uuid ~= myPlayerId  then
            if slotIndex == self.SlotIndex then
                bChangeState = true

                self.PlayerInfoData = v

                self:OnChangeState(UIMatchBattleTypeEnums.TeamGroupSlotState.Teammate)
                break
            else
                slotIndex = slotIndex + 1
            end
        end
    end

    if not bChangeState then
        self:OnChangeState(UIMatchBattleTypeEnums.TeamGroupSlotState.Empty)
    end
end

---------------------------------------
--- UI Event Callback
---------------------------------------
function UIMatchBattleTeammateSlot_C:OnClicked_Invite_Btn()

    local isTeamLeader = LUAPlayerDataMgr:GetMatchDataMgr():IsTeamLeader()
    if not isTeamLeader then
        return
    end

    local bInMatchCD = LUAPlayerDataMgr:GetMatchDataMgr():IsInEnterChooseHeroCD()
    if bInMatchCD then
        return
    end

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_MATCH_INVITE_PLAYER , true)
end

function UIMatchBattleTeammateSlot_C:OnClicked_OpenMenu_Btn()
    self:OnClickedOpenAndCloseMenu(true)
end

function UIMatchBattleTeammateSlot_C:OnClicked_CloseMenu_Btn()
    self:OnClickedOpenAndCloseMenu(false)
end

function UIMatchBattleTeammateSlot_C:OnClicked_CloseMenu2_Btn()
    self:OnClickedOpenAndCloseMenu(false)
end

function UIMatchBattleTeammateSlot_C:OnClicked_KickOutTeam_Btn()
    if self.PlayerInfoData == nil then
        return
    end

    local isLeader = LUAPlayerDataMgr:GetMatchDataMgr():IsTeamLeader()
    if not isLeader then
        return
    end

    local kickPlayerID = self.PlayerInfoData.uuid

    LUAPlayerDataMgr:GetMatchDataMgr():OnC2sTeamKickReq(kickPlayerID)
end

function UIMatchBattleTeammateSlot_C:OnClickedOpenAndCloseMenu(bOpenMenu)
    print("OnClickedOpenAndCloseMenu ...")
    if not self.bEnableOpenMenu then
        return
    end

    self.bOpenMenu = bOpenMenu
    self:OnReflashMenuPanel()
end


--- 界面状态转换
---- @param UIMatchBattleTypeEnums.MatchBattleTypeState
function UIMatchBattleTeammateSlot_C:OnChangeState(NextState)
    if(self.CurrentState == NextState) then
        return
    end

    self.LastState = self.CurrentState
    self.CurrentState = NextState

    self:OnReflashStateUI()
end

function UIMatchBattleTeammateSlot_C:OnReflashStateUI()
    if self.CurrentState == UIMatchBattleTypeEnums.TeamGroupSlotState.Empty then
        print("self.CurrentState => UIMatchBattleTypeEnums.UIMatchTeamGroupSlot.None")
        self:OnReflashSlotEmpty()
    elseif self.CurrentState == UIMatchBattleTypeEnums.TeamGroupSlotState.Teammate then
        print("self.CurrentState => UIMatchBattleTypeEnums.UIMatchTeamGroupSlot.Teammate")
        self:OnReflashSlotTeammate()
    end
end

function UIMatchBattleTeammateSlot_C:OnReflashSlotEmpty()

    --- 清空槽位时候 ，重置菜单元素
    self.bOpenMenu = false
    self.bEnableOpenMenu = true

    self:OnReflashMenuPanel()

    self.SlotFrameCvs_Tb[1]:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.SlotFrameCvs_Tb[2]:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.SlotFrameCvs_Tb[4]:SetVisibility(UE4.ESlateVisibility.Hidden)

    self.SlotFrameCvs_Tb[3]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)

end

function UIMatchBattleTeammateSlot_C:OnReflashSlotTeammate()
    self.SlotFrameCvs_Tb[1]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SlotFrameCvs_Tb[2]:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.SlotFrameCvs_Tb[3]:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.SlotFrameCvs_Tb[4]:SetVisibility(UE4.ESlateVisibility.Hidden)

    self:OnReflashSlotInfo()
end

function UIMatchBattleTeammateSlot_C:OnReflashMenuPanel()
    local isLeader = LUAPlayerDataMgr:GetMatchDataMgr():IsTeamLeader()

    if self.bOpenMenu then
        self.OpenMenu_Btn:SetVisibility(UE4.ESlateVisibility.Hidden)

        if isLeader then
            self.SlotFrameCvs_Tb[2]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
            self.SlotFrameCvs_Tb[4]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
    else
        self.OpenMenu_Btn:SetVisibility(UE4.ESlateVisibility.Visible)

        if isLeader then
            self.SlotFrameCvs_Tb[2]:SetVisibility(UE4.ESlateVisibility.Hidden)
        else
            self.SlotFrameCvs_Tb[4]:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    end
end

function UIMatchBattleTeammateSlot_C:OnReflashSlotInfo()

    self.PlayerName_Text:SetText(self.PlayerInfoData.name)

    --- 性别
    UE4.UMGLuaUtils.UMG_Image_SetBrush(self.PlayerGender_Img , GetUIGenderImg(self.PlayerInfoData.gender))
end

--- 开关菜单功能
function UIMatchBattleTeammateSlot_C:SetOpenMenuSwitch(bEnableOpenMenu , bOpenMenu)
    self.bEnableOpenMenu = bEnableOpenMenu
    self.bOpenMenu = bOpenMenu

    self:OnReflashMenuPanel()
end

return UIMatchBattleTeammateSlot_C
