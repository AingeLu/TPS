// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "PlayerAttributeComponent.generated.h"

#define MATH_SCALE_10K 10000

UENUM(BlueprintType)
enum class EPlayerAttrType : uint8
{
	EN_CHARACTERATTR_MIN			= 0,
	EN_CHARACTERATTR_MAX_HP			= 1, // �������ֵ
	EN_CHARACTERATTR_HP				= 2, // ����ֵ(�����)
	EN_CHARACTERATTR_MAX_MP			= 3, // �����ֵ
	EN_CHARACTERATTR_MP				= 4, // ����ֵ(�����)
	EN_CHARACTERATTR_MAX_SHIELD		= 5, // ��󻤶�ֵ
	EN_CHARACTERATTR_SHIELD			= 6, // ����ֵ(�����)
	EN_CHARACTERATTR_MAX			= 7,
};

UENUM(BlueprintType)
enum class EAttrAddType : uint8
{
	ATTRADD_NONE		= 0,
	ATTRADD_BASE		= 1,	// ��������
	ATTRADD_UPADD		= 2,	// �ӳ�����(�̶���ֵ)
	ATTRADD_BASEMUL		= 3,	// �������Գ˷�(��ֱ�)
	ATTRADD_UPADDMUL	= 4,	// �ӳ����Գ˷�(��ֱ�)
	ATTRADD_ALLMUL		= 5,	// �������Գ˷�(��ֱ�)
	ATTRADD_MAX			= 6,
};

USTRUCT(BlueprintType)
struct FAttrOne
{
	GENERATED_USTRUCT_BODY()

	int iBaseAdd;	// �����ӷ�ֵ
	int iUpAdd;		// �ӳɼӷ�ֵ
	int iBaseMul;	// ����ֵ�˷�
	int iUpMul;		// �ӳ�ֵ�˷�
	int iAllMul;	// ����ֵ�˷�

	int iFlag;		// �����ݱ��
	int iLastVal;	// ����ֵ

public:
	FAttrOne()
	{
		this->iBaseAdd = 0;
		this->iUpAdd = 0;
		this->iBaseMul = 0;
		this->iUpMul = 0;

		this->iFlag = 0;
		this->iLastVal = 0;
	}

	void OnDestroy()
	{
		this->iBaseAdd = 0;
		this->iUpAdd = 0;
		this->iBaseMul = 0;
		this->iUpMul = 0;

		this->iFlag = 0;
		this->iLastVal = 0;
	}

	void Clear()
	{
		this->iBaseAdd = 0;
		this->iUpAdd = 0;
		this->iBaseMul = 0;
		this->iUpMul = 0;

		this->iFlag = false;
		this->iLastVal = 0;
	}
};

UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class TPS_API UPlayerAttributeComponent : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UPlayerAttributeComponent();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

	void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;


	////////////////////////////////////////////////////////////////////////////////////
	// Server Functions
	////////////////////////////////////////////////////////////////////////////////////
public:
	// ��������ֵ
	UFUNCTION(BlueprintType)
	void AddAttr(EPlayerAttrType attrType, int iValue, EAttrAddType addType);
	// ��������ֵ
	UFUNCTION(BlueprintType)
	void DelAttr(EPlayerAttrType attrType, int iValue, EAttrAddType addType);
	// ��������ֵ
	UFUNCTION(BlueprintType)
	void SetAttr(EPlayerAttrType attrType, int iValue, EAttrAddType addType);
	// ��ȡ����ֵ
	UFUNCTION(BlueprintType)
	float GetAttr(EPlayerAttrType attrType);

private:
	int GetAttr_BaseAdd(EPlayerAttrType attrType);
	int GetAttr_UpAdd(EPlayerAttrType attrType);
	int GetAttr_BaseMul(EPlayerAttrType attrType);
	int GetAttr_UpMul(EPlayerAttrType attrType);
	int GetAttr_AllMul(EPlayerAttrType attrType);
	int GetAttr_Flag(EPlayerAttrType attrType);
	int GetAttr_LastVal(EPlayerAttrType attrType);

	void SetAttr_Flag(EPlayerAttrType attrType, int val);
	void SetAttr_LastVal(EPlayerAttrType attrType, int val);

	void ModifiedAttrStart(EPlayerAttrType attrType);
	void ModifiedAttrEnd(EPlayerAttrType attrType);

private:
	UFUNCTION()
	void OnRep_Attrs(TMap<EPlayerAttrType, int> oldAttrs);

private:
	UPROPERTY(ReplicatedUsing = OnRep_Attrs)
	TMap<EPlayerAttrType, int>		Attrs;				// ͬ�����ͻ��˵���ֵ

private:
	TMap<EPlayerAttrType, FAttrOne>	AttrMap;			// ���������б�
	int								LastmodifyVal;		// �޸�ǰ: ��ֵ
	int								LastModifyPrecent;	// �޸�ǰ: ��ֱ�
};
