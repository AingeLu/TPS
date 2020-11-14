// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "TPSAbilityTarget.h"
#include "TPSAbilityTarget_UseEventData.generated.h"

class ATPSCharacter;
class AActor;
struct FGameplayEventData;


/**
 * 
 */
UCLASS()
class TPS_API UTPSAbilityTarget_UseEventData : public UTPSAbilityTarget
{
	GENERATED_BODY()
public:
	// Constructor and overrides
	UTPSAbilityTarget_UseEventData() {}

	/** Uses the passed in event data */
	virtual void GetTargets_Implementation(ATPSCharacter* TargetingCharacter, AActor* TargetingActor,
		FGameplayEventData EventData, TArray<FHitResult>& OutHitResults, TArray<AActor*>& OutActors) const override;
};
