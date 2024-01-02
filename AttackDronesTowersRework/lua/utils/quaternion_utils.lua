function QuatConj( quat )
    return { w = quat.w, x = -quat.x, y = -quat.y, z = -quat.z }
end

function QuatMulQuat( lhs, rhs )

    local result = {}

    result.w = ( ( lhs.w * rhs.w ) - ( lhs.x * rhs.x ) ) - ( ( lhs.y * rhs.y ) + ( lhs.z * rhs.z ) );
    result.x = ( ( lhs.w * rhs.x ) + ( lhs.x * rhs.w ) ) + ( ( lhs.y * rhs.z ) - ( lhs.z * rhs.y ) );
    result.y = ( ( lhs.w * rhs.y ) + ( lhs.y * rhs.w ) ) + ( ( lhs.z * rhs.x ) - ( lhs.x * rhs.z ) );
    result.z = ( ( lhs.w * rhs.z ) + ( lhs.z * rhs.w ) ) + ( ( lhs.x * rhs.y ) - ( lhs.y * rhs.x ) );

    return result;
end

function QuatMulVec3( quat, vec )

    local qv = { w = 0.0, x = vec.x, y = vec.y, z = vec.z };

    local oq = QuatMulQuat( QuatMulQuat( quat, qv ), QuatConj(quat) );

    return { x =  oq.x, y = oq.y, z = oq.z };
end

function MathRound( x )

    local result

    if ( x >= 0 ) then

        result = math.floor(x + 0.5)
    else
        result = math.ceil(x - 0.5)
    end

    return result
end