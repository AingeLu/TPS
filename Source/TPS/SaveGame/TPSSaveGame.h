// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "TPSInventoryTypes.h"
#include "TPSSaveGame.generated.h"

/** List of versions, native code will handle fixups for any old versions */
namespace ETPSSaveGameVersion
{
	enum type
	{
		// Initial version
		Initial,
		// Added Inventory
		AddedInventory,
		// Added ItemData to store count/level
		AddedItemData,

		// -----<new versions must be added before this line>-------------------------------------------------
		VersionPlusOne,
		LatestVersion = VersionPlusOne - 1
	};
}

/**
 * Object that is written to and read from the save game archive, with a data version
 */
UCLASS(BlueprintType)
class TPS_API UTPSSaveGame : public USaveGame
{
	GENERATED_BODY()
	
public:
	/** Constructor */
	UTPSSaveGame()
	{
		// Set to current version, this will get overwritten during serialization when loading
		SavedDataVersion = ETPSSaveGameVersion::LatestVersion;
	}

	/** Map of items to item data */
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = SaveGame)
	TMap<FPrimaryAssetId, FTPSItemData> InventoryData;

	/** Map of slotted items */
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = SaveGame)
	TMap<FTPSItemSlot, FPrimaryAssetId> SlottedItems;

	/** User's unique id */
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = SaveGame)
	FString UserId;

protected:
	/** Deprecated way of storing items, this is read in but not saved out */
	UPROPERTY()
	TArray<FPrimaryAssetId> InventoryItems_DEPRECATED;

	/** What LatestVersion was when the archive was saved */
	UPROPERTY()
	int32 SavedDataVersion;

	/** Overridden to allow version fixups */
	virtual void Serialize(FArchive& Ar) override;
};
