// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/NoExportTypes.h"
#include "Abilities/GameplayAbilityTypes.h"
#include "Engine/EngineTypes.h"
#include "TPSAbilityTarget.generated.h"

class ATPSCharacter;
class AActor;
struct FGameplayEventData;


/**
 * Class that is used to determine targeting for abilities
 * It is meant to be blueprinted to run target logic
 * This does not subclass GameplayAbilityTargetActor because this class is never instanced into the world
 * This can be used as a basis for a game-specific targeting blueprint
 * If your targeting is more complicated you may need to instance into the world once or as a pooled actor
 */
UCLASS(Blueprintable, meta = (ShowWorldContextPin))
class TPS_API UTPSAbilityTarget : public UObject
{
	GENERATED_BODY()

public:
	// Constructor and overrides
	UTPSAbilityTarget() {}

	/** Called to determine targets to apply gameplay effects to */
	UFUNCTION(BlueprintNativeEvent)
	void GetTargets(ATPSCharacter* TargetingCharacter, AActor* TargetingActor,
		FGameplayEventData EventData, TArray<FHitResult>& OutHitResults, TArray<AActor*>& OutActors) const;
};
