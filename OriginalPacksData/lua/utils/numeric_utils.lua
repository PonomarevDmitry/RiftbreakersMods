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


return function(...)
end