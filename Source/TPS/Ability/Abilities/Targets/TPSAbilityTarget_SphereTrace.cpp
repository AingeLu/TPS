// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSAbilityTarget_SphereTrace.h"
#include "TPSCharacter.h"

UTPSAbilityTarget_SphereTrace::UTPSAbilityTarget_SphereTrace()
{
	bIgnoreSelf = true;
	TraceColor = FLinearColor::Red;
	TraceHitColor = FLinearColor::Green;
	DrawTime = 5.0f;
}

void UTPSAbilityTarget_SphereTrace::GetTargets_Implementation(ATPSCharacter* TargetingCharacter, AActor* TargetingActor,
	FGameplayEventData EventData, TArray<FHitResult>& OutHitResults, TArray<AActor*>& OutActors) const
{
	const FVector& ActorLocation = TargetingCharacter->GetActorLocation();
	FVector Start = ActorLocation + OffsetFromActor;
	FVector End = ActorLocation + TargetingCharacter->GetActorForwardVector() * TraceLength;
	TArray<AActor*> ActorsToIgnore;
	TArray<FHitResult> TempHitResults;
	if (UKismetSystemLibrary::SphereTraceMultiForObjects(TargetingCharacter, Start, End, SphereRadius, ObjectTypes, bTraceComplex,
		ActorsToIgnore, DrawDebugType, TempHitResults, bIgnoreSelf, TraceColor, TraceHitColor, DrawTime))
	{
		for (const FHitResult& hitReuslt : TempHitResults)
		{
			if (hitReuslt.Actor.IsValid())
			{
				OutHitResults.Add(hitReuslt);
			}
		}
	}
}