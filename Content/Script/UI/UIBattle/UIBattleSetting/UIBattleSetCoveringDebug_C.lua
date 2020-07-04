--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local UIBattleSetCoveringDebug_C = Class()

--function UIBattleSetCoveringDebug_C:Initialize(Initializer)
--end

--function UIBattleSetCoveringDebug_C:PreConstruct(IsDesignTime)
--end

function UIBattleSetCoveringDebug_C:Construct()
    --- 用户设置的默认值
    self:SetUserConfigSettings()

    ----------------------------------------------------------------------
    ----- UI Event
    ----------------------------------------------------------------------
    --- 高低掩体切换
    self.CheckBox_CoverHeight.OnCheckStateChanged:Add(self, UIBattleSetCoveringDebug_C.OnCheckStateChanged_CoverHeight)
    --- 轴向切换
    self.CheckBox_CoverAxis.OnCheckStateChanged:Add(self, UIBattleSetCoveringDebug_C.OnCheckStateChanged_CoverAxis)
end

--function UIBattleSetCoveringDebug_C:Tick(MyGeometry, InDeltaTime)
--end

-------------------------------------------------------------------------
--- Input Event
-------------------------------------------------------------------------
--- 高低掩体切换
function UIBattleSetCoveringDebug_C:OnCheckStateChanged_CoverHeight(bIsChecked)
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local AllowChangeHeightSetting = UserConfigSettings.AllowChangeHeightSetting
        if AllowChangeHeightSetting then
            UserConfigSettings:SetBool(AllowChangeHeightSetting.Section, AllowChangeHeightSetting.Key, bIsChecked)
        end
    end
end

--- 轴向切换
function UIBattleSetCoveringDebug_C:OnCheckStateChanged_CoverAxis(bIsChecked)
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local AllowChangeCameraSetting = UserConfigSettings.AllowChangeCameraSetting
        if AllowChangeCameraSetting then
            UserConfigSettings:SetBool(AllowChangeCameraSetting.Section, AllowChangeCameraSetting.Key, bIsChecked)
        end
    end
end


-------------------------------------------------------------------------
--- 设置数据接口
-------------------------------------------------------------------------
--- 用户设置的默认值
function UIBattleSetCoveringDebug_C:SetUserConfigSettings()
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        --- 高低掩体切换
        local AllowChangeHeightSetting = UserConfigSettings.AllowChangeHeightSetting
        if AllowChangeHeightSetting then
            local bIsChecked = UserConfigSettings:GetBool(AllowChangeHeightSetting.Section, AllowChangeHeightSetting.Key, AllowChangeHeightSetting.Value)
            self.CheckBox_CoverHeight:SetIsChecked(bIsChecked and true or false)
        end

        --- 轴向切换
        local AllowChangeCameraSetting = UserConfigSettings.AllowChangeCameraSetting
        if AllowChangeCameraSetting then
            local bIsChecked = UserConfigSettings:GetBool(AllowChangeCameraSetting.Section, AllowChangeCameraSetting.Key, AllowChangeCameraSetting.Value)
            self.CheckBox_CoverAxis:SetIsChecked(bIsChecked and true or false)
        end
    end
end

return UIBattleSetCoveringDebug_C
