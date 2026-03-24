local ok, ep = pcall( require, "lua/entity_patcher.lua" )

local effect_test_autoexec = function()
    if not ok then
        return
    end
    local bp_names = {
        "units/ground/canoptrix_base"
    }

    local function effect( blueprint, bone, delay )
        return {
            blueprint = blueprint,
            bone = bone,
            random_delay = delay or 0
        }
    end

    local map = {
        ["EffectDesc"] = {
            ["EffectGroup"] = {
                ep.t:Group( "time_damage_plasmoid", "group", {
                    {},
                    effect( "effects/enemies_generic_ta/time_damage_plasmoid", "att_death", 3 ),
                }, 0 )
            }
        }
    }
    ep:Apply( bp_names, map )
    ep:LogBlueprintComponents( "units/ground/canoptrix_base", "EffectDesc", true )
end

effect_test_autoexec()
