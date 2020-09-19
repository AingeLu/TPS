// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UIConfig.h"
#include "UIStack.generated.h"

struct FUINode;

USTRUCT(BlueprintType)
struct TPS_API FUINode
{
	GENERATED_USTRUCT_BODY()

public:
	FUINode()
	{
		Name = EUINames::NONE;
		Info = FUIInfo();
		Parent = nullptr;
	}

	FUINode(EUINames name, FUIInfo info, FUINode* parent = nullptr)
	{
		Name = name;
		Info = info;
		Parent = parent;
	}

public:
	FORCEINLINE friend bool operator==(const FUINode& Lhs, const FUINode& Rhs) { return Lhs.Name == Rhs.Name; }

public:
	EUINames GetName() { return Name; }
	FUIInfo GetInfo() { return Info; }

public:
	TArray<FUINode> GetChildren() { return Children; }
	void AddChild(const FUINode& uiNode) { Children.Add(uiNode); }
	void RemoveChild(const FUINode& uiNode);
	void RemoveAllChildren();

public:
	FUINode* GetParent() { return Parent; }
	void RemoveFromParent();

private:
	EUINames Name;
	FUIInfo Info;
	TArray<FUINode> Children;
	FUINode* Parent;
};


/**
 * 
 */
USTRUCT(BlueprintType)
struct TPS_API FUIStack
{
	GENERATED_BODY()

public:
	FUIStack();
	~FUIStack();

public:
	void PushUI(EUINames name, const FUIInfo uiInfo);
	void PopUI(EUINames name, const FUIInfo uiInfo);
	bool FindUI(EUINames name, FUINode& outNode);

	TArray<FUINode> GetUINodes() { return UINodes; }
	FUINode& TopUINode();

private:
	TArray<FUINode> UINodes;
};
