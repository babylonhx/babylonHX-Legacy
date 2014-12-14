package com.gamestudiohx.babylonhx.cameras;

import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.tools.math.Vector3;

/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin / Brendon Smith #seacloud9
 */

@:expose('BABYLON.TouchCamera') class TouchCamera extends FreeCamera {

    public var _offsetX:Float;
    public var _offsetY:Float;
    public var _pointerCount:Int = 0;
    public var _pointerPressed:Array<Dynamic>;

    public function new(name:String, position:Vector3, scene:Scene) {
        super(name, position, scene);

        this._offsetX = null;
        this._offsetY = null;
        this._pointerCount = 0;
        this._pointerPressed = [];
    }

}