// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "UISubsystem.generated.h"

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
};
