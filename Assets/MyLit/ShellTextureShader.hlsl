#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float4 color : COLOR;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
};

struct Interpolator
{
    float2 uv : TEXCOORD0;
    float fogCoord : TEXCOORD1;
    float4 vertex : SV_POSITION;
    float4 color : TEXCOORD2;
    float3 normalWS : TEXCOORD3;
    float3 positionWS : TEXCOORD4;
};

TEXTURE2D(_FlowTex);
SAMPLER(sampler_FlowTex);

CBUFFER_START(UnityPerMaterial)
    float4 _Color;
    float _aoFactor;
    float _minHeight;
    float _maxDisplacement;
    vector _gridDimensions;
    vector _scrollSpeed;
    float4 _FlowTex_ST;
CBUFFER_END

float2 CalculateGrassWind(float3 worldPos, float windStrength, float windSpeed) {
    float time = _Time.y;
    float2 windDirection = float2(1.0, 0.3); // Primary wind direction
    windDirection = normalize(windDirection);
    
    // Create variation in wind based on position
    float posVariation = dot(worldPos.xz * 0.1, float2(0.8, 0.2));
    
    // Primary wave
    float primaryWave = sin(time * windSpeed + posVariation);
    
    // Secondary smaller, faster wave for more natural movement
    float secondaryWave = sin(time * windSpeed * 1.8 + posVariation * 1.5) * 0.3;
    
    // Combine waves with some position-based variation to avoid uniform movement
    float windFactor = primaryWave + secondaryWave;
    
    // Add some subtle circular motion
    float2 circularMotion;
    circularMotion.x = cos(time * 0.7 + worldPos.x * 0.01);
    circularMotion.y = sin(time * 0.5 + worldPos.z * 0.01);
    
    // Combine directional wind with subtle circular motion
    float2 windOffset = windStrength * (windDirection * windFactor + circularMotion * 0.2);
    
    return windOffset;
}

Interpolator vert(appdata v)
{
    Interpolator o;

    float2 scrollingUV = TRANSFORM_TEX(v.uv + _Time.y * _scrollSpeed.xy, _FlowTex);
    float2 flowSample = pow(v.color, 2) * _maxDisplacement * (SAMPLE_TEXTURE2D_GRAD(_FlowTex, sampler_FlowTex, scrollingUV, 0, 0) - 0.5) * 2;
    
    float3 displacementTS = float3(flowSample.x, 0, flowSample.y);
    float displacementMag = length(displacementTS);

    float3x3 tangentToWorld = CreateTangentToWorld(SafeNormalize(v.normal), SafeNormalize(v.tangent), 1);
    float3 displacementOS = SafeNormalize(TransformTangentToObject(SafeNormalize(displacementTS), tangentToWorld)) * displacementMag;

    float3 worldPos = TransformObjectToWorld(v.vertex)/10;
    float2 dispAnaly = pow(v.color, 2) * CalculateGrassWind(worldPos, _maxDisplacement, _scrollSpeed.x);
    displacementOS = float3(dispAnaly.x, 0, dispAnaly.y); 

    o.vertex = TransformObjectToHClip(v.vertex + displacementOS);
    o.uv = v.uv;
    o.color = v.color;
    o.normalWS = TransformObjectToWorldNormal(v.normal);

    // Calculate fog factor
    o.fogCoord = ComputeFogFactor(o.vertex.z);

    o.positionWS = TransformObjectToWorld(v.vertex);
    
    return o;
}

float rand(float2 seed)
{
    return frac(sin(dot(seed, float2(12.9898, 78.233))) * 43758.5453);
}

float GrassShapeGenerator(Interpolator i)
{
    //Generate a grid
    float2 gridUV = i.uv * floor(_gridDimensions.xy);

    float2 bladeIndex = floor(gridUV);
    float height = lerp(_minHeight, 1, rand(bladeIndex));

    gridUV = frac(gridUV);
    return (1 - distance(gridUV, float2(0.5, 0.5))) * height;
}

float4 frag(Interpolator i) : SV_Target
{
    // sample the texture
    float4 col = GrassShapeGenerator(i);

    if(col.r <= i.color.r)
    {
        discard;
    }

    Light L = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
    float3 N = normalize(i.normalWS);
    
    float3 lightVal = (dot(N, L.direction) * 0.5f + 0.5f) * L.shadowAttenuation * L.color + SampleSH(N);
    
    for (int j = 0; j < GetAdditionalLightsCount(); j++)
	{
		//Debug.Log("Entering extra lightsource");
		Light L = GetAdditionalLight(j, i.positionWS);
        lightVal += (dot(N, L.direction) * 0.5f + 0.5f) * L.shadowAttenuation * L.color * L.distanceAttenuation;
	}
    col = float4(lightVal, 1) * _Color * lerp(_aoFactor, 1.0f, i.color.r);

    // Apply fog
    col.rgb = MixFog(col.rgb, i.fogCoord);

    return col;
}