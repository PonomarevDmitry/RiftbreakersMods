/**********************************************************************
Copyright (c) 2019 Advanced Micro Devices, Inc. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
********************************************************************/

#ifndef RAYTRACING_UTILS_HLSL
#define RAYTRACING_UTILS_HLSL

#define PI              3.14159265359f
#define GOLDEN_RATIO    1.61803398875f

#define LIGHT_TYPE_DIRECTIONAL  0
#define LIGHT_TYPE_POINT        1
#define LIGHT_TYPE_SPOTLIGHT    2
/**
    Gets an orthogonal vector.

    \param n The vector to retrieve another orthogonal vector from.
    \return An orthogonal vector.
*/
float3 OrthoVector(in float3 n)
{
    float3 p;

    if (abs(n.z) > 0.0f)
    {
        float k = sqrt(n.y * n.y + n.z * n.z);
        p.x = 0.0f; p.y = -n.z / k; p.z = n.y / k;
    }
    else
    {
        float k = sqrt(n.x * n.x + n.y * n.y);
        p.x = n.y / k; p.y = -n.x / k; p.z = 0.0f;
    }

    return p;
}

/**
    Maps the random numbers to the cone.

    \param s The random numbers.
    \param p The tip of the cone.
    \param n The axis of the cone.
    \param radius The radius of the disk.
    \return The random sample.
*/
float3 MapToCone(in float2 s, in float3 p, in float3 n, in float radius)
{
    float3 u = OrthoVector(n);
    const float3 v = cross(u, n);
    u = cross(n, v);

    const float2 offset = 2.0f * s - float2(1.0f, 1.0f);

    if (offset.x == 0.0f && offset.y == 0.0f)
    {
        return p;
    }

    float theta, r;

    if (abs(offset.x) > abs(offset.y))
    {
        r = offset.x;
        theta = PI / 4.0f * (offset.y / offset.x);
    }
    else
    {
        r = offset.y;
        theta = PI / 2.0f * (1.0f - 0.5f * (offset.x / offset.y));
    }

    const float2 uv = float2(radius * r * cos(theta), radius * r * sin(theta));

    return p + uv.x * u + uv.y * v;
}

/**
    Maps the random numbers to the hemispere.

    \param s The random numbers.
    \param n The normal of the surface.
    \return The random sample.
*/
float3 MapToHemisphere(in float2 s, in float3 n)
{
    float a = 1.0f - 2.0f * s[0];
    float b = sqrt(1.0f - a * a);
    a *= 0.999f;
    b *= 0.999f;
    float phi = 2.0f * PI * s[1];
    return float3(n.x + b * cos(phi), n.y + b * sin(phi), n.z + a);
}

#ifndef __PSSL__

uint3 Load3x16BitIndices( uint offsetBytes )
{
    uint3 indices;
    const uint dwordAlignedOffset = offsetBytes & ~3;    
    const uint2 four16BitIndices = IndexBuffer.Load2( dwordAlignedOffset );
 
    if ( dwordAlignedOffset == offsetBytes )
    {
        indices.x = four16BitIndices.x & 0xffff;
        indices.y = ( four16BitIndices.x >> 16 ) & 0xffff;
        indices.z = four16BitIndices.y & 0xffff;
    }
    else
    {
        indices.x = ( four16BitIndices.x >> 16 ) & 0xffff;
        indices.y = four16BitIndices.y & 0xffff;
        indices.z = ( four16BitIndices.y >> 16 ) & 0xffff;
    }

    return indices;
}


/**
    Function to pack two variables of type uint and float into a single uint by placing the input uint value in the upper 16 bits and the float in the lower 16 bits.
    \param a The uint that's placed in the upper 16 bits.
    \param f The float that's placed in the lower 16 bits.
    \return A packed uint(uint16, float16).
*/
uint PackValues(uint a, float f)
{
    uint f16 = f32tof16(f);
    return f16 | (a << 16);
}
/**
    Function to unpack two variables of type uint16 and float16 from a single uint32.
    \param packed The packed uint32 of the format (uint16, float16).
    \return a The uint that's placed in the upper 16 bits of the input.
    \return f The float that's placed in the lower 16 bits of the input.
*/
void UnpackValues(uint packed, out uint a, out float f)
{
    a = uint(packed >> 16);
    f = f16tof32(packed & 0xFFFF);
}

#endif

#endif // RAYTRACING_UTILS_HLSL
