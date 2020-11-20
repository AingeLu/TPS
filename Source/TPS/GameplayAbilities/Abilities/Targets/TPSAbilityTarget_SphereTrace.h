// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "TPSAbilityTarget.h"
#include "Kismet/KismetSystemLibrary.h"
#include "TPSAbilityTarget_SphereTrace.generated.h"

class ATPSCharacter;
class AActor;
struct FGameplayEventData;


/**
 * 
 */
UCLASS()
class TPS_API UTPSAbilityTarget_SphereTrace : public UTPSAbilityTarget
{
	GENERATED_BODY()

public:
	// Constructor and overrides
	UTPSAbilityTarget_SphereTrace();

	/** Uses the passed in event data */
	virtual void GetTargets_Implementation(ATPSCharacter* TargetingCharacter, AActor* TargetingActor,
		FGameplayEventData EventData, TArray<FHitResult>& OutHitResults, TArray<AActor*>& OutActors) const override;

public:
	/** Æ«ÒÆÖ÷½ÇµÄÎ»ÖÃ */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SphereTrace)
	FVector OffsetFromActor;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SphereTrace)
	float SphereRadius;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SphereTrace)
	float TraceLength;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SphereTrace)
	TArray<TEnumAsByte<EObjectTypeQuery>> ObjectTypes;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SphereTrace)
	bool bTraceComplex;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SphereTrace)
	TEnumAsByte<EDrawDebugTrace::Type> DrawDebugType;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SphereTrace)
	bool bIgnoreSelf;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SphereTrace)
	FLinearColor TraceColor;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SphereTrace)
	FLinearColor TraceHitColor;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = SphereTrace)
	float DrawTime;
};
