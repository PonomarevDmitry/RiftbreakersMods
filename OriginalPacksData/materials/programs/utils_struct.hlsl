#ifndef UTILS_STRUCT
#define UTILS_STRUCT

#define POINT_LIGHT 0
#define SPOT_LIGHT 1
#define DIRECTIONAL_LIGHT 2

#define DIRECTIONAL_SHADOW_PENUMBRA 500.0
#define DIRECTIONAL_SHADOW_BIAS 0.0001
#define SPOT_SHADOW_PENUMBRA 0.5
#define SPOT_SHADOW_BIAS 0.0001
#define POINT_SHADOW_PENUMBRA 4.0
#define POINT_SHADOW_BIAS 0.0001

struct Surface
{
    float4                  WorldPos;
    float3                  Albedo;
    float3                  Normal;
    float3                  SubSurface;
    float3                  Emissive;
    float3                  Diffuse;
    float3                  Specular;
    float4                  Refraction;
    float                   Occlusion;
    float                   Roughness;
};

struct Lighting 
{
    float3                  Diffuse;
    float3                  Specular;  
};

struct Light
{       
    uint                    Type;                           // Directional, Point, Spotlight
    float3                  WorldPos;                       // Point, Spotlight
    float3                  WorldDir;                       // Directional, Spotlight 
    float                   LightInvSquareRadius;           // Point, Spotlight
    float3                  LightColor;                     // Directional, Point, Spotlight
    float                   ShadowIntensity;                // Directional, Point, Spotlight
    uint                    ShadowDataOffset;               // Directional, Spotlight, Point
    float                   ScatteringIntensity;            // Directional, Point, Spotlight
    float2                  LightCustomData;                // Spotlight

    inline float            GetSpotLightAngleScale()        { return LightCustomData.x; }
    inline float            GetSpotLightAngleOffset()       { return LightCustomData.y; }
};

#   if SHADOW_MAP || LIGHT_MASK
struct Shadow 
{
    matrix                  ShadowData0;
    float2                  ShadowData1;
    float2                  ShadowData2;
    float2                  ShadowViewportSize;
    float2                  ShadowNearFar;

    inline matrix           GetShadowViewProjMatrix()       { return ShadowData0; }
    inline float2           GetShadowNearFar()              { return ShadowNearFar.xy; }
    inline float2           GetShadowRemapNearFar()         { return ShadowData1.xy; }
    inline float2           GetShadowViewportSize()         { return ShadowViewportSize.xy; }
    inline float2           GetShadowLightSize()            { return ShadowData2.xy; }
    inline float2           GetShadowViewportOffset()       { return ShadowData1.xy; }
    inline float4           GetShadowViewportClamp()        { return float4( ShadowData1.xy, ShadowData1.xy + ShadowViewportSize.xy ); }
    
    inline float2 GetShadowViewportOffset( int viewportIdx )
    {              
        int row = viewportIdx / 2u; 
        int column  = ( viewportIdx % 2u ) * 2u;
        return float2( ShadowData0[ row ][ column ], ShadowData0[ row ][ column + 1 ] );
    }

    inline float4 GetShadowViewportClamp( int viewportIdx )
    { 
        float2 leftTop = GetShadowViewportOffset( viewportIdx );
        float2 rightBottom = leftTop + GetShadowViewportSize();
        return float4( leftTop + ShadowData0._m32_m33, rightBottom - ShadowData0._m32_m33 );
    }

    inline float2 GetShadowViewportTexel()
    {
        return ShadowData0._m32_m33; 
    }
};
#   endif
#endif