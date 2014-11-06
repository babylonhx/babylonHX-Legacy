package com.gamestudiohx.babylonhx.mesh;

import com.gamestudiohx.babylonhx.Engine;
import com.gamestudiohx.babylonhx.mesh.Geometry;
import com.gamestudiohx.babylonhx.mesh.VertexData;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;

import openfl.utils.Float32Array;


class Primitives extends Geometry {
    private var _beingRegenerated:Bool;
    private var _canBeRegenerated:Bool;

    public function new(id:String, engine:Engine, ?vertexData:VertexData, ?canBeRegenerated:Bool, ?mesh:Mesh) {
        this._beingRegenerated = true;
        this._canBeRegenerated = canBeRegenerated;
        super(id, engine, vertexData, false, mesh); // updatable = false to be sure not to update vertices
        this._beingRegenerated = false;
    }

    public function canBeRegenerated():Bool {
        return this._canBeRegenerated;
    }

    public function regenerate():Void {
        if (!this._canBeRegenerated) {
            return;
        }
        this._beingRegenerated = true;
        this.setAllVerticesData(this._regenerateVertexData(), false);
        this._beingRegenerated = false;
    }

    public function asNewGeometry(id:String):Geometry {
        return super.copy(id);
    }

    // overrides

    public function setAllVerticesData(vertexData:VertexData, ?updatable:Bool):Void {
        if (!this._beingRegenerated) {
            return;
        }
        super.setAllVerticesData(vertexData, false);
    }

    public function setVerticesData(kind:String, data:Array<Float>, ?updatable:Bool):Void {
        if (!this._beingRegenerated) {
            return;
        }
        super.setVerticesData(kind, data, false);
    }

    public function _regenerateVertexData():Void {
        trace("Abstract method");
    }

    public function copy(id:String):Void {
        trace("Must be overriden in sub-classes.");
    }

}


class Box extends Primitives {
    //
    //public var Members
    public var size:Float;

    public function new(id:String, engine:Engine, size:Float, ?canBeRegenerated:Bool, ?mesh:Mesh) {
        this.size = size;

        super(id, engine, this._regenerateVertexData(), canBeRegenerated, mesh);
    }

    public function _regenerateVertexData():VertexData {
        return VertexData.CreateBox(this.size);
    }

    public function copy(id:String):Geometry {
        return new Box(id, this.getEngine(), this.size, this.canBeRegenerated(), null);
    }
}

class Sphere extends Primitives {
    //
    //public var Members
    public var segments:Float;
    public var diameter:Float;

    public function new(id:String, engine:Engine, segments:Float, diameter:Float, ?canBeRegenerated:Bool, ?mesh:Mesh) {
        this.segments = segments;
        this.diameter = diameter;

        super(id, engine, this._regenerateVertexData(), canBeRegenerated, mesh);
    }

    public function _regenerateVertexData():VertexData {
        return VertexData.CreateSphere(this.segments, this.diameter);
    }

    public function copy(id:String):Geometry {
        return new Sphere(id, this.getEngine(), this.segments, this.diameter, this.canBeRegenerated(), null);
    }
}

class Cylinder extends Primitives {
    //
    //public var Members
    public var height:Float;
    public var diameterTop:Float;
    public var diameterBottom:Float;
    public var tessellation:Float;

    public function new(id:String, engine:Engine, height:Float, diameterTop:Float, diameterBottom:Float, tessellation:Float, ?canBeRegenerated:Bool, ?mesh:Mesh) {
        this.height = height;
        this.diameterTop = diameterTop;
        this.diameterBottom = diameterBottom;
        this.tessellation = tessellation;

        super(id, engine, this._regenerateVertexData(), canBeRegenerated, mesh);
    }

    public function _regenerateVertexData():VertexData {
        return VertexData.CreateCylinder(this.height, this.diameterTop, this.diameterBottom, this.tessellation);
    }

    public function copy(id:String):Geometry {
        return new Cylinder(id, this.getEngine(), this.height, this.diameterTop, this.diameterBottom, this.tessellation, this.canBeRegenerated(), null);
    }
}

class Torus extends Primitives {
    //
    //public var Members
    public var diameter:Float;
    public var thickness:Float;
    public var tessellation:Float;

    public function new(id:String, engine:Engine, diameter:Float, thickness:Float, tessellation:Float, ?canBeRegenerated:Bool, ?mesh:Mesh) {
        this.diameter = diameter;
        this.thickness = thickness;
        this.tessellation = tessellation;

        super(id, engine, this._regenerateVertexData(), canBeRegenerated, mesh);
    }

    public function _regenerateVertexData():VertexData {
        return VertexData.CreateTorus(this.diameter, this.thickness, this.tessellation);
    }

    public function copy(id:String):Geometry {
        return new Torus(id, this.getEngine(), this.diameter, this.thickness, this.tessellation, this.canBeRegenerated(), null);
    }
}

class Ground extends Primitives {
    //
    //public var Members
    public var width:Float;
    public var height:Float;
    public var subdivisions:Float;

    public function new(id:String, engine:Engine, width:Float, height:Float, subdivisions:Float, ?canBeRegenerated:Bool, ?mesh:Mesh) {
        this.width = width;
        this.height = height;
        this.subdivisions = subdivisions;

        super(id, engine, this._regenerateVertexData(), canBeRegenerated, mesh);
    }

    public function _regenerateVertexData():VertexData {
        return VertexData.CreateGround(this.width, this.height, this.subdivisions);
    }

    public function copy(id:String):Geometry {
        return new Ground(id, this.getEngine(), this.width, this.height, this.subdivisions, this.canBeRegenerated(), null);
    }
}

class Plane extends Primitives {
    //
    //public var Members
    public var size:Float;

    public function new(id:String, engine:Engine, size:Float, ?canBeRegenerated:Bool, ?mesh:Mesh) {
        this.size = size;

        super(id, engine, this._regenerateVertexData(), canBeRegenerated, mesh);
    }

    public function _regenerateVertexData():VertexData {
        return VertexData.CreatePlane(this.size);
    }

    public function copy(id:String):Geometry {
        return new Plane(id, this.getEngine(), this.size, this.canBeRegenerated(), null);
    }
}

class TorusKnot extends Primitives {
    //
    //public var Members
    public var radius:Float;
    public var tube:Float;
    public var radialSegments:Float;
    public var tubularSegments:Float;
    public var p:Float;
    public var q:Float;

    public function new(id:String, engine:Engine, radius:Float, tube:Float, radialSegments:Float, tubularSegments:Float, p:Float, q:Float, ?canBeRegenerated:Bool, ?mesh:Mesh) {
        this.radius = radius;
        this.tube = tube;
        this.radialSegments = radialSegments;
        this.tubularSegments = tubularSegments;
        this.p = p;
        this.q = q;

        super(id, engine, this._regenerateVertexData(), canBeRegenerated, mesh);
    }

    public function _regenerateVertexData():VertexData {
        return VertexData.CreateTorusKnot(this.radius, this.tube, this.radialSegments, this.tubularSegments, this.p, this.q);
    }

    public function copy(id:String):Geometry {
        return new TorusKnot(id, this.getEngine(), this.radius, this.tube, this.radialSegments, this.tubularSegments, this.p, this.q, this.canBeRegenerated(), null);
    }
}
 