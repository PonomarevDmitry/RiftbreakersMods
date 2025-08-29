---
layout: default
title: WeaponService
nav_order: 1
has_children: true
parent: Lua services
---
### DropObject
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ForceStopMeleeAttack
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### GetCurrentMeleeAttackId
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [int](riftbreaker-wiki/docs/reflection/int)
  
### GetMeleeComboCount
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### GetMirrorMeshName
 * ([char const*](riftbreaker-wiki/docs/reflection/char const*)): [string](riftbreaker-wiki/docs/reflection/string)
  
### GetSameWeaponEquipped
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### GetTurretMaxRange
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetTurretTarget
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### GetWeaponDps
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetWeaponFireRate
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [float](riftbreaker-wiki/docs/reflection/float)
  
### GetWeaponReloadProgress
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [float](riftbreaker-wiki/docs/reflection/float)
  
### HasAmmoToShoot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsCharging
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsInterruptBlocked
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsMeleeAttackButtonPressed
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [char const*](riftbreaker-wiki/docs/reflection/char const*)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsMeleeDealingDamage
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsMeleeReady
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### IsShooting
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### OnMeleeAttackButtonPressed
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [char const*](riftbreaker-wiki/docs/reflection/char const*), [int](riftbreaker-wiki/docs/reflection/int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### OnMeleeAttackButtonReleased
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [char const*](riftbreaker-wiki/docs/reflection/char const*)): [void](riftbreaker-wiki/docs/reflection/void)
  
### RequestProjectileExplosion
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### RotateWeaponMuzzleToTarget
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SetCustomTarget
 * ([Entity](riftbreaker-wiki/docs/reflection/Entity), [Entity](riftbreaker-wiki/docs/reflection/Entity)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ShootAmmoOnTargetOrigin
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [IdString](riftbreaker-wiki/docs/reflection/IdString)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ShootArtilleryOnTargetOrigin
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [IdString](riftbreaker-wiki/docs/reflection/IdString), [IdString](riftbreaker-wiki/docs/reflection/IdString)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### ShootEntityOnTargetOrigin
 * ([Math::Vector3<float>](riftbreaker-wiki/docs/reflection/Math::Vector3<float>), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [IdString](riftbreaker-wiki/docs/reflection/IdString), [IdString](riftbreaker-wiki/docs/reflection/IdString)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### ShootEntityOnTargetOrigin
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [IdString](riftbreaker-wiki/docs/reflection/IdString), [IdString](riftbreaker-wiki/docs/reflection/IdString)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### ShootGranadeOnTargetOrigin
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [IdString](riftbreaker-wiki/docs/reflection/IdString), [IdString](riftbreaker-wiki/docs/reflection/IdString)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ShootOnce
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ShootOnce
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [int](riftbreaker-wiki/docs/reflection/int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ShootProjectileOnTargetOrigin
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [IdString](riftbreaker-wiki/docs/reflection/IdString)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### ShootSpikesOnTargetOrigin
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float), [IdString](riftbreaker-wiki/docs/reflection/IdString)): [void](riftbreaker-wiki/docs/reflection/void)
  
### SpawnDangerMarker
 * ([IdString](riftbreaker-wiki/docs/reflection/IdString), [Math::Vector3<float> const&](riftbreaker-wiki/docs/reflection/Math::Vector3<float> const&), [float](riftbreaker-wiki/docs/reflection/float), [float](riftbreaker-wiki/docs/reflection/float)): [Entity](riftbreaker-wiki/docs/reflection/Entity)
  
### StartCharge
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### StartCharge
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [int](riftbreaker-wiki/docs/reflection/int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### StartShoot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### StartShoot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [int](riftbreaker-wiki/docs/reflection/int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### StopCharge
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### StopShoot
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### ThrowGrenade
 * ([IdString](riftbreaker-wiki/docs/reflection/IdString), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [IdString](riftbreaker-wiki/docs/reflection/IdString)): [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)
  
### ThrowObject
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### TryMeleeAttack
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [char const*](riftbreaker-wiki/docs/reflection/char const*)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### TryMeleeAttack
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [char const*](riftbreaker-wiki/docs/reflection/char const*), [int](riftbreaker-wiki/docs/reflection/int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### TryMeleeMirrorAttack
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [char const*](riftbreaker-wiki/docs/reflection/char const*)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### TryMeleeMirrorAttack
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [char const*](riftbreaker-wiki/docs/reflection/char const*), [int](riftbreaker-wiki/docs/reflection/int)): [bool](riftbreaker-wiki/docs/reflection/bool)
  
### UpdateGrenadeAiming
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [Math::Vector3<float> const&](riftbreaker-wiki/docs/reflection/Math::Vector3<float> const&)): [void](riftbreaker-wiki/docs/reflection/void)
  
### UpdateGrenadeAiming
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
### UpdateGrenadeAiming
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [float](riftbreaker-wiki/docs/reflection/float)): [void](riftbreaker-wiki/docs/reflection/void)
  
### UpdateWeaponStatComponent
 * ([unsigned int](riftbreaker-wiki/docs/reflection/unsigned int), [unsigned int](riftbreaker-wiki/docs/reflection/unsigned int)): [void](riftbreaker-wiki/docs/reflection/void)
  
