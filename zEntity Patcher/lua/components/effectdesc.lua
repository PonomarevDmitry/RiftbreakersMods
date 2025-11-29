-- require( "lua/utils/reflection.lua" )
require( "lua/utils/type_utils.lua" )
require( "lua/utils/divergent.lua" )

local M = {}

local switch = {}
local field_map = {
    ["scale"] = vector_helper,
    ["offset"] = vector_helper
}

local function effect_helper( self, out_item, t )
    for k, v in pairs( t ) do
        if self:AssignIfTable( out_item, k, v ) then
            goto continue
        end

        if not self:IsType( "table", v, k ) then
            goto continue
        end

        local invoke = field_map[k]
        if invoke then
            invoke( self, out_item, k, v )
            goto continue
        end

        local container = out_item[k]
        for i = 1, container.count do
            local item = container[i]
            effect_helper( self, item, v[i] or v )
        end

        ::continue::
    end
end

local function CreateEffectType( component, effect, amount )
    local item = component["Effects"]:create_item( effect )
    if effect == "Effect" then
        return item
    end

    local effects = effect == "EffectGroup" and "Effect" or nil
    repeat
        item.Effects:create_item( effects )
        amount = amount - 1
    until amount <= 0

    return item
end

function switch:Effect( component, t, effect )
    for _, content in ipairs( t ) do
        if not content.name then
            self:Log( "Empty name field or nil, can't guess what looking for in" )
            self:MarkFails()
            goto continue
        end

        local container, count = component.Effects:to_container()
        for item in IterItems( container, count ) do
            -- local item = container:GetItem( i )
            if item:GetTypeName() ~= effect then
                goto next
            end
            if item:GetField( "blueprint" ):GetValue() == content.name then
                effect_helper( self, divergent_helper( item ), content.data )
                goto continue
            end
            ::next::
        end

        self:LogCreateIf( effect )
        local new_item = CreateEffectType( component, effect )
        effect_helper( self, new_item, content.data )

        ::continue::
    end
end

function switch:EffectGroup( component, t, effect )
    for _, content in ipairs( t ) do
        if content.look == nil or content.name == nil then
            self:Log( "Empty 'look' or 'name', or nil, expected a 'group' or 'blueprint' to look for in" )
            self:MarkFails()
            goto continue
        end

        local container, count = component.Effects:to_container()
        if content.look == "group" then
            for item in IterItems( container, count ) do
                -- local item = container:GetItem( i )
                if item:GetTypeName() ~= effect then
                    goto next
                end
                if item:GetField( "group" ):GetValue() == content.name then
                    local item_effects = item:GetField( "Effects" ):ToContainer()
                    if item_effects:GetItemCount() < #content.data.Effects then
                        local size = #content.data.Effects
                        while item_effects:GetItemCount() < size do
                            item_effects:CreateItem( "Effect" )
                        end
                    end
                    effect_helper( self, divergent_helper( item ), content.data )
                    goto continue
                end
                ::next::
            end
        elseif content.look == "blueprint" then
            for item in IterItems( container, count ) do
                -- local item = container:GetItem( i )
                if item:GetTypeName() ~= effect then
                    goto next
                end
                local item_effects = item:GetField( "Effects" ):ToContainer()
                local count_effects = item_effects:GetItemCount()
                for item_effect in IterItems( item_effects, count ) do
                    -- local item_effect = item_effects:GetItem( j )
                    if item_effect:GetField( "blueprint" ):GetValue() == content.name then
                        if count_effects < #content.data.Effects then
                            local size = #content.data.Effects
                            while item_effects:GetItemCount() < size do
                                item_effects:CreateItem( "Effect" )
                            end
                        end
                        effect_helper( self, divergent_helper( item ), content.data )
                        goto continue
                    end
                end
                ::next::
            end
        end

        self:LogCreateIf( effect )
        local new_item = CreateEffectType( component, effect, #content.data.Effects )
        effect_helper( self, new_item, content.data )

        ::continue::
    end
end

function switch:EffectRandom( component, t, effect )
    for _, content in ipairs( t ) do
        if not content.name then
            LogService:Log( ("%s Empty name field or nil, can't guess what looking for in %s"):format( self.mod_name, self.bp_name ) )
            self:MarkFails()
            goto continue
        end

        local container, count = component.Effects:to_container()
        for item in IterItems( container, count ) do
            -- local item = container:GetItem( i )
            if item:GetTypeName() ~= effect then
                goto next
            end
            local item_effects = item:GetField( "Effects" ):ToContainer()
            local count_effects = item_effects:GetItemCount()
            for item_effect in IterItems( item_effects, count_effects ) do
                -- local item_effect = item_effects:GetItem( j )
                if item_effect:GetField( "blueprint" ):GetValue() == content.name then
                    if count_effects < #content.data.Effects then
                        local size = #content.data.Effects
                        while item_effects:GetItemCount() < size do
                            item_effects:CreateItem()
                        end
                    end
                    effect_helper( self, divergent_helper( item ), content.data )
                    goto continue
                end
            end
            ::next::
        end

        self:LogCreateIf( effect )
        local new_item = CreateEffectType( component, effect, #content.data.Effects )
        effect_helper( self, new_item, content.data )

        ::continue::
    end
end

function switch:__default( component, t, effect )
    self:Log( ("Expected 'Effect' or 'EffectGroup' or 'EffectRandom', instead got '%s' in"):format( effect ) )
    self:MarkFails()
end

function M:EffectDescHandler( bp_component, t )
    local component_ref = divergent_helper( bp_component )
    for effect, content in pairs( t ) do
        (switch[effect] or switch.__default)( self, component_ref, content, effect )
    end
end

return M
