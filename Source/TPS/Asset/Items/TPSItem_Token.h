// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Asset/Items/TPSItem.h"
#include "TPSItem_Token.generated.h"

/**
 * Native base class for tokens, should be blueprinted 
 */
UCLASS()
class TPS_API UTPSItem_Token : public UTPSItem
{
	GENERATED_BODY()
	
public:
	/** Constructor */
	UTPSItem_Token()
	{
		ItemType = UTPSAssetManager::TokenItemType;
		MaxCount = 0; // Infinite
	}
};
