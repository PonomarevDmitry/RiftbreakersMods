require( "lua/utils/table_utils.lua" )

local helper = require( "lua/utils/patcher_utils.lua" )
local template = require( "lua/utils/template_utils.lua" )
local M = require( "lua/utils/handler_utils.lua" )

-- class "entity_patcher"()
local entity_patcher = {}

entity_patcher.mod_name = nil
entity_patcher.bp_name = nil
entity_patcher.show_bp_log = false
entity_patcher.debug_handler = false

for k, fn in pairs( helper ) do
    entity_patcher[k] = fn
end

entity_patcher.t = {}
for k, fn in pairs( template ) do
    entity_patcher.t[k] = fn
end

local HandlerSwitch = {}

local function PatchBlueprintComponents( self, bp_name, t, sc )
    local bp = ResourceManager:GetBlueprint( bp_name )
    if not bp then
        if self.show_bp_log then
            self:Log( "Blueprint NOT FOUND -->" )
        end
        self:MarkFails()
        return
    end
    for component, fields in pairs( t ) do
        local bp_component = bp:GetComponent( component )
        if not bp_component then
            if sc then
                bp_component = self:CreateComponent( bp, component )
                if bp_component then
                    goto invoke
                end
            end
            if self.show_bp_log then
                self:Log( ("Unable to get component '%s' from"):format( component ) )
            end
            self:MarkFails()
            goto continue
        end
        ::invoke::
        do
            local InvokeHandler = HandlerSwitch[component] or HandlerSwitch.__default
            InvokeHandler( self, bp_component, fields, component )
        end
        ::continue::
    end
end

function entity_patcher:ApplyOrdered( t, show_bp_log, show_patch )
    if type( t ) ~= "table" or #t == 0 then
        LogService:Log( ("%s ApplyOrdered: invalid arguments numeric table expected, on first argument with '.name' and '.data'"):format( self.mod_name ) )
        return
    end
    self.show_bp_log = not not show_bp_log
    show_patch = not not show_patch
    for _, it in ipairs( t ) do
        self.bp_name = it.name
        PatchBlueprintComponents( self, it.name, it.data, true )
        if show_patch then
            self:Log( ("Changes %s -->"):format( self:GetChanges() ) )
        end
        self:ResetChanges()
    end
    LogService:Log( ("%s Entities [%d] | Changes: %s"):format( self.mod_name, #t, self:GetStats() ) )
    self:ResetStats()
    self:RemoveCreatorMode()
end

function entity_patcher:Apply( arg1_table, arg2_table, show_bp_log, show_patch )
    self.show_bp_log = not not show_bp_log
    show_patch = not not show_patch
    if type( arg1_table ) == "table" and type( arg2_table ) == "table" then
        for _, bp_name in pairs( arg1_table ) do
            self.bp_name = bp_name
            PatchBlueprintComponents( self, bp_name, arg2_table )
            if show_patch then
                self:Log( ("Changes %s -->"):format( self:GetChanges() ) )
            end
            self:ResetChanges()
        end
        LogService:Log( ("%s Entities [%d] | Changes: %s"):format( self.mod_name, #arg1_table, self:GetStats() ) )
    elseif type( arg1_table ) == "table" and arg2_table == nil then
        local count = 0
        for bp_name, components in pairs( arg1_table ) do
            self.bp_name = bp_name
            PatchBlueprintComponents( self, bp_name, components )
            if show_patch then
                self:Log( ("Changes %s -->"):format( self:GetChanges() ) )
            end
            count = count + 1
            self:ResetChanges()
        end

        LogService:Log( ("%s Entities [%d] | Changes: %s"):format( self.mod_name, count, self:GetStats() ) )
    else
        LogService:Log( ("%s Apply: invalid arguments | two tables or single table expected"):format( self.mod_name ) )
        return
    end
    self:ResetStats()
    self:RemoveCreatorMode()
end

require( "lua/commands/patcher_commands.lua" )

ConsoleService:RegisterCommand( "ep_log_blueprint", function( args )
    if not Assert( #args == 1, "Command requires one argument! [blueprint_name]" ) then
        return
    end

    entity_patcher:LogBlueprintComponents( args[1], args[2], true, true )
end )

-- ConsoleService:RegisterCommand( "ep_recreate_buildings", function( args )
--     if not Assert( #args == 1, "Command requires one argument! [bool]" ) then
--         return
--     end

--     if args[1] ~= 1 then
--         return
--     end

-- end )

function entity_patcher:SingleEntityEdit( bp_name, component, field, value )
    local bp = ResourceManager:GetBlueprint( bp_name )
    if not bp then
        LogService:Log( self.mod_name .. " " .. self.bp_name .. " NOT FOUND" )
        return
    end

    local bp_component = bp:GetComponent( component )
    if bp_component == nil then
        LogService:Log( self.mod_name .. " Failed to get " .. component .. " from " .. self.bp_name )
        return
    end

    local field_handle = bp_component:GetField( field )
    if field_handle == nil then
        LogService:Log( self.mod_name .. " Failed to get " .. field .. " " .. component .. " --> " .. self.bp_name )
        return
    end
    field_handle:SetValue( value )
end

local function dump_table_keys( tbl, name )
    name = name or "table"
    if type( tbl ) ~= "table" then
        LogService:Log( ("dump_table_keys(%s): not a table, got %s"):format( name, type( tbl ) ) )
        return
    end

    local count = 0
    for _ in pairs( tbl ) do
        count = count + 1
    end
    LogService:Log( ("[%s] keys = %d"):format( name, count ) )

    for k, v in pairs( tbl ) do
        local kstr = tostring( k )
        local vtyp = type( v )
        local vstr
        if vtyp == "function" or vtyp == "userdata" or vtyp == "thread" then
            vstr = tostring( v )
        elseif vtyp == "table" then
            vstr = ("table(%d keys)"):format( (function()
                local n = 0;
                for _ in pairs( v ) do
                    n = n + 1
                end
                return n
            end)() )
        else
            vstr = tostring( v )
        end
        LogService:Log( ("  %s : %s (%s)"):format( kstr, vstr, vtyp ) )
    end
end

local function probe_member( tbl, key )
    local val = rawget( tbl, key )
    LogService:Log( ("rawget(%s) -> %s (%s)"):format( key, tostring( val ), type( val ) ) )
end

function entity_patcher:LogResourceManager()
    LogService:Log( "LogResourceManager" )
    LogService:Log( "type(ResourceManager) = " .. type( ResourceManager ) )
    dump_table_keys( ResourceManager, "ResourceManager" )
    probe_member( ResourceManager, "GetBlueprint" )
    probe_member( ResourceManager, "Load" )
    probe_member( ResourceManager, "Unload" )
end

-- ResourceManager:ResourceExists( resource_type: string, resource_name: string )
-- ResourceManager:GetBlueprint( blueprint_name: string )
-- ResourceManager:GetResource( resource_type: string, resource_name: string )

local function SnakeMode( string )
    return string:lower():gsub( "[^%w]+", "_" ):gsub( "^_+", "" ):gsub( "_+S", "" )
end

local function WriteKey( name )
    local info = debug.getinfo( 3, "n" )
    return "$" .. SnakeMode( name ) .. "" .. info.name
end

-- TODO Remove next update
function GetOrCreateLocker( name, bp_name )
    bp_name = bp_name or "buildings/main/weather_controller"
    local bp_data = EntityService:GetBlueprintDatabase( bp_name )
    if bp_data == nil then
        LogService:Log( ("Failed to get data on '%s' locker will be open %s"):format( bp_name, name ) )
        return false
    end
    local info = debug.getinfo( 2, "n" )
    local key = "$" .. SnakeMode( name ) .. "" .. info.name
    if bp_data:HasInt( key ) then
        LogService:Log( "Already applied " .. name )
        return true
    else
        bp_data:SetInt( key, 1 )
        return false
    end
end

local function GetData( bp_name )
    bp_name = bp_name or "buildings/main/weather_controller"
    local bp_data = EntityService:GetBlueprintDatabase( bp_name )
    return bp_data
end

function ExecuteOnceGuard( name, bp_name )
    local bp_data = GetData( bp_name )
    if bp_data == nil then
        LogService:Log( ("Fail to get blueprint data %s"):format( bp_name ) )
        return false
    end
    local key = WriteKey( name )
    if bp_data:HasInt( key ) then
        return true
    else
        bp_data:SetInt( key, 1 )
        return false
    end
end

function ExecuteUntilGuard( name, n, bp_name )
    local bp_data = GetData( bp_name )
    if bp_data == nil then
        LogService:Log( ("Fail to get blueprint data %s"):format( bp_name ) )
        return false
    end
    local key = WriteKey( name )
    if bp_data:HasInt( key ) then
        local value = bp_data:GetInt( key )
        if value < n then
            bp_data:SetInt( key, value + 1 )
            return false
        end
        return true
    else
        bp_data:SetInt( key, 1 )
        return false
    end
end

HandlerSwitch = {
    ["EffectDesc"] = M.effects.EffectDescHandler,
    ["BuildingDesc"] = M.building.BuildingDescHandler,
    ["BuildingComponent"] = M.building.BuildingDescHandler,
    ["PipeComponent"] = M.pipe.PipeHandler,
    ["GridCullerComponent"] = M.grid.GridCullerHandler,
    ["ResourceConverterDesc"] = M.converter.ResourceConverterDescHandler,
    ["RegenerationComponent"] = M.health.HealthHandler,
    ["HealthDesc"] = M.health.HealthHandler,
    ["HealthComponent"] = M.health.HealthHandler,
    ["LifeTimeDesc"] = M.health.HealthHandler,
    ["TurretComponent"] = M.turret.TurretHandler,
    ["TurretDesc"] = M.turret.TurretHandler,
    ["TypeComponent"] = M.turret.TurretHandler,
    ["DecalComponent"] = M.turret.TurretHandler,
    ["ResistanceComponent"] = M.resistance.ResistanceComponentHandler,
    ["LuaComponent"] = M.lua.LuaComponentHandler,
    ["InventoryItemComponent"] = M.inventory.InventoryItemDescHandler,
    ["EquipmentComponent"] = M.mech.MechEquipmentHandler,
    ["WeaponItemDesc"] = M.weapon.WeaponItemDescHandler,
    __default = M.default.DefaultHandler
}

return entity_patcher
