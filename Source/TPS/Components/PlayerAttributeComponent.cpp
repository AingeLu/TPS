// Fill out your copyright notice in the Description page of Project Settings.


#include "PlayerAttributeComponent.h"

// Sets default values for this component's properties
UPlayerAttributeComponent::UPlayerAttributeComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UPlayerAttributeComponent::BeginPlay()
{
	Super::BeginPlay();

	// ...
    AttrMap = TMap<EPlayerAttrType, FAttrOne>();
    // 初始化属性列表
    for (int attrType = (int)EPlayerAttrType::EN_CHARACTERATTR_MIN; attrType < (int)EPlayerAttrType::EN_CHARACTERATTR_MAX; attrType++)
    {
        AttrMap.FindOrAdd((EPlayerAttrType)attrType);
    }
}

void UPlayerAttributeComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    for (TMap<EPlayerAttrType, FAttrOne>::TIterator It(AttrMap); It; ++It)
    {
        EPlayerAttrType const attrType = It.Key();
        FAttrOne& attrOne = It.Value();
        attrOne.OnDestroy();
    }
}

void UPlayerAttributeComponent::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{

}

// Called every frame
void UPlayerAttributeComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
}

// 增加属性值
void UPlayerAttributeComponent::AddAttr(EPlayerAttrType attrType, int iValue, EAttrAddType addType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType >= EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return;

    FAttrOne& attrOne = AttrMap.FindOrAdd(attrType);

    ModifiedAttrStart(attrType);

    switch (addType)
    {
    case EAttrAddType::ATTRADD_BASE:
        attrOne.iBaseAdd = attrOne.iBaseAdd + iValue;
        break;
    case EAttrAddType::ATTRADD_UPADD:
        attrOne.iUpAdd = attrOne.iUpAdd + iValue;
        break;
    case EAttrAddType::ATTRADD_BASEMUL:
        attrOne.iBaseMul = attrOne.iBaseMul + iValue;
        break;
    case EAttrAddType::ATTRADD_UPADDMUL:
        attrOne.iUpMul = attrOne.iUpMul + iValue;
        break;
    case EAttrAddType::ATTRADD_ALLMUL:
        attrOne.iAllMul = attrOne.iAllMul + iValue;
        break;
    default:
        break;
    }

    SetAttr_Flag(attrType, 0);
    ModifiedAttrEnd(attrType);
}

// 减少属性值
void UPlayerAttributeComponent::DelAttr(EPlayerAttrType attrType, int iValue, EAttrAddType addType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType >= EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return;

    FAttrOne& attrOne = AttrMap.FindOrAdd(attrType);

    ModifiedAttrStart(attrType);

    switch (addType)
    {
    case EAttrAddType::ATTRADD_BASE:
        attrOne.iBaseAdd = attrOne.iBaseAdd - iValue;
        break;
    case EAttrAddType::ATTRADD_UPADD:
        attrOne.iUpAdd = attrOne.iUpAdd - iValue;
        break;
    case EAttrAddType::ATTRADD_BASEMUL:
        attrOne.iBaseMul = attrOne.iBaseMul - iValue;
        break;
    case EAttrAddType::ATTRADD_UPADDMUL:
        attrOne.iUpMul = attrOne.iUpMul - iValue;
        break;
    case EAttrAddType::ATTRADD_ALLMUL:
        attrOne.iAllMul = attrOne.iAllMul - iValue;
        break;
    default:
        break;
    }

    SetAttr_Flag(attrType, 0);
    ModifiedAttrEnd(attrType);
}

// 设置属性值
void UPlayerAttributeComponent::SetAttr(EPlayerAttrType attrType, int iValue, EAttrAddType addType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType >= EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return;

    FAttrOne& attrOne = AttrMap.FindOrAdd(attrType);
    
    // 检查值未变跳过
    switch (addType)
    {
    case EAttrAddType::ATTRADD_BASE:
        if (attrOne.iBaseAdd == iValue)
            return;
    case EAttrAddType::ATTRADD_UPADD:
        if (attrOne.iUpAdd == iValue)
            return;
    case EAttrAddType::ATTRADD_BASEMUL:
        if (attrOne.iBaseMul == iValue)
            return;
    case EAttrAddType::ATTRADD_UPADDMUL:
        if (attrOne.iUpMul == iValue)
            return;
    case EAttrAddType::ATTRADD_ALLMUL:
        if (attrOne.iAllMul == iValue)
            return;
    default:
        break;
    }

    ModifiedAttrStart(attrType);

    switch (addType)
    {
    case EAttrAddType::ATTRADD_BASE:
        attrOne.iBaseAdd = iValue;
        break;
    case EAttrAddType::ATTRADD_UPADD:
        attrOne.iUpAdd = iValue;
        break;
    case EAttrAddType::ATTRADD_BASEMUL:
        attrOne.iBaseMul = iValue;
        break;
    case EAttrAddType::ATTRADD_UPADDMUL:
        attrOne.iUpMul = iValue;
        break;
    case EAttrAddType::ATTRADD_ALLMUL:
        attrOne.iAllMul = iValue;
        break;
    default:
        break;
    }

    SetAttr_Flag(attrType, 0);
    ModifiedAttrEnd(attrType);
}

// 获取属性值
float UPlayerAttributeComponent::GetAttr(EPlayerAttrType attrType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return 0;

    // 客户端
    if (GetOwner() && GetOwner()->GetLocalRole() == ENetRole::ROLE_AutonomousProxy)
    {
        return Attrs.FindOrAdd(attrType);
    }

    if (GetAttr_Flag(attrType) > 0)
        return GetAttr_LastVal(attrType);

    int iBaseAdd = GetAttr_BaseAdd(attrType);
    int iUpAdd = GetAttr_UpAdd(attrType);
    int iBaseMul = GetAttr_BaseMul(attrType);
    int iUpMul = GetAttr_UpMul(attrType);
    int iAllMul = GetAttr_AllMul(attrType);

    int iaddAll = iBaseAdd + iUpAdd;
    int iAttrVal = iaddAll + iBaseAdd * iBaseMul / MATH_SCALE_10K + iUpAdd * iUpMul / MATH_SCALE_10K + iaddAll * iAllMul / MATH_SCALE_10K;

    SetAttr_Flag(attrType, 1);
    SetAttr_LastVal(attrType, iAttrVal);

    return iAttrVal;
}

int UPlayerAttributeComponent::GetAttr_BaseAdd(EPlayerAttrType attrType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return 0;

    return AttrMap.FindOrAdd(attrType).iBaseAdd;
}

int UPlayerAttributeComponent::GetAttr_UpAdd(EPlayerAttrType attrType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return 0;

    return AttrMap.FindOrAdd(attrType).iUpAdd;
}

int UPlayerAttributeComponent::GetAttr_BaseMul(EPlayerAttrType attrType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return 0;

    return AttrMap.FindOrAdd(attrType).iBaseMul;
}

int UPlayerAttributeComponent::GetAttr_UpMul(EPlayerAttrType attrType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return 0;

    return AttrMap.FindOrAdd(attrType).iUpMul;
}

int UPlayerAttributeComponent::GetAttr_AllMul(EPlayerAttrType attrType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return 0;

    return AttrMap.FindOrAdd(attrType).iAllMul;
}

int UPlayerAttributeComponent::GetAttr_Flag(EPlayerAttrType attrType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return false;

    return AttrMap.FindOrAdd(attrType).iFlag;
}

int UPlayerAttributeComponent::GetAttr_LastVal(EPlayerAttrType attrType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return 0;

    return AttrMap.FindOrAdd(attrType).iLastVal;
}

void UPlayerAttributeComponent::SetAttr_Flag(EPlayerAttrType attrType, int val)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return;
    
    AttrMap.FindOrAdd(attrType).iFlag = val;
}

void UPlayerAttributeComponent::SetAttr_LastVal(EPlayerAttrType attrType, int val)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return;

    AttrMap.FindOrAdd(attrType).iLastVal = val;
}

void UPlayerAttributeComponent::ModifiedAttrStart(EPlayerAttrType attrType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return;

    LastModifyPrecent = MATH_SCALE_10K;

    switch (attrType)
    {
    case EPlayerAttrType::EN_CHARACTERATTR_MIN:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_MAX_HP:
        LastmodifyVal = GetAttr(EPlayerAttrType::EN_CHARACTERATTR_MAX_HP);
        LastModifyPrecent = (LastmodifyVal != 0) ? (GetAttr(EPlayerAttrType::EN_CHARACTERATTR_HP) * MATH_SCALE_10K) / LastmodifyVal : 0;
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_HP:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_MAX_MP:
        LastmodifyVal = GetAttr(EPlayerAttrType::EN_CHARACTERATTR_MAX_MP);
        LastModifyPrecent = (LastmodifyVal != 0) ? (GetAttr(EPlayerAttrType::EN_CHARACTERATTR_MP) * MATH_SCALE_10K) / LastmodifyVal : 0;
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_MP:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_MAX_SHIELD:
        LastmodifyVal = GetAttr(EPlayerAttrType::EN_CHARACTERATTR_MAX_SHIELD);
        LastModifyPrecent = (LastmodifyVal != 0) ? (GetAttr(EPlayerAttrType::EN_CHARACTERATTR_MP) * MATH_SCALE_10K) / LastmodifyVal : 0;
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_SHIELD:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_MAX:
        break;
    default:
        break;
    }
}

void UPlayerAttributeComponent::ModifiedAttrEnd(EPlayerAttrType attrType)
{
    if (attrType <= EPlayerAttrType::EN_CHARACTERATTR_MIN || attrType > EPlayerAttrType::EN_CHARACTERATTR_MAX)
        return;

    // 边界保护
    switch (attrType)
    {
    case EPlayerAttrType::EN_CHARACTERATTR_MIN:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_MAX_HP:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_HP:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_MAX_MP:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_MP:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_MAX_SHIELD:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_SHIELD:
        break;
    case EPlayerAttrType::EN_CHARACTERATTR_MAX:
        break;
    default:
        break;
    }
}

// 客户端
void UPlayerAttributeComponent::OnRep_Attrs(TMap<EPlayerAttrType, int> oldAttrs)
{
    // TODO:
}