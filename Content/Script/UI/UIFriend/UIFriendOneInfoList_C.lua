require "UnLua"

local UIFriendOneInfoList_C = Class()

--function UIFriendOneInfoList_C:Initialize(Initializer)
--end

--function UIFriendOneInfoList_C:PreConstruct(IsDesignTime)
--end

function UIFriendOneInfoList_C:Construct()

    self.EventStateEunms =
    {
        Invite = 1 ,
        InGame = 2 ,
        Free = 3 ,
        Invited = 4,
        offline = 5
    }

    self.InviteState_Tb = {}
    for i = 1, 5 do
        self.InviteState_Tb[i] = self:GetWidgetFromName("PlayerState"..i)
    end

    self.InviteState_Tb[1].OnClicked:Add(self, UIFriendOneInfoList_C.OnClicked_Invited_Btn)
end

--function UIFriendOneInfoList_C:Tick(MyGeometry, InDeltaTime)
--end

function UIFriendOneInfoList_C:OnShowWindow(ElementItemData)

    self.ElementItemData = ElementItemData

    self:OnReflashUI()
end

function UIFriendOneInfoList_C:OnClicked_Invited_Btn()

    if self.ElementItemData == nil then
        return
    end

    LUAPlayerDataMgr:GetMatchDataMgr():OnC2sTeamInviteReq(self.ElementItemData.uuid , 0)
end

function UIFriendOneInfoList_C:OnReflashUI()

    if self.ElementItemData == nil then
        return
    end

    self:SetPlayerName()
    self:SetGenderUI()
    self:SetOnlineState()
end

function UIFriendOneInfoList_C:SetPlayerName()
    --- 玩家名字
    self.PlayerName_Text:SetText(self.ElementItemData.name)
end

function UIFriendOneInfoList_C:SetGenderUI()
    --- 玩家性别
    if self.ElementItemData.gender == 1 then
        self.PlayerMale_Img:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.PlayerFemale_Img:SetVisibility(UE4.ESlateVisibility.Hidden)
    else
        self.PlayerMale_Img:SetVisibility(UE4.ESlateVisibility.Hidden)
        self.PlayerFemale_Img:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
end

function UIFriendOneInfoList_C:SetOnlineState()

    if self.ElementItemData.online then

        if self.ElementItemData.state == Ds_BasicState.BASICSTATE_LOBBY then
            self:SetPlayerState(self.EventStateEunms.Invite)
        elseif self.ElementItemData.state == Ds_BasicState.BASICSTATE_QUEUE then
            self:SetPlayerState(self.EventStateEunms.InGame)
        elseif self.ElementItemData.state == Ds_BasicState.BASICSTATE_ROOM then
            self:SetPlayerState(self.EventStateEunms.InGame)
        elseif self.ElementItemData.state == Ds_BasicState.BASICSTATE_BATTLE then
            self:SetPlayerState(self.EventStateEunms.InGame)
        elseif self.ElementItemData.state == Ds_BasicState.BASICSTATE_BATTLE_AWARD then
            self:SetPlayerState(self.EventStateEunms.InGame)
        end
    else
        self:SetPlayerState(self.EventStateEunms.offline)
    end
end

function UIFriendOneInfoList_C:SetPlayerState(state)

    for i = 1, #self.InviteState_Tb do
        self.InviteState_Tb[i]:SetVisibility(UE4.ESlateVisibility.Hidden)
    end

    if self.InviteState_Tb[state] ~= nil then

        self.InviteState_Tb[state]:SetVisibility(UE4.ESlateVisibility.Visible)
    end
end


return UIFriendOneInfoList_C
