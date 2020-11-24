// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "TPSItem.h"
#include "TPSItem_Potion.generated.h"

/**
 * Native base class for potions, should be blueprinted 
 */
UCLASS()
class TPS_API UTPSItem_Potion : public UTPSItem
{
	GENERATED_BODY()
	
public:
	/** Constructor */
	UTPSItem_Potion()
	{
		ItemType = UTPSAssetManager::PotionItemType;
	}
};
