function DatabaseConcatenate( database1, database2 )

    local stringKeys = database2:GetStringKeys()
    for key in Iter( stringKeys ) do
        database1:SetString( key, database2:GetString(key))
    end

    local floatKeys = database2:GetFloatKeys()
    for key in Iter( floatKeys ) do
        database1:SetFloat( key, database2:GetFloat(key))
    end

    local intKeys = database2:GetIntKeys()
    for key in Iter( intKeys ) do
        database1:SetInt( key, database2:GetInt(key))
    end
end

function GetDatabaseFullLog( database )

    local result = "{\n"

    local stringKeys = database:GetStringKeys()
    if ( #stringKeys > 0 ) then

        table.sort(stringKeys, function(a, b) return a:upper() < b:upper() end)

        result = result .. "    Strings\n    {\n"

        for key in Iter( stringKeys ) do

            local value = database:GetString(key)

            result = result .. "        [\"" .. key .. "\"] = \"" .. value .. "\"\n"
        end

        result = result .. "    }\n"
    end

    local floatKeys = database:GetFloatKeys()
    if ( #floatKeys > 0 ) then

        table.sort(floatKeys, function(a, b) return a:upper() < b:upper() end)

        result = result .. "    Floats\n    {\n"

        for key in Iter( floatKeys ) do

            local value = database:GetFloat(key)

            result = result .. "        [\"" .. key .. "\"] = " .. tostring(value) .. "\n"
        end

        result = result .. "    }\n"
    end

    local intKeys = database:GetIntKeys()
    if ( #intKeys > 0 ) then

        table.sort(intKeys, function(a, b) return a:upper() < b:upper() end)

        result = result .. "    Ints\n    {\n"

        for key in Iter( intKeys ) do

            local value = database:GetInt(key)

            result = result .. "        [\"" .. key .. "\"] = " .. tostring(value) .. "\n"
        end

        result = result .. "    }\n"
    end

    result = result .. "}"

    return result
end

function DatabaseFullLog( database )

    local text = GetDatabaseFullLog( database )

    LogService:Log(text)
end

