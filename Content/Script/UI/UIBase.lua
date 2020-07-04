
local M = {}

function M.super(cls)
	return getmetatable(cls).__index
end

--判断一个class或者对象是否
function M.is_a(cls_or_obj, other_cls)
	local tmp = cls_or_obj
	while true do
		local mt = getmetatable(tmp)
		if mt then
			tmp = mt.__index
			if tmp == other_cls then
				return true
			end
		else
			return false
		end
	end
end

--没有一个比较好的方法来防止将Class的table当成一个实例来使用
--命名一个Class的时候一定要和其产生的实例区别开来。
---@class UIBase
local UIBase = {
		--用于区别是否是一个对象 or Class or 普通table
		__UIBaseType__ = "<base class>"
}
UIBase.__index = UIBase
M.UIBase = UIBase

-- DEBUG 接口
local _OBJ_POOL = {}
local weak_mt = { __mode = 'kv' }
local tinsert = table.insert
local function _insert_obj(obj)
    local cls_type = obj.__UIBaseType__
    if not _OBJ_POOL[cls_type] then
        _OBJ_POOL[cls_type] = setmetatable({}, weak_mt)
    end
    _OBJ_POOL[cls_type][obj] = true
end
local function class_info(cls_type)
    if not cls_type then
        return _OBJ_POOL 
    else
        return _OBJ_POOL[cls_type]
    end
end

local function sizeof(t)
    local i = 0
    for _, _ in pairs(t) do
        i = i + 1
    end
    return i
end

local function print_class_info(cls_type)
    local info = class_info(cls_type) 
    if not cls_type then
        for k, v in pairs(info) do
            print('class: ', k, sizeof(v))
        end
    elseif info then
        print('class: ', cls_type, sizeof(info))
    end
end

M.class_info = class_info
M.print_class_info = print_class_info
-- DEBUG 接口结束

function UIBase:Inherit(class_type)	
	local o = {}
    o.__index = o
    o.__UIBaseType__ = class_type or '<base class>'
    
    if self.__tostring then
        o.__tostring = self.__tostring
    end

	return setmetatable(o, self)
end

function UIBase:New(...)
	local o = {}

	--子类，应该在自己的init函数中调用父类的init函数
	setmetatable(o, self)

    if o._init then
		o:_init(...)
	end
    _insert_obj(o)

    print("New Class :" .. o.__UIBaseType__)
	return o
end

function UIBase:Impl(obj, ...)
	--子类，应该在自己的init函数中调用父类的init函数
	setmetatable(obj, self)

    if obj._init then
		obj:_init(...)
	end
    _insert_obj(o)
	return obj
end

function UIBase:is_a(other_cls)
	return M.is_a(self, other_cls)
end

-- 没事还是用 Pattern.XXX 代替 self:super().XXX 吧
function UIBase:super()
    return M.super(getmetatable(self))
end

function UIBase:__tostring()
    local mt = getmetatable(self)
    local tbl_str = tostring(setmetatable(self, {}))
    setmetatable(self, mt)
    if self._class then
        return self._class.__UIBaseType__ .. '实例: ' .. tbl_str
    else
        return self.__UIBaseType__ .. '类:' .. tbl_str
    end
end

return M

