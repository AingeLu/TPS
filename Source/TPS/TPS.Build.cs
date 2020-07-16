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
			"TPS/UI",
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
			"GameplayAbilities",
			"GameplayTags",
			"GameplayTasks"
		});
	}
}
