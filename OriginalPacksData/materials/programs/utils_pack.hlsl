
float2 oct_wrap( float2 v )
{
    return ( 1.0 - abs( v.yx ) ) * ( v.xy >= 0.0 ? 1.0 : -1.0 );
}

float2 pack_normal_xy_to_2ubyte( float3 normal )
{
    //Octahedron-normal vectors
    normal /= ( abs( normal.x ) + abs( normal.y ) + abs( normal.z ) );
    normal.xy = normal.z >= 0.0 ? normal.xy : oct_wrap( normal.xy );
    normal.xy = normal.xy * 0.5 + 0.5;
    return normal.xy;

    //Spheremap Transform
    //float p = sqrt(normal.z*8+8);
    //return float2( normal.xy / p + 0.5);

    //Store X&Y, reconstruct Z
    //return normal.xy * 0.5 + 0.5;
}

float3 unpack_normal_from_2ubyte_xy( float2 packed_norm )
{    
    //Octahedron-normal vectors (optimized)
    packed_norm = packed_norm * 2.0 - 1.0;
    float3 n = float3( packed_norm.x, packed_norm.y, 1.0 - abs( packed_norm.x ) - abs( packed_norm.y ) );
    float t = saturate( -n.z );
    n.xy += n.xy >= 0.0 ? -t : t;
    return normalize( n );

    //Octahedron-normal vectors
    //packed_norm = packed_norm * 2.0 - 1.0;
    //float3 n;
    //n.z = 1.0 - abs( packed_norm.x ) - abs( packed_norm.y );
    //n.xy = n.z >= 0.0 ? packed_norm.xy : oct_wrap( packed_norm.xy );
    //n = normalize( n );
    //return n;

    //Spheremap Transform
    //float2 fenc = packed_norm*4-2;
    //float f = dot(fenc,fenc);
    //float g = sqrt(1-f/4);
    //float3 n;
    //n.xy = fenc*g;
    //n.z = 1-f/2;
    //return n;

    //Store X&Y, reconstruct Z
    //float3 normal;
    //packed_norm.xy = ( packed_norm.xy - 0.5 ) * 2.0;
    //normal.xy = packed_norm.xy;
    //normal.z = sqrt( 1 - normal.x * normal.x - normal.y * normal.y );
    //return normal;
}

//#define PACKED 1 

float3 decodeNormal( float3 normal )
{
//#if defined PACKED == 1
//    return unpack_normal_from_2ubyte_xy( normal.xy );
//#endif
//#if defined PACKED == 2
    return normalize( ( normal * 2.0f ) - 1.0f );
//#endif
//    return normal;
}

float3 encodeNormal( float3 normal )
{   
//#if defined PACKED == 1
//    return float3( pack_normal_xy_to_2ubyte( normal ), 0.0f );
//#endif
//#if defined PACKED == 2
    return normal * 0.5f + 0.5f;
//#endif
//    return normalize( normal );
}
