--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local UIBattleMainUserDefine_C = Class()

function UIBattleMainUserDefine_C:Initialize(Initializer)
	
	
	---------------------------------------------------------------------
	-- Lua ÖÐ¶¨Òå±äÁ¿
	self.LastLocalCoord = 0
	self.CurPointerIndex = 0
	self.CurChooseMainBattleUserDefine_Tb = nil

end

--function UIBattleMainUserDefine_C:PreConstruct(IsDesignTime)
--end

 function UIBattleMainUserDefine_C:construct()
	--------------------------------------------------------------------
    --- UI Event
    --------------------------------------------------------------------
		
	-- ×ó¿ª»ð
    self.LeftStartFire_VirtualJoystick.OnTouchStarted:Add(self,self.OnTouchStarted_LeftStartFire_VirtualJoystick)
    self.LeftStartFire_VirtualJoystick.OnTouchMoved:Add(self,self.OnTouchMoved_LeftStartFire_VirtualJoystick)
    self.LeftStartFire_VirtualJoystick.OnTouchEnded:Add(self,self.OnTouchEnded_LeftStartFire_VirtualJoystick)

	-- ×óÒ¡¸Ë
    self.PlayerMove_VirtualJoystick.OnTouchStarted:Add(self,self.OnTouchStarted_PlayerMove_VirtualJoystick)
    self.PlayerMove_VirtualJoystick.OnTouchMoved:Add(self,self.OnTouchMoved_PlayerMove_VirtualJoystick)
    self.PlayerMove_VirtualJoystick.OnTouchEnded:Add(self,self.OnTouchEnded_PlayerMove_VirtualJoystick)
	
	-- ÓÒ½øÑÚÌå
    self.InCoverTouch_VirtualJoystick.OnTouchStarted:Add(self,self.OnTouchStarted_InCoverTouch_VirtualJoystick)
    self.InCoverTouch_VirtualJoystick.OnTouchMoved:Add(self,self.OnTouchMoved_InCoverTouch_VirtualJoystick)
    self.InCoverTouch_VirtualJoystick.OnTouchEnded:Add(self,self.OnTouchEnded_InCoverTouch_VirtualJoystick)

	-- »»µ¯
    self.WeaponReload_TouchJoystick.OnTouchStarted:Add(self,self.OnTouchStarted_WeaponReload_TouchJoystick)
    self.WeaponReload_TouchJoystick.OnTouchMoved:Add(self,self.OnTouchMoved_WeaponReload_TouchJoystick)
    self.WeaponReload_TouchJoystick.OnTouchEnded:Add(self,self.OnTouchEnded_WeaponReload_TouchJoystick)

	-- Ãé×¼
	self.AimTarget_TouchJoystick.OnTouchStarted:Add(self,self.OnTouchStarted_AimTarget_TouchJoystick)
	self.AimTarget_TouchJoystick.OnTouchMoved:Add(self,self.OnTouchMoved_AimTarget_TouchJoystick)
    self.AimTarget_TouchJoystick.OnTouchEnded:Add(self,self.OnTouchEnded_AimTarget_TouchJoystick)

	-- ÓÒ¿ª»ð
    self.RightStartFire_VirtualJoystick.OnTouchStarted:Add(self,self.OnTouchStarted_RightStartFire_VirtualJoystick)
    self.RightStartFire_VirtualJoystick.OnTouchMoved:Add(self,self.OnTouchMoved_RightStartFire_VirtualJoystick)
    self.RightStartFire_VirtualJoystick.OnTouchEnded:Add(self,self.OnTouchEnded_RightStartFire_VirtualJoystick)

	-- ·µ»Ø
	self.Return_Button.OnClicked:Add(self,UIBattleMainUserDefine_C.OnClickedReturn_Button)

	-- ÖØÖÃ
	self.Reset_Button.OnClicked:Add(self,UIBattleMainUserDefine_C.OnClickedReset_Button)
	
	-- ±£´æ
	self.Save_Button.OnClicked:Add(self,UIBattleMainUserDefine_C.OnClickedSave_Button)

	self.MainBattleUserDefine_Tb = {}
	self.MaxNum = 6
	for i = 1, self.MaxNum do
		self.MainBattleUserDefine_Tb[i] = {}
		self.MainBattleUserDefine_Tb[i].TouchJoystickCanvasPanel = self:GetWidgetFromName("TouchJoystick_CanvasPanel_"..i)
		self.MainBattleUserDefine_Tb[i].CanvasSlot = UE4.UMGLuaUtils.UMG_GetCanvasPanelSlot(self.MainBattleUserDefine_Tb[i].TouchJoystickCanvasPanel)
		self.MainBattleUserDefine_Tb[i].SelectedImage = self.MainBattleUserDefine_Tb[i].TouchJoystickCanvasPanel:GetChildAt(0)
		self.MainBattleUserDefine_Tb[i].Pos = UE4.FVector2D(0,0)--UE4.UMGLuaUtils.UMG_GetCanvasPanelSlot(self.MainBattleUserDefine_Tb[i].TouchJoystickCanvasPanel):GetPosition()
		self.MainBattleUserDefine_Tb[i].Scale = 1
	end
	
	self.BattleMainUserDefinePos = {[1] = 100,[2] = -400,[3] = 220,[4] = -180,[5] = -325,[6] = -100, [7] = -450 ,[8] = -250,[9] = -80,[10] =-380,[11] = -200,[12] = -230}
	
	self:BattleMainUserDefineSettings()
 end
	
function UIBattleMainUserDefine_C:Tick(MyGeometry, InDeltaTime)
	if self.CurChooseMainBattleUserDefine_Tb ~= nil then
		for i = 1, self.MaxNum do
			if self.CurChooseMainBattleUserDefine_Tb ~= self.MainBattleUserDefine_Tb[i] then
				self.MainBattleUserDefine_Tb[i].SelectedImage:SetVisibility(UE4.ESlateVisibility.Hidden)
			end
		end

		local Value = self.ButtonSize_Slider:GetValue()
		local Scale = (2 * Value) + 0.5
		self.CurChooseMainBattleUserDefine_Tb.Scale = Scale
		self.CurChooseMainBattleUserDefine_Tb.TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
	end

end

-- ×ó¿ª»ð
function UIBattleMainUserDefine_C:OnTouchStarted_LeftStartFire_VirtualJoystick(MyGeometry , Event)
	self:OnTouchStarted_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_1)
end

function UIBattleMainUserDefine_C:OnTouchMoved_LeftStartFire_VirtualJoystick(MyGeometry , Event)
	self:OnTouchMoved_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_1)

end

function UIBattleMainUserDefine_C:OnTouchEnded_LeftStartFire_VirtualJoystick(MyGeometry , Event)
	self:OnTouchEnded_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_1)
end

-- ×óÒ¡¸Ë
function UIBattleMainUserDefine_C:OnTouchStarted_PlayerMove_VirtualJoystick(MyGeometry , Event)
	self:OnTouchStarted_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_2)
end

function UIBattleMainUserDefine_C:OnTouchMoved_PlayerMove_VirtualJoystick(MyGeometry , Event)
	self:OnTouchMoved_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_2)

end

function UIBattleMainUserDefine_C:OnTouchEnded_PlayerMove_VirtualJoystick(MyGeometry , Event)
	self:OnTouchEnded_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_2)
end

-- ÓÒ½øÑÚÌå
function UIBattleMainUserDefine_C:OnTouchStarted_InCoverTouch_VirtualJoystick(MyGeometry , Event)
	self:OnTouchStarted_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_3)
end

function UIBattleMainUserDefine_C:OnTouchMoved_InCoverTouch_VirtualJoystick(MyGeometry , Event)
	self:OnTouchMoved_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_3)
end

function UIBattleMainUserDefine_C:OnTouchEnded_InCoverTouch_VirtualJoystick(MyGeometry , Event)
	self:OnTouchEnded_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_3)
end


-- »»µ¯
function UIBattleMainUserDefine_C:OnTouchStarted_WeaponReload_TouchJoystick(MyGeometry , Event)
	print(self.WeaponReload_CanvasPanel)
	self:OnTouchStarted_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_4)
end

function UIBattleMainUserDefine_C:OnTouchMoved_WeaponReload_TouchJoystick(MyGeometry , Event)
	self:OnTouchMoved_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_4)

end

function UIBattleMainUserDefine_C:OnTouchEnded_WeaponReload_TouchJoystick(MyGeometry , Event)
	self:OnTouchEnded_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_4)
end

-- Ãé×¼
function UIBattleMainUserDefine_C:OnTouchStarted_AimTarget_TouchJoystick(MyGeometry , Event)
	self:OnTouchStarted_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_5)
end

function UIBattleMainUserDefine_C:OnTouchMoved_AimTarget_TouchJoystick(MyGeometry , Event)
	self:OnTouchMoved_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_5)

end

function UIBattleMainUserDefine_C:OnTouchEnded_AimTarget_TouchJoystick(MyGeometry , Event)
	self:OnTouchEnded_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_5)
end

-- ÓÒ¿ª»ð
function UIBattleMainUserDefine_C:OnTouchStarted_RightStartFire_VirtualJoystick(MyGeometry , Event)
	self:OnTouchStarted_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_6)
end

function UIBattleMainUserDefine_C:OnTouchMoved_RightStartFire_VirtualJoystick(MyGeometry , Event)
	self:OnTouchMoved_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_6)

end

function UIBattleMainUserDefine_C:OnTouchEnded_RightStartFire_VirtualJoystick(MyGeometry , Event)
	self:OnTouchEnded_DragTouchJoystick(MyGeometry, Event, self.TouchJoystick_CanvasPanel_6)
end

-- ·µ»Ø
function UIBattleMainUserDefine_C:OnClickedReturn_Button()
	LUIManager:HideWindow("UIBattleUserDefineSetting")
	
end

-- ÖØÖÃ
function UIBattleMainUserDefine_C:OnClickedReset_Button()
	for i = 1, self.MaxNum do
		local Pos = UE4.FVector2D(self.BattleMainUserDefinePos[2 * i - 1],self.BattleMainUserDefinePos[2 * i])
		self.MainBattleUserDefine_Tb[i].CanvasSlot:SetPosition(Pos)
		self.MainBattleUserDefine_Tb[i].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(1,1))
		self.ButtonSize_Slider:SetValue( ( 1 - 0.5) / 2)
		self.MainBattleUserDefine_Tb[i].Pos = Pos
		self.MainBattleUserDefine_Tb[i].Scale = 1
	end
end

-- ±£´æ
function UIBattleMainUserDefine_C:OnClickedSave_Button()
	local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
	if UserConfigSettings then
		-- ×ó¿ª»ð
		local LeftStartFireVirtualJoystickPosSetting = UserConfigSettings.LeftStartFireVirtualJoystickPosSetting
		local LeftStartFireVirtualJoystickScaleSetting = UserConfigSettings.LeftStartFireVirtualJoystickScaleSetting
		if LeftStartFireVirtualJoystickPosSetting and LeftStartFireVirtualJoystickScaleSetting then
			UserConfigSettings:SetVector2D(LeftStartFireVirtualJoystickPosSetting.Section, LeftStartFireVirtualJoystickPosSetting.Key,self.MainBattleUserDefine_Tb[1].Pos)
			UserConfigSettings:SetFloat(LeftStartFireVirtualJoystickScaleSetting.Section, LeftStartFireVirtualJoystickScaleSetting.Key,self.MainBattleUserDefine_Tb[1].Scale)
		end
		
		-- ×óÒ¡¸Ë
		local PlayerMoveVirtualJoystickPosSetting = UserConfigSettings.PlayerMoveVirtualJoystickPosSetting
		local PlayerMoveVirtualJoystickScaleSetting = UserConfigSettings.PlayerMoveVirtualJoystickScaleSetting
		if PlayerMoveVirtualJoystickPosSetting and PlayerMoveVirtualJoystickScaleSetting then
			UserConfigSettings:SetVector2D(PlayerMoveVirtualJoystickPosSetting.Section, PlayerMoveVirtualJoystickPosSetting.Key,self.MainBattleUserDefine_Tb[2].Pos)
			UserConfigSettings:SetFloat(PlayerMoveVirtualJoystickScaleSetting.Section, PlayerMoveVirtualJoystickScaleSetting.Key,self.MainBattleUserDefine_Tb[2].Scale)
		end

		-- ³å·æÑÚÌå
		local InCoverTouchVirtualJoystickPosSetting = UserConfigSettings.InCoverTouchVirtualJoystickPosSetting
		local InCoverTouchVirtualJoystickScaleSetting = UserConfigSettings.InCoverTouchVirtualJoystickScaleSetting
		if InCoverTouchVirtualJoystickPosSetting and InCoverTouchVirtualJoystickScaleSetting then
			UserConfigSettings:SetVector2D(InCoverTouchVirtualJoystickPosSetting.Section, InCoverTouchVirtualJoystickPosSetting.Key,self.MainBattleUserDefine_Tb[3].Pos)
			UserConfigSettings:SetFloat(InCoverTouchVirtualJoystickScaleSetting.Section, InCoverTouchVirtualJoystickScaleSetting.Key,self.MainBattleUserDefine_Tb[3].Scale)
		end

		-- »»µ¯
		local WeaponReloadVirtualJoystickPosSetting = UserConfigSettings.WeaponReloadVirtualJoystickPosSetting
		local WeaponReloadVirtualJoystickScaleSetting = UserConfigSettings.WeaponReloadVirtualJoystickScaleSetting
		if WeaponReloadVirtualJoystickPosSetting and WeaponReloadVirtualJoystickScaleSetting then
			UserConfigSettings:SetVector2D(WeaponReloadVirtualJoystickPosSetting.Section, WeaponReloadVirtualJoystickPosSetting.Key,self.MainBattleUserDefine_Tb[4].Pos)
			UserConfigSettings:SetFloat(WeaponReloadVirtualJoystickScaleSetting.Section, WeaponReloadVirtualJoystickScaleSetting.Key,self.MainBattleUserDefine_Tb[4].Scale)
		end

		-- Ãé×¼
		local AimTargetVirtualJoystickPosSetting = UserConfigSettings.AimTargetVirtualJoystickPosSetting
		local AimTargetVirtualJoystickScaleSetting = UserConfigSettings.AimTargetVirtualJoystickScaleSetting
		if AimTargetVirtualJoystickPosSetting and AimTargetVirtualJoystickScaleSetting then
			UserConfigSettings:SetVector2D(AimTargetVirtualJoystickPosSetting.Section, AimTargetVirtualJoystickPosSetting.Key,self.MainBattleUserDefine_Tb[5].Pos)
			UserConfigSettings:SetFloat(AimTargetVirtualJoystickScaleSetting.Section, AimTargetVirtualJoystickScaleSetting.Key,self.MainBattleUserDefine_Tb[5].Scale)
		end

		-- ÓÒ¿ª»ð
		local RightStartFireVirtualJoystickPosSetting = UserConfigSettings.RightStartFireVirtualJoystickPosSetting
		local RightStartFireVirtualJoystickScaleSetting = UserConfigSettings.RightStartFireVirtualJoystickScaleSetting
		if RightStartFireVirtualJoystickPosSetting and RightStartFireVirtualJoystickScaleSetting then
			UserConfigSettings:SetVector2D(RightStartFireVirtualJoystickPosSetting.Section, RightStartFireVirtualJoystickPosSetting.Key,self.MainBattleUserDefine_Tb[6].Pos)
			UserConfigSettings:SetFloat(RightStartFireVirtualJoystickScaleSetting.Section, RightStartFireVirtualJoystickScaleSetting.Key,self.MainBattleUserDefine_Tb[6].Scale)
		end

	end
end

-- ´¥ÃþÒ¡¸ËÒÆ¶¯Âß¼­
function UIBattleMainUserDefine_C:OnTouchStarted_DragTouchJoystick(MyGeometry, Event, TouchJoystickCanvasPanel)
	if TouchJoystickCanvasPanel == nil then
        return
    end	
	print(" UIBattleMainUserDefine_C:OnTouchStarted_DragTouchJoystick")

	for i = 1, self.MaxNum do
		if TouchJoystickCanvasPanel == self.MainBattleUserDefine_Tb[i].TouchJoystickCanvasPanel then
			self.CurChooseMainBattleUserDefine_Tb = self.MainBattleUserDefine_Tb[i]
			self.CurChooseMainBattleUserDefine_Tb.SelectedImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
			
			local Scale = self.CurChooseMainBattleUserDefine_Tb.Scale
			local Value = (Scale - 0.5) / 2
			self.ButtonSize_Slider:SetValue(Value)
		end
	end

    local pos = Event:GetScreenSpacePosition()
    local localCoord = MyGeometry:AbsoluteToLocal(pos)

	self.CurPointerIndex = Event:GetPointerIndex()

    self.LastLocalCoord = localCoord

	self.bTouchMove = true
end

function UIBattleMainUserDefine_C:OnTouchMoved_DragTouchJoystick(MyGeometry, Event, TouchJoystickCanvasPanel)
    if not self.bTouchMove then
        return
    end
	
	if TouchJoystickCanvasPanel == nil then
        return
    end

	print("UIBattleMainUserDefine_C:OnTouchMoved_DragTouchJoystick")

	local pos = Event:GetScreenSpacePosition()
	local LocalCoord = MyGeometry:AbsoluteToLocal(pos)

	if self.CurPointerIndex ~= Event:GetPointerIndex() then
        return        
    end

	local offset = self.LastLocalCoord - LocalCoord 

	if(offset ~= UE4.FVector2D.ZeroVector and self.CurChooseMainBattleUserDefine_Tb ~= nil )then
		local CanvasSlot = UE4.UMGLuaUtils.UMG_GetCanvasPanelSlot(TouchJoystickCanvasPanel)
		local Pos = UE4.FVector2D(CanvasSlot:GetPosition().X - offset.X, CanvasSlot:GetPosition().Y - offset.Y)
		CanvasSlot:SetPosition(Pos)
		self.CurChooseMainBattleUserDefine_Tb.Pos = Pos

	end
	
end

function UIBattleMainUserDefine_C:OnTouchEnded_DragTouchJoystick(MyGeometry, Event, TouchJoystickCanvasPanel)
	if TouchJoystickCanvasPanel == nil then
        return
    end

    print("UIBattleMainUserDefine_C:OnTouchEnded_DragTouchJoystick")
    self.bTouchMove = false
end

-------------------------------------------------------------------------
--- ÓÃ»§½çÃæ×Ô¶¨ÒåµÄÄ¬ÈÏÖµ
function UIBattleMainUserDefine_C:BattleMainUserDefineSettings()
	local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()

    if UserConfigSettings then
		-- ×ó¿ª»ð
		local LeftStartFireVirtualJoystickPosSetting = UserConfigSettings.LeftStartFireVirtualJoystickPosSetting
		local LeftStartFireVirtualJoystickScaleSetting = UserConfigSettings.LeftStartFireVirtualJoystickScaleSetting
		if LeftStartFireVirtualJoystickPosSetting and LeftStartFireVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(LeftStartFireVirtualJoystickPosSetting.Section, LeftStartFireVirtualJoystickPosSetting.Key,LeftStartFireVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(LeftStartFireVirtualJoystickScaleSetting.Section, LeftStartFireVirtualJoystickScaleSetting.Key,LeftStartFireVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[1].CanvasSlot:SetPosition(Pos)
			self.MainBattleUserDefine_Tb[1].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
			self.MainBattleUserDefine_Tb[1].Pos = Pos
			self.MainBattleUserDefine_Tb[1].Scale = Scale
		end
		
		-- ×óÒ¡¸Ë
		local PlayerMoveVirtualJoystickPosSetting = UserConfigSettings.PlayerMoveVirtualJoystickPosSetting
		local PlayerMoveVirtualJoystickScaleSetting = UserConfigSettings.PlayerMoveVirtualJoystickScaleSetting
		if PlayerMoveVirtualJoystickPosSetting and PlayerMoveVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(PlayerMoveVirtualJoystickPosSetting.Section, PlayerMoveVirtualJoystickPosSetting.Key,PlayerMoveVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(PlayerMoveVirtualJoystickScaleSetting.Section, PlayerMoveVirtualJoystickScaleSetting.Key,PlayerMoveVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[2].CanvasSlot:SetPosition(Pos)
		--	self.MainBattleUserDefine_Tb[2].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
			self.MainBattleUserDefine_Tb[2].Pos = Pos
		--	self.MainBattleUserDefine_Tb[2].Scale = Scale
		end

		-- ³å·æÑÚÌå
		local InCoverTouchVirtualJoystickPosSetting = UserConfigSettings.InCoverTouchVirtualJoystickPosSetting
		local InCoverTouchVirtualJoystickScaleSetting = UserConfigSettings.InCoverTouchVirtualJoystickScaleSetting
		if InCoverTouchVirtualJoystickPosSetting and InCoverTouchVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(InCoverTouchVirtualJoystickPosSetting.Section, InCoverTouchVirtualJoystickPosSetting.Key,InCoverTouchVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(InCoverTouchVirtualJoystickScaleSetting.Section, InCoverTouchVirtualJoystickScaleSetting.Key,InCoverTouchVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[3].CanvasSlot:SetPosition(Pos)
			self.MainBattleUserDefine_Tb[3].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
			self.MainBattleUserDefine_Tb[3].Pos = Pos
			self.MainBattleUserDefine_Tb[3].Scale = Scale
		end

		-- »»µ¯
		local WeaponReloadVirtualJoystickPosSetting = UserConfigSettings.WeaponReloadVirtualJoystickPosSetting
		local WeaponReloadVirtualJoystickScaleSetting = UserConfigSettings.WeaponReloadVirtualJoystickScaleSetting
		if WeaponReloadVirtualJoystickPosSetting and WeaponReloadVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(WeaponReloadVirtualJoystickPosSetting.Section, WeaponReloadVirtualJoystickPosSetting.Key,WeaponReloadVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(WeaponReloadVirtualJoystickScaleSetting.Section, WeaponReloadVirtualJoystickScaleSetting.Key,WeaponReloadVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[4].CanvasSlot:SetPosition(Pos)
			self.MainBattleUserDefine_Tb[4].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
			self.MainBattleUserDefine_Tb[4].Pos = Pos
			self.MainBattleUserDefine_Tb[4].Scale = Scale
		end

		-- Ãé×¼
		local AimTargetVirtualJoystickPosSetting = UserConfigSettings.AimTargetVirtualJoystickPosSetting
		local AimTargetVirtualJoystickScaleSetting = UserConfigSettings.AimTargetVirtualJoystickScaleSetting
		if AimTargetVirtualJoystickPosSetting and AimTargetVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(AimTargetVirtualJoystickPosSetting.Section, AimTargetVirtualJoystickPosSetting.Key,AimTargetVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(AimTargetVirtualJoystickScaleSetting.Section, AimTargetVirtualJoystickScaleSetting.Key,AimTargetVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[5].CanvasSlot:SetPosition(Pos)
			self.MainBattleUserDefine_Tb[5].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
			self.MainBattleUserDefine_Tb[5].Pos = Pos
			self.MainBattleUserDefine_Tb[5].Scale = Scale
		end

		-- ÓÒ¿ª»ð
		local RightStartFireVirtualJoystickPosSetting = UserConfigSettings.RightStartFireVirtualJoystickPosSetting
		local RightStartFireVirtualJoystickScaleSetting = UserConfigSettings.RightStartFireVirtualJoystickScaleSetting
		if RightStartFireVirtualJoystickPosSetting and RightStartFireVirtualJoystickScaleSetting then
			local Pos = UserConfigSettings:GetVector2D(RightStartFireVirtualJoystickPosSetting.Section, RightStartFireVirtualJoystickPosSetting.Key,RightStartFireVirtualJoystickPosSetting.Value)
			local Scale = UserConfigSettings:GetFloat(RightStartFireVirtualJoystickScaleSetting.Section, RightStartFireVirtualJoystickScaleSetting.Key,RightStartFireVirtualJoystickScaleSetting.Scale)
			self.MainBattleUserDefine_Tb[6].CanvasSlot:SetPosition(Pos)
			self.MainBattleUserDefine_Tb[6].TouchJoystickCanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
			self.MainBattleUserDefine_Tb[6].Pos = Pos
			self.MainBattleUserDefine_Tb[6].Scale = Scale
		end

	end

end
return UIBattleMainUserDefine_C
