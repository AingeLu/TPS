// Fill out your copyright notice in the Description page of Project Settings.


#include "UISubsystem.h"
#include "Blueprint/UserWidget.h"

DEFINE_LOG_CATEGORY_STATIC(LogUISub, Log, All);

UUISubsystem::UUISubsystem()
{
    UIConfig = CreateDefaultSubobject<UUIConfig>(TEXT("UIConfig"));
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

void UUISubsystem::Open(FString name)
{
    UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::Open name : %s"), *name);

    FUIInfo uiInfo = UIConfig->GetUIInfo(name);
    if (uiInfo.Path.IsEmpty())
    {
        UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::Open Path is Empty. name : %s"), *name);
        return;
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

        switch (uiInfo.Mode)
        {
        case EUIMode::MODE_MAIN:
            break;
        case EUIMode::MODE_FULL:
            break;
        case EUIMode::MODE_COVER:
            break;
        default:
            break;
        }

        TopUIInfo = uiInfo;
    }
}

void UUISubsystem::OpenEx(FUIInfo uiInfo)
{
    UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::OpenEx uiInfo.Name : %s"), *uiInfo.Name);

    if (uiInfo.Path.IsEmpty())
    {
        UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::OpenEx uiInfo.Path is Empty. uiInfo.Name : %s"), *uiInfo.Name);
        return;
    }

    UUserWidget* widget = nullptr;
    if (UserWidgetMap.Contains(uiInfo.Name) && UserWidgetMap.Find(uiInfo.Name))
    {
        widget = *UserWidgetMap.Find(uiInfo.Name);
    }
    else
    {
        widget = LoadUI(uiInfo.Path);
        if (widget)
        {
            UserWidgetMap.Add(uiInfo.Name, widget);
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

        switch (uiInfo.Mode)
        {
        case EUIMode::MODE_MAIN:
            break;
        case EUIMode::MODE_FULL:
            break;
        case EUIMode::MODE_COVER:
            break;
        default:
            break;
        }

        TopUIInfo = uiInfo;
    }
}

void UUISubsystem::Close(FString name)
{
    UE_LOG(LogTemp, Warning, TEXT("UUISubsystem.Close name : %s"), *name);

    if (UserWidgetMap.Contains(name) && UserWidgetMap.Find(name))
    {
        UUserWidget* widget = *UserWidgetMap.Find(name);
        if (widget)
        {
            if (widget->IsInViewport())
            {
                widget->RemoveFromViewport();
            }
        }
    }
}

void UUISubsystem::CloseEx(FUIInfo uiInfo)
{
    UE_LOG(LogTemp, Warning, TEXT("UUISubsystem.CloseEx uiInfo.Name : %s"), *uiInfo.Name);

    if (UserWidgetMap.Contains(uiInfo.Name) && UserWidgetMap.Find(uiInfo.Name))
    {
        UUserWidget* widget = *UserWidgetMap.Find(uiInfo.Name);
        if (widget)
        {
            if (widget->IsInViewport())
            {
                widget->RemoveFromViewport();
            }
        }
    }
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