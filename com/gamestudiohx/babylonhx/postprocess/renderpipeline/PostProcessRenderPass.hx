package com.gamestudiohx.babylonhx.postprocess.renderpipeline;

import com.gamestudiohx.babylonhx.cameras.Camera;
import com.gamestudiohx.babylonhx.postprocess.PostProcessManager;
import com.gamestudiohx.babylonhx.materials.textures.RenderTargetTexture;
import com.gamestudiohx.babylonhx.postprocess.renderpipeline.PostProcessRenderPipelineManager;
import com.gamestudiohx.babylonhx.postprocess.renderpipeline.PostProcessRenderPipeline;
import com.gamestudiohx.babylonhx.postprocess.PostProcess;
import com.gamestudiohx.babylonhx.postprocess.PassPostProcess;
import com.gamestudiohx.babylonhx.materials.Effect;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
import com.gamestudiohx.babylonhx.mesh.Mesh;
import com.gamestudiohx.babylonhx.Scene;



/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Brendon Smith #seacloud9
 */

@:expose('BABYLON.PostProcessRenderPass') class PostProcessRenderPass {
		private var _enabled: Bool = true;
        private var  _renderList: Array<AbstractMesh>;
        private var _renderTexture: RenderTargetTexture;
        private var _scene: Scene;
        private var _refCount: Int = 0;
        public var _name: String;

        public function new(scene: Scene, name: String, size: Int, renderList: Array<AbstractMesh>, beforeRender:Dynamic, afterRender:Dynamic) {
            this._name = name;
            //mipmap false?
            this._renderTexture = new RenderTargetTexture(name, size, scene, false);
            this.setRenderList(renderList);

            this._renderTexture.onBeforeRender = beforeRender;
            this._renderTexture.onAfterRender = afterRender;

            this._scene = scene;

            this._renderList = renderList;
        }

        // private
        public function _incRefCount(): Int {
            if (this._refCount == 0) {
                this._scene.customRenderTargets.push(this._renderTexture);
            }

            return ++this._refCount;
        }

        public function _decRefCount(): Int {
            this._refCount--;

            if (this._refCount <= 0) {
                this._scene.customRenderTargets.splice(this._scene.customRenderTargets.indexOf(this._renderTexture), 1);
            }

            return this._refCount;
        }

        public function _update(): Void {
            this.setRenderList(this._renderList);
        }

        // public

        public function setRenderList(renderList: Array<AbstractMesh>): Void {
            this._renderTexture.renderList = renderList;
        }

        public function getRenderTexture(): RenderTargetTexture {
            return this._renderTexture;
        }

}