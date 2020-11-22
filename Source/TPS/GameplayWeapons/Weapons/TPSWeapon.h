// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "TPSWeapon.generated.h"

class USkeletalMeshComponent;
class ATPSCharacter;


UCLASS()
class TPS_API ATPSWeapon : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	ATPSWeapon();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	/** set the weapon's owning pawn */
	void SetOwningPawn(ATPSCharacter* NewOwner);
	/** Proper way to get the owning pawn of weapon owner.*/
	ATPSCharacter* GetOwningPawn() const { return OwningPawn; }

public:
	/** [server] weapon was added to pawn's inventory */
	UFUNCTION(BlueprintCallable)
	virtual void OnEnterInventory(ATPSCharacter* NewOwner);

	/** [server] weapon was removed from pawn's inventory */
	UFUNCTION(BlueprintCallable)
	virtual void OnLeaveInventory();

public:
	UFUNCTION(BlueprintCallable)
	bool OnEquip() { return true; }
	UFUNCTION(BlueprintCallable)
	bool OnUnEquip() { return true; }

public:
	/** Name of the MeshComponent. Use this name if you want to prevent creation of the component (with ObjectInitializer.DoNotCreateDefaultSubobject). */
	static FName MeshComponentName;

protected:
	/** Cached pointer to owning pawn */
	UPROPERTY(Transient, ReplicatedUsing = OnRep_MyPawn)
	class ATPSCharacter* OwningPawn;

private:
	/** The main skeletal mesh associated with this Weapon (optional sub-object). */
	UPROPERTY(Category = Character, VisibleAnywhere, BlueprintReadOnly, meta = (AllowPrivateAccess = "true"))
	USkeletalMeshComponent* Mesh;
};
