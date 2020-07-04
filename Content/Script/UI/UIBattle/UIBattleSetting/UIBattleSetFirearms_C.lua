--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local UIBattleSetFirearms_C = Class()

--function UIBattleSetFirearms_C:Initialize(Initializer)
--end

--function UIBattleSetFirearms_C:PreConstruct(IsDesignTime)
--end

function UIBattleSetFirearms_C:Construct()
    --- 用户设置的默认值
    self:SetUserConfigSettings()

    --------------------------------------------------------------------
    --- UI Event
    --------------------------------------------------------------------
    --- 一键开镜开火
    self.CheckBox_OnekeyAimFire.OnCheckStateChanged:Add(self, UIBattleSetFirearms_C.OnCheckStateChanged_OnekeyAimFire)
    --- 自动开火
    self.CheckBox_AutoFire.OnCheckStateChanged:Add(self, UIBattleSetFirearms_C.OnCheckStateChanged_AutoFire)
    --- 辅助瞄准
    self.CheckBox_AimAssist.OnCheckStateChanged:Add(self, UIBattleSetFirearms_C.OnCheckStateChanged_AimAssist)

end

--function UIBattleSetFirearms_C:Tick(MyGeometry, InDeltaTime)
--end

-------------------------------------------------------------------------
--- Input Event
-------------------------------------------------------------------------
--- 一键开镜开火
function UIBattleSetFirearms_C:OnCheckStateChanged_OnekeyAimFire(bIsChecked)
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local OnekeyAimFireSetting = UserConfigSettings.OnekeyAimFireSetting
        if OnekeyAimFireSetting then
            UserConfigSettings:SetBool(OnekeyAimFireSetting.Section, OnekeyAimFireSetting.Key, bIsChecked)
        end
    end
end

--- 自动开火
function UIBattleSetFirearms_C:OnCheckStateChanged_AutoFire(bIsChecked)
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local AutoFireSetting = UserConfigSettings.AutoFireSetting
        if AutoFireSetting then
            UserConfigSettings:SetBool(AutoFireSetting.Section, AutoFireSetting.Key, bIsChecked)
        end
    end
end

--- 辅助瞄准
function UIBattleSetFirearms_C:OnCheckStateChanged_AimAssist(bIsChecked)
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local AimAssistSetting = UserConfigSettings.AimAssistSetting
        if AimAssistSetting then
            UserConfigSettings:SetBool(AimAssistSetting.Section, AimAssistSetting.Key, bIsChecked)
        end
    end
end

-------------------------------------------------------------------------
--- 设置数据接口
-------------------------------------------------------------------------
--- 用户设置的默认值
function UIBattleSetFirearms_C:SetUserConfigSettings()
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        --- 一键开镜开火
        local OnekeyAimFireSetting = UserConfigSettings.OnekeyAimFireSetting
        if OnekeyAimFireSetting then
            local bIsChecked = UserConfigSettings:GetBool(OnekeyAimFireSetting.Section, OnekeyAimFireSetting.Key, OnekeyAimFireSetting.Value)
            self.CheckBox_OnekeyAimFire:SetIsChecked(bIsChecked and true or false)
        end

        --- 自动开火
        local AutoFireSetting = UserConfigSettings.AutoFireSetting
        if AutoFireSetting then
            local bIsChecked = UserConfigSettings:GetBool(AutoFireSetting.Section, AutoFireSetting.Key, AutoFireSetting.Value)
            self.CheckBox_AutoFire:SetIsChecked(bIsChecked and true or false)
        end

        --- 辅助瞄准
        local AimAssistSetting = UserConfigSettings.AimAssistSetting
        if AimAssistSetting then
            local bIsChecked = UserConfigSettings:GetBool(AimAssistSetting.Section, AimAssistSetting.Key, AimAssistSetting.Value)
            self.CheckBox_AimAssist:SetIsChecked(bIsChecked and true or false)
        end
    end
end

return UIBattleSetFirearms_C
