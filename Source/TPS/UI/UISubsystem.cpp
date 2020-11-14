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

    if (ShowUserWidget(name, uiInfo))
    {
        UIStack.PopUI(name, uiInfo);

        // 全屏界面
        if (uiInfo.Mode == EUIMode::MODE_MAIN)
        {
            // 隐藏栈内的UINode
            for (FUINode uiNode : UIStack.GetUINodes())
            {
                if (uiNode.GetName() == name)
                    continue;
                
                HideUINode(uiNode);
            }
        }
        else
        {
            // 隐藏栈顶其它非全屏界面
            for (FUINode& child : UIStack.TopUINode().GetChildren())
            {
                HideUINode(child);
            }
        }

        // 将UI插入栈顶
        UIStack.PushUI(name, uiInfo);
    }
}

void UUISubsystem::Close(EUINames name)
{
    UE_LOG(LogTemp, Warning, TEXT("UUISubsystem.Close name : %d"), name);

    FUIInfo uiInfo;
    if (!UIConfig.GetUIInfo(name, uiInfo) || uiInfo.Path.IsEmpty())
    {
        UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::Close Path is Empty. name : %d"), name);
        return;
    }

    if (HideUserWidget(name))
    {
        UIStack.PopUI(name, uiInfo);

        // 全屏界面
        if (uiInfo.Mode == EUIMode::MODE_MAIN)
        {
            if (!UIStack.Empty())
            {
                // 显示栈顶的UINode
                ShowUINode(UIStack.TopUINode());
            }
        }
    }
}

UUserWidget* UUISubsystem::FindUserWidget(EUINames name)
{
    UUserWidget* widget = nullptr;
    if (UserWidgetMap.Contains(name) && UserWidgetMap.Find(name))
    {
        widget = *UserWidgetMap.Find(name);
    }

    return widget;
}

UUserWidget* UUISubsystem::LoadUserWidget(EUINames name, FUIInfo uiInfo)
{
    UUserWidget* widget = FindUserWidget(name);
    if (widget == nullptr)
    {
        UClass* widgetClass = LoadClass<UUserWidget>(nullptr, *uiInfo.Path);
        if (widgetClass == nullptr)
        {
            UE_LOG(LogTemp, Error, TEXT("UUISubsystem::LoadUserWidget WidgetClass is null. path : %s"), *uiInfo.Path);
            return nullptr;
        }

        widget = CreateWidget<UUserWidget>(GetGameInstance(), widgetClass);
        UserWidgetMap.Add(name, widget);
    }

    return widget;
}

bool UUISubsystem::ShowUserWidget(EUINames name, FUIInfo uiInfo)
{
    UUserWidget* widget = LoadUserWidget(name, uiInfo);
    if (widget == nullptr)
        return false;

    if (widget->IsInViewport())
    {
        widget->SetIsEnabled(true);
        widget->SetVisibility(ESlateVisibility::Visible);
    }
    else
    {
        widget->AddToPlayerScreen(uiInfo.Layer);
        widget->SetVisibility(ESlateVisibility::Visible);
    }

    return true;
}

bool UUISubsystem::HideUserWidget(EUINames name)
{
    UUserWidget* widget = FindUserWidget(name);
    if (widget)
    {
        widget->SetIsEnabled(false);
        widget->SetVisibility(ESlateVisibility::Collapsed);

        return true;
    }

    return false;
}

void UUISubsystem::ShowUINode(FUINode node)
{
    for (FUINode& child : node.GetChildren())
    {
        ShowUINode(child);
    }

    ShowUserWidget(node.GetName(), node.GetInfo());
}

void UUISubsystem::HideUINode(FUINode node)
{
    for (FUINode& child : node.GetChildren())
    {
        HideUINode(child);
    }

    HideUserWidget(node.GetName());
}