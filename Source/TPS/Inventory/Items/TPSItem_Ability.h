// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Inventory/Items/TPSItem.h"
#include "TPSItem_Ability.generated.h"

/**
 * Native base class for abilities, should be blueprinted 
 */
UCLASS()
class TPS_API UTPSItem_Ability : public UTPSItem
{
	GENERATED_BODY()

public:
	/** Constructor */
	UTPSItem_Ability()
	{
		ItemType = UTPSAssetManager::AbilityItemType;
	}
};
