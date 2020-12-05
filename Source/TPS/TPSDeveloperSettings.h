// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/DeveloperSettings.h"
#include "TPSDeveloperSettings.generated.h"

/**
 * 
 */
UCLASS(config = TPSDeveloperSettings)
class TPS_API UTPSDeveloperSettings : public UDeveloperSettings
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintPure, DisplayName = TPSDeveloperSettings)
	static UTPSDeveloperSettings* Get() { return GetMutableDefault<UTPSDeveloperSettings>(); }

public:
	UTPSDeveloperSettings(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	/** Gets the settings container name for the settings, either Project or Editor */
	virtual FName GetContainerName() const override { return TEXT("Project"); };
	/** Gets the category for the settings, some high level grouping like, Editor, Engine, Game...etc. */
	virtual FName GetCategoryName() const override { return TEXT("TPS"); };
	/** The unique name for your section of settings, uses the class's FName. */
	virtual FName GetSectionName() const override { return TEXT("TPS"); };

public:
	UPROPERTY(config, EditAnyWhere, BlueprintReadWrite, Category = Defalut)
	FString ProjectName = "ProjectName";
};
