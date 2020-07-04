require "UnLua"

local BP_ShootWeaponRecoilComponent_C = Class()

function BP_ShootWeaponRecoilComponent_C:Initialize(Initializer)

    -------------------------------------------------------------------------
    --- Lua中定义的变量
    -------------------------------------------------------------------------
    self.RecoilType = UE4.EWeaponRecoilType.ERecoilType_None
    self.RecoilAxisPitch = 0.0
    self.CurReturnAxisPitch = 0.0

    self.RecoilReady = false;
    self.RecoilReadyStartTime = 0.0;

    self.UpRecoilSizeVal = UE4.FVector()
    self.UpRecoilRotator = UE4.FRotator()
    self.CurAddRecoilRotator = UE4.FRotator()
end

function BP_ShootWeaponRecoilComponent_C:OnInit()

    self.ShootWeaponBase = self:GetOwner():Cast(UE4.ABP_ShootWeapon_C)
end

--function BP_ShootWeaponRecoilComponent_C:ReceiveBeginPlay()
--end

--function BP_ShootWeaponRecoilComponent_C:ReceiveEndPlay()
--end

function BP_ShootWeaponRecoilComponent_C:ReceiveTick(DeltaSeconds)
    self:UpdateShootRecoil(DeltaSeconds)
end

function BP_ShootWeaponRecoilComponent_C:StartShootRecoil()
    if not self.ShootWeaponBase then
        return
    end

    local CharacterBase = self.ShootWeaponBase:GetOwnerPawn()
    if CharacterBase and CharacterBase:IsLocallyControlled() then
        CharacterBase:ClearFiringAxisPitch()
    end

    self.RecoilAxisPitch = 0.0
    self.CurReturnAxisPitch = 0.0

    self.RecoilReady = false;
    self.RecoilReadyStartTime = 0.0;
end

function BP_ShootWeaponRecoilComponent_C:SimulateShootRecoil(BurstCounter)

    local ShootWeaponBase = self.ShootWeaponBase;
    if not ShootWeaponBase then
        return
    end

    local PlayerController = ShootWeaponBase:GetOwnerController()
    if not PlayerController then
        return
    end

    if ShootWeaponBase.WeaponRecoilData.UseRecoilCurve and ShootWeaponBase.WeaponRecoilData.RecoilCurve then
        local RecoilCurveValue = ShootWeaponBase.WeaponRecoilData.RecoilCurve:GetVectorValue(BurstCounter)
        self.UpRecoilSizeVal.X = RecoilCurveValue.X
        self.UpRecoilSizeVal.Y = RecoilCurveValue.Y

        self.UpRecoilSizeVal.X = math.min(ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceHoriMax, self.UpRecoilSizeVal.X)
        self.UpRecoilSizeVal.Y = math.min(ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceVertMaxVal, self.UpRecoilSizeVal.Y)

        local WeaponAttrMgr = ShootWeaponBase:GetShootWeaponAttrMgr()
        if WeaponAttrMgr then
            self.UpRecoilSizeVal.X = self.UpRecoilSizeVal.X - math.abs(self.UpRecoilSizeVal.X) * 
                WeaponAttrMgr:GetAttr(Ds_ResWeaponAttrType.EN_WEAPONATTR_FIRERECOIL) / MATH_SCALE_10K
            self.UpRecoilSizeVal.Y = self.UpRecoilSizeVal.Y - math.abs(self.UpRecoilSizeVal.Y) * 
                WeaponAttrMgr:GetAttr(Ds_ResWeaponAttrType.EN_WEAPONATTR_FIRERECOIL) / MATH_SCALE_10K
        end
    else
        if ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceVertSpeed == 0.0 then
            return
        end

        local HoriRandom = (ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceHoriRandomMin > 0 and ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceHoriRandomMax > 0) and
            math.random(ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceHoriRandomMin, ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceHoriRandomMax) or 0.0
        self.UpRecoilSizeVal.X = ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceHoriBaseVal + HoriRandom
        self.UpRecoilSizeVal.Y = ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceVertBaseVal

        self.UpRecoilSizeVal.X = math.min(ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceHoriMax, self.UpRecoilSizeVal.X)
        self.UpRecoilSizeVal.Y = math.min(ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceVertMaxVal, self.UpRecoilSizeVal.Y)

        local WeaponAttrMgr = ShootWeaponBase:GetShootWeaponAttrMgr()
        if WeaponAttrMgr then
            self.UpRecoilSizeVal.X = self.UpRecoilSizeVal.X - math.abs(self.UpRecoilSizeVal.X) * 
                WeaponAttrMgr:GetAttr(Ds_ResWeaponAttrType.EN_WEAPONATTR_FIRERECOIL) / MATH_SCALE_10K
            self.UpRecoilSizeVal.Y = self.UpRecoilSizeVal.Y - math.abs(self.UpRecoilSizeVal.Y) * 
                WeaponAttrMgr:GetAttr(Ds_ResWeaponAttrType.EN_WEAPONATTR_FIRERECOIL) / MATH_SCALE_10K
        end
        -- 左右随机
        self.UpRecoilSizeVal.X = self.UpRecoilSizeVal.X * (math.random(0, 1) > 0 and 1 or -1)
    end

    local SizeX = 0
    local SizeY = 0
    SizeX,SizeY = PlayerController:GetViewportSize(SizeX, SizeY)

    self.UpRecoilSizeVal.X = math.floor(self.UpRecoilSizeVal.X * SizeY / RESOLUTIONFACTOR_HEIGHT);
    self.UpRecoilSizeVal.Y = math.floor(self.UpRecoilSizeVal.Y * SizeY / RESOLUTIONFACTOR_HEIGHT);

    local ScreenPosition = UE4.FVector2D(SizeX / 2 + self.UpRecoilSizeVal.X, SizeY / 2 - self.UpRecoilSizeVal.Y)
    
    local WorldPosition = UE4.FVector()
    local WorldDirection = UE4.FVector()
    if not UE4.UGameplayStatics.DeprojectScreenToWorld(PlayerController, ScreenPosition, WorldPosition, WorldDirection) then
        print("SimulateShootRecoil DeprojectScreenToWorld is failed! ScreenPosition:"..ScreenPosition.X.."|"..ScreenPosition.Y)
        return
    end

    local TargetRotator = WorldDirection:ToRotator()
    local CameraRotator = ShootWeaponBase:GetOwnerPawnRotation()

    self.UpRecoilRotator.Yaw = TargetRotator.Yaw - CameraRotator.Yaw
    self.UpRecoilRotator.Pitch = TargetRotator.Pitch - CameraRotator.Pitch

    if math.abs(self.UpRecoilRotator.Yaw) >= 90.0 then
        self.UpRecoilRotator.Yaw = self.UpRecoilRotator.Yaw > 0 and self.UpRecoilRotator.Yaw - 360.0 or self.UpRecoilRotator.Yaw + 360.0
    end

    if math.abs(self.UpRecoilRotator.Pitch) >= 90.0 then
        self.UpRecoilRotator.Pitch = self.UpRecoilRotator.Pitch > 0 and self.UpRecoilRotator.Pitch - 360.0 or self.UpRecoilRotator.Pitch + 360.0
    end

    -- 倍数
    self.UpRecoilRotator.Yaw = self.UpRecoilRotator.Yaw / PlayerController.InputYawScale
    self.UpRecoilRotator.Pitch = self.UpRecoilRotator.Pitch / PlayerController.InputPitchScale

    self.RecoilType = UE4.EWeaponRecoilType.ERecoilType_Up
    self.CurAddRecoilRotator = UE4.FRotator()
end

function BP_ShootWeaponRecoilComponent_C:StartBackRecoil()

    local ShootWeaponBase = self.ShootWeaponBase;
    if not ShootWeaponBase then
        return
    end

    local PlayerController = ShootWeaponBase:GetOwnerController()
    if not PlayerController then
        self.RecoilType = UE4.EWeaponRecoilType.ERecoilType_None
        return
    end

	self.UpRecoilSizeVal.X = 0
	self.UpRecoilSizeVal.Y = self.UpRecoilSizeVal.Y * ShootWeaponBase.WeaponRecoilData.FiringRecoil.BackForceVertRatio

	self.UpRecoilRotator.Pitch = self.UpRecoilRotator.Pitch * (-ShootWeaponBase.WeaponRecoilData.FiringRecoil.BackForceVertRatio)

	self.CurAddRecoilRotator = UE4.FRotator()
	self.RecoilType = UE4.EWeaponRecoilType.ERecoilType_Back
end

function BP_ShootWeaponRecoilComponent_C:StartWaitStopRecoil(CharacterBase)

	self.RecoilAxisPitch = CharacterBase:GetFiringRecoilAxisPitch()
    if self.RecoilAxisPitch == 0.0 then
        self.RecoilType = UE4.EWeaponRecoilType.ERecoilType_None
    else

	    local FiringInputAxisPitch = CharacterBase:GetFiringInputAxisPitch()

	    -- a. 开火的时候手动往上移动相机
        if FiringInputAxisPitch < 0.0 then
            -- 回复的点C在起始点A上方的，只回复后坐力的部分
        -- b. 开火的时候手动往下移动相机
        elseif FiringInputAxisPitch > 0.0 then
            if self.RecoilAxisPitch + FiringInputAxisPitch < 0.0 then
                -- 回复的点C在起始点A上方的，但是往下移动了相机，所以最多回到起始点A
                self.RecoilAxisPitch = self.RecoilAxisPitch + FiringInputAxisPitch
            elseif self.RecoilAxisPitch + FiringInputAxisPitch > 0.0 then
                -- 回复的点C在起始点A下方的，最多回到起始点A
                if self.RecoilAxisPitch + FiringInputAxisPitch < math.abs(self.RecoilAxisPitch) then
                    self.RecoilAxisPitch = self.RecoilAxisPitch + FiringInputAxisPitch
                else
                    self.RecoilAxisPitch = math.abs(self.RecoilAxisPitch)
                end
            end
        end
    
        self.RecoilType = UE4.EWeaponRecoilType.RecoilType_WaitStop
        self.RecoilReadyStartTime = UE4.UGameplayStatics.GetTimeSeconds(CharacterBase:GetWorld())
    end
end

function BP_ShootWeaponRecoilComponent_C:UpdateShootRecoil(DeltaSeconds)
    local ShootWeaponBase = self.ShootWeaponBase;
    if not ShootWeaponBase then
        return
    end

	local CharacterBase = ShootWeaponBase:GetOwnerPawn()
	if not CharacterBase or not CharacterBase:IsLocallyControlled() then
        return
    end

	if self.RecoilType == UE4.EWeaponRecoilType.ERecoilType_None then
        return
    end

	if self.RecoilType == UE4.EWeaponRecoilType.ERecoilType_Up then
        if ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceHoriSpeed > 0.1 then
            
            --X
			local deltaX_Cost = math.abs(self.UpRecoilSizeVal.X) / ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceHoriSpeed
			local RotatorYaw = math.abs(self.UpRecoilRotator.Yaw)
			local Sign = UE4.UKismetMathLibrary.SignOfFloat(self.UpRecoilRotator.Yaw)

			if deltaX_Cost ~= 0 then
				local deltaYaw = DeltaSeconds * RotatorYaw / deltaX_Cost

				if (self.CurAddRecoilRotator.Yaw + deltaYaw) >= RotatorYaw then
					deltaYaw = RotatorYaw - self.CurAddRecoilRotator.Yaw
                end

				self.CurAddRecoilRotator.Yaw = self.CurAddRecoilRotator.Yaw + deltaYaw
				CharacterBase:AddControllerYawInput(deltaYaw * Sign)
            end
        end

        --Y
        local deltaY_Cost = math.abs(self.UpRecoilSizeVal.Y) / ShootWeaponBase.WeaponRecoilData.FiringRecoil.UpForceVertSpeed
        local RotatorPich = math.abs(self.UpRecoilRotator.Pitch)
        local Sign = UE4.UKismetMathLibrary.SignOfFloat(self.UpRecoilRotator.Pitch)

        local deltaPitch = DeltaSeconds * RotatorPich / deltaY_Cost

        if (self.CurAddRecoilRotator.Pitch + deltaPitch) >= RotatorPich then
            deltaPitch = RotatorPich - self.CurAddRecoilRotator.Pitch

            self.RecoilType = UE4.EWeaponRecoilType.ERecoilType_WaitBack
        end

        self.CurAddRecoilRotator.Pitch = self.CurAddRecoilRotator.Pitch + deltaPitch
        CharacterBase:LookUpRecoil(deltaPitch * Sign)

	elseif self.RecoilType == UE4.EWeaponRecoilType.ERecoilType_WaitBack then
		self:StartBackRecoil()

    elseif self.RecoilType == UE4.EWeaponRecoilType.ERecoilType_Back then
        
        local bBackEnd = true;
        --Y
        if  ShootWeaponBase.WeaponRecoilData.FiringRecoil.BackForceVertRatio > 0.0 and 
            ShootWeaponBase.WeaponRecoilData.FiringRecoil.BackForceVertSpeed > 0.1 then
            
			local deltaY_Cost = self.UpRecoilSizeVal.Y / ShootWeaponBase.WeaponRecoilData.FiringRecoil.BackForceVertSpeed
			local RotatorPich = math.abs(self.UpRecoilRotator.Pitch)
			local Sign = UE4.UKismetMathLibrary.SignOfFloat(self.UpRecoilRotator.Pitch)

            local deltaPitch = DeltaSeconds * RotatorPich / deltaY_Cost
            
			if (self.CurAddRecoilRotator.Pitch + deltaPitch) >= RotatorPich then
				deltaPitch = RotatorPich - self.CurAddRecoilRotator.Pitch
            else
                bBackEnd = false;
            end

            self.CurAddRecoilRotator.Pitch = self.CurAddRecoilRotator.Pitch + deltaPitch
            CharacterBase:LookUpRecoil(deltaPitch * Sign)
        end

        if bBackEnd then
            self:StartWaitStopRecoil(CharacterBase)
        end
    
    elseif self.RecoilType == UE4.EWeaponRecoilType.RecoilType_WaitStop then

        local curTime = UE4.UGameplayStatics.GetTimeSeconds(CharacterBase:GetWorld());   
        if curTime - self.RecoilReadyStartTime >= ShootWeaponBase.WeaponRecoilData.RecoilReturnWaitTime then
            self.RecoilType =  UE4.EWeaponRecoilType.ERecoilType_Stop
        end

    elseif self.RecoilType == UE4.EWeaponRecoilType.ERecoilType_Stop then

		if ShootWeaponBase.WeaponRecoilData.RecoilReturnCurve then
			local remainPitch = self.RecoilAxisPitch - self.CurReturnAxisPitch
			local returnPitch = ShootWeaponBase.WeaponRecoilData.RecoilReturnCurve:GetFloatValue(remainPitch)
			if math.abs(returnPitch) > math.abs(remainPitch) or returnPitch == 0.0 then
				returnPitch = remainPitch

				CharacterBase:ClearFiringAxisPitch()
				self.RecoilType = UE4.EWeaponRecoilType.ERecoilType_None
            end
			
			self.CurReturnAxisPitch = self.CurReturnAxisPitch + returnPitch
			CharacterBase:AddControllerPitchInput(returnPitch * -1.0)

		else
            CharacterBase:AddControllerPitchInput(self.RecoilAxisPitch * -1.0)
            
			CharacterBase:ClearFiringAxisPitch()
			self.RecoilType = UE4.EWeaponRecoilType.ERecoilType_None
        end
    end
end

function BP_ShootWeaponRecoilComponent_C:StopShootRecoil()
    
    self.RecoilReady = true;

end

return BP_ShootWeaponRecoilComponent_C
