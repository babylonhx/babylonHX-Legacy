package com.gamestudiohx.babylonhx.materials.textures;


import com.gamestudiohx.babylonhx.mesh.SubMesh;
import com.gamestudiohx.babylonhx.rendering.RenderingManager;
import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.mesh.Mesh;
import com.gamestudiohx.babylonhx.tools.SmartArray;
import openfl.display.Bitmap;
import openfl.display.BitmapData;


class DynamicTexture extends Texture {
    private var _generateMipMaps:Bool;
    //private var _context : CanvasRenderingContext2D;

    public function new(name:String, options:Dynamic, scene:Scene, generateMipMaps:Bool) {
        super(null, scene, !generateMipMaps);

        this.name = name;
        this.wrapU = Texture.CLAMP_ADDRESSMODE;
        this.wrapV = Texture.CLAMP_ADDRESSMODE;
        this._generateMipMaps = generateMipMaps;

        if (options.getContext) {
            this._canvas = options;
            this._texture = scene.getEngine().createDynamicTexture(options.width, options.height, generateMipMaps);
        } else {
            this._canvas = new BitmapData(options.width, options.height, false, 0xFFFFFFFF);
            if (options.width != null) {
                this._texture = scene.getEngine().createDynamicTexture(options.width, options.height, generateMipMaps);
            } else {
                this._texture = scene.getEngine().createDynamicTexture(options, options, generateMipMaps);
            }
        }

        var textureSize = this.getSize();
    }


    public function getCanvas():BitmapData {
        return this._canvas;
    }

    override public function update(invertY:Int = 1):Void {
        this.getScene().getEngine().updateDynamicTexture(this._texture, this._canvas, invertY);
    }

    /* todo: create drawText
        public function drawText(text:String,  x:number,y:Float, font:String, color:String, clearColor:String, ?invertY:boolean ) {
            var size = this.getSize();
            if (clearColor) {
                this._context.fillStyle = clearColor;
                this._context.fillRect(0, 0, size.width, size.height);
            }

            this._context.font = font;
            if (x === null) {
                var textSize = this._context.measureText(text);
                x = (size.width - textSize.width) / 2;
            }

            this._context.fillStyle = color;
            //this._context.fillText(text, x, y);

            this.update(invertY);
        }
        */

    override public function clone():Texture {
        var textureSize = this.getSize();
        var newTexture = new DynamicTexture(this.name, textureSize, this.getScene(), this._generateMipMaps);

        // Base texture
        newTexture.hasAlpha = this.hasAlpha;
        newTexture.level = this.level;

        // Dynamic Texture
        newTexture.wrapU = this.wrapU;
        newTexture.wrapV = this.wrapV;

        return newTexture;
    }
}
 