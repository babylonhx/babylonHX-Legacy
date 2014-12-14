package com.gamestudiohx.babylonhx.mesh;

import com.gamestudiohx.babylonhx.Engine;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;

import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
import openfl.utils.Float32Array;


/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin / Brendon Smith #seacloud9
 */

@:expose('BABYLON.VertexBuffer') class VertexBuffer {

    public static var PositionKind:String = "position";
    public static var NormalKind:String = "normal";
    public static var UVKind:String = "uv";
    public static var UV2Kind:String = "uv2";
    public static var ColorKind:String = "color";
    public static var MatricesIndicesKind:String = "matricesIndices";
    public static var MatricesWeightsKind:String = "matricesWeights";

    public var _mesh:Mesh;
    public var _engine:Engine;
    public var _updatable:Bool;

    public var _buffer:BabylonGLBuffer;
    public var _data:Array<Float>;
    public var _kind:String;

    public var _strideSize:Int;


    public function new(mesh:Dynamic, data:Array<Float>, kind:String, updatable:Bool, postponeInternalCreation:Bool = false) {
        if (Std.is(mesh, Mesh)) { // old versions of BABYLON.VertexBuffer accepted 'mesh' instead of 'engine'
            this._mesh = mesh;
            this._engine = mesh.getScene().getEngine();
        } else {
            this._engine = mesh;
        }
        //this._mesh = mesh;
        //this._engine = mesh.getScene().getEngine();
        this._updatable = updatable;

        if (updatable) {
            this._buffer = this._engine.createDynamicVertexBuffer(data.length * 4);
            this._engine.updateDynamicVertexBuffer(this._buffer, data);
        } else {
            this._buffer = this._engine.createVertexBuffer(data);
        }

        this._data = data;
        if (!postponeInternalCreation) { // by default
            this.create();
        }

        this._kind = kind;


        switch (kind) {
            case VertexBuffer.PositionKind:
                this._strideSize = 3;
            //this._mesh._resetPointsArrayCache();
            case VertexBuffer.NormalKind:
                this._strideSize = 3;
            case VertexBuffer.UVKind:
                this._strideSize = 2;
            case VertexBuffer.UV2Kind:
                this._strideSize = 2;
            case VertexBuffer.ColorKind:
                this._strideSize = 3;
            case VertexBuffer.MatricesIndicesKind:
                this._strideSize = 4;
            case VertexBuffer.MatricesWeightsKind:
                this._strideSize = 4;
            default:
            //
        }
    }

    public function getBuffer():BabylonGLBuffer {
        return this._buffer;
    }

    public function isUpdatable():Bool {
        return this._updatable;
    }

    public function getData():Array<Float> {
        return this._data;
    }

    public function getStrideSize():Int {
        return this._strideSize;
    }

    public function create(?data:Array<Float>):Void {
        if (data == null && this._buffer != null) {
            return; // nothing to do
        }

        if (data == null) {
            data = this._data;
        }

        if (this._buffer == null) { // create buffer
            if (this._updatable) {
                this._buffer = this._engine.createDynamicVertexBuffer(data.length * 4);
            } else {
                this._buffer = this._engine.createVertexBuffer(data);
            }
        }

        if (this._updatable) { // update buffer
            this._engine.updateDynamicVertexBuffer(this._buffer, data);
            this._data = data;
        }
    }


    public function update(data:Array<Float>) {
        this._engine.updateDynamicVertexBuffer(this._buffer, data);
        this._data = data;

        if (this._kind == PositionKind) {
            this._mesh._resetPointsArrayCache();
        }
    }

    public function dispose() {
        this._engine._releaseBuffer(this._buffer);
    }

}
