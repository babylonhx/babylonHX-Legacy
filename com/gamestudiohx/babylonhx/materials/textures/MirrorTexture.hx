package com.gamestudiohx.babylonhx.materials.textures;

import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.Engine;
import com.gamestudiohx.babylonhx.tools.math.Matrix;
import com.gamestudiohx.babylonhx.tools.math.Plane;
import com.gamestudiohx.babylonhx.cameras.Camera;

/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin / Brendon Smith #seacloud9
 */

@:expose('BABYLON.MirrorTexture') class MirrorTexture extends RenderTargetTexture {

    public var _transformMatrix:Matrix = Matrix.Zero();
    public var _savedViewMatrix:Matrix;
    public var _mirrorMatrix:Matrix = Matrix.Zero();
    public var mirrorPlane:Plane = new Plane(0, 1, 0, 1);

    public function new(name:String, size:Dynamic, scene:Scene, generateMipMaps:Bool) {
        super(name, size, scene, generateMipMaps, true);
        //this._scene.clipPlane = this.mirrorPlane;
        this._scene.customRenderTargets.push(this);
        this.onBeforeRender = function() {
            var scene:Scene = this._scene;
           
            Matrix.ReflectionToRef(this.mirrorPlane, this._mirrorMatrix);
            this._savedViewMatrix = scene.getViewMatrix();

            this._mirrorMatrix.multiplyToRef(this._savedViewMatrix, this._transformMatrix);
            scene.setTransformMatrix(this._transformMatrix, scene.getProjectionMatrix());
            this._scene.clipPlane = this.mirrorPlane;
            //trace('before ' + this._scene.clipPlane);
            scene.getEngine().cullBackFaces = false;
        }

        this.onAfterRender = function() {
            var scene = this._scene;
            //trace('after');
            scene.setTransformMatrix(this._savedViewMatrix, scene.getProjectionMatrix());
            scene.getEngine().cullBackFaces = true;
            this._scene.clipPlane = null;
        }
    }

    override public function clone():Texture {
        var textureSize = this.getSize();
        var newTexture:MirrorTexture = new MirrorTexture(this.name, textureSize.width, this._scene, this._generateMipMaps);
        // Base texture
        newTexture.hasAlpha = this.hasAlpha;
        newTexture.level = this.level;
        // Mirror Texture
        newTexture.mirrorPlane = this.mirrorPlane.clone();
        newTexture.renderList = this.renderList.slice(0);
        return newTexture;
    }

}
