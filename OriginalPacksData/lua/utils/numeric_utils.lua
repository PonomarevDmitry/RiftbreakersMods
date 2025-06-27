function RoundUnderOffset( value, offset)
    local sign = 1
	
	if ( value < 0 ) then
		sign = -1
	end
	
	value = value * sign
	
	local integral = math.floor( value )
	local mantissa = value - integral
	
	if ( mantissa < offset ) then
		return math.floor(integral * sign)
	end
	
    return math.floor( (integral * sign ) + sign )
end

function SnapValue( value, snap )
	return RoundUnderOffset( value / snap, 0.5 ) * snap
end

function CreateQuaternion( axis, angle )
	local quaternion = {}
	local halfAngle = math.rad(angle) * 0.5
	local s = math.sin(halfAngle)
	quaternion.x = axis.x * s
	quaternion.y = axis.y * s
	quaternion.z = axis.z * s
	quaternion.w = math.cos(halfAngle)
	return quaternion
end

function Sign( x )
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end

function QuatToEuler( q )
    local sinp_cosp = 2 * ( q.w * q.x + q.y * q.z )
    local cosp_cosp = 1 - 2 * ( q.x * q.x + q.y * q.y )
    local pitch = math.atan2( sinp_cosp, cosp_cosp )


    local siny = 2 * ( q.w * q.y - q.z * q.x )
    local yaw = 0
    if math.abs( siny ) >= 1 then
        yaw = math.pi / 2 * Sign( siny )
    else
        yaw = math.asin( siny )
    end

    local sinr_cosp = 2 * ( q.w * q.z + q.x * q.y )
    local cosr_cosp = 1 - 2 * ( q.y * q.y + q.z * q.z )
    local roll = math.atan2(sinr_cosp, cosr_cosp)

    if math.abs( yaw ) == math.pi / 2 then
        pitch = 0
        roll = 0
    end

    return pitch, yaw, roll
end


function Lerp( minValue, maxValue, t )
	return (minValue * (1 - t) + maxValue * t);
end

function Clamp( x, minValue, maxValue )
	return math.min(math.max(x, minValue), maxValue);
end

function  Length( vector )
	return math.sqrt( vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
end

function  Distance( vector1, vector2 )
	local vector = {}
	vector.x = (vector2.x - vector1.x)
	vector.y = (vector2.y - vector1.y)
	vector.z = (vector2.z - vector1.z)
	return math.sqrt( vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
end

function Normalize( vector )
	return VectorMulByNumber( vector, 1.0 / Length(vector))
end

function DotProduct( vector1, vector2 )
 	return vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z;
end

function  VectorSub( vector1, vector2 )
	local vector = {}
	vector.x = (vector1.x - vector2.x)
	vector.y = (vector1.y - vector2.y)
	vector.z = (vector1.z - vector2.z)
	return vector
end

function  VectorMul( vector1, vector2 )
	local vector = {}
	vector.x = (vector1.x * vector2.x)
	vector.y = (vector1.y * vector2.y)
	vector.z = (vector1.z * vector2.z)
	return vector
end

function  VectorDiv( vector1, vector2 )
	local vector = {}
	vector.x = (vector1.x / vector2.x)
	vector.y = (vector1.y / vector2.y)
	vector.z = (vector1.z / vector2.z)
	return vector
end

function  VectorAdd( vector1, vector2 )
	local vector = {}
	vector.x = (vector2.x + vector1.x)
	vector.y = (vector2.y + vector1.y)
	vector.z = (vector2.z + vector1.z)
	return vector
end

function  VectorMulByNumber( vector1, value )
	local vector = {}
	vector.x = (value * vector1.x)
	vector.y = (value * vector1.y)
	vector.z = (value * vector1.z)
	return vector
end

function VectorLerp( minVector1, maxVector2, t )
	return VectorAdd( VectorMulByNumber( minVector1, (1 - t) ), VectorMulByNumber( maxVector2, t ) );
end

return function(...)
end