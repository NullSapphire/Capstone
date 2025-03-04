#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct Attributes {
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float2 uv : TEXCOORD0;
};

struct Interpolator {
	float4 positionCS : SV_POSITION;
	float3 positionWS : TEXCOORD2;
	float2 uv : TEXCOORD0;
	float3 normalWS : TEXCOORD1;
};

TEXTURE2D(_ColorMap);
SAMPLER(sampler_ColorMap);
float4 _ColorMap_ST;
float4 _SpecularTint;
float4 _ColorTint;
float _Smoothness;

Interpolator Vertex(Attributes input)
{
	Interpolator output;

	VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
	VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS);

	output.positionCS = posnInputs.positionCS;
	output.positionWS = posnInputs.positionWS;
	output.uv = TRANSFORM_TEX(input.uv, _ColorMap);
	output.normalWS = normInputs.normalWS;

	return output;
}

float3 Fragment(Interpolator input) : SV_TARGET
{
	input.normalWS = normalize(input.normalWS);
    float4 colorSample = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, input.uv);

	float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);

	Light mainLight = GetMainLight(shadowCoord);

	float3 lightVal = 0;
	float shininess = exp2(10 * _Smoothness + 1);

	float3 V = GetWorldSpaceViewDir(input.positionWS);
	V = normalize(V);
	float3 H = SafeNormalize(mainLight.direction + V);
	float HoN = (dot(H, input.normalWS) + 1) / 2;
	HoN = smoothstep(0.5, 0.51, pow(HoN, shininess));

	lightVal = smoothstep(0, 0.25, dot(mainLight.direction, input.normalWS)) * mainLight.color;
	float3 specularVal = HoN * _SpecularTint * mainLight.color;

	for (int i = 0; i < GetAdditionalLightsCount(); i++)
	{
		//Debug.Log("Entering extra lightsource");
		Light light = GetAdditionalLight(i, input.positionWS);
		H = normalize(light.direction + V);
		HoN = (dot(H, input.normalWS) + 1) / 2;
		HoN = pow(HoN, shininess);
		lightVal += smoothstep(0, 0.01, dot(light.direction, input.normalWS)) * light.color;
		specularVal += HoN * _SpecularTint * light.color;
	}

	lightVal += SampleSH(input.normalWS);

    return lightVal * colorSample * _ColorTint + specularVal;
}