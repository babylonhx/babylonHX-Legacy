package com.gamestudiohx.babylonhx.postprocess;

import com.gamestudiohx.babylonhx.cameras.Camera;
import com.gamestudiohx.babylonhx.materials.Effect;
import com.gamestudiohx.babylonhx.tools.math.Matrix;



/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin / Brendon Smith #seacloud9
 */

@:expose('BABYLON.ConvolutionPostProcess') class ConvolutionPostProcess extends PostProcess {

    public var kernel:Array<Float>;


    public function new(name:String, kernel:Array<Float>, ratio:Float, camera:Camera, samplingMode:Int = 1) {
        super(name, "convolution", ["kernel", "screenSize"], null, ratio, camera, samplingMode);

        this.kernel = kernel;

        this.onApply = function(effect:Effect):Void {
            effect.setFloat2("screenSize", this.width, this.height);
            effect.setArray("kernel", this.kernel);
        };

    }

    // Statics
    // Based on http://en.wikipedia.org/wiki/Kernel_(image_processing)
    public static var EdgeDetect0Kernel = [1, 0, -1, 0, 0, 0, -1, 0, 1];
    public static var EdgeDetect1Kernel = [0, 1, 0, 1, -4, 1, 0, 1, 0];
    public static var EdgeDetect2Kernel = [-1, -1, -1, -1, 8, -1, -1, -1, -1];
    public static var SharpenKernel = [0, -1, 0, -1, 5, -1, 0, -1, 0];
    public static var EmbossKernel = [-2, -1, 0, -1, 1, 1, 0, 1, 2];
    public static var GaussianKernel = [0, 1, 0, 1, 1, 1, 0, 1, 0];

}