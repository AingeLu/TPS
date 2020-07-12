// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "Blueprint/UserWidget.h"
#include "Blueprint/WidgetLayoutLibrary.h"
#include "CanvasPanelSlot.h"
#include "UISubsystem.generated.h"

// UIœ‘ æ’ª
//LUIManager.UIStack = {
//	1 = {
//		name = name1,
//		uiLayer = {
//			1 = {
//				name = name1,
//				args = { ... },
//			},
//			...
//		}
//	},
//
//	...
//
//}

/**
 * 
 */
UCLASS()
class TPS_API UUISubsystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()
	
public:

	bool ShouldCreateSubsystem(UObject* Outer) const override;

	/** Implement this for initialization of instances of the system */
	void Initialize(FSubsystemCollectionBase& Collection) override;

	/** Implement this for deinitialization of instances of the system */
	void Deinitialize() override;

public:
	void Open(FString name);
	void Close(FString name);

private:
	UUserWidget* LoadUI(FString bpPath);

private:
	TMap<FString, UUserWidget> userWidgetMap;
};
