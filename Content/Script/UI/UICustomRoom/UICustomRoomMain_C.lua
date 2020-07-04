require "UnLua"

---@type UUserWidget
local UICustomRoomMain_C = Class()

local CharacterNode_BP = "/Game/UI/UIMatch/UIMatchMainItem";

function UICustomRoomMain_C:Initialize(Initializer)
end

function UICustomRoomMain_C:OnInitialized()
    self.Overridden.OnInitialized(self)

    self.CreateRoom_btn.OnClicked:Add(self, UICustomRoomMain_C.OnClicked_CreateRoom_Btn)
    self.Close_btn.OnClicked:Add(self, UICustomRoomMain_C.OnClicked_Close_Btn)
    self.Entrance_btn.OnClicked:Add(self, UICustomRoomMain_C.OnClicked_Entrance_Btn)
    self.Refresh_btn.OnClicked:Add(self, UICustomRoomMain_C.OnClicked_Refresh_Btn)

    ---
    self.MatchItem = {}
    --

    self:OnInitMatchItemPool(10)
    --- UI Mgs

    LUIManager:RegisterMsg("UICustomRoomMain",Ds_UIMsgDefine.UI_SYSTEM_FETCH_CUSTEM_DATA,
            function(...) self:OnRefreshMatchItem(...) end)

    LUIManager:RegisterMsg("UICustomRoomMain",Ds_UIMsgDefine.UI_SYSTEM_CUSTEM_ROOM_DATA,
            function(...) self:CreateRoomRsp(...) end)

    --LUIManager:RegisterMsg("UICustomRoomMain",Ds_UIMsgDefine.UI_SYSTEM_CUSTEM_ROOM_DATA,
    --        function(...) self:CreateRoomRsp(...) end)

    --UI_SYSTEM_MATCH_SYCN_ROOM_TEAM
end

function UICustomRoomMain_C:PreConstruct(IsDesignTime)
    self.Overridden.PreConstruct(self, IsDesignTime)
end

function UICustomRoomMain_C:Construct()
    self.Overridden.Construct(self)

    self:OnRefreshMatchItem()
end

function UICustomRoomMain_C:Destruct()
    self.Overridden.Destruct(self)
end

--function UICustomRoomMain_C:Tick(MyGeometry, InDeltaTime)
--end

----------------------------------------------
--- UI Event Callback
----------------------------------------------
function UICustomRoomMain_C:OnClicked_CreateRoom_Btn()

    local vsmode = Ds_BattleVsMode.BATTLEVSMODE_CUSTOM
    local aiconfig = Ds_BattleActorType.ACTORTYPE_SHOOTER
    local mapid = 1001

    LUAPlayerDataMgr:GetMatchDataMgr():OnC2sPrepareBattleReq(vsmode ,aiconfig, mapid)
end

function UICustomRoomMain_C:OnClicked_Close_Btn()
    print("UICustomRoomMain_C:OnClicked_Close_Btn ...")

    LUIManager:DestroyWindow("UICustomRoomMain");

    LUIManager:ShowWindow("UIMainEnterMain")
end

function UICustomRoomMain_C:OnClicked_Entrance_Btn()

end

function UICustomRoomMain_C:OnClicked_Refresh_Btn()

    LUAPlayerDataMgr:GetMatchDataMgr():OnC2sFetchCustomRoomInfoReq()
end

----------------------------------------------
--- UI Mgs Callback
----------------------------------------------

function UICustomRoomMain_C:CreateRoomRsp()
    print("UICustomRoomMain_C:CreateRoomRsp() ... ")

    LUIManager:ShowWindow("UICustomRoom");
end

function UICustomRoomMain_C:OnInitMatchItemPool(initNum)
    if initNum <= 0 then
        return
    end

    for i = 1, initNum do
        local parts_ui_class = UE4.UClass.Load(CharacterNode_BP)

        if parts_ui_class ~= nil then
            local widget = UE4.UWidgetBlueprintLibrary.Create(self, parts_ui_class)

            self.MatchItem[i] = widget;
        end
    end
end


function UICustomRoomMain_C:OnRefreshMatchItem()

    local dataNum = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomNum()
    local matchItemAllNum = #self.MatchItem;
    local scrollBox = self.ScrollBoxContent

    if scrollBox == nil then
        return
    end

    for i = 1, matchItemAllNum do

        local matchItem = self.MatchItem[i];

        if matchItem ~= nil then

            if i > dataNum then

                if scrollBox:HasChild(matchItem) then
                    matchItem:SetVisibility(UE4.ESlateVisibility.Hidden)
                    scrollBox:RemoveChildAt(i)
                end

            else
                local customRoomInfoData = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomInfoByIndex(i)

                if customRoomInfoData ~= nil then

                    if scrollBox:HasChild(matchItem) then
                        matchItem:OnRefreshCustomRoomInfoItem(customRoomInfoData)
                        matchItem:SetVisibility(UE4.ESlateVisibility.Visible)
                    else
                        self.ScrollBoxContent:AddChild(matchItem);
                        matchItem:OnRefreshCustomRoomInfoItem(customRoomInfoData)
                        matchItem:SetVisibility(UE4.ESlateVisibility.Visible)
                    end

                else

                    print("customRoomInfoData is nil . index :" , i)
                end
            end
        end
    end

    if dataNum > matchItemAllNum then

        for i = matchItemAllNum, dataNum do

            local parts_ui_class = UE4.UClass.Load(CharacterNode_BP)

            if parts_ui_class ~= nil then
                local widget = UE4.UWidgetBlueprintLibrary.Create(self, parts_ui_class)

                self.MatchItem[i] = widget;
            end

            local matchItem = self.MatchItem[i]
            local customRoomInfoData = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomInfoByIndex(i)

            if customRoomInfoData ~= nil then
                self.ScrollBoxContent:AddChild(matchItem);
                matchItem:OnRefreshCustomRoomInfoItem(customRoomInfoData)
                matchItem:SetVisibility(UE4.ESlateVisibility.Visible)
            end
        end
    end

end

return UICustomRoomMain_C