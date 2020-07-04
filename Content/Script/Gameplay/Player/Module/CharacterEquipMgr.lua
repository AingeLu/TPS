require "UnLua"

--拾取半径
local PICKUP_RADIUS = 200;

local CharacterModule = require "Gameplay/Player/Module/CharacterModule"

--　装备栏信息
local FCharacterEquipBarInfo = class(CharacterEquipBarInfo)

function FCharacterEquipBarInfo:ctor()
	self.iItemID        = 0	    --道具ID
	self.resItemDesc    = nil
end

function FCharacterEquipBarInfo:OnDestroy()
	self.iItemID        = 0	    --道具ID
	self.resItemDesc     = nil
end

-------------------------------------------------------------------------
-- 装备管理基类
-------------------------------------------------------------------------
local EquipMgrBase = class("EquipMgrBase", CharacterModule)

function EquipMgrBase:ctor()
    EquipMgrBase.super.ctor(self)
    
    self.EquipBarInfos      = {}    -- 装备信息列表
    self.PreEquipBarType    = Ds_EquipBarType.EQUIPBARTYPE_NONE
    self.CurEquipBarType    = Ds_EquipBarType.EQUIPBARTYPE_NONE
end

-- 创建
function EquipMgrBase:OnCreate(AC_Controller)
    EquipMgrBase.super.OnCreate(self, AC_Controller)

    -- 初始化装备信息列表
    for iEquipBarType = Ds_EquipBarType.EQUIPBARTYPE_NONE + 1, Ds_EquipBarType.EQUIPBARTYPE_MAX do
        self.EquipBarInfos[iEquipBarType] = FCharacterEquipBarInfo.new()
    end
end

-- 销毁
function EquipMgrBase:OnDestroy()
    for _, EquipBarInfo in self.EquipBarInfos or {} do
        if "table" == type(EquipBarInfo) and "function" == type(EquipBarInfo.OnDestroy) then 
            EquipBarInfo:OnDestroy()
        end
    end
    self.EquipBarInfos = nil

    EquipMgrBase.super.OnDestroy(self)
end

function EquipMgrBase:Tick(DeltaSeconds)

end

-- 添加装备
-- @Params: (Ds_EquipBarType, ItemDesc_Res, int32)
function EquipMgrBase:AddEquip(iEquipBarType, iResID, BulletNum, EquipState)
    if iResID <= 0 or iEquipBarType <= Ds_EquipBarType.EQUIPBARTYPE_NONE or iEquipBarType > Ds_EquipBarType.EQUIPBARTYPE_MAX then
        return
    end

    local CharacterBase = self:GetOwnerPawn()
    if not CharacterBase or not CharacterBase.EquipComponent then
        return
    end

    local ResItemDesc = GameResMgr:GetGameResDataByResID("ItemDesc_Res", iResID)
    if not ResItemDesc then
        print("-----Error: EquipMgrBase::AddEquip ItemDesc_Res is null, resID = ", iResID)
        return
    end

    local ResWeaponDesc = GameResMgr:GetGameResDataByResID("WeaponDesc_Res", ResItemDesc.ResID)
    if not ResWeaponDesc then
        print("-----Error: EquipMgrBase::AddEquip WeaponDesc_Res is null, resID = ", ResItemDesc.ResID)
        return
    end

    local EquipClass = ResourceMgr:LoadClassByBlueprintsPath(ResWeaponDesc.ModePath)
    if not EquipClass then
        print("-----Error: EquipMgrBase::AddEquip EquipClass is null, resID = ", ResItemDesc.ResID)
        return
    end

    local EquipActor = self:SpawnEquipActor(EquipClass)
    if not EquipActor then
        print("-----Error: EquipMgrBase::AddEquip EquipActor is null, resID = ", ResItemDesc.ResID)
        return
    end

    local PreItemID =  self.EquipBarInfos[iEquipBarType].iItemID;

    self.EquipBarInfos[iEquipBarType].iItemID = ResItemDesc.ResID
    self.EquipBarInfos[iEquipBarType].resItemDesc = ResItemDesc

    --武器一样 增加子子弹
    if PreItemID == ResItemDesc.ResID then

    end

    -- 角色属性
    for i = 1, Ds_RES_EQUIPEFFECT_CNT do
        local EffectType = ResWeaponDesc.EquipEffect[i].Type
        
        local param1 = ResWeaponDesc.EquipEffect[i].Param[0]
        local param2 = ResWeaponDesc.EquipEffect[i].Param[1]
        local param3 = ResWeaponDesc.EquipEffect[i].Param[2]

        if EffectType == Ds_BattleEquipEffectType.BATTLEEQUIPEFFECTTYPE_ATTR then
            local AttrMgr = self:GetAttrMgr()
            if AttrMgr then
                AttrMgr:AttrOpeAdd(param1, param2, param3)
            end
        end
    end

    -- 添加装备
    CharacterBase.EquipComponent:AddEquip(iEquipBarType, EquipActor, EquipState)
    CharacterBase.EquipComponent:OnEquipDataChange_S(iEquipBarType)
end

-- 移除装备
-- @Params: (Ds_EquipBarType)
function EquipMgrBase:RemoveEquip(iEquipBarType)
    if iEquipBarType <= Ds_EquipBarType.EQUIPBARTYPE_NONE or iEquipBarType > Ds_EquipBarType.EQUIPBARTYPE_MAX then
        return
    end

    local CharacterBase = self:GetOwnerPawn()
    if not CharacterBase then
        return
    end

    local ResItemDesc = self.EquipBarInfos[iEquipBarType].resItemDesc
    if not ResItemDesc then
        print("-----Error: EquipMgrBase::RemoveEquip ItemDesc_Res is null, iEquipBarType = ", iEquipBarType)
        return
    end

    local ResWeaponDesc = GameResMgr:GetGameResDataByResID("WeaponDesc_Res", ResItemDesc.ResID)
    if not ResWeaponDesc then
        print("-----Error: EquipMgrBase::RemoveEquip WeaponDesc_Res is null, resID = ", ResItemDesc.ResID)
        return
    end

    -- 同步角色属性
    for i =1, RES_EQUIPEFFECT_CNT do
        local EffectType = ResWeaponDesc.EquipEffect[i].Type
        
        local param1 = ResWeaponDesc.EquipEffect[i].Param[0]
        local param2 = ResWeaponDesc.EquipEffect[i].Param[1]
        local param3 = ResWeaponDesc.EquipEffect[i].Param[2]

        if EffectType == Ds_BattleEquipEffectType.BATTLEEQUIPEFFECTTYPE_ATTR then
            local AttrMgr = self:GetAttrMgr()
            if AttrMgr then
                AttrMgr:AttrOpeMove(param1, param2, param3)
            end
        end
    end

    self.EquipBarInfos[iEquipBarType]:OnDestroy()

    -- 移除装备
    if CharacterBase.EquipComponent then
        CharacterBase.EquipComponent:RemoveEquip(iEquipBarType)
        CharacterBase.EquipComponent:OnEquipDataChange_S(iEquipBarType)
    end
end


-- 获取装备
-- @Params: (Ds_EquipBarType)
-- @Return: FCharacterEquipBarInfo
function EquipMgrBase:GetEquip(iEquipBarType)
    if iEquipBarType <= Ds_EquipBarType.EQUIPBARTYPE_NONE or iEquipBarType > Ds_EquipBarType.EQUIPBARTYPE_MAX then
        return nil
    end

    return self.EquipBarInfos[iEquipBarType]
end

-- 切换到当前装备栏(已装备)
-- @Params: (Ds_EquipBarType)
function EquipMgrBase:SetCurrentEquip(iEquipBarType)
    if iEquipBarType <= Ds_EquipBarType.EQUIPBARTYPE_NONE or iEquipBarType > Ds_EquipBarType.EQUIPBARTYPE_MAX then
        return
    end

    local CharacterBase = self:GetOwnerPawn()
    if not CharacterBase then
        return
    end

    self.PreEquipBarType = self.CurEquipBarType;
    self.CurEquipBarType = iEquipBarType

    if CharacterBase.EquipComponent then
        CharacterBase.EquipComponent:SetCurrentEquip(iEquipBarType)
    end
end

-- 判断装备栏是否已装备
-- @Params: (Ds_EquipBarType)
-- @Return: boolean
function EquipMgrBase:IsEquipedBar(iEquipBarType)
    if iEquipBarType <= Ds_EquipBarType.EQUIPBARTYPE_NONE or iEquipBarType > Ds_EquipBarType.EQUIPBARTYPE_MAX then
        return false
    end

	return self.EquipBarInfos[iEquipBarType].iItemID > 0 and self.EquipBarInfos[iEquipBarType].resItemDesc
end

-- 设置当前装备栏类型
-- @Return: Ds_EquipBarType
function EquipMgrBase:GetCurEquipBarType()
    return self.CurEquipBarType
end

function EquipMgrBase:GetPreEquipBarType()
    return self.PreEquipBarType
end

-- 获取角色属性管理器
-- @Return: CharacterAttrMgr
function EquipMgrBase:GetAttrMgr()
    local PlayerController = self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    if PlayerController then
        return PlayerController:GetAttrMgr()
    end

    return nil
end

-------------------------------------------------------------------------
-- 装备管理类
-------------------------------------------------------------------------
local CharacterEquipMgr = class("CharacterEquipMgr", EquipMgrBase)

function CharacterEquipMgr:ctor()
    CharacterEquipMgr.super.ctor(self)

end

function CharacterEquipMgr:OnInit()
    local CharacterBase = self:GetOwnerPawn()
    if not CharacterBase then
        return
    end

    if not CharacterBase.EquipConfigData then
        return
    end

    local ChooseEquipBarType = Ds_EquipBarType.EQUIPBARTYPE_NONE

    local EquipConfigData = CharacterBase.EquipConfigData
    local EquipState = UE4.EEquipState.EquipState_EquipDowned

    --默认
    if EquipConfigData.Weapon1 > 0 then
        EquipState =  UE4.EEquipState.EquipState_EquipUped
        ChooseEquipBarType  = Ds_EquipBarType.EQUIPBARTYPE_WEAPON1
    end
    self:AddEquip(Ds_EquipBarType.EQUIPBARTYPE_WEAPON1, EquipConfigData.Weapon1, 0, EquipState)

    EquipState = UE4.EEquipState.EquipState_EquipDowned

    self:AddEquip(Ds_EquipBarType.EQUIPBARTYPE_WEAPON2, EquipConfigData.Weapon2, 0, EquipState)
    self:AddEquip(Ds_EquipBarType.EQUIPBARTYPE_FIST, EquipConfigData.Fist, 0, EquipState)
    self:AddEquip(Ds_EquipBarType.EQUIPBARTYPE_THROW, EquipConfigData.Throw, 0, EquipState)
    self:AddEquip(Ds_EquipBarType.EQUIPBARTYPE_PROP, EquipConfigData.Prop, 0, EquipState)
    self:AddEquip(Ds_EquipBarType.EQUIPBARTYPE_ARMOR, EquipConfigData.Armor, 0, EquipState)
    self:AddEquip(Ds_EquipBarType.EQUIPBARTYPE_HELMET, EquipConfigData.Helmet, 0, EquipState)
    self:AddEquip(Ds_EquipBarType.EQUIPBARTYPE_DOWNSHIELD, EquipConfigData.DownShield, 0, EquipState)
    self:AddEquip(Ds_EquipBarType.EQUIPBARTYPE_BAG, EquipConfigData.Bag, 0, EquipState)

    self:SetCurrentEquip(ChooseEquipBarType)
end

-- 请求装备
-- @Params: (ItemDesc_Res, int32)
function CharacterEquipMgr:RequsetEquip(resItemDesc, BulletNum)
    if not resItemDesc then
        return;
    end

    local EquipState = UE4.EEquipState.EquipState_EquipDowned
    local bEquipChange = false;

    -- 武器装备逻辑: 1.替换当前的栏位.2.空的栏位
	local ChooseEquipBarType = resItemDesc.EquipBarType
    if ChooseEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON1 or
        ChooseEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 then
        
        EquipState = UE4.EEquipState.EquipState_EquipUped
        bEquipChange = true;
            
       if self.CurEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON1 or 
        self.CurEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 then
            ChooseEquipBarType = self.CurEquipBarType      
        elseif self.EquipBarInfos[Ds_EquipBarType.EQUIPBARTYPE_WEAPON1].iItemID <= 0 then
            ChooseEquipBarType = Ds_EquipBarType.EQUIPBARTYPE_WEAPON1
        elseif self.EquipBarInfos[Ds_EquipBarType.EQUIPBARTYPE_WEAPON2].iItemID <= 0 then
            ChooseEquipBarType = Ds_EquipBarType.EQUIPBARTYPE_WEAPON2
        end
    end

	-- 将旧装备扔到地上
	self:ThrowToFloor(ChooseEquipBarType)

    self:AddEquip(ChooseEquipBarType, resItemDesc.ResID, BulletNum, EquipState)

    --切换装备数据
    if bEquipChange then
        self:SetCurrentEquip(ChooseEquipBarType)
    end
    
    return true;
end

-- 请求切换装备栏
function CharacterEquipMgr:RequsetChangeCurEquipBarType(newEquipBarType)
   
    if newEquipBarType ~= Ds_EquipBarType.EQUIPBARTYPE_WEAPON1 and newEquipBarType ~= Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 and
        newEquipBarType ~= Ds_EquipBarType.EQUIPBARTYPE_FIST and newEquipBarType ~= Ds_EquipBarType.EQUIPBARTYPE_THROW and
        newEquipBarType ~= Ds_EquipBarType.EQUIPBARTYPE_NONE then
             return;
    end

    local newEquipData =  self:GetEquip(newEquipBarType)
    if newEquipData == nil then
        return
    end

    local CharacterBase = self:GetOwnerPawn()
    if not CharacterBase then
        return
    end

    --if newEquipBarType == self.CurEquipBarType or newEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_NONE then
    --    newEquipBarType = Ds_EquipBarType.EQUIPBARTYPE_NONE;
    --end

    if CharacterBase.EquipComponent then
        CharacterBase.EquipComponent:ChangeCurrentNewEquip(newEquipBarType)
    end

    self.PreEquipBarType = self.CurEquipBarType;
    self.CurEquipBarType = newEquipBarType

    return true;
end

-- 请求装备配件
-- @Params: (ItemDesc_Res, bool )
function CharacterEquipMgr:RequsetEquipParts(resItemDesc, bool)
	local CharacterBase = self:GetOwnerPawn()
	if not CharacterBase then
        return false
    end

    local PriorityEquipBarType = { Ds_EquipBarType.EQUIPBARTYPE_WEAPON1, Ds_EquipBarType.EQUIPBARTYPE_WEAPON2}
    if self.CurEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 then
        PriorityEquipBarType = { Ds_EquipBarType.EQUIPBARTYPE_WEAPON2, Ds_EquipBarType.EQUIPBARTYPE_WEAPON1}
    end

	-- if self.CurEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON1 or
    --     self.CurEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 then
	-- 	PriorityEquipBarType[0] = self.CurEquipBarType
    -- end
    -- PriorityEquipBarType[1] = (PriorityEquipBarType[0] == Ds_EquipBarType.EQUIPBARTYPE_WEAPON1) and
    --     Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 or Ds_EquipBarType.EQUIPBARTYPE_WEAPON1

	for i = 1, 2 do
        if self.EquipBarInfos[PriorityEquipBarType[i]].iItemID > 0 then
            if CharacterBase.EquipComponent then
                local WeaponBase = CharacterBase.EquipComponent:GetWeaponByBarType(PriorityEquipBarType[i])
                if WeaponBase and WeaponBase:EquipParts(resItemDesc, bAuto) then
                    return true
                end
            end
        end
    end

	return false
end

-- 扔到地上
-- @Params: (Ds_EquipBarType)
function CharacterEquipMgr:ThrowToFloor(iEquipBarType)
	-- 非武器无法丢弃
	if iEquipBarType ~= Ds_EquipBarType.EQUIPBARTYPE_WEAPON1 and iEquipBarType ~= Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 then
        return
    end

	if self.EquipBarInfos[iEquipBarType].iItemID <= 0 or not self.EquipBarInfos[iEquipBarType].resItemDesc then
        return
    end

    self:SpawnDropItemActor(iEquipBarType);

	self:RemoveEquip(iEquipBarType)
end

-- 孵化武器
-- @Params: (Ds_EquipBarType)
-- @Return: BP_EquipBase_C
function CharacterEquipMgr:SpawnEquipActor(EquipClass)
    if not self.Controller then
        print("-----Error: CharacterEquipMgr::SpawnEquipActor self.Controller is null.")
        return nil
    end

    local CharacterBase = self:GetOwnerPawn()
    if not CharacterBase then
        print("-----Error: CharacterEquipMgr::SpawnEquipActor CharacterBase is null.")
        return nil
    end

    local World = self.Controller:GetWorld()
    if not World then
        print("-----Error: CharacterEquipMgr::SpawnEquipActor World is null.")
        return nil
    end

    if EquipClass == nil then
        print("-----Error: CharacterEquipMgr::SpawnEquipActor EquipClass is null ModePath = ", ResWeaponDesc.ModePath)
		return nil
    end

    local Transform = FTransform()
    local Actor = World:SpawnActor(EquipClass, Transform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, CharacterBase, CharacterBase)
    if not Actor then
        print("-----Error: CharacterEquipMgr::SpawnEquipActor Actor is null ModePath = ", ResWeaponDesc.ModePath)
        return nil
    end

    return Actor:Cast(UE4.ABP_EquipBase_C)
end

function CharacterEquipMgr:SpawnDropItemActor(iEquipBarType)

    local CharacterBase = self:GetOwnerPawn()
	if not CharacterBase then
        return
    end

    local ResItemDesc = self.EquipBarInfos[iEquipBarType].resItemDesc

    local ItemClass =  ResourceMgr:LoadClassByBlueprintsPath(ResItemDesc.ModePath)
    if not ItemClass then
		print("Error: CharacterEquipMgr::ThrowToFloor ItemClass is null ModePath = ", ResItemDesc.ModePath)
		return nil
    end

    local height = CharacterBase.CapsuleComponent:GetScaledCapsuleHalfHeight() * 2.0

    local RandomQuat = UE4.FQuat.MakeFromEuler(FVector(0, 0, math.random(0.0, 360.0)));
    local StartTrace = CharacterBase:K2_GetActorLocation() + RandomQuat:Vector() * 
        math.random(PICKUP_RADIUS / 5, PICKUP_RADIUS / 2) + FVector(0, 0, height);
	
	local PawnCenter = StartTrace;
	local EndTrace = StartTrace - FVector(0, 0, 1000 * 100.0);
    local OutHit = UE4.FHitResult()
    --local TraceTypeQuery = UE4.ETraceTypeQuery("WorldStatic");

    local bResult = UE4.UKismetSystemLibrary.LineTraceSingle(CharacterBase, StartTrace, EndTrace, UE4.ETraceTypeQuery.WorldStatic,
     false, nil, UE4.EDrawDebugTrace.None, OutHit, true)
	if bResult == true then
		PawnCenter = OutHit.Location + FVector(0, 0, 32);
    end
   
    local PawnQuat = FQuat.MakeFromEuler(FVector(0, 0, math.random(0.0, 360.0)));
    local SpawnTransform = FTransform(PawnQuat, PawnCenter)

    local Actor = UE4.UGameplayStatics.BeginDeferredActorSpawnFromClass(CharacterBase, ItemClass, SpawnTransform,
     UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    if  Actor then
        Actor:OnInit(ResItemDesc.ResID, 1, 0, 0)
        UE4.UGameplayStatics.FinishSpawningActor(Actor, SpawnTransform)
    end
end


return CharacterEquipMgr