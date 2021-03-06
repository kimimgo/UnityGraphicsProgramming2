﻿Shader "Custom/Octahedron Sphere MultiVertex Instancing"
{
	Properties
	{
		//_MainTex ("Texture", 2D) = "white" {}
		//_Level("Level", Int) = 1
		//_Scale("Scale", Float) = 0.1
		_Color("Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Blend One One

		Pass
		{
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Libs\Quaternion.cginc"
			#include "Libs\Color.cginc"
			#include "OctahedronSphereData.cginc"

			struct v2g
			{
				float4 pos : SV_POSITION;
				float scale : TEXCOORD0;
				int level : TEXCOORD1;
				float4 rotation : TEXCOORD2;
				int id : TEXCOORD3;
			};

			struct g2f
			{
				float4 pos : SV_POSITION;
			};

			//sampler2D _MainTex;
			//float4 _MainTex_ST;
			//int _Level;
			//float _Scale;
			float4 _Color;

			StructuredBuffer<OctahedronSphereData> _particleBuffer;

			v2g vert (uint id : SV_VertexID)
			{
				v2g o;
				uint idx = id / 8;
				//o.pos = UnityObjectToClipPos(v.vertex);
				//o.pos = float4(0,0,0,1);	// test
				o.pos = float4(_particleBuffer[idx].position, 0);
				o.scale = _particleBuffer[idx].scale;
				o.level = _particleBuffer[idx].level;
				o.rotation = _particleBuffer[idx].rotation;
				//o.color = _particleBuffer[id].color;
				o.id = id % 8;
				return o;
			}
			
			// ジオメトリシェーダ
			[maxvertexcount(256)]
			//void geom(point v2g input[1], inout TriangleStream<g2f> outStream)
			void geom(point v2g input[1], inout LineStream<g2f> outStream)
			{
				g2f output1, output2, output3;

				float4 pos = input[0].pos;
				int n = input[0].level;
				float scale = input[0].scale;
				float4 rotation = input[0].rotation;

				float4 init_vectors[24];
				// 0 : thr triangle vertical to (1,1,1)
				init_vectors[0] = float4(0, 1, 0, 0);
				init_vectors[1] = float4(0, 0, 1, 0);
				init_vectors[2] = float4(1, 0, 0, 0);
				// 1 : to (1,-1,1)
				init_vectors[3] = float4(0, -1, 0, 0);
				init_vectors[4] = float4(1, 0, 0, 0);
				init_vectors[5] = float4(0, 0, 1, 0);
				// 2 : to (-1,1,1)
				init_vectors[6] = float4(0, 1, 0, 0);
				init_vectors[7] = float4(-1, 0, 0, 0);
				init_vectors[8] = float4(0, 0, 1, 0);
				// 3 : to (-1,-1,1)
				init_vectors[9] = float4(0, -1, 0, 0);
				init_vectors[10] = float4(0, 0, 1, 0);
				init_vectors[11] = float4(-1, 0, 0, 0);
				// 4 : to (1,1,-1)
				init_vectors[12] = float4(0, 1, 0, 0);
				init_vectors[13] = float4(1, 0, 0, 0);
				init_vectors[14] = float4(0, 0, -1, 0);
				// 5 : to (-1,1,-1)
				init_vectors[15] = float4(0, 1, 0, 0);
				init_vectors[16] = float4(0, 0, -1, 0);
				init_vectors[17] = float4(-1, 0, 0, 0);
				// 6 : to (-1,-1,-1)
				init_vectors[18] = float4(0, -1, 0, 0);
				init_vectors[19] = float4(-1, 0, 0, 0);
				init_vectors[20] = float4(0, 0, -1, 0);
				// 7 : to (1,-1,-1)
				init_vectors[21] = float4(0, -1, 0, 0);
				init_vectors[22] = float4(0, 0, -1, 0);
				init_vectors[23] = float4(1, 0, 0, 0);

				int i = input[0].id * 3;
				//for (int i = 0; i < 24; i += 3)
				{
					for (int p = 0; p < n; p++) 
					{
						// edge index 1
						float4 edge_p1 = qslerp(init_vectors[i], init_vectors[i + 2], (float)p / n);
						float4 edge_p2 = qslerp(init_vectors[i + 1], init_vectors[i + 2], (float)p / n);
						float4 edge_p3 = qslerp(init_vectors[i], init_vectors[i + 2], (float)(p + 1) / n);
						float4 edge_p4 = qslerp(init_vectors[i + 1], init_vectors[i + 2], (float)(p + 1) / n);

						for (int q = 0; q < (n - p); q++)
						{
							// edge index 2
							float4 a = qslerp(edge_p1, edge_p2, (float)q / (n - p));
							float4 b = qslerp(edge_p1, edge_p2, (float)(q + 1) / (n - p));
							float4 c, d;

							if(distance(edge_p3, edge_p4) < 0.00001)
							{
								c = edge_p3;
								d = edge_p3;
							}
							else {
								c = qslerp(edge_p3, edge_p4, (float)q / (n - p - 1));
								d = qslerp(edge_p3, edge_p4, (float)(q + 1) / (n - p - 1));
							}

							output1.pos = UnityObjectToClipPos(pos + float4(rotateWithQuaternion(a.xyz, rotation) * scale, 1));
							output2.pos = UnityObjectToClipPos(pos + float4(rotateWithQuaternion(b.xyz, rotation) * scale, 1));
							output3.pos = UnityObjectToClipPos(pos + float4(rotateWithQuaternion(c.xyz, rotation) * scale, 1));
							
							// Triangle Stream
							outStream.Append(output1);
							outStream.Append(output2);
							outStream.Append(output3);
							outStream.RestartStrip();

							if (q < (n - p - 1))
							{
								output1.pos = UnityObjectToClipPos(pos + float4(rotateWithQuaternion(c.xyz, rotation) * scale, 1));
								output2.pos = UnityObjectToClipPos(pos + float4(rotateWithQuaternion(b.xyz, rotation) * scale, 1));
								output3.pos = UnityObjectToClipPos(pos + float4(rotateWithQuaternion(d.xyz, rotation) * scale, 1));
								
								// Triangle Stream
								outStream.Append(output1);
								outStream.Append(output2);
								outStream.Append(output3);
								outStream.RestartStrip();

							}
						}
					}
				}
			}

			fixed4 frag (g2f i) : SV_Target
			{
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);
				return _Color;
			}
			ENDCG
		}
	}
}
