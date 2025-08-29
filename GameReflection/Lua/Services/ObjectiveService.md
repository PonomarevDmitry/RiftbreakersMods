---
layout: default
title: ObjectiveService
nav_order: 1
has_children: true
parent: Lua services
---
### CreateObjective
 * ([string](riftbreaker-wiki/docs/reflection/string), [Database](riftbreaker-wiki/docs/reflection/Database), [bool](riftbreaker-wiki/docs/reflection/bool), [string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### FindMatchingObjectiveIdsFromUniqueName
 * ([string](riftbreaker-wiki/docs/reflection/string)): [Vector<unsigned int,StlAllocatorProxy<unsigned int> >](riftbreaker-wiki/docs/reflection/Vector<unsigned int,StlAllocatorProxy<unsigned int> >)
  
### FinishObjectiveByObjectiveId
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [enum ObjectiveStatus](riftbreaker-wiki/docs/reflection/enum ObjectiveStatus)): [void](riftbreaker-wiki/docs/reflection/void)
  
### FinishObjectiveByObjectiveUniqueName
 * ([string](riftbreaker-wiki/docs/reflection/string), [enum ObjectiveStatus](riftbreaker-wiki/docs/reflection/enum ObjectiveStatus)): [void](riftbreaker-wiki/docs/reflection/void)
  
### GetObjectiveColor
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Math::Vector4<float>](riftbreaker-wiki/docs/reflection/Math::Vector4<float>)
  
### GetObjectiveColorType
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetObjectiveDatabase
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [Database*](riftbreaker-wiki/docs/reflection/Database*)
  
### GetObjectiveIdFromObjectiveUniqueName
 * ([string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetObjectiveMarkerBlueprint
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetObjectiveMinimapIcon
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetObjectiveStatus
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [enum ObjectiveStatus](riftbreaker-wiki/docs/reflection/enum ObjectiveStatus)
  
### GetObjectiveUniqueNameFromObjectiveId
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [IdString](riftbreaker-wiki/docs/reflection/IdString)
  
### IsObjectiveExist
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### RemoveObjectiveByObjectiveId
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### RemoveObjectiveByObjectiveUniqueName
 * ([string](riftbreaker-wiki/docs/reflection/string), [bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetObjectiveStatusByObjectiveId
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [enum ObjectiveStatus](riftbreaker-wiki/docs/reflection/enum ObjectiveStatus)): [void](riftbreaker-wiki/docs/reflection/void)
  
