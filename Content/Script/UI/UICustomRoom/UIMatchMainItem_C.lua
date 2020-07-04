require "UnLua"

---@type UUserWidget
local UIMatchMainItem_C = Class()

function UIMatchMainItem_C:Initialize(Initializer)
end

function UIMatchMainItem_C:OnInitialized()
    self.Overridden.OnInitialized(self)

    --self.DebugBtn.OnClicked:Add(self, BP_Test_C.OnClicked_TestBtn)

    --LUIManager:RegisterMsg("UIMatchMainItem_C",Ds_UIMsgDefine.UI_SYSTEM_NETCONNECT_RET,
    --        function(...) self:OnConnectRet(...) end)
end

function UIMatchMainItem_C:PreConstruct(IsDesignTime)
    self.Overridden.PreConstruct(self, IsDesignTime)
end

function UIMatchMainItem_C:Construct()
    self.Overridden.Construct(self)
end

function UIMatchMainItem_C:Destruct()
    self.Overridden.Destruct(self)
end

--function UIMatchMainItem_C:Tick(MyGeometry, InDeltaTime)
--end


--[[
    data  数据

    message CostomRoomBaseInfo
    {
        optional int32 room_id = 1;
        optional int32 remainder = 2;
        optional int32 leader_uuid = 3;
        optional int32 map_id = 4;
        optional string leader_name = 5;
    }

]]--

function UIMatchMainItem_C:OnRefreshCustomRoomInfoItem(data)
    print("|| OnRefreshCustomRoomInfoItem ...")
    if data == nil then
        return
    end

    self.ItemData = data

    self:OnReflashUI()
end

function UIMatchMainItem_C:OnReflashUI()

    self.MatchRoomName_txt:SetText(self.ItemData.leader_name)
    self.MatchRoomId_txt:SetText(self.ItemData.room_id)

    self.MatchRoomStateWait_txt:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.MatchRoomStateGame_txt:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible);
end


--function UIMatchMainItem_C:OnClicked_TestBtn()
--  print("OnClicked_TestBtn ...")
--    LUIManager:ShowWindow("UIMainEnterMain")
--end

return UIMatchMainItem_C