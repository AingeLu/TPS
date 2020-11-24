// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;

public class TPS : ModuleRules
{
	public TPS(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

		PublicIncludePaths.AddRange(new string[] {
			"TPS",
			"TPS/Components",

			"TPS/Ability",
			"TPS/Ability/Abilities",
			"TPS/Ability/Abilities/Tasks",
			"TPS/Ability/Abilities/Targets",

			"TPS/Weapon",
			"TPS/Weapon/Weapons",

			"TPS/Inventory",
			"TPS/Inventory/Items",

			"TPS/UI",
			"TPS/UI/Battle",
		});

		PrivateIncludePaths.AddRange(new string[] {

		});

		PublicIncludePathModuleNames.AddRange( new string[] {

		});

		PrivateIncludePathModuleNames.AddRange(new string[] {

		});

		PublicDependencyModuleNames.AddRange(new string[] {
			"Core",
			"CoreUObject",
			"Engine",
			"InputCore",
			"HeadMountedDisplay",
			"UMG",
			"GameplayAbilities",
			"GameplayTags",
			"GameplayTasks"
		});

		PrivateDependencyModuleNames.AddRange(new string[] {
			"OnlineSubsystem",
			"OnlineSubsystemUtils",
			"Slate",
			"SlateCore",
			"UMG",
			"GameplayAbilities",
			"GameplayTags",
			"GameplayTasks"
		});
	}
}
