-- For GetPodValue
require( "lua/utils/reflection.lua" )

local TypeContainerHelper = {};
TypeContainerHelper.mt = {
    __index = function( self, key )
        if TypeContainerHelper.mt[key] ~= nil then
            return TypeContainerHelper.mt[key]
        end
        local ptr = rawget( self, "__ptr" );
        if type( key ) == 'number' then
            local item = ptr:GetItem( key - 1 )
            if item == nil then
                return nil
            end

            local value = GetPodValue( item )
            if value ~= nil then
                return value
            end

            return divergent_helper( item )
        elseif key == "count" then
            return ptr:GetItemCount()
        end

        return nil
    end,
    get_item = function( self, key )
        local ptr = rawget( self, "__ptr" )
        local item = ptr:GetItem( key - 1 )
        if item == nil then
            return nil
        end
        return divergent_helper( item )
    end,
    create_item = function( self, type )
        local ptr = rawget( self, "__ptr" );

        if (type ~= nil) then
            return divergent_helper( ptr:CreateItem( type ) )
        end

        return divergent_helper( ptr:CreateItem() )
    end,
    pair_create_item = function( self, key, value )
        local ptr = rawget( self, "__ptr" )
        local item = ptr:ReserveItem()
        item:GetField( "key" ):SetValue( tostring( key ) )
        if value then
            item:GetField( "value" ):SetValue( tostring( value ) )
        end
        ptr:InsertItem( item )
    end,
    map_get_item = function( self, key )
        if not Assert( type( key ) == 'number' or type( key ) == 'string', "ERROR: key must be a number or string, got: " .. type( key ) ) then
            return nil
        end

        local ptr = rawget( self, "__ptr" );

        local count = ptr:GetItemCount()
        for i = 1, count do
            local item = ptr:GetItem( i - 1 )

            local k = GetPodValue( item:GetField( "key" ) )
            if k == key then
                local v = item:GetField( "value" )
                return GetPodValue( v ) or divergent_helper( v )
            end
        end

        local item = ptr:ReserveItem();
        item:GetField( "key" ):SetValue( tostring( key ) )
        ptr:InsertItem( item );

        return divergent_helper( item:GetField( "value" ) )
    end,
    insert_item = function( self, item )
        local ptr = rawget( self, "__ptr" )
        ptr:InsertItem( item )
    end,
    reserve_item = function( self )
        local ptr = rawget( self, "__ptr" )
        return ptr:ReserveItem()
    end,
    type_name = function( self, key )
        if key then
            local ptr = rawget( self[key], "__ptr2" )
            return ptr:GetTypeName()
        end
        local ptr = rawget( self, "__ptr2" )
        return ptr:GetTypeName()
    end,
    field_names = function( self )
        local ptr = rawget( self, "__ptr2" )
        return ptr:GetFieldNames()
    end,
    to_container = function( self )
        local ptr = rawget( self, "__ptr" )
        local count = ptr:GetItemCount()
        return ptr, count
    end,
    is_container = function( self, key )
        if key then
            local ptr = rawget( self[key], "__ptr2" )
            return ptr:IsContainer()
        end
        local ptr = rawget( self, "__ptr2" )
        return ptr:IsContainer()
    end,
    __len = function( self )
        local ptr = rawget( self, "__ptr" );
        return ptr:GetItemCount();
    end,
    __tostring = function( self )
        local ptr = rawget( self, "__ptr2" );

        local value = ptr:GetTypeName()
        value = value .. "\n[\n"

        local container = rawget( self, "__ptr" );

        local count = container:GetItemCount()
        for i = 1, count do
            local item = divergent_helper( container:GetItem( i - 1 ) )
            value = value .. "\t" .. tostring( item ) .. "\n"
        end

        value = value .. "]\n"
        return value
    end
}

local TypeValueHelper = {};
TypeValueHelper.mt = {
    __index = function( self, key )

        if TypeValueHelper.mt[key] ~= nil then
            return TypeValueHelper.mt[key]
        end

        local ptr = rawget( self, "__ptr" )
        local field = ptr:GetField( key )
        if not Assert( field ~= nil, "ERROR: there is no field '" .. tostring( key ) .. "'" ) then
            return nil
        end

        local value = GetPodValue( field )
        if value ~= nil then
            return value
        end

        return divergent_helper( field )
    end,
    type_name = function( self, key )
        if key then
            local ptr = rawget( self, "__ptr" )
            local field = ptr:GetField( key )
            return field:GetTypeName()
        end
        local ptr = rawget( self, "__ptr" )
        return ptr:GetTypeName()
    end,
    field_names = function( self )
        local ptr = rawget( self, "__ptr" )
        return ptr:GetFieldNames()
    end,
    is_container = function( self, key )
        if not key then
            local ptr = rawget( self, "__ptr" )
            return ptr:IsContainer()
        end
        local ptr = rawget( self, "__ptr" )
        local field = ptr:GetField( key )
        return field:IsContainer()
    end,
    __newindex = function( self, key, value )
        local ptr = rawget( self, "__ptr" );

        local field = ptr:GetField( key )
        if field == nil then
            Assert( false, "ERROR: there is no field '" .. key .. "'" )
            return nil
        end

        if type( value ) == 'boolean' then
            if value == false then
                value = "0"
            else
                value = "1"
            end
        end

        local res = field:SetValue( tostring( value ) )
        Assert( res, "ERROR: failed to set value on field '" .. key .. "'" )
    end,
    __tostring = function( self )
        local ptr = rawget( self, "__ptr" );

        local value = ptr:GetTypeName()
        value = value .. "\n{\n"

        for field_name in Iter( ptr:GetFieldNames() ) do
            value = value .. "\t" .. field_name .. " = "

            local field = ptr:GetField( field_name )
            if field ~= nil then
                local field_value = GetPodValue( field )
                if field_value ~= nil then
                    value = value .. tostring( field_value )
                else
                    value = value .. "[" .. field:GetTypeName() .. "]"
                end
            else
                value = value .. "nil"
            end

            value = value .. "\n"
        end

        value = value .. "}\n"
        return value
    end
};

function divergent_helper( ptr, userdata )
    if not Assert( ptr ~= nil, "ERROR: nil" ) then
        return nil
    end

    ptr:SetRealSelfAwareType()

    if ptr:IsContainer() then
        local instance = setmetatable( {}, TypeContainerHelper.mt );
        rawset( instance, "__ptr", ptr:ToContainer() );
        rawset( instance, "__ptr2", ptr );
        rawset( instance, "__userdata", userdata );
        return instance;
    else
        local instance = setmetatable( {}, TypeValueHelper.mt );
        rawset( instance, "__ptr", ptr );
        rawset( instance, "__userdata", userdata );
        return instance;
    end
end

function IterItems( container, count )
    local type_container = type( container )
    local index = -1
    if type_container == "userdata" and container.GetItemCount then
        count = (count or container:GetItemCount()) - 1

        return function()
            index = index + 1

            if index <= count then
                return container:GetItem( index ), index
            end
        end
    elseif type_container == "table" and container:is_container() then
        local ptr = rawget( container, "__ptr" )
        count = (count or ptr:GetItemCount()) - 1

        return function()
            index = index + 1

            if index <= count then
                return divergent_helper( ptr:GetItem( index ) ), index
            end
        end
    end

    Assert( false, "ERROR: Calling IterItems in non container." )
    return nil, nil
end
