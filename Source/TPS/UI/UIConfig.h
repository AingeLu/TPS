// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "UIConfig.generated.h"

UENUM(BlueprintType)
enum class EUIMode : uint8
{
	NONE = 0,
	MODE_MAIN,	// �����棨ͨ����ʾȫ����
	MODE_TIPS,		// ��ʾ��ͨ����ʾ��ȫ����
	MAX,
};

USTRUCT(BlueprintType)
struct FUIInfo
{
	GENERATED_USTRUCT_BODY()

public:
	FUIInfo()
	{
		Path = "";
		Layer = 0;
		Mode = EUIMode::NONE;
	}
	
	FUIInfo(FString path, uint8 layer = 1, EUIMode mode = EUIMode::MODE_MAIN)
	{
		Path = path;
		Layer = layer;
		Mode = mode;
	}

public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = UI)
	FString Path;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = UI)
	uint8	Layer;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = UI)
	EUIMode Mode;
};

UENUM(BlueprintType)
enum class EUINames : uint8
{
	NONE = 0,
	UIBattleMain,

	MAX,
};

/**
 * 
 */
USTRUCT(BlueprintType)
struct TPS_API FUIConfig
{
	GENERATED_BODY()

public:
	FUIConfig();
	~FUIConfig();
	
	void AddUIInfo(EUINames name, FString path, uint8 layer = 1, EUIMode mode = EUIMode::MODE_MAIN);
	bool GetUIInfo(EUINames name, FUIInfo& outInfo);

	void AddUIInfo(FString name, FString path, uint8 layer = 1, EUIMode mode = EUIMode::MODE_MAIN);
	bool GetUIInfo(FString name, FUIInfo& outInfo);
private:
	TMap<EUINames, FUIInfo> UIMap;
	TMap<FString, FUIInfo> UIInfoMap;
};
