// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSAssetManager.h"
#include "AbilitySystemGlobals.h"

const FPrimaryAssetType	UTPSAssetManager::PotionItemType = TEXT("Potion");
const FPrimaryAssetType	UTPSAssetManager::SkillItemType = TEXT("Skill");
const FPrimaryAssetType	UTPSAssetManager::TokenItemType = TEXT("Token");
const FPrimaryAssetType	UTPSAssetManager::WeaponItemType = TEXT("Weapon");

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


//URPGItem* UTPSAssetManager::ForceLoadItem(const FPrimaryAssetId& PrimaryAssetId, bool bLogWarning)
//{
//	FSoftObjectPath ItemPath = GetPrimaryAssetPath(PrimaryAssetId);
//
//	// This does a synchronous load and may hitch
//	URPGItem* LoadedItem = Cast<URPGItem>(ItemPath.TryLoad());
//
//	if (bLogWarning && LoadedItem == nullptr)
//	{
//		UE_LOG(LogActionRPG, Warning, TEXT("Failed to load item for identifier %s!"), *PrimaryAssetId.ToString());
//	}
//
//	return LoadedItem;
//}