// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSAssetFactory.h"
#include "TPSAsset.h"

UTPSAssetFactory::UTPSAssetFactory(const class FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	bCreateNew = true;
	bEditAfterNew = true;
	SupportedClass = UTPSAsset::StaticClass();
}

bool UTPSAssetFactory::CanCreateNew() const
{
	return true;
}

UObject* UTPSAssetFactory::FactoryCreateNew(UClass* Class, UObject* InParent, FName Name, EObjectFlags Flags, UObject* Context, FFeedbackContext* Warn)
{
	check(Class->IsChildOf(UTPSAsset::StaticClass()));
	return NewObject<UTPSAsset>(InParent, Class, Name, Flags);;
}