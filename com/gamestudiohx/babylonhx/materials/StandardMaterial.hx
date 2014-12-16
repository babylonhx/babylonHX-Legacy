package com.gamestudiohx.babylonhx.materials;

import com.gamestudiohx.babylonhx.lights.Light;
import com.gamestudiohx.babylonhx.lights.PointLight;
import com.gamestudiohx.babylonhx.lights.HemisphericLight;
import com.gamestudiohx.babylonhx.lights.DirectionalLight;
import com.gamestudiohx.babylonhx.lights.SpotLight;
import com.gamestudiohx.babylonhx.mesh.Mesh;
import com.gamestudiohx.babylonhx.mesh.VertexBuffer;
import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.Engine;
import com.gamestudiohx.babylonhx.tools.math.Color3;
import com.gamestudiohx.babylonhx.tools.math.Matrix;
import com.gamestudiohx.babylonhx.tools.SmartArray;
import com.gamestudiohx.babylonhx.tools.Tools;
import com.gamestudiohx.babylonhx.materials.textures.Texture;
import com.gamestudiohx.babylonhx.materials.textures.CubeTexture;


/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin / Brendon Smith #seacloud9
 */

@:expose('BABYLON.FresnelParameters') class FresnelParameters {
        public var isEnabled:Bool = true;
        public var leftColor:Color3 = new Color3(1,1,1);
        public var rightColor:Color3 = new Color3();
        public var bias:Float = 0;
        public var power:Int = 1;
}

@:expose('BABYLON.StandardMaterial') class StandardMaterial extends Material {

    public var diffuseTexture:Texture = null;
    public var ambientTexture:Texture = null;
    public var opacityTexture:Texture = null;
    public var reflectionTexture:Texture = null;
    public var emissiveTexture:Texture = null;
    public var specularTexture:Texture = null;
    public var bumpTexture:Texture = null;

    public var ambientColor:Color3;
    public var diffuseColor:Color3;
    public var specularColor:Color3;
    public var specularPower:Float;
    public var emissiveColor:Color3;
    public var useAlphaFromDiffuseTexture:Bool = false;

    public var _cachedDefines:String;

    public var _renderTargets:SmartArray;

    // Internals
    public var _worldViewProjectionMatrix:Matrix;
    public var _lightMatrix:Matrix;
    public var _globalAmbientColor:Color3;
    public var _baseColor:Color3;
    public var _scaledDiffuse:Color3;
    public var _scaledSpecular:Color3;


    public static var DiffuseTextureEnabled = true;
    public static var AmbientTextureEnabled = true;
    public static var OpacityTextureEnabled = true;
    public static var ReflectionTextureEnabled = true;
    public static var EmissiveTextureEnabled = true;
    public static var SpecularTextureEnabled = true;
    public static var BumpTextureEnabled = true;
    public var diffuseFresnelParameters: FresnelParameters;
    public var opacityFresnelParameters: FresnelParameters;
    public var reflectionFresnelParameters: FresnelParameters;
    public var emissiveFresnelParameters: FresnelParameters;



    public function new(name:String, scene:Scene) {
        super(name, scene);

        this.diffuseFresnelParameters = null;
        this.opacityFresnelParameters = null;
        this.reflectionFresnelParameters = null;
        this.emissiveFresnelParameters = null;
        this.ambientColor = new Color3(0, 0, 0);
        this.diffuseColor = new Color3(1, 1, 1);
        this.specularColor = new Color3(1, 1, 1);
        this.specularPower = 64;
        this.emissiveColor = new Color3(0, 0, 0);

        this._cachedDefines = null;

        this._renderTargets = new SmartArray();

        // Internals
        this._worldViewProjectionMatrix = Matrix.Zero();
        this._lightMatrix = Matrix.Zero();
        this._globalAmbientColor = new Color3(0, 0, 0);
        this._baseColor = new Color3();
        this._scaledDiffuse = new Color3();
        this._scaledSpecular = new Color3();
    }

    override public function needAlphaBlending():Bool {
        return (this.alpha < 1.0) || (this.opacityTexture != null) || this._shouldUseAlphaFromDiffuseTexture() || this.opacityFresnelParameters != null  && this.opacityFresnelParameters.isEnabled;
    }

    override public function needAlphaTesting():Bool {
        return this.diffuseTexture != null && this.diffuseTexture.hasAlpha;
    }

    public function _shouldUseAlphaFromDiffuseTexture(): Bool {
            return this.diffuseTexture != null && this.diffuseTexture.hasAlpha && this.useAlphaFromDiffuseTexture;
    }

    override public function isReady(mesh:Mesh = null, useInstances:Bool = false):Bool {
        if (this.checkReadyOnlyOnce) {
            if (this._wasPreviouslyReady) {
                return true;
            }
        }

        if (!this.checkReadyOnEveryCall) {
            if (this._renderId == this._scene.getRenderId()) {
                return true;
            }
        }

        var engine:Engine = this._scene.getEngine();
        var defines:Array<String> = [];
        var optionalDefines:Array<String> = [];

        // Textures
        if (this._scene.texturesEnabled) {
            if (this.diffuseTexture != null) {
                if (!this.diffuseTexture.isReady() && StandardMaterial.DiffuseTextureEnabled) {
                    return false;
                } else {
                    defines.push("#define DIFFUSE");
                }
            }

            if (this.ambientTexture != null) {
                if (!this.ambientTexture.isReady() && StandardMaterial.AmbientTextureEnabled) {
                    return false;
                } else {
                    defines.push("#define AMBIENT");
                }
            }

            if (this.opacityTexture != null) {
                if (!this.opacityTexture.isReady() && StandardMaterial.OpacityTextureEnabled) {
                    return false;
                } else {
                    defines.push("#define OPACITY");
                }
            }
            if (this.reflectionTexture != null) {
                if (!this.reflectionTexture.isReady() && StandardMaterial.ReflectionTextureEnabled) {
                    return false;
                } else {
                    defines.push("#define REFLECTION");
                }
            }

            if (this.emissiveTexture != null) {
                if (!this.emissiveTexture.isReady() && StandardMaterial.EmissiveTextureEnabled) {
                    return false;
                } else {
                    defines.push("#define EMISSIVE");
                }
            }

            if (this.specularTexture != null) {
                if (!this.specularTexture.isReady() && StandardMaterial.SpecularTextureEnabled) {
                    return false;
                } else {
                    defines.push("#define SPECULAR");
                    optionalDefines.push(defines[defines.length - 1]);
                }
            }
        }

        if (this._scene.getEngine().getCaps().standardDerivatives != null && this.bumpTexture != null && StandardMaterial.BumpTextureEnabled) {
            if (!this.bumpTexture.isReady()) {
                return false;
            } else {
                defines.push("#define BUMP");
                optionalDefines.push(defines[defines.length - 1]);
            }
        }

        // Effect
        if (Engine.clipPlane != null) {
            defines.push("#define CLIPPLANE");
        }

        if (engine.getAlphaTesting()) {
            defines.push("#define ALPHATEST");
        }

        if (this._shouldUseAlphaFromDiffuseTexture()) {
                defines.push("#define ALPHAFROMDIFFUSE");
        }

        // Fog
        if (this._scene.fogMode != Scene.FOGMODE_NONE) {
            defines.push("#define FOG");
            optionalDefines.push(defines[defines.length - 1]);
        }

        var shadowsActivated:Bool = false;
        var lightIndex:Int = 0;
        if (this._scene.lightsEnabled) {
            for (index in 0...this._scene.lights.length) {
                var light = this._scene.lights[index];

                if (!light.isEnabled()) {
                    continue;
                }
                


                if (mesh != null && Lambda.indexOf(light.excludedMeshes, mesh) != -1) {
                    continue;
                }

                defines.push("#define LIGHT" + lightIndex);
                

                if (lightIndex > 0) {
                    optionalDefines.push(defines[defines.length - 1]);
                }

                var type:String = "";
                if (Std.is(light, SpotLight)) {
                    type = "#define SPOTLIGHT" + lightIndex;
                } else if (Std.is(light, HemisphericLight)) {
                    type = "#define HEMILIGHT" + lightIndex;
                } else {
                    type = "#define POINTDIRLIGHT" + lightIndex;
                }


                defines.push(type);
                if (lightIndex > 0) {
                    optionalDefines.push(defines[defines.length - 1]);
                }

                // Shadows
                var shadowGenerator = light.getShadowGenerator();
                if (mesh != null && mesh.receiveShadows && shadowGenerator != null) {
                    defines.push("#define SHADOW" + lightIndex);

                    if (lightIndex > 0) {
                        optionalDefines.push(defines[defines.length - 1]);
                    }

                    if (!shadowsActivated) {
                        defines.push("#define SHADOWS");
                        shadowsActivated = true;
                    }

                    if (shadowGenerator.useVarianceShadowMap) {
                        defines.push("#define SHADOWVSM" + lightIndex);
                        if (lightIndex > 0) {
                            optionalDefines.push(defines[defines.length - 1]);
                        }
                    }

                    /*
                    if (shadowGenerator.usePoissonSampling) {
                            defines.push("#define SHADOWPCF" + lightIndex);
                            if (lightIndex > 0) {
                                optionalDefines.push(defines[defines.length - 1]);
                            }
                    }
                    */

                }

                lightIndex++;
                // 4
                if (lightIndex == 6)
                    break;
            }
        }
        //trace(lightIndex);
        //trace(defines);

        // Fresnel
        if (this.diffuseFresnelParameters != null && this.diffuseFresnelParameters.isEnabled ||
                this.opacityFresnelParameters != null && this.opacityFresnelParameters.isEnabled ||
                this.emissiveFresnelParameters != null && this.emissiveFresnelParameters.isEnabled ||
                this.reflectionFresnelParameters != null && this.reflectionFresnelParameters.isEnabled) {

                var fresnelRank = 1;

                if (this.diffuseFresnelParameters != null && this.diffuseFresnelParameters.isEnabled) {
                    defines.push("#define DIFFUSEFRESNEL");
                    //fallbacks.addFallback(fresnelRank, "DIFFUSEFRESNEL");
                    fresnelRank++;
                }

                if (this.opacityFresnelParameters != null && this.opacityFresnelParameters.isEnabled) {
                    defines.push("#define OPACITYFRESNEL");
                    //fallbacks.addFallback(fresnelRank, "OPACITYFRESNEL");
                    fresnelRank++;
                }

                if (this.reflectionFresnelParameters != null && this.reflectionFresnelParameters.isEnabled) {
                    defines.push("#define REFLECTIONFRESNEL");
                    //fallbacks.addFallback(fresnelRank, "REFLECTIONFRESNEL");
                    fresnelRank++;
                }

                if (this.emissiveFresnelParameters != null && this.emissiveFresnelParameters.isEnabled) {
                    defines.push("#define EMISSIVEFRESNEL");
                    //fallbacks.addFallback(fresnelRank, "EMISSIVEFRESNEL");
                    fresnelRank++;
                }

                defines.push("#define FRESNEL");
                //fallbacks.addFallback(fresnelRank - 1, "FRESNEL");
        }

        var attribs:Array<String> = [VertexBuffer.PositionKind, VertexBuffer.NormalKind];
        if (mesh != null) {
            if (mesh.isVerticesDataPresent(VertexBuffer.UVKind)) {
                attribs.push(VertexBuffer.UVKind);
                defines.push("#define UV1");
            }
            if (mesh.isVerticesDataPresent(VertexBuffer.UV2Kind)) {
                attribs.push(VertexBuffer.UV2Kind);
                defines.push("#define UV2");
            }
            if (mesh.isVerticesDataPresent(VertexBuffer.ColorKind)) {
                attribs.push(VertexBuffer.ColorKind);
                defines.push("#define VERTEXCOLOR");
            }
            if (mesh.skeleton != null && mesh.isVerticesDataPresent(VertexBuffer.MatricesIndicesKind) && mesh.isVerticesDataPresent(VertexBuffer.MatricesWeightsKind)) {
                attribs.push(VertexBuffer.MatricesIndicesKind);
                attribs.push(VertexBuffer.MatricesWeightsKind);
                defines.push("#define BONES");
                defines.push("#define BonesPerMesh " + mesh.skeleton.bones.length + 1);
                defines.push("#define BONES4");
                optionalDefines.push(defines[defines.length - 1]);
            }

            // todo
            if(useInstances){
                    defines.push("#define INSTANCES");
                    attribs.push("world0");
                    attribs.push("world1");
                    attribs.push("world2");
                    attribs.push("world3");
            }
        }

        // Get correct effect      
        var join:String = defines.join("\n");
        if (this._cachedDefines != join) {
            this._cachedDefines = join;

            // Legacy browser patch
            var shaderName:String = "default";
            if (!this._scene.getEngine().getCaps().standardDerivatives) {
                    shaderName = "legacydefault";
            }

            this._effect = this._scene.getEngine().createEffect(shaderName, attribs, 
            ["world", "view", "viewProjection", "vEyePosition", "vLightsType", "vAmbientColor", "vDiffuseColor", "vSpecularColor", "vEmissiveColor",
                        "vLightData0", "vLightDiffuse0", "vLightSpecular0", "vLightDirection0", "vLightGround0", "lightMatrix0",
                        "vLightData1", "vLightDiffuse1", "vLightSpecular1", "vLightDirection1", "vLightGround1", "lightMatrix1",
                        "vLightData2", "vLightDiffuse2", "vLightSpecular2", "vLightDirection2", "vLightGround2", "lightMatrix2",
                        "vLightData3", "vLightDiffuse3", "vLightSpecular3", "vLightDirection3", "vLightGround3", "lightMatrix3",
                        "vFogInfos", "vFogColor", "pointSize",
                        "vDiffuseInfos", "vAmbientInfos", "vOpacityInfos", "vReflectionInfos", "vEmissiveInfos", "vSpecularInfos", "vBumpInfos",
                        "mBones",
                        "vClipPlane", "diffuseMatrix", "ambientMatrix", "opacityMatrix", "reflectionMatrix", "emissiveMatrix", "specularMatrix", "bumpMatrix",
                        "darkness0", "darkness1", "darkness2", "darkness3",
                        "diffuseLeftColor", "diffuseRightColor", "opacityParts", "reflectionLeftColor", "reflectionRightColor", "emissiveLeftColor", "emissiveRightColor"
            ],
            ["diffuseSampler", "ambientSampler", "opacitySampler", "reflectionCubeSampler", "reflection2DSampler", "emissiveSampler", "specularSampler", "bumpSampler",
                        "shadowSampler0", "shadowSampler1", "shadowSampler2", "shadowSampler3"
            ],
             join, optionalDefines);
        }
        if (!this._effect.isReady()) {
            return false;
        }

        this._renderId = this._scene.getRenderId();
        this._wasPreviouslyReady = true;
        return true;
    }

    public function getRenderTargetTextures():SmartArray {
        this._renderTargets.reset();

        if (this.reflectionTexture != null && Reflect.field(this.reflectionTexture, "isRenderTarget") != null) {
            this._renderTargets.push(this.reflectionTexture);
        }

        return this._renderTargets;
    }

    override public function unbind() {
        if (this.reflectionTexture != null && Reflect.field(this.reflectionTexture, "isRenderTarget") != null) {
            this._effect.setTexture("reflection2DSampler", null);
        }
    }

    inline override public function bind(world:Matrix, ?mesh:Mesh) {
        this._baseColor.copyFrom(this.diffuseColor);

        // Matrices        
        this._effect.setMatrix("world", world);
        this._effect.setMatrix("viewProjection", this._scene.getTransformMatrix());

        // Bones
        if (mesh.skeleton != null && mesh.isVerticesDataPresent(VertexBuffer.MatricesIndicesKind) && mesh.isVerticesDataPresent(VertexBuffer.MatricesWeightsKind)) {
            this._effect.setMatrices("mBones", mesh.skeleton.getTransformMatrices());
        }

        // Fresnel
        if (this.diffuseFresnelParameters != null && this.diffuseFresnelParameters.isEnabled) {
            this._effect.setColor4("diffuseLeftColor", this.diffuseFresnelParameters.leftColor, this.diffuseFresnelParameters.power);
            this._effect.setColor4("diffuseRightColor", this.diffuseFresnelParameters.rightColor, this.diffuseFresnelParameters.bias);
        }

        if (this.opacityFresnelParameters != null && this.opacityFresnelParameters.isEnabled) {
            this._effect.setColor4("opacityParts", new Color3(this.opacityFresnelParameters.leftColor.toLuminance(), this.opacityFresnelParameters.rightColor.toLuminance(), this.opacityFresnelParameters.bias), this.opacityFresnelParameters.power);
        }

        if (this.reflectionFresnelParameters != null && this.reflectionFresnelParameters.isEnabled) {
            this._effect.setColor4("reflectionLeftColor", this.reflectionFresnelParameters.leftColor, this.reflectionFresnelParameters.power);
            this._effect.setColor4("reflectionRightColor", this.reflectionFresnelParameters.rightColor, this.reflectionFresnelParameters.bias);
        }

        if (this.emissiveFresnelParameters != null && this.emissiveFresnelParameters.isEnabled) {
                this._effect.setColor4("emissiveLeftColor", this.emissiveFresnelParameters.leftColor, this.emissiveFresnelParameters.power);
                this._effect.setColor4("emissiveRightColor", this.emissiveFresnelParameters.rightColor, this.emissiveFresnelParameters.bias);
        }

        // Textures        
        if (this.diffuseTexture != null) {
            this._effect.setTexture("diffuseSampler", this.diffuseTexture);
            this._effect.setFloat2("vDiffuseInfos", this.diffuseTexture.coordinatesIndex, this.diffuseTexture.level);
            this._effect.setMatrix("diffuseMatrix", this.diffuseTexture._computeTextureMatrix());

            this._baseColor.copyFromFloats(1, 1, 1);
        }

        if (this.ambientTexture != null) {
            this._effect.setTexture("ambientSampler", this.ambientTexture);

            this._effect.setFloat2("vAmbientInfos", this.ambientTexture.coordinatesIndex, this.ambientTexture.level);
            this._effect.setMatrix("ambientMatrix", this.ambientTexture._computeTextureMatrix());
        }

        if (this.opacityTexture != null) {
            this._effect.setTexture("opacitySampler", this.opacityTexture);

            this._effect.setFloat2("vOpacityInfos", this.opacityTexture.coordinatesIndex, this.opacityTexture.level);
            this._effect.setMatrix("opacityMatrix", this.opacityTexture._computeTextureMatrix());
        }

        if (this.reflectionTexture != null) {
            if (Std.is(this.reflectionTexture, CubeTexture)) {
                this._effect.setTexture("reflectionCubeSampler", this.reflectionTexture);
            } else {
                this._effect.setTexture("reflection2DSampler", this.reflectionTexture);
            }

            this._effect.setMatrix("reflectionMatrix", this.reflectionTexture._computeReflectionTextureMatrix());
            this._effect.setFloat3("vReflectionInfos", this.reflectionTexture.coordinatesMode, this.reflectionTexture.level, Reflect.field(this.reflectionTexture, "isCube") != null ? 1.0 : 0.0);
        }

        if (this.emissiveTexture != null) {

            this._effect.setTexture("emissiveSampler", this.emissiveTexture);

            this._effect.setFloat2("vEmissiveInfos", this.emissiveTexture.coordinatesIndex, this.emissiveTexture.level);
            this._effect.setMatrix("emissiveMatrix", this.emissiveTexture._computeTextureMatrix());
        }

        if (this.specularTexture != null) {
            this._effect.setTexture("specularSampler", this.specularTexture);

            this._effect.setFloat2("vSpecularInfos", this.specularTexture.coordinatesIndex, this.specularTexture.level);
            this._effect.setMatrix("specularMatrix", this.specularTexture._computeTextureMatrix());
        }

        if (this.bumpTexture != null && this._scene.getEngine().getCaps().standardDerivatives != null) {
            this._effect.setTexture("bumpSampler", this.bumpTexture);
            this._effect.setFloat2("vBumpInfos", this.bumpTexture.coordinatesIndex, this.bumpTexture.level);
            //bump matrix does not work for native!!!
            // 
            this._effect.setMatrix("bumpMatrix", this.bumpTexture._computeTextureMatrix());
        }

        // Colors
        this._scene.ambientColor.multiplyToRef(this.ambientColor, this._globalAmbientColor);

        this._effect.setVector3("vEyePosition", this._scene.activeCamera.position);
        this._effect.setColor3("vAmbientColor", this._globalAmbientColor);
        this._effect.setColor4("vDiffuseColor", this._baseColor, this.alpha * mesh.visibility);
        this._effect.setColor4("vSpecularColor", this.specularColor, this.specularPower);
        this._effect.setColor3("vEmissiveColor", this.emissiveColor);


        if (this._scene.lightsEnabled) {
            var lightIndex:Int = 0;
            for (index in 0...this._scene.lights.length) {
                var light = this._scene.lights[index];

                if (!light.isEnabled()) {
                    continue;
                }

                if (mesh != null && Lambda.indexOf(light.excludedMeshes, mesh) != -1) {
                    continue;
                }

                if (Std.is(light, PointLight)) {
                    // Point Light
                    light.transferToEffect(this._effect, "vLightData" + lightIndex);
                } else if (Std.is(light, DirectionalLight)) {
                    // Directional Light
                    light.transferToEffect(this._effect, "", "vLightData" + lightIndex);
                } else if (Std.is(light, SpotLight)) {
                    // Spot Light
                    light.transferToEffect(this._effect, "vLightData" + lightIndex, "vLightDirection" + lightIndex);
                } else if (Std.is(light, HemisphericLight)) {
                    // Hemispheric Light
                    light.transferToEffect(this._effect, "vLightData" + lightIndex, "vLightGround" + lightIndex);
                }

                light.diffuse.scaleToRef(light.intensity, this._scaledDiffuse);
                light.specular.scaleToRef(light.intensity, this._scaledSpecular);
                //todo investigate
                this._effect.setColor4("vLightDiffuse" + lightIndex, this._scaledDiffuse, Math.POSITIVE_INFINITY);
                this._effect.setColor3("vLightSpecular" + lightIndex, this._scaledSpecular);

                // Shadows
                var shadowGenerator = light.getShadowGenerator();
                if (mesh.receiveShadows && shadowGenerator != null) {
                    world.multiplyToRef(shadowGenerator.getTransformMatrix(), this._lightMatrix);
                    this._effect.setMatrix("lightMatrix" + lightIndex, shadowGenerator.getTransformMatrix());
                    this._effect.setTexture("shadowSampler" + lightIndex, shadowGenerator.getShadowMap());
                    this._effect.setFloat("darkness" + lightIndex, shadowGenerator.getDarkness());
                }

                lightIndex++;
                //4?
                if (lightIndex == 6)
                    break;
            }
        }

        if (Engine.clipPlane != null) {
            this._effect.setFloat4("vClipPlane", Engine.clipPlane.normal.x, Engine.clipPlane.normal.y, Engine.clipPlane.normal.z, Engine.clipPlane.d);
        }

        // View
        if (this._scene.fogMode != Scene.FOGMODE_NONE || this.reflectionTexture != null) {
            this._effect.setMatrix("view", this._scene.getViewMatrix());
        }

        // Fog
        if (this._scene.fogMode != Scene.FOGMODE_NONE) {
            this._effect.setFloat4("vFogInfos", this._scene.fogMode, this._scene.fogStart, this._scene.fogEnd, this._scene.fogDensity);
            this._effect.setColor3("vFogColor", this._scene.fogColor);
        }
    }

    public function getAnimatables():Array<Texture> {
        var results:Array<Texture> = [];

        if (this.diffuseTexture != null && this.diffuseTexture.animations != null && this.diffuseTexture.animations.length > 0) {
            results.push(this.diffuseTexture);
        }

        if (this.ambientTexture != null && this.ambientTexture.animations != null && this.ambientTexture.animations.length > 0) {
            results.push(this.ambientTexture);
        }

        if (this.opacityTexture != null && this.opacityTexture.animations != null && this.opacityTexture.animations.length > 0) {
            results.push(this.opacityTexture);
        }

        if (this.reflectionTexture != null && this.reflectionTexture.animations != null && this.reflectionTexture.animations.length > 0) {
            results.push(this.reflectionTexture);
        }

        if (this.emissiveTexture != null && this.emissiveTexture.animations != null && this.emissiveTexture.animations.length > 0) {
            results.push(this.emissiveTexture);
        }

        if (this.specularTexture != null && this.specularTexture.animations != null && this.specularTexture.animations.length > 0) {
            results.push(this.specularTexture);
        }

        if (this.bumpTexture != null && this.bumpTexture.animations != null && this.bumpTexture.animations.length > 0) {
            results.push(this.bumpTexture);
        }

        return results;
    }

    override public function dispose() {
        if (this.diffuseTexture != null) {
            this.diffuseTexture.dispose();
        }

        if (this.ambientTexture != null) {
            this.ambientTexture.dispose();
        }

        if (this.opacityTexture != null) {
            this.opacityTexture.dispose();
        }

        if (this.reflectionTexture != null) {
            this.reflectionTexture.dispose();
        }

        if (this.emissiveTexture != null) {
            this.emissiveTexture.dispose();
        }

        if (this.specularTexture != null) {
            this.specularTexture.dispose();
        }

        if (this.bumpTexture != null) {
            this.bumpTexture.dispose();
        }

        this.baseDispose();
    }

    public function clone(name:String):StandardMaterial {
        var newStandardMaterial:StandardMaterial = new StandardMaterial(name, this._scene);

        // Base material
        newStandardMaterial.checkReadyOnEveryCall = this.checkReadyOnEveryCall;
        newStandardMaterial.alpha = this.alpha;
        newStandardMaterial.wireframe = this.wireframe;
        newStandardMaterial.backFaceCulling = this.backFaceCulling;

        // Standard material
        if (this.diffuseTexture != null) {
            newStandardMaterial.diffuseTexture = this.diffuseTexture.clone();
        }
        if (this.ambientTexture != null) {
            newStandardMaterial.ambientTexture = this.ambientTexture.clone();
        }
        if (this.opacityTexture != null) {
            newStandardMaterial.opacityTexture = this.opacityTexture.clone();
        }
        if (this.reflectionTexture != null) {
            newStandardMaterial.reflectionTexture = this.reflectionTexture.clone();
        }
        if (this.emissiveTexture != null) {
            newStandardMaterial.emissiveTexture = this.emissiveTexture.clone();
        }
        if (this.specularTexture != null) {
            newStandardMaterial.specularTexture = this.specularTexture.clone();
        }
        if (this.bumpTexture != null) {
            newStandardMaterial.bumpTexture = this.bumpTexture.clone();
        }

        newStandardMaterial.ambientColor = this.ambientColor.clone();
        newStandardMaterial.diffuseColor = this.diffuseColor.clone();
        newStandardMaterial.specularColor = this.specularColor.clone();
        newStandardMaterial.specularPower = this.specularPower;
        newStandardMaterial.emissiveColor = this.emissiveColor.clone();

        return newStandardMaterial;
    }

}