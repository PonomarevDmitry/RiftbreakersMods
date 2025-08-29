---
layout: default
title: ItemService
nav_order: 1
has_children: true
parent: Lua services
---
### ActivateCooldown
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### AddHealthLink
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### AddItemToInventory
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### AddSpeedModifier
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### CanActivateItemSlot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [string](riftbreaker-wiki/docs/reflection/string)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### CanFitResourceGiver
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### CanPlace
 * ([float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### ChangeRegeneration
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ClearNewItemMark
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ClearNewItemsMarks
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### EquipItemInSlot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### FindClosestTreasureInRadius
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [enum DiscoverableLevel](riftbreaker-wiki/docs/reflection/enum DiscoverableLevel), [string](riftbreaker-wiki/docs/reflection/string), [string](riftbreaker-wiki/docs/reflection/string)): [struct std::pair<unsigned int,float>](riftbreaker-wiki/docs/reflection/struct std::pair<unsigned int,float>)
  
### FlyItemToInventory
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### GetActivationStatus
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### GetActiveCooldownLeft
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetAllItemsBlueprints
 * (): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetAllItemsBlueprintsByType
 * ([string](riftbreaker-wiki/docs/reflection/string)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetBlueprintOfItem
 * ([string](riftbreaker-wiki/docs/reflection/string)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetCooldown
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetEquippedItem
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetEquippedItemsInSlot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [Vector<Entity,StlAllocatorProxy<Entity> >](riftbreaker-wiki/docs/reflection/Vector<Entity,StlAllocatorProxy<Entity> >)
  
### GetEquippedPresentationItem
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetFirstItemForBlueprint
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetItemCount
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [int](riftbreaker-wiki/docs/reflection/int)
  
### GetItemCreator
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetItemIcon
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetItemLevel
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetItemName
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetItemSlot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetItemSlot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetItemSubSlot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [int](riftbreaker-wiki/docs/reflection/int)
  
### GetItemSubType
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetItemType
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetOwner
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### GetRandomItemByType
 * ([string](riftbreaker-wiki/docs/reflection/string), [enum WeaponRarity](riftbreaker-wiki/docs/reflection/enum WeaponRarity)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetResourceBlueprint
 * ([string](riftbreaker-wiki/docs/reflection/string)): [string](riftbreaker-wiki/docs/reflection/string)
  
### HasActiveCooldown
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### HasAmmoToShoot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### InteractWithEntity
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### IsItemReference
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsSameSubTypeEquipped
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### PickUpItem
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### RemoveHealthLink
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### RemoveSpeedModifier
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ResetCooldown
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ResetItemCooldownWeaponBased
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### RevealHiddenEntity
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ScanEntity
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ScanEntityByPlayer
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetActivationStatus
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetInvisible
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetItemCreator
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetItemReference
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SpawnLoot
 * ([Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>), [string](riftbreaker-wiki/docs/reflection/string), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### SpawnLoot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [string](riftbreaker-wiki/docs/reflection/string)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### SpawnLoot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [unsigned __int64](riftbreaker-wiki/docs/reflection/unsigned __int64), [float](riftbreaker-wiki/docs/reflection/float), [Database*](riftbreaker-wiki/docs/reflection/Database*)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### SpawnLoot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [unsigned __int64](riftbreaker-wiki/docs/reflection/unsigned __int64), [Database*](riftbreaker-wiki/docs/reflection/Database*)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SpawnLoot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [unsigned __int64](riftbreaker-wiki/docs/reflection/unsigned __int64)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SpawnLoot
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SpawnLootWithPower
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [string](riftbreaker-wiki/docs/reflection/string), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### StopUsingEquippedItem
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string), [bool](riftbreaker-wiki/docs/reflection/bool)): [void](riftbreaker-wiki/docs/reflection/void)
  
### StopUsingEquippedItem
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
### TryEquipItemInEmptySlot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### TryEquipItemInSlot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string), [int](riftbreaker-wiki/docs/reflection/int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### UseEquippedItem
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [string](riftbreaker-wiki/docs/reflection/string)): [void](riftbreaker-wiki/docs/reflection/void)
  
