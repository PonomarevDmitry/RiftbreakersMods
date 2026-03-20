require( "lua/utils/divergent.lua" )

local M = {}

function M:PipeHandler( bp_component, t )

    local component_ref = divergent_helper( bp_component )
    for field, value in pairs( t ) do
        if component_ref[field] == nil then
            goto continue
        end

        if type( value ) ~= "string" then
            LogService:Log( ("%s Expected string 'format', instead got '%s' %s"):format( self.mod_name, type( value ), self.bp_name ) )
            goto continue
        end

        local container, count = component_ref[field]:to_container()
        for name in value:gmatch( "[^,]+" ) do
            for i = 0, count - 1 do
                local item = container:GetItem( i )
                if item:GetValue() == name then
                    goto next
                end
            end
            local new_item = container:CreateItem()
            new_item:SetValue( name )
            self:MarkChanges()
            ::next::
        end

        ::continue::
    end
end

return M
