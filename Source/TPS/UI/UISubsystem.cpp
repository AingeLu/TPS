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
#include "UITypes.h"

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

    ReadUIConifg_DataTable();
    //ReadUIConifg_Json();

    CreateXmlParser();
    ReadXmlParser(FPaths::ProjectContentDir() + "test.xml");
}

/** Implement this for deinitialization of instances of the system */
void UUISubsystem::Deinitialize()
{
	Super::Deinitialize();

}

void UUISubsystem::ReadUIConifg_DataTable()
{
    UDataTable* UIDataTable = LoadObject<UDataTable>(nullptr, TEXT("DataTable'/Game/UMG/DataTables/DT_UIConfig.DT_UIConfig'"));
    if (UIDataTable)
    {
        static const FString ContextString(TEXT("GENERAL"));
        TArray<FUITableRow*> OutRowArray;
        UIDataTable->GetAllRows(ContextString, OutRowArray);
        for (const FUITableRow* val : OutRowArray)
        {
            UIConfig.AddUIInfo(val->Name, val->Path, val->Layer, val->Mode);
        }
    }
}

void UUISubsystem::ReadUIConifg_Json()
{
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
                    EUINames name = EUINames(Obj.Get()->GetNumberField("index"));
                    FString path = Obj.Get()->GetStringField("path");
                    UIConfig.AddUIInfo(name, path);
                }
            }
        }
    }
}

void UUISubsystem::ReadUIConifg_csv()
{

}

void UUISubsystem::CreateXmlParser()
{
    //xml������
    const FString _XmlContent = "<note><body>Don't forget the meeting!</body></note > ";
    //��Buffer�ķ�ʽ����һ��XmlFile����
    FXmlFile* _WriteXml = new FXmlFile(_XmlContent, EConstructMethod::ConstructFromBuffer);
    //����xml�ļ� FPaths::GameDir()��ʾ��ǰ���̵�·��
    _WriteXml->Save(FPaths::ProjectContentDir() + "test.xml");

    GEngine->AddOnScreenDebugMessage(-1, 10, FColor::Red, "create success!");
}

void UUISubsystem::ReadXmlParser(const FString& _XmlPath)
{
    //����һ��XmlFile�Ķ���
    FXmlFile* _XmlFile = new FXmlFile(*_XmlPath);
    //��ȡXmlFile�ĸ��ڵ�
    FXmlNode* _RootNode = _XmlFile->GetRootNode();
    //��ȡ���ڵ��µ������ӽڵ�
    const TArray<FXmlNode*> assetNodes = _RootNode->GetChildrenNodes();
    for (int i = 0; i < assetNodes.Num(); i++)
    {
        FString _TContent = assetNodes[i]->GetContent();
        GEngine->AddOnScreenDebugMessage(-1, 15.0f, FColor::Blue, _TContent);

        const TArray<FXmlNode*> contentNodes = assetNodes[i]->GetChildrenNodes();
        for (int k = 0; k < contentNodes.Num(); k++)
        {
            //��ȡ����ӡ���ڵ�����
            FString _TContent = contentNodes[k]->GetContent();
            GEngine->AddOnScreenDebugMessage(-1, 15.0f, FColor::Blue, _TContent);
        }
    }
}

void UUISubsystem::Open(EUINames name)
{
    UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::Open name : %d"), name);

    // �ж��Ƿ��Ѿ���UIConfig
    FUIInfo uiInfo;
    if (!UIConfig.GetUIInfo(name, uiInfo) || uiInfo.Path.IsEmpty())
    {
        UE_LOG(LogTemp, Warning, TEXT("UUISubsystem::Open Path is Empty. name : %d"), name);
        return;
    }

    if (ShowUserWidget(name, uiInfo))
    {
        UIStack.PopUI(name, uiInfo);

        // ȫ������
        if (uiInfo.Mode == EUIMode::MODE_MAIN)
        {
            // ����ջ�ڵ�UINode
            for (FUINode uiNode : UIStack.GetUINodes())
            {
                if (uiNode.GetName() == name)
                    continue;
                
                HideUINode(uiNode);
            }
        }
        else
        {
            // ����ջ��������ȫ������
            for (FUINode& child : UIStack.TopUINode().GetChildren())
            {
                HideUINode(child);
            }
        }

        // ��UI����ջ��
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

        // ȫ������
        if (uiInfo.Mode == EUIMode::MODE_MAIN)
        {
            if (!UIStack.Empty())
            {
                // ��ʾջ����UINode
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