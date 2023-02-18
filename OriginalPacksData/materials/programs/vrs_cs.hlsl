static const uint AXIS_SHADING_RATE_1X = 0x0;                                                            
static const uint AXIS_SHADING_RATE_2X = 0x1;                                                            
#define MAKE_SHADING_RATE(x,y) ((x << 2) | (y))                                                          
                                                                                                         
#if VRS_TILESIZE == 8                                                                                    
static const uint threadCount1D = 8;                                                                     
static const uint numBlocks1D = 2;                                                                       
#elif VRS_TILESIZE == 16                                                                                 
static const uint threadCount1D = 8;                                                                     
static const uint numBlocks1D = 1;                                                                       
#else // VRS_TILESIZE == 32                                                                              
static const uint threadCount1D = 16;                                                                    
static const uint numBlocks1D = 1;                                                                       
#endif                                                                                                   
static const uint threadCount = threadCount1D * threadCount1D;                                           
static const uint sampleCount1D = 2 * threadCount1D + 2;                                                 
static const uint sampleCount = sampleCount1D * sampleCount1D;                                           
static const uint numBlocks = numBlocks1D * numBlocks1D;                                                 
                                                                                                         
// groupshared buffers to pre-load luminance                                                             
groupshared float    groupLum[sampleCount];                                                              
                                                                                                         
// Texture definitions                                                                                   
RWTexture2D<uint>    imgDestination : register(u0);                                                      
Texture2D            texColor       : register(t0);                                                      
#if VRS_USE_MOTIONVECTORS                                                                                
Texture2D            texVelocity    : register(t1);                                                      
#endif /* VRS_USE_MOTIONVECTORS    */                                                                    
                                                                                                         
// Constant Buffer                                                                                       
cbuffer cb0                                                                                              
{       
#if VRS_USE_MOTIONVECTORS                                                                                                      
    float4    g_Resolution;      
    float     g_MotionFactor;      
#endif                                                                       
    float     g_VarianceCutoff;                                               
}                                                                                                        

float Luminance(float3 color)
{
    return dot(color, float3(0.30, 0.59, 0.11));
}                                                    
                                                                                                         
float GetLuminance(int2 uv)                                                                              
{                                                                                                        
#if VRS_USE_MOTIONVECTORS                                                                                
    //float2 v = MotionVec2D(uv);    
    float2 v = texVelocity[uv].xy * float2(0.5f, -0.5f) * g_Resolution.xy;                                                                      
    uv = uv - round(v);                                                                                  
    // clamp to screen                                                                                   
    if (uv.x < 0) uv.x = 0;                                                                              
    if (uv.y < 0) uv.y = 0;                                                                              
    if (uv.x >= g_Resolution.x) uv.x = g_Resolution.x - 1;                                               
    if (uv.y >= g_Resolution.y) uv.y = g_Resolution.y - 1;                                               
#endif                                                                                                   
    return Luminance(texColor[uv].xyz);                                                                                
}                                                                                                        
                                                                                                         
uint flattenLdsOffset(uint2 coord)                                                                       
{                                                                                                        
    return coord.y * sampleCount1D + coord.x;                                                            
}                                                                                                        
                                                                                                         
/*--------------------------------------------------------------------------------------*/               
/* Main function (without additional shading rates)                                     */               
/*--------------------------------------------------------------------------------------*/               
[numthreads(threadCount1D, threadCount1D, 1)]                                                            
void mainCS(                                                                                             
    uint3 Gid : SV_GroupID,                                                                              
    uint3 Gtid : SV_GroupThreadID,                                                                       
    uint3 Dtid : SV_DispatchThreadID,                                                                    
    uint Gidx : SV_GroupIndex )                                                                          
{                                                                                                        
    int2 tileOffset = Gid.xy * threadCount1D * 2;                                                        
    int2 baseOffset = tileOffset + int2(-1, -1);                                                         
    uint index = Gidx;                                                                                   
                                                                                                         
    /* sample source texture (using motion vectors), reduce to luminance and store in LDS */             
    while (index < sampleCount)                                                                          
    {                                                                                                    
        int2 index2D = int2(index % sampleCount1D, index / sampleCount1D);                              
        groupLum[index] = GetLuminance(baseOffset + index2D);                                            
        index += threadCount;                                                                            
    }                                                                                                    
                                                                                                         
    GroupMemoryBarrierWithGroupSync();                                                                   
                                                                                                         
    /* upper left coordinate in LDS */                                                                   
    uint2 threadUV = uint2(1, 1) + (Gtid.xy * 2);                                                        
                                                                                                         
    /* sample luminance outside the box, to combat burn in effect fur to frame dependence */             
    float4 lumH;                                                                                         
    lumH.x = groupLum[flattenLdsOffset(threadUV + uint2(0, 0))];                                         
    lumH.y = groupLum[flattenLdsOffset(threadUV + uint2(2, 0))];                                         
    lumH.z = groupLum[flattenLdsOffset(threadUV + uint2(-1, 1))];                                        
    lumH.w = groupLum[flattenLdsOffset(threadUV + uint2(1, 1))];                                         
    float2 diffH = abs(lumH.xz - lumH.yw);                                                               
    diffH.x = max(diffH.x, diffH.y);                                                                     
                                                                                                         
    float4 lumV;                                                                                         
    lumV.x = groupLum[flattenLdsOffset(threadUV + uint2(0, -1))];                                        
    lumV.y = groupLum[flattenLdsOffset(threadUV + uint2(0, 1))];                                         
    lumV.z = groupLum[flattenLdsOffset(threadUV + uint2(1, 0))];                                         
    lumV.w = groupLum[flattenLdsOffset(threadUV + uint2(1, 2))];                                         
    float2 diffV = abs(lumV.xz - lumV.yw);                                                               
    diffV.x = max(diffV.x, diffV.y);                                                                     
                                                                                                         
#if VRS_USE_MOTIONVECTORS                                                                                
    /* reduce shading rate for fast moving pixels */                                                     
    float v = length(texVelocity[Dtid.xy * 2].xy * float2(0.5f, -0.5f) * g_Resolution.xy);                  
    v *= g_MotionFactor;                                                                                 
    diffH.x = max(0, diffH.x - v);                                                                       
    diffV.x = max(0, diffV.x - v);                                                                       
#endif                                                                                                   
                                                                                                         
    /* Reduction: find maximum variance within VRS tile */                                               
#if VRS_TILESIZE > 8                                                                                     
    diffH.x = WaveActiveMax(diffH.x);                                                                    
    diffV.x = WaveActiveMax(diffV.x);                                                                    
    if (Gidx < numBlocks)                                                                                
    {                                                                                                    
        uint shadingRateH = (diffH.x >= g_VarianceCutoff) ? AXIS_SHADING_RATE_1X : AXIS_SHADING_RATE_2X; 
        uint shadingRateV = (diffV.x >= g_VarianceCutoff) ? AXIS_SHADING_RATE_1X : AXIS_SHADING_RATE_2X; 
        uint shadingRate = MAKE_SHADING_RATE(shadingRateH, shadingRateV);    
                                                                                                         
        /* Store */                                                                                      
        imgDestination[Gid.xy] = shadingRate;                                                            
    }                                                                                                    
#else                                                                                                    
    float4 diffX=0;                                                                                      
    float4 diffY=0;                                                                                      
    unsigned int idx = (Gtid.y & (numBlocks1D - 1)) * 2 + (Gtid.x & (numBlocks1D - 1));                  
    diffX[idx] = diffH.x;                                                                                
    diffY[idx] = diffV.x;                                                                                
    diffX = WaveActiveMax(diffX);                                                                        
    diffY = WaveActiveMax(diffY);                                                                        
                                                                                                         
    /* write out shading rates to VRS image */                                                           
    if (Gidx < numBlocks)                                                                                
    {                                                                                                    
        float varH = diffX[Gidx];                                                                        
        float varV = diffY[Gidx];                                                                        
                                                                                                         
        /* encode value based on orientation an variance */                                              
        uint shadingRateH = (varH > g_VarianceCutoff) ? AXIS_SHADING_RATE_1X : AXIS_SHADING_RATE_2X;     
        uint shadingRateV = (varV > g_VarianceCutoff) ? AXIS_SHADING_RATE_1X : AXIS_SHADING_RATE_2X;     
        uint shadingRate = MAKE_SHADING_RATE(shadingRateH, shadingRateV);                                
                                                                                                         
        /* Store */                                                                                      
        imgDestination[Gid.xy * numBlocks1D + uint2(Gidx / 2, Gidx % 2)] = shadingRate;                 
    }                                                                                                    
#endif
}                                                                                    