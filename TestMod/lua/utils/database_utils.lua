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

function DatabaseFullLog( database )

    local stringKeys = database:GetStringKeys()
    for key in Iter( stringKeys ) do

        local value = database:GetString(key)
        
        LogService:Log("database.String[" .. key .. "] = " .. value )
    end

    local floatKeys = database:GetFloatKeys()
    for key in Iter( floatKeys ) do

        local value = database:GetFloat(key)
        
        LogService:Log("database.Float[" .. key .. "] = " .. tostring(value) )
    end

    local intKeys = database:GetIntKeys()
    for key in Iter( intKeys ) do

        local value = database:GetInt(key)
        
        LogService:Log("database.Int[" .. key .. "] = " .. tostring(value) )
    end
end

