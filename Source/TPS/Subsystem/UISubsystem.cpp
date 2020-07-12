// Fill out your copyright notice in the Description page of Project Settings.


#include "UISubsystem.h"

bool UUISubsystem::ShouldCreateSubsystem(UObject* Outer) const
{
	Super::ShouldCreateSubsystem(Outer);

	return true;
}

/** Implement this for initialization of instances of the system */
void UUISubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);

}

/** Implement this for deinitialization of instances of the system */
void UUISubsystem::Deinitialize()
{
	Super::Deinitialize();

}