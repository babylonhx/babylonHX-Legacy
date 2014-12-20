package com.gamestudiohx.babylonhx.postprocess.renderpipeline;

import com.gamestudiohx.babylonhx.cameras.Camera;
import com.gamestudiohx.babylonhx.materials.textures.RenderTargetTexture;
import com.gamestudiohx.babylonhx.postprocess.PostProcessManager;
import com.gamestudiohx.babylonhx.postprocess.renderpipeline.PostProcessRenderPipelineManager;
import com.gamestudiohx.babylonhx.postprocess.renderpipeline.PostProcessRenderPipeline;
import com.gamestudiohx.babylonhx.postprocess.renderpipeline.PostProcessRenderPass;
import com.gamestudiohx.babylonhx.postprocess.PostProcess;
import com.gamestudiohx.babylonhx.postprocess.PassPostProcess;
import com.gamestudiohx.babylonhx.materials.Effect;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
import com.gamestudiohx.babylonhx.mesh.Mesh;
import com.gamestudiohx.babylonhx.tools.Tools;
import com.gamestudiohx.babylonhx.materials.Effect;
import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.Engine;



/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Brendon Smith #seacloud9
 */

@:expose('BABYLON.PostProcessRenderEffect') class PostProcessRenderEffect {
		private var _enabled: Bool = true;
        private var  _renderList: Array<Mesh>;
        private var _renderTexture: RenderTargetTexture;
        private var _scene: Scene;
        private var _refCount: Int = 0;
        public var _name: String;
        public var _cameras:Dynamic;
        public var _singleInstance:Bool;
        public var _postProcesses:Map<String, Dynamic>;
        public var _indicesForCamera:Map<String, Array<Dynamic>>;
        public var _getPostProcess:Dynamic;
        public var _renderPasses:Map<String, Dynamic>;
        public var _renderEffectAsPasses:Map<String, Dynamic>;
        public var applyParameters: PostProcess-> Void;
        private var _engine:Engine;

        public function new(engine: Engine, name: String, getPostProcess: Void -> PostProcess, ?singleInstance: Bool) {
            this._engine = engine;
            this._name = name;
            this._singleInstance = true;
            this._cameras = [];

            this._postProcesses = new Map<String, Dynamic>();
            this._indicesForCamera =  new Map<String, Array<Dynamic>>();

            this._renderPasses = new Map<String, Dynamic>();
            this._renderEffectAsPasses = new Map<String, Dynamic>();
            this._getPostProcess = function(?camera: Camera): PostProcess {
                if (this._singleInstance) {
                    var i:Int = 0;
                    var iterR:Dynamic = null;
                    for(k in this._postProcesses.keys()){
                        if(i == 0){
                            iterR = this._postProcesses[k];
                        }
                    }
                    return iterR;

                }
                else {
                    return this._postProcesses[camera.name];
                }
            }
        }

       public function _update(): Void {
            for (renderPassName in this._renderPasses.keys()) {
                this._renderPasses[renderPassName]._update();
            }
        }

        public function addPass(renderPass: PostProcessRenderPass): Void {
            //this._renderPasses[renderPass._name] = renderPass;
            this._renderPasses.set(renderPass._name, renderPass);

            this._linkParameters();
        }

        public function removePass(renderPass: PostProcessRenderPass): Void {
            this._renderPasses[renderPass._name] = null;

            this._linkParameters();
        }

        public function addRenderEffectAsPass(renderEffect: PostProcessRenderEffect): Void {
            //this._renderEffectAsPasses[renderEffect._name] = renderEffect;
            this._renderEffectAsPasses.set(renderEffect._name, renderEffect);
            this._linkParameters();
        }

        public function getPass(passName: String): Dynamic {
            /*var itmR:Dynamic = null;
            for (renderPassName in 0...this._renderPasses.length) {
                if (renderPassName == passName) {
                    itmR = this._renderPasses[passName];
                }
            }*/

            return this._renderPasses.get(passName);
        }

        public function emptyPasses(): Void {
            this._renderPasses = null;

            this._linkParameters();
        }

        public function getSingleInstance():Dynamic{
            var i:Int = 0;
            var retItr:Dynamic = null;
            for(k in this._postProcesses.keys()){
                if(i == 0){
                    retItr = this._postProcesses[k];
                }
            }
            return retItr;
        }

        // private
        public function _attachCameras(cameras: Dynamic): Void {
            var cameraKey:String = null;
            var _cam = null;
            if(cameras != null){
            _cam = Tools.MakeArray(cameras);
            }else{
            _cam = Tools.MakeArray(this._cameras);
            }


            for (i in 0..._cam.length) {
                var camera = _cam[i];
                var cameraName = camera.name;

                if (this._singleInstance) {
                    var i:Int = 0;
                    for(k in this._postProcesses.keys()){
                        if(i == 0){
                            cameraKey = this._postProcesses[k].name;
                        }
                        i++;
                    }
                }
                else {
                    cameraKey = cameraName;
                }

                this._postProcesses[cameraKey] = this._postProcesses[cameraKey] || this._getPostProcess();

                var index = camera.attachPostProcess(this._postProcesses[cameraKey]);

                if (this._indicesForCamera.get(cameraName) == null) {
                    this._indicesForCamera.set(cameraName, new Array<Dynamic>());
                }

                //this._indicesForCamera[cameraName].push(index);
                this._indicesForCamera.set(cameraName, index);

                if (this._cameras.indexOf(camera) == -1) {
                    //this._cameras[cameraName] = camera;
                    this._cameras.push(camera);
                }

                for (passName in this._renderPasses.keys()) {
                    this._renderPasses[passName]._incRefCount();
                }
            }

            this._linkParameters();
        }

        // private
        public function _detachCameras(cameras: Dynamic): Void {
            var _cam = Tools.MakeArray(cameras || this._cameras);

            for (i in 0..._cam.length) {
                var camera = _cam[i];
                var cameraName = camera.name;

                if(this._singleInstance){
                    camera.detachPostProcess(this.getSingleInstance(), this._indicesForCamera[cameraName]);
                }else{
                    camera.detachPostProcess(this._postProcesses[cameraName], this._indicesForCamera[cameraName]);
                }

                //camera.detachPostProcess(this._postProcesses[this._singleInstance ? 0 : cameraName], this._indicesForCamera[cameraName]);

                var index = this._cameras.indexOf(cameraName);
                this._indicesForCamera.remove(cameraName);
                //this._indicesForCamera.splice(index, 1);
                this._cameras.splice(index, 1);

                for (passName in this._renderPasses.keys()) {
                    this._renderPasses[passName]._decRefCount();
                }
            }
        }

        // private
        public function _enable(cameras: Dynamic): Void {
            var _cam = Tools.MakeArray(cameras || this._cameras);

            for (i in 0..._cam.length) {
                var camera = _cam[i];
                var cameraName = camera.name;

                for (j in 0...this._indicesForCamera[cameraName].length) {
                    if (camera._postProcesses[this._indicesForCamera[cameraName][j]] == null) {
                        if(this._singleInstance){
                            camera.attachPostProcess(this.getSingleInstance(), this._indicesForCamera[cameraName]);
                        }else{
                            camera.attachPostProcess(this._postProcesses[cameraName], this._indicesForCamera[cameraName]);
                        }

                        //cameras[i].attachPostProcess(this._postProcesses[this._singleInstance ? 0 : cameraName], this._indicesForCamera[cameraName][j]);
                    }
                }

                for (passName in this._renderPasses.keys()) {
                    this._renderPasses[passName]._incRefCount();
                }
            }
        }

        // private
        public function _disable(cameras: Dynamic): Void {
            var _cam = Tools.MakeArray(cameras || this._cameras);

            for (i in 0..._cam.length) {
                var camera = _cam[i];
                var cameraName = camera.Name;

                if(this._singleInstance){
                            camera.detachPostProcess(this.getSingleInstance(), this._indicesForCamera[cameraName]);
                }else{
                            camera.detachPostProcess(this._postProcesses[cameraName], this._indicesForCamera[cameraName]);
                }
                //camera.detachPostProcess(this._postProcesses[this._singleInstance ? 0 : cameraName], this._indicesForCamera[cameraName]);

                for (passName in this._renderPasses.keys()) {
                    this._renderPasses[passName]._decRefCount();
                }
            }
        }

        public function getPostProcess(?camera: Camera): PostProcess {
                if (this._singleInstance) {
                    var i:Int = 0;
                    var iterR:Dynamic = null;
                    for(k in this._postProcesses.keys()){
                        if(i == 0){
                            iterR = this._postProcesses[k];
                        }
                    }
                    return iterR;
                }
            else {
                return this._postProcesses[camera.name];
            }
        }

        private function _linkParameters(): Void {
            for (index in this._postProcesses.keys()) {
                if (this.applyParameters != null) {
                    this.applyParameters(this._postProcesses[index]);
                }

                this._postProcesses[index].onBeforeRender = function(effect: Effect){
                    this._linkTextures(effect);
                };
            }
        }

        private function _linkTextures(effect:Effect): Void {
            for (renderPassName in this._renderPasses.keys()) {
                effect.setTexture(renderPassName, this._renderPasses[renderPassName].getRenderTexture());
            }

            for (renderEffectName in this._renderEffectAsPasses.keys()) {
                effect.setTextureFromPostProcess(renderEffectName + "Sampler", this._renderEffectAsPasses[renderEffectName].getPostProcess());
            }
        }

}