require "UnLua"

local SprintMode =
{
    LEFT_JOYSTICK_SPRINT = 0,   --- 左侧摇杆冲锋
    RIGHT_COVER_BTN_SPRINT = 1, --- 右侧冲锋按钮冲锋
}

--- 战斗界面底部左右两侧 UI
---@class UIBattleBottomLeftRight_C
local UIBattleBottomLeftRight_C = class("UIBattleBottomLeftRight_C")

---@param ownerWidget UUserWidget
function UIBattleBottomLeftRight_C:OnInitialized(ownerWidget)

    self.ownerWidget = ownerWidget

    --- 冲锋数据
    self.bPressInCoverOrSprint = false
    self.pressTimer = 0.0
    self.bCallNextFrame = false
    --- 当前冲刺操作模式
    self.checkSprintMode = SprintMode.LEFT_JOYSTICK_SPRINT
    self.MoveJoystickX = 0.0
    self.MoveJoystickY = 0.0

    --- 视角旋转
    --self.LastRightAreaCameraLocalCoord = UE4.FVector2D(0 , 0);
    --- 是否冲刺
    self.bSprint = false

    --- 是否为一键开镜开火
    self.bOnekeyAimFire = false
    --- 是否正在启动一键瞄准开火
    self.bOnekeyAimFireStarting = false
    --- 一键开镜开火延迟时间(在开镜过程完成之后才执行开火)
    self.OnekeyAimFireElapseTime = 0

    --- 开镜瞄准图标
    self.AimTargetImgPath =
    {
        --- 普通
        [1] = "PaperSprite'/Game/UI/Atlas/BattleMain2_new/Frames/T_ICON_F_Open_mirror01_png.T_ICON_F_Open_mirror01_png'",
        --- 开镜
        [2] = "PaperSprite'/Game/UI/Atlas/BattleMain2_new/Frames/T_ICON_F_Open_mirror02_png.T_ICON_F_Open_mirror02_png'",
        --- 掩体
        [3] = "PaperSprite'/Game/UI/Atlas/BattleMain2_new/Frames/T_ICON_F_bunker_png.T_ICON_F_bunker_png'",
    }

    --- 触屏镜头转速
    self.rateScaleMode =
    {
        [1] = 1.0 / 20.0,       --- 通常时候
        [2] = 3.0 / 100.0,      --- 瞄准减速
    }

    --------------------------------------------------------------------
    --- UI Mgs
    --------------------------------------------------------------------
    --- 战斗开始
    LUIManager:RegisterMsg("UIBattleMain",Ds_UIMsgDefine.UI_BATTLE_CHARACTER_LEAVECOVER,
            function(...) self:CharacterLeaveCover() end)
end

function UIBattleBottomLeftRight_C:PreConstruct(IsDesignTime)
end

function UIBattleBottomLeftRight_C:Construct()
    self.TouchHandle = {}

    --------------------------------------------------------------------
    --- UI Event
    --------------------------------------------------------------------
    --- 换弹
    self.ownerWidget.WeaponReload_ImageExt.OnClicked:Add(self.ownerWidget,
        function(ownWidget)
            self:OnClicked_WeaponReloading()
        end)

    --- 瞄准
    self.ownerWidget.AimTarget_TouchJoystick.OnTouchStarted:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchStarted_AimTarget(MyGeometry , Event)
        end)

    self.ownerWidget.AimTarget_TouchJoystick.OnTouchMoved:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchMoved_AimTarget(MyGeometry , Event)
        end)

    self.ownerWidget.AimTarget_TouchJoystick.OnTouchEnded:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchEnded_AimTarget(MyGeometry , Event)
        end)

    --- 冲刺进入掩体
    self.ownerWidget.InCoverTouch_VirtualJoystick.OnTouchStarted:Add(self.ownerWidget,
        function(ownWidget , MyGeometry , Event)
            self:OnTouchStarted_InCoverTouch(MyGeometry , Event)
        end)

    self.ownerWidget.InCoverTouch_VirtualJoystick.OnTouchEnded:Add(self.ownerWidget,
        function(ownWidget, MyGeometry , Event)
            self:OnTouchEnded_InCoverTouch(MyGeometry , Event)
        end)

    --- 右侧开火摇杆
    self.ownerWidget.RightStartFire_VirtualJoystick.OnTouchStarted:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchStarted_RightStartFire(MyGeometry , Event)
        end)

    self.ownerWidget.RightStartFire_VirtualJoystick.OnTouchMoved:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchMoved_RightStartFire(MyGeometry , Event)
        end)

    self.ownerWidget.RightStartFire_VirtualJoystick.OnTouchEnded:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchEnded_RightStartFire(MyGeometry , Event)
        end)

    --- 左侧开火摇杆
    self.ownerWidget.LeftStartFire_VirtualJoystick.OnTouchStarted:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchStarted_LeftStartFire(MyGeometry , Event)
        end)

    self.ownerWidget.LeftStartFire_VirtualJoystick.OnTouchMoved:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchMoved_LeftStartFire(MyGeometry , Event)
        end)

    self.ownerWidget.LeftStartFire_VirtualJoystick.OnTouchEnded:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchEnded_LeftStartFire(MyGeometry , Event)
        end)

    --- 左侧角色移动摇杆
    self.ownerWidget.PlayerMove_VirtualJoystick.OnPostJoystickValueEvent:Add(self.ownerWidget,
        function(ownerWidget , ValueX , ValueY)
            self:OnPostJoystickValue(ValueX , ValueY)
        end)

    --- 左侧角色移动摇杆结束
    self.ownerWidget.PlayerMove_VirtualJoystick.OnTouchEnded:Add(self.ownerWidget,
    function(ownerWidget , MyGeometry , Event)
        self:OnTouchEnded_PlayerMove(MyGeometry , Event)
    end)

    --- 右侧镜头摇杆
    self.ownerWidget.RightAreaCamera_TouchVirtualJoystick.OnTouchStarted:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchStarted_RightAreaCamera(MyGeometry , Event)
        end)

    self.ownerWidget.RightAreaCamera_TouchVirtualJoystick.OnTouchMoved:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchMoved_RightAreaCamera(MyGeometry , Event)
        end)

    self.ownerWidget.RightAreaCamera_TouchVirtualJoystick.OnTouchEnded:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchEnded_RightAreaCamera(MyGeometry , Event)
        end)

    --- 全屏镜头摇杆
    self.ownerWidget.FullAreaCamera_TouchVirtualJoystick.OnTouchStarted:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchStarted_FullAreaCamera(MyGeometry , Event)
        end)

    self.ownerWidget.FullAreaCamera_TouchVirtualJoystick.OnTouchMoved:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchMoved_FullAreaCamera(MyGeometry , Event)
        end)

    self.ownerWidget.FullAreaCamera_TouchVirtualJoystick.OnTouchEnded:Add(self.ownerWidget,
        function(ownerWidget , MyGeometry , Event)
            self:OnTouchEnded_FullAreaCamera(MyGeometry , Event)
        end)

    --- 设置瞄准按钮
    self:TouchInput_Sprinting(self.bSprint)
    --- 隐藏冲锋圆弧
    self.ownerWidget.SprintToggle_CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
    --- 设置相机旋转区域
    self:SetAreaCamereaRotate()

    ---- PC 上不开Touch模拟不显示控件
    if LuaMarcoUtils.IsRunningEditor() and not UE4.UMGLuaUtils.UMG_UseMouseForTouch() then
        self.ownerWidget.RightAreaCamera_TouchVirtualJoystick:SetVisibility(UE4.ESlateVisibility.Hidden)
        self.ownerWidget.FullAreaCamera_TouchVirtualJoystick:SetVisibility(UE4.ESlateVisibility.Hidden)
    end

	self.MainBattleUserDefine_Tb = {}
	self.MaxNum = 6
	for i = 1, self.MaxNum do
		self.MainBattleUserDefine_Tb[i] = {}
		self.MainBattleUserDefine_Tb[i].TouchJoystickCanvasPanel = self.ownerWidget:GetWidgetFromName("TouchJoystick_CanvasPanel_"..i)
		self.MainBattleUserDefine_Tb[i].CanvasSlot = UE4.UMGLuaUtils.UMG_GetCanvasPanelSlot(self.MainBattleUserDefine_Tb[i].TouchJoystickCanvasPanel)
	end
end

function UIBattleBottomLeftRight_C:OnShowWindow()
    self.bPressFire = false
    self.bInFire = false

    self:OnRefreshAllBottomLRtUI()
end

function UIBattleBottomLeftRight_C:OnHideWindow()
end

function UIBattleBottomLeftRight_C:Destruct()
end

function UIBattleBottomLeftRight_C:Tick(MyGeometry, InDeltaTime)

    --- 右侧冲锋兼进出掩体模式
    self:CharacterSprintByDiffMode(self.checkSprintMode , InDeltaTime)

    if self.bOnekeyAimFireStarting then
        if self.OnekeyAimFireElapseTime <= 0.2 then
            self.OnekeyAimFireElapseTime = self.OnekeyAimFireElapseTime + InDeltaTime
        else
            self.bOnekeyAimFireStarting = false
            self.bPressFire = true
            self:BattlePlayerFire()
        end
    end

    self:SetFireBtnVisibility(not self.ownerWidget:IsEnableAutomaticFire())
	
	self:BattleBottomLeftRightSetting()
end

function UIBattleBottomLeftRight_C:BattleBottomLeftRightSetting()
	
	local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
		-- 左开火
		local LeftStartFireVirtualJoystickPosSetting = UserConfigSettings.LeftStartFireVirtualJoystickPosSetting
		local LeftStartFireVirtualJoystickScaleSetting = UserConfigSettings.LeftStartFireVirtualJoystickScaleSetting
		if LeftStartFireVirtualJoystickPosSetting and LeftStartFireVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(LeftStartFireVirtualJoystickPosSetting.Section, LeftStartFireVirtualJoystickPosSetting.Key,LeftStartFireVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(LeftStartFireVirtualJoystickScaleSetting.Section, LeftStartFireVirtualJoystickScaleSetting.Key,LeftStartFireVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[1].CanvasSlot:SetPosition(Pos)
			self.MainBattleUserDefine_Tb[1].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
		end
		
		-- 左摇杆
		local PlayerMoveVirtualJoystickPosSetting = UserConfigSettings.PlayerMoveVirtualJoystickPosSetting
		local PlayerMoveVirtualJoystickScaleSetting = UserConfigSettings.PlayerMoveVirtualJoystickScaleSetting
		if PlayerMoveVirtualJoystickPosSetting and PlayerMoveVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(PlayerMoveVirtualJoystickPosSetting.Section, PlayerMoveVirtualJoystickPosSetting.Key,PlayerMoveVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(PlayerMoveVirtualJoystickScaleSetting.Section, PlayerMoveVirtualJoystickScaleSetting.Key,PlayerMoveVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[2].CanvasSlot:SetPosition(Pos)
		--	self.MainBattleUserDefine_Tb[1].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
		end

		-- 冲锋掩体
		local InCoverTouchVirtualJoystickPosSetting = UserConfigSettings.InCoverTouchVirtualJoystickPosSetting
		local InCoverTouchVirtualJoystickScaleSetting = UserConfigSettings.InCoverTouchVirtualJoystickScaleSetting
		if InCoverTouchVirtualJoystickPosSetting and InCoverTouchVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(InCoverTouchVirtualJoystickPosSetting.Section, InCoverTouchVirtualJoystickPosSetting.Key,InCoverTouchVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(InCoverTouchVirtualJoystickScaleSetting.Section, InCoverTouchVirtualJoystickScaleSetting.Key,InCoverTouchVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[3].CanvasSlot:SetPosition(Pos)
			self.MainBattleUserDefine_Tb[3].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
		end

		-- 换弹
		local WeaponReloadVirtualJoystickPosSetting = UserConfigSettings.WeaponReloadVirtualJoystickPosSetting
		local WeaponReloadVirtualJoystickScaleSetting = UserConfigSettings.WeaponReloadVirtualJoystickScaleSetting
		if WeaponReloadVirtualJoystickPosSetting and WeaponReloadVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(WeaponReloadVirtualJoystickPosSetting.Section, WeaponReloadVirtualJoystickPosSetting.Key,WeaponReloadVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(WeaponReloadVirtualJoystickScaleSetting.Section, WeaponReloadVirtualJoystickScaleSetting.Key,WeaponReloadVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[4].CanvasSlot:SetPosition(Pos)
			self.MainBattleUserDefine_Tb[4].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
		end

		-- 瞄准
		local AimTargetVirtualJoystickPosSetting = UserConfigSettings.AimTargetVirtualJoystickPosSetting
		local AimTargetVirtualJoystickScaleSetting = UserConfigSettings.AimTargetVirtualJoystickScaleSetting
		if AimTargetVirtualJoystickPosSetting and AimTargetVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(AimTargetVirtualJoystickPosSetting.Section, AimTargetVirtualJoystickPosSetting.Key,AimTargetVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(AimTargetVirtualJoystickScaleSetting.Section, AimTargetVirtualJoystickScaleSetting.Key,AimTargetVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[5].CanvasSlot:SetPosition(Pos)
			self.MainBattleUserDefine_Tb[5].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
		end

		-- 右开火
		local RightStartFireVirtualJoystickPosSetting = UserConfigSettings.RightStartFireVirtualJoystickPosSetting
		local RightStartFireVirtualJoystickScaleSetting = UserConfigSettings.RightStartFireVirtualJoystickScaleSetting
		if RightStartFireVirtualJoystickPosSetting and RightStartFireVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(RightStartFireVirtualJoystickPosSetting.Section, RightStartFireVirtualJoystickPosSetting.Key,RightStartFireVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(RightStartFireVirtualJoystickScaleSetting.Section, RightStartFireVirtualJoystickScaleSetting.Key,RightStartFireVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[6].CanvasSlot:SetPosition(Pos)
			self.MainBattleUserDefine_Tb[6].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
		end
	end

end

--- 左侧摇杆冲锋 ， 右侧按钮进出掩体 模式
function UIBattleBottomLeftRight_C:LeftJoystickSprintAndCoverMode(InDeltaTime)

    if self.ownerWidget.PlayerMove_VirtualJoystick ~= nil then
        if self.ownerWidget.PlayerMove_VirtualJoystick:GetDragRunningToggle() then
            self.bSprint = true
            self:TouchInput_Sprinting(self.bSprint)
            self.ownerWidget.SprintToggle_CanvasPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        else
            if self.bSprint then
                self.bSprint = false
                self:TouchInput_Sprinting(self.bSprint)
                self.ownerWidget.SprintToggle_CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
            end
        end
    end
end

--- 右侧按钮进出掩体 + 冲锋 模式
function UIBattleBottomLeftRight_C:RightCoverBtnSprintAndCoverMode(InDeltaTime)
    if self.bPressInCoverOrSprint then
        self.pressTimer = self.pressTimer + InDeltaTime

        if self.pressTimer > 0.3 then

            self:TouchInput_Sprinting(true)
        end
    else
        if self.bCallNextFrame then
            if self.pressTimer <= 0.3 and self.pressTimer > 0.0 then

                self:TouchInput_SprintingToCover()
            else
                self:TouchInput_Sprinting(false)
            end

            self.bCallNextFrame = false
        end
    end
end

function UIBattleBottomLeftRight_C:CharacterSprintByDiffMode(sprintMode , InDeltaTime)
    if sprintMode == SprintMode.LEFT_JOYSTICK_SPRINT then
        self:LeftJoystickSprintAndCoverMode(InDeltaTime)
    elseif sprintMode == SprintMode.RIGHT_COVER_BTN_SPRINT then
        self:RightCoverBtnSprintAndCoverMode(InDeltaTime)
    else
        print("UIBattleBottomLeftRight_C:CharacterSprintByDiffMode sprintMode could not find .")
    end
end

---------------------------------------------
--- UI消息
---------------------------------------------
function UIBattleBottomLeftRight_C:CharacterLeaveCover()
    self:SetAreaCamereaRotate()
    self:OnRefreshAimingBtnUI()
end

---------------------------------------------
--- 输入监听
---------------------------------------------

--- 开火
function UIBattleBottomLeftRight_C:BattlePlayerFire()

    if self.ownerWidget == nil then
        return
    end

    local CharacterBase = self.ownerWidget:GetCharacterBase()
    if CharacterBase == nil then
        print("UIBattleBottomLeftRight_C BattlePlayerFire CharacterBase is nil .")
        return
    end

    if self.bPressFire then
        self.bInFire = true

        CharacterBase:Fire_Pressed()
    else
        if self.bInFire then
            self.bInFire = false
            CharacterBase:Fire_Released()
        end
    end
end

---------------------------------------------
--- UI Event
---------------------------------------------
--- 开火 OnTouchStarted
function UIBattleBottomLeftRight_C:OnTouchStarted_RightStartFire(MyGeometry , Event)
    local CharacterBase = self.ownerWidget:GetCharacterBase()
    if not CharacterBase then
        return
    end

    --- 镜头移动
    self:DragMovCameraStart(MyGeometry , Event , self.ownerWidget.RightStartFire_VirtualJoystick)

    if not CharacterBase:IsWeaponAim() then
        local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
        local OnekeyAimFireSetting = UserConfigSettings and UserConfigSettings.OnekeyAimFireSetting or nil
        if OnekeyAimFireSetting then
            --- 一键开镜开火
            if UserConfigSettings:GetBool(OnekeyAimFireSetting.Section, OnekeyAimFireSetting.Key, OnekeyAimFireSetting.Value) then
                self.bOnekeyAimFire = true
                self.bOnekeyAimFireStarting = true
                self.OnekeyAimFireElapseTime = 0
                self:OnClicked_AimingTarget()
                return
            end
        end

        if CharacterBase:IsCovering() then
            local CoveringWaistShootSetting = UserConfigSettings and UserConfigSettings.CoveringWaistShootSetting or nil
            if CoveringWaistShootSetting then
                --- 腰射功能
                if not UserConfigSettings:GetBool(CoveringWaistShootSetting.Section, CoveringWaistShootSetting.Key, CoveringWaistShootSetting.Value) then
                    return
                end
            end
        end

    end

    self.bOnekeyAimFire = false
    self.bPressFire = true
    self:BattlePlayerFire()
end

--- 开火 OnTouchMoved
function UIBattleBottomLeftRight_C:OnTouchMoved_RightStartFire(MyGeometry , Event)
    if not self.bOnekeyAimFireStarting then
        self.bPressFire = true
        self:BattlePlayerFire()
    end

    --- 镜头移动
    self:DragMovCameraMoved(MyGeometry , Event ,self.ownerWidget.RightStartFire_VirtualJoystick)
end

--- 开火 OnTouchEnded
function UIBattleBottomLeftRight_C:OnTouchEnded_RightStartFire(MyGeometry , Event)
    self:DragMovCameraEnded(MyGeometry , Event ,self.ownerWidget.RightStartFire_VirtualJoystick)

    if self.bOnekeyAimFire then
        local CharacterBase = self.ownerWidget:GetCharacterBase()
        if CharacterBase and CharacterBase:IsWeaponAim() then
            local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
            local OnekeyAimFireSetting = UserConfigSettings and UserConfigSettings.OnekeyAimFireSetting or nil
            if OnekeyAimFireSetting then
                --- 一键开镜开火
                if UserConfigSettings:GetBool(OnekeyAimFireSetting.Section, OnekeyAimFireSetting.Key, OnekeyAimFireSetting.Value) then
                    self:OnClicked_AimingTarget()
                end
            end
        end

        self.bOnekeyAimFire = false
    end

    self.bOnekeyAimFireStarting = false
    self.OnekeyAimFireElapseTime = 0

    self.bPressFire = false
    self:BattlePlayerFire()
end

--- 开火 OnTouchStarted
function UIBattleBottomLeftRight_C:OnTouchStarted_LeftStartFire(MyGeometry , Event)
    local CharacterBase = self.ownerWidget:GetCharacterBase()
    if not CharacterBase then
        return
    end

    self:DragMovCameraStart(MyGeometry , Event , self.ownerWidget.LeftStartFire_VirtualJoystick)

    if not CharacterBase:IsWeaponAim() then
        if CharacterBase:IsCovering() then
            local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
            local CoveringWaistShootSetting = UserConfigSettings and UserConfigSettings.CoveringWaistShootSetting or nil
            if CoveringWaistShootSetting then
                --- 腰射功能
                if not UserConfigSettings:GetBool(CoveringWaistShootSetting.Section, CoveringWaistShootSetting.Key, CoveringWaistShootSetting.Value) then
                    return
                end
            end
        end
    end
	
    self.bPressFire = true
    self:BattlePlayerFire()
end

--- 开火 OnTouchMoved
function UIBattleBottomLeftRight_C:OnTouchMoved_LeftStartFire(MyGeometry , Event)
    self.bPressFire = true
    self:BattlePlayerFire()

    self:DragMovCameraMoved(MyGeometry , Event , self.ownerWidget.LeftStartFire_VirtualJoystick)
end

--- 开火 OnTouchEnded
function UIBattleBottomLeftRight_C:OnTouchEnded_LeftStartFire(MyGeometry , Event)
    self:DragMovCameraEnded(MyGeometry , Event, self.ownerWidget.LeftStartFire_VirtualJoystick)
    self.bPressFire = false
    self:BattlePlayerFire()
end

--- 左侧摇杆移动消息
function UIBattleBottomLeftRight_C:OnPostJoystickValue(ValueX , ValueY)
    if self.ownerWidget == nil then
        return
    end

    self.MoveJoystickX = ValueX
    self.MoveJoystickY = ValueY

    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase then
        local PlayerController = characterBase.Controller and characterBase.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
        if PlayerController and not PlayerController:GetIsVirtualGamePad() then
            PlayerController:SetIsVirtualGamePad(true)
        end

        -- 掩体
        if characterBase:IsCovering() then
            if math.abs(ValueX) < math.abs(ValueY) then
                characterBase:LogicMoveForward(ValueY)
            else
                characterBase:LogicMoveRight(ValueX)
            end
            -- characterBase:LogicMoveForward(ValueY)
            -- characterBase:LogicMoveRight(ValueX)
        -- 冲锋
        elseif characterBase:IsRunning() then
            local turnSpeed = 0.38
            characterBase:LogicMoveForward(1)
            characterBase:TurnRate(ValueX * turnSpeed)
        else
            characterBase:LogicMoveForward(ValueY)
            characterBase:LogicMoveRight(ValueX)
        end
    end
end

--- 左侧移动摇杆结束
function UIBattleBottomLeftRight_C:OnTouchEnded_PlayerMove(MyGeometry , Event)
    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase then
        local PlayerController = characterBase.Controller and characterBase.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
        if PlayerController then
            PlayerController:SetIsVirtualGamePad(false)
        end

        characterBase:LogicMoveForward(0)
        characterBase:LogicMoveRight(0)
    end
end

--- 右侧镜头控制
--- 镜头摇杆 OnTouchStarted
function UIBattleBottomLeftRight_C:OnTouchStarted_RightAreaCamera(MyGeometry , Event)
    self:DragMovCameraStart(MyGeometry , Event , self.ownerWidget.RightAreaCamera_TouchVirtualJoystick)
end

--- 镜头摇杆 OnTouchMoved
function UIBattleBottomLeftRight_C:OnTouchMoved_RightAreaCamera(MyGeometry , Event)
    self:DragMovCameraMoved(MyGeometry , Event , self.ownerWidget.RightAreaCamera_TouchVirtualJoystick)
end

--- 镜头摇杆 OnTouchEnded
function UIBattleBottomLeftRight_C:OnTouchEnded_RightAreaCamera(MyGeometry , Event)
    self:DragMovCameraEnded(MyGeometry , Event, self.ownerWidget.RightAreaCamera_TouchVirtualJoystick)
end

--- 全屏镜头控制
--- 镜头摇杆 OnTouchStarted
function UIBattleBottomLeftRight_C:OnTouchStarted_FullAreaCamera(MyGeometry , Event)
    self:DragMovCameraStart(MyGeometry , Event , self.ownerWidget.FullAreaCamera_TouchVirtualJoystick)
end

--- 镜头摇杆 OnTouchMoved
function UIBattleBottomLeftRight_C:OnTouchMoved_FullAreaCamera(MyGeometry , Event)
    self:DragMovCameraMoved(MyGeometry , Event , self.ownerWidget.FullAreaCamera_TouchVirtualJoystick)
end

--- 镜头摇杆 OnTouchEnded
function UIBattleBottomLeftRight_C:OnTouchEnded_FullAreaCamera(MyGeometry , Event)
    self:DragMovCameraEnded(MyGeometry , Event, self.ownerWidget.FullAreaCamera_TouchVirtualJoystick)
end

--- 瞄准事件
--- 瞄准事件 OnTouchStarted
function UIBattleBottomLeftRight_C:OnTouchStarted_AimTarget(MyGeometry , Event)
    --print("OnTouchStarted_AimTarget ...")
    self:DragMovCameraStart(MyGeometry , Event , self.ownerWidget.AimTarget_TouchJoystick)
    self:OnClicked_AimingTarget()
end

--- 瞄准事件 OnTouchMoved
function UIBattleBottomLeftRight_C:OnTouchMoved_AimTarget(MyGeometry , Event)
    --print("OnTouchMoved_AimTarget ...")
    self:DragMovCameraMoved(MyGeometry , Event , self.ownerWidget.AimTarget_TouchJoystick)
end

--- 瞄准事件 OnTouchEnded
function UIBattleBottomLeftRight_C:OnTouchEnded_AimTarget(MyGeometry , Event)
    --print("OnTouchEnded_AimTarget ...")
    self:DragMovCameraEnded(MyGeometry , Event, self.ownerWidget.AimTarget_TouchJoystick)
end

--- 进出掩体 OnTouchStarted
function UIBattleBottomLeftRight_C:OnTouchStarted_InCoverTouch(MyGeometry , Event)
    self.bPressInCoverOrSprint = true
    self.pressTimer = 0.0
    self.bCallNextFrame = false

    if self.checkSprintMode == SprintMode.LEFT_JOYSTICK_SPRINT then
        self:TouchInput_SprintingToCover()
    end
end

--- 进出掩体 OnTouchEnded
function UIBattleBottomLeftRight_C:OnTouchEnded_InCoverTouch(MyGeometry , Event)
    self.bPressInCoverOrSprint = false
    self.bCallNextFrame = true
    self.pressTimer = 0.0
end

---------------------------------------------
--- 辅助函数
---------------------------------------------
--- 更换子弹
function UIBattleBottomLeftRight_C:OnClicked_WeaponReloading()
    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase == nil then
        return
    end

    if characterBase.EquipComponent == nil then
        return
    end

    if not characterBase:IsRifle() then
        return
    end

    if characterBase.EquipComponent then
        characterBase.EquipComponent:StartReload()
    end
end

--- 瞄准
function UIBattleBottomLeftRight_C:OnClicked_AimingTarget()
    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase == nil then
        return
    end

    characterBase:Aim_Pressed()
    --- 设置相机旋转区域
    self:SetAreaCamereaRotate()
end

--- 瞄准按钮图像更变
function UIBattleBottomLeftRight_C:OnChangeAimImg(iconIndex , bursh)
    if iconIndex <= 0 or iconIndex > #self.AimTargetImgPath or bursh == nil then
        return
    end

    local aimClass = UE4.UObject.Load(self.AimTargetImgPath[iconIndex])
    UE4.UWidgetBlueprintLibrary.SetBrushResourceToTexture(bursh , aimClass)
end

--- 刷新瞄准 UI按钮
function UIBattleBottomLeftRight_C:OnRefreshAimingBtnUI()

    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase == nil then
        return
    end

    local bInCover = characterBase:IsCovering()
    local bAiming = characterBase:IsWeaponAim()

    local aimTargetBursh = self.ownerWidget.AimTarget_TouchJoystick.Brush_normal
    if not bInCover then
        if bAiming then
            self:OnChangeAimImg(2 , aimTargetBursh)
        else
            self:OnChangeAimImg(1 ,aimTargetBursh)
        end

    else
        if bAiming then
            self:OnChangeAimImg(3 , aimTargetBursh)
        else
            self:OnChangeAimImg(1 , aimTargetBursh)
        end
    end
end

--- 冲锋掩体按钮 UI
function UIBattleBottomLeftRight_C:OnRefreshSprintInCoverUI()

    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase == nil then
        print("UIBattleBottomLeftRight_C:OnRefreshSprintInCoverUI characterBase is nil .")
        return
    end

    local isSprint = characterBase:IsRunning()
    if isSprint then

        self:RefreshSprintArcUI()
        
        if self:GetSprintControlMode() == SprintMode.LEFT_JOYSTICK_SPRINT then
            self.ownerWidget.SprintingToCover_Image:SetVisibility(UE4.ESlateVisibility.Hidden)
            self.ownerWidget.CanSprintToCover_Image:SetVisibility(UE4.ESlateVisibility.Visible)
        else
            self.ownerWidget.SprintingToCover_Image:SetVisibility(UE4.ESlateVisibility.Hidden)
            self.ownerWidget.CanSprintToCover_Image:SetVisibility(UE4.ESlateVisibility.Visible)
        end


    else
        self.ownerWidget.SprintingToCover_Image:SetVisibility(UE4.ESlateVisibility.Hidden)
        self.ownerWidget.CanSprintToCover_Image:SetVisibility(UE4.ESlateVisibility.Visible)
    end
end

--- 刷新冲锋拱形弧 UI
function UIBattleBottomLeftRight_C:RefreshSprintArcUI()

    local moveJoystickDir = UE4.FVector2D(self.MoveJoystickX , self.MoveJoystickY)
    local forwardDir = UE4.FVector2D(0 , 1)
    moveJoystickDir:Normalize()

    local MovingAngel = UE4.UKismetMathLibrary.DotProduct2D(moveJoystickDir , forwardDir)
    MovingAngel = UE4.UKismetMathLibrary.Acos(MovingAngel)
    MovingAngel = UE4.UKismetMathLibrary.RadiansToDegrees(MovingAngel)

    --- 表现最大旋转角
    local joyStickRunAngel = 60

    local valJsMoveAngel = MovingAngel / joyStickRunAngel

    if valJsMoveAngel >= 1.0 then
        valJsMoveAngel = 1.0
    end

    valJsMoveAngel = valJsMoveAngel * joyStickRunAngel

    local bLeftMove = self.MoveJoystickX < 0
    valJsMoveAngel = bLeftMove and -valJsMoveAngel or valJsMoveAngel

    self.ownerWidget.SprintDot_CanvasPanel:SetRenderAngle(valJsMoveAngel)

end

--- 冲刺进入掩体
function UIBattleBottomLeftRight_C:TouchInput_SprintingToCover()
    if self.ownerWidget == nil then
        return
    end

    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase then
        if characterBase:IsCanEnterCover() then
            characterBase:Cover_Pressed()
            self:SetAreaCamereaRotate()
        else
            characterBase:RollAction_Pressed()
        end
    end
end

--- 冲刺进入掩体
function UIBattleBottomLeftRight_C:TouchInput_Sprinting(bPress)
    if self.ownerWidget == nil then
        return
    end

    if not LuaMarcoUtils.IsRunningEditor() then
        local platformMarco = LuaMarcoUtils.GetPlatform()
        if platformMarco == PLATFORM_WINDOWS then
            return
        end
    else
        if not UE4.UMGLuaUtils.UMG_UseMouseForTouch() then
            return
        end
    end

    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase == nil then
        print("UIBattleBottomLeftRight_C:TouchInput_Sprinting characterBase is nil .")
        return
    end

    if bPress then
        characterBase:Run_Pressed()
    else
        characterBase:Run_Released()
    end

    self:OnRefreshSprintInCoverUI()
end

--- 镜头旋转
function UIBattleBottomLeftRight_C:CharacterCameraTurn(valX , valY , mode)

    if self.ownerWidget == nil then
        print("UIBattleBottomLeftRight_C:CharacterCameraTurn ... Error: self.ownerWidget is nil .")
        return
    end

    if mode < 0 or mode > #self.rateScaleMode then
        return
    end

    local rateScale = self.rateScaleMode[mode]

    if not rateScale then
        print("UIBattleMain_C:CharacterCameraTurn mode error . mode = " , mode)
        return
    end

    local CharacterBase = self.ownerWidget:GetCharacterBase()
    if CharacterBase then

        --- 左侧冲刺模式时候 ， 人物冲刺时候将会禁用右侧的镜头摇杆
        -- if CharacterBase:IsRunning() and self:GetSprintControlMode() == SprintMode.LEFT_JOYSTICK_SPRINT then
            -- return
        -- end

        CharacterBase:TurnRate(valX * rateScale)
        CharacterBase:LookUpRate(valY * rateScale)
    else
        print("Error : CharacterBase is nil .")
    end
end

--- 刷新所有和掩体相关的 UI
function UIBattleBottomLeftRight_C:OnRefreshAllCoverStateUI()
    if self.ownerWidget == nil then
        return
    end

    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase ~= nil then
        self:OnRefreshAimingBtnUI()
    end
end

function UIBattleBottomLeftRight_C:OnRefreshAllBottomLRtUI()
    self:OnRefreshSprintInCoverUI()
    self:OnRefreshAllCoverStateUI()
end

--- 刷新瞄准状态相关 UI
function UIBattleBottomLeftRight_C:OnRefreshAimingState()
    self:OnRefreshAimingBtnUI()
    self:SetAreaCamereaRotate()
end

--- 设置开火按键的显示
function UIBattleBottomLeftRight_C:SetFireBtnVisibility(bVisibility)

    if bVisibility then
        if self.ownerWidget.LeftStartFire_VirtualJoystick ~= nil then
            self.ownerWidget.RightStartFire_VirtualJoystick:SetVisibility(UE4.ESlateVisibility.Visible)
        end
        if self.ownerWidget.LeftStartFire_VirtualJoystick ~= nil then
            self.ownerWidget.LeftStartFire_VirtualJoystick:SetVisibility(UE4.ESlateVisibility.Visible)
        end
    else
        if self.ownerWidget.LeftStartFire_VirtualJoystick ~= nil then
            self.ownerWidget.RightStartFire_VirtualJoystick:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
        if self.ownerWidget.LeftStartFire_VirtualJoystick ~= nil then
            self.ownerWidget.LeftStartFire_VirtualJoystick:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    end
end

--[[
touchData
touchData PointIndex
touchData LocalCoord
touchData Score
--]]
function UIBattleBottomLeftRight_C:RemoveTouchHandleList(PointIndex)
    if self.TouchHandle == nil then
        return
    end

    if not self:IsExistsInTouchHandleList(PointIndex) then
        return
    end

    for i = #self.TouchHandle, 1 , -1 do
        local touchData = self.TouchHandle[i]
        if touchData and PointIndex == touchData.PointIndex then
            table.remove(self.TouchHandle , i)
            break
        end
    end
end

function UIBattleBottomLeftRight_C:RemoveTouchHandleByTouchUI(TouchUI)
    if TouchUI == nil then
        return
    end

    for i = #self.TouchHandle , 1 , -1  do
        if self.TouchHandle[i] and self.TouchHandle[i].TouchUIObj == TouchUI then
            table.remove(self.TouchHandle , i)
        end
    end
end

function UIBattleBottomLeftRight_C:AddToTouchHandleList(curTouchData)
    if self.TouchHandle == nil then
        return
    end

    local isExist = self:IsExistsInTouchHandleList(curTouchData.PointIndex)
    if curTouchData ~= nil and not isExist then
        --- 最优先
        if curTouchData.Score == 0 then
            table.insert(self.TouchHandle , 1 , curTouchData)
        elseif curTouchData.Score == 1 then
            table.insert(self.TouchHandle , curTouchData)
        end
    end
end

function UIBattleBottomLeftRight_C:IsExistsInTouchHandleList(PointIndex)

    if self.TouchHandle == nil then
        return false
    end

    for i = 1 , #self.TouchHandle do
        local touchData = self.TouchHandle[i]
        if touchData and touchData.PointIndex == PointIndex then
            return true
        end
    end

    return false
end

function UIBattleBottomLeftRight_C:UpdateTouchListData(PointIndex , LocalCoord)
    if PointIndex == nil and LocalCoord == nil and self.TouchHandle == nil then
        return
    end

    if not self:IsExistsInTouchHandleList(PointIndex) then
        return
    end

    for i = 1, #self.TouchHandle do
        local touchData = self.TouchHandle[i]
        if touchData and touchData.PointIndex == PointIndex then
            self.TouchHandle[i].LocalCoord = LocalCoord
        end
    end
end

function UIBattleBottomLeftRight_C:CreateTouchData(PointIndex , Score , LocalCoord , TouchUIObj)
    if PointIndex and Score and LocalCoord and TouchUIObj then
        return {PointIndex = PointIndex , Score = Score , LocalCoord = LocalCoord , TouchUIObj = TouchUIObj}
    end

    return nil
end



---------------------------------------------
--- 设置数据接口
---------------------------------------------
--- 设置相机旋转区域
function UIBattleBottomLeftRight_C:SetAreaCamereaRotate()
    local CharacterBase = self.ownerWidget:GetCharacterBase()
    --- 掩体中，瞄准状态下
    if CharacterBase and CharacterBase:IsCovering() and CharacterBase:IsWeaponAim() then
        local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
        if UserConfigSettings then
            local CoveringFullScreenRotationSetting = UserConfigSettings.CoveringFullScreenRotationSetting
            if CoveringFullScreenRotationSetting then
                --- 相机转动范围(全屏)
                if UserConfigSettings:GetBool(CoveringFullScreenRotationSetting.Section, CoveringFullScreenRotationSetting.Key, CoveringFullScreenRotationSetting.Value) then
                    --- 屏蔽移动
                    self.ownerWidget.PlayerMove_VirtualJoystick:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)

                    --- 切换到全屏转向
                    --- 判断状态，防止打断转向镜头事件
                    if self.ownerWidget.RightAreaCamera_TouchVirtualJoystick:GetVisibility() ~= UE4.ESlateVisibility.Hidden then
                        self.ownerWidget.RightAreaCamera_TouchVirtualJoystick:SetVisibility(UE4.ESlateVisibility.Hidden)
                    end

                    if self.ownerWidget.FullAreaCamera_TouchVirtualJoystick:GetVisibility() ~= UE4.ESlateVisibility.Visible then
                        self.ownerWidget.FullAreaCamera_TouchVirtualJoystick:SetVisibility(UE4.ESlateVisibility.Visible)
                    end
                    return
                end
            end
        end
    end

    --- 开启移动
    self.ownerWidget.PlayerMove_VirtualJoystick:SetVisibility(UE4.ESlateVisibility.Visible)
    --- 切换到半屏转向
    --self.ownerWidget.RightAreaCamera_TouchVirtualJoystick:SetVisibility(UE4.ESlateVisibility.Visible)
    --self.ownerWidget.FullAreaCamera_TouchVirtualJoystick:SetVisibility(UE4.ESlateVisibility.Hidden)

    --- 判断状态，防止打断转向镜头事件
    if self.ownerWidget.RightAreaCamera_TouchVirtualJoystick:GetVisibility() ~= UE4.ESlateVisibility.Visible then
        self.ownerWidget.RightAreaCamera_TouchVirtualJoystick:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.ownerWidget.FullAreaCamera_TouchVirtualJoystick:GetVisibility() ~= UE4.ESlateVisibility.Hidden then
        self.ownerWidget.FullAreaCamera_TouchVirtualJoystick:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
end

--- 镜头移动逻辑 TouchUIObj 是最新正在激活的控件 保证只有一个控件生效此逻辑
function UIBattleBottomLeftRight_C:DragMovCameraMoved(MyGeometry , Event , TouchUIObj)
    if TouchUIObj == nil then
        return
    end

    local pos = Event:GetScreenSpacePosition()
    local LocalCoord = MyGeometry:AbsoluteToLocal(pos)
    local activeHandle = self:GetActiveTouchHandle()

    if activeHandle == nil then
        return
    end

    local offset = LocalCoord - activeHandle.LocalCoord;

    self:UpdateTouchListData(Event:GetPointerIndex() , LocalCoord)

    if(offset ~= UE4.FVector2D.ZeroVector) and Event:GetPointerIndex() == activeHandle.PointIndex then

        local movMode = 1
        --- 瞄准到敌人时候转速低
        local characterBase = self.ownerWidget:GetCharacterBase()
        if characterBase and characterBase:IsAimSlowMode() then
            movMode = 2
        end

        self:CharacterCameraTurn(offset.X , offset.Y , movMode)
    end
end

function UIBattleBottomLeftRight_C:DragMovCameraEnded(MyGeometry , Event , TouchUIObj)
    if TouchUIObj == nil then
        return
    end

    self:RemoveTouchHandleList(Event:GetPointerIndex())
end

--- 镜头移动逻辑 TouchUIObj 是最新正在激活的控件 保证只有一个控件生效此逻辑
function UIBattleBottomLeftRight_C:DragMovCameraStart(MyGeometry , Event , TouchUIObj)
    if TouchUIObj == nil then
        return
    end

    local score = 0
    --- 保证拖动镜头面板最优先
    if TouchUIObj == self.ownerWidget.RightAreaCamera_TouchVirtualJoystick or
        TouchUIObj == self.ownerWidget.FullAreaCamera_TouchVirtualJoystick then
        score = 1
    end

    local pos = Event:GetScreenSpacePosition()
    local localCoord = MyGeometry:AbsoluteToLocal(pos)

    --- self.LastRightAreaCameraLocalCoord = localCoord;

    local touchData = self:CreateTouchData(Event:GetPointerIndex() , score , localCoord , TouchUIObj)
    if touchData ~= nil then
        self:AddToTouchHandleList(touchData)
    end
end

---------------------------------------------
--- 获取数据接口
---------------------------------------------
function UIBattleBottomLeftRight_C:GetOwnerWidget()
    return self.ownerWidget
end

--- 获取冲刺操作模式
function UIBattleBottomLeftRight_C:GetSprintControlMode()
    return self.checkSprintMode
end

--- 获取当前激活的控件
function UIBattleBottomLeftRight_C:GetActiveTouchHandle()

    local maxScore = self:GetMaxTouchScore()

    if maxScore then
        if maxScore >= 1 then
            if self.TouchHandle and #self.TouchHandle > 0 then
                return self.TouchHandle[#self.TouchHandle]
            end
        else
            if self.TouchHandle and #self.TouchHandle > 0 then
                return self.TouchHandle[1]
            end
        end
    end

    return nil
end

--- 获取TouchData的最高得分
function UIBattleBottomLeftRight_C:GetMaxTouchScore()
    local maxScore = 0
    for i = 1, #self.TouchHandle do
        local touchData = self.TouchHandle[i]
        if touchData and touchData.Score > maxScore then
            maxScore = touchData.Score
        end
    end

    return maxScore
end



return UIBattleBottomLeftRight_C