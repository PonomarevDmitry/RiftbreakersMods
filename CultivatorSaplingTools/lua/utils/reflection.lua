require("lua/utils/string_utils.lua")

g_reflection_number_types = {
    CalcHash("int8"),
    CalcHash("uchar"),
    CalcHash("short"),
    CalcHash("ushort"),
    CalcHash("int"),
    CalcHash("uint"),
    CalcHash("float"),
    CalcHash("double"),
    CalcHash("int64"),
    CalcHash("uint64"),
};

g_reflection_string_types = {
    CalcHash("String"),
    CalcHash("IdString"),
    CalcHash("NarrowString"),
    CalcHash("WideString"),
    CalcHash("char"),
    CalcHash("wchar")
};

function GetPodValue( field )
    local name = CalcHash( field:GetTypeName() )
    if name == CalcHash("bool") then
        local v = field:GetValueAsBool()
        Assert( v ~= nil, "ERROR: failed to convert to bool from: " .. field:GetTypeName() )
        return v;
    end

    if IndexOf( g_reflection_string_types, name ) ~= nil then
        local v = field:GetValue()
        Assert( v ~= nil, "ERROR: failed to convert to string from: " .. field:GetTypeName() )
        return v;
    end

    if IndexOf( g_reflection_number_types, name ) ~= nil then
        local v = field:GetValueAsNumber()
        Assert( v ~= nil, "ERROR: failed to convert to numeric from: " .. field:GetTypeName() )
        return v;
    end

    return nil
end

TypeContainerHelper = {};
TypeContainerHelper.mt = {
    __index = function( self, key )
        local ptr = rawget(self, "__ptr");

        local count = ptr:GetItemCount()
        if key == "count" then
            return count
        elseif type(key) == 'number' then
            local item = ptr:GetItem(key - 1)
            if item == nil then
                return nil
            end
    
            local value = GetPodValue(item)
            if value ~= nil then
                return value
            end
    
            return reflection_helper( item )
        end

        return nil
    end,
    size = function( self )
        local ptr = rawget(self, "__ptr");
        return ptr:GetItemCount();
    end,
    __len = function( self )
        local ptr = rawget(self, "__ptr");
        return ptr:GetItemCount();
    end
}

TypeValueHelper = {};
TypeValueHelper.mt = {
    __index = function( self, key )
        local ptr = rawget(self, "__ptr");

        local field = ptr:GetField(key)
        if not Assert(field ~= nil, "ERROR: there is no field '" .. key .. "'" ) then
            return nil
        end

        local value = GetPodValue(field)
        if value ~= nil then
            return value
        end

        return reflection_helper( field )
    end,
    __newindex = function( self, key, value )
        local ptr = rawget(self, "__ptr");

        local field = ptr:GetField(key)
        if field == nil then
            return nil
        end

        field:SetValue(tostring(value))
    end,
    __tostring = function( self )

        local ptr = rawget(self, "__ptr");

        local value = ptr:GetTypeName()
        value = value .. "\n{\n"

        for field_name in Iter( ptr:GetFieldNames() ) do
            value = value .. "    " .. field_name .. " = "

            local field = ptr:GetField(field_name)
            if field ~= nil then
                local field_value = GetPodValue(field)
                if field_value ~= nil then
                    value = value .. tostring(field_value)
                else
                    value = value .. "[" .. field:GetTypeName() .. "]"

                    local fieldRef = reflection_helper( field )

                    if field:IsContainer() then

                        value = value .. ".count = " .. tostring(fieldRef.count)

                        for i = 1, fieldRef.count do 
        
                            local fieldValueItem = fieldRef[i]

                            value = value .. "\n    [" .. tostring(i) .. "] ="

                            value = value .. "\n    {"

                            local singleItemString = tostring(fieldValueItem)

                            local singleItemStringSplit = Split( singleItemString, "\n" )

                            for j=1,#singleItemStringSplit do
                                if ( singleItemStringSplit[j] ~= "" and singleItemStringSplit[j] ~= nil ) then
                                    value = value .. "\n        " .. singleItemStringSplit[j]
                                end
                            end
                            
                            value = value .. "\n    },"
                        end
                    else
                        local fieldRefString = tostring(fieldRef)

                        local singleItemStringSplit = Split( fieldRefString, "\n" )

                        for j=1,#singleItemStringSplit do
                            if ( singleItemStringSplit[j] ~= "" and singleItemStringSplit[j] ~= nil ) then
                                value = value .. "\n    " .. singleItemStringSplit[j]
                            end
                        end
                    end
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

function reflection_helper( ptr, userdata )
    if not Assert(ptr ~= nil, "ERROR: nil") then
        return nil
    end

    ptr:SetRealSelfAwareType()

    if ptr:IsContainer() then
        local instance = setmetatable( {}, TypeContainerHelper.mt );
        rawset(instance, "__ptr", ptr:ToContainer());
        rawset(instance, "__userdata", userdata );
        return instance;
    else
        local instance = setmetatable( {}, TypeValueHelper.mt );
        rawset(instance, "__ptr", ptr);
        rawset(instance, "__userdata", userdata );
        return instance;
    end
end