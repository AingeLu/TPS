// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSAbilitySystemComponent.h"
#include "AbilitySystemGlobals.h"

UTPSAbilitySystemComponent::UTPSAbilitySystemComponent()
{

}

UTPSAbilitySystemComponent* UTPSAbilitySystemComponent::GetAbilitySystemComponentFromActor(const AActor* Actor, bool LookForComponent)
{
	return Cast<UTPSAbilitySystemComponent>(UAbilitySystemGlobals::GetAbilitySystemComponentFromActor(Actor, LookForComponent));
}