// Fill out your copyright notice in the Description page of Project Settings.


#include "UIConfig.h"

FUIInfo::FUIInfo(FString name, FString path, uint8 layer, EUIMode mode)
{
	Name = name;
	Path = path;
	Layer = layer;
	Mode = mode;
}

UUIConfig::UUIConfig()
{
	// TODO: 蓝图的路径需要在结尾加 _C
	UIBattleMain = FUIInfo("UIBattleMain", "WidgetBlueprint'/Game/UI/BattleMain/UIBattleMain.UIBattleMain_C'");
	UIInfoMap.Add("UIBattleMain", UIBattleMain);
}

UUIConfig::~UUIConfig()
{
	UIInfoMap.Remove("UIBattleMain");
}

void UUIConfig::AddUIInfo(FString name, FString path, uint8 layer, EUIMode mode)
{
	UIInfoMap.Add(name, FUIInfo(name, path, layer, mode));
}

FUIInfo UUIConfig::GetUIInfo(FString name)
{
	if (UIInfoMap.Contains(name) && UIInfoMap.Find(name))
	{
		return *UIInfoMap.Find(name);
	}

	return FUIInfo(name, "");
}