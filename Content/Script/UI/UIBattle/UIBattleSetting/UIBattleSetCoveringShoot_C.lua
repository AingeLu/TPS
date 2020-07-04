--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local UIBattleSetCoveringShoot_C = Class()

--function UIBattleSetCoveringShoot_C:Initialize(Initializer)
--end

--function UIBattleSetCoveringShoot_C:PreConstruct(IsDesignTime)
--end

function UIBattleSetCoveringShoot_C:Construct()
    --- 用户设置的默认值
    self:SetUserConfigSettings()

    ----------------------------------------------------------------------
    ----- UI Event
    ----------------------------------------------------------------------
    --- 腰射功能
    self.CheckBox_WaistShoot.OnCheckStateChanged:Add(self, UIBattleSetCoveringShoot_C.OnCheckStateChanged_WaistShoot)
    --- 腰射移动
    self.CheckBox_WaistShootMove.OnCheckStateChanged:Add(self, UIBattleSetCoveringShoot_C.OnCheckStateChanged_WaistShootMove)
    --- 开镜移动
    self.CheckBox_AimMove.OnCheckStateChanged:Add(self, UIBattleSetCoveringShoot_C.OnCheckStateChanged_AimMove)
    --- 相机转动范围(全屏)
    self.CheckBox_FullScreenRotation.OnCheckStateChanged:Add(self, UIBattleSetCoveringShoot_C.OnCheckStateChanged_FullScreenRotation)

end

--function UIBattleSetCoveringShoot_C:Tick(MyGeometry, InDeltaTime)
--end

-------------------------------------------------------------------------
--- Input Event
-------------------------------------------------------------------------
--- 腰射功能
function UIBattleSetCoveringShoot_C:OnCheckStateChanged_WaistShoot(bIsChecked)
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local CoveringWaistShootSetting = UserConfigSettings.CoveringWaistShootSetting
        if CoveringWaistShootSetting then
            UserConfigSettings:SetBool(CoveringWaistShootSetting.Section, CoveringWaistShootSetting.Key, bIsChecked)
        end
    end
end

--- 腰射移动
function UIBattleSetCoveringShoot_C:OnCheckStateChanged_WaistShootMove(bIsChecked)
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local CoveringWaistShootMoveSetting = UserConfigSettings.CoveringWaistShootMoveSetting
        if CoveringWaistShootMoveSetting then
            UserConfigSettings:SetBool(CoveringWaistShootMoveSetting.Section, CoveringWaistShootMoveSetting.Key, bIsChecked)
        end
    end
end

--- 开镜移动
function UIBattleSetCoveringShoot_C:OnCheckStateChanged_AimMove(bIsChecked)
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local CoveringAimMoveSetting = UserConfigSettings.CoveringAimMoveSetting
        if CoveringAimMoveSetting then
            UserConfigSettings:SetBool(CoveringAimMoveSetting.Section, CoveringAimMoveSetting.Key, bIsChecked)
        end
    end
end

--- 相机转动范围(全屏)
function UIBattleSetCoveringShoot_C:OnCheckStateChanged_FullScreenRotation(bIsChecked)
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        local CoveringFullScreenRotationSetting = UserConfigSettings.CoveringFullScreenRotationSetting
        if CoveringFullScreenRotationSetting then
            UserConfigSettings:SetBool(CoveringFullScreenRotationSetting.Section, CoveringFullScreenRotationSetting.Key, bIsChecked)
        end
    end
end


-------------------------------------------------------------------------
--- 设置数据接口
-------------------------------------------------------------------------
--- 用户设置的默认值
function UIBattleSetCoveringShoot_C:SetUserConfigSettings()
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()
    if UserConfigSettings then
        --- 腰射功能
        local CoveringWaistShootSetting = UserConfigSettings.CoveringWaistShootSetting
        if CoveringWaistShootSetting then
            local bIsChecked = UserConfigSettings:GetBool(CoveringWaistShootSetting.Section, CoveringWaistShootSetting.Key, CoveringWaistShootSetting.Value)
            self.CheckBox_WaistShoot:SetIsChecked(bIsChecked and true or false)
        end

        --- 腰射移动
        local CoveringWaistShootMoveSetting = UserConfigSettings.CoveringWaistShootMoveSetting
        if CoveringWaistShootMoveSetting then
            local bIsChecked = UserConfigSettings:GetBool(CoveringWaistShootMoveSetting.Section, CoveringWaistShootMoveSetting.Key, CoveringWaistShootMoveSetting.Value)
            self.CheckBox_WaistShootMove:SetIsChecked(bIsChecked and true or false)
        end

        --- 开镜移动
        local CoveringAimMoveSetting = UserConfigSettings.CoveringAimMoveSetting
        if CoveringAimMoveSetting then
            local bIsChecked = UserConfigSettings:GetBool(CoveringAimMoveSetting.Section, CoveringAimMoveSetting.Key, CoveringAimMoveSetting.Value)
            self.CheckBox_AimMove:SetIsChecked(bIsChecked and true or false)
        end

        --- 相机转动范围(全屏)
        local CoveringFullScreenRotationSetting = UserConfigSettings.CoveringFullScreenRotationSetting
        if CoveringFullScreenRotationSetting then
            local bIsChecked = UserConfigSettings:GetBool(CoveringFullScreenRotationSetting.Section, CoveringFullScreenRotationSetting.Key, CoveringFullScreenRotationSetting.Value)
            self.CheckBox_FullScreenRotation:SetIsChecked(bIsChecked and true or false)
        end
    end
end

return UIBattleSetCoveringShoot_C
