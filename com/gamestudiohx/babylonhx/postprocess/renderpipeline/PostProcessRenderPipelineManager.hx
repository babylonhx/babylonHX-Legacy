package com.gamestudiohx.babylonhx.postprocess.renderpipeline;

import com.gamestudiohx.babylonhx.cameras.Camera;
import com.gamestudiohx.babylonhx.postprocess.PostProcessManager;
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

@:expose('BABYLON.PostProcessRenderPipelineManager') class PostProcessRenderPipelineManager {
        private var _renderPipelines:Map<String, PostProcessRenderPipeline>;

        public function new() {
            this._renderPipelines = new Map<String, PostProcessRenderPipeline>();
        }

        public function addPipeline(renderPipeline: PostProcessRenderPipeline): Void {
            //this._renderPipelines[renderPipeline._name] = renderPipeline;
            this._renderPipelines.set(renderPipeline._name, renderPipeline);
        }

        public function attachCamerasToRenderPipeline(renderPipelineName: String, cameras: Dynamic, ?unique: Bool): Void {
            var renderPipeline: PostProcessRenderPipeline = this._renderPipelines.get(renderPipelineName);


            if (renderPipeline == null) {
                return;
            }

            renderPipeline._attachCameras(cameras, unique);
        }

        public function detachCamerasFromRenderPipeline(renderPipelineName: String, cameras: Dynamic): Void {
            var renderPipeline: PostProcessRenderPipeline = this._renderPipelines.get(renderPipelineName);

            if (renderPipeline == null) {
                return;
            }

            renderPipeline._detachCameras(cameras);
        }

        public function enableEffectInPipeline(renderPipelineName: String, renderEffectName: String, cameras: Dynamic): Void {
            var renderPipeline: PostProcessRenderPipeline = this._renderPipelines.get(renderPipelineName);

            if (renderPipeline == null) {
                return;
            }

            renderPipeline._enableEffect(renderEffectName, cameras);
        }


        public function disableEffectInPipeline(renderPipelineName: String, renderEffectName: String, cameras: Dynamic): Void {
            var renderPipeline: PostProcessRenderPipeline = this._renderPipelines.get(renderPipelineName);

            if (renderPipeline == null) {
                return;
            }

            renderPipeline._disableEffect(renderEffectName, cameras);
        }

        public function enableDisplayOnlyPassInPipeline(renderPipelineName: String, passName: String, cameras: Dynamic): Void {
            var renderPipeline: PostProcessRenderPipeline = this._renderPipelines.get(renderPipelineName);

            if (renderPipeline == null) {
                return;
            }

            renderPipeline._enableDisplayOnlyPass(passName, cameras);
        }

        public function disableDisplayOnlyPassInPipeline(renderPipelineName: String, cameras: Dynamic): Void {
            var renderPipeline: PostProcessRenderPipeline = this._renderPipelines.get(renderPipelineName);

            if (renderPipeline == null) {
                return;
            }

            renderPipeline._disableDisplayOnlyPass(cameras);
        }

        public function update(): Void {
            for (renderPipelineName in this._renderPipelines.keys()) {
                this._renderPipelines.get(renderPipelineName)._update();
            }
        }
}