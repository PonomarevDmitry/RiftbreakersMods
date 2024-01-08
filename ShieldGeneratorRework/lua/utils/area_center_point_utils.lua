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

function GetDistanceAndClosestPositionToLineSegment(entity, ownerEntity, pointEntity)

    local ownerPosition = EntityService:GetPosition(ownerEntity)
    if ( ownerEntity == pointEntity ) then

        return EntityService:GetDistance2DBetween(entity, ownerEntity), ownerPosition
    end

    local pointPosition = EntityService:GetPosition(pointEntity)

    local abx = pointPosition.x - ownerPosition.x
    local abz = pointPosition.z - ownerPosition.z

    if ( abx == 0 and abz == 0 ) then

        return EntityService:GetDistance2DBetween(entity, ownerEntity), ownerPosition
    end

    local entityPosition = EntityService:GetPosition(entity)

    local dacab = (entityPosition.x - ownerPosition.x) * abx + (entityPosition.z - ownerPosition.z) * abz
    local dab = abx * abx + abz * abz

    local coef = dacab / dab

    if ( 0 <= coef and coef <= 1) then

        local projectionX = ownerPosition.x + abx * coef
        local projectionZ = ownerPosition.z + abz * coef

        local result = math.sqrt( (entityPosition.x - projectionX) * (entityPosition.x - projectionX) + (entityPosition.z - projectionZ) * (entityPosition.z - projectionZ) )

        local newPosition = {}
        newPosition.x = projectionX
        newPosition.y = 0
        newPosition.z = projectionZ

        return result, newPosition
    end

    local distance1 = EntityService:GetDistance2DBetween(entity, ownerEntity)
    local distance2 = EntityService:GetDistance2DBetween(entity, pointEntity)

    if ( distance1 < distance2) then
        return distance1, ownerPosition
    else
        return distance2, pointPosition
    end
end