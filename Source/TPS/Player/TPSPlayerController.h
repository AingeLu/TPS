// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "TPSPlayerController.generated.h"

/**
 * 
 */
UCLASS()
class TPS_API ATPSPlayerController : public APlayerController
{
	GENERATED_BODY()
	
public:
	ATPSPlayerController(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	/** State entered when inactive (no possessed pawn, not spectating, etc). */
	virtual void BeginInactiveState() override;

	/** Called when leaving the inactive state */
	virtual void EndInactiveState() override;
};
