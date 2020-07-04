require "UnLua"

local ShootWeaponModule = require "Gameplay/Equips/ShootWeapon/Module/ShootWeaponModule"

local ShootWeaponAttrMgr = class("ShootWeaponAttrMgr", ShootWeaponModule)

-------------------------------------------------------------------------
-- 属性结构体
-------------------------------------------------------------------------
local FShootWeaponAttrOne = class("FShootWeaponAttrOne")

-- 构造
function FShootWeaponAttrOne:ctor()
    self.iBaseAdd 	= 0	-- 基础加法值
    self.iUpAdd 	= 0	-- 加成加法值
    self.iBaseMulti	= 0	-- 基础值乘法
    self.iUpMulti	= 0	-- 加成值乘法
    self.iAllMulti	= 0	-- 所有值乘法

    self.iFlag		= 0	-- 脏数据标记
    self.iLastVal	= 0	-- 最终值
end

-- 销毁
function FShootWeaponAttrOne:OnDestroy()
    self.iBaseAdd 	= 0
    self.iUpAdd 	= 0
    self.iBaseMulti	= 0
    self.iUpMulti	= 0
    self.iAllMulti	= 0

    self.iFlag		= 0
    self.iLastVal	= 0
end

-- 清除
function FShootWeaponAttrOne:Clear()
    self.iBaseAdd 	= 0
    self.iUpAdd 	= 0
    self.iBaseMulti	= 0
    self.iUpMulti	= 0
    self.iAllMulti	= 0

    self.iFlag		= 0
    self.iLastVal	= 0
end

-- 构造函数
function ShootWeaponAttrMgr:ctor()
	ShootWeaponAttrMgr.super.ctor(self)
    
    self.Attrs = {}	-- 所有属性列表
end

-- 创建
function ShootWeaponAttrMgr:OnCreate(ShootWeapon)
	ShootWeaponAttrMgr.super.OnCreate(self, ShootWeapon)

    -- 初始化属性列表
    for iAttrID = Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN + 1, Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX do
        self.Attrs[iAttrID] = FShootWeaponAttrOne.new()
    end
end

-- 销毁
function ShootWeaponAttrMgr:OnDestroy()
	ShootWeaponAttrMgr.super.OnDestroy(self)

    for _, Attr in pairs(self.Attrs) do
        if "table" == type(Attr) and "function" == type(Attr.OnDestroy)then 
            Attr:OnDestroy()
        end
    end
    self.Attrs = nil
end

function ShootWeaponAttrMgr:OnInit()

end

-- 清除
function ShootWeaponAttrMgr:OnClear()
    for _, Attr in pairs(self.Attrs) do
        if "table" == type(Attr) and "function" == type(Attr.Clear)then 
            Attr:Clear()
        end
    end
    self.Attrs = {}
end

function ShootWeaponAttrMgr:Tick(DeltaSeconds)
    
end

-- 获取属性
-- @params: (int32)
function ShootWeaponAttrMgr:GetAttr( iAttrID)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
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

	local iaddAll = iBaseAdd + iUpAdd
	local iAttrVal = iaddAll + iBaseAdd * iBaseMul / MATH_SCALE_10K
		+ iUpAdd * iUpMul / MATH_SCALE_10K + iaddAll * iAllMul / MATH_SCALE_10K

	self:SetAttr_Flag(iAttrID, 1)
	self:SetAttr_LastVal(iAttrID, iAttrVal)

	return iAttrVal
end

-- 增加属性
-- @params: (Ds_ResWeaponAttrType, int32, Ds_ATTRADDTYPE)
function ShootWeaponAttrMgr:AttrOpeAdd(iAttrID, iValue, iAddType)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
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

    if self.ShootWeapon then
        self.ShootWeapon:OnAttrChange_S(iAttrID)
    end
end

-- 减少属性
-- @params: (Ds_ResWeaponAttrType, int32, Ds_ATTRADDTYPE)
function ShootWeaponAttrMgr:AttrOpeMove(iAttrID, iValue, iAddType)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
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

    if self.ShootWeapon then
        self.ShootWeapon:OnAttrChange_S(iAttrID)
    end
end

-- 设置属性
-- @params: (Ds_ResWeaponAttrType, int32, Ds_ATTRADDTYPE)
function ShootWeaponAttrMgr:AttrOpeSet(iAttrID, iValue, iAddType)
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

    if self.ShootWeapon then
        self.ShootWeapon:OnAttrChange_S(iAttrID)
    end
end

-- @params: (int32)
function ShootWeaponAttrMgr:GetAttr_BaseAdd(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
        return 0
    end

	return self.Attrs[iAttrID].iBaseAdd
end

-- @params: (int32)
function ShootWeaponAttrMgr:GetAttr_UpAdd(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
        return 0
    end

	return self.Attrs[iAttrID].iUpAdd
end

-- @params: (int32)
function ShootWeaponAttrMgr:GetAttr_BaseMul(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
        return 0
    end

	return self.Attrs[iAttrID].iBaseMulti
end

-- @params: (int32)
function ShootWeaponAttrMgr:GetAttr_UpMul(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
        return 0
    end

	return self.Attrs[iAttrID].iUpMulti
end

-- @params: (int32)
function ShootWeaponAttrMgr:GetAttr_AllMul(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
        return 0
    end

	return self.Attrs[iAttrID].iAllMulti
end

-- @params: (int32)
function ShootWeaponAttrMgr:GetAttr_Flag(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
        return 0
    end

	return self.Attrs[iAttrID].iFlag
end

-- @params: (int32, int8)
function ShootWeaponAttrMgr:SetAttr_Flag(iAttrID, val)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
        return
    end

    if not self.Attrs[iAttrID] then
        self.Attrs[iAttrID] = {}
    end

	self.Attrs[iAttrID].iFlag = val
end

-- @params: (int32)
function ShootWeaponAttrMgr:GetAttr_LastVal(iAttrID)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
        return 0
    end

	return self.Attrs[iAttrID].iLastVal
end

-- @params: (int32, int32)
function ShootWeaponAttrMgr:SetAttr_LastVal(iAttrID, val)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
        return
    end

	self.Attrs[iAttrID].iLastVal = val
end

-- @params: (Ds_ResWeaponAttrType)
function ShootWeaponAttrMgr:ModifiedAttrStart(iAttrID)

end

-- @params: (Ds_ResWeaponAttrType)
function ShootWeaponAttrMgr:ModifiedAttrEnd(iAttrID)

end

-- [client]Todo: client
-- @params: (int32, int32)
function ShootWeaponAttrMgr:SetAttr_C(iAttrID, val)
    if not iAttrID or iAttrID <= Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN or iAttrID > Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX then
        return
    end

	self.Attrs[iAttrID].iLastVal = val
	self:SetAttr_Flag(iAttrID, 1)
end


return ShootWeaponAttrMgr