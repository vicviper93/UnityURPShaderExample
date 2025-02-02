Shader "cloud"
{
    Properties
    {
        _MainTex ("Texture", 3D) = "white" {}
        _Alpha ("Alpha", float) = 0.007
        _StepSize ("Step Size", float) = 0.01
        _MaxSteps ("Max Raymarching Steps", int) = 128
    }

    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags {"LightMode" = "UniversalForward"}

            Blend One OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #define EPSILON 0.00001f

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 objectVertex : TEXCOORD0;
                float3 vectorToSurface : TEXCOORD1;
            };

            TEXTURE3D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            float _Alpha;
            float _StepSize;
            int _MaxSteps;

            Varyings vert(Attributes IN)
            {
                Varyings o;
                o.objectVertex = IN.positionOS.xyz;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                o.positionCS = vertexInput.positionCS;
                o.vectorToSurface = TransformWorldToObjectDir(vertexInput.positionWS - _WorldSpaceCameraPos);
                return o;
            }

            float4 BlendUnder(float4 color, float4 newColor)
            {
                color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
                color.a += 0;
                return color;
            }

            float4 raymarchingByStep(float3 rayOrigin, float3 rayDirection, int maxSteps, float stepSize, float alpha)
            {
                float4 color = float4(0, 0, 0, 0);
                float3 samplePosition = rayOrigin;

                for (int step = 0; step < maxSteps; ++step)
                {
                    if (max(abs(samplePosition.x), max(abs(samplePosition.y), abs(samplePosition.z))) < 0.5f + EPSILON)
                    {
                        float4 sampledColor = SAMPLE_TEXTURE3D(_MainTex, sampler_MainTex, samplePosition + float3(0.5f, 0.5f, 0.5f));
                        sampledColor.a *= alpha;

                        if (sampledColor.a > EPSILON)
                        {
                            color = BlendUnder(color, sampledColor);
                        }

                        samplePosition += rayDirection * stepSize;
                    }
                }

                return color;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Compute ray origin and direction
                float3 rayOrigin = IN.objectVertex;
                float3 rayDirection = normalize(IN.vectorToSurface);

                // Apply raymarching
                float4 col = raymarchingByStep(rayOrigin, rayDirection, _MaxSteps, _StepSize, _Alpha);
                return col;
            }
            ENDHLSL
        }
    }
}