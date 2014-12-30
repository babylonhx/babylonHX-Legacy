package com.gamestudiohx.babylonhx.mesh;

import com.gamestudiohx.babylonhx.mesh.VertexData;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
import com.gamestudiohx.babylonhx.mesh.GroundMesh;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh.BabylonGLBuffer;
import com.gamestudiohx.babylonhx.culling.BoundingInfo;
import com.gamestudiohx.babylonhx.mesh.SubMesh;
import com.gamestudiohx.babylonhx.mesh.Geometry;
import com.gamestudiohx.babylonhx.mesh.InstancedMesh;
import com.gamestudiohx.babylonhx.materials.Material;
import com.gamestudiohx.babylonhx.materials.Effect;
import com.gamestudiohx.babylonhx.particles.ParticleSystem;
import com.gamestudiohx.babylonhx.tools.Tools;
import com.gamestudiohx.babylonhx.tools.math.Matrix;
import com.gamestudiohx.babylonhx.tools.math.Plane;
import com.gamestudiohx.babylonhx.tools.math.Quaternion;
import com.gamestudiohx.babylonhx.tools.math.Ray;
import com.gamestudiohx.babylonhx.tools.math.Vector3;
import com.gamestudiohx.babylonhx.Engine.BabylonCaps;
import com.gamestudiohx.babylonhx.materials.textures.Texture;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.gl.GLBuffer;
import openfl.utils.Float32Array;
import openfl.utils.UInt8Array;


/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Brendon Smith #seacloud9
 */

@:expose('BABYLON.InstancesBatch') class InstancesBatch {
    public var mustReturn:Bool = false;
    public var visibleInstances:Array<InstancedMesh>;
    public var renderSelf:Bool = true;

    public function new() {}
}

@:expose('BABYLON.Mesh') class Mesh extends AbstractMesh implements IGetSetVerticesData {
    // Members
    public var delayLoadState:Int = Engine.DELAYLOADSTATE_NONE;
    public var instances = new Array<InstancedMesh>();
    public var delayLoadingFile:String;
    //private var _onBeforeRenderCallbacks:Array<Void -> Void> = new Array<Void -> Void>();
    private var  _onAfterRenderCallbacks = new Array<Dynamic>();

    //
    // public var Private
    public var _geometry:Geometry;
    private var _onBeforeRenderCallbacks = new Array<Dynamic>();
    //private var _delayInfo:Dynamic; //ANY
    //private var _delayLoadingFunction: (any, Mesh) => void;
    private var _delayLoadingFunction:String;
    public var _visibleInstances:Dynamic;
    public var _renderIdForInstances:Int = -1;
    private var _preActivateId: Int;
    private var _batchCache:InstancesBatch = new InstancesBatch();
    private var _worldMatricesInstancesBuffer:BabylonGLBuffer;
    private var _worldMatricesInstancesArray:Float32Array;
    private var _instancesBufferSize:Int = 32 * 16 * 4; // let's start with a maximum of 32 instances

    public function new(name:String, scene:Scene) {
        super(name, scene);
    }

    override function getTotalVertices():Int {
        if (this._geometry == null) {
            return 0;
        }
        return this._geometry.getTotalVertices();
    }

    override function getVerticesData(kind:String):Array<Float> {
        if (this._geometry == null) {
            return null;
        }
        return this._geometry.getVerticesData(kind);
    }

    public function getVertexBuffer(kind):VertexBuffer {
        if (this._geometry == null) {
            return null;
        }
        return this._geometry.getVertexBuffer(kind);
    }

    override function isVerticesDataPresent(kind:String):Bool {
        if (this._geometry == null) {
            if (this._delayInfo.length > 0) {
                return this._delayInfo.indexOf(kind) != -1;
            }
            return false;
        }
        return this._geometry.isVerticesDataPresent(kind);
    }

    public function getVerticesDataKinds():Array<String> {
        if (this._geometry == null) {
            var result = new Array<String>();
            if (this._delayInfo.length > 0) {
                // haxe does not support for loops with C/JS syntaxt ... unfolding :
                //  for (var kind in this._delayInfo)
                for (kind in this._delayInfo) {
                    result.push(kind);
                }

            }
            return result;
        }
        return this._geometry.getVerticesDataKinds();
    }

    public function getTotalIndices():Int {
        if (this._geometry == null) {
            return 0;
        }
        return this._geometry.getTotalIndices();
    }

    override function getIndices():Array<Int> {
        if (this._geometry == null) {
            return new Array<Int>();
        }
        return this._geometry.getIndices();
    }

    override function isReady():Bool {
        if (this.delayLoadState == Engine.DELAYLOADSTATE_LOADING) {
            return false;
        }
        return super.isReady();
    }

    /*
        public function isDisposed() : Bool {
            return this._isDisposed;
        }*/

    // Methods

    override function _preActivate():Void {
        var sceneRenderId = this.getScene().getRenderId();
        if (this._preActivateId == sceneRenderId) {
            return;
        }

        this._preActivateId = sceneRenderId;

        this._visibleInstances = null;
    }

    public function _registerInstanceForRenderId(instance:InstancedMesh, renderId:Int) {
        if (this._visibleInstances != null) {
            this._visibleInstances = {};
            this._visibleInstances.defaultRenderId = renderId;
            this._visibleInstances.selfDefaultRenderId = this._renderId;
        }

        if (this._visibleInstances[renderId] == null) {
            this._visibleInstances[renderId] = new Array<InstancedMesh>();
        }

        this._visibleInstances[renderId].push(instance);
    }

    public function refreshBoundingInfo():Void {
        var data = this.getVerticesData(VertexBuffer.PositionKind);

        if (data.length > 0) {
            var extend = Tools.ExtractMinAndMax(data, 0, this.getTotalVertices());
            this._boundingInfo = new BoundingInfo(extend.minimum, extend.maximum);
        }

        if (this.subMeshes.length > 0) {
            // haxe does not support for loops with C/JS syntaxt ... unfolding :
            //  for (var index = 0; index < this.subMeshes.length; index++)
            var index = 0;
            while (index < this.subMeshes.length) {
                this.subMeshes[index].refreshBoundingInfo();
                index++;

            }
        }

        this._updateBoundingInfo();
    }

    public function _createGlobalSubMesh():SubMesh {
        var totalVertices = this.getTotalVertices();
        //todo
        //
        if (totalVertices == 0 || this.getIndices().length == 0) {
            return null;
        }

        this.releaseSubMeshes();
        return new SubMesh(0, 0, totalVertices, 0, this.getTotalIndices(), this);
    }

    public function subdivide(count:Float):Void {
        if (count < 1) {
            return;
        }

        var totalIndices = this.getTotalIndices();
        var subdivisionSize = Std.int(totalIndices / count) | 0;
        var offset = 0;

        // Ensure that subdivisionSize is a multiple of 3
        while (subdivisionSize % 3 != 0) {
            subdivisionSize++;
        }

        this.releaseSubMeshes();
        var index = 0;
        while (index < count) {
            if (offset >= totalIndices) {
                break;
            }

            SubMesh.CreateFromIndices(0, offset, Std.int(Math.min(subdivisionSize, totalIndices - offset)), this);

            offset += subdivisionSize;
            index++;

        }

        this.synchronizeInstances();
    }

    public function setVerticesData(kind:Dynamic, data:Dynamic, ?updatable:Bool):Void {
        if (Std.is(kind, Array)) {
            var temp = data;
            data = kind;
            kind = temp;

            trace("Deprecated usage of setVerticesData detected (since v1.12). Current signature is setVerticesData(kind, data, updatable).");
        }

        if (this._geometry == null) {
            var vertexData = new VertexData();
            vertexData.set(data, kind);

            var scene = this.getScene();
            //new Geometry(Geometry.RandomId(), scene.getEngine(), vertexData, updatable, this);
            this._geometry = new Geometry(Geometry.RandomId(), scene.getEngine(), vertexData, updatable, this);
        } else {
            this._geometry.setVerticesData(kind, data, updatable);
        }
    }

    public function updateVerticesData(kind:String, data:Array<Float>, ?updateExtends:Bool, ?makeItUnique:Bool):Void {
        if (this._geometry == null) {
            return;
        }
        if (!makeItUnique) {
            this._geometry.updateVerticesData(kind, data, updateExtends);
        } else {
            this.makeGeometryUnique();
            this.updateVerticesData(kind, data, updateExtends, false);
        }
    }

    public function makeGeometryUnique() {
        if (this._geometry == null) {
            return;
        }
        var geometry = this._geometry.copy(Geometry.RandomId());
        geometry.applyToMesh(this);
    }

    public function setIndices(indices:Array<Int>):Void {
        if (this._geometry == null) {
            var vertexData = new VertexData();
            vertexData.indices = indices;
            var scene = this.getScene();

            new Geometry(Geometry.RandomId(), scene.getEngine(), vertexData, false, this);
        } else {
            this._geometry.setIndices(indices);
        }
    }

    public function _bind(subMesh:SubMesh, effect:Effect, ?wireframe:Bool):Void {

        var engine = this.getScene().getEngine();

        // Wireframe
        var indexToBind = this._geometry.getIndexBuffer();

        if (wireframe) {
            indexToBind = subMesh.getLinesIndexBuffer(this.getIndices(), engine);
        }

        // VBOs
        engine.bindMultiBuffers(this._geometry.getVertexBuffers(), indexToBind, effect);
    }

    public function _draw(subMesh:SubMesh, useTriangles:Bool, ?instancesCount:Int):Void {
        // todo double check this call breaks mac issue with this._geometry.getIndexBuffer this._geometry.getIndexBuffer() == null
        if (this._geometry == null || Lambda.count(this._geometry.getVertexBuffers()) == 0 || this._geometry.getIndexBuffer() == null) {
            return;
        }

        var engine = this.getScene().getEngine();

        // Draw order
        engine.draw(useTriangles, useTriangles ? subMesh.indexStart : 0, useTriangles ? subMesh.indexCount : subMesh.linesIndexCount, instancesCount);
    }

    public function registerBeforeRender(func:Dynamic):Void {
        this._onBeforeRenderCallbacks.push(func);
    }

    public function unregisterBeforeRender(func:Dynamic):Void {
        var index = this._onBeforeRenderCallbacks.indexOf(func);

        if (index > -1) {
            this._onBeforeRenderCallbacks.splice(index, 1);
        }
    }

    public function registerAfterRender(func:Dynamic):Void {
        this._onAfterRenderCallbacks.push(func);
    }

    public function unregisterAfterRender(func:Dynamic):Void {
        var index = this._onAfterRenderCallbacks.indexOf(func);

        if (index > -1) {
            this._onAfterRenderCallbacks.splice(index, 1);
        }
    }

    public function _getInstancesRenderList():InstancesBatch {
        var scene = this.getScene();
        this._batchCache.mustReturn = false;
        this._batchCache.renderSelf = true;
        this._batchCache.visibleInstances = null;

        if (this._visibleInstances) {
            var currentRenderId = scene.getRenderId();
            this._batchCache.visibleInstances = this._visibleInstances[currentRenderId];
            var selfRenderId = this._renderId;

            if (this._batchCache.visibleInstances == null && this._visibleInstances.defaultRenderId) {
                this._batchCache.visibleInstances = this._visibleInstances[this._visibleInstances.defaultRenderId];
                currentRenderId = this._visibleInstances.defaultRenderId;
                selfRenderId = this._visibleInstances.selfDefaultRenderId;
            }

            if (this._batchCache.visibleInstances != null && this._batchCache.visibleInstances.length > 0) {
                if (this._renderIdForInstances == currentRenderId) {
                    this._batchCache.mustReturn = true;
                    return this._batchCache;
                }

                if (currentRenderId != selfRenderId) {
                    this._batchCache.renderSelf = false;
                }

            }
            this._renderIdForInstances = currentRenderId;
        }

        return this._batchCache;
    }

    public function _renderWithInstances(subMesh:SubMesh, wireFrame:Bool, batch:InstancesBatch, effect:Effect, engine:Engine):Void {
        var matricesCount = this.instances.length + 1;
        var bufferSize = matricesCount * 16 * 4;

        while (this._instancesBufferSize < bufferSize) {
            this._instancesBufferSize *= 2;
        }

        if (this._worldMatricesInstancesBuffer == null || this._worldMatricesInstancesBuffer.capacity < this._instancesBufferSize) {
            if (this._worldMatricesInstancesBuffer != null) {
                engine._releaseBuffer(this._worldMatricesInstancesBuffer);
            }

            this._worldMatricesInstancesBuffer = engine.createDynamicVertexBuffer(this._instancesBufferSize);
            #if html5
                this._worldMatricesInstancesArray = new Float32Array(cast this._instancesBufferSize / 4); 
                #else
            this._worldMatricesInstancesArray = new Float32Array(this._instancesBufferSize / 4);
            #end

        }

        var offset = 0;
        var instancesCount = 0;

        var world = this.getWorldMatrix();
        if (batch.renderSelf) {
            world.copyToArray(this._worldMatricesInstancesArray, offset);
            offset += 16;
            instancesCount++;
        }
        var instanceIndex = 0;
        while (instanceIndex < batch.visibleInstances.length) {
            var instance = batch.visibleInstances[instanceIndex];
            instance.getWorldMatrix().copyToArray(this._worldMatricesInstancesArray, offset);
            offset += 16;
            instancesCount++;
            instanceIndex++;

        }

        var offsetLocation0 = effect.getAttributeLocationByName("world0");
        var offsetLocation1 = effect.getAttributeLocationByName("world1");
        var offsetLocation2 = effect.getAttributeLocationByName("world2");
        var offsetLocation3 = effect.getAttributeLocationByName("world3");

        var offsetLocations = [offsetLocation0, offsetLocation1, offsetLocation2, offsetLocation3];

        engine.updateAndBindInstancesBuffer(this._worldMatricesInstancesBuffer, this._worldMatricesInstancesArray, offsetLocations);

        this._draw(subMesh, !wireFrame, instancesCount);

        engine.unBindInstancesBuffer(this._worldMatricesInstancesBuffer, offsetLocations);
    }

    public function render(subMesh:SubMesh):Void {
        var scene = this.getScene();

        // Managing instances
        var batch = this._getInstancesRenderList();

        if (batch.mustReturn) {
            return;
        }

        // Checking geometry state
        if (this._geometry == null || this._geometry.getVertexBuffers() == null || this._geometry.getIndexBuffer() == null) {
            return;
        }

        for (callbackIndex in 0...this._onBeforeRenderCallbacks.length) {
            this._onBeforeRenderCallbacks[callbackIndex]();
        }

        var engine = scene.getEngine();
        var hardwareInstancedRendering = (engine.getCaps().instancedArrays != null) && (batch.visibleInstances != null);

        // Material
        var effectiveMaterial = subMesh.getMaterial();


        // todo hardwareInstancedRendering  effectiveMaterial.isReady(this, hardwareInstancedRendering)
        if (effectiveMaterial == null || !effectiveMaterial.isReady(this)) {
            return;
        }

        // World
        var world:Matrix = this.getWorldMatrix();

        // Material
        //var effectiveMaterial = subMesh.getMaterial();
        //if (effectiveMaterial == null || !effectiveMaterial.isReady(this)) {
        //  return;
        //}
        var effect = effectiveMaterial.getEffect();
        var wireFrame = engine.forceWireframe || effectiveMaterial.wireframe;
        this._bind(subMesh, effect, wireFrame);

        if (Std.is(effectiveMaterial, Material)) {
            effectiveMaterial._preBind();
            effectiveMaterial.bind(world, this);
        }


        /*
            // Bind
            var wireFrame = engine.forceWireframe || effectiveMaterial.wireframe;
            this._bind(subMesh, effect, wireFrame);

            var world = this.getWorldMatrix();
            effectiveMaterial.bind(world, this);
            */

        // Instances rendering
        if (hardwareInstancedRendering) {
            this._renderWithInstances(subMesh, wireFrame, batch, effect, engine);
        } else {
            if (batch.renderSelf) {
                // Draw
                this._draw(subMesh, !wireFrame);
            }
            if (batch.visibleInstances != null) {
                var instanceIndex = 0;
                while (instanceIndex < batch.visibleInstances.length) {
                    var instance = batch.visibleInstances[instanceIndex];

                    // World
                    world = instance.getWorldMatrix();
                    effectiveMaterial.bindOnlyWorldMatrix(world);

                    // Draw
                    this._draw(subMesh, !wireFrame);
                    instanceIndex++;

                }
            }
        }
        // Unbind
        effectiveMaterial.unbind();

        for (callbackIndex in 0...this._onAfterRenderCallbacks.length) {
            this._onAfterRenderCallbacks[callbackIndex]();
        }
    }

    public function getEmittedParticleSystems():Array<ParticleSystem> {
        var results = new Array<ParticleSystem>();
        var index = 0;
        while (index < this.getScene().particleSystems.length) {
            var particleSystem = this.getScene().particleSystems[index];
            if (particleSystem.emitter == this) {
                results.push(particleSystem);
            }
            index++;

        }

        return results;
    }

    public function getHierarchyEmittedParticleSystems():Array<ParticleSystem> {
        var results = new Array<ParticleSystem>();
        var descendants = this.getDescendants();
        descendants.push(this);
        var index = 0;
        while (index < this.getScene().particleSystems.length) {
            var particleSystem = this.getScene().particleSystems[index];
            if (descendants.indexOf(particleSystem.emitter) != -1) {
                results.push(particleSystem);
            }
            index++;

        }

        return results;
    }

    public function getChildren():Array<Node> {
        var results = new Array<Node>();
        var index = 0;
        while (index < this.getScene().meshes.length) {
            var mesh = this.getScene().meshes[index];
            if (mesh.parent == this) {
                results.push(mesh);
            }
            index++;

        }

        return results;
    }

    public function _checkDelayState():Void {
        var that = this;
        var scene = this.getScene();
        if (this._geometry != null) {
            this._geometry.load(scene);
        } else if (that.delayLoadState == Engine.DELAYLOADSTATE_NOTLOADED) {
            that.delayLoadState = Engine.DELAYLOADSTATE_LOADING;

            scene._addPendingData(that);

            /*
                Tools.LoadFile(this.delayLoadingFile, data => {
                    this._delayLoadingFunction(JSON.parse(data), this);
                    this.delayLoadState = Engine.DELAYLOADSTATE_LOADED;
                    scene._removePendingData(this);
                }, () => { }, scene.database);*/

            Tools.LoadFile(_delayLoadingFunction);
        }
    }

    /*
        todo check this
        public function isInFrustum(frustumPlanes:Array<Plane>):Bool {
            if (this._boundingInfo.isInFrustum(frustumPlanes) == null) {
                return false;
            }

            return true;
        }*/


    override function isInFrustum(frustumPlanes:Array<Plane>):Bool {
        if (this.delayLoadState == Engine.DELAYLOADSTATE_LOADING) {
            return false;
        }

        if (!super.isInFrustum(frustumPlanes)) {
            return false;
        }

        this._checkDelayState();

        return true;
    }

    public function setMaterialByID(id:String):Void {
        var materials = this.getScene().materials;
        var index = 0;
        while (index < materials.length) {
            if (materials[index].id == id) {
                this.material = materials[index];
                return;
            }
            index++;

        }

        // Multi
        var multiMaterials = this.getScene().multiMaterials;
        index = 0;
        while (index < multiMaterials.length) {
            if (multiMaterials[index].id == id) {
                this.material = multiMaterials[index];
                return;
            }
            index++;

        }
    }

    public function getAnimatables():Array<IAnimatable> {
        var results = new Array<IAnimatable>();

        if (this.material != null) {
            results.push(this.material);
        }

        return results;
    }

    // Geometry

    public function bakeTransformIntoVertices(transform:Matrix):Void {
        // Position
        if (!this.isVerticesDataPresent(VertexBuffer.PositionKind)) {
            return;
        }

        this._resetPointsArrayCache();

        var data = this.getVerticesData(VertexBuffer.PositionKind);
        var temp = [];
        var index = 0;
        while (index < data.length) {
            Vector3.TransformCoordinates(Vector3.FromArray(data, index), transform).toArray(temp, index);
            index += 3;

        }

        this.setVerticesData(VertexBuffer.PositionKind, temp, this.getVertexBuffer(VertexBuffer.PositionKind).isUpdatable());

        // Normals
        if (!this.isVerticesDataPresent(VertexBuffer.NormalKind)) {
            return;
        }

        data = this.getVerticesData(VertexBuffer.NormalKind);
        index = 0;
        while (index < data.length) {
            Vector3.TransformNormal(Vector3.FromArray(data, index), transform).toArray(temp, index);
            index += 3;

        }

        this.setVerticesData(VertexBuffer.NormalKind, temp, this.getVertexBuffer(VertexBuffer.NormalKind).isUpdatable());
    }


    // Cache
    /* todo
        public function _resetPointsArrayCache() : Void {
            this._positions = null;
        }*/

    override function _generatePointsArray():Bool {
        if (this._positions != null) {
            return true;
        }


        this._positions = new Array<Vector3>();

        var data = this.getVerticesData(VertexBuffer.PositionKind);

        if (data == null) {
            return false;
        }
        var index = 0;
        while (index < data.length) {
            this._positions.push(Vector3.FromArray(data, index));
            index += 3;

        }

        return true;
    }

    // Clone

    override function clone(name:String, newParent:Node = null, doNotCloneChildren:Bool = false):Mesh {
        var resultMesh = new Mesh(name, this.getScene());
        var index = 0;

        // Geometry
        this._geometry.applyToMesh(resultMesh);

        // Deep copy
        Tools.DeepCopy(this, resultMesh, ["_onBeforeRenderCallbacks", "name", "material", "skeleton" ]);

        // Material
        resultMesh.material = this.material;

        // Parent
        if (newParent != null) {
            resultMesh.parent = newParent;
        }

        if (!doNotCloneChildren) {
            // Children
            while (index < this.getScene().meshes.length) {
                var mesh = this.getScene().meshes[index];

                if (mesh.parent == this) {
                    mesh.clone(mesh.name, resultMesh);
                }
                index++;

            }
        }

        // Particles
        index = 0;
        while (index < this.getScene().particleSystems.length) {
            var system = this.getScene().particleSystems[index];

            if (system.emitter == this) {
                system.clone(system.name, resultMesh);
            }
            index++;

        }

        resultMesh.computeWorldMatrix(true);

        return resultMesh;
    }

    // Dispose

    override function dispose(doNotRecurse:Bool = false):Void {
        if (this._geometry != null) {
            // todo investigate
            // this._geometry.releaseForMesh(this, true);
            this._geometry.releaseForMesh(this);
        }

        // Instances
        if (this._worldMatricesInstancesBuffer != null) {
            this.getScene().getEngine()._releaseBuffer(this._worldMatricesInstancesBuffer);
            this._worldMatricesInstancesBuffer = null;
        }

        while (this.instances.length > 0) {
            this.instances[0].dispose();
        }

        super.dispose(doNotRecurse);
    }

    // Geometric tools

    public function convertToFlatShadedMesh() {
        /// <summary>Update normals and vertices to get a flat shading rendering.</summary>
        /// <summary>Warning: This may imply adding vertices to the mesh in order to get exactly 3 vertices per face</summary>

        var kinds:Array<String> = this.getVerticesDataKinds();
        var vbs:Map<String, VertexBuffer> = new Map();
        var data:Map<String, Array<Float>> = new Map();
        var newdata:Map<String, Array<Float>> = new Map();
        var updatableNormals:Bool = false;
        for (kindIndex in 0...kinds.length) {
            var kind = kinds[kindIndex];

            if (kind == VertexBuffer.NormalKind) {
                updatableNormals = this.getVertexBuffer(kind).isUpdatable();
                kinds.remove(kind);
                continue;
            }
        }
        for (kind in kinds) {
            vbs.set(kind, this.getVertexBuffer(kind));
            data.set(kind, vbs.get(kind).getData());
            newdata.set(kind, []);
        }

        // Save previous submeshes
        var previousSubmeshes:Array<SubMesh> = this.subMeshes.slice(0);

        var indices:Array<Int> = this.getIndices();

        // Generating unique vertices per face
        for (index in 0...indices.length) {
            var vertexIndex:Int = indices[index];

            for (kindIndex in 0...kinds.length) {
                var kind = kinds[kindIndex];
                var stride = vbs.get(kind).getStrideSize();

                for (offset in 0...stride) {
                    newdata[kind].push(data[kind][vertexIndex * stride + offset]);
                }
            }
        }

        // Updating faces & normal
        var normals:Array<Float> = [];
        var positions = newdata[VertexBuffer.PositionKind];
        var index:Int = 0;
        while (index < indices.length) {
            indices[index] = index;
            indices[index + 1] = index + 1;
            indices[index + 2] = index + 2;

            var p1 = Vector3.FromArray(positions, index * 3);
            var p2 = Vector3.FromArray(positions, (index + 1) * 3);
            var p3 = Vector3.FromArray(positions, (index + 2) * 3);

            var p1p2 = p1.subtract(p2);
            var p3p2 = p3.subtract(p2);

            var normal = Vector3.Normalize(Vector3.Cross(p1p2, p3p2));

            // Store same normals for every vertex
            for (localIndex in 0...3) {
                normals.push(normal.x);
                normals.push(normal.y);
                normals.push(normal.z);
            }

            index += 3;
        }

        this.setIndices(indices);
        this.setVerticesData(VertexBuffer.NormalKind, normals, updatableNormals);

        // Updating vertex buffers
        for (kindIndex in 0...kinds.length) {
            var kind:String = kinds[kindIndex];
            this.setVerticesData(kind, newdata.get(kind), vbs.get(kind).isUpdatable());
            //this.setVerticesData(newdata.get(kind), kind, vbs.get(kind).isUpdatable());
        }

        // Updating submeshes
        this.subMeshes = new Array<SubMesh>();
        for (submeshIndex in 0...previousSubmeshes.length) {
            var previousOne:SubMesh = previousSubmeshes[submeshIndex];
            var subMesh = new SubMesh(previousOne.materialIndex, previousOne.indexStart, previousOne.indexCount, previousOne.indexStart, previousOne.indexCount, this);
        }
    }

    // Instances

    public function createInstance(name:String):InstancedMesh {
        return new InstancedMesh(name, this);
    }

    public function synchronizeInstances():Void {
        var instanceIndex = 0;
        while (instanceIndex < this.instances.length) {
            var instance = this.instances[instanceIndex];
            instance._syncSubMeshes();
            instanceIndex++;

        }
    }

    // Statics

    public static function CreateBox(name:String, size:Float, scene:Scene, ?updatable:Bool):Mesh {
        var box = new Mesh(name, scene);
        var vertexData = VertexData.CreateBox(size);

        vertexData.applyToMesh(box, updatable);

        return box;
    }

    public static function CreateSphere(name:String, segments:Float, diameter:Float, scene:Scene, ?updatable:Bool):Mesh {
        var sphere = new Mesh(name, scene);
        var vertexData = VertexData.CreateSphere(segments, diameter);

        vertexData.applyToMesh(sphere, updatable);

        return sphere;
    }

    // Cylinder and

    public static function CreateCylinder(name:String, height:Int, diameterTop:Float, diameterBottom:Float, tessellation:Int,subdivisions:Int, scene:Scene, ?updatable:Bool):Mesh {
        var cylinder = new Mesh(name, scene);
        var vertexData = VertexData.CreateCylinder(height, diameterTop, diameterBottom, tessellation, subdivisions);

        vertexData.applyToMesh(cylinder, updatable);

        return cylinder;
    }

    //

    public static function CreateTorus(name:String, diameter:Float, thickness:Float, tessellation:Int, scene:Scene, ?updatable:Bool):Mesh {
        var torus = new Mesh(name, scene);
        var vertexData = VertexData.CreateTorus(diameter, thickness, tessellation);

        vertexData.applyToMesh(torus, updatable);

        return torus;
    }

    public static function CreateTorusKnot(name:String, radius:Float, tube:Float, radialSegments:Float, tubularSegments:Float, p:Float, q:Float, scene:Scene, ?updatable:Bool):Mesh {
        var torusKnot = new Mesh(name, scene);
        var vertexData = VertexData.CreateTorusKnot(radius, tube, radialSegments, tubularSegments, p, q);

        vertexData.applyToMesh(torusKnot, updatable);

        return torusKnot;
    }

    // Plane & ground

    public static function CreatePlane(name:String, size:Float, scene:Scene, ?updatable:Bool):Mesh {
        var plane = new Mesh(name, scene);
        var vertexData = VertexData.CreatePlane(size);

        vertexData.applyToMesh(plane, updatable);

        return plane;
    }

   
    public static function CreateGround(name:String, width:Float, height:Float, subdivisions:Float, scene:Scene, ?updatable:Bool ) : Mesh {
            var ground = new GroundMesh(name, scene);
            ground._setReady(false);
            ground._subdivisions = subdivisions;

            var vertexData = VertexData.CreateGround(width, height, subdivisions);

            vertexData.applyToMesh(ground, updatable);

            ground._setReady(true);

            return ground;
    }

               
    public static function CreateGroundFromHeightMap(name:String, url:String, width:Int, height:Int, subdivisions:Int, minHeight:Int, maxHeight:Int, scene:Scene, ?updatable:Bool ) : GroundMesh {
            var ground = new GroundMesh(name, scene);
            ground._subdivisions = subdivisions;

            ground._setReady(false);

            var onload = function(img:BitmapData, samplingMode:Int) {
                var canvas = img;
                var heightMapWidth = canvas.width;
                var heightMapHeight = canvas.height;


                #if html5
                var buffer = canvas.getPixels(canvas.rect).byteView;
                #else
                var buffer = new UInt8Array(BitmapData.getRGBAPixels(canvas));
                #end
                //var buffer = context.getImageData(0, 0, heightMapWidth, heightMapHeight).data;
                var vertexData = VertexData.CreateGroundFromHeightMap(width, height, subdivisions, minHeight, maxHeight, buffer, heightMapWidth, heightMapHeight);

                vertexData.applyToMesh(ground, updatable);

                ground._setReady(true);
            }

            Tools.LoadImage(url, Texture.TRILINEAR_SAMPLINGMODE, onload);

            return ground;

    }

    public static function MinMax(meshes:Array<AbstractMesh>):Dynamic {
        //var min : Vector3;
        //var max : Vector3;
        var _MinMax:Dynamic = {min:new Vector3(0, 0, 0), max:new Vector3(0, 0, 0)};
        var minVector:Vector3 = new Vector3(0, 0, 0);
        var maxVector:Vector3 = new Vector3(0, 0, 0);
        // haxe does not support for loops with C/JS syntaxt ... unfolding :
        //  for (var i in meshes)
        for (i in 0...meshes.length) {
            var mesh = meshes[i];
            var boundingBox = mesh.getBoundingInfo().boundingBox;
            if (minVector == null) {
                minVector = boundingBox.minimumWorld;
                maxVector = boundingBox.maximumWorld;
                continue;
            }
            minVector.MinimizeInPlace(boundingBox.minimumWorld);
            maxVector.MaximizeInPlace(boundingBox.maximumWorld);
        }
        _MinMax.min = minVector;
        _MinMax.max = maxVector;
        return _MinMax;
    }

    public static function Center(meshesOrMinMaxVector:Dynamic):Vector3 {
        var minMaxVector = meshesOrMinMaxVector.min != null ? meshesOrMinMaxVector : Mesh.MinMax(meshesOrMinMaxVector);
        return Vector3.Center(minMaxVector.min, minMaxVector.max);
    }
}
 