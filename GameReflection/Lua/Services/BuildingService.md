---
layout: default
title: BuildingService
nav_order: 1
has_children: true
parent: Lua services
---
### AddConverterCostModifier
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### AttachGuiTimer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float), [bool](riftbreaker-wiki/docs/reflection/bool)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### AttachGuiTimerWithMaterial
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float), [bool](riftbreaker-wiki/docs/reflection/bool), [string](riftbreaker-wiki/docs/reflection/string)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### AttachMissingResourceIcon
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [bool](riftbreaker-wiki/docs/reflection/bool)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### BlinkBuilding
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### BlinkBuildingSelector
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### CalculateBuildTime
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [float](riftbreaker-wiki/docs/reflection/float)
  
### CanAffordBuilding
 * ([string](riftbreaker-wiki/docs/reflection/string), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### CanAffordRepair
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### CanAffordRepair
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### CanAffordUpgrade
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### CanBuildBuilding
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### CanBuildFloor
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### CanUpgrade
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### CheckAndAddAllCompressedresources
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### CheckAndFixBuildingConnection
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### CheckGhostBuildingStatus
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Transform<float>](riftbreaker-wiki/docs/reflection/Math::Transform<float>), [string](riftbreaker-wiki/docs/reflection/string), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Optional<BuildInfo>](riftbreaker-wiki/docs/reflection/Optional<BuildInfo>)
  
### CheckGhostFloorStatus
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Transform<float>](riftbreaker-wiki/docs/reflection/Math::Transform<float>), [string](riftbreaker-wiki/docs/reflection/string)): [Optional<BuildInfo>](riftbreaker-wiki/docs/reflection/Optional<BuildInfo>)
  
### ClearDecompressor
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ClearResourceGraphs
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### CreateFloraCultivatorComponent
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [string](riftbreaker-wiki/docs/reflection/string)
  
### CreateGuiTimer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float), [bool](riftbreaker-wiki/docs/reflection/bool), [bool](riftbreaker-wiki/docs/reflection/bool)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### CreateGuiTimer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float), [bool](riftbreaker-wiki/docs/reflection/bool)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### CreateGuiTimer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### CreateGuiTimerWithMaterial
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float), [bool](riftbreaker-wiki/docs/reflection/bool), [string](riftbreaker-wiki/docs/reflection/string)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### CreateRadarComponent
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### DecreaseBuildingLimits
 * ([string](riftbreaker-wiki/docs/reflection/string), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### DecreaseEnergyAmount
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### DisableBuilding
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### DisablePhysics
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### DisableSellOption
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### EnableBuilding
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### EnableDiscoverableSystem
 * ([bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### EnablePhysics
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### EnableSellOption
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### FindBaseBuilding
 * ([string](riftbreaker-wiki/docs/reflection/string)): [Optional<TypeValueView>](riftbreaker-wiki/docs/reflection/Optional<TypeValueView>)
  
### FindEnergyRadius
 * ([string](riftbreaker-wiki/docs/reflection/string)): [Optional<float>](riftbreaker-wiki/docs/reflection/Optional<float>)
  
### FindLowUpgrade
 * ([string](riftbreaker-wiki/docs/reflection/string)): [string](riftbreaker-wiki/docs/reflection/string)
  
### FindPathByBlueprint
 * ([Math::Transform<float> const&](riftbreaker-wiki/docs/reflection/Math::Transform<float> const&), [Math::Transform<float> const&](riftbreaker-wiki/docs/reflection/Math::Transform<float> const&), [string](riftbreaker-wiki/docs/reflection/string)): [Vector<Math::Vector3<float>,StlAllocatorProxy<Math::Vector3<float> > >](riftbreaker-wiki/docs/reflection/Vector<Math::Vector3<float>,StlAllocatorProxy<Math::Vector3<float> > >)
  
### FindSpotsByDistance
 * ([Math::Transform<float> const&](riftbreaker-wiki/docs/reflection/Math::Transform<float> const&), [Math::Transform<float> const&](riftbreaker-wiki/docs/reflection/Math::Transform<float> const&), [float](riftbreaker-wiki/docs/reflection/float), [string](riftbreaker-wiki/docs/reflection/string)): [Vector<Math::Transform<float>,StlAllocatorProxy<Math::Transform<float> > >](riftbreaker-wiki/docs/reflection/Vector<Math::Transform<float>,StlAllocatorProxy<Math::Transform<float> > >)
  
### FlyCubesToBuilding
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [bool](riftbreaker-wiki/docs/reflection/bool), [bool](riftbreaker-wiki/docs/reflection/bool)): [struct std::pair<Entity,Entity>](riftbreaker-wiki/docs/reflection/struct std::pair<Entity,Entity>)
  
### GetBuildCosts
 * ([string](riftbreaker-wiki/docs/reflection/string), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetBuildModeActionMapperName
 * (): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetBuildingBuildMode
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetBuildingByBpCount
 * ([string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetBuildingByNameCount
 * ([string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetBuildingByTypeCount
 * ([string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetBuildingCategory
 * ([string](riftbreaker-wiki/docs/reflection/string)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetBuildingDesc
 * ([string](riftbreaker-wiki/docs/reflection/string)): [Optional<TypeValueView>](riftbreaker-wiki/docs/reflection/Optional<TypeValueView>)
  
### GetBuildingErases
 * ([string](riftbreaker-wiki/docs/reflection/string)): [Vector<StringHash,StlAllocatorProxy<StringHash> >](riftbreaker-wiki/docs/reflection/Vector<StringHash,StlAllocatorProxy<StringHash> >)
  
### GetBuildingGridSize
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>)
  
### GetBuildingLastLevel
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetBuildingLevel
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [int](riftbreaker-wiki/docs/reflection/int)
  
### GetBuildingMode
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [enum BuildingMode](riftbreaker-wiki/docs/reflection/enum BuildingMode)
  
### GetBuildingName
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetBuildingOverrides
 * ([string](riftbreaker-wiki/docs/reflection/string)): [Vector<StringHash,StlAllocatorProxy<StringHash> >](riftbreaker-wiki/docs/reflection/Vector<StringHash,StlAllocatorProxy<StringHash> >)
  
### GetBuildingType
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetEnergyAmount
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetFinishedBuildingByBp
 * ([char const*](riftbreaker-wiki/docs/reflection/char const*)): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetFinishedBuildingByBp
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [char const*](riftbreaker-wiki/docs/reflection/char const*), [float](riftbreaker-wiki/docs/reflection/float)): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetFinishedBuildingByName
 * ([char const*](riftbreaker-wiki/docs/reflection/char const*)): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetFinishedBuildingByName
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [char const*](riftbreaker-wiki/docs/reflection/char const*), [float](riftbreaker-wiki/docs/reflection/float)): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetFinishedBuildingByType
 * ([char const*](riftbreaker-wiki/docs/reflection/char const*)): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetFinishedBuildingByType
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [char const*](riftbreaker-wiki/docs/reflection/char const*), [float](riftbreaker-wiki/docs/reflection/float)): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetGeothermalPowerModificator
 * (): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetMeshEntity
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### GetMissingResources
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Set<StringHash,struct std::less<StringHash>,StlAllocatorProxy<StringHash> >](riftbreaker-wiki/docs/reflection/Set<StringHash,struct std::less<StringHash>,StlAllocatorProxy<StringHash> >)
  
### GetPipeResourceClaimed
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetProducedResources
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Vector<StringHash,StlAllocatorProxy<StringHash> >](riftbreaker-wiki/docs/reflection/Vector<StringHash,StlAllocatorProxy<StringHash> >)
  
### GetRepairCosts
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetResourceConnected
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetResourceProduction
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [char const*](riftbreaker-wiki/docs/reflection/char const*)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetResourceVeins
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [char const*](riftbreaker-wiki/docs/reflection/char const*)): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### GetSellResourceAmount
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetSolarPowerModificator
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetSolarPowerModificator
 * (): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetStorageResources
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Vector<StringHash,StlAllocatorProxy<StringHash> >](riftbreaker-wiki/docs/reflection/Vector<StringHash,StlAllocatorProxy<StringHash> >)
  
### GetUpgradeCosts
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetWindPowerModificator
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetWindPowerModificator
 * (): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetWorkingTime
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Optional<float>](riftbreaker-wiki/docs/reflection/Optional<float>)
  
### HasBuildingWithBp
 * ([string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IncreaseBuildingLimits
 * ([string](riftbreaker-wiki/docs/reflection/string), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### IsBuildingAvailable
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsBuildingAvailable
 * ([string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsBuildingFinished
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsBuildingPowered
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsBuildingSpaceOccupied
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsFloor
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsOnResource
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsPlayerWorking
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsResourceConnected
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsResourceSupplied
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsSameConnection
 * ([luabind::object const&](riftbreaker-wiki/docs/reflection/luabind::object const&), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsSpaceOccupied
 * ([Math::Vector3<float> const&](riftbreaker-wiki/docs/reflection/Math::Vector3<float> const&), [string](riftbreaker-wiki/docs/reflection/string), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsWorking
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### OperateBuildCosts
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [luabind::object const&](riftbreaker-wiki/docs/reflection/luabind::object const&)): [void](riftbreaker-wiki/docs/reflection/void)
  
### OperateBuildingStorage
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### OperateRepairCosts
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [luabind::object const&](riftbreaker-wiki/docs/reflection/luabind::object const&)): [void](riftbreaker-wiki/docs/reflection/void)
  
### OperateSellCosts
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [luabind::object const&](riftbreaker-wiki/docs/reflection/luabind::object const&)): [void](riftbreaker-wiki/docs/reflection/void)
  
### OperateUpgradeCosts
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [luabind::object const&](riftbreaker-wiki/docs/reflection/luabind::object const&)): [void](riftbreaker-wiki/docs/reflection/void)
  
### PauseGuiTimer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### PayRepairCosts
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### RemoveConverterCostModifier
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### RemoveGuiTimer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### RemoveResourceConverterEfficientyModificator
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### RepairBuilding
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ReplaceProductionByCompressedItem
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [string](riftbreaker-wiki/docs/reflection/string), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ResumeGuiTimer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetBuildingLastLevel
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetBuildingLastLevel
 * ([string](riftbreaker-wiki/docs/reflection/string), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetGuiTimer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetGuiTimerLimit
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetResourceConverterEfficientyModificator
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ShouldBuildFloor
 * ([Math::Transform<float> const&](riftbreaker-wiki/docs/reflection/Math::Transform<float> const&), [Math::Transform<float> const&](riftbreaker-wiki/docs/reflection/Math::Transform<float> const&), [float](riftbreaker-wiki/docs/reflection/float)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### SpawnCultivatorSaplingsAt
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>)): [Vector<Entity,StlAllocatorProxy<Entity> >](riftbreaker-wiki/docs/reflection/Vector<Entity,StlAllocatorProxy<Entity> >)
  
### TryDecreaseResourceByEntity
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [float](riftbreaker-wiki/docs/reflection/float)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### UnlockBuilding
 * ([string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
