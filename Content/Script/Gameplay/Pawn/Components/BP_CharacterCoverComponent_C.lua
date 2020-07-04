require "UnLua"

local BP_CharacterCoverComponent_C = Class()

function BP_CharacterCoverComponent_C:Initialize(Initializer)
    -------------------------------------------------------------------------
    --- Blueprint中定义的配置数据
    -------------------------------------------------------------------------
    self.DistanceTraceForward       = 500
    self.DistanceTraceBackward      = 100
    self.DistanceOffsetRight        = 40
    self.HighCoverHeightPercent     = 0.7
    self.DistanceToCover            = 50.0
    self.MinCoverMoveAngle          = 50.0
    self.MaxCoverMoveAngle          = 130.0

    -------------------------------------------------------------------------
    --- Blueprint中定义的变量
    -------------------------------------------------------------------------
    -- 掩体状态
    self.TakeCoverState     = ETakeCoverState.ETakeCoverState_None
    self.TakeCoverActor     = nil

    -- 朝向掩体的角度
    self.FaceToCoverAngle = 0
    self.FaceToCoverCrossZ = 0

    -- 掩体中探头的状态
    self.CoverProbeState = UE4.ECoverProbeState.ECoverProbeState_None

    -- 沿样条线的距离
    self.DistanceAlongSpline = 0
    
    -------------------------------------------------------------------------
    --- Lua中定义的变量
    -------------------------------------------------------------------------
    self.IsCanEnterCover = false
    self.LastCover = nil

    self.ChangeCoverSpline = nil
    self.ChangeCoverAxisValue = 0
    self.ChangeCoverDistanceAlongSpline = 0
end

function BP_CharacterCoverComponent_C:ReceiveEndPlay()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase and CharacterBase.CharacterMovement then
        CharacterBase.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Walking)
    end
end

function BP_CharacterCoverComponent_C:ReceiveTick(DeltaSeconds)

    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase then
        if CharacterBase:GetLocalRole() == UE4.ENetRole.ROLE_AutonomousProxy or UE4.UKismetSystemLibrary.IsStandalone(self) then
            if self.TakeCoverState == ETakeCoverState.ETakeCoverState_None then
                local TraceStart, TraceEnd = self:GetTraceInfo(false, CharacterBase.InputAxisForward, CharacterBase.InputAxisRight)
                local HitResult = self:TraceCover(TraceStart, TraceEnd, 40)
                if HitResult then
                    local CoverActor = HitResult.Actor and HitResult.Actor:Cast(UE4.ABP_LevelCoverBase_C) or nil
                    if CoverActor then
                        self.IsCanEnterCover = true
                        -- 在冲锋的时候碰到掩体，则进入掩体
                        if CharacterBase:IsRunning() then
                            self:EnterCover(true)
                        end
                    else
                        self.IsCanEnterCover = false
                    end
                else
                    self.IsCanEnterCover = false
                end
                self:CoverIndicator()

            elseif self.TakeCoverState == ETakeCoverState.ETakeCoverState_Entering then
                self:MoveToCover()
            elseif self.TakeCoverState == ETakeCoverState.ETakeCoverState_Covering then
                local Velocity = CharacterBase.CharacterMovement:GetVelocity()
                if Velocity:Size() > 0 or CharacterBase.InputAxisForward ~= 0 or CharacterBase.InputAxisRight ~= 0 then
                    local SplineLocation = self:GetLocationAtDistanceAlongSpline(self.DistanceAlongSpline)
                    local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)

                    -- 前后端浮点数有精度问题，导致行走不顺畅，所以由客户端驱动行走
                    self:MoveAlongSpline(SplineLocation, SplineRotation)
                end
            elseif self.TakeCoverState == ETakeCoverState.ETakeCoverState_Changing then
                self:ChangeToCover()
                self:ChangeToCoverAlongSpline()
            elseif self.TakeCoverState == ETakeCoverState.ETakeCoverState_Vaulting then
                if CharacterBase.CharacterMovement then
                    print("--------------------- MovementMode ", CharacterBase.CharacterMovement.MovementMode)
                    print("--------------------- IsFalling ", CharacterBase.CharacterMovement:IsFalling())
                end
            end

        end

        if CharacterBase.InputAxisForward == 0 and CharacterBase.InputAxisRight == 0 then
            if self.CoverProbeState ~= UE4.ECoverProbeState.ECoverProbeState_None then
                self:SetCoverProbeState(UE4.ECoverProbeState.ECoverProbeState_None)
            end
        end

    end

    if self.TakeCoverState == ETakeCoverState.ETakeCoverState_Covering then
        self:FindCoverAlongSpline()
    end
    
    --- 探头指示
    self:ChangAndVaultCoverIndicator()
end


-------------------------------------------------------------------------
--- 设置数据接口
-------------------------------------------------------------------------
--- 设置掩体使用的状态
function BP_CharacterCoverComponent_C:SetTakeCoverState(NewState)
    self.TakeCoverState = NewState


    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase then
        CharacterBase:UpdateCharacterCameraMode()
    end

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_COVERSTATENOTIFY , self.TakeCoverState)
end

--- 设置当前贴靠的掩体
function BP_CharacterCoverComponent_C:SetTakeCoverActor(NewActor)
    self.TakeCoverActor = NewActor
end

--- 设置距离轨道起点的长度
function BP_CharacterCoverComponent_C:SetDistanceAlongSpline(NewDistanceAlongSpline)
    self.DistanceAlongSpline = NewDistanceAlongSpline
end

--- 设置切换掩体的轨道
function BP_CharacterCoverComponent_C:SetChangeCoverSpline(NewChangeCoverSpline)
    self.ChangeCoverSpline = NewChangeCoverSpline
end

--- 设置切换掩体移动的输入轴值
function BP_CharacterCoverComponent_C:SetChangeCoverAxisValue(NewChangeCoverAxisValue)
    self.ChangeCoverAxisValue = NewChangeCoverAxisValue
end

--- 设置距离切换掩体的轨道起点的长度
function BP_CharacterCoverComponent_C:SetChangeCoverDistanceAlongSpline(NewDistanceAlongSpline)
    self.ChangeCoverDistanceAlongSpline = NewDistanceAlongSpline
end

--- RPC函数 设置与掩体的Angle、CrossZ，同步给其他玩家
function BP_CharacterCoverComponent_C:SetPlayerFaceToCoverAngleAndCrossZ(FaceToCoverAngle, FaceToCoverCrossZ)
    if FaceToCoverAngle == self.FaceToCoverAngle and FaceToCoverCrossZ == self.FaceToCoverCrossZ then
        return
    end

    self.FaceToCoverAngle = FaceToCoverAngle
    self.FaceToCoverCrossZ = FaceToCoverCrossZ

    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase then
        -- 请求服务器
        if CharacterBase:GetLocalRole() < UE4.ENetRole.ROLE_Authority then
            self:ServerSetPlayerFaceToCoverAngleAndCrossZ(FaceToCoverAngle, FaceToCoverCrossZ)
        end
    end
end

-- 掩体中探头状态
function BP_CharacterCoverComponent_C:SetCoverProbeState(NewProbeState)
    if NewProbeState == self.CoverProbeState then
        return
    end

    self.CoverProbeState = NewProbeState

    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase then
        -- 请求服务器
        if CharacterBase:GetLocalRole() < UE4.ENetRole.ROLE_Authority then
            self:ServerSetCoverProbeState(NewProbeState)
        end
    end
end

--- 胶囊体的位置
function BP_CharacterCoverComponent_C:SetCharacterLocationAlongSpline(SplineLocation)
    if not SplineLocation then
        return
    end

    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return
    end

    local CharacterLocation = CharacterBase:K2_GetActorLocation()

    SplineLocation:Set(SplineLocation.X, SplineLocation.Y, CharacterLocation.Z)
    CharacterBase:K2_SetActorLocation(SplineLocation, true)
end

--- 胶囊体的朝向
function BP_CharacterCoverComponent_C:SetCharacterRotationAlongSpline(SplineRotation)
    if not SplineRotation then
        return
    end

    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return
    end

    SplineRotation:Set(0, SplineRotation.Yaw, 0)
    SplineRotation = UE4.UKismetMathLibrary.ComposeRotators(SplineRotation, UE4.FRotator(0, -90, 0))
    CharacterBase:K2_SetActorRotation(SplineRotation, true)
end

--- RPC函数 控制器的朝向
function BP_CharacterCoverComponent_C:SetControlRotationAlongSpline(SplineRotation)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller then
        return
    end

    SplineRotation:Set(0, SplineRotation.Yaw, 0)
    SplineRotation = UE4.UKismetMathLibrary.ComposeRotators(SplineRotation, UE4.FRotator(0, -90, 0))

    local CharacterRotation = CharacterBase:K2_GetActorRotation()
    local ControlRotation = CharacterBase.Controller:GetControlRotation()
    local ControlToCharacterYaw = ControlRotation.Yaw - CharacterRotation.Yaw

    ControlRotation.Yaw = SplineRotation.Yaw + ControlToCharacterYaw
    CharacterBase.Controller:SetControlRotation(ControlRotation)

    -- 请求服务器
    if CharacterBase:GetLocalRole() < UE4.ENetRole.ROLE_Authority then
        self:ServerSetControlRotationAlongSpline(SplineRotation)
    end
end

--- 蹲
function BP_CharacterCoverComponent_C:SetCharacterCrouch()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return
    end

    if CharacterBase:GetLocalRole() == UE4.ENetRole.ROLE_Authority and not UE4.UKismetSystemLibrary.IsStandalone(self) then
        return
    end

    --- 高掩体
    if self:GetCoverHeightType() == UE4.ECoverHeightType.ECoverHeightType_High then
        CharacterBase:UnCrouch(true)
    elseif self:GetCoverHeightType() == UE4.ECoverHeightType.ECoverHeightType_Low then
        --- 视角与轴线的夹角
        local FaceToAxisAngle = self:GetLocalPlayerFaceToAxisAngle()
        if FaceToAxisAngle < self.StandCrouchAngle and CharacterBase:IsWeaponAim() then
            CharacterBase:UnCrouch(true)
        else
            CharacterBase:Crouch(true)
        end
    end
end

-- 进入掩体时设置移动状态
function BP_CharacterCoverComponent_C:SetCharacterMovementCoverQTE(bInCover)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase and CharacterBase.CharacterMovementComponent then               
        if bInCover then
            -- 进掩体时, 取消开镜
            if CharacterBase:IsWeaponAim() then
                CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM, false)
            end

            -- 进掩体时, 取消冲锋
            if CharacterBase:IsRunning() then
                CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK)
            end
            
            CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVERQTE, true)
        else
            CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVERQTE, false)
        end
    end
end

-- 设置角色移动状态 -- 沿着掩体，在边缘的时候需要调整相机
function BP_CharacterCoverComponent_C:SetCharacterMovementCoverEdge(bInCover)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase and CharacterBase.CharacterMovementComponent then
        local bChange = false
        if bInCover then
            local SplineLength = self:GetSplineLength()

            -- 到左边缘的距离
            local DistanceToLeft = self.DistanceAlongSpline
            -- 到右边缘的距离
            local DistanceToRight = SplineLength - self.DistanceAlongSpline

            -- 左边缘
            if DistanceToLeft <= self.EnterCoverEdgeDistance and math.abs(DistanceToLeft) <= math.abs(DistanceToRight) then
                -- 进入左边缘
                if not CharacterBase.CharacterMovementComponent:IsCoverLeft() then
                    CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVEREDGE_LEFT, true)
                end
                -- 退出右边缘
                if CharacterBase.CharacterMovementComponent:IsCoverRight() then
                    CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVEREDGE_RIGHT, false)
                end
                return
            -- 右边缘
            elseif DistanceToRight <= self.EnterCoverEdgeDistance and math.abs(DistanceToRight) < math.abs(DistanceToLeft) then
                -- 退出左边缘
                if not CharacterBase.CharacterMovementComponent:IsCoverRight() then
                    CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVEREDGE_RIGHT, true)
                end
                -- 进入右边缘
                if CharacterBase.CharacterMovementComponent:IsCoverLeft() then
                    CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVEREDGE_LEFT, false)
                end
                return
            end
        end

        -- 退出左边缘
        if CharacterBase.CharacterMovementComponent:IsCoverLeft() then
            CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVEREDGE_LEFT, false)
        end
        -- 退出右边缘
        if CharacterBase.CharacterMovementComponent:IsCoverRight() then
            CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_COVEREDGE_RIGHT, false)
        end
    end
end

--- 切换持武器的手  移动
function BP_CharacterCoverComponent_C:SetCurrentEquipHand_Move(MoveAxisValue)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller or not CharacterBase.EquipComponent or not CharacterBase.CharacterMovementComponent  then
        return false
    end

    if not self:IsAllowChangeAxis() or CharacterBase:IsWeaponAim() then
        return false
    end

    --- 轨道朝向
    local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)
    SplineRotation:Set(0, SplineRotation.Yaw, 0)
    SplineRotation = UE4.UKismetMathLibrary.ComposeRotators(SplineRotation, UE4.FRotator(0, -90, 0))
    SplineRotation:Normalize()

    -- 相机朝向
    local ControlRotation = CharacterBase.Controller:GetControlRotation()
    ControlRotation:Set(0, ControlRotation.Yaw, 0)
    local ControlForward = ControlRotation:GetForwardVector()
    ControlForward:Normalize()

    -- 角度
    local ControlAngle = UE4.UKismetMathLibrary.DegAcos(ControlForward:CosineAngle2D(SplineRotation:ToVector()))
    if ControlAngle > self.StandCrouchAngle then
        return false
    end

    if MoveAxisValue > 0 and CharacterBase:IsHoldEquipLeft() then
        --- 切换装备到右手
        CharacterBase.EquipComponent:ChangeCurrentEquipHand(true)
        --- 切换视角到右手
        CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(UE4.ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_HOLDEQUIP_LEFT, false)

        return true
    elseif MoveAxisValue < 0 and not CharacterBase:IsHoldEquipLeft() then
        --- 切换装备到左手
        CharacterBase.EquipComponent:ChangeCurrentEquipHand(false)
        --- 切换视角到左手
        CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(UE4.ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_HOLDEQUIP_LEFT, true)

        return true
    end

    return false
end

--- 切换持武器的手  旋转
function BP_CharacterCoverComponent_C:SetCurrentEquipHand_Turn()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller or not CharacterBase.CharacterMovementComponent then
        return
    end

    if not self:IsAllowChangeAxis() then
        return
    end

    --- 视角与轴线的夹角
    local FaceToAxisAngle = self:GetLocalPlayerFaceToAxisAngle()
    if FaceToAxisAngle < self.StandCrouchAngle then
        return
    end

    --- 切换轴向
    local FaceToAxisCrossZ = self:GetLocalPlayerFaceToAxisCrossZ()
    if FaceToAxisCrossZ < 0 and CharacterBase:IsHoldEquipLeft() then
        --- 切换装备到右手
        CharacterBase.EquipComponent:ChangeCurrentEquipHand(true)
        --- 切换视角到右手
        CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(UE4.ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_HOLDEQUIP_LEFT, false)
    elseif FaceToAxisCrossZ >= 0 and not CharacterBase:IsHoldEquipLeft() then
        --- 切换装备到左手
        CharacterBase.EquipComponent:ChangeCurrentEquipHand(false)
        --- 切换视角到左手
        CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(UE4.ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_HOLDEQUIP_LEFT, true)
    end
end

function BP_CharacterCoverComponent_C:UpdateCharacterCameraMode_Turn()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or CharacterBase:IsWeaponAim() then
        return
    end

    if not self:IsAllowChangeAxis() then
        return
    end

    --- 视角与轴线的夹角
    local FaceToAxisAngle = self:GetLocalPlayerFaceToAxisAngle()
    if FaceToAxisAngle >= self.StandCrouchAngle then
        return
    end

    local FaceToAxisCrossZ = self:GetLocalPlayerFaceToAxisCrossZ()
    if (FaceToAxisCrossZ < 0 and CharacterBase:IsHoldEquipLeft()) or (FaceToAxisCrossZ >= 0 and not CharacterBase:IsHoldEquipLeft()) then
        CharacterBase:UpdateCharacterCameraMode()
    end
end

-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------
-- 获取搜索信息
function BP_CharacterCoverComponent_C:GetTraceInfo(bRunEnter, InputAxisForward, InputAxisRight)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return UE4.FVector(), UE4.FVector()
    end

    local CharacterRotation = CharacterBase:K2_GetActorRotation()
    CharacterRotation:Set(0, CharacterRotation.Yaw, 0)

    local CharacterForward = CharacterRotation:GetForwardVector()

    -- 扫描起点
    local TraceStart = CharacterBase:K2_GetActorLocation()

    -- 高度偏移
    local _, BoxExtent = CharacterBase:GetActorBounds(true)
    local HeightAdjust = (BoxExtent.Z - BoxExtent.Z * self.HighCoverHeightPercent) * -1
    TraceStart.Z = TraceStart.Z + HeightAdjust

    -- 扫描方向
    local TraceDirection = nil

    local Velocity = CharacterBase.CharacterMovement:GetVelocity()
    if Velocity:Size() > 0 then
        if (InputAxisForward == 0 and InputAxisRight == 0) then
            TraceDirection = CharacterForward
        else
            local IncludeAngle = UE4.UKismetMathLibrary.DegAcos(Velocity:CosineAngle2D(CharacterForward))
            if IncludeAngle > 90 then
                TraceDirection = CharacterRotation:GetRightVector() * InputAxisRight
            else
                TraceDirection = Velocity
            end
        end
    else
        TraceDirection = CharacterForward
    end

    if not TraceDirection then
        TraceDirection = UE4.FVector()
    end
    TraceDirection:Normalize()

    -- 扫描终点
    local TraceDistance = bRunEnter and self.DistanceTraceRunEnter or self.DistanceTraceForward
    local TraceEnd = TraceStart + TraceDirection * TraceDistance

    return TraceStart, TraceEnd
end

-- 获取沿着轨道扫描信息
function BP_CharacterCoverComponent_C:GetTraceInfoAlongSpline()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return UE4.FVector(), UE4.FVector()
    end

    local CharacterRotation = CharacterBase:K2_GetActorRotation()
    CharacterRotation:Set(0, CharacterRotation.Yaw, 0)

    -- 扫描起点
    local TraceStart = CharacterBase:K2_GetActorLocation()

    -- 前后偏移
    local CharacterForward = CharacterRotation:GetForwardVector()
    CharacterForward:Normalize()

    -- 高度偏移
    local _, BoxExtent = CharacterBase:GetActorBounds(true)
    local HeightAdjust = (BoxExtent.Z - BoxExtent.Z * self.HighCoverHeightPercent) * -1
    TraceStart.Z = TraceStart.Z + HeightAdjust

    -- 扫描终点
    local TraceEnd = TraceStart + CharacterForward * self.DistanceTraceBackward

    return TraceStart, TraceEnd
end

-- 计算 样条曲线距离
function BP_CharacterCoverComponent_C:CalculateDistanceAlongSpline(CharacterBase, MoveAxisValue, CoverSpline, CurDistanceAlongSpline)
    if not CharacterBase or not CharacterBase.CharacterMovement or not CoverSpline then
        return 0
    end

    local SplineLength = CoverSpline:GetSplineLength()

    -- 圆形掩体
    if CoverSpline.CircularMovement then
        if CurDistanceAlongSpline > SplineLength then
            CurDistanceAlongSpline = 0.1
        elseif CurDistanceAlongSpline <= 0.0 then
            CurDistanceAlongSpline = SplineLength
        end
    else
        if CurDistanceAlongSpline > SplineLength then
            CurDistanceAlongSpline = SplineLength
        elseif CurDistanceAlongSpline <= 0.0 then
            CurDistanceAlongSpline = 0.0
        end
    end

    local DistanceToMove = 0
    local Velocity = CharacterBase.CharacterMovement:GetVelocity()
    if Velocity:Size() > 0 then
        DistanceToMove = Velocity:Size() * MoveAxisValue * UE4.UGameplayStatics.GetWorldDeltaSeconds(self)
    else
        DistanceToMove = MoveAxisValue * UE4.UGameplayStatics.GetWorldDeltaSeconds(self)
    end

    local DistanceAlongSpline = CurDistanceAlongSpline + DistanceToMove
    return DistanceAlongSpline
end

-- 轨道坐标
function BP_CharacterCoverComponent_C:GetLocationAtDistanceAlongSpline(DistanceAlongSpline)
    local CoverSpline = self.TakeCoverActor and self.TakeCoverActor.CoverSpline or nil
    if not CoverSpline then
        print("---------------- GetLocationAtDistanceAlongSpline CoverSpline ", CoverSpline)
        return UE4.FVector()
    end

    return CoverSpline:GetLocationAtDistanceAlongSpline(DistanceAlongSpline)
end

-- 轨道朝向
function BP_CharacterCoverComponent_C:GetRotationAtDistanceAlongSpline(DistanceAlongSpline)
    local CoverSpline = self.TakeCoverActor and self.TakeCoverActor.CoverSpline or nil
    if not CoverSpline then
        print("---------------- GetRotationAtDistanceAlongSpline CoverSpline ", CoverSpline)
        return UE4.FRotator()
    end

    return CoverSpline:GetRotationAtDistanceAlongSpline(DistanceAlongSpline)
end

-- 轨道长度
function BP_CharacterCoverComponent_C:GetSplineLength()
    local CoverSpline = self.TakeCoverActor and self.TakeCoverActor.CoverSpline or nil
    if not CoverSpline then
        print("---------------- GetSplineLength CoverSpline ", CoverSpline)
        return 0
    end

    return CoverSpline:GetSplineLength()
end

-- 给相机动画提供接口 -- 离边缘的距离
function BP_CharacterCoverComponent_C:GetDistanceEdgeAlongSpline()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return 0
    end

    local SplineLength = self:GetSplineLength()

    local DistanceEdge = self.DistanceAlongSpline
    --- 左手持枪时与左边缘的距离
    if CharacterBase:IsHoldEquipLeft() then
        DistanceEdge = math.max(0, self.DistanceAlongSpline)
    --- 右手持枪时与右边缘的距离
    else
        DistanceEdge = math.max(0, SplineLength - self.DistanceAlongSpline)
    end

    return math.max(0, DistanceEdge)
end

--- 获取掩体高低类型
function BP_CharacterCoverComponent_C:GetCoverHeightType()
    return self.TakeCoverActor and self.TakeCoverActor.CoverHeightType
end

--- 本地客戶端 移动方向与掩体轴线的Angle
function BP_CharacterCoverComponent_C:GetLocalMoveFaceToCoverAngle(InDirection, InAxisValue)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return 0
    end

    --- 轨道朝向
    local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)
    SplineRotation:Set(0, SplineRotation.Yaw, 0)
    --- 轴线朝向
    SplineRotation = UE4.UKismetMathLibrary.ComposeRotators(SplineRotation, UE4.FRotator(0, -90, 0))
    SplineRotation:Normalize()

    --- 移动方向
    local MoveDirection = InDirection * InAxisValue
    MoveDirection:Normalize()

    return UE4.UKismetMathLibrary.DegAcos(MoveDirection:CosineAngle2D(SplineRotation:ToVector()))
end

--- 本地客戶端 移动方向与掩体轴线的CrossZ
function BP_CharacterCoverComponent_C:GetLocalMoveFaceToCoverCrossZ(InDirection, InAxisValue)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return 0
    end

    --- 轨道朝向
    local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)
    SplineRotation:Set(0, SplineRotation.Yaw, 0)
    --- 轴线朝向
    SplineRotation = UE4.UKismetMathLibrary.ComposeRotators(SplineRotation, UE4.FRotator(0, -90, 0))
    SplineRotation:Normalize()

    --- 移动方向
    local MoveDirection = InDirection * InAxisValue
    MoveDirection:Normalize()

    return MoveDirection:Cross(SplineRotation:ToVector()).Z
end

--- 本地客戶端 控制器与掩体轴线的Angle
function BP_CharacterCoverComponent_C:GetLocalPlayerFaceToAxisAngle()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller or not CharacterBase.CharacterMovementComponent then
        return 0
    end

    --- 轨道朝向
    local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)
    SplineRotation:Set(0, SplineRotation.Yaw, 0)
    --- 轴线朝向
    SplineRotation = UE4.UKismetMathLibrary.ComposeRotators(SplineRotation, UE4.FRotator(0, -90, 0))
    SplineRotation:Normalize()

    --- 相机朝向
    local ControlRotation = CharacterBase.Controller:GetControlRotation()
    ControlRotation:Set(0, ControlRotation.Yaw, 0)
    local ControlForward = ControlRotation:GetForwardVector()
    ControlForward:Normalize()

    --- 视角与轴线的夹角
    return UE4.UKismetMathLibrary.DegAcos(ControlForward:CosineAngle2D(SplineRotation:ToVector()))
end

--- 本地客戶端 控制器与掩体轴线的CrossZ
function BP_CharacterCoverComponent_C:GetLocalPlayerFaceToAxisCrossZ()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller or not CharacterBase.CharacterMovementComponent then
        return 0
    end

    --- 轨道朝向
    local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)
    SplineRotation:Set(0, SplineRotation.Yaw, 0)
    --- 轴线朝向
    SplineRotation = UE4.UKismetMathLibrary.ComposeRotators(SplineRotation, UE4.FRotator(0, -90, 0))
    SplineRotation:Normalize()


    --- 相机朝向
    local ControlRotation = CharacterBase.Controller:GetControlRotation()
    ControlRotation:Set(0, ControlRotation.Yaw, 0)
    local ControlForward = ControlRotation:GetForwardVector()
    ControlForward:Normalize()

    return ControlForward:Cross(SplineRotation:ToVector()).Z
end

--- 本地客戶端 控制器与掩体的Angle
function BP_CharacterCoverComponent_C:GetLocalPlayerFaceToCoverAngle()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller then
        return 0
    end

    -- 轨道朝向
    local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)
    SplineRotation:Set(0, SplineRotation.Yaw, 0)
    SplineRotation:Normalize()

    -- 相机朝向
    local ControlRotation = CharacterBase.Controller:GetControlRotation()
    ControlRotation:Set(0, ControlRotation.Yaw, 0)
    local ControlForward = ControlRotation:GetForwardVector()
    ControlForward:Normalize()

    return UE4.UKismetMathLibrary.DegAcos(ControlForward:CosineAngle2D(SplineRotation:ToVector()))
end

--- 本地客戶端 控制器与掩体的CrossZ
function BP_CharacterCoverComponent_C:GetLocalPlayerFaceToCoverCrossZ()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller then
        return 0
    end

    -- 轨道朝向
    local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)
    SplineRotation:Set(0, SplineRotation.Yaw, 0)
    SplineRotation:Normalize()

    -- 相机朝向
    local ControlRotation = CharacterBase.Controller:GetControlRotation()
    ControlRotation:Set(0, ControlRotation.Yaw, 0)
    local ControlForward = ControlRotation:GetForwardVector()
    ControlForward:Normalize()

    return ControlForward:Cross(SplineRotation:ToVector()).Z
end

--- 提供给动作蓝图使用  蓝图接口
function BP_CharacterCoverComponent_C:GetPlayerFaceToCoverAngle()
    return self.FaceToCoverAngle
end

--- 提供给动作蓝图使用  蓝图接口
function BP_CharacterCoverComponent_C:GetPlayerFaceToCoverCrossZ()
    return self.FaceToCoverCrossZ
end

--- 获取角色到掩体的距离
function BP_CharacterCoverComponent_C:GetCharacterToCoverDistSquared2D()
    local CharacterBase = self:GetOwner() and self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C) or nil
    if not CharacterBase then
        return 0
    end

    local CharacterLocation = CharacterBase:K2_GetActorLocation()
    local DestLocation = self:GetLocationAtDistanceAlongSpline(self.DistanceAlongSpline)

    return CharacterLocation:DistSquared2D(DestLocation)
end

-------------------------------------------------------------------------
-- 条件判断接口
-------------------------------------------------------------------------

-- 是否可以扫描掩体
function BP_CharacterCoverComponent_C:CanTraceCover()
    return self.TakeCoverState == ETakeCoverState.ETakeCoverState_None
end

-- 正在进入掩体
function BP_CharacterCoverComponent_C:IsEnteringCover()
    return self.TakeCoverState == ETakeCoverState.ETakeCoverState_Entering
end

-- 正在使用掩体
function BP_CharacterCoverComponent_C:IsCovering()
    return self.TakeCoverState == ETakeCoverState.ETakeCoverState_Covering
end

-- 正在翻越掩体
function BP_CharacterCoverComponent_C:IsVaultingCover()
    return self.TakeCoverState == ETakeCoverState.ETakeCoverState_Vaulting
end

-- 正在切换掩体
function BP_CharacterCoverComponent_C:IsChangingCover()
    return self.TakeCoverState == ETakeCoverState.ETakeCoverState_Changing
end

--- 掩体中是否可以移动
function BP_CharacterCoverComponent_C:CanMove()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase then
        local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
        if UserConfigSettings then
            if CharacterBase:IsWeaponAim() then
                --- 开镜移动
                local CoveringAimMoveSetting = UserConfigSettings.CoveringAimMoveSetting
                if CoveringAimMoveSetting then
                    if not UserConfigSettings:GetBool(CoveringAimMoveSetting.Section, CoveringAimMoveSetting.Key, CoveringAimMoveSetting.Value) then
                        return false
                    end
                end
            elseif CharacterBase:IsFiring() then
                --- 腰射移动
                local CoveringWaistShootMoveSetting = UserConfigSettings.CoveringWaistShootMoveSetting
                if CoveringWaistShootMoveSetting then
                    if not UserConfigSettings:GetBool(CoveringWaistShootMoveSetting.Section, CoveringWaistShootMoveSetting.Key, CoveringWaistShootMoveSetting.Value) then
                        return false
                    end
                end
            end
        end
    end

    return true
end

--- 掩体中是否可以开镜
function BP_CharacterCoverComponent_C:CanAim()
    if not self.TakeCoverActor or not self.TakeCoverActor.bCanAim then
        return false
    end

    return true
end

--- 掩体中是否可以开火
function BP_CharacterCoverComponent_C:CanFire()
    if not self.TakeCoverActor or not self.TakeCoverActor.bCanFire then
        return false
    end

    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase and CharacterBase.Controller then
        if CharacterBase:IsWeaponAim() then
            return true
        end

        local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
        if UserConfigSettings then
            --- 腰射功能
            local CoveringWaistShootSetting = UserConfigSettings.CoveringWaistShootSetting
            if CoveringWaistShootSetting then
                if not UserConfigSettings:GetBool(CoveringWaistShootSetting.Section, CoveringWaistShootSetting.Key, CoveringWaistShootSetting.Value) then
                    return false
                end
            end
        end

        -- 模型朝向
        local CharacterRotation = CharacterBase:K2_GetActorRotation()
        CharacterRotation:Set(0, CharacterRotation.Yaw, 0)

        local CharacterForward = CharacterRotation:GetForwardVector()
        CharacterForward:Normalize()

        local ControlRotation = CharacterBase.Controller:GetControlRotation()
        ControlRotation:Set(0, ControlRotation.Yaw, 0)
        local ControlForward = ControlRotation:GetForwardVector()

        local IncludeAngle = UE4.UKismetMathLibrary.DegAcos(ControlForward:CosineAngle2D(CharacterForward))
        if IncludeAngle >= 30 then
            return true
        end
    end

    return false
end

--- 判断是否进入掩体时的右侧
function BP_CharacterCoverComponent_C:IsEnterCoverHandRight(CoverActor, DistanceAlongSpline)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller then
        return false
    end

    -- 轨道朝向
    local SplineRotation = self:GetRotationAtDistanceAlongSpline(DistanceAlongSpline)
    SplineRotation:Set(0, SplineRotation.Yaw, 0)
    SplineRotation:Normalize()

    -- 相机朝向
    local ControlRotation = CharacterBase.Controller:GetControlRotation()
    ControlRotation:Set(0, ControlRotation.Yaw, 0)
    local ControlForward = ControlRotation:GetForwardVector()
    ControlForward:Normalize()

    -- 角度
    local ControlForwardToCoverAngle = UE4.UKismetMathLibrary.DegAcos(ControlForward:CosineAngle2D(SplineRotation:ToVector()))

    --- 计算进入掩体时的初始轴向
    if ControlForwardToCoverAngle < self.EnterCoverRightAxisAngle then
        return true
    end

    return false
end

--- Debug 允许高低掩体切换
function BP_CharacterCoverComponent_C:IsAllowChangeHeight()
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local AllowChangeHeightSetting = UserConfigSettings.AllowChangeHeightSetting
        if AllowChangeHeightSetting then
            return UserConfigSettings:GetBool(AllowChangeHeightSetting.Section, AllowChangeHeightSetting.Key, AllowChangeHeightSetting.Value)
        end
    end

    return false
end


--- Debug 允许切换轴向
function BP_CharacterCoverComponent_C:IsAllowChangeAxis()
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local AllowChangeCameraSetting = UserConfigSettings.AllowChangeCameraSetting
        if AllowChangeCameraSetting then
            return UserConfigSettings:GetBool(AllowChangeCameraSetting.Section, AllowChangeCameraSetting.Key, AllowChangeCameraSetting.Value)
        end
    end

    return false
end

function BP_CharacterCoverComponent_C:CanEnterCover()
    return self.IsCanEnterCover
end

function BP_CharacterCoverComponent_C:CanVaultCover()
    return (self.TakeCoverActor and self.TakeCoverActor.bCanVault) and true or false
end

-- 是否准备翻越掩体，探头的判断
function BP_CharacterCoverComponent_C:IsReadyVaultCover()
    if self.TakeCoverState ~= UE4.ETakeCoverState.ETakeCoverState_Covering then
        return false
    end

    return (self.CoverProbeState == UE4.ECoverProbeState.ECoverProbeState_Vault) and true or false
end

function BP_CharacterCoverComponent_C:CanChangeCover()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return false
    end

    if not self.TakeCoverActor then
        return false
    end

    local bFlag = false
    if CharacterBase:IsHoldEquipLeft() then
        -- 掩体左侧、左手持枪
        if CharacterBase.CharacterMovementComponent:IsCoverLeft() then
            bFlag = (self.TakeCoverActor.LeftChangeCoverActor and self.TakeCoverActor.LeftChangeCoverSpline) and true or false
        end
    else
        -- 掩体右侧、右手持枪
        if CharacterBase.CharacterMovementComponent:IsCoverRight() then
            bFlag = (self.TakeCoverActor.RightChangeCoverActor and self.TakeCoverActor.RightChangeCoverSpline) and true or false
        end
    end

    return bFlag
end

-- 是否准备翻滚出掩体，探头的判断
function BP_CharacterCoverComponent_C:IsReadyForRoll()
    if self.TakeCoverState ~= UE4.ETakeCoverState.ETakeCoverState_Covering then
        return false
    end

    return (self.CoverProbeState == UE4.ECoverProbeState.ECoverProbeState_Roll) and true or false
end

-- 冲锋离开掩体
function BP_CharacterCoverComponent_C:CanRunLeaveCover()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return false
    end

    if not self.TakeCoverActor then
        return false
    end

    local bFlag = false
    if CharacterBase:IsHoldEquipLeft() then
        -- 掩体左侧、左手持枪
        bFlag = CharacterBase.CharacterMovementComponent:IsCoverLeft() and true or false
    else
        -- 掩体右侧、右手持枪
        bFlag = CharacterBase.CharacterMovementComponent:IsCoverRight() and true or false
    end

    return bFlag
end

-- 是否准备冲锋出掩体，探头的判断
function BP_CharacterCoverComponent_C:IsReadyForRun()
    if self.TakeCoverState ~= UE4.ETakeCoverState.ETakeCoverState_Covering then
        return false
    end

    return (self.CoverProbeState == UE4.ECoverProbeState.ECoverProbeState_Run) and true or false
end

-- 是否准备切换掩体，探头的判断
function BP_CharacterCoverComponent_C:IsReadyChangeCover()
    if self.TakeCoverState ~= UE4.ETakeCoverState.ETakeCoverState_Covering then
        return false
    end

    return (self.CoverProbeState == UE4.ECoverProbeState.ECoverProbeState_Change) and true or false
end


-- 在掩体左侧边缘
function BP_CharacterCoverComponent_C:IsCoverLeft()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase and CharacterBase.CharacterMovementComponent then
        return CharacterBase.CharacterMovementComponent:IsCoverLeft()
    end

    return false
end

-- 在掩体右侧边缘
function BP_CharacterCoverComponent_C:IsCoverRight()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase and CharacterBase.CharacterMovementComponent then
        return CharacterBase.CharacterMovementComponent:IsCoverRight()
    end

    return false
end

-------------------------------------------------------------------------
-- 进出掩体的接口
-------------------------------------------------------------------------
-- 搜索掩体
function BP_CharacterCoverComponent_C:TraceCover(TraceStart, TraceEnd, Radius)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return nil
    end

    local HitResult = UE4.FHitResult()
    local ActorsToIgnore = UE4.TArray(UE4.AActor)
    ActorsToIgnore:Add(CharacterBase)

    -- UE4.EDrawDebugTrace.ForOneFrame
    -- UE4.EDrawDebugTrace.None
    if UE4.UKismetSystemLibrary.SphereTraceSingle(self, TraceStart, TraceEnd, Radius, UE4.ETraceTypeQuery.Cover, false,
        ActorsToIgnore, UE4.EDrawDebugTrace.None, HitResult, true) then
        -- 获取掩体组件
        return HitResult
    end

    return nil
end

-- 进入掩体
function BP_CharacterCoverComponent_C:EnterCover(bRunEnter)
    if self.TakeCoverState == ETakeCoverState.ETakeCoverState_None then
        local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
        if CharacterBase then
            if UE4.UKismetSystemLibrary.IsStandalone(self) then
                self:ServerEnterCoverInternal(bRunEnter, CharacterBase.InputAxisForward, CharacterBase.InputAxisRight)
            else
                -- 请求服务器
                self:ServerEnterCover(bRunEnter, CharacterBase.InputAxisForward, CharacterBase.InputAxisRight)
            end
        end
    end
end

-- 服务器 执行进入掩体
function BP_CharacterCoverComponent_C:ServerEnterCoverInternal(bRunEnter, InputAxisForward, InputAxisRight)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller then
        return
    end

    local TraceStart, TraceEnd = self:GetTraceInfo(bRunEnter, InputAxisForward, InputAxisRight)
    local Radius = bRunEnter and 20 or 40

    local HitResult = self:TraceCover(TraceStart, TraceEnd, Radius)
    if HitResult then
        local CoverActor = HitResult.Actor and HitResult.Actor:Cast(UE4.ABP_LevelCoverBase_C) or nil
        if not CoverActor or not CoverActor.CoverSpline then
            return
        end

        local DistanceAlongSpline = CoverActor.CoverSpline:GetDistanceAlongSpline(HitResult.ImpactPoint)

        -- 进入掩体
        self:EnterCoverInternal(CoverActor, DistanceAlongSpline)

        -- 通知客户端
        if not UE4.UKismetSystemLibrary.IsStandalone(self) then
            self:ClientEnterCover(CoverActor, DistanceAlongSpline)
        end
    end
end

-- 进入掩体的内部执行体
function BP_CharacterCoverComponent_C:EnterCoverInternal(CoverActor, DistanceAlongSpline)
    if not CoverActor or not CoverActor.CoverSpline then
        return
    end

    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.CharacterMovementComponent then
        return
    end

    self:SetTakeCoverState(ETakeCoverState.ETakeCoverState_Entering)
    self:SetTakeCoverActor(CoverActor)
    self:SetDistanceAlongSpline(DistanceAlongSpline)

    if self:IsAllowChangeAxis() then
        --- 切换装备的左右手
        local bRight = self:IsEnterCoverHandRight(CoverActor, DistanceAlongSpline)
        CharacterBase.EquipComponent:ChangeCurrentEquipHand(bRight)
        --- 切换视角的左右手
        CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(UE4.ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_HOLDEQUIP_LEFT, not bRight)
    end

    -- 下蹲
    if CoverActor.CoverHeightType == UE4.ECoverHeightType.ECoverHeightType_Low then
        CharacterBase:Crouch(true)
    else
        CharacterBase:UnCrouch(true)
    end

    -- 固定角色朝向
    CharacterBase.bUseControllerRotationYaw = false
    -- 设置角色朝向
    self:SetCharacterRotationAlongSpline(self:GetRotationAtDistanceAlongSpline(DistanceAlongSpline))

    self:PerformCoveringTurn()

    -- 掩体状态。进掩体时, 取消开镜和冲锋
    self:SetCharacterMovementCoverQTE(true)
    -- 掩体边缘状态
    self:SetCharacterMovementCoverEdge(true)

    -- 进掩体时, 取消开火
    if CharacterBase.EquipComponent and CharacterBase.EquipComponent:IsFiring() then
        CharacterBase.EquipComponent:StopFire()
    end
end

-- 移向掩体
function BP_CharacterCoverComponent_C:MoveToCover()
    if self:IsEnteringCover() then
        local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
        if not CharacterBase or not CharacterBase.Controller then
            return
        end

        local CharacterLocation = CharacterBase:K2_GetActorLocation()
        local DestLocation = self:GetLocationAtDistanceAlongSpline(self.DistanceAlongSpline)
        
        local DistSquared2D = CharacterLocation:DistSquared2D(DestLocation)
        if DistSquared2D <= self.DistanceToCover * self.DistanceToCover then
            -- 到达掩体时手动强制修改一下角色位置
            local SplineLocation = self:GetLocationAtDistanceAlongSpline(self.DistanceAlongSpline)
            local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)
            -- 前后端浮点数有精度问题，导致行走不顺畅，所以由客户端驱动行走
            self:MoveAlongSpline(SplineLocation, SplineRotation)

            -- 到达掩体
            self:ArrivedCover(DestLocation)

            -- 播放相机抖动
            if self.CameraShake then
                CharacterBase.Controller:ClientPlayCameraShake(self.CameraShake)
            end
        else
            CharacterLocation.Z = 0
            DestLocation.Z = 0

            local Direction = DestLocation - CharacterLocation
            Direction:Normalize()

            CharacterBase:AddMovementInput(Direction, 1)
        end
    end
end

-- 到达掩体
function BP_CharacterCoverComponent_C:ArrivedCover(DestLocation)
    if self:IsEnteringCover() or self:IsChangingCover() then
        if not DestLocation then
            return
        end

        local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
        if not CharacterBase then
            return
        end

        if self.LastCover then
            self.LastCover.CoverIndicatorWidget:SetVisibility(false)
        end

        local CharacterLocation = CharacterBase:K2_GetActorLocation()
        DestLocation.Z = CharacterLocation.Z + 20

        local CharacterRotation = CharacterBase:K2_GetActorRotation()
        local NeedRotator = UE4.UKismetMathLibrary.ComposeRotators(CharacterRotation, UE4.FRotator(0, 180, 0)) - UE4.FRotator(0, 90, 0)  -- 需要旋转的角度
        
        self:OnArrivedCoverEvent(DestLocation, NeedRotator)

        self:SetTakeCoverState(UE4.ETakeCoverState.ETakeCoverState_Covering)
        
        if CharacterBase.CharacterMovement then
            CharacterBase.CharacterMovement:StopMovementImmediately()
        end

        -- 请求服务器
        if CharacterBase:GetLocalRole() < UE4.ENetRole.ROLE_Authority then
            self:ServerArrivedCover(DestLocation)
        end
    end
end

-- 沿着掩体轨道行走
function BP_CharacterCoverComponent_C:MoveAlongSpline(SplineLocation, SplineRotation)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.CharacterMovement then
        return
    end

    local Velocity = CharacterBase.CharacterMovement:GetVelocity()
    if Velocity:Size() > 0 then
        -- 位置
        self:SetCharacterLocationAlongSpline(SplineLocation)
        -- 朝向
        self:SetCharacterRotationAlongSpline(SplineRotation)

        -- 请求服务器
        if CharacterBase:GetLocalRole() < UE4.ENetRole.ROLE_Authority then
            self:ServerMoveAlongSpline(SplineLocation, SplineRotation)
        end
    end
end

-- 进入到同一轨道上的新掩体
function BP_CharacterCoverComponent_C:FindCoverAlongSpline()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return
    end

    if CharacterBase:GetLocalRole() < UE4.ENetRole.ROLE_Authority then
        return
    end

    local Velocity = CharacterBase.CharacterMovement:GetVelocity()
    if Velocity:Size() <= 0 then
        return
    end

    local TraceStart, TraceEnd = self:GetTraceInfoAlongSpline()
    local HitResult = self:TraceCover(TraceStart, TraceEnd, 5)
    if not HitResult then
        return
    end

    local CoverActor = HitResult.Actor and HitResult.Actor:Cast(UE4.ABP_LevelCoverBase_C) or nil
    if not CoverActor or CoverActor == self.TakeCoverActor  then
        return
    end

    -- 必须处于同一个轨道
    if not self.TakeCoverActor or self.TakeCoverActor.CoverSpline ~= CoverActor.CoverSpline then
        return
    end

    self:ChangeCoverAlongSpline(CoverActor)

    -- 通知客户端
    if not UE4.UKismetSystemLibrary.IsStandalone(self) then
        self:ClientChangeCoverAlongSpline(CoverActor)
    end
end

-- 沿着掩体轨道行走时切换掩体
function BP_CharacterCoverComponent_C:ChangeCoverAlongSpline(CoverActor)
    self:SetTakeCoverActor(CoverActor)

    -- 高低切换
    if self:IsAllowChangeHeight() then
        self:SetCharacterCrouch()
    end
end

-- 离开掩体
function BP_CharacterCoverComponent_C:LeaveCover()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.CharacterMovementComponent then
        return
    end

    self:SetTakeCoverState(UE4.ETakeCoverState.ETakeCoverState_None)
    self:SetTakeCoverActor(nil)
    self:SetDistanceAlongSpline(0)

    self:SetCoverProbeState(UE4.ECoverProbeState.ECoverProbeState_None)

    CharacterBase:UnCrouch(true)

    CharacterBase.bUseControllerRotationYaw = true

    -- 掩体状态
    self:SetCharacterMovementCoverQTE(false)
    -- 掩体边缘状态
    self:SetCharacterMovementCoverEdge(false)

    -- 切换装备到右手
    CharacterBase.EquipComponent:ChangeCurrentEquipHand(true)
    -- 切换视角到右手
    CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(UE4.ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_HOLDEQUIP_LEFT, false)

    -- 请求服务器
    if CharacterBase:GetLocalRole() < UE4.ENetRole.ROLE_Authority then
        self:ServerLeaveCover()
        LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_LEAVECOVER)
    end
end

-- 翻越掩体
function BP_CharacterCoverComponent_C:VaultCover()
    if self:IsCovering() then
        if not self:CanVaultCover() then
            return
        end

        local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
        if not CharacterBase or not CharacterBase.CharacterMovement then
            return
        end

        self:SetTakeCoverState(UE4.ETakeCoverState.ETakeCoverState_Vaulting)

        CharacterBase.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Flying)
        CharacterBase:UnCrouch(true)

        -- local CharacterRotation = CharacterBase:K2_GetActorRotation()
        -- local CharacterDirection = CharacterRotation:ToVector()
        -- CharacterDirection:Normalize()

        local TraceStart, TraceEnd = self:GetTraceInfoAlongSpline()
        local HitResult = self:TraceCover(TraceStart, TraceEnd, 5)
        if not HitResult then
            return
        end

        local CoverActor = HitResult.Actor and HitResult.Actor:Cast(UE4.ABP_LevelCoverBase_C) or nil
        if not CoverActor or CoverActor ~= self.TakeCoverActor  then
            return
        end

        local CoverRotation = HitResult.ImpactNormal:ToRotator()
        CoverRotation = UE4.UKismetMathLibrary.ComposeRotators(CoverRotation, UE4.FRotator(0, 180, 0))
        CoverRotation:Normalize()
        CoverRotation:ToVector()

        self.VaultDirection = CoverRotation:ToVector()
        self.VaultDirection:Normalize()

        self:VaultCoverJump()

        -- 请求服务器
        if CharacterBase:GetLocalRole() < UE4.ENetRole.ROLE_Authority then
            self:ServerVaultCover()    
        end
    end
end

-- 翻越掩体 - 起跳
function BP_CharacterCoverComponent_C:VaultCoverJump()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.CharacterMovement then
        return
    end

    CharacterBase.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Flying)

    local CharacterLocation = CharacterBase:K2_GetActorLocation()

    local CoverHeight = self.TakeCoverActor and self.TakeCoverActor.CoverHeight or 100
    local TargetRelativeLocation = UE4.FVector(CharacterLocation.X, CharacterLocation.Y, CharacterLocation.Z + CoverHeight)
    local TargetRelativeRotation = CharacterBase:K2_GetActorRotation()
    local OverTime = CoverHeight / self.VaultJumpSpeed
    self:MoveComponentTo(CharacterBase:K2_GetRootComponent(), TargetRelativeLocation, TargetRelativeRotation, OverTime,
            UE4.EVaultCoverState.EVaultCoverState_Jump)
end

-- 翻越掩体 - 横移
function BP_CharacterCoverComponent_C:VaultCoverMove()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.CharacterMovement then
        return
    end

    local CoverWidth = self.TakeCoverActor and self.TakeCoverActor.CoverWidth or 100
    local TargetRelativeLocation = CharacterBase:K2_GetActorLocation() + self.VaultDirection * CoverWidth
    local TargetRelativeRotation = CharacterBase:K2_GetActorRotation()
    local OverTime = CoverWidth / self.VaultMoveSpeed
    self:MoveComponentTo(CharacterBase:K2_GetRootComponent(), TargetRelativeLocation, TargetRelativeRotation, OverTime,
            UE4.EVaultCoverState.EVaultCoverState_Move)
end

-- 翻越掩体 - 结束
function BP_CharacterCoverComponent_C:VaultCoverOver()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return
    end

    if CharacterBase.CharacterMovement then
        CharacterBase.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Falling)
    end

    if CharacterBase:GetLocalRole() == UE4.ENetRole.ROLE_AutonomousProxy or UE4.UKismetSystemLibrary.IsStandalone(self) then
        -- self:LeaveCover()
    end
end

-- 翻越掩体 - 移动组件完成通知
function BP_CharacterCoverComponent_C:MoveComponentToComplete(VaultStateComplete)
    if VaultStateComplete == UE4.EVaultCoverState.EVaultCoverState_Jump then
        self:VaultCoverMove()
    elseif VaultStateComplete == UE4.EVaultCoverState.EVaultCoverState_Move then
        self:VaultCoverOver()
    end
end

-- 切换掩体
function BP_CharacterCoverComponent_C:ChangeCover()
    if self:IsCovering() then
        if UE4.UKismetSystemLibrary.IsStandalone(self) then
            self:ServerChangeCoverInternal()
        else
            -- 请求服务器
            self:ServerChangeCover()
        end
    end
end

function BP_CharacterCoverComponent_C:ServerChangeCoverInternal()
    if self:IsCovering() then
        local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
        if not CharacterBase or not CharacterBase.CharacterMovementComponent then
            return
        end

        local ChangeCoverActor = nil
        local ChangeCoverSpline = nil
        local ChangeCoverAxisValue = 0
        -- 掩体左侧、左手持枪
        if CharacterBase.CharacterMovementComponent:IsCoverLeft() and CharacterBase:IsHoldEquipLeft() then
            ChangeCoverActor        = self.TakeCoverActor and self.TakeCoverActor.LeftChangeCoverActor or nil
            ChangeCoverSpline       = self.TakeCoverActor and self.TakeCoverActor.LeftChangeCoverSpline or nil
            ChangeCoverAxisValue    = self.TakeCoverActor and self.TakeCoverActor.LeftChangeCoverAxisValue or 0
        -- 掩体右侧、右手持枪
        elseif CharacterBase.CharacterMovementComponent:IsCoverRight() and not CharacterBase:IsHoldEquipLeft() then
            ChangeCoverActor        = self.TakeCoverActor and self.TakeCoverActor.RightChangeCoverActor or nil
            ChangeCoverSpline       = self.TakeCoverActor and self.TakeCoverActor.RightChangeCoverSpline or nil
            ChangeCoverAxisValue    = self.TakeCoverActor and self.TakeCoverActor.RightChangeCoverAxisValue or 0
        end

        if not ChangeCoverActor or not ChangeCoverActor.CoverSpline or not ChangeCoverSpline then
            return
        end

        local DestLocation = UE4.FVector()
        if ChangeCoverAxisValue > 0 then
            DestLocation = ChangeCoverSpline:GetLocationAtDistanceAlongSpline(ChangeCoverSpline:GetSplineLength())
        else
            DestLocation = ChangeCoverSpline:GetLocationAtDistanceAlongSpline(0)
        end
        local DistanceAlongSpline = ChangeCoverActor.CoverSpline:GetDistanceAlongSpline(DestLocation)

        local CharacterLocation = CharacterBase:K2_GetActorLocation()
        local ChangeCoverDistanceAlongSpline = ChangeCoverSpline:GetDistanceAlongSpline(CharacterLocation)

        self:ChangeCoverInternal(ChangeCoverActor, ChangeCoverSpline, ChangeCoverAxisValue, DistanceAlongSpline, ChangeCoverDistanceAlongSpline)

        -- 通知客户端
        if not UE4.UKismetSystemLibrary.IsStandalone(self) then
            self:ClientChangeCover(ChangeCoverActor, ChangeCoverSpline, ChangeCoverAxisValue, DistanceAlongSpline, ChangeCoverDistanceAlongSpline)
        end
    end
end

function BP_CharacterCoverComponent_C:ChangeCoverInternal(NewCoverActor, NewChangeCoverSpline, NewChangeCoverAxisValue, NewDistanceAlongSpline, NewChangeCoverDistanceAlongSpline)
    if not NewCoverActor or not NewCoverActor.CoverSpline then
        return
    end

    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return
    end

    self:SetTakeCoverState(UE4.ETakeCoverState.ETakeCoverState_Changing)
    self:SetTakeCoverActor(NewCoverActor)
    self:SetDistanceAlongSpline(NewDistanceAlongSpline)

    self:SetChangeCoverSpline(NewChangeCoverSpline)
    self:SetChangeCoverAxisValue(NewChangeCoverAxisValue)
    self:SetChangeCoverDistanceAlongSpline(NewChangeCoverDistanceAlongSpline)

    if self:IsAllowChangeAxis() then
        --- 切换装备的左右手
        local bRight = self:IsEnterCoverHandRight(NewCoverActor, NewDistanceAlongSpline)
        CharacterBase.EquipComponent:ChangeCurrentEquipHand(bRight)
        --- 切换视角的左右手
        CharacterBase.CharacterMovementComponent:ChangeMoveMentLayer2Type(UE4.ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_HOLDEQUIP_LEFT, not bRight)
    end

    -- 下蹲
    if NewCoverActor.CoverHeightType == UE4.ECoverHeightType.ECoverHeightType_Low then
        CharacterBase:Crouch(true)
    else
        CharacterBase:UnCrouch(true)
    end

    -- 固定角色朝向
    CharacterBase.bUseControllerRotationYaw = false
    -- 设置角色朝向
    self:SetCharacterRotationAlongSpline(self:GetRotationAtDistanceAlongSpline(NewDistanceAlongSpline))

    self:PerformCoveringTurn()
end

-- 切换掩体 - 移向掩体
function BP_CharacterCoverComponent_C:ChangeToCover()
    if self:IsChangingCover() then
        local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
        if not CharacterBase or not CharacterBase.Controller then
            return
        end

        local CharacterLocation = CharacterBase:K2_GetActorLocation()
        local DestLocation = self:GetLocationAtDistanceAlongSpline(self.DistanceAlongSpline)

        local DistSquared2D = CharacterLocation:DistSquared2D(DestLocation)
        if DistSquared2D <= self.DistanceToCover * self.DistanceToCover then
            -- 到达掩体时手动强制修改一下角色位置
            local SplineLocation = self:GetLocationAtDistanceAlongSpline(self.DistanceAlongSpline)
            local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)
            -- 前后端浮点数有精度问题，导致行走不顺畅，所以由客户端驱动行走
            self:MoveAlongSpline(SplineLocation, SplineRotation)

            -- 到达掩体
            self:ArrivedCover(DestLocation)

            self:SetChangeCoverSpline(nil)
            self:SetChangeCoverAxisValue(0)

            -- 播放相机抖动
            if self.CameraShake then
                CharacterBase.Controller:ClientPlayCameraShake(self.CameraShake)
            end
        else
            CharacterLocation.Z = 0
            DestLocation.Z = 0

            local Direction = DestLocation - CharacterLocation
            Direction:Normalize()

            CharacterBase:AddMovementInput(Direction, 1)
        end
    end
end

-- 切换掩体 - 沿着轨道移动
function BP_CharacterCoverComponent_C:ChangeToCoverAlongSpline()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return
    end

    if not self.ChangeCoverSpline then
        return
    end

    local CurLocation = self.ChangeCoverSpline:GetLocationAtDistanceAlongSpline(self.ChangeCoverDistanceAlongSpline)

    local NewDistanceAlongSpline = self:CalculateDistanceAlongSpline(CharacterBase, self.ChangeCoverAxisValue, self.ChangeCoverSpline, self.ChangeCoverDistanceAlongSpline)
    local DestLocation = self.ChangeCoverSpline:GetLocationAtDistanceAlongSpline(NewDistanceAlongSpline)

    local Direction = DestLocation - CurLocation
    if self.ChangeCoverAxisValue < 0 then
        Direction = CurLocation - DestLocation
    end
    Direction:Normalize()
    if Direction:Size() <= 0 then
        -- -- 到达掩体
        -- self:ArrivedCover(DestLocation)

        -- self:SetChangeCoverSpline(nil)
        -- self:SetChangeCoverAxisValue(0)

        -- -- 播放相机抖动
        -- if self.CameraShake then
        --     CharacterBase.Controller:ClientPlayCameraShake(self.CameraShake)
        -- end
    else
        local SplineLocation = self.ChangeCoverSpline:GetLocationAtDistanceAlongSpline(self.ChangeCoverDistanceAlongSpline)
        local SplineRotation = self.ChangeCoverSpline:GetRotationAtDistanceAlongSpline(self.ChangeCoverDistanceAlongSpline)
        self:MoveAlongSpline(SplineLocation, SplineRotation)

        self:SetChangeCoverDistanceAlongSpline(NewDistanceAlongSpline)
    end
end

-------------------------------------------------------------------------
--- 进入掩体过程中移动
function BP_CharacterCoverComponent_C:PerformEnteringMove(InDirection, InAxisValue)

    -- 进入掩体过程中
    if self.TakeCoverState == UE4.ETakeCoverState.ETakeCoverState_Entering then
        local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
        if not CharacterBase then
            return InDirection, 0
        end

        --- 轨道朝向
        local SplineRotation = self:GetRotationAtDistanceAlongSpline(self.DistanceAlongSpline)
        SplineRotation:Set(0, SplineRotation.Yaw, 0)
        SplineRotation = UE4.UKismetMathLibrary.ComposeRotators(SplineRotation, UE4.FRotator(0, -90, 0))
        SplineRotation:Normalize()

        --- 移动方向
        local MoveDirection = InDirection * InAxisValue
        MoveDirection:Normalize()

        local MoveAngle = UE4.UKismetMathLibrary.DegAcos(MoveDirection:CosineAngle2D(SplineRotation:ToVector()))
        if MoveAngle > self.MaxCoverMoveAngle then
            self:LeaveCover()
        end
    end

    return InDirection, 0
end

--- 在掩体中移动
function BP_CharacterCoverComponent_C:PerformCoveringMove(InDirection, InAxisValue)
    if self.TakeCoverState == UE4.ETakeCoverState.ETakeCoverState_Covering then
        local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
        if not CharacterBase then
            return InDirection, 0
        end

        local CoverSpline = self.TakeCoverActor and self.TakeCoverActor.CoverSpline or nil
        if not CoverSpline then
            return InDirection, 0
        end

        local MoveAngle = self:GetLocalMoveFaceToCoverAngle(InDirection, InAxisValue)
        if MoveAngle <= self.MinCoverMoveAngle then

            -- 在边缘的时候进入冲锋
            if self:CanRunLeaveCover() then
                if self.CoverProbeState ~= UE4.ECoverProbeState.ECoverProbeState_Run then
                    self:SetCoverProbeState(UE4.ECoverProbeState.ECoverProbeState_Run)
                end
            elseif self:CanVaultCover() then
                if self.CoverProbeState ~= UE4.ECoverProbeState.ECoverProbeState_Vault then
                    self:SetCoverProbeState(UE4.ECoverProbeState.ECoverProbeState_Vault)
                end
            end

            return InDirection, 0
        elseif MoveAngle <= self.MaxCoverMoveAngle and self:CanMove() then

            --- 掩体中移动
            local MoveCrossZ = self:GetLocalMoveFaceToCoverCrossZ(InDirection, InAxisValue)
            local MoveAxisValue = (MoveCrossZ * InAxisValue < 0) and InAxisValue or InAxisValue * -1

            --- 切换轴向
            if self:SetCurrentEquipHand_Move(MoveAxisValue) then
                return InDirection, 0
            end
            
            local CurLocation = self:GetLocationAtDistanceAlongSpline(self.DistanceAlongSpline)

            local NewDistanceAlongSpline = self:CalculateDistanceAlongSpline(CharacterBase, MoveAxisValue, CoverSpline, self.DistanceAlongSpline)
            local DestLocation = self:GetLocationAtDistanceAlongSpline(NewDistanceAlongSpline)
            
            local Direction = DestLocation - CurLocation
            if MoveAxisValue < 0 then
                Direction = CurLocation - DestLocation
            end
            Direction:Normalize()
            if Direction:Size() <= 0 then
                -- 掩体边缘状态
                self:SetCharacterMovementCoverEdge(true)
                -- 切换掩体
                if self:CanChangeCover() then
                    if self.CoverProbeState ~= UE4.ECoverProbeState.ECoverProbeState_Change then
                        self:SetCoverProbeState(UE4.ECoverProbeState.ECoverProbeState_Change)
                    end
                else
                    if self.CoverProbeState ~= UE4.ECoverProbeState.ECoverProbeState_Roll then
                        self:SetCoverProbeState(UE4.ECoverProbeState.ECoverProbeState_Roll)
                    end
                end

                return InDirection, 0
            end

            if self.CoverProbeState ~= UE4.ECoverProbeState.ECoverProbeState_None then
                self:SetCoverProbeState(UE4.ECoverProbeState.ECoverProbeState_None)
            end

            self:SetDistanceAlongSpline(NewDistanceAlongSpline)
            -- 相机朝向
            self:SetControlRotationAlongSpline(self:GetRotationAtDistanceAlongSpline(NewDistanceAlongSpline))
            -- 掩体边缘状态
            self:SetCharacterMovementCoverEdge(true)

            return Direction, MoveAxisValue

        elseif math.abs(InAxisValue) > 0.7 then
            self:LeaveCover()
        end

        return InDirection, 0
    end

    return InDirection, InAxisValue
end

--- 在掩体中转向
function BP_CharacterCoverComponent_C:PerformCoveringTurn()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller or not CharacterBase.CharacterMovementComponent then
        return
    end

    --- 设置与掩体的Angle、CrossZ，同步给其他玩家
    local FaceToCoverAngle = self:GetLocalPlayerFaceToCoverAngle()
    local FaceToCoverCrossZ = self:GetLocalPlayerFaceToCoverCrossZ()
    self:SetPlayerFaceToCoverAngleAndCrossZ(FaceToCoverAngle, FaceToCoverCrossZ)

    self:SetCharacterCrouch()

    self:SetCurrentEquipHand_Turn()

    self:UpdateCharacterCameraMode_Turn()
end

--- 掩体指示
function BP_CharacterCoverComponent_C:CoverIndicator()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)

    if not CharacterBase then
        return
    end

    local TraceStart, TraceEnd = self:GetTraceInfo(false, CharacterBase.InputAxisForward, CharacterBase.InputAxisRight)
    local HitResult = self:TraceCover(TraceStart, TraceEnd, 40) 

    if HitResult then
        local CoverActor = HitResult.Actor and HitResult.Actor:Cast(UE4.ABP_LevelCoverBase_C) or nil
        if CoverActor then
            CoverActor.CoverIndicatorWidget:SetVisibility(true)
            self:SetWidgetRotationAndLocation(CoverActor,HitResult)

            if self.LastCover ~= CoverActor and self.LastCover then
                self.LastCover.CoverIndicatorWidget:SetVisibility(false)
            end
            self.LastCover = CoverActor

        elseif self.LastCover then
                self.LastCover.CoverIndicatorWidget:SetVisibility(false)            
        end
    elseif self.LastCover then
            self.LastCover.CoverIndicatorWidget:SetVisibility(false)
    end
end    

--- 掩体指示的旋转和位置
function BP_CharacterCoverComponent_C:SetWidgetRotationAndLocation(CoverActor,HitResult)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return
    end
    local CharacterLocation = CharacterBase:K2_GetActorLocation()
    local CharacterRotation = CharacterBase:K2_GetActorRotation()
    local Direction = CharacterRotation:ToVector();

    local Spline = CoverActor.CoverSpline and CoverActor.CoverSpline.Spline or nil
               
    if not Spline then
        print("---------------- SetWidgetRotationAndLocation CoverSpline ", Spline)
        return 
    end
    
    local value = CoverActor.CoverSpline:GetDistanceAlongSpline(HitResult.ImpactPoint)
    local pos = CoverActor.CoverSpline:GetLocationAtDistanceAlongSpline(value, UE4.ESplineCoordinateSpace.World)

    local meshName = UE4.UKismetSystemLibrary.GetDisplayName(CoverActor.Mesh.StaticMesh)
    local Arrow = UE4.FVector(0,0,0)
    if meshName == "Cylinder" then
        local LookAtRotation = UE4.UKismetMathLibrary.FindLookAtRotation( UE4.FVector(CoverActor.Mesh:K2_GetComponentLocation().X,CoverActor.Mesh:K2_GetComponentLocation().Y,0), UE4.FVector(HitResult.ImpactPoint.X,HitResult.ImpactPoint.Y,0))
        CoverActor.CoverIndicatorWidget:K2_SetWorldRotation(LookAtRotation,false, nil, false)
    else
        local a = Direction:Dot(CoverActor.Arrow:GetForwardVector())
        local degree = math.deg(math.acos(a)) 

        local Rotator = UE4.FRotator(0,0,0)
        if degree < 90 then
            Rotator = UE4.FRotator(0,180,0) 
            Arrow = CoverActor.Arrow:GetForwardVector()
        else
            Arrow = - CoverActor.Arrow:GetForwardVector()
        end
        CoverActor.CoverIndicatorWidget:K2_SetRelativeRotation(Rotator,false, nil, false)
    end

    if value > 0 and value < CoverActor.CoverSpline:GetSplineLength() then
        CoverActor.CoverIndicatorWidget:K2_SetWorldLocation(UE4.FVector(HitResult.ImpactPoint.X, HitResult.ImpactPoint.Y, pos.Z + CoverActor.CoverIndicatorHight), false, nil, false)
    elseif value == 0 then
        local firstAplinePos = Spline:GetWorldLocationAtSplinePoint(0)
        local EndLocation = firstAplinePos + Arrow * 100
        local Result = self:CalculatePointSplineToCover(firstAplinePos,EndLocation)  
        
        if Result then
            CoverActor.CoverIndicatorWidget:K2_SetWorldLocation(UE4.FVector(Result.ImpactPoint.X,Result.ImpactPoint.Y, pos.Z + CoverActor.CoverIndicatorHight) ,false,nil,false)
        end
    elseif  value == CoverActor.CoverSpline:GetSplineLength() then           
        local pointNum = Spline:GetNumberOfSplinePoints() 
        local lastAplinePos = Spline:GetWorldLocationAtSplinePoint(pointNum)
        local EndLocation = lastAplinePos + Arrow * 100
        local Result = self:CalculatePointSplineToCover(lastAplinePos,EndLocation)
        
        if Result then
            CoverActor.CoverIndicatorWidget:K2_SetWorldLocation(UE4.FVector(Result.ImpactPoint.X,Result.ImpactPoint.Y, pos.Z + CoverActor.CoverIndicatorHight),false,nil,false)
        end
    end
end

--- 计算掩体和过轨道端点的垂线的交点
function BP_CharacterCoverComponent_C:CalculatePointSplineToCover(StartLoc,EndLoc)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return
    end

    local ActorsToIgnore = UE4.TArray(UE4.AActor)
    ActorsToIgnore:Add(CharacterBase)
    local Result = UE4.FHitResult()

    UE4.UKismetSystemLibrary.LineTraceSingle(self,StartLoc,EndLoc, UE4.ETraceTypeQuery.Cover, false, ActorsToIgnore,UE4.EDrawDebugTrace.ForOneFrame,
    Result, true,UE4.FLinearColor(0,1,0))
    if Result then
        local Cover = Result.Actor and Result.Actor:Cast(UE4.ABP_LevelCoverBase_C) or nil
        if Cover then
            return Result
        end
    end
end

--- 探头指示
function BP_CharacterCoverComponent_C:ChangAndVaultCoverIndicator()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase then
        return
    end

    if self:IsCovering() then
        if not self.TakeCoverActor  then
            return
        end

        local ChangeWidget = CharacterBase.ProbeIndicatorWidget:GetUserWidgetObject()
        -- 切换掩体  
        if self:IsReadyChangeCover() then
            ChangeWidget.StateText:SetText("ChangeCover")
            CharacterBase.ProbeIndicatorWidget:SetVisibility(true)
            if self:IsCoverLeft() then
                ChangeWidget.Image_62:SetRenderAngle(180)
                CharacterBase.ProbeIndicatorWidget:K2_SetRelativeLocation(UE4.FVector(0,-70,0),false,nil,false) 
            elseif self:IsCoverRight() then
                ChangeWidget.Image_62:SetRenderAngle(0)
                CharacterBase.ProbeIndicatorWidget:K2_SetRelativeLocation(UE4.FVector(0,70,0),false,nil,false)              
            end
        -- 翻越掩体
        elseif self:IsReadyVaultCover() then
            CharacterBase.ProbeIndicatorWidget:SetVisibility(true)
            ChangeWidget.StateText:SetText("VaultCover")
            if CharacterBase:IsHoldEquipLeft() then
                ChangeWidget.Image_62:SetRenderAngle(-135) 
                CharacterBase.ProbeIndicatorWidget:K2_SetRelativeLocation(UE4.FVector(0,-50,70),false,nil,false)
            else
                ChangeWidget.Image_62:SetRenderAngle(-45)
                CharacterBase.ProbeIndicatorWidget:K2_SetRelativeLocation(UE4.FVector(0,50,70),false,nil,false)
            end
        elseif self:IsReadyForRun()then
            ChangeWidget.StateText:SetText("Run")
            CharacterBase.ProbeIndicatorWidget:SetVisibility(true)
            if self:IsCoverLeft() then
                ChangeWidget.Image_62:SetRenderAngle(180)
                CharacterBase.ProbeIndicatorWidget:K2_SetRelativeLocation(UE4.FVector(0,-70,0),false,nil,false) 
            elseif self:IsCoverRight() then
                ChangeWidget.Image_62:SetRenderAngle(0)
                CharacterBase.ProbeIndicatorWidget:K2_SetRelativeLocation(UE4.FVector(0,70,0),false,nil,false)  
            end
        elseif self:IsReadyForRoll() then           
            ChangeWidget.StateText:SetText("Roll")
            CharacterBase.ProbeIndicatorWidget:SetVisibility(true)
            if self:IsCoverLeft() then
                ChangeWidget.Image_62:SetRenderAngle(180)
                CharacterBase.ProbeIndicatorWidget:K2_SetRelativeLocation(UE4.FVector(0,-70,0),false,nil,false) 
            elseif self:IsCoverRight() then
                ChangeWidget.Image_62:SetRenderAngle(0)
                CharacterBase.ProbeIndicatorWidget:K2_SetRelativeLocation(UE4.FVector(0,70,0),false,nil,false) 
            end
        else    
            CharacterBase.ProbeIndicatorWidget:SetVisibility(false)
            
        end
    else
        CharacterBase.ProbeIndicatorWidget:SetVisibility(false)
        
    end
 
end

return BP_CharacterCoverComponent_C
