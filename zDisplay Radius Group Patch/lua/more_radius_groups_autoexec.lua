require( "lua/utils/table_utils.lua" )
local ok, ep = pcall( require, "lua/entity_patcher.lua" )

local more_radius_groups_autoexec = function()
    if not ok then
        LogService:Log( "Fail to load module [lua/entity_patcher.lua] --> [Radius Group Patch]" )
        ConsoleService:Write( "Fail to load module [lua/entity_patcher.lua] --> [Radius Group Patch]" )
        return
    end
    ep.mod_name = "[Radius Group Patch]"
    if ExecuteOnceGuard( ep.mod_name ) then
        return
    end

    -- orange = "effects/decals/range_circle_harvesting",
    -- blue = "effects/decals/range_circle_shield",
    -- green = "effects/decals/range_circle_repair"

    local function AddLevel( t_in, t_out, key, levels )
        local map = t_out[key]
        t_in[key] = map
        for lvl in Iter( levels ) do
            local new_key = ("%s_lvl_%d"):format( key, lvl )
            t_in[new_key] = map
        end
    end

    local function DisplayRadius( display_radius_group, display_radius_blueprint )
        return {
            string = {
                display_radius_group = display_radius_group,
                display_radius_blueprint = display_radius_blueprint
            }
        }
    end

    local bp_table = {
        ["buildings/defense/tower_lightning"] = {
            ["LuaComponent"] = {
                ["database"] = DisplayRadius( "tower_lightning", "effects/decals/range_circle" )
            }
        },
        ["buildings/defense/tower_alien_influence"] = {
            ["LuaComponent"] = {
                ["database"] = DisplayRadius( "tower_alien_influence", "effects/decals/range_circle_shield" )
            }
        },
        ["buildings/defense/tower_acid_spitter"] = {
            ["LuaComponent"] = {
                ["database"] = DisplayRadius( "tower_acid_spitter", "effects/decals/range_circle_green" )
            }
        },
        ["buildings/defense/tower_shotgun"] = {
            ["LuaComponent"] = {
                ["database"] = DisplayRadius( "tower_shotgun", "effects/decals/range_circle_orange" )
            }
        },
        ["buildings/resources/drone_mine"] = {
            ["LuaComponent"] = {
                ["database"] = DisplayRadius( "drone_mine", "effects/decals/range_circle_harvesting" )
            }
        },
        ["buildings/resources/loot_collector"] = {
            ["LuaComponent"] = {
                ["database"] = DisplayRadius( "loot_collector", "effects/decals/range_circle_harvesting" )
            }
        },
        ["buildings/defense/tower_flamer"] = {
            ["LuaComponent"] = {
                ["database"] = DisplayRadius( nil, "effects/decals/range_circle_red" )
            }
        },
        ["buildings/defense/tower_rockets"] = {
            ["LuaComponent"] = {
                ["database"] = DisplayRadius( "tower_rockets", "effects/decals/range_circle_purple" )
            }
        },
        ["buildings/defense/tower_mine_layer"] = {
            ["LuaComponent"] = {
                ["database"] = DisplayRadius( nil, "effects/decals/range_circle_purple" )
            }
        }
    }
    local patch = {}
    local levels = {
        2,
        3
    }
    for k, _ in pairs( bp_table ) do
        AddLevel( patch, bp_table, k, levels )
    end
    ep:Apply( patch, nil )
end

more_radius_groups_autoexec()

