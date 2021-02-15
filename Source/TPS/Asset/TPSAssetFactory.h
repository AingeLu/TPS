// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Factories/Factory.h"
#include "TPSAssetFactory.generated.h"

/**
 * 
 */
UCLASS()
class TPS_API UTPSAssetFactory : public UFactory
{
	GENERATED_UCLASS_BODY()
	
	// UFactory interface
	virtual UObject* FactoryCreateNew(UClass* Class, UObject* InParent, FName Name, EObjectFlags Flags, UObject* Context, FFeedbackContext* Warn) override;
	virtual bool CanCreateNew() const override;
	// End of UFactory interface
};
