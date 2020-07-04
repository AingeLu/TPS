--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local UIBattleSetStandingShoot_C = Class()

--function UIBattleSetStandingShoot_C:Initialize(Initializer)
--end

--function UIBattleSetStandingShoot_C:PreConstruct(IsDesignTime)
--end

function UIBattleSetStandingShoot_C:Construct()
    --- 用户设置的默认值
    self:SetUserConfigSettings()

    --------------------------------------------------------------------
    --- UI Event
    --------------------------------------------------------------------
    --- 开镜功能
    self.CheckBox_Aim.OnCheckStateChanged:Add(self, UIBattleSetStandingShoot_C.OnCheckStateChanged_Aim)
end

--function UIBattleSetStandingShoot_C:Tick(MyGeometry, InDeltaTime)
--end

-------------------------------------------------------------------------
--- Input Event
-------------------------------------------------------------------------
--- 开镜功能
function UIBattleSetStandingShoot_C:OnCheckStateChanged_Aim(bIsChecked)
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local StandingAimSetting = UserConfigSettings.StandingAimSetting
        if StandingAimSetting then
            UserConfigSettings:SetBool(StandingAimSetting.Section, StandingAimSetting.Key, bIsChecked)
        end
    end
end

-------------------------------------------------------------------------
--- 设置数据接口
-------------------------------------------------------------------------
--- 用户设置的默认值
function UIBattleSetStandingShoot_C:SetUserConfigSettings()
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        --- 开镜功能
        local StandingAimSetting = UserConfigSettings.StandingAimSetting
        if StandingAimSetting then
            local bIsChecked = UserConfigSettings:GetBool(StandingAimSetting.Section, StandingAimSetting.Key, StandingAimSetting.Value)
            self.CheckBox_Aim:SetIsChecked(bIsChecked and true or false)
        end

    end
end

return UIBattleSetStandingShoot_C
