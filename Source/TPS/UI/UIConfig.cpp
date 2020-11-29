// Fill out your copyright notice in the Description page of Project Settings.


#include "UIConfig.h"

FUIConfig::FUIConfig()
{
	// TODO: 蓝图的路径需要在结尾加 _C
	//AddUIInfo(EUINames::UIBattleMain, "WidgetBlueprint'/Game/UMG/Battle/UIBattleMain.UIBattleMain_C'");
}

FUIConfig::~FUIConfig()
{
	UIMap.Remove(EUINames::UIBattleMain);
}

void FUIConfig::AddUIInfo(EUINames name, FString path, uint8 layer, EUIMode mode)
{
	UIMap.Add(name, FUIInfo(path, layer, mode));
}

bool FUIConfig::GetUIInfo(EUINames name, FUIInfo& outInfo)
{
	if (UIMap.Contains(name) && UIMap.Find(name))
	{
		outInfo = *UIMap.Find(name);
		return true;
	}

	return false;
}

void FUIConfig::AddUIInfo(FString name, FString path, uint8 layer, EUIMode mode)
{
	UIInfoMap.Add(name, FUIInfo(path, layer, mode));
}

bool FUIConfig::GetUIInfo(FString name, FUIInfo& outInfo)
{
	if (UIInfoMap.Contains(name) && UIInfoMap.Find(name))
	{
		outInfo = *UIInfoMap.Find(name);
		return true;
	}

	return false;
}