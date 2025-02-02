Shader "SDFRender"
{
    Properties
    {
        _BaseMap ("SDF Texture", 2D) = "white" {}
        _Threshold ("Threshold", Range(0, 1)) = 0.5
        _EdgeSoftness ("Edge Softness", Range(0.001, 0.1)) = 0.01
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"
               "RenderType" = "Transparent"
               "RenderPipeline" = "UniversalPipeline" }
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float _Threshold;
                float _EdgeSoftness;
                float4 _Color;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            Varyings vert (Attributes IN)
            {
                Varyings o;
                o.pos = TransformObjectToHClip(IN.pos);
                o.uv = IN.uv * _BaseMap_ST.xy + +_BaseMap_ST.zw;
                return o;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                float rawAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).a;
                clip(rawAlpha - (_Threshold - _EdgeSoftness));
                float smoothedAlpha = smoothstep(_Threshold - _EdgeSoftness, _Threshold + _EdgeSoftness, rawAlpha);
                return half4(_Color.rgb, smoothedAlpha);
            }
            ENDHLSL
        }
    }
}
