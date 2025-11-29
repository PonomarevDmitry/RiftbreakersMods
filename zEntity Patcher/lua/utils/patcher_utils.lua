require( "lua/utils/table_utils.lua" )

local controller = require( "lua/utils/patcher_controller.lua" )

local M = {}

for k, fn in pairs( controller ) do
    M[k] = fn
end

function M:Exist( var, field )
    if var == nil then
        self:Log( ("Exist Not (%s) or nil -->"):format( tostring( field or "" ) ) )
        self:MarkFails( 1 )
        return false
    end
    return true
end

function M:AssignIfTable( item, field, value )
    if not self:Exist( item[field], field ) then
        return true
    end
    if type( item[field] ) ~= "table" then
        item[field] = value
        self:MarkChanges()
        return true
    end

    return false
end

function M:IsType( expected, var, field )
    if type( var ) == expected then
        return true
    end
    self:Log( ("Type mismatch '%s': expected '%s', got '%s' -->"):format( field or "", expected, type( var ) ) )
    self:MarkFails()
    return false
end

-- Create all at once to prevent inherit value
function M:AddComponent( t1, check )
    if type( t1 ) ~= "table" then
        self:Log( ("Expected table format got '%s'"):format( type( t1 ) ) )
        return
    end
    for bp_name, component in pairs( t1 ) do
        local bp = ResourceManager:GetBlueprint( bp_name )
        local bp_component = bp:CreateComponent( component )
        if not bp_component then
            if not check then
                goto continue
            end
            bp_component = bp:GetComponent( component )
            if bp_component then
                self:Log( ("Component already exist %s in"):format( component ) )
            else
                self:Log( ("Failed to create component %s to"):format( component ) )
            end
        end
        ::continue::
    end
end

local simple_type = {
    String = true,
    StringHash = true,
    TypeId = true,
    Integer = true,
    hash = true
}

local function LogContainer( container, level, godeep )
    local count = container:GetItemCount()
    for i = 0, count - 1 do
        local item = container:GetItem( i )
        local tabs = string.rep( "\t", level )
        local type_name = item:GetTypeName()
        if simple_type[type_name] then
            LogService:Log( ("%s[%d] %s = %s"):format( tabs, i, type_name, item:GetValue() ) )
        else
            LogService:Log( ("%s[%d] %s"):format( tabs, i, type_name ) )
        end
        for item_field_name in Iter( item:GetFieldNames() ) do
            local field = item:GetField( item_field_name )
            if field:IsContainer() and godeep then
                LogService:Log( ("%s\t%s: %s = {...}"):format( tabs, item_field_name, field:GetTypeName() ) )
                LogContainer( field:ToContainer(), level + 1, godeep )
                goto continue
            end

            local field_value = field:GetValue()
            if field_value then
                LogService:Log( ("%s\t%s: %s = %s"):format( tabs, item_field_name, field:GetTypeName(), field_value ) )
                goto continue
            end

            LogService:Log( ("%s\t%s: %s"):format( tabs, item_field_name, field:GetTypeName() ) )

            ::continue::
        end
    end
end

-- ==== based on lukaasm snip code ==== --
function M:LogBlueprintComponents( bp_name, component, godeep, ghost, ghost_filter, t_ )
    local t = component and {} or t_
    if component and t_ == nil then
        local type_name = type( component )
        if type_name == "string" then
            for name in component:gmatch( "([^|]+)" ) do
                t[name] = true
            end
        elseif type_name == "table" then
            for name in Iter( component ) do
                t[name] = true
            end
        end
    end
    LogService:Log( "======== Log Component* =======" )
    LogService:Log( "[" .. bp_name .. "]" )
    local bp = ResourceManager:GetBlueprint( bp_name )
    if not bp then
        LogService:Log( bp_name .. " NOT FOUND" )
        return
    end
    godeep = not not godeep
    for component_name in Iter( bp:GetComponentNames() ) do
        if t and not t[component_name] then
            goto continue
        end
        LogService:Log( "*" .. component_name )
        local bp_component = bp:GetComponent( component_name )
        for field_name in Iter( bp_component:GetFieldNames() ) do
            local field = bp_component:GetField( field_name )
            if field:IsContainer() then
                LogService:Log( (" \t%s: %s = {...}"):format( field_name, field:GetTypeName() ) )
                LogContainer( field:ToContainer(), 3, godeep )
                goto next
            end

            local field_value = field:GetValue()
            if field_value then
                LogService:Log( (" \t%s: %s = %s"):format( field_name, field:GetTypeName(), field_value ) )
                goto next
            end

            LogService:Log( (" \t%s: %s"):format( field_name, field:GetTypeName() ) )
            ::next::
        end
        ::continue::
    end

    LogService:Log( "===============================" )
    if ghost == true then
        LogService:Log( "============ Ghost ============" )
        self:LogBlueprintComponents( (bp_name .. "_ghost"), nil, godeep, false, nil, (ghost_filter and t) )
    end
end

-- inherit issues
function M:CreateComponent( bp, component )
    local bp_component = bp:CreateComponent( component )
    if bp_component == nil then
        self:Log( "Failed to create component " .. component )
        return nil
    end
    return bp_component
end

function M:LogCreateIf( item )
    if self.show_bp_log then
        self:Log( "Creating new " .. item )
    end
end

function M:Log( str )
    LogService:Log( ("%s %s %s"):format( self.mod_name, str, self.bp_name or "" ) )
end

return M
