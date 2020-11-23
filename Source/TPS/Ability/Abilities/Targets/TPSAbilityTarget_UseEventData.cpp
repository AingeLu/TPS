// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSAbilityTarget_UseEventData.h"
#include "TPSCharacter.h"

/** Uses the passed in event data */
void UTPSAbilityTarget_UseEventData::GetTargets_Implementation(ATPSCharacter* TargetingCharacter, AActor* TargetingActor,
	FGameplayEventData EventData, TArray<FHitResult>& OutHitResults, TArray<AActor*>& OutActors) const
{
	const FHitResult* FoundHitResult = EventData.ContextHandle.GetHitResult();
	if (FoundHitResult)
	{
		OutHitResults.Add(*FoundHitResult);
	}
	else if (EventData.Target)
	{
		OutActors.Add(const_cast<AActor*>(EventData.Target));
	}
}