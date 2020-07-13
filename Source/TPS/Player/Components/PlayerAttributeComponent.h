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
	EN_CHARACTERATTR_MAX_HP			= 1, // 最大生命值
	EN_CHARACTERATTR_HP				= 2, // 生命值(计算后)
	EN_CHARACTERATTR_MAX_MP			= 3, // 最大法术值
	EN_CHARACTERATTR_MP				= 4, // 法术值(计算后)
	EN_CHARACTERATTR_MAX_SHIELD		= 5, // 最大护盾值
	EN_CHARACTERATTR_SHIELD			= 6, // 护盾值(计算后)
	EN_CHARACTERATTR_MAX			= 7,
};

UENUM(BlueprintType)
enum class EAttrAddType : uint8
{
	ATTRADD_NONE		= 0,
	ATTRADD_BASE		= 1,	// 基础属性
	ATTRADD_UPADD		= 2,	// 加成属性(固定数值)
	ATTRADD_BASEMUL		= 3,	// 基础属性乘法(万分比)
	ATTRADD_UPADDMUL	= 4,	// 加成属性乘法(万分比)
	ATTRADD_ALLMUL		= 5,	// 所有属性乘法(万分比)
	ATTRADD_MAX			= 6,
};

USTRUCT(BlueprintType)
struct FAttrOne
{
	GENERATED_USTRUCT_BODY()

	int iBaseAdd;	// 基础加法值
	int iUpAdd;		// 加成加法值
	int iBaseMul;	// 基础值乘法
	int iUpMul;		// 加成值乘法
	int iAllMul;	// 所有值乘法

	int iFlag;		// 脏数据标记
	int iLastVal;	// 最终值

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
	// 增加属性值
	UFUNCTION(BlueprintType)
	void AddAttr(EPlayerAttrType attrType, int iValue, EAttrAddType addType);
	// 减少属性值
	UFUNCTION(BlueprintType)
	void DelAttr(EPlayerAttrType attrType, int iValue, EAttrAddType addType);
	// 设置属性值
	UFUNCTION(BlueprintType)
	void SetAttr(EPlayerAttrType attrType, int iValue, EAttrAddType addType);
	// 获取属性值
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
	TMap<EPlayerAttrType, int>		Attrs;				// 同步到客户端的数值

private:
	TMap<EPlayerAttrType, FAttrOne>	AttrMap;			// 所有属性列表
	int								LastmodifyVal;		// 修改前: 数值
	int								LastModifyPrecent;	// 修改前: 万分比
};
