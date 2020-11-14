// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSAbilityTask_Melee.h"

UTPSAbilityTask_Melee::UTPSAbilityTask_Melee(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{

}

UTPSAbilityTask_Melee* UTPSAbilityTask_Melee::Melee(UGameplayAbility* OwningAbility, FName TaskInstanceName)
{
	UTPSAbilityTask_Melee* MyObj = NewAbilityTask<UTPSAbilityTask_Melee>(OwningAbility, TaskInstanceName);

	// TODO: 

	return MyObj;
}