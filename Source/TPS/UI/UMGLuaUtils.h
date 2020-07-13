#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "Blueprint/WidgetLayoutLibrary.h"
//#include "CanvasPanelSlot.h"

//class UMGLuaUtils
//{
//public:
//	static void UMG_Image_SetBrush(UObject* Image, FString Path);
//
//	static void UMG_ImageExt_SetBrush(UObject* ImageExt, FString Path);
//
//	static void UMG_ProgressBar_SetBrush(UObject* ProgressBar, FString Path);
//
//	static void UMG_Text_SetText(UObject* Text, FString Content);
//
//	static UCanvasPanelSlot* UMG_GetCanvasPanelSlot(UObject* widget);
//
//	static float UMG_GetScreen();
//
//	static void UMG_GetScreenXY(FVector2D * screenXY);
//
//	static UMaterialInstanceDynamic * UMG_GetMaterial(FString bpPath, UObject * uobj);
//
//	static UTexture2D * UMG_GetTexture(FString Path);
//
//	static void UMG_SlateBrush_SetResource(UObject * ProgressBar ,UMaterialInstanceDynamic * matPtr);
//
//	static void UMG_Image_SetResource(UObject * Image, UMaterialInstanceDynamic * matPtr);
//
//	static bool UMG_SetUIWorldPosToWidget(APlayerController * playerController , FVector worldPos , UWidget * widget);
//
//	static void UMG_SetGridSlotLocation(UObject * uiObj , int32 X , int32 Y);
//
//	static bool UMG_GetFPointEventScreenSpacePosition(FPointerEvent pointerEvent , FVector * screenLocationXY);
//
//	static UUserWidget* UMG_LoadUI(FString bpPath);
//
//	static bool UMG_UseMouseForTouch();
//
//	static bool UMG_PositionIsInside(const FVector2D& Center, const FVector2D& Position, const FVector2D& BoxSize);
//
//	static float UMG_GetFPS();
//};