// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSAssetManager.h"
#include "AbilitySystemGlobals.h"
#include "TPSItem.h"


const FPrimaryAssetType	UTPSAssetManager::AbilityItemType = TEXT("Ability");
const FPrimaryAssetType	UTPSAssetManager::WeaponItemType = TEXT("Weapon");
const FPrimaryAssetType	UTPSAssetManager::PotionItemType = TEXT("Potion");
const FPrimaryAssetType	UTPSAssetManager::TokenItemType = TEXT("Token");


UTPSAssetManager& UTPSAssetManager::Get()
{
	UTPSAssetManager* This = Cast<UTPSAssetManager>(GEngine->AssetManager);

	if (This)
	{
		return *This;
	}
	else
	{
		//UE_LOG(LogActionRPG, Fatal, TEXT("Invalid AssetManager in DefaultEngine.ini, must be TPSAssetManager!"));
		return *NewObject<UTPSAssetManager>(); // never calls this
	}
}

void UTPSAssetManager::StartInitialLoading()
{
	Super::StartInitialLoading();

	UAbilitySystemGlobals::Get().InitGlobalData();
}

UTPSItem* UTPSAssetManager::ForceLoadItem(const FPrimaryAssetId& PrimaryAssetId, bool bLogWarning)
{
	FSoftObjectPath ItemPath = GetPrimaryAssetPath(PrimaryAssetId);

	// This does a synchronous load and may hitch
	UTPSItem* LoadedItem = Cast<UTPSItem>(ItemPath.TryLoad());

	if (bLogWarning && LoadedItem == nullptr)
	{
		//UE_LOG(LogActionRPG, Warning, TEXT("Failed to load item for identifier %s!"), *PrimaryAssetId.ToString());
	}

	return LoadedItem;
}