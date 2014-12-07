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
import com.gamestudiohx.babylonhx.tools.math.Color4;
import com.gamestudiohx.babylonhx.tools.math.Vector2;
import com.gamestudiohx.babylonhx.tools.math.Vector3;
import com.gamestudiohx.babylonhx.tools.math.Matrix;
import com.gamestudiohx.babylonhx.tools.SmartArray;
import com.gamestudiohx.babylonhx.tools.Tools;
import com.gamestudiohx.babylonhx.materials.textures.Texture;
import com.gamestudiohx.babylonhx.materials.textures.CubeTexture;

/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Brendon Smith
 */

class ShaderMaterial extends Material {

    private var _shaderPath:Dynamic;
    private var _options:Dynamic;
    private var _textures:Map<String, Texture>;
    private var _floats:Map<String, Float>;
    private var _floatsArrays:Map<String, Dynamic>;
    private var _colors3:Map<String, Color3>;
    private var _colors4:Map<String, Color4>;
    private var _vectors2:Map<String, Vector2>;
    private var _vectors3:Map<String, Vector3>;
    private var _matrices:Map<String, Matrix>;
    private var _cachedWorldViewMatrix:Matrix;

    public function new(name:String, scene:Scene, shaderPath:Dynamic, options:Dynamic) {
        super(name, scene);
        this._shaderPath = shaderPath;
        if (options.needAlphaBlending == null) {
            options.needAlphaBlending = false;
        }
        if (options.needAlphaTesting == null) {
            options.needAlphaTesting = false;
        }
        if (options.attributes == null) {
            options.attributes = ["position", "normal", "uv"];
        }
        if (options.uniforms == null) {
            options.uniforms = ["worldViewProjection"];
        }
        if (options.samplers == null) {
            options.samplers = new Array<String>();
        }

        this._textures = new Map<String, Texture>();
        this._floats = new Map<String, Float>();
        this._colors3 = new Map<String, Color3>();
        this._colors4 = new Map<String, Color4>();
        this._vectors2 = new Map<String, Vector2>();
        this._vectors3 = new Map<String, Vector3>();
        this._matrices = new Map<String, Matrix>();
        this._floatsArrays = new Map<String, Dynamic>();
        this._cachedWorldViewMatrix = new Matrix();

        this._options = options;
    }


    override public function needAlphaBlending():Bool {
        return this._options.needAlphaBlending;
    }

    override public function needAlphaTesting():Bool {
        return this._options.needAlphaTesting;
    }

    private function _checkUniform(uniformName):Void {
        if (Lambda.indexOf(this._options.uniforms, uniformName) == -1) {
            this._options.uniforms.push(uniformName);
        }
    }

    public function setTexture(name:String, texture:Texture):ShaderMaterial {
        if (Lambda.indexOf(this._options.samplers, name) == -1) {
            this._options.samplers.push(name);
        }
        this._textures.set(name, texture);

        return this;
    }

    public function setFloat(name:String, value:Float):ShaderMaterial {
        this._checkUniform(name);
        this._floats.set(name, value);

        return this;
    }

    public function setFloats(name:String, value:Array<Float>):ShaderMaterial {
        this._checkUniform(name);
        this._floatsArrays.set(name, value);

        return this;
    }

    public function setColor3(name:String, value:Color3):ShaderMaterial {
        this._checkUniform(name);
        this._colors3.set(name, value);

        return this;
    }

    public function setColor4(name:String, value:Color4):ShaderMaterial {
        this._checkUniform(name);
        this._colors4.set(name, value);

        return this;
    }

    public function setVector2(name:String, value:Vector2):ShaderMaterial {
        this._checkUniform(name);
        this._vectors2.set(name, value);

        return this;
    }

    public function setVector3(name:String, value:Vector3):ShaderMaterial {
        this._checkUniform(name);
        this._vectors3.set(name, value);

        return this;
    }

    public function setMatrix(name:String, value:Matrix):ShaderMaterial {
        this._checkUniform(name);
        this._matrices.set(name, value);

        return this;
    }

    override public function isReady(mesh:Mesh = null, useInstances:Bool = false):Bool {
        var engine:Engine = this._scene.getEngine();
        this._effect = engine.createEffect(this._shaderPath, this._options.attributes, this._options.uniforms, this._options.samplers, "", null);
        if (!this._effect.isReady()) {
            return false;
        }

        return true;
    }

    inline override public function bind(world:Matrix, ?mesh:Mesh) {
        // Std values
        // look at shader material most likely a dynamic issue use lambda!!
        if (Lambda.indexOf(this._options.uniforms, "world") != -1) {
            this._effect.setMatrix("world", world);
        }

        if (Lambda.indexOf(this._options.uniforms, "view") != -1) {
            this._effect.setMatrix("view", this._scene.getViewMatrix());
        }

        if (Lambda.indexOf(this._options.uniforms, "worldView") != -1) {
            world.multiplyToRef(this._scene.getViewMatrix(), this._cachedWorldViewMatrix);
            this._effect.setMatrix("worldView", this._cachedWorldViewMatrix);
        }

        if (Lambda.indexOf(this._options.uniforms, "projection") != -1) {
            this._effect.setMatrix("projection", this._scene.getProjectionMatrix());
        }

        if (Lambda.indexOf(this._options.uniforms, "worldViewProjection") != -1) {
            this._effect.setMatrix("worldViewProjection", world.multiply(this._scene.getTransformMatrix()));
        }

        // Texture
        for (name in this._textures.keys()) {
            this._effect.setTexture(name, this._textures[name]);
        }

        // Float
        for (name in this._floats.keys()) {
            this._effect.setFloat(name, this._floats[name]);
        }

        // Float s
        for (name in this._floatsArrays.keys()) {
            this._effect.setArray(name, this._floatsArrays[name]);
        }

        // Color3
        for (name in this._colors3.keys()) {
            this._effect.setColor3(name, this._colors3[name]);
        }

        // Color4
        for (name in this._colors4.keys()) {
            var color = this._colors4[name];
            this._effect.setFloat4(name, color.r, color.g, color.b, color.a);
        }

        // Vector2
        for (name in this._vectors2.keys()) {
            this._effect.setVector2(name, this._vectors2[name]);
        }

        // Vector3
        for (name in this._vectors3.keys()) {
            this._effect.setVector3(name, this._vectors3[name]);
        }

        // Matrix
        for (name in this._matrices.keys()) {
            this._effect.setMatrix(name, this._matrices[name]);
        }
    }

    inline override public function dispose() {
        for (name in this._textures.keys()) {
            this._textures[name].dispose();
        }

        this._textures = new Map<String, Texture>();
        //super.dispose(forceDisposeEffect);
        this.baseDispose();
    }

}