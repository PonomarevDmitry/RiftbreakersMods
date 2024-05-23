cbuffer CSConstantBuffer : register(b0)
{
    matrix          cInvViewProjMatrix;
    float4          cVolumetricFogParams1;   	// x - scatteringDistribution, y - extinctionScale, z - maxDistance, w - fogDensity
    float4          cVolumetricFogParams2;   	// x - fogHeight, y - fogHeightFalloff, z - invFadeInDistance, w - fadeInFalloff
    float4      	cVolumetricFogAlbedo; 
#if USE_EMISSIVE   
    float4      	cVolumetricFogEmissive;
#endif
    float3      	cCameraWorldPos;
	float2 			cNearFarClip;
};

#include "materials/programs/volumetric_fog_internal.hlsl"

RWTexture3D< float4 > VBuffer0 : register( u0 );

#if USE_EMISSIVE
	RWTexture3D< float4 > VBuffer1 : register( u1 );
#endif

[numthreads( 4, 4, 4 )]
void main( uint3 dispatchThreadID : SV_DispatchThreadID )
{
	uint3 dims;
    VBuffer0.GetDimensions( dims.x, dims.y, dims.z );

	const uint3 did = dispatchThreadID;
    if ( any( did >= dims ) )
        return;

	float3 worldPos = GetVolumeWorldPos( did, dims, 0.5f );
	float globalDensity = cVolumetricFogParams1.w * exp2( -cVolumetricFogParams2.y * ( worldPos.y - cVolumetricFogParams2.x ) );

	float heightFogFactor = 0.5;
	float extinction = max( 0.0, globalDensity * cVolumetricFogParams1.y * heightFogFactor );
	float3 scattering = cVolumetricFogAlbedo.xyz * extinction;
	float absorption = max( 0.0, extinction - Luminance( scattering ) );

	VBuffer0[ did ] = float4( scattering, absorption );
#if USE_EMISSIVE
	VBuffer1[ did ] = float4( cVolumetricFogEmissive.xyz, 0.0 );
#endif
}