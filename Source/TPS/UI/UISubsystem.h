// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "Blueprint/UserWidget.h"
#include "Blueprint/WidgetLayoutLibrary.h"
#include "UIConfig.h"
#include "UIStack.h"
#include "UISubsystem.generated.h"


/**
 * 
 */
UCLASS()
class TPS_API UUISubsystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()
	
public:
	UUISubsystem();
	~UUISubsystem();

	bool ShouldCreateSubsystem(UObject* Outer) const override;

	/** Implement this for initialization of instances of the system */
	void Initialize(FSubsystemCollectionBase& Collection) override;

	/** Implement this for deinitialization of instances of the system */
	void Deinitialize() override;

public:
	UFUNCTION(BlueprintCallable)
	void Open(EUINames name);
	UFUNCTION(BlueprintCallable)
	void Close(EUINames name = EUINames::NONE);
	UFUNCTION(BlueprintCallable)
	void CloseUINode(FUINode node);

	UFUNCTION(BlueprintCallable)
	FUIInfo GetTopUIInfo() { return TopUIInfo; }

private:
	UFUNCTION(BlueprintCallable)
	UUserWidget* LoadUI(FString path);

private:
	// 当前显示在最顶层的UI
	FUIInfo TopUIInfo;

	FUIConfig UIConfig;
	FUIStack UIStack;

	TMap<EUINames, UUserWidget*> UserWidgetMap;
};
