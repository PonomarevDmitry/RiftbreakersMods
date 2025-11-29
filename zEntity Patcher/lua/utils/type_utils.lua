require( "lua/utils/reflection.lua" )

function vector_helper( self, component, field, t )
    if not self:IsType( "table", t, field ) then
        return
    end

    for k, v in pairs( t ) do
        if component[field][k] then
            component[field][k] = v
            self:MarkChanges()
        else
            self:Log( ("Unable to get Vector '%s.%s'"):format( field, k ) )
            self:MarkFails()
        end
    end
end

-- ===== ponomaryow.dmitry hash solution ===== --
function hash_helper( self, component, field, hash_values )
    if not component:is_container( field ) then
        self:Log( ("Hash field '%s' is not a container"):format( field ) )
        self:MarkFails()
        return
    end
    local container, count = component[field]:to_container()
    for hash_value in hash_values:gmatch( "([^|]+)" ) do
        hash_value = CalcHash( hash_value )
        for i = 0, count - 1 do
            local item = divergent_helper( container:GetItem( i ) )
            if item.hash == hash_value then
                goto continue
            end
        end

        local new_item = divergent_helper( container:CreateItem() )
        new_item.hash = hash_value
        self:MarkChanges()

        ::continue::
    end
end

function VectorString( self, component, field, t )
    local container, count = component[field]:to_container()
    for k in Iter( t ) do
        for i = 0, count - 1 do
            local item = container:GetItem( i )
            if item:GetValue() == k then
                goto continue
            end
        end

        local new_item = container:CreateItem()
        new_item:SetValue( k )
        self:MarkChanges()

        ::continue::
    end
end

function ResourceBasket( self, component, field, t )
    local container = component[field].resource
    for k, v in pairs( t ) do
        local hash = CalcHash( k )
        local value = v * 1000000
        for i = 1, container.count do
            local item = container[i]
            if item.key.hash == hash then
                item.value.value = value
                goto continue
            end
        end
        local new_item = container:reserve_item()
        local new_ref = divergent_helper( new_item )
        new_ref.key.hash = hash
        new_ref.value.value = value
        container:insert_item( new_item )
        ::continue::
    end
end
