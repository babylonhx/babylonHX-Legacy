package com.gamestudiohx.babylonhx.postprocess;

import com.gamestudiohx.babylonhx.cameras.Camera;
import com.gamestudiohx.babylonhx.materials.Effect;


/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin
 */

class FxaaPostProcess extends PostProcess {

    public var texelWidth:Float;
    public var texelHeight:Float;

    public function new(name:String, ratio:Float, camera:Camera, samplingMode:Int = 1) {
        super(name, "fxaa", ["texelSize"], null, ratio, camera, samplingMode);

        texelWidth = 0;
        texelHeight = 0;

        this.onApply = function(effect:Effect):Void{
            effect.setFloat2("texelSize", this.texelWidth, this.texelHeight);
        }

        this.onSizeChanged = function():Void{
            this.texelWidth = 1.0 / this.width;
            this.texelHeight = 1.0 / this.height;
        }
    }

    /*
    public function onSizeChanged() {
        this.texelWidth = 1.0 / this.width;
        this.texelHeight = 1.0 / this.height;
    }
    */

    /*
    override function onApply(effect:Effect) {
        effect.setFloat2("texelSize", this.texelWidth, this.texelHeight);
    }
    */

}
