package com.gamestudiohx.babylonhx.postprocess;

import com.gamestudiohx.babylonhx.cameras.Camera;
import com.gamestudiohx.babylonhx.materials.Effect;
import com.gamestudiohx.babylonhx.materials.textures.Texture;
import com.gamestudiohx.babylonhx.Engine;
import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.tools.SmartArray;

/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * Brendon Smith #seacloud9
 */

@:expose('BABYLON.DisplayPassPostProcess') class DisplayPassPostProcess extends PostProcess {
        public function new (name: String, ratio: Float, camera: Camera, ?samplingMode: Int, ?engine: Engine, ?reusable:Bool) {
            super(name, "displayPass", ["passSampler"], ["passSampler"], ratio, camera, samplingMode, engine, reusable);
        }
  }
