#include "AssetTypeActions_TPSAsset.h"


//void FAssetTypeActions_TPSAsset::OpenAssetEditor(const TArray<UObject*>& InObjects, TSharedPtr<class IToolkitHost> EditWithinLevelEditor)
//{
//	EToolkitMode::Type Mode = EditWithinLevelEditor.IsValid() ? EToolkitMode::WorldCentric : EToolkitMode::Standalone;
//
//	for (auto Object : InObjects)
//	{
//		auto Scenario = Cast<UTPSAsset>(Object);
//		if (Scenario != nullptr)
//		{
//			bool bFoundExisting = false;
//			if (!bFoundExisting)
//			{
//				//FGameFrameworkEditorModule& GameFrameworkEditorModule = FModuleManager::LoadModuleChecked<FGameFrameworkEditorModule>("GameFrameworkEditor").Get();
//				//TSharedRef< FScenarioEditor > NewEditor = GameFrameworkEditorModule.CreateScenarioEditor(Mode, EditWithinLevelEditor, Scenario);
//			}
//		}
//	}
//}
