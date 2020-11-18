// Copyright Epic Games, Inc. All Rights Reserved.

#include "TPSGameMode.h"
#include "TPSCharacter.h"
#include "TPSPlayerController.h"
#include "UObject/ConstructorHelpers.h"

ATPSGameMode::ATPSGameMode()
{
	// set default pawn class to our Blueprinted character
	static ConstructorHelpers::FClassFinder<APawn> PlayerPawnBPClass(TEXT("/Game/Blueprints/BP_TPSCharacterBase"));
	if (PlayerPawnBPClass.Class != NULL)
	{
		DefaultPawnClass = PlayerPawnBPClass.Class;
	}

	PlayerControllerClass = ATPSPlayerController::StaticClass();
}
