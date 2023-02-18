#include "materials/programs/compat.hlsl"

/*
** Copyright (c) 2012, Romain Dura romain@shazbits.com
**
** Permission to use, copy, modify, and/or distribute this software for any
** purpose with or without fee is hereby granted, provided that the above
** copyright notice and this permission notice appear in all copies.
**
** THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
** WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
** MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
** SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
** WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
** ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
** IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

/*
** Photoshop & misc math
** Blending modes, RGB/HSL/Contrast/Desaturate, levels control
**
** Romain Dura | Romz
** Blog: http://mouaif.wordpress.com
** Post: http://mouaif.wordpress.com/?p=94
*/

/*
** Desaturation
*/

float4 Desaturate(float3 color, float Desaturation)
{
	float3 grayXfer = float3(0.3, 0.59, 0.11);
	float grayf = dot(grayXfer, color);
	float3 gray = float3(grayf, grayf, grayf);
	return float4(lerp(color, gray, Desaturation), 1.0);
}


/*
** Hue, saturation, luminance
*/

float3 RGBToHSL(float3 color)
{
	float3 hsl = float3( 0.0, 0.0, 0.0 ); // init to 0 to avoid warnings ? (and reverse if + remove first part)

	float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
	float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
	float delta = fmax - fmin; //Delta RGB value

	hsl.z = (fmax + fmin) / 2.0; // Luminance

	if (delta == 0.0)	//This is a gray, no chroma...
	{
		hsl.x = 0.0;	// Hue
		hsl.y = 0.0;	// Saturation
	}
	else //Chromatic data...
	{
		if (hsl.z < 0.5)
			hsl.y = delta / (fmax + fmin); // Saturation
		else
			hsl.y = delta / (2.0 - fmax - fmin); // Saturation

		float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
		float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
		float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;

		if (color.r == fmax )
			hsl.x = deltaB - deltaG; // Hue
		else if (color.g == fmax)
			hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
		else if (color.b == fmax)
			hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue

		if (hsl.x < 0.0)
			hsl.x += 1.0; // Hue
		else if (hsl.x > 1.0)
			hsl.x -= 1.0; // Hue
	}

	return hsl;
}

float HueToRGB(float f1, float f2, float hue)
{
	if (hue < 0.0)
		hue += 1.0;
	else if (hue > 1.0)
		hue -= 1.0;
	float res;
	if ((6.0 * hue) < 1.0)
		res = f1 + (f2 - f1) * 6.0 * hue;
	else if ((2.0 * hue) < 1.0)
		res = f2;
	else if ((3.0 * hue) < 2.0)
		res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
	else
		res = f1;
	return res;
}

float3 HSLToRGB(float3 hsl)
{
	float3 rgb;

	if (hsl.y == 0.0)
		rgb = float3(hsl.z, hsl.z, hsl.z); // Luminance
	else
	{
		float f2;

		if (hsl.z < 0.5)
			f2 = hsl.z * (1.0 + hsl.y);
		else
			f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);

		float f1 = 2.0 * hsl.z - f2;

		rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
		rgb.g = HueToRGB(f1, f2, hsl.x);
		rgb.b= HueToRGB(f1, f2, hsl.x - (1.0/3.0));
	}

	return rgb;
}

/*
** Contrast, saturation, brightness
** Code of this function is from TGM's shader pack
** http://irrlicht.sourceforge.net/phpBB2/viewtopic.php?t=21057
*/

// For all settings: 1.0 = 100% 0.5=50% 1.5 = 150%
float3 ContrastSaturationBrightness(float3 color, float brt, float sat, float con)
{
	// Increase or decrease theese values to adjust r, g and b color channels seperately
	const float AvgLumR = 0.5;
	const float AvgLumG = 0.5;
	const float AvgLumB = 0.5;

	const float3 LumCoeff = float3(0.2125, 0.7154, 0.0721);

	float3 AvgLumin = float3(AvgLumR, AvgLumG, AvgLumB);
	float3 brtColor = color * brt;
	float intensityf = dot(brtColor, LumCoeff);
	float3 intensity = float3(intensityf, intensityf, intensityf);
	float3 satColor = lerp(intensity, brtColor, sat);
	float3 conColor = lerp(AvgLumin, satColor, con);
	return conColor;
}

/*
** Float blending modes
** Adapted from here: http://www.nathanm.com/photoshop-blending-math/
** But I modified the HardMix (wrong condition), Overlay, SoftLight, ColorDodge, ColorBurn, VividLight, PinLight (inverted layers) ones to have correct results
*/

#define BlendLinearDodgef 				BlendAddf
#define BlendLinearBurnf 				BlendSubstractf
#define BlendAddf(base, blend) 			min(base + blend, 1.0)
#define BlendSubstractf(base, blend) 	max(base + blend - 1.0, 0.0)
#define BlendLightenf(base, blend) 		max(blend, base)
#define BlendDarkenf(base, blend) 		min(blend, base)
#define BlendLinearLightf(base, blend) 	(blend < 0.5 ? BlendLinearBurnf(base, (2.0 * blend)) : BlendLinearDodgef(base, (2.0 * (blend - 0.5))))
#define BlendScreenf(base, blend) 		(1.0 - ((1.0 - base) * (1.0 - blend)))
#define BlendOverlayf(base, blend) 		(base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)))
#define BlendSoftLightf(base, blend) 	((blend < 0.5) ? (2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) : (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend)))
#define BlendColorDodgef(base, blend) 	((blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0))
#define BlendColorBurnf(base, blend) 	((blend == 0.0) ? blend : max((1.0 - ((1.0 - base) / blend)), 0.0))
#define BlendVividLightf(base, blend) 	((blend < 0.5) ? BlendColorBurnf(base, (2.0 * blend)) : BlendColorDodgef(base, (2.0 * (blend - 0.5))))
#define BlendPinLightf(base, blend) 	((blend < 0.5) ? BlendDarkenf(base, (2.0 * blend)) : BlendLightenf(base, (2.0 *(blend - 0.5))))
#define BlendHardMixf(base, blend) 		((BlendVividLightf(base, blend) < 0.5) ? 0.0 : 1.0)
#define BlendReflectf(base, blend) 		((blend == 1.0) ? blend : min(base * base / (1.0 - blend), 1.0))



/*
** Vector3 blending modes
*/

// Component wise blending
#define Blend(base, blend, funcf) 		float3(funcf(base.r, blend.r), funcf(base.g, blend.g), funcf(base.b, blend.b))

#define BlendNormal(base, blend) 		(base)
#define BlendLighten					BlendLightenf
#define BlendDarken						BlendDarkenf
#define BlendMultiply(base, blend) 		(base * blend)
#define BlendAverage(base, blend) 		((base + blend) / 2.0)
#define BlendAdd(base, blend) 			min(base + blend, float3(1.0, 1.0, 1.0))
#define BlendSubstract(base, blend) 	max(base + blend - float3(1.0, 1.0, 1.0), float3(0.0, 0.0, 0.0))
#define BlendDifference(base, blend) 	abs(base - blend)
#define BlendNegation(base, blend) 		(float3(1.0, 1.0, 1.0) - abs(float3(1.0, 1.0, 1.0) - base - blend))
#define BlendExclusion(base, blend) 	(base + blend - 2.0 * base * blend)
#define BlendScreen(base, blend) 		Blend(base, blend, BlendScreenf)
#define BlendOverlay(base, blend) 		Blend(base, blend, BlendOverlayf)
#define BlendSoftLight(base, blend) 	Blend(base, blend, BlendSoftLightf)
#define BlendHardLight(base, blend) 	BlendOverlay(blend, base)
#define BlendColorDodge(base, blend) 	Blend(base, blend, BlendColorDodgef)
#define BlendColorBurn(base, blend) 	Blend(base, blend, BlendColorBurnf)
#define BlendLinearDodge				BlendAdd
#define BlendLinearBurn					BlendSubstract

// Linear Light is another contrast-increasing mode
// If the blend color is darker than midgray, Linear Light darkens the image by decreasing the brightness. If the blend color is lighter than midgray, the result is a brighter image due to increased brightness.
#define BlendLinearLight(base, blend) 	Blend(base, blend, BlendLinearLightf)
#define BlendVividLight(base, blend) 	Blend(base, blend, BlendVividLightf)
#define BlendPinLight(base, blend) 		Blend(base, blend, BlendPinLightf)
#define BlendHardMix(base, blend) 		Blend(base, blend, BlendHardMixf)
#define BlendReflect(base, blend) 		Blend(base, blend, BlendReflectf)
#define BlendGlow(base, blend) 			BlendReflect(blend, base)
#define BlendPhoenix(base, blend) 		(min(base, blend) - max(base, blend) + float3(1.0, 1.0, 1.0))
#define BlendOpacity(base, blend, F, O)	F(base, blend) * O + blend * (1.0 - O))

// Hue Blend mode creates the result color by combining the luminance and saturation of the base color with the hue of the blend color.
float3 BlendHue(float3 base, float3 blend)
{
	float3 baseHSL = RGBToHSL(base);
	return HSLToRGB(float3(RGBToHSL(blend).r, baseHSL.g, baseHSL.b));
}

// Saturation Blend mode creates the result color by combining the luminance and hue of the base color with the saturation of the blend color.
float3 BlendSaturation(float3 base, float3 blend)
{
	float3 baseHSL = RGBToHSL(base);
	return HSLToRGB(float3(baseHSL.r, RGBToHSL(blend).g, baseHSL.b));
}

// Color Mode keeps the brightness of the base color and applies both the hue and saturation of the blend color.
float3 BlendColor(float3 base, float3 blend)
{
	float3 blendHSL = RGBToHSL(blend);
	return HSLToRGB(float3(blendHSL.r, blendHSL.g, RGBToHSL(base).b));
}

// Luminosity Blend mode creates the result color by combining the hue and saturation of the base color with the luminance of the blend color.
float3 BlendLuminosity(float3 base, float3 blend)
{
	float3 baseHSL = RGBToHSL(base);
	return HSLToRGB(float3(baseHSL.r, baseHSL.g, RGBToHSL(blend).b));
}


/*
** Gamma correction
** Details: http://blog.mouaif.org/2009/01/22/photoshop-gamma-correction-shader/
*/

#define GammaCorrection(color, gamma)								pow(color, 1.0 / gamma)

/*
** Levels control (input (+gamma), output)
** Details: http://blog.mouaif.org/2009/01/28/levels-control-shader/
*/

#define LevelsControlInputRange(color, minInput, maxInput)			min(max(color - float3(minInput, minInput, minInput), float3(0.0, 0.0, 0.0)) / (float3(maxInput, maxInput, maxInput) - float3(minInput, minInput, minInput)), float3(1.0, 1.0, 1.0))
#define LevelsControlInput(color, minInput, gamma, maxInput)		GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
#define LevelsControlOutputRange(color, minOutput, maxOutput) 		lerp(float3(minOutput, minOutput, minOutput), float3(maxOutput, maxOutput, maxOutput), color)
#define LevelsControl(color, minInput, gamma, maxInput, minOutput, maxOutput) 	LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)


void mainVP( float4 iPosition		: POSITION,
			 float4 iColor    		: COLOR,
			 float2 iTexCoord       : TEXCOORD0,
             out float4 oPosition   : SV_POSITION,
             out float4 oColor      : COLOR,
             out float2 oTexCoord   : TEXCOORD0,
			 out float2 oDestCoord  : TEXCOORD1,
			 uniform float4 cTexelOffset,
			 uniform float4x4 cWorldViewProj )
{
    oTexCoord = iTexCoord;

	float4 pos = mul( cWorldViewProj, iPosition );
	float4 posTexelFix = pos;
	posTexelFix.x += 2.0 * cTexelOffset.z;
	posTexelFix.y -= 2.0 * cTexelOffset.w;
    oPosition = posTexelFix;

	oDestCoord = pos.xy * float2(0.5,-0.5) + 0.5;
	//oDestCoord = posTexelFix * float2(0.5,-0.5) + 0.5;

    oColor = iColor;
}


void mainFP_add( float4 iPosition   			: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                 uniform Sampler2D sAlbedo,
                 uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendAddf).xyz, srcColor.w ), 1.0 );
}

void mainFP_multiply( float4 iPosition   		: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
					 uniform Sampler2D sAlbedo,
                      uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, BlendMultiply(destColor, srcColor.xyz).xyz, srcColor.w ), 1.0 );
}


void mainFP_overlay( float4 iPosition   		: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                     uniform Sampler2D sAlbedo,
                     uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendOverlayf).xyz, srcColor.w ), 1.0 );
}

void mainFP_darken( float4 iPosition   	     	: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                    uniform Sampler2D sAlbedo,
                    uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, BlendDarken(destColor, srcColor.xyz), srcColor.w ), 1.0 );
}

void mainFP_color_burn( float4 iPosition   	    : SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                        uniform Sampler2D sAlbedo,
                        uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendColorBurnf).xyz, srcColor.w ), 1.0 );
}

void mainFP_linear_burn( float4 iPosition   	: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                         uniform Sampler2D sAlbedo,
                         uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendLinearBurnf).xyz, srcColor.w ), 1.0 );
}

void mainFP_lighten( float4 iPosition   	   	: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                     uniform Sampler2D sAlbedo,
                     uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendLightenf).xyz, srcColor.w ), 1.0 );
}

void mainFP_screen( float4 iPosition   	     	: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                    uniform Sampler2D sAlbedo,
                    uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendScreenf).xyz, srcColor.w ), 1.0 );
}

void mainFP_color_dodge( float4 iPosition   	: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                         uniform Sampler2D sAlbedo,
                         uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendColorDodgef).xyz, srcColor.w ), 1.0 );
}

void mainFP_soft_light( float4 iPosition   	    : SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                        uniform Sampler2D sAlbedo,
                        uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendSoftLightf).xyz, srcColor.w ), 1.0 );
}

void mainFP_hard_light( float4 iPosition   	    : SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                        uniform Sampler2D sAlbedo,
                        uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(srcColor.rgb, destColor, BlendOverlayf).xyz, srcColor.w ), 1.0 );
}

void mainFP_vivid_light( float4 iPosition   	: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                         uniform Sampler2D sAlbedo,
                         uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendVividLightf).xyz, srcColor.w ), 1.0 );
}

void mainFP_linear_light( float4 iPosition   	: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                          uniform Sampler2D sAlbedo,
                          uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendLinearLightf).xyz, srcColor.w ), 1.0 );
}

void mainFP_pin_light( float4 iPosition   	    : SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                       uniform Sampler2D sAlbedo,
                       uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, Blend(destColor, srcColor.rgb, BlendPinLightf).xyz, srcColor.w ), 1.0 );
}

void mainFP_difference( float4 iPosition   	   	: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                        uniform Sampler2D sAlbedo,
                        uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, BlendDifference(destColor, srcColor.rgb).xyz, srcColor.w ), 1.0 );
}

void mainFP_exclusion( float4 iPosition   	    : SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                       uniform Sampler2D sAlbedo,
                       uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = Tex2D( sMain, iDestCoord ).xyz;
	oColor = float4( lerp( destColor, BlendExclusion(destColor, srcColor.rgb).xyz, srcColor.w ), 1.0 );
}

void mainFP_hue( float4 iPosition   	   	    : SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                 uniform Sampler2D sAlbedo,
                 uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = min( Tex2D( sMain, iDestCoord ).xyz, 1.0 );
	oColor = float4( lerp( destColor, BlendHue(destColor, srcColor.rgb).xyz, srcColor.w ), 1.0 );
}

void mainFP_saturation( float4 iPosition   	   	: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                        uniform Sampler2D sAlbedo,
                        uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = min( Tex2D( sMain, iDestCoord ).xyz, 1.0 );
	oColor = float4( lerp( destColor, BlendSaturation(destColor, srcColor.rgb).xyz, srcColor.w ), 1.0 );
}

void mainFP_color( float4 iPosition   	   		: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                   uniform Sampler2D sAlbedo,
                   uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = min( Tex2D( sMain, iDestCoord ).xyz, 1.0 );
	oColor = float4( lerp( destColor, BlendColor(destColor, srcColor.rgb).xyz, srcColor.w ), 1.0 );
}

void mainFP_luminosity( float4 iPosition   	   	: SV_POSITION,
                     float4 iColor      		: COLOR,
					 float2 iTexCoord   		: TEXCOORD0,
					 float2 iDestCoord   		: TEXCOORD1,
					 out float4 oColor  		: SV_TARGET,
                        uniform Sampler2D sAlbedo,
                        uniform Sampler2D sMain )
{
	float4 srcColor = Tex2D( sAlbedo, iTexCoord ) * iColor;
	float3 destColor = min( Tex2D( sMain, iDestCoord ).xyz, 1.0 );
	oColor = float4( lerp( destColor, BlendLuminosity(destColor, srcColor.rgb).xyz, srcColor.w ), 1.0 );
}
