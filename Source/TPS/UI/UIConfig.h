// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "UIConfig.generated.h"


UENUM(BlueprintType)
enum class EUIMode : uint8
{
	MODE_NONE = 0,
	MODE_MAIN,
	MODE_FULL,
	MODE_COVER,
	MODE_Max
};

USTRUCT(BlueprintType)
struct FUIInfo
{
	GENERATED_USTRUCT_BODY()

public:
	FUIInfo() {}
	FUIInfo(FString name, FString path, uint8 layer = 1, EUIMode mode = EUIMode::MODE_MAIN);

public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = UI)
	FString Name;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = UI)
	FString Path;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = UI)
	uint8	Layer;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = UI)
	EUIMode Mode;
};

/**
 * 
 */
UCLASS(BlueprintType, hideCategories = Object, meta = (BlueprintUIConfig))
class TPS_API UUIConfig : public UObject
{
	GENERATED_BODY()

public:
	UUIConfig();
	~UUIConfig();
	
	void AddUIInfo(FString name, FString path, uint8 layer = 1, EUIMode mode = EUIMode::MODE_MAIN);
	FUIInfo GetUIInfo(FString name);

public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = UI)
	FUIInfo UIBattleMain;

private:
	TMap<FString, FUIInfo> UIInfoMap;
};
