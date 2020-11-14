// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSAbilityTarget_UseOwner.h"
#include "TPSCharacter.h"

void UTPSAbilityTarget_UseOwner::GetTargets_Implementation(ATPSCharacter* TargetingCharacter, AActor* TargetingActor,
	FGameplayEventData EventData, TArray<FHitResult>& OutHitResults, TArray<AActor*>& OutActors) const
{
	OutActors.Add(TargetingCharacter);
}