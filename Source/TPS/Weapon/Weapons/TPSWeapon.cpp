// Fill out your copyright notice in the Description page of Project Settings.


#include "TPSWeapon.h"
#include "Components/SkeletalMeshComponent.h"
#include "TPSCharacter.h"

FName ATPSWeapon::MeshComponentName(TEXT("WeaponMesh0"));

// Sets default values
ATPSWeapon::ATPSWeapon()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	Mesh = CreateOptionalDefaultSubobject<USkeletalMeshComponent>(ATPSWeapon::MeshComponentName);
}

// Called when the game starts or when spawned
void ATPSWeapon::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void ATPSWeapon::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

void ATPSWeapon::SetOwningPawn(ATPSCharacter* NewOwner)
{
	if (OwningPawn != NewOwner)
	{
		SetInstigator(NewOwner);
		OwningPawn = NewOwner;
		// net owner for RPC calls
		SetOwner(NewOwner);
	}
}

void ATPSWeapon::OnEnterInventory(ATPSCharacter* NewOwner)
{
	SetOwningPawn(NewOwner);
}

void ATPSWeapon::OnLeaveInventory()
{
	//if (IsAttachedToPawn())
	//{
	//	OnEnterInventory();
	//}

	if (GetLocalRole() == ROLE_Authority)
	{
		SetOwningPawn(NULL);
	}
}