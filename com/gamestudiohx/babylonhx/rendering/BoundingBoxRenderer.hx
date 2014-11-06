package com.gamestudiohx.babylonhx.rendering;

import com.gamestudiohx.babylonhx.mesh.SubMesh;
import com.gamestudiohx.babylonhx.particles.ParticleSystem;
import com.gamestudiohx.babylonhx.materials.ShaderMaterial;
import com.gamestudiohx.babylonhx.mesh.VertexBuffer;
import com.gamestudiohx.babylonhx.mesh.VertexData;
import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh.BabylonGLBuffer;
import com.gamestudiohx.babylonhx.sprites.SpriteManager;
import com.gamestudiohx.babylonhx.tools.math.Color4;
import com.gamestudiohx.babylonhx.tools.math.Color3;
import com.gamestudiohx.babylonhx.tools.math.Matrix;
import com.gamestudiohx.babylonhx.tools.SmartArray;
import openfl.gl.GLBuffer;
import openfl.Lib;


class BoundingBoxRenderer {
    public var frontColor = new Color3(1, 1, 1);
    public var backColor = new Color3(0.1, 0.1, 0.1);
    public var showBackLines = true;
    public var renderList = new SmartArray();
    private var _scene:Scene;
    private var _colorShader:ShaderMaterial;
    private var _vb:VertexBuffer;
    private var _ib:BabylonGLBuffer;

    public function new(scene:Scene) {

        this._scene = scene;
        this.renderList.length = 32;
        this._colorShader = new ShaderMaterial("colorShader", scene, "color", {
        attributes: ["position"], uniforms: ["worldViewProjection", "color"]
        });


        var engine = this._scene.getEngine();
        var boxdata = VertexData.CreateBox(1.0);
        this._vb = new VertexBuffer(engine, boxdata.positions, VertexBuffer.PositionKind, false);
        this._ib = engine.createIndexBuffer([0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 7, 1, 6, 2, 5, 3, 4]);
    }

    public function reset():Void {
        this.renderList.reset();
    }

    public function render():Void {
        //todo fix this!!!
        /* if (this.renderList.length == 0 || !this._colorShader.isReady()) {
                return;
            }*/


        var engine = this._scene.getEngine();
        engine.setDepthWrite(false);
        this._colorShader._preBind();
        // haxe does not support for loops with C/JS syntaxt ... unfolding :
        //  for (var boundingBoxIndex = 0; boundingBoxIndex < this.renderList.length; boundingBoxIndex++)
        var boundingBoxIndex = 0;
        while (boundingBoxIndex < this.renderList.length) {
            var boundingBox = this.renderList.data[boundingBoxIndex];
            var min = boundingBox.minimum;
            var max = boundingBox.maximum;
            var diff = max.subtract(min);
            var median = min.add(diff.scale(0.5));

            var worldMatrix = Matrix.Scaling(diff.x, diff.y, diff.z)
            .multiply(Matrix.Translation(median.x, median.y, median.z))
            .multiply(boundingBox.getWorldMatrix());

            // VBOs
            engine.bindBuffers(this._vb.getBuffer(), this._ib, [3], 3 * 4, this._colorShader.getEffect());

            if (this.showBackLines) {
                // Back
                engine.setDepthFunctionToGreaterOrEqual();
                this._colorShader.setColor3("color", this.backColor);
                this._colorShader.bind(worldMatrix);

                // Draw order
                engine.draw(false, 0, 24);
            }

            // Front
            engine.setDepthFunctionToLess();
            this._colorShader.setColor3("color", this.frontColor);
            this._colorShader.bind(worldMatrix);

            // Draw order
            engine.draw(false, 0, 24);
            boundingBoxIndex++;

        }
        this._colorShader.unbind();
        engine.setDepthFunctionToLessOrEqual();
        engine.setDepthWrite(true);
    }

    public function dispose():Void {
        this._colorShader.dispose();
        this._vb.dispose();
        this._scene.getEngine()._releaseBuffer(this._ib);
    }
}
 