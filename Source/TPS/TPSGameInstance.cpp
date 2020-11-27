// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSGameInstance.h"
#include "TPSInventorySaveGame.h"
#include "TPSAssetManager.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Engine/StreamableManager.h"

void UTPSGameInstance::Init()
{
	Super::Init();

	InitializeStoreItems();
}

void UTPSGameInstance::InitializeStoreItems()
{
	for (const TPair<FPrimaryAssetType, int32>& Pair : ItemSlotsPerType)
	{
		TArray<FPrimaryAssetId> OutPrimaryAssetIdList;
		//UKismetSystemLibrary::GetPrimaryAssetIdList(Pair.Key, OutPrimaryAssetIdList);
		if (UAssetManager* Manager = UAssetManager::GetIfValid())
		{
			if (Manager->GetPrimaryAssetIdList(Pair.Key, OutPrimaryAssetIdList))
			{
				TArray<FName> LoadBundles;
				TSharedPtr<FStreamableHandle> LoadHandle = Manager->LoadPrimaryAssets(OutPrimaryAssetIdList, LoadBundles);
				if (LoadHandle.IsValid())
				{
					if (LoadHandle->HasLoadCompleted())
					{
						HandleLoadCompleted();
					}
					else
					{
						LoadHandle->BindCompleteDelegate(FStreamableDelegate::CreateUObject(this, &UTPSGameInstance::HandleLoadCompleted));
					}
				}
			}
		}
	}
}

void UTPSGameInstance::HandleLoadCompleted()
{

}

void UTPSGameInstance::AddDefaultInventory(UTPSInventorySaveGame* SaveGame, bool bRemoveExtra)
{
	// If we want to remove extra, clear out the existing inventory
	if (bRemoveExtra)
	{
		SaveGame->InventoryData.Reset();
	}

	// Now add the default inventory, this only adds if not already in hte inventory
	for (const TPair<FPrimaryAssetId, FTPSItemData>& Pair : DefaultInventory)
	{
		if (!SaveGame->InventoryData.Contains(Pair.Key))
		{
			SaveGame->InventoryData.Add(Pair.Key, Pair.Value);
		}
	}
}

bool UTPSGameInstance::IsValidItemSlot(FTPSItemSlot ItemSlot) const
{
	if (ItemSlot.IsValid())
	{
		const int32* FoundCount = ItemSlotsPerType.Find(ItemSlot.ItemType);

		if (FoundCount)
		{
			return ItemSlot.SlotNumber < *FoundCount;
		}
	}
	return false;
}

UTPSInventorySaveGame* UTPSGameInstance::GetInventorySaveGame()
{
	return InventorySaveGame;
}

void UTPSGameInstance::SetSavingEnabled(bool bEnabled)
{
	bSavingEnabled = bEnabled;
}

bool UTPSGameInstance::LoadOrCreateSaveGame()
{
	UTPSInventorySaveGame* LoadedSave = nullptr;

	if (UGameplayStatics::DoesSaveGameExist(SaveSlot, SaveUserIndex) && bSavingEnabled)
	{
		LoadedSave = Cast<UTPSInventorySaveGame>(UGameplayStatics::LoadGameFromSlot(SaveSlot, SaveUserIndex));
	}

	return HandleSaveGameLoaded(LoadedSave);
}

bool UTPSGameInstance::HandleSaveGameLoaded(USaveGame* SaveGameObject)
{
	bool bLoaded = false;

	if (!bSavingEnabled)
	{
		// If saving is disabled, ignore passed in object
		SaveGameObject = nullptr;
	}

	// Replace current save, old object will GC out
	InventorySaveGame = Cast<UTPSInventorySaveGame>(SaveGameObject);
	if (InventorySaveGame)
	{
		// Make sure it has any newly added default inventory
		AddDefaultInventory(InventorySaveGame, false);
		bLoaded = true;
	}
	else
	{
		// This creates it on demand
		InventorySaveGame = Cast<UTPSInventorySaveGame>(UGameplayStatics::CreateSaveGameObject(UTPSInventorySaveGame::StaticClass()));
		AddDefaultInventory(InventorySaveGame, true);
	}

	OnSaveGameLoaded.Broadcast(InventorySaveGame);
	OnSaveGameLoadedNative.Broadcast(InventorySaveGame);

	return bLoaded;
}

void UTPSGameInstance::GetSaveSlotInfo(FString& SlotName, int32& UserIndex) const
{
	SlotName = SaveSlot;
	UserIndex = SaveUserIndex;
}

bool UTPSGameInstance::WriteSaveGame()
{
	if (bSavingEnabled)
	{
		if (bCurrentlySaving)
		{
			// Schedule another save to happen after current one finishes. We only queue one save
			bPendingSaveRequested = true;
			return true;
		}

		// Indicate that we're currently doing an async save
		bCurrentlySaving = true;

		// This goes off in the background
		UGameplayStatics::AsyncSaveGameToSlot(GetInventorySaveGame(), SaveSlot, SaveUserIndex,
			FAsyncSaveGameToSlotDelegate::CreateUObject(this, &UTPSGameInstance::HandleAsyncSave));
		return true;
	}
	return false;
}

void UTPSGameInstance::HandleAsyncSave(const FString& SlotName, const int32 UserIndex, bool bSuccess)
{
	ensure(bCurrentlySaving);
	bCurrentlySaving = false;

	if (bPendingSaveRequested)
	{
		// Start another save as we got a request while saving
		bPendingSaveRequested = false;
		WriteSaveGame();
	}
}

void UTPSGameInstance::ResetSaveGame()
{
	// Call handle function with no loaded save, this will reset the data
	HandleSaveGameLoaded(nullptr);
}