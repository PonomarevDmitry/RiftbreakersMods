function IndexOf( t, key )
    if type( key ) == "function" then
        for index, value in ipairs( t ) do
            if key( t[index] ) then
                return index
            end
        end
    else
        for index, value in ipairs( t ) do
            if value == key then
                return index
            end
        end
    end

    return nil
end

function Copy( t )
    local result = {}

    for key, value in pairs( t ) do
        result[key] = value
    end

    return result
end

function DeepCopy( orig )
    if type( orig ) ~= "table" then
        return orig
    end

    local copy = {}
    for key, value in next, orig, nil do
        copy[DeepCopy( key )] = DeepCopy( value )
    end
    setmetatable( copy, DeepCopy( getmetatable( orig ) ) )

    return copy
end

function Insert( t, item )
    local count = #t
    t[count + 1] = item
end

function Remove( t, item )
    local index = IndexOf( t, item )
    if index == nil then
        return
    end

    table.remove( t, index )
end

function Size( t )
    local count = 0
    for _, _ in pairs( t ) do
        count = count + 1
    end

    return count
end

function Concat( t1, t2 )
    for _, v in ipairs( t2 ) do
        Insert( t1, v )
    end
end

function ConcatUnique( t1, t2 )
    for _, v in ipairs( t2 ) do
        if (IndexOf( t1, v ) == nil) then
            Insert( t1, v )
        end
    end
end

function Clear( t )
    for k in pairs( t ) do
        t[k] = nil
    end
end

function Iter( t, count )
    if not Assert( type( t ) == "table", "ERROR: calling Iter on non table type: `" .. type( t ) .. "`" ) then
        return nil
    end

    local index = 0
    count = count or #t

    return function()
        index = index + 1

        if index <= count then
            return t[index]
        end

    end
end

function SortedIter( t, order )
    -- collect the keys
    local keys = {}
    for _, k in pairs( t ) do
        keys[#keys + 1] = k
    end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort( keys, function( a, b )
            return order( t, a, b )
        end )
    else
        table.sort( keys )
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function IsArray( t )
    if Assert( type( t ) ~= "table", "Error: Calling IsArray in non-table type: " .. type( t ) ) then
        return false
    end

    local max = 0
    local count = 0

    for k, _ in pairs( t ) do
        if type( k ) ~= "number" or k % 1 ~= 0 or k <= 0 then
            return false
        end

        if k > max then
            max = k
        end

        count = count + 1
    end

    return max == count
end

function MakeHashTable( t, bool )
    if type( t ) ~= "table" then
        return
    end

    bool = not not bool

    local hash = {}
    for _, v in ipairs( t ) do
        hash[v] = bool
    end

    return hash
end

function RemoveWithTail( t, index )
    local count = #t

    t[index] = t[count]
    t[count] = nil
end

function IterTail( t, count )
    if not Assert( type( t ) == "table", "ERROR: calling Iter on non table type: `" .. type( t ) .. "`" ) then
        return nil
    end

    local index = #t + 1
    count = count or 1

    return function()
        index = index - 1

        if index >= count then
            return t[index], index
        end

    end

end
