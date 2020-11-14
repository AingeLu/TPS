// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Abilities/GameplayAbility.h"
#include "GameplayTagContainer.h"
#include "TPSAbilityTypes.h"
#include "TPSAbility.generated.h"

/**
 * 
 */
UCLASS()
class TPS_API UTPSAbility : public UGameplayAbility
{
	GENERATED_BODY()
public:
	// Constructor and overrides
	UTPSAbility();

	/** Map of gameplay tags to gameplay effect containers */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = GameplayEffects)
	TMap<FGameplayTag, FTPSGameplayEffectContainer> EffectContainerMap;
};
