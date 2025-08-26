cbuffer CSConstantBuffer : register( b0 )
{
    matrix              	cInvViewProjMatrix;
#if SKYBOX_SPECULAR || SKYBOX_DIFFUSE
    float4      			cSkyboxParams;     // skyboxSpecularIntensity (x), skyboxDiffuseIntensity (y)
#endif
#if CLOUDS
    float4      			cCloudsParams;     // cloudsOpacity (x), cloudsDensity (y),  cloudsSpeed (zw)
    float       			cTime;
#endif
    float3      			cCameraWorldPos;
    int         			cNumLights;
    int2        			cViewportSize;
};

#if SKYBOX_DIFFUSE
	TextureCube         	tEnvDiffuse;
	SamplerState            sEnvDiffuse;
#endif

#if SKYBOX_SPECULAR
	Texture2D       		tEnvBRDF;
    SamplerState            sEnvBRDF;
    TextureCube         	tEnvSpecular;
    SamplerState        	sEnvSpecular;
#endif

Texture2D           		tOcclusionTex;
SamplerState        		sBilinearClamp;

#if SHADOW_MAP
    Texture2D             	tShadowTex;
	SamplerComparisonState  sShadowComparisonSampler;
#endif

#if CLOUDS
    Texture2D               tCloudsNoiseTex;
    SamplerState            sBilinearWrap;
#endif

#if LIGHT_MASK
    Texture2D               tLightMaskTex;
#endif

#if SHADOW_BUFFER
    Texture2D               tRaytracedShadowsTex;
#endif

Texture2D           		tGBuffer0;
Texture2D           		tGBuffer1;
Texture2D           		tGBuffer2;
Texture2D           		tGBuffer3;
Texture2D           		tGBuffer4;
Texture2D           		tDepthTex;

#include "materials/programs/utils_struct.hlsl"

StructuredBuffer<uint>      LightIndexList;
StructuredBuffer<Light>     Lights;

#if SHADOW_MAP || LIGHT_MASK
StructuredBuffer<Shadow>    Shadows;
#endif

#include "materials/programs/tiled_deferred_light_internal.hlsl"

RWTexture2D<float4> 		OutputTexture : register( u0 );

float3 GetWorldPos( float2 uv, float depth )
{
    float4 projPos = float4( uv * float2( 2.0, -2.0 ) + float2( -1.0, 1.0 ), depth, 1.0 );
    float4 worldPos = mul( cInvViewProjMatrix, projPos );
    return worldPos.xyz / worldPos.w;
}

[numthreads( TILED_DEFERRED_BLOCK_SIZE, TILED_DEFERRED_BLOCK_SIZE, 1 )]
void main( uint3 groupID : SV_GroupID, uint3 dispatchThreadID  : SV_DispatchThreadID )
{    
    const int3 did = int3( dispatchThreadID.xy, 0 );
    if ( any( did.xy >= cViewportSize.xy ) )
        return;

    const float depth = tDepthTex.Load( did ).r;
    const float2 texelSize = 1.0f / float2( cViewportSize.xy );
    const float2 uv = ( did.xy + 0.5f ) * texelSize;
    const float3 worldPos = GetWorldPos( uv, depth );

    float4 occlusionRoughnessMetalness = LoadOcclusionRoughnessMetalness( tGBuffer2, did );

    Surface surface;
    surface.Albedo = LoadAlbedo( tGBuffer0, did ).xyz;
    surface.WorldPos = float4( worldPos, 1.0f );
    surface.Normal = LoadNormal( tGBuffer1, did );
	surface.SubSurface = LoadCustomData( tGBuffer4, did );
	surface.Emissive = LoadCustomData( tGBuffer3, did );
    surface.Occlusion = GetOcclusion( tOcclusionTex, sBilinearClamp, uv ) * occlusionRoughnessMetalness.x;
    surface.Roughness = occlusionRoughnessMetalness.y;
    surface.Refraction = float4( 0.0, 0.0, 0.0, 0.0 );
    surface.Diffuse = lerp( surface.Albedo.xyz, 0.0f, occlusionRoughnessMetalness.z );
    surface.Specular = lerp( 0.04f, surface.Albedo.xyz, occlusionRoughnessMetalness.z );

    Lighting lighting;
    lighting.Diffuse = float3( 0.0, 0.0, 0.0 );
    lighting.Specular = float3( 0.0, 0.0, 0.0 );

    const uint linearTileIndex = LinearTileIndex( groupID.xy, cViewportSize.x );
    const uint lightIndexListAddress = linearTileIndex * TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT;
	const uint lastMaxLightIndex = cNumLights - 1;
	const uint lastLightBucket = min( lastMaxLightIndex / 32u, max( 0u, ( uint ) TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT - 1 ) );
	[loop]
	for ( uint lightBucket = 0; lightBucket <= lastLightBucket; ++lightBucket )
	{    
        uint lightBits = LightIndexList[ lightIndexListAddress + lightBucket ];
		[loop]
		while ( lightBits != 0 )
		{
			const uint lightBitIndex = firstbitlow( lightBits );
			const uint lightIndex = lightBucket * 32 + lightBitIndex;
			lightBits ^= 1u << lightBitIndex;

	        Light light = Lights[ lightIndex ];
	        switch ( light.Type )
	        {
	            case POINT_LIGHT:
	            {
	            	ComputePointLight( surface, light, lighting );
	            }
	            break;
	            case SPOT_LIGHT:
	            {
	            	ComputeSpotLight( surface, light, lighting );
	            }
	            break;
	            case DIRECTIONAL_LIGHT:
	            {	
	            	ComputeDirectionalLight( surface, light, uv, lighting );
	            }
	            break;
	        }
		}
	}

#if SHADOW_MAP
	//if ( did.x < 1024 && did.y < 1024 )
	//{
	//	float2 shadowUV = float2( ( did.x / 1024.0f ), did.y / 1024.0f );
	//	OutputTexture[ did.xy ] = float4( tShadowTex.SampleLevel( sBilinearClamp, shadowUV, 0.0f ).xxx * 5.0f, 1.0f );
	//	return;
	//}
#endif

	OutputTexture[ did.xy ] = float4( ComputeOutputColor( surface, lighting ), 1.0f );
}