cbuffer CSConstantBuffer : register(b0)
{
	matrix          cInvViewProjMatrix;
    float4          cVolumetricFogParams1;   	// x - scatteringDistribution, y - extinctionScale, z - maxDistance, w - fogDensity
    float4          cVolumetricFogParams2;   	// x - fogHeight, y - fogHeightFalloff, z - invFadeInDistance, w - fadeInFalloff
    float3          cCameraWorldPos;
	float2 			cNearFarClip;
};

#include "materials/programs/volumetric_fog_internal.hlsl"

Texture3D< float4> 		InputLightScattering 	: register( t0 );
RWTexture3D< float4 > 	OutputLightScattering 	: register( u0 );

[numthreads( 8, 8, 1 )]
void main( uint3 dispatchThreadID : SV_DispatchThreadID )
{
	uint3 dims;
    OutputLightScattering.GetDimensions( dims.x, dims.y, dims.z );

	const uint2 did = dispatchThreadID.xy;
	if ( any( did >= dims.xy ) )
        return;

    float accumDepth = 0.0;
	float4 accumScatteringTransmittance = float4( 0.0, 0.0, 0.0, 1.0 );
	float3 prevWorldPos = cCameraWorldPos;
	for ( uint textureDepth = 0; textureDepth < dims.z; textureDepth++ )
	{
		uint4 volumeUV = uint4( did.xy, textureDepth, 0 );
		float3 worldPos = GetVolumeWorldPos( volumeUV.xyz, dims, 0.5f );
		float thickness = length( worldPos - prevWorldPos );
		prevWorldPos = worldPos;
        accumDepth += thickness;

		float4 scatteringExtinction = InputLightScattering.Load( volumeUV );
		const float transmittance = exp( -scatteringExtinction.w * thickness ); 
        
		float scatteringFadeIn = pow( saturate( accumDepth * cVolumetricFogParams2.z ), cVolumetricFogParams2.w );
		float3 scatteringIntegratedOverSlice = scatteringFadeIn * scatteringExtinction.rgb * ( 1.0 - transmittance ) / max( scatteringExtinction.w, 0.00001f );
		accumScatteringTransmittance.rgb += scatteringIntegratedOverSlice * accumScatteringTransmittance.a;
		accumScatteringTransmittance.a *= lerp( 1.0f, transmittance, scatteringFadeIn );
	
		OutputLightScattering[ volumeUV.xyz ] = accumScatteringTransmittance;
	}
}
