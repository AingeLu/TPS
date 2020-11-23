// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Inventory/Items/TPSItem.h"
#include "TPSItem_Weapon.generated.h"

/**
 * Native base class for weapons, should be blueprinted 
 */
UCLASS()
class TPS_API UTPSItem_Weapon : public UTPSItem
{
	GENERATED_BODY()
	
public:
	/** Constructor */
	UTPSItem_Weapon()
	{
		ItemType = UTPSAssetManager::WeaponItemType;
	}

	/** Weapon actor to spawn */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = Weapon)
	TSubclassOf<AActor> WeaponActor;
};
