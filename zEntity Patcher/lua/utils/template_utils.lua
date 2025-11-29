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
            int = amount and {
                drone_per_spot = amount,
                drone_visible_on_spot = visible
            } or nil,
            string = blueprint and {
                drone_blueprint = blueprint
            } or nil
        }
    }
end

function M:Regeneration( regeneration, regeneration_cooldown )
    return {
        regeneration = regeneration,
        regeneration_cooldown = regeneration_cooldown or 10
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

-- For Shapes
function M:BoxShape( x, y, z, position )
    return {
        x = x,
        y = y,
        z = z,
        position = position
    }
end

-- for InventoryComponent 
function M:MechInventory( name, subslots_count, allow_types )
    return {
        name = name,
        subslots_count = subslots_count or 1,
        allow_types = allow_types
    }

end

return M

