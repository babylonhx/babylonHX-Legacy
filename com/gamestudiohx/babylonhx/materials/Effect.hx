package com.gamestudiohx.babylonhx.materials;

import com.gamestudiohx.babylonhx.Engine;
import com.gamestudiohx.babylonhx.materials.textures.Texture;
import com.gamestudiohx.babylonhx.postprocess.PostProcess;
import com.gamestudiohx.babylonhx.tools.math.Color3;
import com.gamestudiohx.babylonhx.tools.math.Matrix;
import com.gamestudiohx.babylonhx.tools.math.Vector2;
import com.gamestudiohx.babylonhx.tools.math.Vector3;
import com.gamestudiohx.babylonhx.tools.Tools;
import openfl.Assets;
import openfl.gl.GL;
import openfl.utils.Float32Array;

import openfl.gl.GLProgram;
import openfl.gl.GLUniformLocation;


/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin / Brendon Smith #seacloud9
 */

@:expose('BABYLON.Effect') class Effect {

    public static var ShadersStore:Map<String, String> = [
		"anaglyphPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\nuniform sampler2D leftSampler;\n\nvoid main(void)\n{\n    vec4 leftFrag = texture2D(leftSampler, vUV);\n    leftFrag = vec4(1.0, leftFrag.g, leftFrag.b, 1.0);\n\n\tvec4 rightFrag = texture2D(textureSampler, vUV);\n    rightFrag = vec4(rightFrag.r, 1.0, 1.0, 1.0);\n\n    gl_FragColor = vec4(rightFrag.rgb * leftFrag.rgb, 1.0);\n}",
		"blackAndWhitePixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\n\nvoid main(void) \n{\n\tfloat luminance = dot(texture2D(textureSampler, vUV).rgb, vec3(0.3, 0.59, 0.11));\n\tgl_FragColor = vec4(luminance, luminance, luminance, 1.0);\n}",
		"blurPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\n\n// Parameters\nuniform vec2 screenSize;\nuniform vec2 direction;\nuniform float blurWidth;\n\nvoid main(void)\n{\n\tfloat weights[7];\n\tweights[0] = 0.05;\n\tweights[1] = 0.1;\n\tweights[2] = 0.2;\n\tweights[3] = 0.3;\n\tweights[4] = 0.2;\n\tweights[5] = 0.1;\n\tweights[6] = 0.05;\n\n\tvec2 texelSize = vec2(1.0 / screenSize.x, 1.0 / screenSize.y);\n\tvec2 texelStep = texelSize * direction * blurWidth;\n\tvec2 start = vUV - 3.0 * texelStep;\n\n\tvec4 baseColor = vec4(0., 0., 0., 0.);\n\tvec2 texelOffset = vec2(0., 0.);\n\n\tfor (int i = 0; i < 7; i++)\n\t{\n\t\tbaseColor += texture2D(textureSampler, start + texelOffset) * weights[i];\n\t\ttexelOffset += texelStep;\n\t}\n\n\tgl_FragColor = baseColor;\n}",
		"convolutionPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\n\nuniform vec2 screenSize;\nuniform float kernel[9];\n\nvoid main(void)\n{\n\tvec2 onePixel = vec2(1.0, 1.0) / screenSize;\n\tvec4 colorSum =\n\t\ttexture2D(textureSampler, vUV + onePixel * vec2(-1, -1)) * kernel[0] +\n\t\ttexture2D(textureSampler, vUV + onePixel * vec2(0, -1)) * kernel[1] +\n\t\ttexture2D(textureSampler, vUV + onePixel * vec2(1, -1)) * kernel[2] +\n\t\ttexture2D(textureSampler, vUV + onePixel * vec2(-1, 0)) * kernel[3] +\n\t\ttexture2D(textureSampler, vUV + onePixel * vec2(0, 0)) * kernel[4] +\n\t\ttexture2D(textureSampler, vUV + onePixel * vec2(1, 0)) * kernel[5] +\n\t\ttexture2D(textureSampler, vUV + onePixel * vec2(-1, 1)) * kernel[6] +\n\t\ttexture2D(textureSampler, vUV + onePixel * vec2(0, 1)) * kernel[7] +\n\t\ttexture2D(textureSampler, vUV + onePixel * vec2(1, 1)) * kernel[8];\n\n\tfloat kernelWeight =\n\t\tkernel[0] +\n\t\tkernel[1] +\n\t\tkernel[2] +\n\t\tkernel[3] +\n\t\tkernel[4] +\n\t\tkernel[5] +\n\t\tkernel[6] +\n\t\tkernel[7] +\n\t\tkernel[8];\n\n\tif (kernelWeight <= 0.0) {\n\t\tkernelWeight = 1.0;\n\t}\n\n\tgl_FragColor = vec4((colorSum / kernelWeight).rgb, 1);\n}",
		"colorPixelShader" => "precision mediump float;\n\nuniform vec3 color;\n\nvoid main(void) {\n\tgl_FragColor = vec4(color, 1.);\n}",
		"colorVertexShader" => "precision mediump float;\n\n// Attributes\nattribute vec3 position;\n\n// Uniforms\nuniform mat4 worldViewProjection;\n\nvoid main(void) {\n\tgl_Position = worldViewProjection * vec4(position, 1.0);\n}",
		"defaultPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n#define MAP_EXPLICIT\t0.\n#define MAP_SPHERICAL\t1.\n#define MAP_PLANAR\t\t2.\n#define MAP_CUBIC\t\t3.\n#define MAP_PROJECTION\t4.\n#define MAP_SKYBOX\t\t5.\n\n// Constants\nuniform vec3 vEyePosition;\nuniform vec3 vAmbientColor;\nuniform vec4 vDiffuseColor;\nuniform vec4 vSpecularColor;\nuniform vec3 vEmissiveColor;\n\n// Input\nvarying vec3 vPositionW;\nvarying vec3 vNormalW;\n\n#ifdef VERTEXCOLOR\nvarying vec3 vColor;\n#endif\n\n// Lights\n#ifdef LIGHT0\nuniform vec4 vLightData0;\nuniform vec4 vLightDiffuse0;\nuniform vec3 vLightSpecular0;\n#ifdef SHADOW0\nvarying vec4 vPositionFromLight0;\nuniform sampler2D shadowSampler0;\nuniform float darkness0;\n#endif\n#ifdef SPOTLIGHT0\nuniform vec4 vLightDirection0;\n#endif\n#ifdef HEMILIGHT0\nuniform vec3 vLightGround0;\n#endif\n#endif\n\n#ifdef LIGHT1\nuniform vec4 vLightData1;\nuniform vec4 vLightDiffuse1;\nuniform vec3 vLightSpecular1;\n#ifdef SHADOW1\nvarying vec4 vPositionFromLight1;\nuniform sampler2D shadowSampler1;\nuniform float darkness1;\n#endif\n#ifdef SPOTLIGHT1\nuniform vec4 vLightDirection1;\n#endif\n#ifdef HEMILIGHT1\nuniform vec3 vLightGround1;\n#endif\n#endif\n\n#ifdef LIGHT2\nuniform vec4 vLightData2;\nuniform vec4 vLightDiffuse2;\nuniform vec3 vLightSpecular2;\n#ifdef SHADOW2\nvarying vec4 vPositionFromLight2;\nuniform sampler2D shadowSampler2;\nuniform float darkness2;\n#endif\n#ifdef SPOTLIGHT2\nuniform vec4 vLightDirection2;\n#endif\n#ifdef HEMILIGHT2\nuniform vec3 vLightGround2;\n#endif\n#endif\n\n#ifdef LIGHT3\nuniform vec4 vLightData3;\nuniform vec4 vLightDiffuse3;\nuniform vec3 vLightSpecular3;\n#ifdef SHADOW3\nvarying vec4 vPositionFromLight3;\nuniform sampler2D shadowSampler3;\nuniform float darkness3;\n#endif\n#ifdef SPOTLIGHT3\nuniform vec4 vLightDirection3;\n#endif\n#ifdef HEMILIGHT3\nuniform vec3 vLightGround3;\n#endif\n#endif\n\n// Samplers\n#ifdef DIFFUSE\nvarying vec2 vDiffuseUV;\nuniform sampler2D diffuseSampler;\nuniform vec2 vDiffuseInfos;\n#endif\n\n#ifdef AMBIENT\nvarying vec2 vAmbientUV;\nuniform sampler2D ambientSampler;\nuniform vec2 vAmbientInfos;\n#endif\n\n#ifdef OPACITY\t\nvarying vec2 vOpacityUV;\nuniform sampler2D opacitySampler;\nuniform vec2 vOpacityInfos;\n#endif\n\n#ifdef EMISSIVE\nvarying vec2 vEmissiveUV;\nuniform vec2 vEmissiveInfos;\nuniform sampler2D emissiveSampler;\n#endif\n\n#ifdef SPECULAR\nvarying vec2 vSpecularUV;\nuniform vec2 vSpecularInfos;\nuniform sampler2D specularSampler;\n#endif\n\n// Reflection\n#ifdef REFLECTION\nvarying vec3 vPositionUVW;\nuniform samplerCube reflectionCubeSampler;\nuniform sampler2D reflection2DSampler;\nuniform vec3 vReflectionInfos;\nuniform mat4 reflectionMatrix;\nuniform mat4 view;\n\nvec3 computeReflectionCoords(float mode, vec4 worldPos, vec3 worldNormal)\n{\n\tif (mode == MAP_SPHERICAL)\n\t{\n\t\tvec3 coords = vec3(view * vec4(worldNormal, 0.0));\n\n\t\treturn vec3(reflectionMatrix * vec4(coords, 1.0));\n\t}\n\telse if (mode == MAP_PLANAR)\n\t{\n\t\tvec3 viewDir = worldPos.xyz - vEyePosition;\n\t\tvec3 coords = normalize(reflect(viewDir, worldNormal));\n\n\t\treturn vec3(reflectionMatrix * vec4(coords, 1));\n\t}\n\telse if (mode == MAP_CUBIC)\n\t{\n\t\tvec3 viewDir = worldPos.xyz - vEyePosition;\n\t\tvec3 coords = reflect(viewDir, worldNormal);\n\n\t\treturn vec3(reflectionMatrix * vec4(coords, 0));\n\t}\n\telse if (mode == MAP_PROJECTION)\n\t{\n\t\treturn vec3(reflectionMatrix * (view * worldPos));\n\t}\n\telse if (mode == MAP_SKYBOX)\n\t{\n\t\treturn vPositionUVW;\n\t}\n\n\treturn vec3(0, 0, 0);\n}\n#endif\n\n// Shadows\n#ifdef SHADOWS\n\nfloat unpack(vec4 color)\n{\n\tconst vec4 bitShift = vec4(1. / (255. * 255. * 255.), 1. / (255. * 255.), 1. / 255., 1.);\n\treturn dot(color, bitShift);\n}\n\nfloat unpackHalf(vec2 color)\n{\n\treturn color.x + (color.y / 255.0);\n}\n\nfloat computeShadow(vec4 vPositionFromLight, sampler2D shadowSampler, float darkness)\n{\n\tvec3 depth = vPositionFromLight.xyz / vPositionFromLight.w;\n\tvec2 uv = 0.5 * depth.xy + vec2(0.5, 0.5);\n\n\tif (uv.x < 0. || uv.x > 1.0 || uv.y < 0. || uv.y > 1.0)\n\t{\n\t\treturn 1.0;\n\t}\n\n\tfloat shadow = unpack(texture2D(shadowSampler, uv));\n\n\tif (depth.z > shadow)\n\t{\n\t\treturn darkness;\n\t}\n\treturn 1.;\n}\n\nfloat computeShadowWithPCF(vec4 vPositionFromLight, sampler2D shadowSampler)\n{\n\tvec3 depth = vPositionFromLight.xyz / vPositionFromLight.w;\n\tvec2 uv = 0.5 * depth.xy + vec2(0.5, 0.5);\n\n\tif (uv.x < 0. || uv.x > 1.0 || uv.y < 0. || uv.y > 1.0)\n\t{\n\t\treturn 1.0;\n\t}\n\n\tfloat visibility = 1.;\n\n\tvec2 poissonDisk[4];\n\tpoissonDisk[0] = vec2(-0.94201624, -0.39906216);\n\tpoissonDisk[1] = vec2(0.94558609, -0.76890725);\n\tpoissonDisk[2] = vec2(-0.094184101, -0.92938870);\n\tpoissonDisk[3] = vec2(0.34495938, 0.29387760);\n\n\t// Poisson Sampling\n\tfor (int i = 0; i<4; i++){\n\t\tif (unpack(texture2D(shadowSampler, uv + poissonDisk[i] / 1500.0))  <  depth.z){\n\t\t\tvisibility -= 0.2;\n\t\t}\n\t}\n\treturn visibility;\n}\n\n// Thanks to http://devmaster.net/\nfloat ChebychevInequality(vec2 moments, float t)\n{\n\tif (t <= moments.x)\n\t{\n\t\treturn 1.0;\n\t}\n\n\tfloat variance = moments.y - (moments.x * moments.x);\n\tvariance = max(variance, 0.);\n\n\tfloat d = t - moments.x;\n\treturn variance / (variance + d * d);\n}\n\nfloat computeShadowWithVSM(vec4 vPositionFromLight, sampler2D shadowSampler)\n{\n\tvec3 depth = vPositionFromLight.xyz / vPositionFromLight.w;\n\tvec2 uv = 0.5 * depth.xy + vec2(0.5, 0.5);\n\n\tif (uv.x < 0. || uv.x > 1.0 || uv.y < 0. || uv.y > 1.0)\n\t{\n\t\treturn 1.0;\n\t}\n\n\tvec4 texel = texture2D(shadowSampler, uv);\n\n\tvec2 moments = vec2(unpackHalf(texel.xy), unpackHalf(texel.zw));\n\treturn clamp(1.3 - ChebychevInequality(moments, depth.z), 0., 1.0);\n}\n#endif\n\n// Bump\n#ifdef BUMP\n#extension GL_OES_standard_derivatives : enable\nvarying vec2 vBumpUV;\nuniform vec2 vBumpInfos;\nuniform sampler2D bumpSampler;\n\n// Thanks to http://www.thetenthplanet.de/archives/1180\nmat3 cotangent_frame(vec3 normal, vec3 p, vec2 uv)\n{\n\t// get edge vectors of the pixel triangle\n\tvec3 dp1 = dFdx(p);\n\tvec3 dp2 = dFdy(p);\n\tvec2 duv1 = dFdx(uv);\n\tvec2 duv2 = dFdy(uv);\n\n\t// solve the linear system\n\tvec3 dp2perp = cross(dp2, normal);\n\tvec3 dp1perp = cross(normal, dp1);\n\tvec3 tangent = dp2perp * duv1.x + dp1perp * duv2.x;\n\tvec3 binormal = dp2perp * duv1.y + dp1perp * duv2.y;\n\n\t// construct a scale-invariant frame \n\tfloat invmax = inversesqrt(max(dot(tangent, tangent), dot(binormal, binormal)));\n\treturn mat3(tangent * invmax, binormal * invmax, normal);\n}\n\nvec3 perturbNormal(vec3 viewDir)\n{\n\tvec3 map = texture2D(bumpSampler, vBumpUV).xyz * vBumpInfos.y;\n\tmap = map * 255. / 127. - 128. / 127.;\n\tmat3 TBN = cotangent_frame(vNormalW, -viewDir, vBumpUV);\n\treturn normalize(TBN * map);\n}\n#endif\n\n#ifdef CLIPPLANE\nvarying float fClipDistance;\n#endif\n\n// Fog\n#ifdef FOG\n\n#define FOGMODE_NONE    0.\n#define FOGMODE_EXP     1.\n#define FOGMODE_EXP2    2.\n#define FOGMODE_LINEAR  3.\n#define E 2.71828\n\nuniform vec4 vFogInfos;\nuniform vec3 vFogColor;\nvarying float fFogDistance;\n\nfloat CalcFogFactor()\n{\n\tfloat fogCoeff = 1.0;\n\tfloat fogStart = vFogInfos.y;\n\tfloat fogEnd = vFogInfos.z;\n\tfloat fogDensity = vFogInfos.w;\n\n\tif (FOGMODE_LINEAR == vFogInfos.x)\n\t{\n\t\tfogCoeff = (fogEnd - fFogDistance) / (fogEnd - fogStart);\n\t}\n\telse if (FOGMODE_EXP == vFogInfos.x)\n\t{\n\t\tfogCoeff = 1.0 / pow(E, fFogDistance * fogDensity);\n\t}\n\telse if (FOGMODE_EXP2 == vFogInfos.x)\n\t{\n\t\tfogCoeff = 1.0 / pow(E, fFogDistance * fFogDistance * fogDensity * fogDensity);\n\t}\n\n\treturn clamp(fogCoeff, 0.0, 1.0);\n}\n#endif\n\n// Light Computing\nstruct lightingInfo\n{\n\tvec3 diffuse;\n\tvec3 specular;\n};\n\nlightingInfo computeLighting(vec3 viewDirectionW, vec3 vNormal, vec4 lightData, vec3 diffuseColor, vec3 specularColor, float range) {\n\tlightingInfo result;\n\n\tvec3 lightVectorW;\n\tfloat attenuation = 1.0;\n\tif (lightData.w == 0.)\n\t{\n\t\tvec3 direction = lightData.xyz - vPositionW;\n\n\t\tattenuation = max(0., 1.0 - length(direction) / range);\n\t\tlightVectorW = normalize(direction);\n\t}\n\telse\n\t{\n\t\tlightVectorW = normalize(-lightData.xyz);\n\t}\n\n\t// diffuse\n\tfloat ndl = max(0., dot(vNormal, lightVectorW));\n\n\t// Specular\n\tvec3 angleW = normalize(viewDirectionW + lightVectorW);\n\tfloat specComp = max(0., dot(vNormal, angleW));\n\tspecComp = pow(specComp, max(1., vSpecularColor.a));\n\n\tresult.diffuse = ndl * diffuseColor * attenuation;\n\tresult.specular = specComp * specularColor * attenuation;\n\n\treturn result;\n}\n\nlightingInfo computeSpotLighting(vec3 viewDirectionW, vec3 vNormal, vec4 lightData, vec4 lightDirection, vec3 diffuseColor, vec3 specularColor, float range) {\n\tlightingInfo result;\n\n\tvec3 direction = lightData.xyz - vPositionW;\n\tvec3 lightVectorW = normalize(direction);\n\tfloat attenuation = max(0., 1.0 - length(direction) / range);\n\n\t// diffuse\n\tfloat cosAngle = max(0., dot(-lightDirection.xyz, lightVectorW));\n\tfloat spotAtten = 0.0;\n\n\tif (cosAngle >= lightDirection.w)\n\t{\n\t\tcosAngle = max(0., pow(cosAngle, lightData.w));\n\t\tspotAtten = max(0., (cosAngle - lightDirection.w) / (1. - cosAngle));\n\n\t\t// Diffuse\n\t\tfloat ndl = max(0., dot(vNormal, -lightDirection.xyz));\n\n\t\t// Specular\n\t\tvec3 angleW = normalize(viewDirectionW - lightDirection.xyz);\n\t\tfloat specComp = max(0., dot(vNormal, angleW));\n\t\tspecComp = pow(specComp, vSpecularColor.a);\n\n\t\tresult.diffuse = ndl * spotAtten * diffuseColor * attenuation;\n\t\tresult.specular = specComp * specularColor * spotAtten * attenuation;\n\n\t\treturn result;\n\t}\n\n\tresult.diffuse = vec3(0.);\n\tresult.specular = vec3(0.);\n\n\treturn result;\n}\n\nlightingInfo computeHemisphericLighting(vec3 viewDirectionW, vec3 vNormal, vec4 lightData, vec3 diffuseColor, vec3 specularColor, vec3 groundColor) {\n\tlightingInfo result;\n\n\t// Diffuse\n\tfloat ndl = dot(vNormal, lightData.xyz) * 0.5 + 0.5;\n\n\t// Specular\n\tvec3 angleW = normalize(viewDirectionW + lightData.xyz);\n\tfloat specComp = max(0., dot(vNormal, angleW));\n\tspecComp = pow(specComp, vSpecularColor.a);\n\n\tresult.diffuse = mix(groundColor, diffuseColor, ndl);\n\tresult.specular = specComp * specularColor;\n\n\treturn result;\n}\n\nvoid main(void) {\n\t// Clip plane\n#ifdef CLIPPLANE\n\tif (fClipDistance > 0.0)\n\t\tdiscard;\n#endif\n\n\tvec3 viewDirectionW = normalize(vEyePosition - vPositionW);\n\n\t// Base color\n\tvec4 baseColor = vec4(1., 1., 1., 1.);\n\tvec3 diffuseColor = vDiffuseColor.rgb;\n\n\t// Alpha\n\tfloat alpha = vDiffuseColor.a;\n\n#ifdef VERTEXCOLOR\n\tdiffuseColor *= vColor;\n#endif\n\n#ifdef DIFFUSE\n\tbaseColor = texture2D(diffuseSampler, vDiffuseUV);\n\n#ifdef ALPHATEST\n\tif (baseColor.a < 0.4)\n\t\tdiscard;\n#endif\n\n#ifdef ALPHAFROMDIFFUSE\n\talpha *= baseColor.a;\n#endif\n\n\tbaseColor.rgb *= vDiffuseInfos.y;\n#endif\n\n\t// Bump\n\tvec3 normalW = normalize(vNormalW);\n\n#ifdef BUMP\n\tnormalW = perturbNormal(viewDirectionW);\n#endif\n\n\t// Ambient color\n\tvec3 baseAmbientColor = vec3(1., 1., 1.);\n\n#ifdef AMBIENT\n\tbaseAmbientColor = texture2D(ambientSampler, vAmbientUV).rgb * vAmbientInfos.y;\n#endif\n\n\t// Lighting\n\tvec3 diffuseBase = vec3(0., 0., 0.);\n\tvec3 specularBase = vec3(0., 0., 0.);\n\tfloat shadow = 1.;\n\n#ifdef LIGHT0\n#ifdef SPOTLIGHT0\n\tlightingInfo info = computeSpotLighting(viewDirectionW, normalW, vLightData0, vLightDirection0, vLightDiffuse0.rgb, vLightSpecular0, vLightDiffuse0.a);\n#endif\n#ifdef HEMILIGHT0\n\tlightingInfo info = computeHemisphericLighting(viewDirectionW, normalW, vLightData0, vLightDiffuse0.rgb, vLightSpecular0, vLightGround0);\n#endif\n#ifdef POINTDIRLIGHT0\n\tlightingInfo info = computeLighting(viewDirectionW, normalW, vLightData0, vLightDiffuse0.rgb, vLightSpecular0, vLightDiffuse0.a);\n#endif\n#ifdef SHADOW0\n#ifdef SHADOWVSM0\n\tshadow = computeShadowWithVSM(vPositionFromLight0, shadowSampler0);\n#else\n\t#ifdef SHADOWPCF0\n\t\tshadow = computeShadowWithPCF(vPositionFromLight0, shadowSampler0);\n\t#else\n\t\tshadow = computeShadow(vPositionFromLight0, shadowSampler0, darkness0);\n\t#endif\n#endif\n#else\n\tshadow = 1.;\n#endif\n\tdiffuseBase += info.diffuse * shadow;\n\tspecularBase += info.specular * shadow;\n#endif\n\n#ifdef LIGHT1\n#ifdef SPOTLIGHT1\n\tinfo = computeSpotLighting(viewDirectionW, normalW, vLightData1, vLightDirection1, vLightDiffuse1.rgb, vLightSpecular1, vLightDiffuse1.a);\n#endif\n#ifdef HEMILIGHT1\n\tinfo = computeHemisphericLighting(viewDirectionW, normalW, vLightData1, vLightDiffuse1.rgb, vLightSpecular1, vLightGround1);\n#endif\n#ifdef POINTDIRLIGHT1\n\tinfo = computeLighting(viewDirectionW, normalW, vLightData1, vLightDiffuse1.rgb, vLightSpecular1, vLightDiffuse1.a);\n#endif\n#ifdef SHADOW1\n#ifdef SHADOWVSM1\n\tshadow = computeShadowWithVSM(vPositionFromLight1, shadowSampler1);\n#else\n\t#ifdef SHADOWPCF1\n\t\tshadow = computeShadowWithPCF(vPositionFromLight1, shadowSampler1);\n\t#else\n\t\tshadow = computeShadow(vPositionFromLight1, shadowSampler1, darkness1);\n\t#endif\n#endif\n#else\n\tshadow = 1.;\n#endif\n\tdiffuseBase += info.diffuse * shadow;\n\tspecularBase += info.specular * shadow;\n#endif\n\n#ifdef LIGHT2\n#ifdef SPOTLIGHT2\n\tinfo = computeSpotLighting(viewDirectionW, normalW, vLightData2, vLightDirection2, vLightDiffuse2.rgb, vLightSpecular2, vLightDiffuse2.a);\n#endif\n#ifdef HEMILIGHT2\n\tinfo = computeHemisphericLighting(viewDirectionW, normalW, vLightData2, vLightDiffuse2.rgb, vLightSpecular2, vLightGround2);\n#endif\n#ifdef POINTDIRLIGHT2\n\tinfo = computeLighting(viewDirectionW, normalW, vLightData2, vLightDiffuse2.rgb, vLightSpecular2, vLightDiffuse2.a);\n#endif\n#ifdef SHADOW2\n#ifdef SHADOWVSM2\n\tshadow = computeShadowWithVSM(vPositionFromLight2, shadowSampler2);\n#else\n\t#ifdef SHADOWPCF2\n\t\tshadow = computeShadowWithPCF(vPositionFromLight2, shadowSampler2);\n\t#else\n\t\tshadow = computeShadow(vPositionFromLight2, shadowSampler2, darkness2);\n\t#endif\t\n#endif\t\n#else\n\tshadow = 1.;\n#endif\n\tdiffuseBase += info.diffuse * shadow;\n\tspecularBase += info.specular * shadow;\n#endif\n\n#ifdef LIGHT3\n#ifdef SPOTLIGHT3\n\tinfo = computeSpotLighting(viewDirectionW, normalW, vLightData3, vLightDirection3, vLightDiffuse3.rgb, vLightSpecular3, vLightDiffuse3.a);\n#endif\n#ifdef HEMILIGHT3\n\tinfo = computeHemisphericLighting(viewDirectionW, normalW, vLightData3, vLightDiffuse3.rgb, vLightSpecular3, vLightGround3);\n#endif\n#ifdef POINTDIRLIGHT3\n\tinfo = computeLighting(viewDirectionW, normalW, vLightData3, vLightDiffuse3.rgb, vLightSpecular3, vLightDiffuse3.a);\n#endif\n#ifdef SHADOW3\n#ifdef SHADOWVSM3\n\tshadow = computeShadowWithVSM(vPositionFromLight3, shadowSampler3);\n#else\n\t#ifdef SHADOWPCF3\n\t\tshadow = computeShadowWithPCF(vPositionFromLight3, shadowSampler3);\n\t#else\n\t\tshadow = computeShadow(vPositionFromLight3, shadowSampler3, darkness3);\n\t#endif\t\n#endif\t\n#else\n\tshadow = 1.;\n#endif\n\tdiffuseBase += info.diffuse * shadow;\n\tspecularBase += info.specular * shadow;\n#endif\n\n\t// Reflection\n\tvec3 reflectionColor = vec3(0., 0., 0.);\n\n#ifdef REFLECTION\n\tvec3 vReflectionUVW = computeReflectionCoords(vReflectionInfos.x, vec4(vPositionW, 1.0), normalW);\n\n\tif (vReflectionInfos.z != 0.0)\n\t{\n\t\treflectionColor = textureCube(reflectionCubeSampler, vReflectionUVW).rgb * vReflectionInfos.y * shadow;\n\t}\n\telse\n\t{\n\t\tvec2 coords = vReflectionUVW.xy;\n\n\t\tif (vReflectionInfos.x == MAP_PROJECTION)\n\t\t{\n\t\t\tcoords /= vReflectionUVW.z;\n\t\t}\n\n\t\tcoords.y = 1.0 - coords.y;\n\n\t\treflectionColor = texture2D(reflection2DSampler, coords).rgb * vReflectionInfos.y * shadow;\n\t}\n#endif\n\n#ifdef OPACITY\n\tvec4 opacityMap = texture2D(opacitySampler, vOpacityUV);\n\n#ifdef OPACITYRGB\n\topacityMap.rgb = opacityMap.rgb * vec3(0.3, 0.59, 0.11);\n\talpha *= (opacityMap.x + opacityMap.y + opacityMap.z)* vOpacityInfos.y;\n#else\n\talpha *= opacityMap.a * vOpacityInfos.y;\n#endif\n\n\n#endif\n\n\t// Emissive\n\tvec3 emissiveColor = vEmissiveColor;\n#ifdef EMISSIVE\n\temissiveColor += texture2D(emissiveSampler, vEmissiveUV).rgb * vEmissiveInfos.y;\n#endif\n\n\t// Specular map\n\tvec3 specularColor = vSpecularColor.rgb;\n#ifdef SPECULAR\n\tspecularColor = texture2D(specularSampler, vSpecularUV).rgb * vSpecularInfos.y;\n#endif\n\n\t// Composition\n\tvec3 finalDiffuse = clamp(diffuseBase * diffuseColor + emissiveColor + vAmbientColor, 0.0, 1.0) * baseColor.rgb;\n\tvec3 finalSpecular = specularBase * specularColor;\n\n\tvec4 color = vec4(finalDiffuse * baseAmbientColor + finalSpecular + reflectionColor, alpha);\n\n#ifdef FOG\n\tfloat fog = CalcFogFactor();\n\tcolor.rgb = fog * color.rgb + (1.0 - fog) * vFogColor;\n#endif\n\n\tgl_FragColor = color;\n}",
		"defaultVertexShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Attributes\nattribute vec3 position;\nattribute vec3 normal;\n#ifdef UV1\nattribute vec2 uv;\n#endif\n#ifdef UV2\nattribute vec2 uv2;\n#endif\n#ifdef VERTEXCOLOR\nattribute vec3 color;\n#endif\n#ifdef BONES\nattribute vec4 matricesIndices;\nattribute vec4 matricesWeights;\n#endif\n\n// Uniforms\n\n#ifdef INSTANCES\nattribute vec4 world0;\nattribute vec4 world1;\nattribute vec4 world2;\nattribute vec4 world3;\n#else\nuniform mat4 world;\n#endif\n\nuniform mat4 view;\nuniform mat4 viewProjection;\n\n#ifdef DIFFUSE\nvarying vec2 vDiffuseUV;\nuniform mat4 diffuseMatrix;\nuniform vec2 vDiffuseInfos;\n#endif\n\n#ifdef AMBIENT\nvarying vec2 vAmbientUV;\nuniform mat4 ambientMatrix;\nuniform vec2 vAmbientInfos;\n#endif\n\n#ifdef OPACITY\nvarying vec2 vOpacityUV;\nuniform mat4 opacityMatrix;\nuniform vec2 vOpacityInfos;\n#endif\n\n#ifdef EMISSIVE\nvarying vec2 vEmissiveUV;\nuniform vec2 vEmissiveInfos;\nuniform mat4 emissiveMatrix;\n#endif\n\n#ifdef SPECULAR\nvarying vec2 vSpecularUV;\nuniform vec2 vSpecularInfos;\nuniform mat4 specularMatrix;\n#endif\n\n#ifdef BUMP\nvarying vec2 vBumpUV;\nuniform vec2 vBumpInfos;\nuniform mat4 bumpMatrix;\n#endif\n\n#ifdef BONES\nuniform mat4 mBones[BonesPerMesh];\n#endif\n\n// Output\nvarying vec3 vPositionW;\nvarying vec3 vNormalW;\n\n#ifdef VERTEXCOLOR\nvarying vec3 vColor;\n#endif\n\n#ifdef CLIPPLANE\nuniform vec4 vClipPlane;\nvarying float fClipDistance;\n#endif\n\n#ifdef FOG\nvarying float fFogDistance;\n#endif\n\n#ifdef SHADOWS\n#ifdef LIGHT0\nuniform mat4 lightMatrix0;\nvarying vec4 vPositionFromLight0;\n#endif\n#ifdef LIGHT1\nuniform mat4 lightMatrix1;\nvarying vec4 vPositionFromLight1;\n#endif\n#ifdef LIGHT2\nuniform mat4 lightMatrix2;\nvarying vec4 vPositionFromLight2;\n#endif\n#ifdef LIGHT3\nuniform mat4 lightMatrix3;\nvarying vec4 vPositionFromLight3;\n#endif\n#endif\n\n#ifdef REFLECTION\nvarying vec3 vPositionUVW;\n#endif\n\nvoid main(void) {\n\tmat4 finalWorld;\n\n#ifdef REFLECTION\n\tvPositionUVW = position;\n#endif \n\n#ifdef BONES\n\tmat4 m0 = mBones[int(matricesIndices.x)] * matricesWeights.x;\n\tmat4 m1 = mBones[int(matricesIndices.y)] * matricesWeights.y;\n\tmat4 m2 = mBones[int(matricesIndices.z)] * matricesWeights.z;\n\n#ifdef BONES4\n\tmat4 m3 = mBones[int(matricesIndices.w)] * matricesWeights.w;\n\tfinalWorld = world * (m0 + m1 + m2 + m3);\n#else\n\tfinalWorld = world * (m0 + m1 + m2);\n#endif \n\n#else\n#ifdef INSTANCES\n\tfinalWorld = mat4(world0, world1, world2, world3);\n#else\n\tfinalWorld = world;\n#endif\n#endif\n\tgl_Position = viewProjection * finalWorld * vec4(position, 1.0);\n\n\tvec4 worldPos = finalWorld * vec4(position, 1.0);\n\tvPositionW = vec3(worldPos);\n\tvNormalW = normalize(vec3(finalWorld * vec4(normal, 0.0)));\n\n\t// Texture coordinates\n#ifndef UV1\n\tvec2 uv = vec2(0., 0.);\n#endif\n#ifndef UV2\n\tvec2 uv2 = vec2(0., 0.);\n#endif\n\n#ifdef DIFFUSE\n\tif (vDiffuseInfos.x == 0.)\n\t{\n\t\tvDiffuseUV = vec2(diffuseMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvDiffuseUV = vec2(diffuseMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n#ifdef AMBIENT\n\tif (vAmbientInfos.x == 0.)\n\t{\n\t\tvAmbientUV = vec2(ambientMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvAmbientUV = vec2(ambientMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n#ifdef OPACITY\n\tif (vOpacityInfos.x == 0.)\n\t{\n\t\tvOpacityUV = vec2(opacityMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvOpacityUV = vec2(opacityMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n#ifdef EMISSIVE\n\tif (vEmissiveInfos.x == 0.)\n\t{\n\t\tvEmissiveUV = vec2(emissiveMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvEmissiveUV = vec2(emissiveMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n#ifdef SPECULAR\n\tif (vSpecularInfos.x == 0.)\n\t{\n\t\tvSpecularUV = vec2(specularMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvSpecularUV = vec2(specularMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n#ifdef BUMP\n\tif (vBumpInfos.x == 0.)\n\t{\n\t\tvBumpUV = vec2(bumpMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvBumpUV = vec2(bumpMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n\t// Clip plane\n#ifdef CLIPPLANE\n\tfClipDistance = dot(worldPos, vClipPlane);\n#endif\n\n\t// Fog\n#ifdef FOG\n\tfFogDistance = (view * worldPos).z;\n#endif\n\n\t// Shadows\n#ifdef SHADOWS\n#ifdef LIGHT0\n\tvPositionFromLight0 = lightMatrix0 * worldPos;\n#endif\n#ifdef LIGHT1\n\tvPositionFromLight1 = lightMatrix1 * worldPos;\n#endif\n#ifdef LIGHT2\n\tvPositionFromLight2 = lightMatrix2 * worldPos;\n#endif\n#ifdef LIGHT3\n\tvPositionFromLight3 = lightMatrix3 * worldPos;\n#endif\n#endif\n\n\t// Vertex color\n#ifdef VERTEXCOLOR\n\tvColor = color;\n#endif\n}",
		"displaypassPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\nuniform sampler2D passSampler;\n\nvoid main(void)\n{\n    gl_FragColor = texture2D(passSampler, vUV);\n}",
		"filterPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\n\nuniform mat4 kernelMatrix;\n\nvoid main(void)\n{\n\tvec3 baseColor = texture2D(textureSampler, vUV).rgb;\n\tvec3 updatedColor = (kernelMatrix * vec4(baseColor, 1.0)).rgb;\n\n\tgl_FragColor = vec4(updatedColor, 1.0);\n}",
		"fxaaPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n#define FXAA_REDUCE_MIN   (1.0/128.0)\n#define FXAA_REDUCE_MUL   (1.0/8.0)\n#define FXAA_SPAN_MAX     8.0\n\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\nuniform vec2 texelSize;\n\nvoid main(){\n\tvec2 localTexelSize = texelSize;\n\tvec4 rgbNW = texture2D(textureSampler, (vUV + vec2(-1.0, -1.0) * localTexelSize));\n\tvec4 rgbNE = texture2D(textureSampler, (vUV + vec2(1.0, -1.0) * localTexelSize));\n\tvec4 rgbSW = texture2D(textureSampler, (vUV + vec2(-1.0, 1.0) * localTexelSize));\n\tvec4 rgbSE = texture2D(textureSampler, (vUV + vec2(1.0, 1.0) * localTexelSize));\n\tvec4 rgbM = texture2D(textureSampler, vUV);\n\tvec4 luma = vec4(0.299, 0.587, 0.114, 1.0);\n\tfloat lumaNW = dot(rgbNW, luma);\n\tfloat lumaNE = dot(rgbNE, luma);\n\tfloat lumaSW = dot(rgbSW, luma);\n\tfloat lumaSE = dot(rgbSE, luma);\n\tfloat lumaM = dot(rgbM, luma);\n\tfloat lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));\n\tfloat lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));\n\n\tvec2 dir = vec2(-((lumaNW + lumaNE) - (lumaSW + lumaSE)), ((lumaNW + lumaSW) - (lumaNE + lumaSE)));\n\n\tfloat dirReduce = max(\n\t\t(lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),\n\t\tFXAA_REDUCE_MIN);\n\n\tfloat rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);\n\tdir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),\n\t\tmax(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),\n\t\tdir * rcpDirMin)) * localTexelSize;\n\n\tvec4 rgbA = 0.5 * (\n\t\ttexture2D(textureSampler, vUV + dir * (1.0 / 3.0 - 0.5)) +\n\t\ttexture2D(textureSampler, vUV + dir * (2.0 / 3.0 - 0.5)));\n\n\tvec4 rgbB = rgbA * 0.5 + 0.25 * (\n\t\ttexture2D(textureSampler, vUV + dir *  -0.5) +\n\t\ttexture2D(textureSampler, vUV + dir * 0.5));\n\tfloat lumaB = dot(rgbB, luma);\n\tif ((lumaB < lumaMin) || (lumaB > lumaMax)) {\n\t\tgl_FragColor = rgbA;\n\t}\n\telse {\n\t\tgl_FragColor = rgbB;\n\t}\n}",
		"layerPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\n\n// Color\nuniform vec4 color;\n\nvoid main(void) {\n\tvec4 baseColor = texture2D(textureSampler, vUV);\n\n\tgl_FragColor = baseColor * color;\n}",
		"layerVertexShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Attributes\nattribute vec2 position;\n\n// Uniforms\nuniform mat4 textureMatrix;\n\n// Output\nvarying vec2 vUV;\n\nconst vec2 madd = vec2(0.5, 0.5);\n\nvoid main(void) {\t\n\n\tvUV = vec2(textureMatrix * vec4(position * madd + madd, 1.0, 0.0));\n\tgl_Position = vec4(position, 0.0, 1.0);\n}",
		"legacydefaultPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n#define MAP_PROJECTION\t4.\n\n// Constants\nuniform vec3 vEyePosition;\nuniform vec3 vAmbientColor;\nuniform vec4 vDiffuseColor;\nuniform vec4 vSpecularColor;\nuniform vec3 vEmissiveColor;\n\n// Input\nvarying vec3 vPositionW;\nvarying vec3 vNormalW;\n\n#ifdef VERTEXCOLOR\nvarying vec3 vColor;\n#endif\n\n// Lights\n#ifdef LIGHT0\nuniform vec4 vLightData0;\nuniform vec4 vLightDiffuse0;\nuniform vec3 vLightSpecular0;\n#ifdef SHADOW0\nvarying vec4 vPositionFromLight0;\nuniform sampler2D shadowSampler0;\n#endif\n#ifdef SPOTLIGHT0\nuniform vec4 vLightDirection0;\n#endif\n#ifdef HEMILIGHT0\nuniform vec3 vLightGround0;\n#endif\n#endif\n\n#ifdef LIGHT1\nuniform vec4 vLightData1;\nuniform vec4 vLightDiffuse1;\nuniform vec3 vLightSpecular1;\n#ifdef SHADOW1\nvarying vec4 vPositionFromLight1;\nuniform sampler2D shadowSampler1;\n#endif\n#ifdef SPOTLIGHT1\nuniform vec4 vLightDirection1;\n#endif\n#ifdef HEMILIGHT1\nuniform vec3 vLightGround1;\n#endif\n#endif\n\n#ifdef LIGHT2\nuniform vec4 vLightData2;\nuniform vec4 vLightDiffuse2;\nuniform vec3 vLightSpecular2;\n#ifdef SHADOW2\nvarying vec4 vPositionFromLight2;\nuniform sampler2D shadowSampler2;\n#endif\n#ifdef SPOTLIGHT2\nuniform vec4 vLightDirection2;\n#endif\n#ifdef HEMILIGHT2\nuniform vec3 vLightGround2;\n#endif\n#endif\n\n#ifdef LIGHT3\nuniform vec4 vLightData3;\nuniform vec4 vLightDiffuse3;\nuniform vec3 vLightSpecular3;\n#ifdef SHADOW3\nvarying vec4 vPositionFromLight3;\nuniform sampler2D shadowSampler3;\n#endif\n#ifdef SPOTLIGHT3\nuniform vec4 vLightDirection3;\n#endif\n#ifdef HEMILIGHT3\nuniform vec3 vLightGround3;\n#endif\n#endif\n\n// Samplers\n#ifdef DIFFUSE\nvarying vec2 vDiffuseUV;\nuniform sampler2D diffuseSampler;\nuniform vec2 vDiffuseInfos;\n#endif\n\n#ifdef AMBIENT\nvarying vec2 vAmbientUV;\nuniform sampler2D ambientSampler;\nuniform vec2 vAmbientInfos;\n#endif\n\n#ifdef OPACITY\t\nvarying vec2 vOpacityUV;\nuniform sampler2D opacitySampler;\nuniform vec2 vOpacityInfos;\n#endif\n\n#ifdef REFLECTION\nvarying vec3 vReflectionUVW;\nuniform samplerCube reflectionCubeSampler;\nuniform sampler2D reflection2DSampler;\nuniform vec3 vReflectionInfos;\n#endif\n\n#ifdef EMISSIVE\nvarying vec2 vEmissiveUV;\nuniform vec2 vEmissiveInfos;\nuniform sampler2D emissiveSampler;\n#endif\n\n#ifdef SPECULAR\nvarying vec2 vSpecularUV;\nuniform vec2 vSpecularInfos;\nuniform sampler2D specularSampler;\n#endif\n\n// Shadows\n#ifdef SHADOWS\n\nfloat unpack(vec4 color)\n{\n\tconst vec4 bitShift = vec4(1. / (255. * 255. * 255.), 1. / (255. * 255.), 1. / 255., 1.);\n\treturn dot(color, bitShift);\n}\n\nfloat unpackHalf(vec2 color)\n{\n\treturn color.x + (color.y / 255.0);\n}\n\nfloat computeShadow(vec4 vPositionFromLight, sampler2D shadowSampler)\n{\n\tvec3 depth = vPositionFromLight.xyz / vPositionFromLight.w;\n\tvec2 uv = 0.5 * depth.xy + vec2(0.5, 0.5);\n\n\tif (uv.x < 0. || uv.x > 1.0 || uv.y < 0. || uv.y > 1.0)\n\t{\n\t\treturn 1.0;\n\t}\n\n\tfloat shadow = unpack(texture2D(shadowSampler, uv));\n\n\tif (depth.z > shadow)\n\t{\n\t\treturn 0.;\n\t}\n\treturn 1.;\n}\n\n// Thanks to http://devmaster.net/\nfloat ChebychevInequality(vec2 moments, float t)\n{\n\tif (t <= moments.x)\n\t{\n\t\treturn 1.0;\n\t}\n\n\tfloat variance = moments.y - (moments.x * moments.x);\n\tvariance = max(variance, 0.);\n\n\tfloat d = t - moments.x;\n\treturn variance / (variance + d * d);\n}\n\nfloat computeShadowWithVSM(vec4 vPositionFromLight, sampler2D shadowSampler)\n{\n\tvec3 depth = vPositionFromLight.xyz / vPositionFromLight.w;\n\tvec2 uv = 0.5 * depth.xy + vec2(0.5, 0.5);\n\n\tif (uv.x < 0. || uv.x > 1.0 || uv.y < 0. || uv.y > 1.0)\n\t{\n\t\treturn 1.0;\n\t}\n\n\tvec4 texel = texture2D(shadowSampler, uv);\n\n\tvec2 moments = vec2(unpackHalf(texel.xy), unpackHalf(texel.zw));\n\treturn clamp(1.3 - ChebychevInequality(moments, depth.z), 0., 1.0);\n}\n#endif\n\n#ifdef CLIPPLANE\nvarying float fClipDistance;\n#endif\n\n// Fog\n#ifdef FOG\n\n#define FOGMODE_NONE    0.\n#define FOGMODE_EXP     1.\n#define FOGMODE_EXP2    2.\n#define FOGMODE_LINEAR  3.\n#define E 2.71828\n\nuniform vec4 vFogInfos;\nuniform vec3 vFogColor;\nvarying float fFogDistance;\n\nfloat CalcFogFactor()\n{\n\tfloat fogCoeff = 1.0;\n\tfloat fogStart = vFogInfos.y;\n\tfloat fogEnd = vFogInfos.z;\n\tfloat fogDensity = vFogInfos.w;\n\n\tif (FOGMODE_LINEAR == vFogInfos.x)\n\t{\n\t\tfogCoeff = (fogEnd - fFogDistance) / (fogEnd - fogStart);\n\t}\n\telse if (FOGMODE_EXP == vFogInfos.x)\n\t{\n\t\tfogCoeff = 1.0 / pow(E, fFogDistance * fogDensity);\n\t}\n\telse if (FOGMODE_EXP2 == vFogInfos.x)\n\t{\n\t\tfogCoeff = 1.0 / pow(E, fFogDistance * fFogDistance * fogDensity * fogDensity);\n\t}\n\n\treturn clamp(fogCoeff, 0.0, 1.0);\n}\n#endif\n\n// Light Computing\nmat3 computeLighting(vec3 viewDirectionW, vec3 vNormal, vec4 lightData, vec4 diffuseColor, vec3 specularColor) {\n\tmat3 result;\n\n\tvec3 lightVectorW;\n\tif (lightData.w == 0.)\n\t{\n\t\tlightVectorW = normalize(lightData.xyz - vPositionW);\n\t}\n\telse\n\t{\n\t\tlightVectorW = normalize(-lightData.xyz);\n\t}\n\n\t// diffuse\n\tfloat ndl = max(0., dot(vNormal, lightVectorW));\n\n\t// Specular\n\tvec3 angleW = normalize(viewDirectionW + lightVectorW);\n\tfloat specComp = max(0., dot(vNormal, angleW));\n\tspecComp = max(0., pow(specComp, max(1.0, vSpecularColor.a)));\n\n\tresult[0] = ndl * diffuseColor.rgb;\n\tresult[1] = specComp * specularColor;\n\tresult[2] = vec3(0.);\n\n\treturn result;\n}\n\nmat3 computeSpotLighting(vec3 viewDirectionW, vec3 vNormal, vec4 lightData, vec4 lightDirection, vec4 diffuseColor, vec3 specularColor) {\n\tmat3 result;\n\n\tvec3 lightVectorW = normalize(lightData.xyz - vPositionW);\n\n\t// diffuse\n\tfloat cosAngle = max(0., dot(-lightDirection.xyz, lightVectorW));\n\tfloat spotAtten = 0.0;\n\n\tif (cosAngle >= lightDirection.w)\n\t{\n\t\tcosAngle = max(0., pow(cosAngle, lightData.w));\n\t\tspotAtten = max(0., (cosAngle - lightDirection.w) / (1. - cosAngle));\n\n\t\t// Diffuse\n\t\tfloat ndl = max(0., dot(vNormal, -lightDirection.xyz));\n\n\t\t// Specular\n\t\tvec3 angleW = normalize(viewDirectionW - lightDirection.xyz);\n\t\tfloat specComp = max(0., dot(vNormal, angleW));\n\t\tspecComp = pow(specComp, vSpecularColor.a);\n\n\t\tresult[0] = ndl * spotAtten * diffuseColor.rgb;\n\t\tresult[1] = specComp * specularColor * spotAtten;\n\t\tresult[2] = vec3(0.);\n\n\t\treturn result;\n\t}\n\n\tresult[0] = vec3(0.);\n\tresult[1] = vec3(0.);\n\tresult[2] = vec3(0.);\n\n\treturn result;\n}\n\nmat3 computeHemisphericLighting(vec3 viewDirectionW, vec3 vNormal, vec4 lightData, vec4 diffuseColor, vec3 specularColor, vec3 groundColor) {\n\tmat3 result;\n\n\t// Diffuse\n\tfloat ndl = dot(vNormal, lightData.xyz) * 0.5 + 0.5;\n\n\t// Specular\n\tvec3 angleW = normalize(viewDirectionW + lightData.xyz);\n\tfloat specComp = max(0., dot(vNormal, angleW));\n\tspecComp = pow(specComp, vSpecularColor.a);\n\n\tresult[0] = mix(groundColor, diffuseColor.rgb, ndl);\n\tresult[1] = specComp * specularColor;\n\tresult[2] = vec3(0.);\n\n\treturn result;\n}\n\nvoid main(void) {\n\t// Clip plane\n#ifdef CLIPPLANE\n\tif (fClipDistance > 0.0)\n\t\tdiscard;\n#endif\n\n\tvec3 viewDirectionW = normalize(vEyePosition - vPositionW);\n\n\t// Base color\n\tvec4 baseColor = vec4(1., 1., 1., 1.);\n\tvec3 diffuseColor = vDiffuseColor.rgb;\n\n#ifdef VERTEXCOLOR\n\tdiffuseColor *= vColor;\n#endif\n\n#ifdef DIFFUSE\n\tbaseColor = texture2D(diffuseSampler, vDiffuseUV);\n\n#ifdef ALPHATEST\n\tif (baseColor.a < 0.4)\n\t\tdiscard;\n#endif\n\n\tbaseColor.rgb *= vDiffuseInfos.y;\n#endif\n\n\t// Bump\n\tvec3 normalW = normalize(vNormalW);\n\n\t// Ambient color\n\tvec3 baseAmbientColor = vec3(1., 1., 1.);\n\n#ifdef AMBIENT\n\tbaseAmbientColor = texture2D(ambientSampler, vAmbientUV).rgb * vAmbientInfos.y;\n#endif\n\n\t// Lighting\n\tvec3 diffuseBase = vec3(0., 0., 0.);\n\tvec3 specularBase = vec3(0., 0., 0.);\n\tfloat shadow = 1.;\n\n#ifdef LIGHT0\n#ifdef SPOTLIGHT0\n\tmat3 info = computeSpotLighting(viewDirectionW, normalW, vLightData0, vLightDirection0, vLightDiffuse0, vLightSpecular0);\n#endif\n#ifdef HEMILIGHT0\n\tmat3 info = computeHemisphericLighting(viewDirectionW, normalW, vLightData0, vLightDiffuse0, vLightSpecular0, vLightGround0);\n#endif\n#ifdef POINTDIRLIGHT0\n\tmat3 info = computeLighting(viewDirectionW, normalW, vLightData0, vLightDiffuse0, vLightSpecular0);\n#endif\n#ifdef SHADOW0\n#ifdef SHADOWVSM0\n\tshadow = computeShadowWithVSM(vPositionFromLight0, shadowSampler0);\n#else\n\tshadow = computeShadow(vPositionFromLight0, shadowSampler0);\n#endif\n#else\n\tshadow = 1.;\n#endif\n\tdiffuseBase += info[0] * shadow;\n\tspecularBase += info[1] * shadow;\n#endif\n\n#ifdef LIGHT1\n#ifdef SPOTLIGHT1\n\tinfo = computeSpotLighting(viewDirectionW, normalW, vLightData1, vLightDirection1, vLightDiffuse1, vLightSpecular1);\n#endif\n#ifdef HEMILIGHT1\n\tinfo = computeHemisphericLighting(viewDirectionW, normalW, vLightData1, vLightDiffuse1, vLightSpecular1, vLightGround1);\n#endif\n#ifdef POINTDIRLIGHT1\n\tinfo = computeLighting(viewDirectionW, normalW, vLightData1, vLightDiffuse1, vLightSpecular1);\n#endif\n#ifdef SHADOW1\n#ifdef SHADOWVSM1\n\tshadow = computeShadowWithVSM(vPositionFromLight1, shadowSampler1);\n#else\n\tshadow = computeShadow(vPositionFromLight1, shadowSampler1);\n#endif\n#else\n\tshadow = 1.;\n#endif\n\tdiffuseBase += info[0] * shadow;\n\tspecularBase += info[1] * shadow;\n#endif\n\n#ifdef LIGHT2\n#ifdef SPOTLIGHT2\n\tinfo = computeSpotLighting(viewDirectionW, normalW, vLightData2, vLightDirection2, vLightDiffuse2, vLightSpecular2);\n#endif\n#ifdef HEMILIGHT2\n\tinfo = computeHemisphericLighting(viewDirectionW, normalW, vLightData2, vLightDiffuse2, vLightSpecular2, vLightGround2);\n#endif\n#ifdef POINTDIRLIGHT2\n\tinfo = computeLighting(viewDirectionW, normalW, vLightData2, vLightDiffuse2, vLightSpecular2);\n#endif\n#ifdef SHADOW2\n#ifdef SHADOWVSM2\n\tshadow = computeShadowWithVSM(vPositionFromLight2, shadowSampler2);\n#else\n\tshadow = computeShadow(vPositionFromLight2, shadowSampler2);\n#endif\t\n#else\n\tshadow = 1.;\n#endif\n\tdiffuseBase += info[0] * shadow;\n\tspecularBase += info[1] * shadow;\n#endif\n\n#ifdef LIGHT3\n#ifdef SPOTLIGHT3\n\tinfo = computeSpotLighting(viewDirectionW, normalW, vLightData3, vLightDirection3, vLightDiffuse3, vLightSpecular3);\n#endif\n#ifdef HEMILIGHT3\n\tinfo = computeHemisphericLighting(viewDirectionW, normalW, vLightData3, vLightDiffuse3, vLightSpecular3, vLightGround3);\n#endif\n#ifdef POINTDIRLIGHT3\n\tinfo = computeLighting(viewDirectionW, normalW, vLightData3, vLightDiffuse3, vLightSpecular3);\n#endif\n#ifdef SHADOW3\n#ifdef SHADOWVSM3\n\tshadow = computeShadowWithVSM(vPositionFromLight3, shadowSampler3);\n#else\n\tshadow = computeShadow(vPositionFromLight3, shadowSampler3);\n#endif\t\n#else\n\tshadow = 1.;\n#endif\n\tdiffuseBase += info[0] * shadow;\n\tspecularBase += info[1] * shadow;\n#endif\n\n\t// Reflection\n\tvec3 reflectionColor = vec3(0., 0., 0.);\n\n#ifdef REFLECTION\n\tif (vReflectionInfos.z != 0.0)\n\t{\n\t\treflectionColor = textureCube(reflectionCubeSampler, vReflectionUVW).rgb * vReflectionInfos.y;\n\t}\n\telse\n\t{\n\t\tvec2 coords = vReflectionUVW.xy;\n\n\t\tif (vReflectionInfos.x == MAP_PROJECTION)\n\t\t{\n\t\t\tcoords /= vReflectionUVW.z;\n\t\t}\n\n\t\tcoords.y = 1.0 - coords.y;\n\n\t\treflectionColor = texture2D(reflection2DSampler, coords).rgb * vReflectionInfos.y;\n\t}\n#endif\n\n\t// Alpha\n\tfloat alpha = vDiffuseColor.a;\n\n#ifdef OPACITY\n\tvec4 opacityMap = texture2D(opacitySampler, vOpacityUV);\n#ifdef OPACITYRGB\n\topacityMap.rgb = opacityMap.rgb * vec3(0.3, 0.59, 0.11);\n\talpha *= (opacityMap.x + opacityMap.y + opacityMap.z)* vOpacityInfos.y;\n#else\n\talpha *= opacityMap.a * vOpacityInfos.y;\n#endif\n#endif\n\n\t// Emissive\n\tvec3 emissiveColor = vEmissiveColor;\n#ifdef EMISSIVE\n\temissiveColor += texture2D(emissiveSampler, vEmissiveUV).rgb * vEmissiveInfos.y;\n#endif\n\n\t// Specular map\n\tvec3 specularColor = vSpecularColor.rgb;\n#ifdef SPECULAR\n\tspecularColor = texture2D(specularSampler, vSpecularUV).rgb * vSpecularInfos.y;\n#endif\n\n\t// Composition\n\tvec3 finalDiffuse = clamp(diffuseBase * diffuseColor + emissiveColor + vAmbientColor, 0.0, 1.0) * baseColor.rgb;\n\tvec3 finalSpecular = specularBase * specularColor;\n\n\tvec4 color = vec4(finalDiffuse * baseAmbientColor + finalSpecular + reflectionColor, alpha);\n\n#ifdef FOG\n\tfloat fog = CalcFogFactor();\n\tcolor.rgb = fog * color.rgb + (1.0 - fog) * vFogColor;\n#endif\n\n\tgl_FragColor = color;\n}",
		"legacydefaultVertexShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n#define MAP_EXPLICIT\t0.\n#define MAP_SPHERICAL\t1.\n#define MAP_PLANAR\t\t2.\n#define MAP_CUBIC\t\t3.\n#define MAP_PROJECTION\t4.\n#define MAP_SKYBOX\t\t5.\n\n// Attributes\nattribute vec3 position;\nattribute vec3 normal;\n#ifdef UV1\nattribute vec2 uv;\n#endif\n#ifdef UV2\nattribute vec2 uv2;\n#endif\n#ifdef VERTEXCOLOR\nattribute vec3 color;\n#endif\n#ifdef BONES\nattribute vec4 matricesIndices;\nattribute vec4 matricesWeights;\n#endif\n\n// Uniforms\nuniform mat4 world;\nuniform mat4 view;\nuniform mat4 viewProjection;\n\n#ifdef DIFFUSE\nvarying vec2 vDiffuseUV;\nuniform mat4 diffuseMatrix;\nuniform vec2 vDiffuseInfos;\n#endif\n\n#ifdef AMBIENT\nvarying vec2 vAmbientUV;\nuniform mat4 ambientMatrix;\nuniform vec2 vAmbientInfos;\n#endif\n\n#ifdef OPACITY\nvarying vec2 vOpacityUV;\nuniform mat4 opacityMatrix;\nuniform vec2 vOpacityInfos;\n#endif\n\n#ifdef REFLECTION\nuniform vec3 vEyePosition;\nvarying vec3 vReflectionUVW;\nuniform vec3 vReflectionInfos;\nuniform mat4 reflectionMatrix;\n#endif\n\n#ifdef EMISSIVE\nvarying vec2 vEmissiveUV;\nuniform vec2 vEmissiveInfos;\nuniform mat4 emissiveMatrix;\n#endif\n\n#ifdef SPECULAR\nvarying vec2 vSpecularUV;\nuniform vec2 vSpecularInfos;\nuniform mat4 specularMatrix;\n#endif\n\n#ifdef BUMP\nvarying vec2 vBumpUV;\nuniform vec2 vBumpInfos;\nuniform mat4 bumpMatrix;\n#endif\n\n#ifdef BONES\nuniform mat4 mBones[BonesPerMesh];\n#endif\n\n// Output\nvarying vec3 vPositionW;\nvarying vec3 vNormalW;\n\n#ifdef VERTEXCOLOR\nvarying vec3 vColor;\n#endif\n\n#ifdef CLIPPLANE\nuniform vec4 vClipPlane;\nvarying float fClipDistance;\n#endif\n\n#ifdef FOG\nvarying float fFogDistance;\n#endif\n\n#ifdef SHADOWS\n#ifdef LIGHT0\nuniform mat4 lightMatrix0;\nvarying vec4 vPositionFromLight0;\n#endif\n#ifdef LIGHT1\nuniform mat4 lightMatrix1;\nvarying vec4 vPositionFromLight1;\n#endif\n#ifdef LIGHT2\nuniform mat4 lightMatrix2;\nvarying vec4 vPositionFromLight2;\n#endif\n#ifdef LIGHT3\nuniform mat4 lightMatrix3;\nvarying vec4 vPositionFromLight3;\n#endif\n#endif\n\n#ifdef REFLECTION\nvec3 computeReflectionCoords(float mode, vec4 worldPos, vec3 worldNormal)\n{\n\tif (mode == MAP_SPHERICAL)\n\t{\n\t\tvec3 coords = vec3(view * vec4(worldNormal, 0.0));\n\n\t\treturn vec3(reflectionMatrix * vec4(coords, 1.0));\n\t}\n\telse if (mode == MAP_PLANAR)\n\t{\n\t\tvec3 viewDir = worldPos.xyz - vEyePosition;\n\t\tvec3 coords = normalize(reflect(viewDir, worldNormal));\n\n\t\treturn vec3(reflectionMatrix * vec4(coords, 1));\n\t}\n\telse if (mode == MAP_CUBIC)\n\t{\n\t\tvec3 viewDir = worldPos.xyz - vEyePosition;\n\t\tvec3 coords = reflect(viewDir, worldNormal);\n\n\t\treturn vec3(reflectionMatrix * vec4(coords, 0));\n\t}\n\telse if (mode == MAP_PROJECTION)\n\t{\n\t\treturn vec3(reflectionMatrix * (view * worldPos));\n\t}\n\telse if (mode == MAP_SKYBOX)\n\t{\n\t\treturn position;\n\t}\n\n\treturn vec3(0, 0, 0);\n}\n#endif\n\nvoid main(void) {\n\tmat4 finalWorld;\n\n#ifdef BONES\n\tmat4 m0 = mBones[int(matricesIndices.x)] * matricesWeights.x;\n\tmat4 m1 = mBones[int(matricesIndices.y)] * matricesWeights.y;\n\tmat4 m2 = mBones[int(matricesIndices.z)] * matricesWeights.z;\n\n#ifdef BONES4\n\tmat4 m3 = mBones[int(matricesIndices.w)] * matricesWeights.w;\n\tfinalWorld = world * (m0 + m1 + m2 + m3);\n#else\n\tfinalWorld = world * (m0 + m1 + m2);\n#endif \n\n#else\n\tfinalWorld = world;\n#endif\n\n\tgl_Position = viewProjection * finalWorld * vec4(position, 1.0);\n\n\tvec4 worldPos = finalWorld * vec4(position, 1.0);\n\tvPositionW = vec3(worldPos);\n\tvNormalW = normalize(vec3(finalWorld * vec4(normal, 0.0)));\n\n\t// Texture coordinates\n#ifndef UV1\n\tvec2 uv = vec2(0., 0.);\n#endif\n#ifndef UV2\n\tvec2 uv2 = vec2(0., 0.);\n#endif\n\n#ifdef DIFFUSE\n\tif (vDiffuseInfos.x == 0.)\n\t{\n\t\tvDiffuseUV = vec2(diffuseMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvDiffuseUV = vec2(diffuseMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n#ifdef AMBIENT\n\tif (vAmbientInfos.x == 0.)\n\t{\n\t\tvAmbientUV = vec2(ambientMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvAmbientUV = vec2(ambientMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n#ifdef OPACITY\n\tif (vOpacityInfos.x == 0.)\n\t{\n\t\tvOpacityUV = vec2(opacityMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvOpacityUV = vec2(opacityMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n#ifdef REFLECTION\n\tvReflectionUVW = computeReflectionCoords(vReflectionInfos.x, vec4(vPositionW, 1.0), vNormalW);\n#endif\n\n#ifdef EMISSIVE\n\tif (vEmissiveInfos.x == 0.)\n\t{\n\t\tvEmissiveUV = vec2(emissiveMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvEmissiveUV = vec2(emissiveMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n#ifdef SPECULAR\n\tif (vSpecularInfos.x == 0.)\n\t{\n\t\tvSpecularUV = vec2(specularMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvSpecularUV = vec2(specularMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n#ifdef BUMP\n\tif (vBumpInfos.x == 0.)\n\t{\n\t\tvBumpUV = vec2(bumpMatrix * vec4(uv, 1.0, 0.0));\n\t}\n\telse\n\t{\n\t\tvBumpUV = vec2(bumpMatrix * vec4(uv2, 1.0, 0.0));\n\t}\n#endif\n\n\t// Clip plane\n#ifdef CLIPPLANE\n\tfClipDistance = dot(worldPos, vClipPlane);\n#endif\n\n\t// Fog\n#ifdef FOG\n\tfFogDistance = (view * worldPos).z;\n#endif\n\n\t// Shadows\n#ifdef SHADOWS\n#ifdef LIGHT0\n\tvPositionFromLight0 = lightMatrix0 * worldPos;\n#endif\n#ifdef LIGHT1\n\tvPositionFromLight1 = lightMatrix1 * worldPos;\n#endif\n#ifdef LIGHT2\n\tvPositionFromLight2 = lightMatrix2 * worldPos;\n#endif\n#ifdef LIGHT3\n\tvPositionFromLight3 = lightMatrix3 * worldPos;\n#endif\n#endif\n\n\t// Vertex color\n#ifdef VERTEXCOLOR\n\tvColor = color;\n#endif\n}",
		"lensFlarePixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\n\n// Color\nuniform vec4 color;\n\nvoid main(void) {\n\tvec4 baseColor = texture2D(textureSampler, vUV);\n\n\tgl_FragColor = baseColor * color;\n}",
		"lensFlareVertexShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Attributes\nattribute vec2 position;\n\n// Uniforms\nuniform mat4 viewportMatrix;\n\n// Output\nvarying vec2 vUV;\n\nconst vec2 madd = vec2(0.5, 0.5);\n\nvoid main(void) {\t\n\n\tvUV = position * madd + madd;\n\tgl_Position = viewportMatrix * vec4(position, 0.0, 1.0);\n}",
		"oculusdistortioncorrectionPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\nuniform vec2 LensCenter;\nuniform vec2 Scale;\nuniform vec2 ScaleIn;\nuniform vec4 HmdWarpParam;\n\nvec2 HmdWarp(vec2 in01) {\n\n\tvec2 theta = (in01 - LensCenter) * ScaleIn; // Scales to [-1, 1]\n\tfloat rSq = theta.x * theta.x + theta.y * theta.y;\n\tvec2 rvector = theta * (HmdWarpParam.x + HmdWarpParam.y * rSq + HmdWarpParam.z * rSq * rSq + HmdWarpParam.w * rSq * rSq * rSq);\n\treturn LensCenter + Scale * rvector;\n}\n\n\n\nvoid main(void)\n{\n\tvec2 tc = HmdWarp(vUV);\n\tif (tc.x <0.0 || tc.x>1.0 || tc.y<0.0 || tc.y>1.0)\n\t\tgl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);\n\telse{\n\t\tgl_FragColor = vec4(texture2D(textureSampler, tc).rgb, 1.0);\n\t}\n}",
		"outlinePixelShader" => "precision mediump float;\n\nuniform vec3 color;\n\n#ifdef ALPHATEST\nvarying vec2 vUV;\nuniform sampler2D diffuseSampler;\n#endif\n\nvoid main(void) {\n#ifdef ALPHATEST\n\tif (texture2D(diffuseSampler, vUV).a < 0.4)\n\t\tdiscard;\n#endif\n\n\tgl_FragColor = vec4(color, 1.);\n}",
		"outlineVertexShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Attribute\nattribute vec3 position;\nattribute vec3 normal;\n\n#ifdef BONES\nattribute vec4 matricesIndices;\nattribute vec4 matricesWeights;\n#endif\n\n// Uniform\nuniform float offset;\n\n#ifdef INSTANCES\nattribute vec4 world0;\nattribute vec4 world1;\nattribute vec4 world2;\nattribute vec4 world3;\n#else\nuniform mat4 world;\n#endif\n\nuniform mat4 viewProjection;\n#ifdef BONES\nuniform mat4 mBones[BonesPerMesh];\n#endif\n\n#ifdef ALPHATEST\nvarying vec2 vUV;\nuniform mat4 diffuseMatrix;\n#ifdef UV1\nattribute vec2 uv;\n#endif\n#ifdef UV2\nattribute vec2 uv2;\n#endif\n#endif\n\nvoid main(void)\n{\n#ifdef INSTANCES\n\tmat4 finalWorld = mat4(world0, world1, world2, world3);\n#else\n\tmat4 finalWorld = world;\n#endif\n\n\tvec3 offsetPosition = position + normal * offset;\n\n#ifdef BONES\n\tmat4 m0 = mBones[int(matricesIndices.x)] * matricesWeights.x;\n\tmat4 m1 = mBones[int(matricesIndices.y)] * matricesWeights.y;\n\tmat4 m2 = mBones[int(matricesIndices.z)] * matricesWeights.z;\n\tmat4 m3 = mBones[int(matricesIndices.w)] * matricesWeights.w;\n\tfinalWorld = finalWorld * (m0 + m1 + m2 + m3);\n\tgl_Position = viewProjection * finalWorld * vec4(offsetPosition, 1.0);\n#else\n\tgl_Position = viewProjection * finalWorld * vec4(offsetPosition, 1.0);\n#endif\n\n#ifdef ALPHATEST\n#ifdef UV1\n\tvUV = vec2(diffuseMatrix * vec4(uv, 1.0, 0.0));\n#endif\n#ifdef UV2\n\tvUV = vec2(diffuseMatrix * vec4(uv2, 1.0, 0.0));\n#endif\n#endif\n}",
		"particlesPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nvarying vec4 vColor;\nuniform vec4 textureMask;\nuniform sampler2D diffuseSampler;\n\n#ifdef CLIPPLANE\nvarying float fClipDistance;\n#endif\n\nvoid main(void) {\n#ifdef CLIPPLANE\n\tif (fClipDistance > 0.0)\n\t\tdiscard;\n#endif\n\tvec4 baseColor = texture2D(diffuseSampler, vUV);\n\n\tgl_FragColor = (baseColor * textureMask + (vec4(1., 1., 1., 1.) - textureMask)) * vColor;\n}",
		"particlesVertexShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Attributes\nattribute vec3 position;\nattribute vec4 color;\nattribute vec4 options;\n\n// Uniforms\nuniform mat4 view;\nuniform mat4 projection;\n\n// Output\nvarying vec2 vUV;\nvarying vec4 vColor;\n\n#ifdef CLIPPLANE\nuniform vec4 vClipPlane;\nuniform mat4 invView;\nvarying float fClipDistance;\n#endif\n\nvoid main(void) {\t\n\tvec3 viewPos = (view * vec4(position, 1.0)).xyz; \n\tvec3 cornerPos;\n\tfloat size = options.y;\n\tfloat angle = options.x;\n\tvec2 offset = options.zw;\n\n\tcornerPos = vec3(offset.x - 0.5, offset.y  - 0.5, 0.) * size;\n\n\t// Rotate\n\tvec3 rotatedCorner;\n\trotatedCorner.x = cornerPos.x * cos(angle) - cornerPos.y * sin(angle);\n\trotatedCorner.y = cornerPos.x * sin(angle) + cornerPos.y * cos(angle);\n\trotatedCorner.z = 0.;\n\n\t// Position\n\tviewPos += rotatedCorner;\n\tgl_Position = projection * vec4(viewPos, 1.0);   \n\t\n\tvColor = color;\n\tvUV = offset;\n\n\t// Clip plane\n#ifdef CLIPPLANE\n\tvec4 worldPos = invView * vec4(viewPos, 1.0);\n\tfClipDistance = dot(worldPos, vClipPlane);\n#endif\n}",
		"passPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\n\nvoid main(void) \n{\n\tgl_FragColor = texture2D(textureSampler, vUV);\n}",
		"postprocessVertexShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Attributes\nattribute vec2 position;\n\n// Output\nvarying vec2 vUV;\n\nconst vec2 madd = vec2(0.5, 0.5);\n\nvoid main(void) {\t\n\n\tvUV = position * madd + madd;\n\tgl_Position = vec4(position, 0.0, 1.0);\n}",
		"refractionPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D textureSampler;\nuniform sampler2D refractionSampler;\n\n// Parameters\nuniform vec3 baseColor;\nuniform float depth;\nuniform float colorLevel;\n\nvoid main() {\n\tfloat ref = 1.0 - texture2D(refractionSampler, vUV).r;\n\n\tvec2 uv = vUV - vec2(0.5);\n\tvec2 offset = uv * depth * ref;\n\tvec3 sourceColor = texture2D(textureSampler, vUV - offset).rgb;\n\n\tgl_FragColor = vec4(sourceColor + sourceColor * ref * colorLevel, 1.0);\n}",
		"shadowMapPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\nvec4 pack(float depth)\n{\n\tconst vec4 bitOffset = vec4(255. * 255. * 255., 255. * 255., 255., 1.);\n\tconst vec4 bitMask = vec4(0., 1. / 255., 1. / 255., 1. / 255.);\n\t\n\tvec4 comp = mod(depth * bitOffset * vec4(254.), vec4(255.)) / vec4(254.);\n\tcomp -= comp.xxyz * bitMask;\n\t\n\treturn comp;\n}\n\n// Thanks to http://devmaster.net/\nvec2 packHalf(float depth) \n{ \n\tconst vec2 bitOffset = vec2(1.0 / 255., 0.);\n\tvec2 color = vec2(depth, fract(depth * 255.));\n\n\treturn color - (color.yy * bitOffset);\n}\n\n#ifndef VSM\nvarying vec4 vPosition;\n#endif\n\n#ifdef ALPHATEST\nvarying vec2 vUV;\nuniform sampler2D diffuseSampler;\n#endif\n\nvoid main(void)\n{\n#ifdef ALPHATEST\n\tif (texture2D(diffuseSampler, vUV).a < 0.4)\n\t\tdiscard;\n#endif\n\n#ifdef VSM\n\tfloat moment1 = gl_FragCoord.z / gl_FragCoord.w;\n\tfloat moment2 = moment1 * moment1;\n\tgl_FragColor = vec4(packHalf(moment1), packHalf(moment2));\n#else\n\tgl_FragColor = pack(vPosition.z / vPosition.w);\n#endif\n}",
		"shadowMapVertexShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Attribute\nattribute vec3 position;\n#ifdef BONES\nattribute vec4 matricesIndices;\nattribute vec4 matricesWeights;\n#endif\n\n// Uniform\n#ifdef INSTANCES\nattribute vec4 world0;\nattribute vec4 world1;\nattribute vec4 world2;\nattribute vec4 world3;\n#else\nuniform mat4 world;\n#endif\n\nuniform mat4 viewProjection;\n#ifdef BONES\nuniform mat4 mBones[BonesPerMesh];\n#endif\n\n#ifndef VSM\nvarying vec4 vPosition;\n#endif\n\n#ifdef ALPHATEST\nvarying vec2 vUV;\nuniform mat4 diffuseMatrix;\n#ifdef UV1\nattribute vec2 uv;\n#endif\n#ifdef UV2\nattribute vec2 uv2;\n#endif\n#endif\n\nvoid main(void)\n{\n#ifdef INSTANCES\n\tmat4 finalWorld = mat4(world0, world1, world2, world3);\n#else\n\tmat4 finalWorld = world;\n#endif\n\n#ifdef BONES\n\tmat4 m0 = mBones[int(matricesIndices.x)] * matricesWeights.x;\n\tmat4 m1 = mBones[int(matricesIndices.y)] * matricesWeights.y;\n\tmat4 m2 = mBones[int(matricesIndices.z)] * matricesWeights.z;\n\tmat4 m3 = mBones[int(matricesIndices.w)] * matricesWeights.w;\n\tfinalWorld = finalWorld * (m0 + m1 + m2 + m3);\n\tgl_Position = viewProjection * finalWorld * vec4(position, 1.0);\n#else\n#ifndef VSM\n\tvPosition = viewProjection * finalWorld * vec4(position, 1.0);\n#endif\n\tgl_Position = viewProjection * finalWorld * vec4(position, 1.0);\n#endif\n\n#ifdef ALPHATEST\n#ifdef UV1\n\tvUV = vec2(diffuseMatrix * vec4(uv, 1.0, 0.0));\n#endif\n#ifdef UV2\n\tvUV = vec2(diffuseMatrix * vec4(uv2, 1.0, 0.0));\n#endif\n#endif\n}",
		"spritesPixelShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\nuniform bool alphaTest;\n\nvarying vec4 vColor;\n\n// Samplers\nvarying vec2 vUV;\nuniform sampler2D diffuseSampler;\n\n// Fog\n#ifdef FOG\n\n#define FOGMODE_NONE    0.\n#define FOGMODE_EXP     1.\n#define FOGMODE_EXP2    2.\n#define FOGMODE_LINEAR  3.\n#define E 2.71828\n\nuniform vec4 vFogInfos;\nuniform vec3 vFogColor;\nvarying float fFogDistance;\n\nfloat CalcFogFactor()\n{\n\tfloat fogCoeff = 1.0;\n\tfloat fogStart = vFogInfos.y;\n\tfloat fogEnd = vFogInfos.z;\n\tfloat fogDensity = vFogInfos.w;\n\n\tif (FOGMODE_LINEAR == vFogInfos.x)\n\t{\n\t\tfogCoeff = (fogEnd - fFogDistance) / (fogEnd - fogStart);\n\t}\n\telse if (FOGMODE_EXP == vFogInfos.x)\n\t{\n\t\tfogCoeff = 1.0 / pow(E, fFogDistance * fogDensity);\n\t}\n\telse if (FOGMODE_EXP2 == vFogInfos.x)\n\t{\n\t\tfogCoeff = 1.0 / pow(E, fFogDistance * fFogDistance * fogDensity * fogDensity);\n\t}\n\n\treturn min(1., max(0., fogCoeff));\n}\n#endif\n\n\nvoid main(void) {\n\tvec4 baseColor = texture2D(diffuseSampler, vUV);\n\n\tif (alphaTest) \n\t{\n\t\tif (baseColor.a < 0.95)\n\t\t\tdiscard;\n\t}\n\n\tbaseColor *= vColor;\n\n#ifdef FOG\n\tfloat fog = CalcFogFactor();\n\tbaseColor.rgb = fog * baseColor.rgb + (1.0 - fog) * vFogColor;\n#endif\n\n\tgl_FragColor = baseColor;\n}",
		"spritesVertexShader" => "#ifdef GL_ES\nprecision mediump float;\n#endif\n\n// Attributes\nattribute vec3 position;\nattribute vec4 options;\nattribute vec4 cellInfo;\nattribute vec4 color;\n\n// Uniforms\nuniform vec2 textureInfos;\nuniform mat4 view;\nuniform mat4 projection;\n\n// Output\nvarying vec2 vUV;\nvarying vec4 vColor;\n\n#ifdef FOG\nvarying float fFogDistance;\n#endif\n\nvoid main(void) {\t\n\tvec3 viewPos = (view * vec4(position, 1.0)).xyz; \n\tvec3 cornerPos;\n\t\n\tfloat angle = options.x;\n\tfloat size = options.y;\n\tvec2 offset = options.zw;\n\tvec2 uvScale = textureInfos.xy;\n\n\tcornerPos = vec3(offset.x - 0.5, offset.y  - 0.5, 0.) * size;\n\n\t// Rotate\n\tvec3 rotatedCorner;\n\trotatedCorner.x = cornerPos.x * cos(angle) - cornerPos.y * sin(angle);\n\trotatedCorner.y = cornerPos.x * sin(angle) + cornerPos.y * cos(angle);\n\trotatedCorner.z = 0.;\n\n\t// Position\n\tviewPos += rotatedCorner;\n\tgl_Position = projection * vec4(viewPos, 1.0);   \n\n\t// Color\n\tvColor = color;\n\t\n\t// Texture\n\tvec2 uvOffset = vec2(abs(offset.x - cellInfo.x), 1.0 - abs(offset.y - cellInfo.y));\n\n\tvUV = (uvOffset + cellInfo.zw) * uvScale;\n\n\t// Fog\n#ifdef FOG\n\tfFogDistance = viewPos.z;\n#endif\n}"
	];

    public var name:Dynamic;
    public var _engine:Engine;
    public var defines:String;
    public var _uniforms:Array<GLUniformLocation>;
    public var _uniformsNames:Array<String>;
    public var _samplers:Array<String>;
    public var _isReady:Bool;
    public var _compilationError:String;
    public var _attributes:Array<Int>;
    public var _attributesNames:Array<String>;
    public var _valueCache:Map<String, Array<Float>>; // TODO
    public var _program:GLProgram;
    public var onCompiled:Effect -> Void;
    public var onError:Effect -> String -> Void;


    public function new(baseName:Dynamic, attributesNames:Array<String>, uniformsNames:Array<String>, samplers:Array<String>, engine:Engine, defines:String, optionalDefines:Array<String> = null, ?onCompiled:Effect -> Void, ?onError:Effect -> String -> Void) {
        this._engine = engine;
        this.name = baseName;
        this.defines = defines;
        this._uniformsNames = uniformsNames.concat(samplers);
        this._samplers = samplers;
        this._isReady = false;
        this._compilationError = "";
        this._attributesNames = attributesNames;

        if (onError != null) {
            this.onError = onError;
        }

        if (onCompiled != null) {
            this.onCompiled = onCompiled;
        }


        var vertex:String = Reflect.field(baseName, "vertex") != null ? baseName.vertex : baseName;
        var fragment:String = Reflect.field(baseName, "fragment") != null ? baseName.fragment : baseName;

        var vertexShaderUrl:String = "";
        if (vertex.charAt(0) == ".") {
            vertexShaderUrl = vertex;
        } else {
            vertexShaderUrl = Engine.ShadersRepository + vertex;
        }
        var fragmentShaderUrl:String = "";
        if (fragment.charAt(0) == ".") {
            fragmentShaderUrl = fragment;
        } else {
            fragmentShaderUrl = Engine.ShadersRepository + fragment;
        }

        var _vertexCode:String = "";
        if (Effect.ShadersStore.exists(vertex + "VertexShader")) {
            _vertexCode = Effect.ShadersStore.get(vertex + "VertexShader");
        } else {
            _vertexCode = StringTools.trim(Assets.getText(vertexShaderUrl + ".vertex.txt"));
        }

        var _fragmentCode:String = "";
        if (Effect.ShadersStore.exists(fragment + "PixelShader")) {
            _fragmentCode = Effect.ShadersStore.get(fragment + "PixelShader");
        } else {
            _fragmentCode = StringTools.trim(Assets.getText(fragmentShaderUrl + ".fragment.txt"));
        }
        this._prepareEffect(_vertexCode, _fragmentCode, attributesNames, defines, optionalDefines, false);

        // Cache
        this._valueCache = new Map<String, Array<Float>>();
    }

    public function isReady():Bool {
        return this._isReady;
    }

    public function getAttributeLocationByName(name:String):Int {
        var index = this._attributesNames.indexOf(name);
        return this._attributes[index];
    }

    public function getProgram():GLProgram {
        return this._program;
    }

    public function getAttributesNames():Array<String> {
        return this._attributesNames;
    }

    public function getAttribute(index:Int):Int {
        return this._attributes[index];
    }

    public function getAttributesCount():Int {
        return this._attributes.length;
    }

    public function getUniformIndex(uniformName:String):Int {
        return Lambda.indexOf(this._uniformsNames, uniformName);
    }

    public function getUniform(uniformName:String):GLUniformLocation {
        return this._uniforms[Lambda.indexOf(this._uniformsNames, uniformName)];
    }

    public function getSamplers():Array<String> {
        return this._samplers;
    }

    public function getCompilationError():String {
        return this._compilationError;
    }

    //public function _loadVertexShader(vertex:String, callbackFn:String->Void) {

    public function _loadVertexShader(vertex:String, callbackFn:String -> Void) {
        // Is in local store ?
        if (Effect.ShadersStore.exists(vertex + "VertexShader")) {
            callbackFn(Effect.ShadersStore.get(vertex + "VertexShader"));
            return;
        }

        var vertexShaderUrl:String = "";

        if (vertex.charAt(0) == ".") {
            vertexShaderUrl = vertex;
        } else {
            vertexShaderUrl = Engine.ShadersRepository + vertex;
        }

        // Vertex shader
        Tools.LoadFile(vertexShaderUrl + ".vertex.fx", callbackFn);
    }

    public function _loadFragmentShader(fragment:String, callbackFn:String -> Void) {
        // Is in local store ?
        if (Effect.ShadersStore.exists(fragment + "PixelShader")) {
            callbackFn(Effect.ShadersStore.get(fragment + "PixelShader"));
            return;
        }

        var fragmentShaderUrl:String = "";

        if (fragment.charAt(0) == ".") {
            fragmentShaderUrl = fragment;
        } else {
            fragmentShaderUrl = Engine.ShadersRepository + fragment;
        }

        // Fragment shader
        Tools.LoadFile(fragmentShaderUrl + ".fragment.fx", callbackFn);
    }

    public function _prepareEffect(vertexSourceCode:String, fragmentSourceCode:String, attributesNames:Array<String>, defines:String, optionalDefines:Array<String> = null, useFallback:Bool) {
        try {
            var engine:Engine = this._engine;
            if (Tools.isDebug) {
                trace(defines);
                trace('prepareEffect pre built..');
                trace('vertex ----------');
                trace(vertexSourceCode);
                trace('vertex ----------');
                trace('fragmentSourceCode ----------');
                trace(fragmentSourceCode);
                trace('fragmentSourceCode ----------');
            }
            this._program = engine.createShaderProgram(vertexSourceCode, fragmentSourceCode, defines);
            this._uniforms = engine.getUniforms(this._program, this._uniformsNames);
            this._attributes = engine.getAttributes(this._program, attributesNames);

            var index:Int = 0;
            while (index < this._samplers.length) {
                var sampler = this.getUniform(this._samplers[index]);
                if (Tools.isDebug) {
                	trace('sampler -> ' + sampler);
            	}
                #if html5
				if (sampler == null) {
				#else
                if (sampler < 0) {
                #end
                    this._samplers.splice(index, 1);
                    index--;
                }
                index++;
            }
            engine.bindSamplers(this);
            this._isReady = true;
        } catch (e:Dynamic) {
            trace(e);
            if (!useFallback && optionalDefines != null) {
                for (index in 0...optionalDefines.length) {
                    defines = StringTools.replace(defines, optionalDefines[index], "");
                }
                this._prepareEffect(vertexSourceCode, fragmentSourceCode, attributesNames, defines, optionalDefines, true);
            } else {
                trace("Unable to compile effect: " + this.name);
                trace("Defines: " + defines);
                trace("Optional defines: " + optionalDefines);
                
                this._compilationError = cast e;
            }
        }
    }

    public function _bindTexture(channel:String, texture:BabylonTexture) {
        this._engine._bindTexture(Lambda.indexOf(this._samplers, channel), texture);
    }

    public function setTexture(channel:String, texture:Texture) {
    	//todo investigate
    	//trace(Lambda.indexOf(this._samplers, channel));
    	//trace('setTexture...');
        this._engine.setTexture(Lambda.indexOf(this._samplers, channel), texture);
    }

    public function setTextureFromPostProcess(channel:String, postProcess:PostProcess) {
        this._engine.setTextureFromPostProcess(Lambda.indexOf(this._samplers, channel), postProcess);
    }

    //public function _cacheMatrix = function (uniformName, matrix) {
    //    if (!this._valueCache[uniformName]) {
    //        this._valueCache[uniformName] = new BABYLON.Matrix();
    //    }

    //    for (var index = 0; index < 16; index++) {
    //        this._valueCache[uniformName].m[index] = matrix.m[index];
    //    }
    //};

    inline public function _cacheFloat2(uniformName:String, x:Float, y:Float) {
        if (!this._valueCache.exists(uniformName)) {
            this._valueCache.set(uniformName, [x, y]);
        } else {
            this._valueCache.get(uniformName)[0] = x;
            this._valueCache.get(uniformName)[1] = y;
        }
    }

    inline public function _cacheFloat3(uniformName:String, x:Float, y:Float, z:Float) {
        if (!this._valueCache.exists(uniformName)) {
            this._valueCache.set(uniformName, [x, y, z]);
        } else {
            this._valueCache.get(uniformName)[0] = x;
            this._valueCache.get(uniformName)[1] = y;
            this._valueCache.get(uniformName)[2] = z;
        }
    }

    inline public function _cacheFloat4(uniformName:String, x:Float, y:Float, z:Float, w:Float) {
        if (!this._valueCache.exists(uniformName)) {
            this._valueCache.set(uniformName, [x, y, z, w]);
        } else {
            this._valueCache.get(uniformName)[0] = x;
            this._valueCache.get(uniformName)[1] = y;
            this._valueCache.get(uniformName)[2] = z;
            this._valueCache.get(uniformName)[3] = w;
        }
    }

    inline public function setMatrices(uniformName:String, matrices:#if html5 Float32Array #else Array<Float> #end) {
        this._engine.setMatrices(this.getUniform(uniformName), matrices);
    }

    inline public function setArray(uniformName:String, array:Array<Float>):Effect {
        this._engine.setArray(this.getUniform(uniformName), array);
        return this;
    }

    inline public function setMatrix(uniformName:String, matrix:Matrix) {
        //if (this._valueCache[uniformName] && this._valueCache[uniformName].equals(matrix))
        //    return;

        //this._cacheMatrix(uniformName, matrix);
        //static???
        this._engine.setMatrix(this.getUniform(uniformName), matrix);
    }

    inline public function setFloat(uniformName:String, value:Float) {
        if (!(this._valueCache.exists(uniformName) && this._valueCache.get(uniformName)[0] == value)) {
            this._valueCache.set(uniformName, [value]);
            this._engine.setFloat(this.getUniform(uniformName), value);
        }
    }

    inline public function setBool(uniformName:String, bool:Bool) {
        if (!(this._valueCache.exists(uniformName) && this._valueCache.get(uniformName)[0] == (bool ? 1.0 : 0.0))) {
            this._valueCache.set(uniformName, (bool ? [1.0] : [0.0]));
            this._engine.setBool(this.getUniform(uniformName), bool);
        }
    }

    inline public function setVector2(uniformName:String, vector2:Vector2) {
        if (!(this._valueCache.exists(uniformName) && this._valueCache.get(uniformName)[0] == vector2.x && this._valueCache.get(uniformName)[1] == vector2.y)) {
            this._cacheFloat2(uniformName, vector2.x, vector2.y);
            this._engine.setFloat2(this.getUniform(uniformName), vector2.x, vector2.y);
        }
    }

    inline public function setFloat2(uniformName:String, x:Float, y:Float) {
        if (!(this._valueCache.exists(uniformName) && this._valueCache.get(uniformName)[0] == x && this._valueCache.get(uniformName)[1] == y)) {
            this._cacheFloat2(uniformName, x, y);
            this._engine.setFloat2(this.getUniform(uniformName), x, y);
        }
    }

    inline public function setVector3(uniformName:String, vector3:Vector3) {
        if (!(this._valueCache.exists(uniformName) && this._valueCache.get(uniformName)[0] == vector3.x && this._valueCache.get(uniformName)[1] == vector3.y && this._valueCache.get(uniformName)[2] == vector3.z)) {
            this._cacheFloat3(uniformName, vector3.x, vector3.y, vector3.z);
            this._engine.setFloat3(this.getUniform(uniformName), vector3.x, vector3.y, vector3.z);
        }
    }

    inline public function setFloat3(uniformName:String, x:Float, y:Float, z:Float) {
        if (!(this._valueCache.exists(uniformName) && this._valueCache.get(uniformName)[0] == x && this._valueCache.get(uniformName)[1] == y && this._valueCache.get(uniformName)[2] == z)) {
            this._cacheFloat3(uniformName, x, y, z);
            this._engine.setFloat3(this.getUniform(uniformName), x, y, z);
        }
    }

    inline public function setFloat4(uniformName:String, x:Float, y:Float, z:Float, w:Float) {
        if (!(this._valueCache.exists(uniformName) && this._valueCache.get(uniformName)[0] == x && this._valueCache.get(uniformName)[1] == y && this._valueCache.get(uniformName)[2] == z && this._valueCache.get(uniformName)[3] == w)) {
            this._cacheFloat4(uniformName, x, y, z, w);
            this._engine.setFloat4(this.getUniform(uniformName), x, y, z, w);
        }
    }

    inline public function setColor3(uniformName:String, color3:Color3) {
        if (!(this._valueCache.exists(uniformName) && this._valueCache.get(uniformName)[0] == color3.r && this._valueCache.get(uniformName)[1] == color3.g && this._valueCache.get(uniformName)[2] == color3.b)) {
            this._cacheFloat3(uniformName, color3.r, color3.g, color3.b);
            this._engine.setColor3(this.getUniform(uniformName), color3);
        }
    }

    inline public function setColor4(uniformName:String, color3:Color3, alpha:Float) {
        if (!(this._valueCache.exists(uniformName) && this._valueCache.get(uniformName)[0] == color3.r && this._valueCache.get(uniformName)[1] == color3.g && this._valueCache.get(uniformName)[2] == color3.b && this._valueCache.get(uniformName)[3] == alpha)) {
            this._cacheFloat4(uniformName, color3.r, color3.g, color3.b, alpha);
            this._engine.setColor4(this.getUniform(uniformName), color3, alpha);
        }
    }

}
