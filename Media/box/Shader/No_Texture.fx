//--------------------------------------------------------------------------------------
// Copyright 2014 Intel Corporation
// All Rights Reserved
//
// Permission is granted to use, copy, distribute and prepare derivative works of this
// software for any purpose and without fee, provided, that the above copyright notice
// and this statement appear in all copies.  Intel makes no representations about the
// suitability of this software for any purpose.  THIS SOFTWARE IS PROVIDED "AS IS."
// INTEL SPECIFICALLY DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, AND ALL LIABILITY,
// INCLUDING CONSEQUENTIAL AND OTHER INDIRECT DAMAGES, FOR THE USE OF THIS SOFTWARE,
// INCLUDING LIABILITY FOR INFRINGEMENT OF ANY PROPRIETARY RIGHTS, AND INCLUDING THE
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  Intel does not
// assume any responsibility for any errors which may appear in this software nor any
// responsibility to update it.
//--------------------------------------------------------------------------------------
// Generated by ShaderGenerator.exe version 0.13
//--------------------------------------------------------------------------------------

// -------------------------------------
cbuffer cbPerModelValues
{
    row_major float4x4 World : WORLD;
    row_major float4x4 NormalMatrix : WORLD;
    row_major float4x4 WorldViewProjection : WORLDVIEWPROJECTION;
    row_major float4x4 InverseWorld : WORLDINVERSE;
    row_major float4x4 LightWorldViewProjection;
              float4   BoundingBoxCenterWorldSpace  < string UIWidget="None"; >;
              float4   BoundingBoxHalfWorldSpace    < string UIWidget="None"; >;
              float4   BoundingBoxCenterObjectSpace < string UIWidget="None"; >;
              float4   BoundingBoxHalfObjectSpace   < string UIWidget="None"; >;
			  float4   UserData1;
};

// -------------------------------------
cbuffer cbPerFrameValues
{
    row_major float4x4  View;
    row_major float4x4  InverseView : ViewInverse	< string UIWidget="None"; >;
    row_major float4x4  Projection;
    row_major float4x4  ViewProjection;
              float4    AmbientColor < string UIWidget="None"; > = .20;
              float4    LightColor < string UIWidget="None"; >   = 1.0f;
              float4    LightDirection  : Direction < string UIName = "Light Direction";  string Object = "TargetLight"; string Space = "World"; int Ref_ID=0; > = {0,0,-1, 0};
              float4    EyePosition;
              float4    TotalTimeInSeconds < string UIWidget="None"; >;
};

cbuffer cbExternals
{
    float4 gSurfaceColor;
    float gSpecExpon;
    float Kd;
    float Ks;

};
// -------------------------------------
struct VS_INPUT
{
    float3 Position : POSITION; // Projected position
    float3 Normal   : NORMAL;
    float2 UV0      : TEXCOORD0;
};

// -------------------------------------
struct PS_INPUT
{
    float4 Position : SV_POSITION;
    float3 Normal   : NORMAL;
    float2 UV0      : TEXCOORD0;
    float4 LightUV       : TEXCOORD1;
    float3 WorldPosition : TEXCOORD2;
    float3 Reflection : TEXCOORD3;
};

// -------------------------------------
#ifdef _CPUT
    SamplerState SAMPLER0 : register( s0 );
    SamplerComparisonState SHADOW_SAMPLER : register( s1);
    Texture2D texture0 : register( t0 );
    Texture2D _Shadow : register( t1 );
#else
    texture2D texture0 < string Name = "texture0"; string UIName = "texture0"; string ResourceType = "2D";>;
    sampler2D SAMPLER0 = sampler_state{ texture = (texture0);};
#endif

// -------------------------------------
float4 DIFFUSE( PS_INPUT input )
{
    return float4(0.5, 0.5, 0.5, 1.0);
//#ifdef _CPUT
//texture0.Sample( SAMPLER0, (((input.UV0)) *(10)) )
//#else
//SRGB2Linear(tex2D( SAMPLER0, (((input.UV0)) *(10)) ), texture0sRGB)
//#endif
//;
}

// -------------------------------------
float4 SPECULAR( PS_INPUT input )
{
    return float3(1, 1, 1).xyzz;
}

// -------------------------------------
float ComputeShadowAmount( PS_INPUT input )
{
#ifdef _CPUT
    float3  lightUV = input.LightUV.xyz / input.LightUV.w;
    lightUV.xy = lightUV.xy * 0.5f + 0.5f;
    lightUV.y  = 1.0f - lightUV.y;
    float  shadowAmount = _Shadow.SampleCmp( SHADOW_SAMPLER, lightUV, lightUV.z ).r;
    return shadowAmount;
#else
    return 1.0f;
#endif
}


// -------------------------------------
PS_INPUT VSMain( VS_INPUT input )
{
    PS_INPUT output = (PS_INPUT)0;

    output.Position      = mul( float4( input.Position, 1.0f), WorldViewProjection );
    output.WorldPosition = mul( float4( input.Position, 1.0f), World ).xyz;

    // TODO: transform the light into object space instead of the normal into world space
    output.Normal   = mul( input.Normal, (float3x3)World );
    output.UV0 = input.UV0;
    output.LightUV = mul( float4( input.Position, 1.0f), LightWorldViewProjection );

    return output;
}

// -------------------------------------
float4 PSMain( PS_INPUT input ) : SV_Target
{
    float4 result = UserData1;
    
    float specExp = 8.0;
    float3 F0 = 0.04;
    float3 n = normalize(input.Normal);

    // Specular-related computation
    float3 v = normalize(InverseView._m30_m31_m32 - input.WorldPosition);
    float3 r = reflect(-v, n);
    float3 l = -LightDirection.xyz;
    float nDotL = saturate(dot(n, l));
    float  rDotL = saturate(dot(r, l.xyz));
    float3 specular = pow(rDotL, specExp)*F0;
        
    float  shadowAmount = ComputeShadowAmount( input );

    //float3 diffuseColor = DIFFUSE(input).rgb * gSurfaceColor.rgb;
    // Ambient-related computation
    //float3 ambient = AmbientColor.rgb * diffuseColor;
    //result.xyz +=  ambient;

    // Diffuse-related computation
    //float  nDotL = saturate(dot(normal, lightDirection.xyz));
    //float3 diffuse = LightColor.rgb * nDotL * shadowAmount  * diffuseColor * gKd;
    //result.xyz += diffuse;

    result.xyz += nDotL > 0.0 ? specular * Ks: float3(0.0, 0.0, 0.0);
    result.xyz += nDotL * gSurfaceColor * Kd;
    result.xyz *= shadowAmount;
    result.xyz += AmbientColor.rgb * gSurfaceColor;

#ifdef _CPUT
    return UserData1;
#else
    return Linear2SRGB(result);
#endif //_CPUT
}

// -------------------------------------
technique DefaultTechnique
{
    pass pass1
    {
        VertexShader        = compile vs_3_0 VSMain();
        PixelShader         = compile ps_3_0 PSMain();
        ZWriteEnable        = true;
    }
}

