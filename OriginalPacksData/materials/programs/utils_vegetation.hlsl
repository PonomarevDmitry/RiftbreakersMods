/////////////////////////////////////////////// VEGETATION TREE //////////////////////////////////////////////

void VertexBending( inout float4 vPos, float4 bendingInfo )
{
    if ( bendingInfo.w > 0.0f )
    {
        const float b = 0.5;
        float lengthFromGround = length(vPos.xyz);
        float nH = vPos.y / bendingInfo.w;
        float blend = ( 1 - b ) * pow( abs( nH ), 3 ) + b * nH;
        float4 vNewPos = vPos;
        vNewPos.xz += bendingInfo.xz * blend;
        vPos.xyz = normalize(vNewPos.xyz) * lengthFromGround; 
    }
    else
    {
        float3 newPos = vPos.xyz;
        newPos.xz += bendingInfo.xy * vPos.y * vPos.y;
        float dist = length(vPos.xyz);
        vPos.xyz = normalize(newPos) * dist;
    }
}

void VertexDeform( inout float4 vPos, float3 vNormal, float3 vColor, float strength, float speed, float currentTime )
{
    float t1 = currentTime * 3.14f * speed;
    float t2 = currentTime * 4.71f * speed;

    float changeR = sin( t1 );
    float changeG = cos( t1 );
    float changeB = sin( t2 );
    
    float3 changeRGB = ( 1.0f + float3( changeR, changeG, changeB ) ) / 2.0f;

    vPos.xyz += vNormal.xyz * vColor.x * changeRGB.x * strength;
    vPos.xyz += vNormal.xyz * vColor.y * changeRGB.y * strength;
    vPos.xyz += vNormal.xyz * vColor.z * changeRGB.z * strength;
}

void VertexBump( inout float4 vPos, float3 vNormal, float strength )
{
    vPos.xyz += vNormal.xyz * strength;
    vPos.xyz += vNormal.xyz * strength;
    vPos.xyz += vNormal.xyz * strength;
}