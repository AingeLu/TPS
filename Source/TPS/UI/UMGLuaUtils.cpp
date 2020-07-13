#include "UMGLuaUtils.h"
//#include "UnrealProject.h"
//#include "ShooterGame.h"
//#include "PaperSprite.h"
#include "Kismet/KismetRenderingLibrary.h"
#include "Engine/TextureRenderTarget2D.h"
#include "UMG/Public/Components/GridSlot.h"

#if WITH_EDITOR

#include "Editor/EditorEngine.h"
#include "Editor/UnrealEdEngine.h"

#else

#include "Engine/GameEngine.h"

#endif


//void UMGLuaUtils::UMG_Image_SetBrush(UObject* Image, FString Path)
//{
//	if (Image == NULL)
//		return;
//
//	UImage* Cast_Image = Cast<UImage>(Image);
//	if (Cast_Image == NULL)
//	{
//		UE_LOG(GameLogic, Error, TEXT("Image_SetBrushFromTexture UWidget is not UImage Type, Path:"), *Path);
//		return;
//	}
//
//	if (Path.Len() <= 0)
//		return;
//
//	FString name = TEXT("");
//	int32 Index = 0;
//	if (Path.FindLastChar(TCHAR('/'), Index))
//	{
//		name = Path.Right(Path.Len() - Index - 1);
//	}
//
//	FString FullPath = FString::Printf(TEXT("/Game/%s.%s"), *Path, *name);
//	UPaperSprite* Sprite = Cast<UPaperSprite> (StaticLoadObject(UPaperSprite::StaticClass(), NULL, *FullPath));
//	if (Sprite)
//	{
//		const FVector2D SpriteSize = Sprite->GetSlateAtlasData().GetSourceDimensions();
//
//		FSlateBrush TempBrush;
//		TempBrush.SetResourceObject(Sprite);
//		TempBrush.ImageSize = FVector2D(SpriteSize.X, SpriteSize.Y);
//
//		Cast_Image->SetBrush(TempBrush);
//	}
//	else
//	{
//	
//	}
//}
//
//void UMGLuaUtils::UMG_SlateBrush_SetResource(UObject * ProgressBar, UMaterialInstanceDynamic * matPtr)
//{
//	if (ProgressBar == NULL)
//		return;
//
//	UProgressBar* Cast_ProgressBar = Cast<UProgressBar>(ProgressBar);
//	if (Cast_ProgressBar == NULL)
//	{
//		UE_LOG(GameLogic, Error, TEXT("Image_SetBrushFromTexture UWidget is not UProgressBar Type"));
//		return;
//	}
//
//	if (matPtr == nullptr) 
//	{
//		UE_LOG(GameLogic, Error, TEXT("matPtr is nullptr ."));
//		return;
//	}
//
//	Cast_ProgressBar->WidgetStyle.FillImage.SetResourceObject(matPtr);
//}
//
//void UMGLuaUtils::UMG_Image_SetResource(UObject * Image, UMaterialInstanceDynamic * matPtr)
//{
//	if (Image == NULL)
//		return;
//
//	UImage* Cast_Image = Cast<UImage>(Image);
//	if (Cast_Image == NULL)
//	{
//		UE_LOG(GameLogic, Error, TEXT("Image_SetBrushFromTexture UWidget is not UImage Type"));
//		return;
//	}
//
//	if (matPtr == nullptr)
//	{
//		UE_LOG(GameLogic, Error, TEXT("matPtr is nullptr ."));
//		return;
//	}
//
//	Cast_Image->Brush.SetResourceObject(matPtr);
//}
//
//bool UMGLuaUtils::UMG_SetUIWorldPosToWidget(APlayerController * playerController, FVector worldPos, UWidget * widget)
//{
//	if (!playerController || !widget)
//		return false;
//
//	FVector2D uiPos;
//
//	bool bSuccess = UWidgetLayoutLibrary::ProjectWorldLocationToWidgetPosition(playerController, worldPos, uiPos);
//
//	UCanvasPanelSlot * cvs_slot = Cast<UCanvasPanelSlot>(widget->Slot);
//	if (!cvs_slot) 
//	{
//		UE_LOG(GameLogic, Error, TEXT("Image_SetBrushFromTexture UWidget is cvs_slot is null ."));
//		return false;
//	}
//
//	cvs_slot->SetPosition(uiPos);
//	
//
//	return bSuccess;
//}
//
//void UMGLuaUtils::UMG_SetGridSlotLocation(UObject * uiObj, int32 X, int32 Y)
//{
//	if (uiObj == NULL)
//		return;
//
//	UWidget * uwidget = Cast<UWidget>(uiObj);
//
//	if (uwidget == NULL)
//	{
//		UE_LOG(GameLogic, Error, TEXT("UMGLuaUtils::UMG_SetGridSlotLocation can not cast to UUserWidget ."));
//		return;
//	}
//
//	UGridSlot * gridSlot = Cast<UGridSlot>(uwidget->Slot);
//	if (gridSlot == NULL)
//	{
//		UE_LOG(GameLogic, Error, TEXT("UMGLuaUtils::UMG_SetGridSlotLocation can not cast to UCanvasPanelSlot ."));
//		return;
//	}
//
//	gridSlot->SetRow(X);
//	gridSlot->SetColumn(Y);
//}
//
//bool UMGLuaUtils::UMG_GetFPointEventScreenSpacePosition(FPointerEvent pointerEvent, FVector * screenLocationXY)
//{
//	if (screenLocationXY) 
//	{
//		screenLocationXY->X = pointerEvent.GetScreenSpacePosition().X;
//		screenLocationXY->Y = pointerEvent.GetScreenSpacePosition().Y;
//		return true;
//	}
//
//	return false;
//}
//
//UUserWidget* UMGLuaUtils::UMG_LoadUI(FString bpPath)
//{
//	//UClass* uclass = LoadClass<T>(NULL, *path);
//	FString fullBpPath = FString("Blueprint'" + bpPath + "_C'");
//
//	UE_LOG(LogTemp, Warning, TEXT("UMGLuaUtils::UMG_LoadUI fullBpPath : %s") , *fullBpPath);
//
//	auto uclass = LoadClass<UUserWidget>(NULL, *fullBpPath);
//
//	if (uclass == nullptr)
//	{
//		UE_LOG(LogTemp, Error, TEXT("UMGLuaUtils::UMG_LoadUI uclass is null ."));
//		return nullptr;
//	}
//
//	UUserWidget* widget = nullptr;
//
//	// using GameInstance as default
//	UGameInstance* GameInstance = nullptr;
//#if WITH_EDITOR
//	UUnrealEdEngine* engine = Cast<UUnrealEdEngine>(GEngine);
//	if (engine && engine->PlayWorld) GameInstance = engine->PlayWorld->GetGameInstance();
//#else
//	UGameEngine* engine = Cast<UGameEngine>(GEngine);
//	if (engine) GameInstance = engine->GameInstance;
//#endif
//
//	widget = CreateWidget<UUserWidget>(GameInstance, uclass);
//
//	return widget;
//}
//
//bool UMGLuaUtils::UMG_UseMouseForTouch()
//{
//	UInputSettings* defaultInputSettings = UInputSettings::StaticClass()->GetDefaultObject<UInputSettings>();
//	if (!defaultInputSettings)
//	{
//		return false;
//	}
//
//	return defaultInputSettings->bUseMouseForTouch;
//}
//
//bool UMGLuaUtils::UMG_PositionIsInside(const FVector2D& Center, const FVector2D& Position, const FVector2D& BoxSize)
//{
//	return
//		Position.X >= Center.X - BoxSize.X * 0.5f &&
//		Position.X <= Center.X + BoxSize.X * 0.5f &&
//		Position.Y >= Center.Y - BoxSize.Y * 0.5f &&
//		Position.Y <= Center.Y + BoxSize.Y * 0.5f;
//}
//
//float UMGLuaUtils::UMG_GetFPS()
//{
//	extern ENGINE_API float GAverageFPS;
//	return GAverageFPS;
//}
//
//void UMGLuaUtils::UMG_ImageExt_SetBrush(UObject* ImageExt, FString Path)
//{
//	if (ImageExt == NULL)
//		return;
//
//	UImageExt* Cast_Image = Cast<UImageExt>(ImageExt);
//	if (Cast_Image == NULL)
//	{
//		UE_LOG(GameLogic, Error, TEXT("Image_SetBrushFromTexture UWidget is not UImage Type, Path:"), *Path);
//		return;
//	}
//
//	if (Path.Len() <= 0)
//		return;
//
//	FString name = TEXT("");
//	int32 Index = 0;
//	if (Path.FindLastChar(TCHAR('/'), Index))
//	{
//		name = Path.Right(Path.Len() - Index - 1);
//	}
//
//	FString FullPath = FString::Printf(TEXT("/Game/%s.%s"), *Path, *name);
//	UPaperSprite* Sprite = Cast<UPaperSprite>(StaticLoadObject(UPaperSprite::StaticClass(), NULL, *FullPath));
//	if (Sprite)
//	{
//		const FVector2D SpriteSize = Sprite->GetSlateAtlasData().GetSourceDimensions();
//
//		FSlateBrush TempBrush;
//		TempBrush.SetResourceObject(Sprite);
//		TempBrush.ImageSize = FVector2D(SpriteSize.X, SpriteSize.Y);
//
//		Cast_Image->SetBrush(TempBrush);
//	}
//	else
//	{
//
//	}
//}
//
//void UMGLuaUtils::UMG_ProgressBar_SetBrush(UObject * ProgressBar, FString Path)
//{
//	if (ProgressBar == NULL)
//		return;
//
//	UProgressBar* Cast_ProgressBar = Cast<UProgressBar>(ProgressBar);
//	if (Cast_ProgressBar == NULL)
//	{
//		UE_LOG(GameLogic, Error, TEXT("Image_SetBrushFromTexture UWidget is not UProgressBar Type, Path:"), *Path);
//		return;
//	}
//
//	if (Path.Len() <= 0)
//		return;
//
//	FString name = TEXT("");
//	int32 Index = 0;
//	if (Path.FindLastChar(TCHAR('/'), Index))
//	{
//		name = Path.Right(Path.Len() - Index - 1);
//	}
//
//	FString FullPath = FString::Printf(TEXT("/Game/%s.%s"), *Path, *name);
//	UPaperSprite* Sprite = Cast<UPaperSprite>(StaticLoadObject(UPaperSprite::StaticClass(), NULL, *FullPath));
//	if (Sprite)
//	{
//		const FVector2D SpriteSize = Sprite->GetSlateAtlasData().GetSourceDimensions();
//
//		FSlateBrush TempBrush;
//		TempBrush.SetResourceObject(Sprite);
//		TempBrush.ImageSize = FVector2D(SpriteSize.X, SpriteSize.Y);
//
//		Cast_ProgressBar->WidgetStyle.SetFillImage(TempBrush);
//	}
//	else
//	{
//
//	}
//}
//
//void UMGLuaUtils::UMG_Text_SetText(UObject* Text, FString Content)
//{
//	if (Text == NULL)
//		return;
//
//	UTextBlock* Cast_Text = Cast<UTextBlock>(Text);
//	if (Cast_Text == NULL)
//	{
//		UE_LOG(GameLogic, Error, TEXT("UMG_Text_SetText UWidget is not UTextBlock Type"));
//		return;
//	}
//
//	Cast_Text->SetText(FText::FromString(Content));
//}
//
//UCanvasPanelSlot* UMGLuaUtils::UMG_GetCanvasPanelSlot(UObject* widget)
//{
//	if (widget == NULL)
//		return NULL;
//
//	UWidget* uWidget = Cast<UWidget>(widget);
//	if (uWidget == NULL)
//	{
//		UE_LOG(GameLogic, Error, TEXT("UMG_GetCanvasPanelSlot widget is not UWidget Type"));
//		return NULL;
//	}
//
//	return  Cast<UCanvasPanelSlot>(uWidget->Slot);
//}
//
//float UMGLuaUtils::UMG_GetScreen()
//{
//	   FVector2D screen = FVector2D(1, 1);
//	   if (GEngine && GEngine->GameViewport)
//	   {
//		   GEngine->GameViewport->GetViewportSize( /*out*/screen);
//		   return screen.X/ screen.Y;
//	   }
//	 return  1;
//}
//
//void UMGLuaUtils::UMG_GetScreenXY(FVector2D * screenXY)
//{
//	FVector2D screen = FVector2D(0, 0);
//	if (GEngine && GEngine->GameViewport && screenXY)
//	{
//		GEngine->GameViewport->GetViewportSize( /*out*/screen);
//
//		screenXY->X = screen.X;
//		screenXY->Y = screen.Y;
//	}
//}
//
//UMaterialInstanceDynamic * UMGLuaUtils::UMG_GetMaterial(FString bpPath , UObject * uobj)
//{
//	UObject* loadObj = StaticLoadObject(UMaterial::StaticClass(), NULL, *bpPath);
//	if (loadObj) 
//	{
//		UMaterialInterface* materialInterfacePtr = Cast<UMaterialInterface>(loadObj);
//		if (materialInterfacePtr) 
//		{
//			return UMaterialInstanceDynamic::Create(materialInterfacePtr, uobj);
//		}
//	}
//
//	return nullptr;
//}
//
//UTexture2D * UMGLuaUtils::UMG_GetTexture(FString Path)
//{
//	UObject* loadObj = StaticLoadObject(UTexture2D::StaticClass(), NULL, *Path);
//
//	if (loadObj)
//	{
//		UTexture2D* tex = Cast<UTexture2D>(loadObj);
//		if (tex)
//		{
//			return tex;
//		}
//	}
//
//	return nullptr;
//}
