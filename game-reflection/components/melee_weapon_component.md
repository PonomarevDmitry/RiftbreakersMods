---
layout: default
title: MeleeWeaponComponent
has_children: false
parent: Component
grand_parent: Game Reflection
---
# MeleeWeaponComponent
Description 

## Fields

| Type | Name |
|:----------|:--------------|
| Container< [MeleeAttackRequest](/riftbreaker-wiki/docs/game-reflection/classes/melee_attack_request/) > | attack_request_vec |
| Container< [MeleeDamageRequest](/riftbreaker-wiki/docs/game-reflection/classes/melee_damage_request/) > | damage_request_vec |
| [EntityBlueprintHolder](/riftbreaker-wiki/docs/game-reflection/components/entity_blueprint_holder/) | blueprint |
| [Entity](/riftbreaker-wiki/docs/game-reflection/classes/entity/) | owner |
| [float](/riftbreaker-wiki/docs/game-reflection/components/float/) | affector_time |
| [float](/riftbreaker-wiki/docs/game-reflection/components/float/) | affector_power |
| [bool](/riftbreaker-wiki/docs/game-reflection/components/bool/) | button_holded |
| [uint](/riftbreaker-wiki/docs/game-reflection/components/uint/) | button_click_counter |
| Container< [MeleeAttackRequest](/riftbreaker-wiki/docs/game-reflection/classes/melee_attack_request/) > | pending_removal_attack_vec |
| Container< [MeleeDamageRequest](/riftbreaker-wiki/docs/game-reflection/classes/melee_damage_request/) > | pending_removal_damage_vec |

