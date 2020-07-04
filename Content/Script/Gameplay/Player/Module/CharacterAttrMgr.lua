
require "UnLua"

local CharacterModule = require "Gameplay/Player/Module/CharacterModule"

-------------------------------------------------------------------------
-- 属性结构体
-------------------------------------------------------------------------
local FCharacterAttrOne = class("FCharacterAttrOne")

-- 构造
function FCharacterAttrOne:ctor()
    self.iBaseAdd 	= 0	-- 基础加法值
    self.iUpAdd 	= 0	-- 加成加法值
    self.iBaseMulti	= 0	-- 基础值乘法
    self.iUpMulti	= 0	-- 加成值乘法
    self.iAllMulti	= 0	-- 所有值乘法

    self.iFlag		= 0	-- 脏数据标记
    self.iLastVal	= 0	-- 最终值
end

-- 销毁
function FCharacterAttrOne:OnDestroy()
    self.iBaseAdd 	= 0
    self.iUpAdd 	= 0
    self.iBaseMulti	= 0
    self.iUpMulti	= 0
    self.iAllMulti	= 0

    self.iFlag		= 0
    self.iLastVal	= 0
end

-- 清除
function FCharacterAttrOne:Clear()
    self.iBaseAdd 	= 0
    self.iUpAdd 	= 0
    self.iBaseMulti	= 0
    self.iUpMulti	= 0
    self.iAllMulti	= 0

    self.iFlag		= 0
    self.iLastVal	= 0
end


-------------------------------------------------------------------------
-- 属性管理基类
-------------------------------------------------------------------------
local AttrMgrBase = class("AttrMgrBase", CharacterModule)

-- 构造函数
function AttrMgrBase:ctor()
    AttrMgrBase.super.ctor(self)
    self.Attrs 				= {}	-- 所有属性列表
    self.LastModifVal 		= 0		-- 修改前: 数值
    self.LastModifPrecent	= 0		-- 修改前: 万分比
end

-- 创建
function AttrMgrBase:OnCreate(AC_Controller)
    AttrMgrBase.super.OnCreate(self, AC_Controller)

    -- 初始化属性列表
    for iAttrID = Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN + 1, Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX do
        self.Attrs[iAttrID] = FCharacterAttrOne.new()
    end
end

-- 销毁
function AttrMgrBase:OnDestroy()
    for _, Attr in pairs(self.Attrs) do
        if "table" == type(Attr) and "function" == type(Attr.OnDestroy)then 
            Attr:OnDestroy()
        end
    end
    self.Attrs = nil
    
    self.LastModifVal 		= 0
    self.LastModifPrecent	= 0

    AttrMgrBase.super.OnDestroy(self)
end

-- 清除
function AttrMgrBase:OnClear()
    for _, Attr in pairs(self.Attrs) do
        if "table" == type(Attr) and "function" == type(Attr.Clear)then 
            Attr:Clear()
        end
    end
    self.Attrs = {}

    self.LastModifVal 		= 0
    self.LastModifPrecent	= 0

    AttrMgrBase.super.OnClear(self)
end

function AttrMgrBase:Tick(DeltaSeconds)

end

-- 获取属性
-- @Params: (int32)
function AttrMgrBase:GetAttr(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return
    end

    if self:GetAttr_Flag(iAttrID) > 0 then
        return self:GetAttr_LastVal(iAttrID)
    end

    local iBaseAdd  = self:GetAttr_BaseAdd(iAttrID)
    local iUpAdd    = self:GetAttr_UpAdd(iAttrID)
    local iBaseMul  = self:GetAttr_BaseMul(iAttrID)
    local iUpMul    = self:GetAttr_UpMul(iAttrID)
    local iAllMul   = self:GetAttr_AllMul(iAttrID)

    local iaddAll   = iBaseAdd + iUpAdd
    local iAttrVal  = iaddAll + iBaseAdd * iBaseMul / MATH_SCALE_10K
        + iUpAdd * iUpMul / MATH_SCALE_10K + iaddAll * iAllMul / MATH_SCALE_10K

    self:SetAttr_Flag(iAttrID, 1)
    self:SetAttr_LastVal(iAttrID, iAttrVal)

    return iAttrVal
end

-- 增加属性值
-- @Params: (Ds_ResCharacterAttrType, int32, Ds_ATTRADDTYPE)
function AttrMgrBase:AttrOpeAdd(iAttrID, iValue, iAddType)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return
    end

    if not self.Attrs[iAttrID] then
        self.Attrs[iAttrID] = {}
    end

    self:ModifiedAttrStart(iAttrID)

    if iAddType == Ds_ATTRADDTYPE.ATTRADD_BASE then
        self.Attrs[iAttrID].iBaseAdd = self.Attrs[iAttrID].iBaseAdd + iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_UPADD then
        self.Attrs[iAttrID].iUpAdd = self.Attrs[iAttrID].iUpAdd + iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_BASEMUL then
        self.Attrs[iAttrID].iBaseMulti = self.Attrs[iAttrID].iBaseMulti + iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_UPADDMUL then
        self.Attrs[iAttrID].iUpMulti = self.Attrs[iAttrID].iUpMulti + iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_ALLMUL then
        self.Attrs[iAttrID].iAllMulti = self.Attrs[iAttrID].iAllMulti + iValue

    end

    self:SetAttr_Flag(iAttrID, 0)

    self:ModifiedAttrEnd(iAttrID)

    -- 同步Pawn的属性
    local CharacterBase = self:GetOwnerPawn()
    if CharacterBase then
        CharacterBase:OnAttrChange_S(iAttrID)
    end
end

-- 减少属性值
-- @Params: (Ds_ResCharacterAttrType, int32, Ds_ATTRADDTYPE)
function AttrMgrBase:AttrOpeMove(iAttrID, iValue, iAddType)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return
    end

    if not self.Attrs[iAttrID] then
        self.Attrs[iAttrID] = {}
    end

    self:ModifiedAttrStart(iAttrID)

    if iAddType == Ds_ATTRADDTYPE.ATTRADD_BASE then
        self.Attrs[iAttrID].iBaseAdd = self.Attrs[iAttrID].iBaseAdd - iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_UPADD then
        self.Attrs[iAttrID].iUpAdd = self.Attrs[iAttrID].iUpAdd - iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_BASEMUL then
        self.Attrs[iAttrID].iBaseMulti = self.Attrs[iAttrID].iBaseMulti - iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_UPADDMUL then
        self.Attrs[iAttrID].iUpMulti = self.Attrs[iAttrID].iUpMulti - iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_ALLMUL then
        self.Attrs[iAttrID].iAllMulti = self.Attrs[iAttrID].iAllMulti - iValue

    end

    self:SetAttr_Flag(iAttrID, 0)

    self:ModifiedAttrEnd(iAttrID)

    -- 同步Pawn的属性
    local CharacterBase = self:GetOwnerPawn()
    if CharacterBase then
        CharacterBase:OnAttrChange_S(iAttrID)
    end
end

-- 设置属性值
-- @Params: (Ds_ResCharacterAttrType, int32, Ds_ATTRADDTYPE)
function AttrMgrBase:AttrOpeSet(iAttrID, iValue, iAddType)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return
    end
    
    if not self.Attrs[iAttrID] then
        self.Attrs[iAttrID] = {}
    end

    -- 检查值未变跳过
    if iAddType == Ds_ATTRADDTYPE.ATTRADD_BASE then
        if self.Attrs[iAttrID].iBaseAdd == iValue then
            return
        end
    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_UPADD then
        if self.Attrs[iAttrID].iUpAdd == iValue then
            return
        end
    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_BASEMUL then
        if self.Attrs[iAttrID].iBaseMulti == iValue then
            return
        end
    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_UPADDMUL then
        if self.Attrs[iAttrID].iUpMulti == iValue then
            return
        end
    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_ALLMUL then
        if self.Attrs[iAttrID].iAllMulti == iValue then
            return
        end
    end

    self:ModifiedAttrStart(iAttrID)

    if iAddType == Ds_ATTRADDTYPE.ATTRADD_BASE then
        self.Attrs[iAttrID].iBaseAdd = iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_UPADD then
        self.Attrs[iAttrID].iUpAdd = iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_BASEMUL then
        self.Attrs[iAttrID].iBaseMulti = iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_UPADDMUL then
        self.Attrs[iAttrID].iUpMulti = iValue

    elseif iAddType == Ds_ATTRADDTYPE.ATTRADD_ALLMUL then
        self.Attrs[iAttrID].iAllMulti = iValue
        
    end

    self:SetAttr_Flag(iAttrID, 0)

    self:ModifiedAttrEnd(iAttrID)

    -- 同步Pawn的属性
    local CharacterBase = self:GetOwnerPawn()
    if CharacterBase then
        CharacterBase:OnAttrChange_S(iAttrID)
    end
end

-- @Params: (int32)
function AttrMgrBase:GetAttr_BaseAdd(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return 0
    end
    
    return self.Attrs[iAttrID] and self.Attrs[iAttrID].iBaseAdd or 0
end

-- @Params: (int32)
function AttrMgrBase:GetAttr_UpAdd(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return 0
    end

    return self.Attrs[iAttrID] and self.Attrs[iAttrID].iUpAdd or 0
end

-- @Params: (int32)
function AttrMgrBase:GetAttr_BaseMul(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return 0
    end

    return self.Attrs[iAttrID] and self.Attrs[iAttrID].iBaseMulti or 0
end

-- @Params: (int32)
function AttrMgrBase:GetAttr_UpMul(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return 0
    end

    return self.Attrs[iAttrID] and self.Attrs[iAttrID].iUpMulti or 0
end

-- @Params: (int32)
function AttrMgrBase:GetAttr_AllMul(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return 0
    end

    return self.Attrs[iAttrID] and self.Attrs[iAttrID].iAllMulti or 0
end

-- @Params: (int32)
function AttrMgrBase:GetAttr_Flag(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return 0
    end

    return self.Attrs[iAttrID] and self.Attrs[iAttrID].iFlag or 0
end

-- @Params: (int32, int8)
function AttrMgrBase:SetAttr_Flag(iAttrID, val)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return
    end

    if not self.Attrs[iAttrID] then
        self.Attrs[iAttrID] = {}
    end

    self.Attrs[iAttrID].iFlag = val
end

-- @Params: (int32)
function AttrMgrBase:GetAttr_LastVal(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return 0
    end

    return self.Attrs[iAttrID] and self.Attrs[iAttrID].iLastVal or 0
end

-- @Params: (int32, int32)
function AttrMgrBase:SetAttr_LastVal(iAttrID, val)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return
    end

    if not self.Attrs[iAttrID] then
        self.Attrs[iAttrID] = {}
    end

    self.Attrs[iAttrID].iLastVal = val
end

-- 修改属性开始
-- @Params: (Ds_ResCharacterAttrType)
function AttrMgrBase:ModifiedAttrStart(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return
    end

    self.LastModifPrecent = MATH_SCALE_10K

    if iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP then
        self.LastModifVal = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP)
        self.LastModifPrecent = (self.LastModifVal ~= 0) and (self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP) * MATH_SCALE_10K) / self.LastModifVal or 0

    elseif iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_MP then
        self.LastModifVal = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_MP)
        self.LastModifPrecent = (self.LastModifVal ~= 0) and (self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP) * MATH_SCALE_10K) / self.LastModifVal or 0

    elseif iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_SHIELD then
        self.LastModifVal = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_SHIELD)
        self.LastModifPrecent = (self.LastModifVal ~= 0) and (self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP) * MATH_SCALE_10K) / self.LastModifVal or 0

    end
end

-- 修正数值
-- @Params: (Ds_ResCharacterAttrType)
function AttrMgrBase:ModifiedAttrEnd(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return
    end

    -- 边界保护
    if iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP then
        local remainHp = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP) - self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP)
        if remainHp > 0 then
            local lastHp = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP)
            self.Attrs[Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP].iBaseAdd = lastHp

            self:SetAttr_Flag(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP, 0)

            local CharacterBase = self:GetOwnerPawn()
            if CharacterBase then
                CharacterBase:OnAttrChange_S(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP)
            end
        end
        
    elseif iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP then
        local remainMp = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP) - self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_MP)
        if remainMp > 0 then
            local lastMp = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_MP)
            self.Attrs[Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP].iBaseAdd = lastMp

            self:SetAttr_Flag(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP, 0)

            local CharacterBase = self:GetOwnerPawn()
            if CharacterBase then
                CharacterBase:OnAttrChange_S(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP)
            end
        end
        
    elseif iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD then
        local remainShield = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD) - self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_SHIELD)
        if remainShield > 0 then
            local lastMp = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_SHIELD)
            self.Attrs[Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD].iBaseAdd = lastMp

            self:SetAttr_Flag(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD, 0)

            local CharacterBase = self:GetOwnerPawn()
            if CharacterBase then
                CharacterBase:OnAttrChange_S(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD)
            end
        end

    elseif iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP then
        local maxHp = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP)

        -- 如果增加了 走比值
        if maxHp > self.LastModifVal then
            local lastHp = (self.LastModifPrecent * maxHp) / MATH_SCALE_10K
            self.Attrs[Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP].iBaseAdd = lastHp
            
        else
            local curHp = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP)
            local lastHp = curHp > maxHp and maxHp or curHp
            self.Attrs[Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP].iBaseAdd = lastHp
        
        end

        self:SetAttr_Flag(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP, 0)

        local CharacterBase = self:GetOwnerPawn()
        if CharacterBase then
            CharacterBase:OnAttrChange_S(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP)
        end

    elseif iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_MP then
        local maxMp = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_MP)

        -- 如果增加了 走比值
        if maxMp > self.LastModifVal then
            local lastMp = (self.LastModifPrecent * maxMp) / MATH_SCALE_10K
            self.Attrs[Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP].iBaseAdd = lastMp

        else
            local curMp = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP)
            local lastMp = curMp > maxMp and maxMp or curMp
            self.Attrs[Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP].iBaseAdd = lastMp
        
        end

        self:SetAttr_Flag(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP, 0)

        local CharacterBase = self:GetOwnerPawn()
        if CharacterBase then
            CharacterBase:OnAttrChange_S(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP)
        end

    elseif iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_SHIELD then
        local maxShield = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_SHIELD)

        -- 如果增加了 走比值
        if maxShield > self.LastModifVal then
            local lastShield = (self.LastModifPrecent * maxShield) / MATH_SCALE_10K
            self.Attrs[Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD].iBaseAdd = lastShield

        else
            local curShield = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD)
            local lastShield = curShield > maxShield and maxShield or curShield
            self.Attrs[Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD].iBaseAdd = lastShield
        
        end

        self:SetAttr_Flag(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD, 0)

        local CharacterBase = self:GetOwnerPawn()
        if CharacterBase then
            CharacterBase:OnAttrChange_S(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD)
        end
    end
end

-- [client]Todo: client
-- @Params: (int32, int32)
function AttrMgrBase:SetAttr_C(iAttrID, val)
    if not iAttrID or iAttrID <= Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN or iAttrID > Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX then
        return
    end

    if not self.Attrs[iAttrID] then
        self.Attrs[iAttrID] = {}
    end

    self.Attrs[iAttrID].iLastVal = val
    self:SetAttr_Flag(iAttrID, 1)
end

-------------------------------------------------------------------------
-- 属性管理类
-------------------------------------------------------------------------

HP_RECOVERY_INTERAL = 1.0
HP_INJURED_PRECENT  = 300

local CharacterAttrMgr = class("CharacterAttrMgr", AttrMgrBase)

function CharacterAttrMgr:ctor()
    CharacterAttrMgr.super.ctor(self)

    self.LastRecoveryTime = 0
    self.Level = 1
end

function CharacterAttrMgr:OnInit()
    local CharacterBase = self:GetOwnerPawn()
    if CharacterBase then
        local characterConfigData = CharacterBase.CharacterConfigData
        if not characterConfigData or not characterConfigData.CharacterAttrConfigData then
            return
        end

        local CharacterAttrConfigData = characterConfigData.CharacterAttrConfigData

        -- 生命最大值
        local tempVal = CharacterAttrConfigData.HpMax
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.HPRecovery
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP_RECOVERY, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.DownHp
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_DOWN_HP, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.ResurgenceHP
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_RESURGENCE_HP, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.HPRecoveryInterval
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP_RECOVERY_INTERVAL, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.StopHurtHPRecoveryTime
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_STOP_HURT_HP_RECOVERY_TIME, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.HPRecoveryType
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP_RECOVERY_TYPE, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        -- shield
        tempVal = self:CalLeveUp(CharacterAttrConfigData.ShieldMax, CharacterAttrConfigData.ShieldMax_Lv, self.Level)
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_SHIELD, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = self:CalLeveUp(CharacterAttrConfigData.Shield_ReCover, CharacterAttrConfigData.Shield_ReCover_Lv, self.Level)
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD_RECOVER, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.Cd_Reduction
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_CD_REDUCTION, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        -- armor
        tempVal = CharacterAttrConfigData.ArmorHead
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORHEAD, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.ArmorNeck
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORNECK, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.ArmorTorso
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORTORSO, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.ArmorStomach
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORSTOMACH, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.ArmorLimbs
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORLIMBS, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        -- 移动速度
        tempVal = CharacterAttrConfigData.Walk_MoveSpeed
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_WALK_MOVESPEED, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.Run_MoveSpeed
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_RUN_MOVESPEED, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.Roll_Acceleration
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ROLL_ACCELERATION, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.EnterCover_MoveSpeed
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ENTERCOVER_MOVESPEED, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)
        
        tempVal = CharacterAttrConfigData.EnterCover_Acceleration
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ENTERCOVER_ACCELERATION, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.Roll_DurationTime
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ROLL_DURATIONTIME, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.Down_MoveSpeed
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_DOWN_MOVESPEED, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.Roll_CD
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ROLL_COOLDOWNTIME, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.SelfRescueSpeed
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SELFRESCUESPEED, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        tempVal = CharacterAttrConfigData.RescueSpeed
        self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_RESCUESPEED, tempVal, Ds_ATTRADDTYPE.ATTRADD_BASE)

        self:FillHpMpPrecent(MATH_SCALE_10K)
    end
end

function CharacterAttrMgr:Tick(DeltaSeconds)
    CharacterAttrMgr.super.Tick(self, DeltaSeconds)

    local CharacterBase = self:GetOwnerPawn()
    if  not CharacterBase or not CharacterBase:IsAlive() or CharacterBase:IsDown() then
        return
    end

    local CurrentTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(CharacterBase:GetWorld())
    local LastBeHitTime = CharacterBase:GetLastBeHitTime()
    local DeltaTime = CurrentTime - LastBeHitTime 

    self.LastRecoveryTime = self.LastRecoveryTime + DeltaSeconds

    local hp_recovery_interval = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP_RECOVERY_INTERVAL)
    if self.LastRecoveryTime > hp_recovery_interval then
        self.LastRecoveryTime = self.LastRecoveryTime - hp_recovery_interval
         
        local stop_hurt_recovery_time = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_STOP_HURT_HP_RECOVERY_TIME) 
        if not self:IsHPFull() and DeltaTime >= stop_hurt_recovery_time then
            local hp_recovery = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP_RECOVERY)
            local val = hp_recovery / 5
            local hp_recovery_type = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP_RECOVERY_TYPE)
            if hp_recovery_type == ECharacterHpRecoveryType.ECharacterHpRecoveryType_Fixed then
                val = hp_recovery
            elseif hp_recovery_type == ECharacterHpRecoveryType.ECharacterHpRecoveryType_Ratio then
                val = UE4.UKismetMathLibrary.Round((hp_recovery * self:GetHPMax()) / MATH_SCALE_10K)
            end
            if val ~= 0 then
                self:AttrOpeAdd(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP, val, Ds_ATTRADDTYPE.ATTRADD_BASE)
            end
        end

        if not self:IsShieldFull() then
            local shield_recovery = self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD_RECOVER)
            local val = shield_recovery / 5
            if val ~= 0 then
                self:AttrOpeAdd(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD, val, Ds_ATTRADDTYPE.ATTRADD_BASE)
            end
        end
       
    end
end

function CharacterAttrMgr:OnRevival()
    self:FillHpMpPrecent(MATH_SCALE_10K)
end

function CharacterAttrMgr:FillHpMpPrecent(precent)
    local hp = self:GetHPMax() * precent / MATH_SCALE_10K
    local mp = self:GetMPMax() * precent / MATH_SCALE_10K

    self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP, hp, Ds_ATTRADDTYPE.ATTRADD_BASE)
    self:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP, mp, Ds_ATTRADDTYPE.ATTRADD_BASE)
end

function CharacterAttrMgr:GetHP()
    return self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP)
end

function CharacterAttrMgr:GetHPMax()
    return self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP)
end

function CharacterAttrMgr:IsHPFull()
    return (self:GetHP() == self:GetHPMax()) and true or false
end

function CharacterAttrMgr:GetMP()
    return self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MP)
end

function CharacterAttrMgr:GetMPMax()
    return self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_MP)
end

function CharacterAttrMgr:IsMPFull()
    return (self:GetMP() == self:GetMPMax()) and true or false
end

function CharacterAttrMgr:GetSheild()
    return self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD)
end

function CharacterAttrMgr:GetSheildMax()
    return self:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_SHIELD)
end

function CharacterAttrMgr:IsShieldFull()
    return (self:GetSheild() == self:GetSheildMax()) and true or false
end

function CharacterAttrMgr:CalLeveUp(baseVal, upVal, curLevel)
    return baseVal + upVal * (curLevel - 1)
end

return CharacterAttrMgr