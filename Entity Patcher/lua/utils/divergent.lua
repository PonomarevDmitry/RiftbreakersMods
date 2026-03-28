g_reflection_types = {
    [CalcHash( "bool" )] = "GetValueAsBool",

    [CalcHash( "String" )] = "GetValue",
    [CalcHash( "IdString" )] = "GetValue",
    [CalcHash( "NarrowString" )] = "GetValue",
    [CalcHash( "WideString" )] = "GetValue",
    [CalcHash( "char" )] = "GetValue",
    [CalcHash( "wchar" )] = "GetValue",

    [CalcHash( "int8" )] = "GetValueAsNumber",
    [CalcHash( "uchar" )] = "GetValueAsNumber",
    [CalcHash( "short" )] = "GetValueAsNumber",
    [CalcHash( "ushort" )] = "GetValueAsNumber",
    [CalcHash( "int" )] = "GetValueAsNumber",
    [CalcHash( "uint" )] = "GetValueAsNumber",
    [CalcHash( "float" )] = "GetValueAsNumber",
    [CalcHash( "double" )] = "GetValueAsNumber",
    [CalcHash( "int64" )] = "GetValueAsNumber",
    [CalcHash( "uint64" )] = "GetValueAsNumber"
}

local function DivergentGetPodValue( FoI )
    local invoke = g_reflection_types[CalcHash( FoI:GetTypeName() )]

    if invoke then
        local value = FoI[invoke]( FoI )
        if value ~= nil then
            return value
        end

        local error = "ERROR: failed to convert to %s from: %s"
        local type_name = FoI:GetTypeName()
        Assert( invoke ~= "GetValue", error:format( "string", type_name ) )
        Assert( invoke ~= "GetValueAsBool", error:format( "bool", type_name ) )
        Assert( invoke ~= "GetValueAsNumber", error:format( "numeric", type_name ) )

    end

    return divergent_helper( FoI )
end

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

            return DivergentGetPodValue( item )
        elseif key == "count" then
            return ptr:GetItemCount()
        end

        return nil
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
        item:GetField( "value" ):SetValue( tostring( value ) )
        ptr:InsertItem( item )
    end,
    map_get_item = function( self, key )
        local key_type = type( key )
        if key ~= "string" and key ~= "number" then
            Assert( false, "ERROR: key must be a number or string, got: " .. key_type )
            return nil
        end

        local ptr = rawget( self, "__ptr" );
        for item in IterItems( ptr ) do

            local k = DivergentGetPodValue( item:GetField( "key" ) )
            if k == key then
                return divergent_helper( item )
            end
        end

        local new_item = ptr:ReserveItem();
        new_item:GetField( "key" ):SetValue( tostring( key ) )
        ptr:InsertItem( new_item );

        return divergent_helper( new_item )
    end,
    insert_item = function( self, item )
        local ptr = rawget( self, "__ptr" )
        -- local ptr_item = rawget(item, "__ptr")
        ptr:InsertItem( item )
    end,
    reserve_item = function( self )
        local ptr = rawget( self, "__ptr" )
        -- return divergent_helper(ptr:ReserveItem())
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

local function indent_multiline( s, indent )
    s = tostring( s )
    return (s:gsub( "\n", "\n" .. indent ))
end

local function dump_table( t, indent, depth, max_depth, seen )
    if type( t ) ~= "table" then
        return indent .. tostring( t )
    end

    if seen[t] then
        return indent .. "<cycle>"
    end
    seen[t] = true

    if depth >= max_depth then
        seen[t] = nil
        return indent .. "{ … }"
    end

    local lines = {}
    lines[#lines + 1] = indent .. "{"

    -- stable order (optional but makes logs nicer)
    local keys = {}
    for k in pairs( t ) do
        keys[#keys + 1] = k
    end
    table.sort( keys, function( a, b )
        return tostring( a ) < tostring( b )
    end )

    local child_indent = indent .. "\t"
    for _, k in ipairs( keys ) do
        local v = t[k]
        if type( v ) == "table" then
            lines[#lines + 1] = child_indent .. tostring( k ) .. " ="
            lines[#lines + 1] = dump_table( v, child_indent, depth + 1, max_depth, seen )
        else
            local sv = indent_multiline( v, child_indent )
            lines[#lines + 1] = child_indent .. tostring( k ) .. " = " .. tostring( sv )
        end
    end

    lines[#lines + 1] = indent .. "}"

    seen[t] = nil
    return table.concat( lines, "\n" )
end

local TypeValueHelper = {};
TypeValueHelper.mt = {
    __index = function( self, key )

        if TypeValueHelper.mt[key] ~= nil then
            return TypeValueHelper.mt[key]
        end

        local ptr = rawget( self, "__ptr" )
        local field = ptr:GetField( key )
        if not Assert( field ~= nil, "ERROR: there is no field '" .. key .. "'" ) then
            return nil
        end

        return DivergentGetPodValue( field )
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
            value = value and "1" or "0"
        end

        local res = field:SetValue( tostring( value ) )
        Assert( res, "ERROR: failed to set value on field '" .. key .. "'" )
    end,
    pretty_log = function( self, deep, seen )
        deep = deep or 0
        seen = seen or {}

        if seen[self] then
            return string.rep( "\t", deep ) .. "<cycle>\n"
        end
        seen[self] = true

        local ptr = rawget( self, "__ptr" )

        local tabs = string.rep( "\t", deep )

        local out = {}
        out[#out + 1] = tabs .. ptr:GetTypeName()
        out[#out + 1] = tabs .. "{"

        for field_name in Iter( ptr:GetFieldNames() ) do
            local field = ptr:GetField( field_name )
            local v = self[field_name]

            if type( v ) ~= "table" then
                out[#out + 1] = tabs .. "\t" .. field_name .. " = " .. tostring( v )
            else

                out[#out + 1] = tabs .. "\t" .. field_name .. " = [" .. field:GetTypeName() .. "]"
                if type( v.pretty_log ) == "function" then
                    local nested = v:pretty_log( deep + 2, seen )

                    out[#out + 1] = nested:sub( 1, -2 )
                else
                    local s = tostring( v )
                    s = s:gsub( "\n", "\n" .. tabs .. "\t\t" )
                    out[#out + 1] = tabs .. "\t\t" .. s
                end
            end
        end

        out[#out + 1] = tabs .. "}"
        seen[self] = nil
        return table.concat( out, "\n" ) .. "\n"
    end,
    __tostring = function( self )
        local ptr = rawget( self, "__ptr" );

        local value = ptr:GetTypeName()
        value = value .. "\n{\n"

        for field_name in Iter( ptr:GetFieldNames() ) do
            value = value .. "\t" .. field_name .. " = "

            local field = ptr:GetField( field_name )
            if field ~= nil then
                -- local field_value = DivergentGetPodValue( field )
                local field_value = self[field_name]

                if type( field_value ) ~= "table" then
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
    -- local type_container = type( container )
    local index = -1
    if container.GetItemCount then
        count = (count or container:GetItemCount()) - 1

        return function()
            index = index + 1

            if index <= count then
                return container:GetItem( index ), index
            end
        end
    elseif type( container ) == "table" and container:is_container() then
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

