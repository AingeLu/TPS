// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/WorldSettings.h"
#include "TPSWorldSettings.generated.h"

/**
 * 
 */
UCLASS()
class TPS_API ATPSWorldSettings : public AWorldSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = Custom)
	int32 WorldLevel;
};
