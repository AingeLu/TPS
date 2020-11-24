// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSSaveGame.h"

void UTPSSaveGame::Serialize(FArchive& Ar)
{
	Super::Serialize(Ar);

	if (Ar.IsLoading() && SavedDataVersion != ETPSSaveGameVersion::LatestVersion)
	{
		if (SavedDataVersion < ETPSSaveGameVersion::AddedItemData)
		{
			// Convert from list to item data map
			for (const FPrimaryAssetId& ItemId : InventoryItems_DEPRECATED)
			{
				InventoryData.Add(ItemId, FTPSItemData(1, 1));
			}

			InventoryItems_DEPRECATED.Empty();
		}

		SavedDataVersion = ETPSSaveGameVersion::LatestVersion;
	}
}