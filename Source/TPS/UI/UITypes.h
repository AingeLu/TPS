// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/DataTable.h"
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
	uint16 index : 1;

	UPROPERTY(EditAnywhere, Category = DataTable)
	FString path;
};
