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
    end

    if free_build then
        ConsoleService:ExecuteCommand("cheat_free_build 1")
    end

    if no_cost then
        ConsoleService:ExecuteCommand("cheat_unlimited_money 1")
    end

    if give_all_mods then

        RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

            local playerId = evt:GetPlayerId()

            for i=1,5 do

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_cluster_projectiles_extreme_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_cluster_projectiles_enable_extreme_item")

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_penetration_extreme_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_penetration_enable_extreme_item")

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_per_burst_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_per_shot_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_rate_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_cost_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_homing_extreme_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_homing_enable_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_lifesteal_extreme_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_lifesteal_enable_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_range_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_splash_damage_extreme_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_splash_damage_enable_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_stun_chance_extreme_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_stun_chance_enable_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_autoaim_extreme_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_autoaim_enable_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_spread_add_extreme_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_spread_sub_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_critical_chance_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_extreme_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_over_time_extreme_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_over_time_enable_extreme_item")













                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_cluster_projectiles_superior_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_cluster_projectiles_enable_superior_item")

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_penetration_superior_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_penetration_enable_superior_item")

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_per_burst_superior_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_per_shot_superior_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_rate_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_cost_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_homing_superior_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_homing_enable_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_lifesteal_superior_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_lifesteal_enable_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_range_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_splash_damage_superior_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_splash_damage_enable_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_stun_chance_superior_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_stun_chance_enable_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_autoaim_superior_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_autoaim_enable_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_spread_add_superior_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_spread_sub_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_critical_chance_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_superior_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_over_time_superior_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_over_time_enable_superior_item")







        

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_cluster_projectiles_advanced_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_cluster_projectiles_enable_advanced_item")

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_penetration_advanced_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_penetration_enable_advanced_item")

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_per_burst_advanced_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_per_shot_advanced_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_rate_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_cost_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_homing_advanced_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_homing_enable_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_lifesteal_advanced_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_lifesteal_enable_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_range_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_splash_damage_advanced_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_splash_damage_enable_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_stun_chance_advanced_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_stun_chance_enable_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_autoaim_advanced_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_autoaim_enable_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_spread_add_advanced_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_spread_sub_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_critical_chance_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_advanced_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_over_time_advanced_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_over_time_enable_advanced_item")





        

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_cluster_projectiles_standard_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_cluster_projectiles_enable_standard_item")

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_penetration_standard_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_penetration_enable_standard_item")

                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_per_burst_standard_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_per_shot_standard_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_fire_rate_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_cost_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_homing_standard_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_homing_enable_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_lifesteal_standard_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_lifesteal_enable_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_range_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_splash_damage_standard_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_splash_damage_enable_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_stun_chance_standard_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_stun_chance_enable_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_autoaim_standard_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_autoaim_enable_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_spread_add_standard_item")
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_ammo_spread_sub_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_critical_chance_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_standard_item")
                    
                PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_over_time_standard_item")
                --PlayerService:AddItemToInventory(playerId, "items/loot/weapon_mods/mod_damage_over_time_enable_standard_item")
            end

            -- for end

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