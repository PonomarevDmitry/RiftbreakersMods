local M = {}

-- ==== For EffectDesc ====
function M:Effect( name, effect )
    return {
        name = name,
        data = effect
    }
end

function M:Group( name, look, effects, enable )
    return {
        name = name,
        look = look,
        data = {
            group = look == "group" and name or nil,
            enabled = enable,
            Effects = effects
        }
    }
end

function M:Random( name, effects )
    return {
        name = name,
        data = {
            Effects = effects
        }
    }
end

function M:DroneSpot( amount, visible, blueprint )
    return {
        database = {
            int = (amount or visible) and {
                drone_per_spot = amount,
                drone_visible_on_spot = visible
            } or nil,
            string = blueprint and {
                drone_blueprint = blueprint
            } or nil
        }
    }
end

function M:Regeneration( regeneration, regeneration_cooldown, effect, effect_end )
    return {
        regeneration = regeneration,
        regeneration_cooldown = regeneration_cooldown,
        regeneration_effect = effect,
        regeneration_end_effect = effect_end or effect
    }
end

function M:WeaponVecItem( t, stat, min_max, default_max, stat_feature, features )
    t[stat] = {
        ["min=max"] = min_max,
        ["default=max"] = default_max,
        ["stat_features-"] = stat_feature,
        ["default=max_ifnot"] = features
    }
end

function M:PipeComponent( str )
    return {
        PipeComponent = {
            attachment = str
        }
    }
end

-- for Shapes
function M:BoxShape( x, y, z, position )
    return {
        x = x,
        y = y,
        z = z,
        position = position
    }
end

-- for Mech InventoryComponent 
function M:MechInventory( name, subslots_count, allow_types )
    return {
        name = name,
        subslots_count = subslots_count or 1,
        allow_types = allow_types
    }
end

-- for Research Tree
function M:ResearchAward( blueprint, is_visible )
    if is_visible == nil then
        is_visible = true
    end

    return {
        blueprint = blueprint,
        is_visible = is_visible
    }
end

function M:Node( research_name, research_awards )
    return {
        research_name = research_name,
        research_awards = research_awards
    }
end

return M

