// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSInventorySaveGame.h"

void UTPSInventorySaveGame::Serialize(FArchive& Ar)
{
	Super::Serialize(Ar);

	if (Ar.IsLoading() && SavedDataVersion != ETPSInventorySaveGameVersion::LatestVersion)
	{
		if (SavedDataVersion < ETPSInventorySaveGameVersion::AddedItemData)
		{
			// Convert from list to item data map
			for (const FPrimaryAssetId& ItemId : InventoryItems_DEPRECATED)
			{
				InventoryData.Add(ItemId, FTPSItemData(1, 1));
			}

			InventoryItems_DEPRECATED.Empty();
		}

		SavedDataVersion = ETPSInventorySaveGameVersion::LatestVersion;
	}
}