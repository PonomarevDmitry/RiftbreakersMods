--LogService:Log("Pi_is_fun_Autoexec")
--ConsoleService:ExecuteCommand("debug_triggers 1")

if not cheat_init then --Make all one-time
    cheat_init = true
    
    --CONTROLS
    map_cheats   = false
    ammo_cheat   = false
    free_build   = false
    no_cost 	 = false
    give_all_mods = false
    debug_rifle = false
    --all_tech = false
    
    if not ( CampaignService:GetCurrentCampaignType() == "survival" and DifficultyService:GetCurrentDifficultyName() == "sandbox" ) then
        return
    end
    
    if ammo_cheat then
        ConsoleService:ExecuteCommand("cheat_unlimited_ammo 1")
    end

    if map_cheats then
        ConsoleService:ExecuteCommand("cheat_minimap_teleport_on_click 1")
    end

    if map_cheats then 
        ConsoleService:ExecuteCommand("cheat_reveal_minimap 1")
    else
        ConsoleService:ExecuteCommand("cheat_reveal_minimap 0")
    end
        
    if free_build then
        ConsoleService:ExecuteCommand("cheat_free_build 1")
    end
        
    if no_cost then
        ConsoleService:ExecuteCommand("cheat_unlimited_money 1")
    end
        
    if give_all_mods then

        RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

            for i=1,3 do --give player 3 of every extreme weapon mod

                local playerId = evt:GetPlayerId()

                PlayerService:AddItemToInventory(playerId, "items/weapons/laser_sword_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_cluster_projectiles_enable_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_cluster_projectiles_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_penetration_enable_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_penetration_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_per_burst_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_per_shot_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_rate_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_cost_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_homing_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_homing_enable_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_lifesteal_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_lifesteal_enable_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_range_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_splash_damage_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_splash_damage_enable_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_stun_chance_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_stun_chance_enable_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_autoaim_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_autoaim_enable_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_spread_add_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_spread_sub_extreme_item")
            end
        end)
    end
        
    if all_tech then
        RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)
            ConsoleService:ExecuteCommand("cheat_finish_all_research")
        end)
    end
        
    if debug_rifle then
        RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

            local playerId = evt:GetPlayerId()

            PlayerService:AddItemToInventory(playerId, "items/weapons/debug_rifle_item")
            PlayerService:AddItemToInventory(playerId, "items/weapons/debug_rifle_advanced_item")
            PlayerService:AddItemToInventory(playerId, "items/weapons/debug_rifle_superior_item")
            PlayerService:AddItemToInventory(playerId, "items/weapons/debug_rifle_extreme_item")

            --  PlayerService:AddItemToInventory(0, "items/weapons/debug_rifle_item")
            --  PlayerService:AddItemToInventory(0, "items/weapons/debug_rifle_advanced_item")
            --  PlayerService:AddItemToInventory(0, "items/weapons/debug_rifle_superior_item")
            --  PlayerService:AddItemToInventory(0, "items/weapons/debug_rifle_extreme_item")
        end)
            
    end
        
    if free_build or no_cost then
        ConsoleService:ExecuteCommand("building_speed_multiplier 0")
        ConsoleService:ExecuteCommand("cheat_unlock_all 1")
    end
end