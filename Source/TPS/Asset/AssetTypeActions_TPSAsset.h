#pragma once

#include "CoreMinimal.h"
#include "Widgets/SWidget.h"
#include "AssetTypeActions_Base.h"
#include "TPSAsset.h"

struct FAssetData;
class IClassTypeActions;

class FAssetTypeActions_TPSAsset : public FAssetTypeActions_Base
{
public:
	FAssetTypeActions_TPSAsset(EAssetTypeCategories::Type InAssetCategoryBit)
		: AssetCategoryBit(InAssetCategoryBit)
	{
	}

	// IAssetTypeActions Implementation
	virtual FText GetName() const override { return NSLOCTEXT("AssetTypeActions", "AssetTypeActions_TPSAsset", "TPSAsset"); }
	virtual FColor GetTypeColor() const override { return FColor(149, 70, 255); }
	virtual UClass* GetSupportedClass() const override { return UTPSAsset::StaticClass(); }
	//virtual void OpenAssetEditor(const TArray<UObject*>& InObjects, TSharedPtr<class IToolkitHost> EditWithinLevelEditor = TSharedPtr<IToolkitHost>()) override;
	virtual uint32 GetCategories() override { return AssetCategoryBit | EAssetTypeCategories::Basic; }

private:

	EAssetTypeCategories::Type AssetCategoryBit;
};

