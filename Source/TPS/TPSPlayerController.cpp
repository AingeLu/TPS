// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSPlayerController.h"
#include "UISubsystem.h"
#include "Kismet/GameplayStatics.h"

ATPSPlayerController::ATPSPlayerController(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	bShowMouseCursor = true;
}

void ATPSPlayerController::BeginPlayingState()
{
	Super::BeginPlayingState();

	// ¿Í»§¶Ë
	if (GetLocalRole() == ENetRole::ROLE_AutonomousProxy || GetNetMode() == ENetMode::NM_Standalone)
	{
		UGameInstance* GameInstance = UGameplayStatics::GetGameInstance(this);
		UUISubsystem* UISubsystem = GameInstance->GetSubsystem<UUISubsystem>();
		UISubsystem->Open(EUINames::UIBattleMain);
	}
}

void ATPSPlayerController::EndPlayingState()
{
	Super::EndPlayingState();

}

void ATPSPlayerController::BeginInactiveState()
{
	Super::BeginInactiveState();

}

void ATPSPlayerController::EndInactiveState()
{
	Super::EndInactiveState();
}