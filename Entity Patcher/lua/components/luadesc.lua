-- require( "lua/utils/reflection.lua" )
require( "lua/utils/divergent.lua" )

local M = {}

local data_map = {
    int = {
        lua = "number",
        Has = "HasInt",
        Set = "SetInt"
     },
    float = {
        lua = "number",
        Has = "HasFloat",
        Set = "SetFloat"
     },
    string = {
        lua = "string",
        Has = "HasString",
        Set = "SetString"
     }
 }

local function DatabaseHandler( self, t )
    local bp_data = EntityService2:GetBlueprintDatabase( self.bp_name )
    if bp_data == nil then
        self:Log( "Unable to get data from" )
        self:MarkFails()
        return
    end

    for type_data, fields in pairs( t ) do
        if not self:IsType( "table", fields, type_data ) then
            goto continue
        end

        local invoke = data_map[type_data]
        if invoke == nil then
            self:Log( ("Type passed invalid '%s'"):format( type_data ) )
            self:MarkFails()
            goto continue
        end

        for k, v in pairs( fields ) do

            if not self:IsType( invoke.lua, v, k ) then
                goto continue_fields
            end

            if not bp_data[invoke.Has]( bp_data, k ) and self.show_bp_log then
                self:Log( ("Adding '%s' to data "):format( k ) )
            end

            bp_data[invoke.Set]( bp_data, k, v )
            self:MarkChanges()

            ::continue_fields::
        end
        ::continue::
    end
end

function M:LuaComponentHandler( bp_component, t )
    for field, value in pairs( t ) do
        if field == "database" then
            if not self:IsType( "table", value, field ) then
                goto continue
            else
                DatabaseHandler( self, value )
            end

        end
        -- local component_ref = reflection_helper( bp_component )
        -- LogService:Log( "[Test] script type " .. type( component_ref.script ) )
        -- LogService:Log( "[Test] script = " .. tostring( component_ref.script ) )
        ::continue::
    end
end

return M
