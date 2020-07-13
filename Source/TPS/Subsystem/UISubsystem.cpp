// Fill out your copyright notice in the Description page of Project Settings.


#include "UISubsystem.h"
#include "Blueprint/UserWidget.h"

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

//template <typename... Args>
//void UUISubsystem::Open(FString name, Args... args)
//{
    //print("LUIManager.ShowUI name = " ..name)
    //local config = self.UIConfig[name]
    //if nil == config then
    //    print("LUIManager.ShowUI config is nil. name = " ..name)
    //    return
    //end

    //    local bpClass = self.BPClasses[name]
    //    if nil == bpClass then

    //        -- - 创建蓝图 Widget
    //        bpClass = self:LoadUI(config.bp_class)

    //        print("LUIManager:ShowUI Load UI Success .")

    //        if bpClass == nil then
    //            print("bpClass is nil . bp_class : ", config.bp_class)
    //        end

    //        self.BPClasses[name] = bpClass;

    //        if LUIManager:IsAdaptIphonex() then
    //            local adapterCvs = bpClass.Adapt_CanvasPanel
    //            print("|| AdaptIphonex ... name :", name)
    //            if adapterCvs ~= nil then
    //                local CanvasAdapt_cvs = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(adapterCvs);

    //            local margin = UE4.FMargin()
    //            margin.Left = 56.0
    //            margin.Right = 56.0

    //            if CanvasAdapt_cvs ~= nil then
    //                CanvasAdapt_cvs : SetOffsets(margin);
    //            end
    //        end
    //    end
    //end

    //if bpClass == nil then
    //    print("bpClass is nil ........")
    //    return
    //end

    //if not bpClass:IsInViewport() then
    //    bpClass : AddToViewport(config.layer)
    //else
    //    if not bpClass:GetIsEnabled() then
    //        bpClass : SetIsEnabled(true)
    //        bpClass : SetVisibility(UE4.ESlateVisibility.Visible)
    //    end
    //end

    //-- - 调用 OnShowWindow
    //if bpClass.OnShowWindow ~= nil and type(bpClass.OnShowWindow) == "function" then
    //    bpClass : OnShowWindow(...)
    //end
//}

//function LUIManager : IsAdaptIphonex()
//return  UE4.UMGLuaUtils.UMG_GetScreen() >= 2
//end

void UUISubsystem::Open(FString name)
{
    UE_LOG(LogTemp, Warning, TEXT("LUIManager.Open name : %s"), *name);

    UUserWidget* widget = nullptr;
    if (UserWidgetMap.Contains(name))
    {
        widget = UserWidgetMap[name];
    }
    
    if (widget == nullptr)
    {
        FString bpPath = name;
        widget = LoadUI(bpPath);
        if (widget)
        {
            UserWidgetMap[name] = widget;
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
    }
}

void UUISubsystem::Close(FString name)
{

}

UUserWidget* UUISubsystem::LoadUI(FString bpPath)
{
	//UClass* uclass = LoadClass<T>(NULL, *path);
	FString fullBpPath = FString("WidgetBlueprint'" + bpPath + "_C'");
	UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::LoadUI fullBpPath : %s"), *fullBpPath);

	auto uclass = LoadClass<UUserWidget>(nullptr, *fullBpPath);
	if (uclass == nullptr)
	{
		UE_LOG(LogTemp, Error, TEXT("UUISubsystem::LoadUI uclass is null ."));
		return nullptr;
	}

	UUserWidget* widget = CreateWidget<UUserWidget>(GetGameInstance(), uclass);
    return widget;
}