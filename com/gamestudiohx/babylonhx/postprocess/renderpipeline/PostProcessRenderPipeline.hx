package com.gamestudiohx.babylonhx.postprocess.renderpipeline;

import com.gamestudiohx.babylonhx.cameras.Camera;
import com.gamestudiohx.babylonhx.postprocess.PostProcessManager;
import com.gamestudiohx.babylonhx.postprocess.renderpipeline.PostProcessRenderPipelineManager;
import com.gamestudiohx.babylonhx.postprocess.DisplayPassPostProcess;
import com.gamestudiohx.babylonhx.postprocess.renderpipeline.PostProcessRenderEffect;
import com.gamestudiohx.babylonhx.postprocess.PostProcess;
import com.gamestudiohx.babylonhx.postprocess.PassPostProcess;
import com.gamestudiohx.babylonhx.materials.Effect;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.tools.Tools;



/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Brendon Smith #seacloud9
 */

@:expose('BABYLON.PostProcessRenderPipeline') class PostProcessRenderPipeline {
        private var _engine:Engine;
        private var _renderEffects:Map<String, PostProcessRenderEffect> = new Map<String, PostProcessRenderEffect>();
        private var _renderEffectsForIsolatedPass:Map<String, PostProcessRenderEffect> = new Map<String, PostProcessRenderEffect>();
        private var _cameras:Array<Camera>;
        // private
        public var _name: String;
        private static var  PASS_EFFECT_NAME: String = "passEffect";
        private static var  PASS_SAMPLER_NAME: String = "passSampler";

        public function new(engine: Engine, name: String) {
            this._engine = engine;
            this._name = name;

            //this._renderEffects = [];
            //this._renderEffectsForIsolatedPass = [];

            this._cameras = [];
        }

        public function addEffect(renderEffect: PostProcessRenderEffect): Void {
            //this._renderEffects[renderEffect._name] = renderEffect;
            this._renderEffects.set(renderEffect._name, renderEffect);
        }

        // private


        public function _enableEffect(renderEffectName: String, cameras: Dynamic): Void {
            var renderEffects: PostProcessRenderEffect = this._renderEffects[renderEffectName];

            if (renderEffects == null) {
                return;
            }
            if(cameras != null){
            renderEffects._enable(Tools.MakeArray(cameras));
            }else{
            renderEffects._enable(Tools.MakeArray(this._cameras));
            }
            
        }

        public function _disableEffect(renderEffectName: String, cameras): Void {
            var renderEffects: PostProcessRenderEffect = this._renderEffects[renderEffectName];

            if (renderEffects == null) {
                return;
            }
            if(cameras != null){
            renderEffects._disable(Tools.MakeArray(cameras));
            }else{
            renderEffects._disable(Tools.MakeArray(this._cameras));
            }
        }


        public function _attachCameras(cameras: Dynamic, unique: Bool): Void {
            var _cam = null;
            if(cameras != null){
            _cam = Tools.MakeArray(cameras);
            }else{
            _cam = Tools.MakeArray(this._cameras);
            }

            var indicesToDelete = [];

            for (i in 0..._cam.length) {
                var camera = _cam[i];
                //var cameraName = camera.name;

                if (this._cameras.indexOf(camera) == -1) {
                    //this._cameras[cameraName] = camera;
                    this._cameras.push(camera);
                }
                else if (unique) {
                    indicesToDelete.push(i);
                }
            }

            for (i in 0...indicesToDelete.length) {
                cameras.splice(indicesToDelete[i], 1);
            }

            for (renderEffectName in this._renderEffects.keys()) {
                this._renderEffects[renderEffectName]._attachCameras(_cam);
            }
        }

        public function _detachCameras(cameras: Dynamic): Void {
            var _cam = null;
            if(cameras != null){
            _cam = Tools.MakeArray(cameras);
            }else{
            _cam = Tools.MakeArray(this._cameras);
            }


            for (renderEffectName in this._renderEffects.keys()) {
                this._renderEffects[renderEffectName]._detachCameras(_cam);
            }

            for (i in 0..._cam.length) {

                this._cameras.splice(this._cameras.indexOf(_cam[i]), 1);
            }
        }

        public function _enableDisplayOnlyPass(passName, cameras: Dynamic): Void {
            var _cam = null;
            if(cameras != null){
            _cam = Tools.MakeArray(cameras);
            }else{
            _cam = Tools.MakeArray(this._cameras);
            }


            var pass = null;

            for (renderEffectName in this._renderEffects.keys()) {
                pass = this._renderEffects[renderEffectName].getPass(passName);

                if (pass != null) {
                    break;
                }
            }

            if (pass == null) {
                return;
            }

            for (renderEffectName in this._renderEffects.keys()) {
                this._renderEffects[renderEffectName]._disable(_cam);
            }

            pass._name = PostProcessRenderPipeline.PASS_SAMPLER_NAME;

            for (i in 0..._cam.length) {
                var camera = _cam[i];
                var cameraName = camera.name;
                var target:Dynamic;
                if(this._renderEffectsForIsolatedPass.get(cameraName) != null){
                    target = this._renderEffectsForIsolatedPass[cameraName];
                    //this._renderEffectsForIsolatedPass.set(cameraName, this._renderEffectsForIsolatedPass[cameraName]);
                }else{
                        target = new PostProcessRenderEffect(this._engine, PostProcessRenderPipeline.PASS_EFFECT_NAME,
                    function(){return new DisplayPassPostProcess(PostProcessRenderPipeline.PASS_EFFECT_NAME, 1.0, null, null, this._engine, true); });
                }

                
                target.emptyPasses();
                target.addPass(pass);
                target._attachCameras(camera);
            }
        }


        public function _disableDisplayOnlyPass(cameras: Dynamic): Void {
            var _cam = null;
            var target:Dynamic;
            if(cameras != null){
            _cam = Tools.MakeArray(cameras);
            }else{
            _cam = Tools.MakeArray(this._cameras);
            }


            for (i in 0..._cam.length) {
                var camera = _cam[i];
                var cameraName = camera.name;

                if(this._renderEffectsForIsolatedPass.get(cameraName) != null){
                    target = this._renderEffectsForIsolatedPass[cameraName];
                }else{
                        target = new PostProcessRenderEffect(this._engine, PostProcessRenderPipeline.PASS_EFFECT_NAME,
                    function(){return new DisplayPassPostProcess(PostProcessRenderPipeline.PASS_EFFECT_NAME, 1.0, null, null, this._engine, true); });
                }
                target._disable(camera);
            }

            for (renderEffectName in this._renderEffects.keys()) {
                this._renderEffects[renderEffectName]._enable(_cam);
            }
        }

        public function _update(): Void {
            for (renderEffectName in this._renderEffects.keys()) {
                this._renderEffects[renderEffectName]._update();
            }
            for (i in 0...this._cameras.length) {
                var cameraName = this._cameras[i].name;
                if (this._renderEffectsForIsolatedPass[cameraName] != null) {
                    this._renderEffectsForIsolatedPass[cameraName]._update();
                }
            }
        }
}