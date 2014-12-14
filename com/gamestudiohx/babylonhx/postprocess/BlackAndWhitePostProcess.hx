package com.gamestudiohx.babylonhx.postprocess;

import com.gamestudiohx.babylonhx.cameras.Camera;


/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin / Brendon Smith #seacloud9
 */

@:expose('BABYLON.BlackAndWhitePostProcess') class BlackAndWhitePostProcess extends PostProcess {

    public function new(name:String, ratio:Float, camera:Camera, samplingMode:Int) {
        super(name, "blackAndWhite", null, null, ratio, camera, samplingMode);
    }

}