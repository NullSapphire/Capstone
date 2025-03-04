Shader "Capstone/ShellTexture"
{
    Properties
    {
        [NoScaleOffset] _FlowTex ("FlowTexture", 2D) = "black" {}
        [MainColor] _Color ("MainColor", Color) = (1, 1, 1, 1)
        
        _aoFactor ("AmbientOcclusionFactor", Range(0, 1)) = 0.5
        _gridDimensions ("GridDimensions", Vector) = (64, 64, 0, 0)
        _minHeight ("MinimumHeight", Range(0, 1)) = 0.5
        _scrollSpeed ("ScrollSpeed", Vector) = (1, 1, 0, 0)
        _maxDisplacement ("MaxDisplacement", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Name "ShellTexture"
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOW_SCREEN

            #include "ShellTextureShader.hlsl"
            ENDHLSL
        }
    }
}