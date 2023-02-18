#define FXAA_PC 1
#define FXAA_HLSL_5 1
#define FXAA_QUALITY__PRESET 12
//#define IN_GAMMA_CORRECT_MODE

#ifdef IN_GAMMA_CORRECT_MODE
    #define FXAA_LINEAR 1
#else
    #define FXAA_LINEAR 0
#endif

#include "materials/programs/fxaa_311.hlsl"

cbuffer FPConstantBuffer
{
    float4 cViewportSize;
    float  cAdjDispRange;
    float  cAdjLowerThreshold;
    float  cAdjNormScaleFactor;
};

struct FXAAConstants
{
    // {x_} = 1.0/screenWidthInPixels
    // {_y} = 1.0/screenHeightInPixels
    float2 rcpFrame;

    // This must be from a constant/uniform.
    // {x___} = 2.0/screenWidthInPixels
    // {_y__} = 2.0/screenHeightInPixels
    // {__z_} = 0.5/screenWidthInPixels
    // {___w} = 0.5/screenHeightInPixels
    float4 rcpFrameOpt;

    // {x___} = -N/screenWidthInPixels  
    // {_y__} = -N/screenHeightInPixels
    // {__z_} =  N/screenWidthInPixels  
    // {___w} =  N/screenHeightInPixels 
    float4 rcpFrameOpt2;

    // This can effect sharpness.
    //   1.00 - upper limit (softer)
    //   0.75 - default amount of filtering
    //   0.50 - lower limit (sharper, less sub-pixel aliasing removal)
    //   0.25 - almost off
    //   0.00 - completely off
    float fxaaQualitySubpix;

    // The minimum amount of local contrast required to apply algorithm.
    //   0.333 - too little (faster)
    //   0.250 - low quality
    //   0.166 - default
    //   0.125 - high quality 
    //   0.063 - overkill (slower)
    float fxaaQualityEdgeThreshold;

    // This used to be the FXAA_QUALITY__EDGE_THRESHOLD_MIN define.
    float fxaaQualityEdgeThresholdMin;

    // This used to be the FXAA_CONSOLE__EDGE_SHARPNESS define.
    float fxaaConsoleEdgeSharpness;

    // This used to be the FXAA_CONSOLE__EDGE_THRESHOLD define.
    float fxaaConsoleEdgeThreshold;

    // This used to be the FXAA_CONSOLE__EDGE_THRESHOLD_MIN define.
    float fxaaConsoleEdgeThresholdMin;

	float2 Packing;
    //    
    // Extra constants for 360 FXAA Console only.
    float4 fxaaConsole360ConstDir;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  TexCoord    : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4  Color       : SV_TARGET;
};

SamplerState sSamplerTex : register(s0);
Texture2D	 tSamplerTex : register(t0);

PS_OUTPUT luma_fp(VS_OUTPUT In)
{
	PS_OUTPUT Out;

    Out.Color = tSamplerTex.Sample( sSamplerTex, In.TexCoord.xy );
    
 #ifdef IN_GAMMA_CORRECT_MODE
    Out.Color.a = dot( sqrt(Out.Color.rgb), float3(0.299, 0.587, 0.114) ); // compute luma
 #else
    Out.Color.a = dot(Out.Color.rgb, float3(0.299, 0.587, 0.114)); // compute luma
 #endif

    return Out;
}

PS_OUTPUT main_fp(VS_OUTPUT In)
{
	PS_OUTPUT Out;

    FXAAConstants g_FXAA;
    // {x_} = 1.0/screenWidthInPixels
    // {_y} = 1.0/screenHeightInPixels
    g_FXAA.rcpFrame[ 0 ] = 1.0 / (float)cViewportSize.x;
    g_FXAA.rcpFrame[ 1 ] = 1.0 / (float)cViewportSize.y;

    // {x___} = 2.0/screenWidthInPixels
    // {_y__} = 2.0/screenHeightInPixels
    // {__z_} = 0.5/screenWidthInPixels
    // {___w} = 0.5/screenHeightInPixels
    g_FXAA.rcpFrameOpt[ 0 ] = 2.0 / (float)cViewportSize.x;
    g_FXAA.rcpFrameOpt[ 1 ] = 2.0 / (float)cViewportSize.y;
    g_FXAA.rcpFrameOpt[ 2 ] = 0.5 / (float)cViewportSize.x;
    g_FXAA.rcpFrameOpt[ 3 ] = 0.5 / (float)cViewportSize.y;

    // {x___} = -N/screenWidthInPixels  
    // {_y__} = -N/screenHeightInPixels
    // {__z_} =  N/screenWidthInPixels  
    // {___w} =  N/screenHeightInPixels 

    float N = 0.5;
    g_FXAA.rcpFrameOpt2[ 0 ] = -N / (float)cViewportSize.x;
    g_FXAA.rcpFrameOpt2[ 1 ] = -N / (float)cViewportSize.y;
    g_FXAA.rcpFrameOpt2[ 2 ] = N / (float)cViewportSize.x;
    g_FXAA.rcpFrameOpt2[ 3 ] = N / (float)cViewportSize.y;

    // This can effect sharpness.
    //   1.00 - upper limit (softer)
    //   0.75 - default amount of filtering
    //   0.50 - lower limit (sharper, less sub-pixel aliasing removal)
    //   0.25 - almost off
    //   0.00 - completely off
    g_FXAA.fxaaQualitySubpix = 0.50;

    // Only used on FXAA Quality.
    // This used to be the FXAA_QUALITY__EDGE_THRESHOLD define.
    // It is here now to allow easier tuning.
    // The minimum amount of local contrast required to apply algorithm.
    //   0.333 - too little (faster)
    //   0.250 - low quality
    //   0.166 - default
    //   0.125 - high quality 
    //   0.063 - overkill (slower)
    g_FXAA.fxaaQualityEdgeThreshold = 0.166;

    // Only used on FXAA Quality.
    // This used to be the FXAA_QUALITY__EDGE_THRESHOLD_MIN define.
    // It is here now to allow easier tuning.
    // Trims the algorithm from processing darks.
    //   0.0833 - upper limit (default, the start of visible unfiltered edges)
    //   0.0625 - high quality (faster)
    //   0.0312 - visible limit (slower)
    // Special notes when using FXAA_GREEN_AS_LUMA,
    //   Likely want to set this to zero.
    //   As colors that are mostly not-green
    //   will appear very dark in the green channel!
    //   Tune by looking at mostly non-green content,
    //   then start at zero and increase until aliasing is a problem.
    g_FXAA.fxaaQualityEdgeThresholdMin = 0.0625;

    FxaaTex tex;
    tex.smpl = sSamplerTex;
    tex.tex  = tSamplerTex;

    float2 screenPos = In.Position.xy;
#ifdef FXAA_GATHER_ISSUE_WORKAROUND
    screenPos.xy = (screenPos.xy + 0.001);
#endif

    Out.Color = FxaaPixelShader( screenPos.xy * g_FXAA.rcpFrame.xy, float4( 0, 0, 0, 0 ), tex,tex,tex, g_FXAA.rcpFrame, g_FXAA.rcpFrameOpt,g_FXAA.rcpFrameOpt2,g_FXAA.rcpFrameOpt2,
        g_FXAA.fxaaQualitySubpix,
        g_FXAA.fxaaQualityEdgeThreshold,
        g_FXAA.fxaaQualityEdgeThresholdMin,
        g_FXAA.fxaaConsoleEdgeSharpness,
        g_FXAA.fxaaConsoleEdgeThreshold,
        g_FXAA.fxaaConsoleEdgeThresholdMin,
        g_FXAA.fxaaConsole360ConstDir	
	 );

    //Out.Color = tSamplerTex.Sample( sSamplerTex, In.TexCoord.xy );

	return Out;
}