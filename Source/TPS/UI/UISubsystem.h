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

private:
	void ReadUIConifg_DataTable();
	void ReadUIConifg_Json();
	void ReadUIConifg_csv();
	
	void CreateXmlParser();
	void ReadXmlParser(const FString& _XmlPath);

public:
	UFUNCTION(BlueprintCallable)
	void Open(EUINames name);
	UFUNCTION(BlueprintCallable)
	void Close(EUINames name = EUINames::NONE);

private:
	UFUNCTION(BlueprintCallable)
	UUserWidget* FindUserWidget(EUINames name);
	UFUNCTION(BlueprintCallable)
	UUserWidget* LoadUserWidget(EUINames name, FUIInfo uiInfo);

	UFUNCTION(BlueprintCallable)
	bool ShowUserWidget(EUINames name, FUIInfo uiInfo);
	UFUNCTION(BlueprintCallable)
	bool HideUserWidget(EUINames name);

private:
	UFUNCTION(BlueprintCallable)
	void ShowUINode(FUINode node);
	UFUNCTION(BlueprintCallable)
	void HideUINode(FUINode node);

private:
	FUIConfig UIConfig;
	FUIStack UIStack;

	TMap<EUINames, UUserWidget*> UserWidgetMap;
};
