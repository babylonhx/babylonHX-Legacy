package com.gamestudiohx.babylonhx.mesh;

import com.gamestudiohx.babylonhx.mesh.VertexData;
import com.gamestudiohx.babylonhx.culling.BoundingInfo;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
import com.gamestudiohx.babylonhx.mesh.SubMesh;
import com.gamestudiohx.babylonhx.mesh.Geometry;
import com.gamestudiohx.babylonhx.materials.Material;
import com.gamestudiohx.babylonhx.materials.ShaderMaterial;
import com.gamestudiohx.babylonhx.materials.Effect;
import com.gamestudiohx.babylonhx.bones.Skeleton;
import com.gamestudiohx.babylonhx.tools.Tools;
import com.gamestudiohx.babylonhx.tools.math.Color3;
import com.gamestudiohx.babylonhx.tools.math.Color4;
import com.gamestudiohx.babylonhx.tools.math.Matrix;
import com.gamestudiohx.babylonhx.tools.math.Plane;
import com.gamestudiohx.babylonhx.tools.math.Quaternion;
import com.gamestudiohx.babylonhx.tools.math.Ray;
import com.gamestudiohx.babylonhx.tools.math.Vector3;

import openfl.gl.GLBuffer;
import openfl.utils.Float32Array;


/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Brendon Smith #seacloud9
 */

@:expose('BABYLON.LinesMesh') class LinesMesh extends Mesh {
    public var color:Color3 = new Color3(1, 1, 1);
    public var alpha:Float = 1.0;
    private var _ib: GLBuffer;
    private var _indicesLength: Int;
    private var _sourceMesh:Mesh;
    private var _colorShader:ShaderMaterial;

    public function new(name:String, scene: Scene, updatable:Bool = false) {
        super(name, scene);

        this._colorShader = new ShaderMaterial("color", scene, "color",
                {
                    attributes: ["position"],
                    uniforms: ["worldViewProjection", "color"],
                    needAlphaBlending: true
        });
        this.material = this._colorShader;

    }

    public function getMaterial(): ShaderMaterial {
        return this._colorShader;
    }

    public function get__isPickable(): Bool {
        return false;
    }

    public function get__checkCollisions(): Bool {
        return false;
    }

    override function  _bind(subMesh: SubMesh, effect: Effect, fillMode: Int = null, ?wireframe:Bool) {
        var engine = this.getScene().getEngine();

        var indexToBind = this._geometry.getIndexBuffer();

        // VBOs
        engine.bindBuffers(this._geometry.getVertexBuffer(VertexBuffer.PositionKind).getBuffer(), indexToBind, [3], 3 * 4, this._colorShader.getEffect());

        // Color
        this._colorShader.setColor4("color", this.color.toColor4(this.alpha));
   
    }

    override function  _draw(subMesh: SubMesh, useTriangles:Bool, fillMode: Int = null, ?instancesCount: Int) {
        if (this._geometry == null || Lambda.count(this._geometry.getVertexBuffers()) == 0 || this._geometry.getIndexBuffer() == null) {
            return;
        }

        var engine = this.getScene().getEngine();

        // Draw order
        engine.draw(false, subMesh.indexStart, subMesh.indexCount);
    }

    override function intersects(ray:Ray, fastCheck:Bool = false) {
        return null;
    }

    override function dispose(doNotRecurse:Bool = false){
        this._colorShader.dispose();

        super.dispose(doNotRecurse);
    }

}
 