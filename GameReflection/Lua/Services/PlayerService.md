---
layout: default
title: PlayerService
nav_order: 1
has_children: true
parent: Lua services
---
### AddGlobalAward
 * ([string](riftbreaker-wiki/docs/reflection/string), [bool](riftbreaker-wiki/docs/reflection/bool), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### AddItemToInventory
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### AddItemsByTypeToInventory
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### AddResourceAmount
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string), [float](riftbreaker-wiki/docs/reflection/float), [bool](riftbreaker-wiki/docs/reflection/bool)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### AddResourceAmount
 * ([string](riftbreaker-wiki/docs/reflection/string), [float](riftbreaker-wiki/docs/reflection/float), [bool](riftbreaker-wiki/docs/reflection/bool)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### AddResourceAmount
 * ([string](riftbreaker-wiki/docs/reflection/string), [float](riftbreaker-wiki/docs/reflection/float)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### BlockAction
 * ([string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### BuildBuildingAtSpot
 * ([string](riftbreaker-wiki/docs/reflection/string), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### CalculateJumpTrajectory
 * ([float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>), [Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>), [float](riftbreaker-wiki/docs/reflection/float)): [struct std::pair<Math::Vector3<float>,float>](riftbreaker-wiki/docs/reflection/struct std::pair<Math::Vector3<float>,float>)
  
### ChangePlayerEquipmentVisibility
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### CreateFakePlayer
 * ([string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### CreateFakePlayer
 * (): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### CreatePlayerBot
 * ([string](riftbreaker-wiki/docs/reflection/string), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [struct TeamId](riftbreaker-wiki/docs/reflection/struct TeamId)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### CreatePlayerTeam
 * ([string](riftbreaker-wiki/docs/reflection/string), [bool](riftbreaker-wiki/docs/reflection/bool)): [struct TeamId](riftbreaker-wiki/docs/reflection/struct TeamId)
  
### DisableAllBuildings
 * (): [void](riftbreaker-wiki/docs/reflection/void)
  
### DisableBuildMode
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### DisableBuilding
 * ([string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### DropItem
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### EnableAllBuildings
 * (): [void](riftbreaker-wiki/docs/reflection/void)
  
### EnableBuildMode
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### EnableBuilding
 * ([string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### EnableResearch
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### EnableResearch
 * ([string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### EquipItemInSlot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### FindPositionForJump
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float)): [struct std::pair<bool,Math::Vector3<float> >](riftbreaker-wiki/docs/reflection/struct std::pair<bool,Math::Vector3<float> >)
  
### FindPositionForTeleport
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>), [float](riftbreaker-wiki/docs/reflection/float)): [struct std::pair<bool,Math::Vector3<float> >](riftbreaker-wiki/docs/reflection/struct std::pair<bool,Math::Vector3<float> >)
  
### GetAimDir
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>)
  
### GetAllEquippedItemsInSlot
 * ([string](riftbreaker-wiki/docs/reflection/string), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Vector<Entity,StlAllocatorProxy<Entity> >](riftbreaker-wiki/docs/reflection/Vector<Entity,StlAllocatorProxy<Entity> >)
  
### GetAllPlayers
 * (): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetAmmoList
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetAmmoList
 * (): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetConnectedPlayers
 * (): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetConnectedPlayersFromTeam
 * ([struct TeamId](riftbreaker-wiki/docs/reflection/struct TeamId)): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetEnergyLvl
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetFamiliarityLevel
 * ([string](riftbreaker-wiki/docs/reflection/string), [string](riftbreaker-wiki/docs/reflection/string)): [int](riftbreaker-wiki/docs/reflection/int)
  
### GetGlobalPlayerEntity
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### GetGlobalResourcesList
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetGlobalResourcesList
 * (): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetGlobalTeamEntity
 * ([struct TeamId](riftbreaker-wiki/docs/reflection/struct TeamId)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### GetItemNumber
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetLeadingPlayer
 * (): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetOrCreateGlobalDatabase
 * ([string](riftbreaker-wiki/docs/reflection/string)): [Database*](riftbreaker-wiki/docs/reflection/Database*)
  
### GetPadTriggerIndexForEquipmentSlot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [Optional<int>](riftbreaker-wiki/docs/reflection/Optional<int>)
  
### GetPickupRange
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetPlayerByMech
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetPlayerControlledEnt
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### GetPlayerForEntity
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetPlayerName
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetPlayerSelector
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### GetPlayerSpawnPoint
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### GetPlayerTeam
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [struct TeamId](riftbreaker-wiki/docs/reflection/struct TeamId)
  
### GetPlayersFromTeam
 * ([struct TeamId](riftbreaker-wiki/docs/reflection/struct TeamId)): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetPlayersMechs
 * (): [Vector<Entity,StlAllocatorProxy<Entity> >](riftbreaker-wiki/docs/reflection/Vector<Entity,StlAllocatorProxy<Entity> >)
  
### GetResearchNameFromResearchId
 * ([string](riftbreaker-wiki/docs/reflection/string)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetResearchesAvailableToUnlockList
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [bool](riftbreaker-wiki/docs/reflection/bool)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetResearchesAvailableToUnlockList
 * ([bool](riftbreaker-wiki/docs/reflection/bool)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetResourceAmount
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetResourceAmount
 * ([string](riftbreaker-wiki/docs/reflection/string)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetResourceIncome
 * ([string](riftbreaker-wiki/docs/reflection/string)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetResourceIncome
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetResourceLimit
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetResourceLimit
 * ([string](riftbreaker-wiki/docs/reflection/string)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetUnlockedResearchesList
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetUnlockedResearchesList
 * (): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetVelocity
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>)
  
### GetWeaponLookPoint
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>)
  
### HarvestResource
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### HasEmptyEquipmentSlots
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### HasGlobalAward
 * ([string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### HasItem
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### HasSimilarEquipped
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### HighlightResearch
 * ([string](riftbreaker-wiki/docs/reflection/string), [bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### IncreaseEnergyLvl
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### IncreaseFamilyInfoLvl
 * ([string](riftbreaker-wiki/docs/reflection/string), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### IsActionActive
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsCraftingEnabled
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsCraftingEnabled
 * (): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsInBuildMode
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsInFighterMode
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsInSelectorMode
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsPlayerVoteInProgress
 * (): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsResearchEnabled
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsResearchEnabled
 * (): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsResearchUnlocked
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsResearchUnlocked
 * ([string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsResourceUnlocked
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsResourceUnlocked
 * ([string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### MovePlayer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>)): [void](riftbreaker-wiki/docs/reflection/void)
  
### OperateActionMapper
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### RemoveGlobalDatabase
 * ([string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### RemovePlayerBot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ResetDeathStats
 * (): [void](riftbreaker-wiki/docs/reflection/void)
  
### ResetEnergyLvl
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ResetPadTriggerMode
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [int](riftbreaker-wiki/docs/reflection/int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ScaleTeamBasicResources
 * ([struct TeamId](riftbreaker-wiki/docs/reflection/struct TeamId), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ScaleTeamGlobalResources
 * ([struct TeamId](riftbreaker-wiki/docs/reflection/struct TeamId), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetActionBlocking
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [string](riftbreaker-wiki/docs/reflection/string), [bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetAimDir
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetEnergyLvl
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetMoveDir
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetPadHapticFeedback
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string), [bool](riftbreaker-wiki/docs/reflection/bool), [int](riftbreaker-wiki/docs/reflection/int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetPadTriggerFeedbackMode
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [int](riftbreaker-wiki/docs/reflection/int), [unsigned char](riftbreaker-wiki/docs/reflection/unsigned char), [unsigned char](riftbreaker-wiki/docs/reflection/unsigned char)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetPadTriggerVibrationMode
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [int](riftbreaker-wiki/docs/reflection/int), [unsigned char](riftbreaker-wiki/docs/reflection/unsigned char), [unsigned char](riftbreaker-wiki/docs/reflection/unsigned char), [unsigned char](riftbreaker-wiki/docs/reflection/unsigned char)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetPadTriggerWeaponMode
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [int](riftbreaker-wiki/docs/reflection/int), [unsigned char](riftbreaker-wiki/docs/reflection/unsigned char), [unsigned char](riftbreaker-wiki/docs/reflection/unsigned char), [unsigned char](riftbreaker-wiki/docs/reflection/unsigned char)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetPickupRange
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetPlayerBlueprint
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetPlayerTeam
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [struct TeamId](riftbreaker-wiki/docs/reflection/struct TeamId)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetPlayerTeamSpawnPoint
 * ([struct TeamId](riftbreaker-wiki/docs/reflection/struct TeamId), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetResourceAmount
 * ([string](riftbreaker-wiki/docs/reflection/string), [float](riftbreaker-wiki/docs/reflection/float), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetTempPlayerSpawnPoint
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetWeaponLookPoint
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>)): [void](riftbreaker-wiki/docs/reflection/void)
  
### StartJump
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### StopPadHapticFeedback
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### TeleportPlayer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### TeleportPlayerByOffset
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>)): [void](riftbreaker-wiki/docs/reflection/void)
  
### TryEquipItemInSlot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string), [int](riftbreaker-wiki/docs/reflection/int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### UnBlockAction
 * ([string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### UnBlockAllActions
 * (): [void](riftbreaker-wiki/docs/reflection/void)
  
### UnhideResearch
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### UnhideResearch
 * ([string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### UnlockLoot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### UnlockLootBlueprint
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### UnlockResearch
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### UnlockResearch
 * ([string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
