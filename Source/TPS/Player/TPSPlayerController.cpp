// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSPlayerController.h"
#include "UISubsystem.h"
#include "Kismet/GameplayStatics.h"

ATPSPlayerController::ATPSPlayerController(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{

}

void ATPSPlayerController::BeginInactiveState()
{
	Super::BeginInactiveState();

	UGameInstance* GameInstance = UGameplayStatics::GetGameInstance(this);
	UUISubsystem* UISubsystem = GameInstance->GetSubsystem<UUISubsystem>();
	//UISubsystem->Open(FUIConfig::BattleMain);
}

void ATPSPlayerController::EndInactiveState()
{
	Super::EndInactiveState();
}