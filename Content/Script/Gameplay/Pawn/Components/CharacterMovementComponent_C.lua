require "UnLua"

local CharacterMovementComponent_C = class(CharacterMovementComponent_C)


function CharacterMovementComponent_C:Initialize(CharacterBase)
    -------------------------------------------------------------------------
    --- Blueprint中定义的变量
    -------------------------------------------------------------------------
 
    -- lua定义-----------
    self.CharacterBase = CharacterBase;
    self.MoveMentLayer2Type = 0;
end

function CharacterMovementComponent_C:Receive_BeginPlay()

    self.CharacterBase.MoveMentBaseType = ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_STAND;
    self.CharacterBase.MoveMentLayer1Type =  ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK;
    self.MoveMentLayer2Type = self.CharacterBase:GetMoveMentLayer2Type();
end


function CharacterMovementComponent_C:Receive_EndPlay()
end

function CharacterMovementComponent_C:Receive_TickComponent(DeltaTime)
    if not self.CharacterBase:IsValid() then
        return
    end

    self:UpdateRollMovementAction(DeltaTime)
end

function CharacterMovementComponent_C:Receive_GetMaxSpeed(MaxSpeed)
    local addMoveSpeed = 0.0;

    if self:IsRunning() then
        addMoveSpeed = MaxSpeed * self.CharacterBase:GetRepAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_RUN_MOVESPEED)/ MATH_SCALE_10K
    elseif self:IsWeaponAim() then 
        addMoveSpeed = MaxSpeed * self.CharacterBase:GetRepAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_AIM_MOVESPEED)/ MATH_SCALE_10K
    elseif self:IsInRolling() then
        local rollSpeedValue = 0.0
        local rollSpeedCurve = self.CharacterBase.RollSpeedCurve
        if rollSpeedCurve and rollSpeedCurve.GetFloatValue then
            rollSpeedValue = rollSpeedCurve:GetFloatValue(self.CharacterBase.RollTickTimer)
        end

        addMoveSpeed = MaxSpeed * rollSpeedValue / MATH_SCALE_10K
    elseif self:IsDown() then
        addMoveSpeed = MaxSpeed * self.CharacterBase:GetRepAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_DOWN_MOVESPEED)/ MATH_SCALE_10K
    else
        addMoveSpeed = MaxSpeed * self.CharacterBase:GetRepAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_WALK_MOVESPEED)/ MATH_SCALE_10K
    end

    if self.CharacterBase and (self.CharacterBase:IsEnteringCover() or self.CharacterBase:IsChangingCover()) then
        addMoveSpeed = MaxSpeed * self.CharacterBase:GetRepAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ENTERCOVER_MOVESPEED)/ MATH_SCALE_10K
    end

    MaxSpeed = MaxSpeed + addMoveSpeed;

    return MaxSpeed;
end

function CharacterMovementComponent_C:Receive_GetMaxAcceleration(MaxAcceleration)
    local addAcceleration = 0.0

    if self.CharacterBase and self.CharacterBase:IsValid() then
        if self.CharacterBase:IsEnteringCover() or self.CharacterBase:IsChangingCover() then
            addAcceleration = MaxAcceleration * self.CharacterBase:GetRepAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ENTERCOVER_ACCELERATION) / MATH_SCALE_10K
        elseif self:IsInRolling() then
            addAcceleration = MaxAcceleration * self.CharacterBase:GetRepAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ROLL_ACCELERATION) / MATH_SCALE_10K
        end
    end

    MaxAcceleration = MaxAcceleration + addAcceleration

    return MaxAcceleration
end

--- layer2状态同步
function CharacterMovementComponent_C:Receive_OnRep_MoveMentLayer2Type(PreMoveMentLayer2Type)
    
    self.MoveMentLayer2Type = self.CharacterBase:GetMoveMentLayer2Type();
    self:MaybeMoveMentLayer2ChangeStatus(PreMoveMentLayer2Type,self.MoveMentLayer2Type);
end

----------------------切换基础状态(待机/弯腰/下蹲)----------------------
function CharacterMovementComponent_C:ChangeMoveMentBaseType(NeweMoveMentBaseType, NeedRpc)
    
    if NeweMoveMentBaseType < ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_STAND or 
        NeweMoveMentBaseType > ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_CROUCH then
            return;
    end

    local PreMoveMentBaseType = self.CharacterBase.MoveMentBaseType;
    self.CharacterBase.MoveMentBaseType = NeweMoveMentBaseType;

    self:MoveMentBaseTypeStuaChange(PreMoveMentBaseType, NeweMoveMentBaseType)

    if not  self.CharacterBase:HasAuthority() and NeedRpc then
        -- 蓝图中的方法
        self.CharacterBase:ServerChangeMoveMentBaseType(NeweMoveMentBaseType)
    end

end

function CharacterMovementComponent_C:MoveMentBaseTypeStuaChange(PreMoveMentBaseType, NewMoveMentBaseType)

    if PreMoveMentBaseType == ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_STAND then

    elseif PreMoveMentBaseType == ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_BOW then
    
    elseif PreMoveMentBaseType == ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_CROUCH then
        self:OnLeave_Crouch()
    end

    if NewMoveMentBaseType == ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_STAND then

    elseif NewMoveMentBaseType == ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_BOW then
    
    elseif NewMoveMentBaseType == ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_CROUCH then
        self:OnEnter_Crouch()
    end

end

function CharacterMovementComponent_C:OnEnter_Crouch()
   self.CharacterBase:UpdateCharacterCameraMode()
end

function CharacterMovementComponent_C:OnLeave_Crouch()
    self.CharacterBase:UpdateCharacterCameraMode()
end

----------------------切换层级1状态(走/跑/跳/战术翻滚/倒地)----------------------
function CharacterMovementComponent_C:ChangeMoveMentLayer1Type(NewMoveMentLayer1Type)
    if NewMoveMentLayer1Type < ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK or
        NewMoveMentLayer1Type > ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_MAX then
            return;
    end

    local PreMoveMentLayer1Type = self.CharacterBase.MoveMentLayer1Type;
    self.CharacterBase.MoveMentLayer1Type = NewMoveMentLayer1Type;

    self:MoveMentLayer1TypeStuaChange(PreMoveMentLayer1Type, NewMoveMentLayer1Type)

    if not self.CharacterBase:HasAuthority() then
        -- 蓝图中的方法
        self.CharacterBase:ServerChangeMoveMentLayer1Type(NewMoveMentLayer1Type)
    end
end

function CharacterMovementComponent_C:MoveMentLayer1TypeStuaChange(PreNewMoveMentLayer1Type, NewMoveMentLayer1Type)
    if PreNewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK then

    elseif PreNewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RUN then
        self:OnLeave_Running()
    elseif PreNewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_JUMP then

    elseif PreNewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_DOWN then
        self:OnLeave_Down()
    elseif PreNewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_ROLL then
        self:OnLeave_Rolling()
    elseif PreNewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RESURGETEAMMATE then
        self:OnLeave_ResurgeTeammate()
    elseif PreNewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RAGDOLL then
        self:OnLeave_Ragdoll()
    end

    if NewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK then

    elseif NewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RUN then
        self:OnEnter_Running()
    elseif NewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_JUMP then

    elseif NewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_DOWN then
        self:OnEnter_Down()
    elseif NewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_ROLL then
        self:OnEnter_Rolling()
    elseif NewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RESURGETEAMMATE then
        self:OnEnter_ResurgeTeammate()
    elseif NewMoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RAGDOLL then
        self:OnEnter_Ragdoll()
    end
end

function CharacterMovementComponent_C:OnEnter_Ragdoll()
    print("OnEnter_Ragdoll ...")
end

function CharacterMovementComponent_C:OnLeave_Ragdoll()
    print("OnLeave_Ragdoll ...")
end

function CharacterMovementComponent_C:OnEnter_ResurgeTeammate()
    if not self.CharacterBase:HasAuthority() or UE4.UKismetSystemLibrary.IsStandalone(self.CharacterBase) then
        self.CharacterBase:ResurgeTeammate_C(false)
    end

    self.CharacterBase.bUseControllerRotationYaw = false
end

function CharacterMovementComponent_C:OnLeave_ResurgeTeammate()
    if not self.CharacterBase:HasAuthority() or UE4.UKismetSystemLibrary.IsStandalone(self.CharacterBase) then
        self.CharacterBase:ResurgeTeammate_C(true)
    end

    --self.CharacterBase.Controller:OnResetControllerCameraStart(self , self.OnResetControllerCameraStart_Callback)
    self.CharacterBase.bUseControllerRotationYaw = true
end

function CharacterMovementComponent_C:OnEnter_Running()
    self.CharacterBase:UpdateCharacterCameraMode()
    self.CharacterBase:UpdateResetControlPitch(true)
end

function CharacterMovementComponent_C:OnLeave_Running()
    self.CharacterBase:UpdateCharacterCameraMode()
    self.CharacterBase:UpdateResetControlPitch(false)
end

function CharacterMovementComponent_C:OnEnter_Rolling()
    self.CharacterBase.RollTickTimer = 0.0

    self.CharacterBase:UpdateCharacterCameraMode()
    self.CharacterBase:OnHandleRollingStart()
end

function CharacterMovementComponent_C:OnLeave_Rolling()
    self.CharacterBase.RollTickTimer = 0.0

    self.CharacterBase:UpdateCharacterCameraMode()
    self.CharacterBase:OnHandleRollingEnd()
end

function CharacterMovementComponent_C:OnEnter_Down()
    self.CharacterBase:UpdateCharacterCameraMode()
end

function CharacterMovementComponent_C:OnLeave_Down()
    self.CharacterBase:UpdateCharacterCameraMode()
end

---------------------切换层级2状态(武器瞄准/掩体探头/掩体QTE)-----------------
function CharacterMovementComponent_C:ChangeMoveMentLayer2Type(NewMoveMentLayer2Type, inFlag)
    if NewMoveMentLayer2Type < ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_NONE or
        NewMoveMentLayer2Type >= ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_MAX then
            return;
    end

    local PreMoveMentLayer2Type = self.MoveMentLayer2Type;

    local mask = NewMoveMentLayer2Type
    self.MoveMentLayer2Type = LuaMarcoUtils.AND_VALUE(self.MoveMentLayer2Type, mask, inFlag and 1 or 0);

    if self.CharacterBase:HasAuthority() then
        self.CharacterBase:SetMoveMentLayer2Type(self.MoveMentLayer2Type);

        self:MaybeMoveMentLayer2ChangeStatus(PreMoveMentLayer2Type,self.MoveMentLayer2Type);
    else
        -- 蓝图中的方法
        self.CharacterBase:ServerChangeMoveMentLayer2Type(NewMoveMentLayer2Type, inFlag)
    end

    if NewMoveMentLayer2Type == ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM then
        LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_AIMINGCHANGE)
    end
end

function CharacterMovementComponent_C:MaybeMoveMentLayer2ChangeStatus(PreMoveMentLayer2Type, NewMoveMentLayer2Type)
    for i = ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_NONE + 1, ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_MAX-1 do

        local mask = i;
        local preValue = self.CharacterBase:IsContainMoveMentLayer2Type(PreMoveMentLayer2Type, mask);
        local newValue = self.CharacterBase:IsContainMoveMentLayer2Type(NewMoveMentLayer2Type, mask);

        if preValue ~= newValue then
            self:MoveMentLayer2TypeStuaChange(i, newValue);
        end

    end
end

--切换layer2状态
function CharacterMovementComponent_C:MoveMentLayer2TypeStuaChange(NewMoveMentLayer2Type, Flag)

    if NewMoveMentLayer2Type == ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM then
        if Flag then self:OnEnter_WeaponAim() else self:OnLeave_WeaponAim() end
    elseif NewMoveMentLayer2Type == ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVERHEADOUT then
        if Flag then self:OnEnter_CoverHeadOut() else self:OnLeave_CoverHeadOut() end
    elseif NewMoveMentLayer2Type == ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVERQTE then
        if Flag then self:OnEnter_CoverQTE() else self:OnLeave_CoverQTE() end
    elseif NewMoveMentLayer2Type == ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_CLIMB then

    elseif NewMoveMentLayer2Type == ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_HOLDEQUIP_LEFT then
        if Flag then self:OnEnter_HoldEquip_Left() else self:OnLeave_HoldEquip_Left() end
    elseif NewMoveMentLayer2Type == ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVEREDGE_LEFT then
        self.CharacterBase:UpdateCharacterCameraMode()
    elseif NewMoveMentLayer2Type == ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVEREDGE_RIGHT then
        self.CharacterBase:UpdateCharacterCameraMode()
    elseif NewMoveMentLayer2Type == ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_MortalBlows then
        if Flag then self:OnEnter_MortalBlows() else self:OnLeave_MortalBlows() end
    end
end

function CharacterMovementComponent_C:OnEnter_WeaponAim()
    self.CharacterBase:UpdateCharacterCameraMode()
end

function CharacterMovementComponent_C:OnLeave_WeaponAim()
     
     self.CharacterBase:UpdateCharacterCameraMode()
end

function CharacterMovementComponent_C:OnEnter_CoverHeadOut()

end

function CharacterMovementComponent_C:OnLeave_CoverHeadOut()

end

function CharacterMovementComponent_C:OnEnter_CoverQTE()

end

function CharacterMovementComponent_C:OnLeave_CoverQTE()

end

function CharacterMovementComponent_C:OnEnter_HoldEquip_Left()
    self.CharacterBase:UpdateCharacterCameraMode()
end

function CharacterMovementComponent_C:OnLeave_HoldEquip_Left()
    self.CharacterBase:UpdateCharacterCameraMode()
end

--- 进入处决
function CharacterMovementComponent_C:OnEnter_MortalBlows()
    UE4.UKismetSystemLibrary.PrintString(self.CharacterBase , "OnEnter_MortalBlows ...")

    local MortalBlowsAnimation = self.CharacterBase:FindAnimationByID(20001);

    if MortalBlowsAnimation ~= nil  then
        print("OnEnter_MortalBlows ... 1")
        if MortalBlowsAnimation.Pawn3P then
            print("OnEnter_MortalBlows ... 2")
            self.CharacterBase:PlayAnimMontage(MortalBlowsAnimation.Pawn3P , 1.0 , "Dafault");
        end
    end
end

--- 退出处决
function CharacterMovementComponent_C:OnLeave_MortalBlows()
    UE4.UKismetSystemLibrary.PrintString(self.CharacterBase , "OnLeave_MortalBlows ...")
end

-------------------------------------------------------------------------
-- 条件判断接口
-------------------------------------------------------------------------

function CharacterMovementComponent_C:IsStand()
    return self.CharacterBase.MoveMentBaseType == ECharacterMoveMentLayerBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_STAND and true or false;
end

function CharacterMovementComponent_C:IsBow()
    return self.CharacterBase.MoveMentBaseType == ECharacterMoveMentLayerBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_BOW and true or false;
end

function CharacterMovementComponent_C:IsCrouching()
    return self.CharacterBase.CharacterMovement:IsCrouching();
end

function CharacterMovementComponent_C:IsRunning()
    return self.CharacterBase.MoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RUN and true or false;
end

function CharacterMovementComponent_C:IsDown()
    return self.CharacterBase.MoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_DOWN and true or false;
end

function CharacterMovementComponent_C:IsInRolling()
    return self.CharacterBase.MoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_ROLL and true or false;
end

function CharacterMovementComponent_C:IsResurgeTeammate()
    return self.CharacterBase.MoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RESURGETEAMMATE and true or false;
end

function CharacterMovementComponent_C:IsRagdoll()
    return self.CharacterBase.MoveMentLayer1Type == ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RAGDOLL and true or false;
end

function CharacterMovementComponent_C:IsWeaponAim()
    local mask = ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM;
    return self.CharacterBase:IsContainMoveMentLayer2Type(self.MoveMentLayer2Type, mask);
end

function CharacterMovementComponent_C:IsCoverHeadOut()
    local mask = ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVERHEADOUT;
    return self.CharacterBase:IsContainMoveMentLayer2Type(self.MoveMentLayer2Type, mask);
end

function CharacterMovementComponent_C:IsCoverQTE()
    local mask = ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVERQTE;
    return self.CharacterBase:IsContainMoveMentLayer2Type(self.MoveMentLayer2Type, mask);
end

function CharacterMovementComponent_C:IsHoldEquipLeft()
    local mask = ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_HOLDEQUIP_LEFT;
    return self.CharacterBase:IsContainMoveMentLayer2Type(self.MoveMentLayer2Type, mask);
end

function CharacterMovementComponent_C:IsCoverLeft()
    local mask = ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVEREDGE_LEFT;
    return self.CharacterBase:IsContainMoveMentLayer2Type(self.MoveMentLayer2Type, mask);
end

function CharacterMovementComponent_C:IsCoverRight()
    local mask = ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVEREDGE_RIGHT;
    return self.CharacterBase:IsContainMoveMentLayer2Type(self.MoveMentLayer2Type, mask);
end

function CharacterMovementComponent_C:IsMortalBlows()
    local mask = ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_MortalBlows;
    return self.CharacterBase:IsContainMoveMentLayer2Type(self.MoveMentLayer2Type, mask);
end

-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------

-- 翻滚间隔时间
function CharacterMovementComponent_C:GetRollDurationTime()
    if self.CharacterBase and self.CharacterBase:IsValid() then
        return self.CharacterBase.RollDurationTime
    end

    return 0.0
end

--- 翻滚计时逻辑
function CharacterMovementComponent_C:UpdateRollMovementAction(DeltaTime)
    if self:IsInRolling() then
        self.CharacterBase.RollTickTimer = self.CharacterBase.RollTickTimer + DeltaTime

        --if not self.CharacterBase:HasAuthority() then
        if self.CharacterBase:GetLocalRole() == UE4.ENetRole.ROLE_AutonomousProxy or UE4.UKismetSystemLibrary.IsStandalone(self.CharacterBase) then
            if self:IsUpdateRollTimeFinish() then

                self.CharacterBase:UpdateRollMovement_C(true)
                return
            end

            self.CharacterBase:UpdateRollMovement_C(false)
        else
            if UE4.UKismetSystemLibrary.IsStandalone(self.CharacterBase) then
                if self:IsUpdateRollTimeFinish() then
                    self.CharacterBase:UpdateRollMovement_C(true)
                    return
                end

                self.CharacterBase:UpdateRollMovement_C(false)
            end
        end
    end
end

function CharacterMovementComponent_C:IsUpdateRollTimeFinish()
    if self.CharacterBase.RollTickTimer >= self:GetRollDurationTime() then
        return true
    end

    return false
end

return CharacterMovementComponent_C
