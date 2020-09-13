// Fill out your copyright notice in the Description page of Project Settings.


#include "UISubsystem.h"
#include "Blueprint/UserWidget.h"

DEFINE_LOG_CATEGORY_STATIC(LogUISub, Log, All);

UUISubsystem::UUISubsystem()
{

}

UUISubsystem::~UUISubsystem()
{
    UE_LOG(LogUISub, Log, TEXT("%s %s (%p), frame # %llu"), ANSI_TO_TCHAR(__FUNCTION__), *GetClass()->GetName(), this, (uint64)GFrameCounter);
}

bool UUISubsystem::ShouldCreateSubsystem(UObject* Outer) const
{
	Super::ShouldCreateSubsystem(Outer);

	return true;
}

/** Implement this for initialization of instances of the system */
void UUISubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);

}

/** Implement this for deinitialization of instances of the system */
void UUISubsystem::Deinitialize()
{
	Super::Deinitialize();

}

void UUISubsystem::Open(EUINames name)
{
    UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::Open name : %d"), name);

    // 判断是否已经在UIConfig
    FUIInfo uiInfo;
    if (!UIConfig.GetUIInfo(name, uiInfo) || uiInfo.Path.IsEmpty())
    {
        UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::Open Path is Empty. name : %d"), name);
        return;
    }

    // 判断是否已经在UIStack
    FUINode uiNode;
    if (UIStack.FindUI(name, uiNode))
    {
        CloseUINode(uiNode);
    }

    UUserWidget* widget = nullptr;
    if (UserWidgetMap.Contains(name) && UserWidgetMap.Find(name))
    {
        widget = *UserWidgetMap.Find(name);
    }
    else
    {
        widget = LoadUI(uiInfo.Path);
        if (widget)
        {
            UserWidgetMap.Add(name, widget);
        }
    }

    if (widget)
    {
        if (!widget->IsInViewport())
        {
            widget->AddToPlayerScreen(1);
        }
        else if (!widget->GetIsEnabled())
        {
            widget->SetIsEnabled(true);
            widget->SetVisibility(ESlateVisibility::Visible);
        }

        UIStack.PushUI(name, uiInfo);

        TopUIInfo = uiInfo;
    }
}

void UUISubsystem::Close(EUINames name)
{
    UE_LOG(LogTemp, Warning, TEXT("UUISubsystem.Close name : %s"), name);

    FUIInfo uiInfo;
    if (!UIConfig.GetUIInfo(name, uiInfo) || uiInfo.Path.IsEmpty())
    {
        UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::Close Path is Empty. name : %d"), name);
        return;
    }

    if (UserWidgetMap.Contains(name) && UserWidgetMap.Find(name))
    {
        UUserWidget* widget = *UserWidgetMap.Find(name);
        if (widget)
        {
            if (widget->IsInViewport())
            {
                widget->RemoveFromViewport();
            }

            UIStack.PopUI(name, uiInfo);
        }
    }
}

void UUISubsystem::CloseUINode(FUINode node)
{
    for (FUINode& child : node.GetChildren())
    {
        CloseUINode(child);
    }

    Close(node.GetName());
}

UUserWidget* UUISubsystem::LoadUI(FString path)
{
    UClass* widgetClass = LoadClass<UUserWidget>(nullptr, *path);
	if (widgetClass == nullptr)
	{
		UE_LOG(LogTemp, Error, TEXT("UUISubsystem::LoadUI WidgetClass is null. path : %s"), *path);
		return nullptr;
	}

	UUserWidget* widget = CreateWidget<UUserWidget>(GetGameInstance(), widgetClass);
    return widget;
}