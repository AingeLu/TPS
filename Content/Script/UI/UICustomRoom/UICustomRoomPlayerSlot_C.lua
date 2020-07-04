require "UnLua"

---@type UUserWidget
local UICustomRoomPlayerSlot_C = Class()

function UICustomRoomPlayerSlot_C:Initialize(Initializer)
end

function UICustomRoomPlayerSlot_C:OnInitialized()
    self.Overridden.OnInitialized(self)



    --LUIManager:RegisterMsg("UICustomRoomPlayerSlot_C",Ds_UIMsgDefine.UI_SYSTEM_NETCONNECT_RET,
    --        function(...) self:OnConnectRet(...) end)
end

function UICustomRoomPlayerSlot_C:PreConstruct(IsDesignTime)
    self.Overridden.PreConstruct(self, IsDesignTime)
end

function UICustomRoomPlayerSlot_C:Construct()
    self.Overridden.Construct(self)

    self.ComeOut1_btn.OnClicked:Add(self, UICustomRoomPlayerSlot_C.OnClick_KickOutRoom)
end

function UICustomRoomPlayerSlot_C:Destruct()
    self.Overridden.Destruct(self)
end

function UICustomRoomPlayerSlot_C:Tick(MyGeometry, InDeltaTime)

end

function UICustomRoomPlayerSlot_C:OnClick_KickOutRoom()

    --print("pos index :" , self.PosIndex)

    local roomID = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomID()
    local roomRemainder = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomRemainder()

    LUAPlayerDataMgr:GetMatchDataMgr():OnC2sKickCustomRoomReq(roomID , self.PosIndex , roomRemainder)
end

--function UICustomRoomPlayerSlot_C:OnClicked_TestBtn()
--  print("OnClicked_TestBtn ...")
--    LUIManager:ShowWindow("UIMainEnterMain")
--end

----------------------------------------------
--- 外部接口
----------------------------------------------

---@param data CustomRoomMember in pb
--[[

message CustomRoomMember
{
    optional int32  uuid = 1;
    optional string name = 2;
}

--]]
function UICustomRoomPlayerSlot_C:OnRefreshPlayerInfo(data , pos_index)
    self.PlayerSlotData = nil
    self.PlayerSlotData = data
    self.PosIndex = pos_index

    if self.PlayerSlotData == nil then
        return
    end

    self:OnRefreshPlayerSlotUI()
end

function UICustomRoomPlayerSlot_C:OnRefreshPlayerSlotUI()

    if self.PlayerSlotData.uuid == nil or self.PlayerSlotData.uuid <= 0 then
        self:SetSlotClear()
        return
    end

    self.PlayerDataSlot_Cvs:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PlayName1_txt:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ComeOut1_btn:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.Change1_btn:SetVisibility(UE4.ESlateVisibility.Hidden)

    self.PlayName1_txt:SetText(self.PlayerSlotData.name)
end

function UICustomRoomPlayerSlot_C:SetSlotClear()
    --self.PlayerDataSlot_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.PlayName1_txt:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.ComeOut1_btn:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.Change1_btn:SetVisibility(UE4.ESlateVisibility.Hidden)
end

return UICustomRoomPlayerSlot_C