require "UnLua"

local CharacterModule = require "Gameplay/Player/Module/CharacterModule"

local CharacterHitDmgCalc = class("CharacterHitDmgCalc", CharacterModule)

local CharacterBoneNameNum = 3;
local CharacterBoneNames = {"Head", "Body", "Limb"}

function CharacterHitDmgCalc:ctor()
    CharacterHitDmgCalc.super.ctor(self)
end

function CharacterHitDmgCalc:OnCreate(AC_Controller)
    CharacterHitDmgCalc.super.OnCreate(self, AC_Controller)
end

function CharacterHitDmgCalc:OnDestroy()
    CharacterHitDmgCalc.super.OnDestroy(self)
end

function CharacterHitDmgCalc:OnInit()
end

function CharacterHitDmgCalc:OnClear()
end

function CharacterHitDmgCalc:DoStartDamage(CharacterBase, Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser,
    DamageEvent_TypeID, DamageEvent_OutHitInfo, DamageEvent_OutImpulseDir)

    if AC_EventInstigator == nil then
        return 0;
    end

    local CurGameMode = UE4.UGameplayStatics.GetGameMode(CharacterBase);
    CurGameMode = CurGameMode:Cast(UE4.ABP_ShooterGameModeBase_C);

    local ActualDamage = Damage;
    
    --FPointDamageEvent::ClassID
    if (DamageEvent_TypeID == 1)  then
     
        for  i = 1,  CharacterBoneNameNum do
                
            --根据部位计算伤害	
			if DamageEvent_OutHitInfo.BoneName == CharacterBoneNames[i] then

				if i == tagCharacterBodyType.CHARACTERBODYTYPE_HEAD then
					local armorHead = CharacterBase:GetArmorHead() / MATH_SCALE_10K;
					ActualDamage = math.floor(ActualDamage * (1.0 - armorHead));
                    break;
                    
                elseif i == tagCharacterBodyType.CHARACTERBODYTYPE_NECK then
					local armorNeck = CharacterBase:GetArmorNeck() / MATH_SCALE_10K;
					ActualDamage = math.floor(ActualDamage * (1.0 - armorNeck));
                    break;

                elseif i == tagCharacterBodyType.CHARACTERBODYTYPE_TORSO then
					local armorTorso = CharacterBase:GetArmorTorso() / MATH_SCALE_10K;
					ActualDamage = math.floor(ActualDamage * (1.0 - armorTorso));
                    break;

                elseif i == tagCharacterBodyType.CHARACTERBODYTYPE_STOMACH then
					local armorStomach = CharacterBase:GetArmorStomach() / MATH_SCALE_10K;
					ActualDamage = math.floor(ActualDamage * (1.0 - armorStomach));
                    break;
                    
                elseif i == tagCharacterBodyType.CHARACTERBODYTYPE_LIMBS then		
					local armorLimbs = CharacterBase:GetArmorLimbs() / MATH_SCALE_10K;
					ActualDamage = math.floor(ActualDamage * (1.0 - armorLimbs));
					break;
                end
			end
        end
    end

    if CurGameMode and not CurGameMode:CanDealDamage(self.Controller, AC_EventInstigator) then
        ActualDamage = 0;
    end

	return ActualDamage;
end

function CharacterHitDmgCalc:DoEndDamage(CharacterBase, Damage, DamageEvent, AC_EventInstigator,AA_DamageCauser, DamageEvent_TypeID)
    local AttrMgr = CharacterBase:GetAttrMgr();

    local curHp = AttrMgr:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP);
    local curShield = AttrMgr:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD);
    
    local LastDamage = Damage;

	if curShield > 0 then
	
		LastDamage = LastDamage - curShield;
		LastDamage = UKismetMathLibrary.FClamp(LastDamage, 0, LastDamage);

		curShield = curShield - Damage;
		curShield = UKismetMathLibrary.FClamp(curShield, 0, curShield);

        AttrMgr:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD, curShield,
         Ds_ATTRADDTYPE.ATTRADD_BASE);
    end

	curHp = curHp - LastDamage;
    curHp = UKismetMathLibrary.FClamp(curHp, 0, curHp);
    
	AttrMgr:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP, curHp, Ds_ATTRADDTYPE.ATTRADD_BASE);

	local DamageCauserCharacter = nil;
    if AA_DamageCauser then
		if AA_DamageCauser:IsA(UE4.ABP_ShooterCharacterBase_C) then
            DamageCauserCharacter = AA_DamageCauser:Cast(ABP_ShooterCharacterBase_C)
        else
            local Instigator = AA_DamageCauser:GetInstigator()
            if Instigator then
                DamageCauserCharacter = Instigator:Cast(ABP_ShooterCharacterBase_C)
            end
        end
    end

	if DamageCauserCharacter then
		DamageCauserCharacter:OnAttackDamage_S(Damage, DamageEvent, AA_DamageCauser);
    end

	if (curHp <= 0) then
        local characterDownTimes = CharacterBase:GetCharacterDownTotalTimes()

        if DamageEvent_TypeID == 1001 then
            -- 处决死亡
            CharacterBase:OnDie_S(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser , DamageEvent_TypeID);
            return
        end

        --- 倒地 死亡
        if characterDownTimes > 0 then
            if CharacterBase:GetCharacterStatus() == ECharacterStatus.ECharacterStatus_ALIVE then

                local maxHp = AttrMgr:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP);
                local downHp = AttrMgr:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_DOWN_HP);
                downHp = math.min(downHp , maxHp)
                AttrMgr:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP, downHp, Ds_ATTRADDTYPE.ATTRADD_BASE);

                CharacterBase:OnDown_S(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser,DamageEvent_TypeID);
            elseif CharacterBase:GetCharacterStatus() == ECharacterStatus.ECharacterStatus_DOWN then
                CharacterBase:OnDie_S(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser , DamageEvent_TypeID,DamageEvent_TypeID);
            end
        else
            CharacterBase:OnDie_S(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser , DamageEvent_TypeID);
        end

	else
		CharacterBase:OnBeHit_S(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser,DamageEvent_TypeID);
    end

end

return CharacterHitDmgCalc