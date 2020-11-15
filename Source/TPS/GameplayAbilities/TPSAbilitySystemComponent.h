// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AbilitySystemComponent.h"
#include "TPSAbilitySystemComponent.generated.h"

/**
 * 
 */
UCLASS()
class TPS_API UTPSAbilitySystemComponent : public UAbilitySystemComponent
{
	GENERATED_BODY()
	
public:
	// Constructors and overrides
	UTPSAbilitySystemComponent();

	/** Version of function in AbilitySystemGlobals that returns correct type */
	static UTPSAbilitySystemComponent* GetAbilitySystemComponentFromActor(const AActor* Actor, bool LookForComponent = false);

};
