require "UnLua"

---战斗界面 底部中间面板 UI
---@type UIBattleBottomMid_C
local UIBattleBottomMid_C = class("UIBattleBottomMid_C")

function UIBattleBottomMid_C:OnInitialized(ownerWidget)

    self.ownerWidget = ownerWidget

    --------------------------------------
    --- 数据
    --------------------------------------
    --- 装备武器相关数据
    self.MaxWeaponEquipSlot = 2
    self.CurrUseWeaponGunEquipBar = -1



end

function UIBattleBottomMid_C:PreConstruct(IsDesignTime)

end

function UIBattleBottomMid_C:Construct()

    --------------------------------------
    --- 控件
    --------------------------------------
    ----- 武器装备 UI 控件
    self.WeaponEquipTb = {}
    for i = 1, self.MaxWeaponEquipSlot do
        self.WeaponEquipTb[i] = {}
        self.WeaponEquipTb[i].Weapon_BK_ImageExt = self.ownerWidget:GetWidgetFromName("Weapon"..i.."_BK_ImageExt")
        self.WeaponEquipTb[i].WeaponHalo_Image = self.ownerWidget:GetWidgetFromName("Weapon"..i.."_Halo_Image")
        self.WeaponEquipTb[i].WeaponAmmoEquipTyp_CanvasPanel = self.ownerWidget:GetWidgetFromName("Weapon"..i.."AmmoEquipTyp_CanvasPanel")
        self.WeaponEquipTb[i].WeaponAmmoUnEquipTyp_CanvasPanel = self.ownerWidget:GetWidgetFromName("Weapon"..i.."AmmoUnEquipTyp_CanvasPanel")
        self.WeaponEquipTb[i].WeaponIcon_Image = self.ownerWidget:GetWidgetFromName("Weapon"..i.."_Icon_Image")
        self.WeaponEquipTb[i].WeaponIconGlow_Image = self.ownerWidget:GetWidgetFromName("Weapon"..i.."_IconGlow_Image")
        self.WeaponEquipTb[i].WeaponEquipAmmoInClip_Text = self.ownerWidget:GetWidgetFromName("Weapon"..i.."EquipAmmoInClip_Text")
        self.WeaponEquipTb[i].WeaponEquipAllAmmo_Text = self.ownerWidget:GetWidgetFromName("Weapon"..i.."EquipAllAmmo_Text")
        self.WeaponEquipTb[i].WeaponUnEquipAmmoInClip_Text = self.ownerWidget:GetWidgetFromName("Weapon"..i.."UnEquipAmmoInClip_Text")
        self.WeaponEquipTb[i].WeaponUnEquipAllAmmo_Text = self.ownerWidget:GetWidgetFromName("Weapon"..i.."UnEquipAllAmmo_Text")

        self.WeaponEquipTb[i].Weapon_BK_ImageExt.OnClicked:Add(self.ownerWidget, function(ownerWidget)
            self:OnClicked_WeaponBk(i)
        end)
    end


    self.ownerWidget.Rescue_Button:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.ownerWidget.Rescue_Button.OnClicked:Add(self.ownerWidget, function(ownerWidget)
        self:OnClicked_Rescue()
    end)

    self:OnInitRescueCircularProgressBar()

    self:RescueUIVisible(false)
end

--- 救援进度条设置
function UIBattleBottomMid_C:OnInitRescueCircularProgressBar()
    self.Rescue_CircularProgress_Mat = UE4.UMGLuaUtils.UMG_GetMaterial("Material'/Game/UI/UIBattle/CircleProgressBar/M_ProgressCircle_3.M_ProgressCircle_3'" , self.ownerWidget);
    if self.Rescue_CircularProgress_Mat then
        if self.ownerWidget.Rescue_CircularProgressBarTexture then
            self.Rescue_CircularProgress_Mat:SetTextureParameterValue("Circular_Tex" , self.ownerWidget.Rescue_CircularProgressBarTexture.ParameterValue)
        end

        self.Rescue_CircularProgress_Mat:SetScalarParameterValue("Alpha" , 100)
        self.Rescue_CircularProgress_Mat:SetVectorParameterValue("Color" , UE4.FLinearColor(1,1,1,1))
        UE4.UMGLuaUtils.UMG_SlateBrush_SetResource(self.ownerWidget.Rescue_ProgressBar , self.Rescue_CircularProgress_Mat)
    end
end

--- 设置救援进度条进度
function UIBattleBottomMid_C:SetRescueCircularProgressBarPercent(percent)
    self.Rescue_CircularProgress_Mat:SetScalarParameterValue("Alpha" , percent)
    UE4.UMGLuaUtils.UMG_SlateBrush_SetResource(self.ownerWidget.Rescue_ProgressBar , self.Rescue_CircularProgress_Mat)
end

function UIBattleBottomMid_C:OnClicked_Rescue()
    print("OnClicked_Rescue ... ...")
    local character = self.ownerWidget:GetCharacterBase()
    if character and character:IsValid() then
        if character:IsAlive() then
            local rescueTeammate = character:GetCheckBeRescuer()
            --local isResurgeTeammate = ownCharacter:IsResurgeTeammate()
            if rescueTeammate then
                character:ResurgeTeammate_Pressed()
            end
        end
    end
end

function UIBattleBottomMid_C:OnShowWindow()

    self:OnRefreshWeaponEquipBar()
    self:OnRefreshHp()
end

function UIBattleBottomMid_C:OnHideWindow()

end

function UIBattleBottomMid_C:Destruct()
    self.WeaponEquipTb = nil
end

function UIBattleBottomMid_C:Tick(MyGeometry, InDeltaTime)
    self:OnRefreshHp()

    local character = self.ownerWidget:GetCharacterBase()
    if character and character:IsValid() then
        self:UpdateRescueUI(character)
    end
end

function UIBattleBottomMid_C:TickPerSec(MyGeometry, InDeltaTime)

end

function UIBattleBottomMid_C:UpdateRescueUI(ownCharacter)
    if ownCharacter:IsAlive() then
        local rescueTeammate = ownCharacter:GetCheckBeRescuer()
        if not rescueTeammate then
            self:RescueUIVisible(false)
            return
        end

        --local isResurgeTeammate = ownCharacter:IsResurgeTeammate()
        if rescueTeammate:IsValid() and not rescueTeammate:IsDying() then

            local percent = rescueTeammate:GetResurgenceProcessTime() / rescueTeammate:GetResurgenceTime()
            self:SetRescueCircularProgressBarPercent(percent)

            self:RescueUIVisible(true)
        else
            self:RescueUIVisible(false)
        end
    elseif ownCharacter:IsInResurgence() then
        self:RescueUIVisible(true)

        local percent = ownCharacter:GetResurgenceProcessTime() / ownCharacter:GetResurgenceTime()
        self:SetRescueCircularProgressBarPercent(percent)
    else
        self:RescueUIVisible(false)
    end
end

function UIBattleBottomMid_C:RescueUIVisible(visible)
    if visible then
        self.ownerWidget.Rescue_Button:SetVisibility(UE4.ESlateVisibility.Visible)
        self.ownerWidget.Rescue_ProgressBar:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
        self.ownerWidget.Rescue_Button:SetVisibility(UE4.ESlateVisibility.Hidden)
        self.ownerWidget.Rescue_ProgressBar:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
end

---------------------------------------------
--- UI Mgs
---------------------------------------------

---- 角色装备改变
function UIBattleBottomMid_C:OnCharacterEquipNotify()
    self:OnRefreshWeaponEquipBar()
end


---------------------------------------------
--- UI Event
---------------------------------------------
---@param weaponEquipIndex 武器槽位 【对应 EQUIPBARTYPE_NONE , EQUIPBARTYPE_WEAPON1 , EQUIPBARTYPE_WEAPON2】
function UIBattleBottomMid_C:OnClicked_WeaponBk(weaponEquipIndex)

    if Ds_EquipBarType.EQUIPBARTYPE_WEAPON1 ~= weaponEquipIndex and
            Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 ~= weaponEquipIndex and
            Ds_EquipBarType.EQUIPBARTYPE_NONE ~= weaponEquipIndex then
        return
    end

    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase and characterBase:IsValid() then
        characterBase:ServerChangeCurEquipBarType(weaponEquipIndex, false)
    end
end

---------------------------------------------
--- 辅助函数
---------------------------------------------

--- 更新武器装备栏
function UIBattleBottomMid_C:OnRefreshWeaponEquipBar()

    --- 更新装备武器
    local currEquipType = self:GetShootWeaponEquipBarType()
    self:SetCurrUseWeaponIndex(currEquipType)

    --- 更新子弹
    self:OnRefreshSingleWeaponAmmoUI(self.CurrUseWeaponGunEquipBar == Ds_EquipBarType.EQUIPBARTYPE_WEAPON1 , Ds_EquipBarType.EQUIPBARTYPE_WEAPON1)
    self:OnRefreshSingleWeaponAmmoUI(self.CurrUseWeaponGunEquipBar == Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 , Ds_EquipBarType.EQUIPBARTYPE_WEAPON2)
end

--- 刷新血条
function UIBattleBottomMid_C:OnRefreshHp()
    local currHp , maxHp = self:GetCharacterHpAndMaxHp()
    --print("OnRefreshHp currHp:" , currHp , maxHp)
    self:OnRefreshHpBarUI(currHp , maxHp)
end

--- 刷新装备武器位置的全部 UI
--- @param CurrUseWeaponIndex 武器槽位 【对应 EQUIPBARTYPE_NONE , EQUIPBARTYPE_WEAPON1 , EQUIPBARTYPE_WEAPON2】
function UIBattleBottomMid_C:OnRefreshWeaponEquipUI(CurrUseWeaponIndex)

    local weaponEquipNum = self:GetShootWeaponCtn()
    local currEquipWeaponIndex = CurrUseWeaponIndex

    local slotIndex = 1
    for i = 1, self.MaxWeaponEquipSlot do
        slotIndex = i
        if i <= weaponEquipNum then
            --- TODO: Weapon Equip
            self:OnRefreshSingleWeaponEquipSlotUI(true , currEquipWeaponIndex == i , slotIndex)

        else
            --- TODO: Weapon UnEquip
            self:OnRefreshSingleWeaponEquipSlotUI(false , false ,  slotIndex)
        end
    end
end

--- 刷新单个武器装备位置的 UI
--- @param bHasWeapon 是否拥有武器
--- @param bEquip 是否装备中
--- @param slotIndex 武器槽位 【对应 EQUIPBARTYPE_NONE , EQUIPBARTYPE_WEAPON1 , EQUIPBARTYPE_WEAPON2】
function UIBattleBottomMid_C:OnRefreshSingleWeaponEquipSlotUI(bHasWeapon , bEquip , slotIndex)

    if slotIndex <= 0 or slotIndex > self.MaxWeaponEquipSlot then
        print("UIBattleBottomMid_C:OnRefreshSingleWeaponEquipSlotUI slotIndex out of index .")
        return
    end

    if bEquip then
        self.WeaponEquipTb[slotIndex].Weapon_BK_ImageExt:SetOpacity(0)

        self.WeaponEquipTb[slotIndex].WeaponHalo_Image:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.WeaponEquipTb[slotIndex].WeaponAmmoEquipTyp_CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.WeaponEquipTb[slotIndex].WeaponAmmoUnEquipTyp_CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)

        self.WeaponEquipTb[slotIndex].WeaponIconGlow_Image:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
        self.WeaponEquipTb[slotIndex].Weapon_BK_ImageExt:SetOpacity(1)

        self.WeaponEquipTb[slotIndex].WeaponHalo_Image:SetVisibility(UE4.ESlateVisibility.Hidden)
        self.WeaponEquipTb[slotIndex].WeaponAmmoEquipTyp_CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
        self.WeaponEquipTb[slotIndex].WeaponAmmoUnEquipTyp_CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)

        self.WeaponEquipTb[slotIndex].WeaponIconGlow_Image:SetVisibility(UE4.ESlateVisibility.Hidden)
    end

    self:OnRefreshSingleWeaponAmmoUI(bEquip , slotIndex)
end

--- 刷新单个武器子弹 UI
--- @param bEquip 是否装备中
--- @param slotIndex 武器槽位 【对应 EQUIPBARTYPE_NONE , EQUIPBARTYPE_WEAPON1 , EQUIPBARTYPE_WEAPON2】
function UIBattleBottomMid_C:OnRefreshSingleWeaponAmmoUI(bEquip , slotIndex)

    if slotIndex <= 0 or slotIndex > self.MaxWeaponEquipSlot then
        print("UIBattleBottomMid_C:OnRefreshSingleWeaponEquipSlotUI slotIndex out of index .")
        return
    end

    local ammoInClip , allAmmo = self:GetWeaponAmmoNum(slotIndex)

    if bEquip then
        self.WeaponEquipTb[slotIndex].WeaponEquipAmmoInClip_Text:SetText(ammoInClip)
        self.WeaponEquipTb[slotIndex].WeaponEquipAllAmmo_Text:SetText(allAmmo)
    else
        self.WeaponEquipTb[slotIndex].WeaponUnEquipAmmoInClip_Text:SetText(ammoInClip)
        self.WeaponEquipTb[slotIndex].WeaponUnEquipAllAmmo_Text:SetText(allAmmo)
    end
end

--- 刷新血量数据
function UIBattleBottomMid_C:OnRefreshHpBarUI(currHp , maxHp)

    if self.ownerWidget == nil then
        return
    end

    local currHpPercent = 0
    if maxHp > 0 then
        currHpPercent = currHp / maxHp
    else
        currHpPercent = 0
    end

    local coDelaySetHitHpBar = coroutine.create(UIBattleBottomMid_C.DelaySetHitHpBar)
    coroutine.resume(coDelaySetHitHpBar, self.ownerWidget, currHpPercent)

    self.ownerWidget.PlayerNormalHp_ProgressBar:SetPercent(currHpPercent)

end

function UIBattleBottomMid_C:DelaySetHitHpBar(hp_percent)
    UE4.UKismetSystemLibrary.Delay(self, 0.5)

    self.PlayerHitHp_ProgressBar:SetPercent(hp_percent)
end

---------------------------------------------
--- Getter 数据接口
---------------------------------------------
function UIBattleBottomMid_C:GetOwnerWidget()
    return self.ownerWidget
end

function UIBattleBottomMid_C:GetCurrUseWeaponIndex()
    return self.CurrUseWeaponGunEquipBar
end

--- 获取当前装备的枪类型
function UIBattleBottomMid_C:GetShootWeaponEquipBarType()
    if self.ownerWidget == nil then
        return Ds_EquipBarType.EQUIPBARTYPE_NONE
    end

    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase == nil then
        return Ds_EquipBarType.EQUIPBARTYPE_NONE
    end

    if characterBase.EquipComponent == nil then
        return Ds_EquipBarType.EQUIPBARTYPE_NONE
    end


    local equipBarType = characterBase.EquipComponent:GetCurEquipBarType()
    if equipBarType >= Ds_EquipBarType.EQUIPBARTYPE_NONE and
        equipBarType <= Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 then
        return equipBarType
    end

    return Ds_EquipBarType.EQUIPBARTYPE_NONE
end

--- 获取枪子弹的数量
--- @param EquipBarType
--- @return AmmoInClip , AllAmmo
function UIBattleBottomMid_C:GetWeaponAmmoNum(EquipBarType)

    if EquipBarType <= Ds_EquipBarType.EQUIPBARTYPE_NONE or EquipBarType > Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 then
        return 0,0
    end

    if self.ownerWidget == nil then
        return 0,0
    end

    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase == nil then
        return 0,0
    end

    if characterBase.EquipComponent == nil then
        return 0,0
    end

    local weaponGun = characterBase.EquipComponent:GetWeaponByBarType(EquipBarType)
    if weaponGun == nil then
        return 0,0
    end

    local currentAmmoInClip , currentAmmo = 0 , 0
    if isLuaFunc(weaponGun.GetCurrentAmmoInClip) then
        currentAmmoInClip = weaponGun:GetCurrentAmmoInClip()
    end

    if isLuaFunc(weaponGun.GetCurrentAmmo) then
        currentAmmo = weaponGun:GetCurrentAmmo()
    end

    return currentAmmoInClip , currentAmmo
end

--- 获取枪装备的数量
function UIBattleBottomMid_C:GetShootWeaponCtn()
    if self.ownerWidget == nil then
        return 0
    end

    local characterBase = self.ownerWidget:GetCharacterBase()
    if characterBase == nil then
        return 0
    end

    if characterBase.EquipComponent == nil then
        return 0
    end

    local weaponEquipCtn = characterBase.EquipComponent:GetCurEquipWeaponCtn()

    return weaponEquipCtn
end

--- 获取角色血量
--- @return currHp , maxHp
function UIBattleBottomMid_C:GetCharacterHpAndMaxHp()
    local character = self.ownerWidget:GetCharacterBase()
    if character == nil then
        --print("UIBattleBottomMid_C GetCharacterHp Character is nil .")
        return 0 , 0
    end

    return character:GetHp() , character:GetMaxHp()
end


---------------------------------------------
--- Setter 数据接口
---------------------------------------------

--- 设置当前使用枪类型
--- @param index [Ds_EquipBarType Only : EQUIPBARTYPE_NONE ,EQUIPBARTYPE_WEAPON1, EQUIPBARTYPE_WEAPON2]
function UIBattleBottomMid_C:SetCurrUseWeaponIndex(weaponEquipBarType)

    if weaponEquipBarType < 0 or weaponEquipBarType > self.MaxWeaponEquipSlot then
        print("Error : UIBattleBottomMid_C:SetCurrUseWeaponIndex Failed . index = " , weaponEquipBarType)
        return
    end

    self.CurrUseWeaponGunEquipBar = weaponEquipBarType

    self:OnRefreshWeaponEquipUI(self.CurrUseWeaponGunEquipBar)
end


return UIBattleBottomMid_C