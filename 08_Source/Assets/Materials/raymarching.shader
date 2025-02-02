Shader "Raymarching"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "black" {}
        _CameraDepthMap ("CameraDepthMap", 2D) = "black" {}
        _SurfaceDistance ("Surface Distance", float) = 0.001
        _MarchingStep ("Marching Step", int) = 128
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SphereSize ("Sphere Size", float) = 0.2
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        ZWrite Off
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
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 cameraPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float _SurfaceDistance;
                int _MarchingStep;
                half4 _Color;
                float _SphereSize;
            CBUFFER_END
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_CameraDepthMap);
            SAMPLER(sampler_CameraDepthMap);

            Varyings vert(Attributes v)
            {
                Varyings o;
                float3 worldPos = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(worldPos);
                o.worldPos = worldPos;
                o.cameraPos = GetCameraPositionWS();
                o.screenPos = ComputeScreenPos(o.positionCS);
                return o;
            }

            float GetSphere(float3 p, float r)
            {
                return length(p) - r;
            }

            float Raymarch(float3 ro, float3 rd, float maxDepth)
            {
                float dS = 0.0;
                float dO = 0.0;
                float3 p;
                for (int i = 0; i < _MarchingStep; i++)
                {
                    p = ro + dO * rd;
                    dS = GetSphere(p, _SphereSize); 
                    if (dS < _SurfaceDistance) return 1.0;
                    dO += dS;
                    if (dO > maxDepth) return 0.0;
                }
                return 0.0;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 ro = i.cameraPos;
                float3 rd = normalize(i.worldPos - ro);

                float2 uv = i.screenPos.xy / i.screenPos.w;
                uv.y = 1.0 - uv.y;
                half4 grabCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);

                float cameraDepth = SAMPLE_TEXTURE2D(_CameraDepthMap, sampler_CameraDepthMap, uv).r;
                float eyeDepthLinear = LinearEyeDepth(cameraDepth, _ZBufferParams);
                float maxDepth = length(ro + rd * eyeDepthLinear);
                float hit = Raymarch(ro, rd, maxDepth);
                half4 col = lerp(grabCol, _Color, hit);
                return col;
            }

            ENDHLSL
        }
    }
}