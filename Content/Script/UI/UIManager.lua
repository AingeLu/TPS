if LUIManager ~= nil then
    return LUIManager
end

LUIManager = {}

require("UI/UIConfig")
local LUIRdNameConfig = require("UI/UIRdNameConfig")

--[[ UI显示栈
LUIManager.UIStack = {
    1 = {
        name = name1,
        uiLayer = {
            1 = {
                name = name1,
                args = { ... },
            },
            ...
        }
    },
    
	...
	
}

function OnLuaCreate()
function OnAwake(bpClass)
function OnDeosty()
function Tick(deltaSeconds)
function OnShowWindow(bpClass, ...)
function OnHideWindow()
--]]

LUIManager.UIStack = {}
-- 蓝图类缓存[name=obj]
LUIManager.BPClasses = {}
-- 消息注册[name={msgid,func}]
LUIManager.LuaMsgPool = {}

function LUIManager:OnInit()
    print("LUIManager.Init succ")
    
    LUIRdNameConfig:OnInit();

	 for name, config in pairs(LUIManager.UIConfig) do
        print("name : " , name)
		self.LuaMsgPool[name] = {};
    end

end

function LUIManager:UnInit()

    LUIRdNameConfig:UnInit();

	LUIManager.UIStack = {}
	LUIManager.BPClasses = {}
	LUIManager.LuaMsgPool = {}
	print("LUIManager.UnInit succ")

end

function LUIManager:PostMsg(msgId, ...)

    if DEBUG_LOG_UI_MGS == 1 then
        --print("LUIManager PostMsg:"..msgId)
    end

	for name, v in pairs(self.LuaMsgPool) do

		local bpClass = self.BPClasses[name];
		
		if  bpClass ~= nil and
            bpClass:IsInViewport() and
            bpClass:GetVisibility() ~= UE4.ESlateVisibility.Hidden then
			for _msgId,_func in pairs(v) do
				if msgId == _msgId and _func ~= nil then
					_func(...);
				end
			end
		end

	end
end

function LUIManager:RegisterMsg(name,msgId,func)
	if msgId == nil then
		print("LUIManager RegisterMsg msgid is null, name:"..name)
		return;
	end

	local MsgPool = self.LuaMsgPool[name];
	if MsgPool ~= nil then
		MsgPool[msgId] = func;
	else
		print("LUIManager RegisterMsg not find name:"..name)
	end
end

function LUIManager:UnRegisterMsg(name,msgId)
	local MsgPool = self.LuaMsgPool[name];
	if MsgPool == nil then
		MsgPool[msgId] = nil;
	end
end

-------------------------------------------------------------
-- 辅助函数
-------------------------------------------------------------
-- 显示UI
function LUIManager:ShowUI(name, ...)
    print("LUIManager.ShowUI name = " .. name)
    local config = self.UIConfig[name]
    if nil == config then
        print("LUIManager.ShowUI config is nil. name = " .. name)
        return
    end

    local bpClass = self.BPClasses[name]
    if nil == bpClass then

        --- 创建蓝图 Widget
        bpClass = self:LoadUI(config.bp_class)

        print("LUIManager:ShowUI Load UI Success .")

        if bpClass == nil then
            print("bpClass is nil . bp_class : " , config.bp_class)
        end

        self.BPClasses[name] = bpClass;

        if LUIManager:IsAdaptIphonex() then
            local adapterCvs = bpClass.Adapt_CanvasPanel
            print("|| AdaptIphonex ... name :" , name)
            if adapterCvs ~= nil then
                local CanvasAdapt_cvs = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(adapterCvs);

                local margin = UE4.FMargin()
                margin.Left = 56.0
                margin.Right = 56.0

                if CanvasAdapt_cvs ~= nil then

                    CanvasAdapt_cvs:SetOffsets(margin);
                end
            end
        end
    end

    if bpClass == nil then
        print("bpClass is nil ........")
        return
    end

    if not bpClass:IsInViewport() then
        bpClass:AddToViewport(config.layer)
    else
        if not bpClass:GetIsEnabled() then
            bpClass:SetIsEnabled(true)
            bpClass:SetVisibility(UE4.ESlateVisibility.Visible)
        end
    end

    --- 调用 OnShowWindow
    if bpClass.OnShowWindow ~= nil and type(bpClass.OnShowWindow) == "function" then
        bpClass:OnShowWindow(...)
    end
end

function LUIManager:IsAdaptIphonex ( )
    return  UE4.UMGLuaUtils.UMG_GetScreen() >= 2
end

-- 加载UI
function LUIManager:LoadUI(bpPath)

    if bpPath == nil then
        print("LUIManager:LoadUI bpPath is nil.")
        return
    end

    local Widget = UE4.UMGLuaUtils.UMG_LoadUI(bpPath)

    return Widget
end

-- 隐藏UI
function LUIManager:HideUI(name)
    print("LUIManager.HideUI name = " .. name)
    
    local bpClass = self.BPClasses[name];
    if bpClass ~= nil  then

		if bpClass:IsInViewport() and bpClass:GetIsEnabled() then
            bpClass:SetIsEnabled(false)
            bpClass:SetVisibility(UE4.ESlateVisibility.Collapsed)
		end

        if bpClass ~= nil and type(bpClass.OnHideWindow) == "function" then
            bpClass:OnHideWindow()
        end
    end
end


-- 销毁UI
function LUIManager:DestroyUI(name)
    print("LUIManager.DestroyUI name = " .. name)
	
	local bpClass = self.BPClasses[name];
    if bpClass ~= nil  then

        if bpClass ~= nil and type(bpClass.OnDestroy) == "function" then
            bpClass:OnDestroy()
        end

		if bpClass:IsInViewport() then 
			bpClass:RemoveFromViewport();
		end
		--bpClass:Destruct();
        print("name = " , name , "  RemoveFromViewport ...")
    end
	
	self.LuaMsgPool[name] = {};
	self.BPClasses[name] = nil;
end


-- UIStack 插入UI
function LUIManager:InsertUI(name, mode, ...)
    print("LUIManager.InsertUI name = " .. name)
    
    local uiLayer = nil
    local bFindLayer = false
    for _, v in pairs(self.UIStack) do
        if v.name == name then
            uiLayer = v.uiLayer
            bFindLayer = true
            break
        end
        
        for _, v2 in pairs(v.uiLayer) do
            if v2.name == name then
                uiLayer = v.uiLayer
                bFindLayer = true
                break
            end
        end
        
        if bFindLayer then break end
    end

    if false == bFindLayer then
        if mode == "overlay" then
            local topLayer = self.UIStack[#self.UIStack]
            if topLayer then
                uiLayer = topLayer.uiLayer
            end
        end
        if nil == uiLayer then
            uiLayer = {}
            table.insert(self.UIStack, {name = name, uiLayer = uiLayer})
        end
    end
    
    local uiInfo = nil
    for _, v in pairs(uiLayer) do
        if v.name == name then
            v.args = {...}
            uiInfo = v
            break
        end
    end
    
    if nil == uiInfo then
        table.insert(uiLayer, {name = name, args = { ... }})
    end
end

-- UIStack 删除UI
function LUIManager:RemoveUI(name)
    print("LUIManager.RemoveUI name = " .. name)

    for k, v in pairs(self.UIStack) do
        local uiLayer = v.uiLayer
        if uiLayer then
            local bFlag = false
            for k2, v2 in pairs(uiLayer) do
                if v2.name == name then
                    table.remove(uiLayer, k2)
                    bFlag = true
                    break
                end
            end
            
            if #uiLayer <= 0 then
                table.remove(self.UIStack, k)
            end
            
            if true == bFlag then
                break
            end
        end
    end
end

-- 隐藏UI栈内所有界面
function LUIManager:HideUIStack(mode)
    print("LUIManager.HideUIStack mode = " .. mode)
    if mode == "overlay" then
        return
    end
    
    for _, v in pairs(self.UIStack or {}) do
        for _, v2 in pairs(v.uiLayer or {}) do
            local uiConfig = self.UIConfig[v2.name]
            if uiConfig ~= nil and uiConfig.mode ~= "overlay" then
                LUIManager:HideUI(v2.name)
            end
        end
    end
end

-- 显示Layer层内所有界面
function LUIManager:ShowUILayer(index)
    print("LUIManager.ShowUILayer index = " .. index)
    
    local uiLayer = self.UIStack[index]
    if uiLayer then
        for k, v in pairs(uiLayer.uiLayer or {}) do
            self:ShowUI(v.name, v.args)
        end
    end
end

function LUIManager.CallShowWindow(name)
    local uiManager =   require "Core/UI/UIManager"
    uiManager:ShowWindow(name);
end
-------------------------------------------------------------
-- 显示界面
function LUIManager:ShowWindow(name, ...)
    print("LUIManager.ShowWindow name = " .. name)

    local config = self.UIConfig[name]
    if nil == config then
        print("LUIManager.ShowWindow config is nil. name = " .. name)
        return
    end
    
    -- 隐藏栈内界面
    self:HideUIStack(config.mode)
    
    -- 显示界面
    self:ShowUI(name, ...)
    
    -- 加到显示栈顶
    self:InsertUI(config.name, config.mode, ...)

    --dump(self.UIStack, "ShowWindow.UIStack", 7)
end

-------------------------------------------------------------
-- 隐藏界面
function LUIManager:HideWindow(name)
    print("LUIManager.HideWindow name = " .. name)
    
    -- 隐藏界面
    self:HideUI(name)
    
    -- 从显示栈内删除
    self:RemoveUI(name)
    --dump(self.UIStack, "HideWindow.UIStack", 7)

    -- 显示栈顶界面
    self:ShowUILayer(#self.UIStack)
end

-- 销毁界面
function LUIManager:DestroyWindow(name)
    print("LUIManager.DestroyWindow name = " .. name)
    
    -- 隐藏界面
    self:DestroyUI(name)
    
    -- 从显示栈内删除
    self:RemoveUI(name)

    -- 显示栈顶界面
    self:ShowUILayer(#self.UIStack)

    dump(self.UIStack)
end

-- 销毁界面
function LUIManager:DestroyAllWindow()
   
   for k,v in pairs(self.BPClasses) do
		local bpClass = self.BPClasses[k];
		if bpClass ~= nil then
			self:DestroyUI(k)
		end	
	end
	
	self.UIStack = {}
end


function LUIManager:IsInViewport(name)
    local bpClass = self.BPClasses[name];
    if bpClass == nil then
        return false
    end

    return bpClass:IsInViewport()
end


--==================内部模块==========================

function LUIManager:GetRdNameConfig()
    return LUIRdNameConfig;
end


return LUIManager