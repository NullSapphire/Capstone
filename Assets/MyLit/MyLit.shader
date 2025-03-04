Shader "Capstone/MyLit"
{
    Properties {
        [Header(Surface options)]
        [MainTexture] _ColorMap("Color", 2D) = "white" {}
        [MainColor] _ColorTint("Tint", Color) = (1,1,1,1)
        [HDR] _SpecularTint("Specular Tint", Color) = (1,1,1,1)
        _Smoothness("Smoothness", range(0, 1)) = 0.5
    }

    SubShader {
        Tags {"RenderPipeline" = "UniversalPipeline"}

        Pass {
            Name "ForwardLit"

            Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS

            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "MyLitForwardLit.hlsl"
            ENDHLSL

        }

        Pass {
            Name "ShadowPass"

            Tags {"LightMode" = "ShadowCaster"}

            HLSLPROGRAM

            #pragma vertex Vertex
            #pragma fragment shadowFrag

            float3 shadowFrag() : SV_TARGET
            {
                return 0;
            }

            #include "MyLitForwardLit.hlsl"
            ENDHLSL

        }
    }

}
