package com.gamestudiohx.babylonhx.materials.textures;

import com.gamestudiohx.babylonhx.mesh.SubMesh;
import com.gamestudiohx.babylonhx.rendering.RenderingManager;
import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
import com.gamestudiohx.babylonhx.mesh.Mesh;
import com.gamestudiohx.babylonhx.tools.SmartArray;
import com.gamestudiohx.babylonhx.cameras.Camera;

/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin / Brendon Smith #seacloud9
 */

@:expose('BABYLON.RenderTargetTexture') class RenderTargetTexture extends Texture {

    public var _generateMipMaps:Bool;
    public var _renderingManager:RenderingManager;
    public var renderList:Array<AbstractMesh>;

    public var renderParticles:Bool;
    public var renderSprites:Bool;
    public var isRenderTarget:Bool;
    public var _size:Float = 0;
    private var _currentRefreshId:Int = -1;
    private var refreshRate:Int = 1;
    private var _doNotChangeAspectRatio: Bool;
    public var activeCamera: Camera;

    public var customRenderFunction:Dynamic;

    // Methods  
    public var onBeforeRender:Void -> Void;
    public var onAfterRender:Void -> Void;

    public var _waitingRenderList:Array<String>;

    function get_refreshRate() {
        return refreshRate;
    }

    function set_refreshRate(refreshRate:Int) {
        return this.refreshRate = refreshRate;
    }

    public function scale(ratio:Float):Void {
            var newSize = this._size * ratio;

            this.resize(newSize, this._generateMipMaps);
    }
    public function new(name:String, size:Dynamic, scene:Scene, generateMipMaps:Bool, doNotChangeAspectRatio:Bool = true) {
        

        this._texture = scene.getEngine().createRenderTargetTexture(size, generateMipMaps);
        super(name, scene, !generateMipMaps);
        this.renderParticles = true;
        this.renderSprites = false;
        this._generateMipMaps = generateMipMaps;
        this.isRenderTarget = true;
        this.coordinatesMode = Texture.PROJECTION_MODE;
        this._size = size;
        this._doNotChangeAspectRatio = doNotChangeAspectRatio;

        /*
        this._texture._size = Std.int(this._texture._width);
        this._texture._baseHeight = Std.int(this._texture._width);
        this._texture._baseWidth = Std.int(this._texture._width);
        this._texture._cachedWrapU = Std.int(-this._texture._width);
        this._texture._cachedWrapV = Std.int(-this._texture._width);
        trace(this._texture);
        */

        // Render list
        this.renderList = [];

        // Rendering groups
        //todo throughly investigate??
        //scene.customRenderTargets.push(this);
        this._renderingManager = new RenderingManager(scene);
    }

    public function _shouldRender(): Bool {
            if (this._currentRefreshId == -1) { // At least render once
                this._currentRefreshId = 1;
                return true;
            }

            if (this.refreshRate == this._currentRefreshId) {
                this._currentRefreshId = 1;
                return true;
            }

            this._currentRefreshId++;
            return false;
    }

    public function resize(size:Float, generateMipMaps:Bool) {
        this.releaseInternalTexture();
        this._texture = this._scene.getEngine().createRenderTargetTexture(size, generateMipMaps);
    }

    public function render(useCameraPostProcess:Bool = false) {
        var scene = this._scene;
        var engine = scene.getEngine();

        if (this._waitingRenderList != null) {
            this.renderList = [];
            for (index in 0...this._waitingRenderList.length) {
                var id = this._waitingRenderList[index];
                this.renderList.push(this._scene.getMeshByID(id));
            }

            this._waitingRenderList = null;
        }

        if (this.renderList == null || this.renderList.length == 0) {
            return;
        } 
        
		if (!useCameraPostProcess || !scene.postProcessManager._prepareFrame(this._texture)) {
            engine.bindFramebuffer(this._texture);
        }
        
        //engine.bindFramebuffer(this._texture);

        // Clear
        engine.clear(scene.clearColor, true, true);

        this._renderingManager.reset();

        for (meshIndex in 0...this.renderList.length) {
            var mesh:AbstractMesh = this.renderList[meshIndex];

            if(mesh != null){
                if (!mesh.isReady() || (mesh.material && !mesh.material.isReady())) {
                        // Reset _currentRefreshId
                        this.resetRefreshCounter();
                        continue;
                }
                if (mesh.isEnabled() && mesh.isVisible && mesh.subMeshes != null && ((mesh.layerMask & scene.activeCamera.layerMask) != 0)) {
                    mesh._activate(scene.getRenderId());
                    for (subIndex in 0...mesh.subMeshes.length) {
                        var subMesh:SubMesh = mesh.subMeshes[subIndex];
                        scene._activeVertices += subMesh.verticesCount;
                        this._renderingManager.dispatch(subMesh);
                    }
                }

            }
            
        }

        if (!this._doNotChangeAspectRatio) {
                scene.updateTransformMatrix(true);
        }

        if (this.onBeforeRender != null) {
            this.onBeforeRender();
        }

        // Render
        this._renderingManager.render(this.customRenderFunction, this.renderList, this.renderParticles, this.renderSprites);

        if (useCameraPostProcess) {
            scene.postProcessManager._finalizeFrame(false, this._texture);
        }

        if (this.onAfterRender != null) {
            this.onAfterRender();
        }

        // Unbind
        engine.unBindFramebuffer(this._texture);

        if (!this._doNotChangeAspectRatio) {
            scene.updateTransformMatrix(true);
        }

    }

    public function resetRefreshCounter(): Void {
            this._currentRefreshId = -1;
    }

    override public function clone():Texture {
        var textureSize = this.getSize();
        var newTexture:RenderTargetTexture = new RenderTargetTexture(this.name, textureSize.width, this._scene, this._generateMipMaps);

        // Base texture
        newTexture.hasAlpha = this.hasAlpha;
        newTexture.level = this.level;

        // RenderTarget Texture
        newTexture.coordinatesMode = this.coordinatesMode;
        newTexture.renderList = this.renderList.copy();

        return newTexture;
    }

}
