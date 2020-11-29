// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/DataTable.h"
#include "Blueprint/UserWidget.h"
#include "UIConfig.h"
#include "UITypes.generated.h"

/**
 * 
 */
USTRUCT(BlueprintType)
struct FUITableRow : public FTableRowBase
{
	GENERATED_USTRUCT_BODY()

	FUITableRow() { }
	virtual ~FUITableRow() { }

	UPROPERTY(EditAnywhere, Category = DataTable)
	EUINames Name;

	UPROPERTY(EditAnywhere, Category = DataTable)
	FString Path;

	UPROPERTY(EditAnywhere, Category = DataTable)
	TSubclassOf<UUserWidget> UserWidget;

	UPROPERTY(EditAnywhere, Category = DataTable)
	EUIMode Mode;

	UPROPERTY(EditAnywhere, Category = DataTable)
	uint8 Layer;
};
