package com.gamestudiohx.babylonhx.mesh;

import com.gamestudiohx.babylonhx.mesh.VertexData;
import com.gamestudiohx.babylonhx.culling.BoundingInfo;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
import com.gamestudiohx.babylonhx.mesh.SubMesh;
import com.gamestudiohx.babylonhx.mesh.Geometry;
import com.gamestudiohx.babylonhx.materials.Material;
import com.gamestudiohx.babylonhx.bones.Skeleton;
import com.gamestudiohx.babylonhx.tools.Tools;
import com.gamestudiohx.babylonhx.tools.math.Matrix;
import com.gamestudiohx.babylonhx.tools.math.Plane;
import com.gamestudiohx.babylonhx.tools.math.Quaternion;
import com.gamestudiohx.babylonhx.tools.math.Ray;
import com.gamestudiohx.babylonhx.tools.math.Vector3;

import openfl.gl.GLBuffer;
import openfl.utils.Float32Array;


class InstancedMesh extends AbstractMesh {
    private var _sourceMesh:Mesh;

    public function new(name:String, source:Mesh) {
        super(name, source.getScene());

        source.instances.push(this);

        this._sourceMesh = source;

        this.position.copyFrom(source.position);
        this.rotation.copyFrom(source.rotation);
        this.scaling.copyFrom(source.scaling);

        if (source.rotationQuaternion != null) {
            this.rotationQuaternion = source.rotationQuaternion.clone();
        }

        this.infiniteDistance = source.infiniteDistance;

        this.setPivotMatrix(source.getPivotMatrix());

        this.refreshBoundingInfo();
        this._syncSubMeshes();
    }

    // Methods
    //public get
    /*
        override function receiveShadows() :Bool {
            return this._sourceMesh.receiveShadows;
        }

        //public get
        /*
        override function material() : Material {
            return this._sourceMesh.material;
        }

        //public get

        override function visibility() : Float {
            return this._sourceMesh.visibility;
        }

        //public get

        public function skeleton() : Skeleton {
            return this._sourceMesh.skeleton;
        }

        /*
        override function getTotalVertices() : Float {
            return this._sourceMesh.getTotalVertices();
        }

        //public get

        public function sourceMesh() : Mesh {
            return this._sourceMesh;
        }

        override function getVerticesData(kind:String ) : Array<Float> {
            return this._sourceMesh.getVerticesData(kind);
        }

        override function isVerticesDataPresent(kind:String ) : Bool {
            return this._sourceMesh.isVerticesDataPresent(kind);
        }

        override function getIndices() : Array<Int>{
            return this._sourceMesh.getIndices();
        }

        //public get
        // 
        /*
        public function _positions() : Array<Vector3> {
            return this._sourceMesh._positions;
        }*/

    public function refreshBoundingInfo():Void {
        var data = this._sourceMesh.getVerticesData(VertexBuffer.PositionKind);

        if (data.length > 0) {
            var extend = Tools.ExtractMinAndMax(data, 0, this._sourceMesh.getTotalVertices());
            this._boundingInfo = new BoundingInfo(extend.minimum, extend.maximum);
        }

        this._updateBoundingInfo();
    }

    override function _activate(renderId:Int):Void {
        this._sourceMesh._registerInstanceForRenderId(this, renderId);
    }

    public function _syncSubMeshes():Void {
        this.releaseSubMeshes();
        // haxe does not support for loops with C/JS syntaxt ... unfolding :
        //  for (var index = 0; index < this._sourceMesh.subMeshes.length; index++)
        var index = 0;
        while (index < this._sourceMesh.subMeshes.length) {
            this._sourceMesh.subMeshes[index].clone(this, this._sourceMesh);
            index++;

        }
    }

    override function _generatePointsArray():Bool {
        return this._sourceMesh._generatePointsArray();
    }

    // Clone

    override function clone(name:String, newParent:Node = null, doNotCloneChildren:Bool = false):InstancedMesh {
        var result = this._sourceMesh.createInstance(name);

        // Deep copy
        Tools.DeepCopy(this, result, ["name"], []);

        // Bounding info
        this.refreshBoundingInfo();

        // Parent
        if (newParent != null) {
            result.parent = newParent;
        }

        if (!doNotCloneChildren) {
            // Children
            // haxe does not support for loops with C/JS syntaxt ... unfolding :
            //  for (var index = 0; index < this.getScene().meshes.length; index++)
            var index = 0;
            while (index < this.getScene().meshes.length) {
                var mesh = cast(this.getScene().meshes[index], InstancedMesh);

                if (mesh.parent == this) {
                    mesh.clone(mesh.name, result);
                }
                index++;

            }
        }

        result.computeWorldMatrix(true);

        return result;
    }

    // Dispoe

    override function dispose(doNotRecurse:Bool = false):Void {

        // Remove from mesh
        var index = this._sourceMesh.instances.indexOf(this);
        this._sourceMesh.instances.splice(index, 1);

        super.dispose(doNotRecurse);
    }
}
 