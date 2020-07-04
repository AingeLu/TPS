require "UnLua"

---@type UUserWidget
local UICustomRoom_C = Class()

function UICustomRoom_C:Initialize(Initializer)

end

function UICustomRoom_C:OnInitialized()
    self.Overridden.OnInitialized(self)

    ---------------------------------------
    --- 玩家 UI显示位置 [ UI元素 widget ]
    ---------------------------------------
    self.UICustomRoomPlaySlot_Tb = {}
    for i = 1, 8 do
        self.UICustomRoomPlaySlot_Tb[i] = {}
        self.UICustomRoomPlaySlot_Tb[i] = self:GetWidgetFromName("UICustomRoomPlaySlot_"..i)
    end

    ---------------------------------------
    --- 数据
    ---------------------------------------
    self.bCountDown = false     --- 倒计时相关
    self.CountDownTime = 6

    ---------------------------------------
    --- 注册事件
    ---------------------------------------
    self.Start_btn.OnClicked:Add(self, UICustomRoom_C.OnClicked_Start_Btn)
    self.Close_btn.OnClicked:Add(self, UICustomRoom_C.OnClicked_Close_Btn)


    LUIManager:RegisterMsg("UICustomRoom",Ds_UIMsgDefine.UI_SYSTEM_CUSTEM_ROOM_DATA,
            function(...) self:OnRefresh(...) end)

    LUIManager:RegisterMsg("UICustomRoom",Ds_UIMsgDefine.UI_SYSTEM_KICK_CUSTEM_DATA,
            function(...) self:OnClicked_Close_Btn() end)

    LUIManager:RegisterMsg("UICustomRoom",Ds_UIMsgDefine.UI_SYSTEM_GAME_COUNT_DOWN,
            function(...) self:OnGameCountDown() end)
end

function UICustomRoom_C:PreConstruct(IsDesignTime)
    self.Overridden.PreConstruct(self, IsDesignTime)
end

function UICustomRoom_C:Construct()
    self.Overridden.Construct(self)

    self:OnRefresh();
end

function UICustomRoom_C:Destruct()
    self.Overridden.Destruct(self)
end

function UICustomRoom_C:Tick(MyGeometry, InDeltaTime)

    if  self.bCountDown then
        self.CountDownTime = self.CountDownTime - InDeltaTime;
        if  self.CountDownTime < 1 then
            self.CountDownTime = 1;
        end
        self.CountDown_cvs:SetVisibility(UE4.ESlateVisibility.Visible);
        if self.CountDownTime  then
            self.CountDown_txt:SetText( math.floor(self.CountDownTime) );
        end
    else
        self.CountDown_cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    end
end


---------------------------------------
--- UI Event Callback
---------------------------------------
function UICustomRoom_C:OnGameCountDown()
    self.bCountDown = true
end


---------------------------------------
--- UI Event Callback
---------------------------------------
function UICustomRoom_C:OnClicked_Close_Btn()
    local roomID = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomID()
    local roomRemainder = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomRemainder()
    LUAPlayerDataMgr:GetMatchDataMgr():OnC2sLeaveCustomRoomReq(roomID , roomRemainder)

    LUIManager:DestroyUI("UICustomRoom")
    LUIManager:ShowWindow("UICustomRoomMain")
end

function UICustomRoom_C:OnClicked_Start_Btn()
    local roomID = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomID()
    local roomRemainder = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomRemainder()

    if roomID > 0 and roomRemainder > 0 then
        LUAPlayerDataMgr:GetMatchDataMgr():OnC2sStartCustomRoomReq(roomID , roomRemainder)
    end
end

--------------------------------------
--- 辅助函数
--------------------------------------
function UICustomRoom_C:OnRefresh()
    local roomMemberCtn = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomPlayerCtn()

    --dump(LUAPlayerDataMgr:GetMatchDataMgr().CustomRoomData.members)
    local customRoomID = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomID()
    self.RoomID_Txt:SetText(customRoomID)

    for i = 1, #self.UICustomRoomPlaySlot_Tb do

        if i <= roomMemberCtn then
            local memberUISlot = self.UICustomRoomPlaySlot_Tb[i]
            local roomMemberData = LUAPlayerDataMgr:GetMatchDataMgr():GetCustomRoomPlayerDataByIndex(i)

            if roomMemberData ~= nil then
                memberUISlot:OnRefreshPlayerInfo(roomMemberData , i)
            else
                memberUISlot:SetSlotClear()
            end
        end
    end
end

return UICustomRoom_C