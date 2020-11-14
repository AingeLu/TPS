// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "TPSAbilityTask.h"
#include "TPSAbilityTask_Melee.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FTPSMeleeDelegate);

/**
 * 
 */
UCLASS(Blueprintable)
class TPS_API UTPSAbilityTask_Melee : public UTPSAbilityTask
{
	GENERATED_UCLASS_BODY()
	
	UPROPERTY(BlueprintAssignable)
	FTPSMeleeDelegate		OnSuccess;

	UPROPERTY(BlueprintAssignable)
	FTPSMeleeDelegate		OnFailure;

	/** UTPSAbilityTask_Melee */
	UFUNCTION(BlueprintCallable, Category = "Ability|Tasks", meta = (HidePin = "OwningAbility", DefaultToSelf = "OwningAbility", BlueprintInternalUseOnly = "TRUE"))
	static UTPSAbilityTask_Melee* Melee(UGameplayAbility* OwningAbility, FName TaskInstanceName);

};
