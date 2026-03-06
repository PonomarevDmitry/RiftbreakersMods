-- math.MAXFLOAT = 3.402823466e+38
function GetBitFrom( key, t )
    local id = t[key]

    if not Assert( id ~= nil, "Unknow Type Passed " .. tostring( key ) ) then
        return nil
    end

    return 2 ^ (id - 1)
end

function HasBit( mask, bit )
    return mask % (bit * 2) >= bit
end
