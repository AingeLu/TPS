// Copyright Epic Games, Inc. All Rights Reserved.

#include "TPS.h"
#include "Modules/ModuleManager.h"
#include "IAssetTools.h"
#include "AssetToolsModule.h"
#include "Asset/AssetTypeActions_TPSAsset.h"

#define LOCTEXT_NAMESPACE "FTPSGameModuleImpl"

class FTPSGameModuleImpl : public IModuleInterface
{
public:
    virtual void StartupModule() override
    {
        IAssetTools& AssetTools = FModuleManager::LoadModuleChecked<FAssetToolsModule>("AssetTools").Get();
        //定义资产的分类名
        EAssetTypeCategories::Type AssetCategory = AssetTools.RegisterAdvancedAssetCategory(FName(TEXT("TPSAsset")), FText::FromName(TEXT("TPSAsset")));
        TSharedPtr<FAssetTypeActions_TPSAsset> actionType = MakeShareable(new FAssetTypeActions_TPSAsset(AssetCategory));

        AssetTools.RegisterAssetTypeActions(actionType.ToSharedRef());
    }

    virtual void ShutdownModule() override
    {
    }
};

#undef LOCTEXT_NAMESPACE

IMPLEMENT_PRIMARY_GAME_MODULE(FTPSGameModuleImpl, TPS, "TPS");
//IMPLEMENT_PRIMARY_GAME_MODULE( FDefaultGameModuleImpl, TPS, "TPS" );
 