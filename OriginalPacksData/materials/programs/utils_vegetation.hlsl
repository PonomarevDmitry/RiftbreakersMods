/////////////////////////////////////////////// VEGETATION TREE //////////////////////////////////////////////

#define SIDE_TO_SIDE_FREQ1 0.1975 * 5
#define SIDE_TO_SIDE_FREQ2 0.0793 * 5
#define UP_AND_DOWN_FREQ1 0.375
#define UP_AND_DOWN_FREQ2 0.193 
#define BRANCH_AMPLITUDE_SCALER 0.0004f * 0.75f

float4 SmoothCurve(float4 x)
{
    return x * x * (3.0 - 2.0 * x);
}
float4 TriangleWave(float4 x)
{
    return abs(frac(x + 0.5) * 2.0 - 1.0);
}
float4 SmoothTriangleWave(float4 x)
{
    return SmoothCurve(TriangleWave(x));
}

void ApplyTrunkBend(inout float4 vPos, in float4 treeInfo )
{
    const float b = 0.5;
    float lengthFromGround = length(vPos.xyz);
    float nH = vPos.y / treeInfo.w;
    float blend = ( 1 - b ) * pow( abs( nH ), 3 ) + b * nH;
    float4 vNewPos = vPos;
    vNewPos.xz += treeInfo.xz * blend;
    vPos.xyz = normalize(vNewPos.xyz) * lengthFromGround;
}

void ApplyBranchBend( 
    inout float4 vPos, 
    in float3    vNormal,
    in float3    treePos,
    in float     branchElasticity, 
    in float     time, 
    in float     windForce
    )
{
    float speed = 0.3;
    float treePhase = dot( treePos, 1.0f);
    float branchPhase = treePhase + 3.0f;
    float vertexPhase = dot( vPos.xyz, branchPhase );
    float2 phase = time + float2(vertexPhase, branchPhase);
    float4 waves = ( frac( phase.xxyy *
					   float4( SIDE_TO_SIDE_FREQ1, SIDE_TO_SIDE_FREQ2, UP_AND_DOWN_FREQ1, UP_AND_DOWN_FREQ2 ) ) *
					   2.0 - 1.0 ) * speed;
    float4 sines = SmoothTriangleWave(waves);
    float2 sinesSum = sines.xy + sines.zw;
    float branchAmplitude = windForce * BRANCH_AMPLITUDE_SCALER;
    vPos.xyz += sinesSum.x * float3( branchElasticity * vNormal.xyz * branchAmplitude );
}

/////////////////////////////////////////////// VEGETATION BASIC //////////////////////////////////////////////

// vBendParams.x = windir x
// vBendParams.y = windir y
// vBendParams.z = bending strength

// Main vegetation bending animation (applied on entire vegetation)
void MainBending( inout float4 vPos, float2 wind )
{
    float3 newPos = vPos.xyz;
    newPos.xz += wind.xy * vPos.y * vPos.y;
    float dist = length(vPos.xyz);
    vPos.xyz = normalize(newPos) * dist;
}

// vBendDetailParams.x = time
// vBendDetailParams.y = detail bend frequency
// vBendDetailParams.z = detail bend leaf amplitude
// vBendDetailParams.w = bend detail phase

// vVertexInfo.x = vertex color R ( edge info )
// vVertexInfo.y = vertex color G ( brach phase )
// vVertexInfo.z = vertex color B ( brach bend amount )
// vVertexInfo.w = bend detail branch amplitude

void DetailBending(half3 worldPos, inout float4 vPos, float3 vNormal, half3 vVertexInfo, half4 vBendDetailParams, float currentTime)
{
    half fSpeed = vBendDetailParams.w;

    #if USE_GRASS_BRANCH == 1
        fSpeed *= vPos.y;
    #endif

    half fDetailFreq = vBendDetailParams.x;
    half fDetailLeafAmp = vBendDetailParams.y;
    half fDetailBranchAmp = vBendDetailParams.z;

    half fEdgeAtten = vVertexInfo.x;
    half fBranchPhase = vVertexInfo.y;
    half fBranchAtten = vVertexInfo.z;

    // Phases (object, vertex, branch)
    half fObjPhase = (dot(worldPos.xyz, 2));
    fBranchPhase += fObjPhase;

    half fVtxPhase = (dot(vPos.xyz, fBranchPhase));

    // Detail bending for leaves/grass
    // x: is used for edges, y is used for branch
    half2 vWavesIn = currentTime;
    vWavesIn += half2(fVtxPhase, fBranchPhase);

    half4 vWaves = (frac(vWavesIn.xxyy * half4(1.975, 0.793, 0.375,  0.193)) * 2.0 - 1.0) * fDetailFreq * fSpeed;
    vWaves = TriangleWave(vWaves);

    // x: is used for edges, y is used for branches
    half2 vWavesSum = ((vWaves.xz + vWaves.yw));

    // Edge and branch bending (xz is used for edges, y for branches)
    vPos.xyz += vWavesSum.xyx * half3(fEdgeAtten * fDetailLeafAmp * vNormal.x, fBranchAtten * fDetailBranchAmp, fEdgeAtten * fDetailLeafAmp * vNormal.z);
}

void VertexBending(inout float4 vPos, half3 BendInfoLocal, inout float3 vNormal, half3 vVertexInfo, half3 worldPos, half4 vBendDetailParams, float currentTime )
{
    DetailBending( worldPos, vPos, vNormal, vVertexInfo, vBendDetailParams, currentTime );
    MainBending( vPos, BendInfoLocal.xy );
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