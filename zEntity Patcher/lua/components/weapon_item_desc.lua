require( "lua/utils/table_utils.lua" )
require( "lua/utils/divergent.lua" )

local M = {}

local features_to_enum = {
    ["BASE_DEFAULT"] = 1,
    ["BASE_MINMAX"] = 2,
    ["MODABLE"] = 4,
    ["STATISTIC"] = 8,
    ["HIDDEN"] = 16,
    ["INITIAL_RANDOMIZABLE"] = 32
}
local stat_type_enum = {
    [1] = "FIRE_RATE",
    [2] = "FIRE_PER_BURST",
    [3] = "FIRE_PER_SHOT",
    [4] = "DAMAGE_VALUE",
    [5] = "DAMAGE_SPREAD",
    [6] = "DAMAGE_CRITICAL_CHANCE",
    [7] = "DAMAGE_CRITICAL_FACTOR",
    [8] = "DAMAGE_OVER_TIME",
    [9] = "DAMAGE_OVER_TIME_LENGTH",
    [10] = "DAMAGE_SPLASH",
    [11] = "DAMAGE_LIFESTEAL",
    [12] = "DAMAGE_PENETRATION",
    [13] = "AMMO_STUN",
    [14] = "AMMO_STUN_LENGTH",
    [15] = "AMMO_COST",
    [16] = "AMMO_SPREAD",
    [17] = "AMMO_AUTOAIM",
    [18] = "AMMO_HOMING",
    [19] = "AMMO_CLUSTER",
    [20] = "AMMO_SPEED",
    [21] = "AMMO_ANGLE_SPEED",
    [22] = "BEAM_RANGE",
    [23] = "BEAM_WIDTH",
    [24] = "WEAPON_SCALE",
    [25] = "WEAPON_ANIMATION_SPEED"
}

local rarity = 0

local function HasFeature( features, feature )
    local value = features_to_enum[feature]
    if not value then
        Assert( false, ("Unknow feature: '%s'"):format( feature ) )
        return false
    end
    return (features % (value * 2)) >= value
end

local function AllFeaturesCheck( features, str )
    for feature in str:gmatch( "([^|]+)" ) do
        if not HasFeature( features, feature ) then
            return false
        end
    end
    return true
end

local vec_switch = {
    ["default*"] = function( self, item, v )
        item.default_value = item.default_value * v
        self:MarkChanges()
    end,
    ["default+"] = function( self, item, v )
        item.default_value = item.default_value + v
        self:MarkChanges()
    end,
    ["default-"] = function( self, item, v )
        item.default_value = math.max( 0, item.default_value - v )
        self:MarkChanges()
    end,
    ["default0="] = function( self, item, v )
        if item.default_value ~= 0 then
            return
        end
        item.default_value = v
        self:MarkChanges()
    end,
    ["default=max"] = function( self, item )
        if item.default_value == 0 then
            return
        end
        item.default_value = item.max_value
        self:MarkChanges()
    end,
    ["default=max_ifnot"] = function( self, item, str )
        str = str ~= "" and str or "BASE_DEFAULT"
        local features = item.stat_features
        if AllFeaturesCheck( features, str ) then
            return
        end
        item.default_value = item.max_value
    end,
    ["min=max"] = function( self, item )
        item.min_value = item.max_value
        self:MarkChanges()
    end,
    ["max=min"] = function( self, item )
        item.max_value = item.min_value
        self:MarkChanges()
    end,
    ["mm*"] = function( self, item, v )
        item.max_value = item.max_value * v
        item.min_value = item.min_value * v
        self:MarkChanges( 2 )
    end,
    ["mm+"] = function( self, item, v )
        item.max_value = item.max_value + v
        item.min_value = item.min_value + v
        self:MarkChanges( 2 )
    end,
    ["mm-"] = function( self, item, v )
        item.max_value = math.max( 0, item.max_value - v )
        item.min_value = math.max( 0, item.min_value - v )
        self:MarkChanges( 2 )
    end,
    ["mm="] = function( self, item, v )
        item.max_value = v
        item.min_value = v
        self:MarkChanges( 2 )
    end,
    ["mm0="] = function( self, item, str )
        if item.max_value ~= 0 and item.min_value ~= 0 then
            return
        end
        if type( str ) ~= "string" then
            self:Log( ("Expected string format for field 'mm0=', instead got %s"):format( type( str ) ) )
            self:MarkFails()
            return
        end
        local t = {}
        for value in str:gmatch( "([^|]+)" ) do
            Insert( t, value )
        end
        if #t == 0 then
            return
        end
        item.max_value = t[1]
        item.min_value = t[2] or t[1]
        self:MarkChanges( 2 )
    end,
    ["stat_features-"] = function( self, item, str, field )
        if not self:IsType( "string", str, field ) then
            return
        end

        local features = item.stat_features
        for feature in str:gmatch( "[^|]+" ) do
            if HasFeature( features, feature ) then
                features = features - features_to_enum[feature]
            end
            -- local value = features_to_enum[feature]
            -- if value then
            --     if features % (value * 2) >= value then
            --         features = features - value
            --     end
            -- else
            --     LogService:Log( ("%s  Unknow feature: |%s| ignoring %s"):format( self.mod_name, feature, self.bp_name ) )
            --     self:MarkFails()
            -- end
        end
        item.stat_features = features
        self:MarkChanges()
    end,
    ["stat_features"] = function( self, item, str, field )
        if not self:IsType( "string", str, field ) then
            return
        end
        local features = 0
        local seen = {}
        for feature in str:gmatch( "[^|]+" ) do
            local value = features_to_enum[feature]
            if value then
                if not seen[value] then
                    features = features + value
                    seen[value] = true
                end
            else
                self:Log( ("Unknow feature: |%s| ignoring"):format( feature ) )
                self:MarkFails()
            end
        end
        -- avoid MODABLE to get to standard item
        if rarity == 0 then
            if seen[4] then
                features = features - 4
            end
        end

        item[field] = features
        self:MarkChanges()
    end,
    ["stat_type"] = function( self, item, str, field )
        if not self:IsType( "string", str, field ) then
            return
        end
        for k, v in pairs( stat_type_enum ) do
            if v == str then
                item[field] = k
                self:MarkChanges()
                return
            end
        end
        self:Log( ("Unknow type '%s'"):format( str ) )
        self:MarkFails()
    end,
    __default = function( self, item, value, field )
        if item[field] ~= nil then
            item[field] = value
            self:MarkChanges()
        end
    end
}

local function StatDefVec( self, item, t )
    if not self:IsType( "table", t ) then
        return
    end

    for k, v in pairs( t ) do
        (vec_switch[k] or vec_switch.__default)( self, item, v, k )
    end
end

function M:WeaponItemDescHandler( bp_component, t )
    local component_ref = divergent_helper( bp_component )
    for field, value in pairs( t ) do
        if self:AssignIfTable( component_ref, field, value ) then
            goto continue
        end

        if not self:IsType( "table", value, field ) then
            goto continue
        end

        rarity = component_ref.rarity
        local vector = component_ref[field]
        local seen = {}
        for item in IterItems( vector ) do
            local stat_id = stat_type_enum[item.stat_type]
            local fields = value[stat_id]
            if fields ~= nil then
                StatDefVec( self, item, fields )
                seen[stat_id] = true
            end
        end

        if not self:IsCreator() then
            goto continue
        end

        for stat_id, fields in pairs( value ) do
            if not seen[stat_id] then
                self:LogCreateIf( stat_id )
                StatDefVec( self, vector:create_item(), fields )
            end
        end

        ::continue::
    end
end

return M
