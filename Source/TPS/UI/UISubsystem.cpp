// Fill out your copyright notice in the Description page of Project Settings.


#include "UISubsystem.h"
#include "Blueprint/UserWidget.h"
#include "Json.h"
#include "Dom/JsonValue.h"
#include "Dom/JsonObject.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonWriter.h"
#include "Serialization/JsonSerializer.h"
#include "XmlFile.h"

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

    ReadUIConifg();
}

/** Implement this for deinitialization of instances of the system */
void UUISubsystem::Deinitialize()
{
	Super::Deinitialize();

}

void UUISubsystem::ReadUIConifg()
{
    // JSON
    FString uiConfigPath = FPaths::ProjectContentDir() + TEXT("UMG/DataTables/UIConfig.json");
    if (FPaths::FileExists(uiConfigPath))
    {
        FString fileStr;
        if (FFileHelper::LoadFileToString(fileStr, *uiConfigPath))
        {
            TArray<TSharedPtr<FJsonValue>> OutArray;
            TSharedRef<TJsonReader<>> JsonReader = TJsonReaderFactory<>::Create(fileStr);
            if (FJsonSerializer::Deserialize(JsonReader, OutArray))
            {
                for (TSharedPtr<FJsonValue>& Val : OutArray)
                {
                    const TSharedPtr<FJsonObject>& Obj = Val.Get()->AsObject();
                    FString Name = Obj.Get()->GetStringField("Name");
                    FString Path = Obj.Get()->GetStringField("path");
                    UIConfig.AddUIInfo(Name, Path);
                }
            }
        }
    }
}

void UUISubsystem::CreateXmlParser()
{
    //xml的内容
    const FString _XmlContent = "nn< ID>01 nABnBCDnn";
    //以Buffer的方式构建一个XmlFile对象
    FXmlFile* _WriteXml = new FXmlFile(_XmlContent, EConstructMethod::ConstructFromBuffer);
    //保存xml文件 FPaths::GameDir()表示当前工程的路径
    _WriteXml->Save(FPaths::ProjectContentDir() + "test.xml");

    //GEngine->AddOnScreenDebugMessage(-1, 10, FColor::Red, "create success!");
}

void UUISubsystem::ReadXmlParser(const FString& _XmlPath)
{
    //创建一个XmlFile的对象
    FXmlFile* _XmlFile = new FXmlFile(*_XmlPath);
    //获取XmlFile的根节点
    FXmlNode* _RootNode = _XmlFile->GetRootNode();
    //获取根节点下的所有子节点
    const TArray<FXmlNode> assetNodes = _RootNode->GetChildrenNodes();
    for (int i = 0; i < assetNodes.Num(); i++)
    {
        const TArray<FXmlNode> contentNodes = assetNodes[i]->GetChildrenNodes();

        for (int i = 0; i < contentNodes.Num(); i++)
        {
            //获取并打印出节点内容
            FString _TContent = contentNodes[i]->GetContent();
            GEngine->AddOnScreenDebugMessage(-1, 15.0f, FColor::Blue, _TContent);
        }
    }
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