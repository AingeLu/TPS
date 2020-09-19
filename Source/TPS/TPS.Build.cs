// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;

public class TPS : ModuleRules
{
	public TPS(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

		PublicIncludePaths.AddRange(new string[] {
			"TPS/Game",

			"TPS/Player",
			"TPS/Player/Components",
			"TPS/Player/GameplayAbilities",
			"TPS/Player/GameplayAbilities/Abilities",
			"TPS/Player/GameplayAbilities/Abilities/Tasks",

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
			"UMG",
			"GameplayAbilities",
			"GameplayTags",
			"GameplayTasks"
		});
	}
}
