require "UnLua"

---@type UIBattleTopLeft_C
local UIBattleTopLeft_C = class()
local KillMsgNode_BP = "/Game/UI/UIBattle/UIBattleMain/KillMsg";

function UIBattleTopLeft_C:OnInitialized(ownerWidget)
    self.ownerWidget = ownerWidget
    self.MaxSlotNum = 3
end

function UIBattleTopLeft_C:PreConstruct(IsDesignTime)

end

function UIBattleTopLeft_C:Construct()

end

function UIBattleTopLeft_C:OnShowWindow()

end

function UIBattleTopLeft_C:OnHideWindow()

end

function UIBattleTopLeft_C:Destruct()

end

function UIBattleTopLeft_C:Tick(MyGeometry, InDeltaTime)
    self.CurBoxChildrenCount = self.ownerWidget.KillMsg_ScrollBox:GetChildrenCount()
    if self.CurBoxChildrenCount > self.MaxSlotNum then
        self:OnRefreshScrollOffset()
    end
end

function UIBattleTopLeft_C:TickPerSec(MyGeometry, InDeltaTime)

end

function UIBattleTopLeft_C:OnPlayerBeKillDown(KillerPlayerState, BeKillerPlayerState)

    if KillerPlayerState ~= nil and BeKillerPlayerState ~= nil then
        self:OnRefreshKillInformation(KillerPlayerState, BeKillerPlayerState)
    end

end

--- 刷新击杀消息
function UIBattleTopLeft_C:OnRefreshKillInformation(KillerPlayerState, BeKillerPlayerState)
    local KillMsgWidget = self:CreateKillMsgWidget()
    if KillMsgWidget ~= nil then

        KillMsgWidget.KillerName_Text:SetText(KillerPlayerState:GetRuntimePlayerName())
        KillMsgWidget.BeKillerName_Text:SetText(BeKillerPlayerState:GetRuntimePlayerName())
        
        KillMsgWidget:SetSlateColor()

        local myTeamID = self.ownerWidget:GetMyTeamID()
        if myTeamID == KillerPlayerState:GetTeamID() then    --击杀者是队友
           KillMsgWidget.KillerName_Text:SetColorAndOpacity(KillMsgWidget.Blue_SlateColor)
           KillMsgWidget.BeKillerName_Text:SetColorAndOpacity(KillMsgWidget.Red_SlateColor)
        else
           KillMsgWidget.KillerName_Text:SetColorAndOpacity(KillMsgWidget.Red_SlateColor)
           KillMsgWidget.BeKillerName_Text:SetColorAndOpacity(KillMsgWidget.Blue_SlateColor)
        end
        self.ownerWidget.KillMsg_ScrollBox:AddChild(KillMsgWidget)
    end

     local coDelayRemoveChild = coroutine.create(UIBattleTopLeft_C.DelayRemoveChild)
     coroutine.resume(coDelayRemoveChild, self.ownerWidget, KillMsgWidget)

end

--- 延迟删除子节点
function UIBattleTopLeft_C:DelayRemoveChild(KillMsgWidget)
    UE4.UKismetSystemLibrary.Delay(self, 6)
    if self.KillMsg_ScrollBox:HasChild(KillMsgWidget) then
        self.KillMsg_ScrollBox:RemoveChild(KillMsgWidget)
    end 
end

function UIBattleTopLeft_C:CreateKillMsgWidget()
    local KillMsg_class = UE4.UClass.Load(KillMsgNode_BP)

    if KillMsg_class ~= nil then
        local Widget = UE4.UWidgetBlueprintLibrary.Create(self.ownerWidget, KillMsg_class)
        return Widget
    end
end

--- 刷新滚动
function UIBattleTopLeft_C:OnRefreshScrollOffset()

    local CurrentTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self.ownerWidget:GetWorld())
    local ControllerBase = self.ownerWidget:GetPlayerController()
    if ControllerBase == nil then
        print("UIBattleTopLeft_C:OnRefreshScrollOffset Error: ControllerBase is nil .")
        return
    end
    local LastKillTime = ControllerBase:GetLastKillPlayerTime()
    local DeltaTime = CurrentTime - LastKillTime
    local FadeTime = 0.5
    if DeltaTime >= 0 and DeltaTime <= FadeTime then  
        local ScrollOffset =  22.1737499 * math.min(1.0, DeltaTime / FadeTime)
        self.ownerWidget.KillMsg_ScrollBox:SetScrollOffset(ScrollOffset)
    end

end

return UIBattleTopLeft_C