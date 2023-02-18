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
