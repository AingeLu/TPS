require "UnLua"

---@type UUserWidget
local UI_MainEnter_2_C = Class()

function UI_MainEnter_2_C:Initialize(Initializer)
end

function UI_MainEnter_2_C:OnInitialized()

    self.Overridden.OnInitialized(self)

    self.GameStart_Btn.OnClicked:Add(self, UI_MainEnter_2_C.OnClicked_GameStart_Btn)
    self.Level_Btn.OnClicked:Add(self, UI_MainEnter_2_C.OnClicked_Level_Btn)
    self.ChangModel_Btn.OnClicked:Add(self,UI_MainEnter_2_C.OnClicked_ChangModel_Btn)
    self.TouchVirtualJoystick_Rot.OnTouchStarted:Add(self, UI_MainEnter_2_C.OnTouchStartedRotation)
    self.TouchVirtualJoystick_Rot.OnTouchMoved:Add(self, UI_MainEnter_2_C.OnTouchMovedRotation)
    self.TouchVirtualJoystick_Rot.OnTouchEnded:Add(self, UI_MainEnter_2_C.OnTouchEndedRotation)

    --------lua 变量
    self.bTouchMovModel = false
end

function UI_MainEnter_2_C:PreConstruct(IsDesignTime)
end

function UI_MainEnter_2_C:Construct()
    self.Overridden.Construct(self)

    self.PlayerName_Text:SetText(LUAPlayerDataMgr:GetPlayerName())

    ---旋转
    self.LastLocalCoord = UE4.FVector2D(0 , 0);

    self.CurPointerIndex = 0

    self.modelRotationValue = 0

end

function UI_MainEnter_2_C:Tick(MyGeometry, InDeltaTime)

end

function UI_MainEnter_2_C:OnShowWindow()
end

---------------------------------------
--- UI Event Callback
---------------------------------------
function UI_MainEnter_2_C:OnClicked_GameStart_Btn()
    print("OnClicked_GameStart_Btn ...")

    LUIManager:ShowWindow("UIMatchBattleType")
end

function UI_MainEnter_2_C:OnClicked_Level_Btn()
    print("OnClicked_Level_Btn ...")

    LUIManager:ShowWindow("UICustomRoomMain")
end

function UI_MainEnter_2_C:OnClicked_ChangModel_Btn()
    print("OnClicked_ChangModel_Btn ...")
    local pawn = self:GetOwningPlayerPawn()

    if pawn ~= nil then
        local MainMenuPawn = pawn:Cast(UE4.ABP_MainMenuPawn_C)
        if MainMenuPawn ~= nil then
            MainMenuPawn:ChangCurModel()
        end
    end
    
end

---------------------------------
---  Joystick Rotate Model
---------------------------------

------模型摇杆  OnTouchStarted
function UI_MainEnter_2_C:OnTouchStartedRotation(MyGeometry , Event)
    print("UI_MainEnter_2_C:OnTouchStarted in lua")
    local pos = Event:GetScreenSpacePosition()

    local localCoord = MyGeometry:AbsoluteToLocal(pos)
    self.CurPointerIndex = Event:GetPointerIndex()
    self.LastLocalCoord = localCoord;
    self.bTouchMovModel = true
end

------模型摇杆  OnTouchMoved
function UI_MainEnter_2_C:OnTouchMovedRotation(MyGeometry , Event)
    if not self.bTouchMovModel then
        return
    end

    local  pos = Event:GetScreenSpacePosition()
    local LocalCoord = MyGeometry:AbsoluteToLocal(pos)

    if self.CurPointerIndex ~= Event:GetPointerIndex() then
        return        
    end

    local offset = self.LastLocalCoord - LocalCoord
    self.modelRotationValue = offset.X

    if(offset ~= UE4.FVector2D.ZeroVector)then
        self:SetCurrModelRotation(self.modelRotationValue)

        self.LastLocalCoord = LocalCoord;
    end
end

------模型摇杆  OnTouchEnded
function UI_MainEnter_2_C:OnTouchEndedRotation(MyGeometry , Event)
    print("UI_MainEnter_2_C:OnTouchEnded in lua")
    self.bTouchMovModel = false
end

function UI_MainEnter_2_C:SetCurrModelRotation(modelRotationValue)
    local rateRotateMode =
    {
        [0] = 1.0 / 1.0,
        [1] = 1.0 / 2.0,
    }

    local fRotator = UE4.FRotator(0 , modelRotationValue * rateRotateMode[1] , 0)

    local pawn = self:GetOwningPlayerPawn()

    if pawn ~= nil then
        local CharacterBase = pawn:Cast(UE4.ABP_MainMenuPawn_C)

        if CharacterBase ~= nil then
           CharacterBase:RotateModel(fRotator)
        else
            print("Error : CharacterBase is nill .")
        end

    else
        print("self.GetOwningPlayerPawn is nil .")
    end
end

return UI_MainEnter_2_C
