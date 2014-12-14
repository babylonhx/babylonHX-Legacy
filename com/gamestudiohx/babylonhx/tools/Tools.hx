package com.gamestudiohx.babylonhx.tools;

import com.gamestudiohx.babylonhx.tools.math.Vector3;
import com.gamestudiohx.babylonhx.animations.Animation;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.Lib;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.utils.Timer;
import openfl.Assets;
import openfl.utils.Float32Array;
#if cpp
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;
#end


typedef BabylonMinMax = {
minimum:Vector3, maximum:Vector3
}

interface IAnimatable {
    public var animations:Array<Animation>;
}

enum Space {
    LOCAL;
    WORLD;
}

class Axis {
    public static var X:Vector3 = new Vector3(1, 0, 0);
    public static var Y:Vector3 = new Vector3(0, 1, 0);
    public static var Z:Vector3 = new Vector3(0, 0, 1);
}



/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin / Brendon Smith #seacloud9
 */

@:expose('BABYLON.Tools') class Tools {
    public static var isDebug:Bool = false;
    public static var timer:Timer;

    public static inline function ExtractMinAndMax(positions:Array<Float>, start:Int, count:Int):BabylonMinMax {
        var minimum:Vector3 = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        var maximum:Vector3 = new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);

        for (index in start...start + count) {
            var current = new Vector3(positions[index * 3], positions[index * 3 + 1], positions[index * 3 + 2]);

            minimum = Vector3.Minimize(current, minimum);
            maximum = Vector3.Maximize(current, maximum);
        }

        return {
        minimum: minimum, maximum: maximum
        };
    }

    public static inline function randomNumber(min:Float, max:Float):Float {
        var ret:Float = min;
        if (min == max) {
            ret = min;
        } else {
            var random = Math.random();
            ret = ((random * (max - min)) + min);
        }
        return ret;
    }

    public static inline function WithinEpsilon(a:Float, b:Float):Bool {
        var num:Float = a - b;
        return -1.401298E-45 <= num && num <= 1.401298E-45;
    }

    public static function LoadFile(url:String, ?callbackFn:String -> Void, ?progressCallBack:Dynamic, ?database:Dynamic, useArrayBuffer:Bool = false):Void {
        if (Tools.isDebug) {
            trace('LoadFile URL - ' + url);
        }

        //url = Tools.CleanUrl(url);
        #if html5       // Assets.getText doesn't work in html5 -> Chrome ????
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, function(data) {
                callbackFn(loader.data);
            });
            loader.load(new URLRequest(url));
            #else
        if (Assets.exists(url)) {
            var file:String = Assets.getText(url);
            callbackFn(file);
        } else {
            trace("File: " + url + " doesn't exist !");
        }
        #end

        /*
            var noIndexedDB = () => {
                var request = new XMLHttpRequest();
                var loadUrl = Tools.BaseUrl + url;
                request.open('GET', loadUrl, true);

                if (useArrayBuffer) {
                    request.responseType = "arraybuffer";
                }

                request.onprogress = progressCallBack;

                request.onreadystatechange = () => {
                    if (request.readyState == 4) {
                        if (request.status == 200) {
                            callback(!useArrayBuffer ? request.responseText : request.response);
                        } else { // Failed
                            throw new Error("Error status: " + request.status + " - Unable to load " + loadUrl);
                        }
                    }
                };

                request.send(null);
            };

            var loadFromIndexedDB = () => {
                database.loadSceneFromDB(url, callback, progressCallBack, noIndexedDB);
            };

            // Caching only scenes files
            if (database && url.indexOf(".babylon") !== -1 && (database.enableSceneOffline)) {
                database.openAsync(loadFromIndexedDB, noIndexedDB);
            }
            else {
                noIndexedDB();
            }*/
    }

    public static function LoadImage(url:String, onload:BitmapData -> Void) {
        if (url != null) {
            if (Assets.exists(url)) {
                var img:BitmapData = Assets.getBitmapData(url);
                onload(img);
            } else {
                trace("Error: Image '" + url + "' doesn't exist !");
            }
        }

    }

    public static function DeepCopy(source:Dynamic, destination:Dynamic, doNotCopyList:Array<String> = null, mustCopyList:Array<String> = null) {
        var i = 0;
        for (prop in Reflect.fields(source)) {
            i++;
            if (Tools.isDebug) {
                trace('DeepCopy - PROP = ' + Type.typeof(prop));
                trace('DeepCopy - int ' + i);
            }
            if (prop.charAt(0) == "_" && (mustCopyList == null || Lambda.indexOf(mustCopyList, prop) == -1)) {
                continue;
            }

            if (doNotCopyList != null && Lambda.indexOf(doNotCopyList, prop) != -1) {
                continue;
            }
            if (Tools.isDebug) {
                trace('=== DeepCopy hitCount ' + i);
                trace('=== DeepCopy hitCount ' + prop);
            }
            //try{
            var sourceValue = Reflect.field(source, prop);
            //}catch(e:String){
            //  trace("Error: " +e);
            // }


            if (Reflect.isFunction(sourceValue)) {
                if (Tools.isDebug) {
                    trace('=== DeepCopy - sourcevalue and prop  ' + sourceValue + '  ' + prop);
                    trace('=== DeepCopy - int ' + i);
                }
                continue;
            }
            if (Tools.isDebug) {
                trace('DeepCopy - sourcevalue and prop ' + sourceValue + '  ' + prop);
                trace('DeepCopy  ' + i);
                trace('DeepCopy type ' + Type.typeof(sourceValue));
                trace('DeepCopy -' + sourceValue + '>>>>>PROP>>>> ' + prop);
                trace('________________');
            }
            try {
                //Reflect.setField(destination, prop, Reflect.copy(sourceValue)); 
                Reflect.setField(destination, prop, sourceValue);
            } catch (e:String) {
                trace("Error: " + e);
            }

        }
    }


    // FPS
    public static var fpsRange:Float = 60.0;
    public static var previousFramesDuration:Array<Float> = [];
    public static var fps:Float = 60.0;
    public static var deltaTime:Float = 0.0;

    public static function GetFps():Float {
        return fps;
    }

    public static function GetDeltaTime():Float {
        return deltaTime;
    }

    inline public static function _MeasureFps() {
        previousFramesDuration.push(Lib.getTimer());
        var length = previousFramesDuration.length;

        if (length >= 2) {
            deltaTime = previousFramesDuration[length - 1] - previousFramesDuration[length - 2];
        }

        if (length >= fpsRange) {

            if (length > fpsRange) {
                previousFramesDuration.splice(0, 1);
                length = previousFramesDuration.length;
            }

            var sum:Float = 0;
            for (id in 0...length - 1) {
                sum += previousFramesDuration[id + 1] - previousFramesDuration[id];
            }

            fps = 1000.0 / (sum / (length - 1));
        }
    }

}
