// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "Blueprint/UserWidget.h"
#include "Blueprint/WidgetLayoutLibrary.h"
#include "UISubsystem.generated.h"

struct FUINode
{
	FUINode()
	{

	}

	template <typename... Args>
	FUINode(FString name, Args... args)
	{
		Name		= name;
		int dummy[] = { 0, ((void)bar(std::forward<Args>(args)), 0) ... };
	}

	FORCEINLINE friend bool operator==(const FUINode& Lhs, const FUINode& Rhs) { return Lhs.Name == Rhs.Name; }

public:
	FString Name;
};

struct FUILayer
{
	FUILayer()
	{

	}

	FUILayer(FString name)
	{
		Name = name;
	}

	FORCEINLINE friend bool operator==(const FUILayer& Lhs, const FUILayer& Rhs) { return Lhs.Name == Rhs.Name; }

public:
	template <typename... Args>
	void AddNode(FString name, Args... args)
	{
		if (NodeMap.Contains(name))
			return;

		FUINode uiNode = FUINode(name, args);
		Nodes.Add(uiNode);
		NodeMap.Add(name, uiNode);
	}

	void RemoveNode(FString name)
	{
		if (NodeMap.Contains(name))
		{
			FUINode uiNode = NodeMap.FindRef(name);
			Nodes.Remove(uiNode);
			NodeMap.Remove(name);
		}
	}

	FUINode GetNode(FString name)
	{
		return NodeMap.FindRef(name);
	}

public:
	FString Name;
	TArray<FUINode> Nodes;
	TMap<FString, FUINode> NodeMap;
};

/**
 * 
 */
UCLASS()
class TPS_API UUISubsystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()
	
public:

	bool ShouldCreateSubsystem(UObject* Outer) const override;

	/** Implement this for initialization of instances of the system */
	void Initialize(FSubsystemCollectionBase& Collection) override;

	/** Implement this for deinitialization of instances of the system */
	void Deinitialize() override;

public:
	//template <typename... Args>
	//void Open(FString name, Args... args);

	UFUNCTION(BlueprintCallable)
	void Open(FString name);
	UFUNCTION(BlueprintCallable)
	void Close(FString name);

private:
	UFUNCTION(BlueprintCallable)
	UUserWidget* LoadUI(FString bpPath);

private:
	TMap<FString, UUserWidget*> UserWidgetMap;
	//TArray<FUILayer> UILayerStack;
};
