package com.gamestudiohx.babylonhx.mesh;

import com.gamestudiohx.babylonhx.animations.Animation;
import com.gamestudiohx.babylonhx.bones.Skeleton;
import com.gamestudiohx.babylonhx.collisions.Collider;
import com.gamestudiohx.babylonhx.collisions.PickingInfo;
import com.gamestudiohx.babylonhx.materials.Effect;
import com.gamestudiohx.babylonhx.materials.Material;
import com.gamestudiohx.babylonhx.Engine;
import com.gamestudiohx.babylonhx.materials.StandardMaterial;
import com.gamestudiohx.babylonhx.Node;
import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.tools.Tools;
import com.gamestudiohx.babylonhx.tools.math.Vector2;
import com.gamestudiohx.babylonhx.tools.math.Matrix;
import com.gamestudiohx.babylonhx.tools.math.Plane;
import com.gamestudiohx.babylonhx.tools.math.Quaternion;
import com.gamestudiohx.babylonhx.tools.math.Ray;
import com.gamestudiohx.babylonhx.tools.math.Vector3;
import com.gamestudiohx.babylonhx.culling.BoundingInfo;
import com.gamestudiohx.babylonhx.particles.ParticleSystem;
import com.gamestudiohx.babylonhx.mesh.Geometry;
import com.gamestudiohx.babylonhx.mesh.VertexData;
import com.gamestudiohx.babylonhx.culling.octrees.Octree;
import openfl.display.BitmapData;
import haxe.io.BufferInput;

import openfl.gl.GLBuffer;
import openfl.utils.Float32Array;

/**
 * Port of BabylonJs project - http://www.babylonjs.com/
 * ...
 * @author Krtolica Vujadin
 */

typedef MeshCache = {
localMatrixUpdated:Null<Bool>, position:Null<Vector3>, scaling:Null<Vector3>, rotation:Null<Vector3>, rotationQuaternion:Null<Quaternion>, pivotMatrixUpdated:Null<Bool>
}

class BabylonGLBuffer {

    public var buffer:GLBuffer;
    public var references:Int;
    public var capacity:Int;

    public function new(buffer:GLBuffer, _capacity:Int = 0) {
        this.buffer = buffer;
        this.references = 1;
        this.capacity = _capacity;
    }

}

class AbstractMesh extends Node {

    public static var BILLBOARDMODE_NONE:Int = 0;
    public static var BILLBOARDMODE_X:Int = 1;
    public static var BILLBOARDMODE_Y:Int = 2;
    public static var BILLBOARDMODE_Z:Int = 4;
    public static var BILLBOARDMODE_ALL:Int = 7;


    public var rotation:Vector3;
    public var scaling:Vector3;
    public var rotationQuaternion:Quaternion;
    public var subMeshes:Array<SubMesh>;
    public var animations:Array<Animation>;
    public var infiniteDistance:Bool;

    // privates ?
    //public var delayLoadState:Int;
    //public var delayLoadingFile:String;
    public var material:Dynamic; // Material or MultiMaterial
    public var isVisible:Bool;
    public var isPickable:Bool;
    public var visibility:Float; // Int ?
    public var billboardMode:Int;
    public var checkCollisions:Bool;
    public var receiveShadows:Bool;

    public var onDispose:Void -> Void;
    public var skeleton:Skeleton;
    public var renderingGroupId:Int;

    public var _animationStarted:Bool; //??
    public var _scaleFactor:Float; //??
    public var _isDisposed:Bool;
    public var _totalVertices:Int;
    public var _worldMatrix:Matrix;
    public var _pivotMatrix:Matrix;
    public var _vertexStrideSize:Int; // Float ?
    public var _indices:Array<Int>; //??
    public var _renderId:Int;
    //public var _onBeforeRenderCallbacks:Array<Dynamic>;		// TODO
    public var _localScaling:Matrix;
    public var _localRotation:Matrix;
    public var _localTranslation:Matrix;
    public var _localBillboard:Matrix;
    public var _localPivotScaling:Matrix;
    public var _localPivotScalingRotation:Matrix;
    public var _localWorld:Matrix;
    public var _rotateYByPI:Matrix;

    public var _boundingInfo:BoundingInfo;
    public var _collisionsTransformMatrix:Matrix;
    public var _collisionsScalingMatrix:Matrix;
    private var _absolutePosition:Vector3;
    private var _isDirty:Bool = false;
    //public var _currentRenderId:Int; //??

    public var _positions:Array<Vector3>;

    public var _vertexBuffers:Map<String, VertexBuffer>; // TODO - this can be both VertexBuffer and BabylonGLBuffer
    public var _vertexBuffersB:Map<String, BabylonGLBuffer>; // so this one is created to separate these two ...
    public var _delayInfo:Array<String>;
    public var _indexBuffer:BabylonGLBuffer;

    public var parentId(get, null):String;
    public var showSubMeshesBoundingBox = false;

    public var _submeshesOctree:Dynamic;


    public function new(name:String, scene:Scene) {
        super(scene);

        this.name = name;
        this.id = name;
        this._scene = scene;

        this._totalVertices = 0;
        this._worldMatrix = Matrix.Identity();

        scene.meshes.push(this);

        this.position = new Vector3(0, 0, 0);
        this.rotation = new Vector3(0, 0, 0);
        this.rotationQuaternion = null;
        this.scaling = new Vector3(1, 1, 1);

        this._pivotMatrix = Matrix.Identity();

        this._indices = new Array<Int>();
        this.subMeshes = new Array<SubMesh>();
        this._submeshesOctree = null;

        this._renderId = 0;

        //this._onBeforeRenderCallbacks = new Array<Dynamic>();

        // Animations
        this.animations = new Array<Animation>();

        // Cache
        this._positions = null;
        this._cache = {
        localMatrixUpdated: false, position: Vector3.Zero(), scaling: Vector3.Zero(), rotation: Vector3.Zero(), rotationQuaternion: new Quaternion(0, 0, 0, 0), pivotMatrixUpdated: null
        };
        //this._initCache();

        this._localScaling = Matrix.Zero();
        this._localRotation = Matrix.Zero();
        this._localTranslation = Matrix.Zero();
        this._localBillboard = Matrix.Zero();
        this._localPivotScaling = Matrix.Zero();
        this._localPivotScalingRotation = Matrix.Zero();
        this._localWorld = Matrix.Zero();
        this._worldMatrix = Matrix.Zero();
        this._rotateYByPI = Matrix.RotationY(Math.PI);

        this._collisionsTransformMatrix = Matrix.Zero();
        this._collisionsScalingMatrix = Matrix.Zero();

        this._absolutePosition = Vector3.Zero();

        //this.delayLoadState = Engine.DELAYLOADSTATE_NONE;
        this.material = null;
        this.isVisible = true;
        this.isPickable = true;
        this.visibility = 1.0;
        this.billboardMode = AbstractMesh.BILLBOARDMODE_NONE;
        this.checkCollisions = false;
        this.receiveShadows = false;

        this._isDisposed = false;
        this.onDispose = null;

        this.skeleton = null;

        this.renderingGroupId = 0;

        this.infiniteDistance = false;
    }

    public function _resetPointsArrayCache() {
        this._positions = null;
    }

    public function _generatePointsArray():Bool {
        return false;
    }


    inline public function _collideForSubMesh(subMesh:SubMesh, transformMatrix:Matrix, collider:Collider) {
        this._generatePointsArray();

        // Transformation
        if (subMesh._lastColliderWorldVertices == null || !subMesh._lastColliderTransformMatrix.equals(transformMatrix)) {
            subMesh._lastColliderTransformMatrix = transformMatrix;
            subMesh._lastColliderWorldVertices = new Array<Vector3>();
            var start = subMesh.verticesStart;
            var end = (subMesh.verticesStart + subMesh.verticesCount);
            for (i in start...end) {
                subMesh._lastColliderWorldVertices.push(Vector3.TransformCoordinates(this._positions[i], transformMatrix));
            }
        }
        // todo find out why this does not work! fixed
        // Collide
        collider._collide(subMesh, subMesh._lastColliderWorldVertices, this.getIndices(), subMesh.indexStart, subMesh.indexStart + subMesh.indexCount, subMesh.verticesStart);
    }

    inline public function _processCollisionsForSubModels(collider:Collider, transformMatrix:Matrix) {
        for (index in 0...this.subMeshes.length) {
            var subMesh = this.subMeshes[index];

            // Bounding test
            if (this.subMeshes.length > 1 && !subMesh._checkCollision(collider))
                continue;

            this._collideForSubMesh(subMesh, transformMatrix, collider);
        }
    }

    inline public function _checkCollision(collider:Collider) {
        // Bounding box test
        if (this._boundingInfo._checkCollision(collider)) {
            // Transformation matrix
            Matrix.ScalingToRef(1.0 / collider.radius.x, 1.0 / collider.radius.y, 1.0 / collider.radius.z, this._collisionsScalingMatrix);
            this._worldMatrix.multiplyToRef(this._collisionsScalingMatrix, this._collisionsTransformMatrix);

            this._processCollisionsForSubModels(collider, this._collisionsTransformMatrix);
        }
    }

    public function isInFrustum(frustumPlanes:Array<Plane>):Bool {
        if (!this._boundingInfo.isInFrustum(frustumPlanes)) {
            return false;
        }

        return true;
    }

    public function getBoundingInfo():BoundingInfo {
        return this._boundingInfo;
    }

    public function _preActivate():Void {
    }

    public function _activate(renderId:Int):Void {
        this._renderId = renderId;
    }

    public function getScene():Scene {
        return this._scene;
    }

    function get_parentId():String {
        if (this.parent != null) {
            return this.parent.id;
        }
        return "";
    }

    override inline public function getWorldMatrix():Matrix {
        if (this._currentRenderId != this._scene.getRenderId()) {
        	//trace('getworldmatrix');
            this.computeWorldMatrix();
        }
        //trace(this._worldMatrix);
        return this._worldMatrix;
    }

    public function getWorldMatrixFromCache():Matrix {
        return this._worldMatrix;
    }

    public function getTotalVertices():Int {
        return this._totalVertices;
    }

    public function getabsolutePosition():Vector3 {
        return this._absolutePosition;
    }

    inline public function getAbsolutePosition():Vector3 {
        this.computeWorldMatrix();
        return this._absolutePosition;
    }

    // param: absolutePosition can be Array<Float> or Vector3

    public function setAbsolutePosition(absolutePosition:Dynamic = null) {
        if (absolutePosition == null) {
            return;
        }

        var absolutePositionX:Float = 0;
        var absolutePositionY:Float = 0;
        var absolutePositionZ:Float = 0;

        if (Std.is(absolutePosition, Array)) {
            if (absolutePosition.length < 3) {
                return;
            }
            absolutePositionX = absolutePosition[0];
            absolutePositionY = absolutePosition[1];
            absolutePositionZ = absolutePosition[2];
        } else { // its Vector3
            absolutePositionX = absolutePosition.x;
            absolutePositionY = absolutePosition.y;
            absolutePositionZ = absolutePosition.z;
        }

        // worldMatrix = pivotMatrix * scalingMatrix * rotationMatrix * translateMatrix * parentWorldMatrix
        // => translateMatrix = invertRotationMatrix * invertScalingMatrix * invertPivotMatrix * worldMatrix * invertParentWorldMatrix

        // get this matrice before the other ones since
        // that will update them if they have to be updated
        // Todo thoughly test this 
        /*
        var worldMatrix = this.getWorldMatrix().clone();

        worldMatrix.m[12] = absolutePositionX;
        worldMatrix.m[13] = absolutePositionY;
        worldMatrix.m[14] = absolutePositionZ;

        var invertRotationMatrix = this._localRotation.clone();
        invertRotationMatrix.invert();

        var invertScalingMatrix = this._localScaling.clone();
        invertScalingMatrix.invert();

        var invertPivotMatrix = this._pivotMatrix.clone();
        invertPivotMatrix.invert();

        var translateMatrix = invertRotationMatrix.multiply(invertScalingMatrix);

        translateMatrix.multiplyToRef(invertPivotMatrix, invertScalingMatrix); // reuse matrix
        invertScalingMatrix.multiplyToRef(worldMatrix, translateMatrix);
        */

        if (this.parent != null) {
            var invertParentWorldMatrix = this.parent.getWorldMatrix().clone();
            invertParentWorldMatrix.invert();

            var worldPosition = new Vector3(absolutePositionX, absolutePositionY, absolutePositionZ);

            this.position = Vector3.TransformCoordinates(worldPosition, invertParentWorldMatrix);
            /*
            translateMatrix.multiplyToRef(invertParentWorldMatrix, invertScalingMatrix); // reuse matrix
            translateMatrix = invertScalingMatrix;*/
        } else {
            this.position.x = absolutePositionX;
            this.position.y = absolutePositionY;
            this.position.z = absolutePositionZ;
        }


    }

    public function rotate(axis:Vector3, amount:Float, space:Space):Void {
        if (this.rotationQuaternion == null) {
            this.rotationQuaternion = Quaternion.RotationYawPitchRoll(this.rotation.y, this.rotation.x, this.rotation.z);
            this.rotation = Vector3.Zero();
        }

        if (space == null || space == Space.LOCAL) {
            var rotationQuaternion = Quaternion.RotationAxis(axis, amount);
            this.rotationQuaternion = this.rotationQuaternion.multiply(rotationQuaternion);
        } else {
            if (this.parent != null) {
                var invertParentWorldMatrix = this.parent.getWorldMatrix().clone();
                invertParentWorldMatrix.invert();

                axis = Vector3.TransformNormal(axis, invertParentWorldMatrix);
            }
            rotationQuaternion = Quaternion.RotationAxis(axis, amount);
            this.rotationQuaternion = rotationQuaternion.multiply(this.rotationQuaternion);
        }
    }

    public function translate(axis:Vector3, distance:Float, space:Space):Void {
        var displacementVector = axis.scale(distance);

        if (space != null || space == Space.LOCAL) {
            var tempV3 = this.getLocalTranslation().add(displacementVector);
            this.setLocalTranslation(tempV3);
        } else {
            this.setAbsolutePosition(this.getAbsolutePosition().add(displacementVector));
        }
    }


    public function getVerticesData(kind:String):Array<Float> /*Array<Dynamic>*/ { // TODO - Float32Array ??
        return null;
    }

    public function isVerticesDataPresent(kind:String):Bool {
        return false;
    }

    public function getTotalIndicies():Int {
        return this._indices.length;
    }

    public function getIndices():Array<Int> {
        return this._indices;
    }

    public function getVertexStrideSize():Float {
        return this._vertexStrideSize;
    }

    inline public function setPivotMatrix(matrix:Matrix) {
        this._pivotMatrix = matrix;
        this._cache.pivotMatrixUpdated = true;
    }

    public function getPivotMatrix():Matrix {
        return this._pivotMatrix;
    }

    override public function isSynchronized(updateCache:Bool = true):Bool {
        if (this._isDirty) {
            return false;
        }

        if (this.billboardMode != AbstractMesh.BILLBOARDMODE_NONE)
            return false;

        if (this._cache.pivotMatrixUpdated) {
            return false;
        }

        if (this.infiniteDistance) {
            return false;
        }

        if (!this._cache.position.equals(this.position))
            return false;

        if (this.rotationQuaternion != null) {
            if (!this._cache.rotationQuaternion.equals(this.rotationQuaternion))
                return false;
        } else {
            if (!this._cache.rotation.equals(this.rotation))
                return false;
        }

        if (!this._cache.scaling.equals(this.scaling))
            return false;

        return true;
    }

    public function isAnimated():Bool {
        return this._animationStarted;
    }

    public function isDisposed():Bool {
        return this._isDisposed;
    }

    override public function _initCache() {
        this._cache.localMatrixUpdated = false;
        this._cache.position = Vector3.Zero();
        this._cache.scaling = Vector3.Zero();
        this._cache.rotation = Vector3.Zero();
        this._cache.rotationQuaternion = new Quaternion(0, 0, 0, 0);
        this._cache.pivotMatrixUpdated = null;
    }

    public function markAsDirty(property:String) {
        //todo
        if (property == "rotation") {
            this.rotationQuaternion = null;
        }
        this._childrenFlag = 1;
        this._isDirty = true;
    }

    public inline function refreshBoudningInfo() {
        var data = this.getVerticesData(VertexBuffer.PositionKind);

        if (data == null) {
            return;
        }

        var extend = Tools.ExtractMinAndMax(data, 0, this._totalVertices);
        this._boundingInfo = new BoundingInfo(extend.minimum, extend.maximum);

        for (index in 0...this.subMeshes.length) {
            this.subMeshes[index].refreshBoundingInfo();
        }

        this._updateBoundingInfo();
    }

    public inline function _updateBoundingInfo() {
        if (this._boundingInfo != null) {
            this._scaleFactor = Math.max(this.scaling.x, this.scaling.y);
            this._scaleFactor = Math.max(this._scaleFactor, this.scaling.z);

            if (this.parent != null && Reflect.field(this.parent, "_scaleFactor") != null)
                this._scaleFactor = this._scaleFactor * Reflect.field(this.parent, "_scaleFactor");

            this._boundingInfo._update(this._worldMatrix, this._scaleFactor);

            for (subIndex in 0...this.subMeshes.length) {
                var subMesh = this.subMeshes[subIndex];

                subMesh.updateBoundingInfo(this._worldMatrix, this._scaleFactor);
            }
        }
    }

    public inline function computeWorldMatrix(force:Bool = false):Matrix {

    	//todo test thoughly force
        var ret = this._worldMatrix;
        if (!force && (this._currentRenderId == this._scene.getRenderId() || this.isSynchronized())) {
            return this._worldMatrix;
        }

        this._cache.position.copyFrom(this.position);
        this._cache.scaling.copyFrom(this.scaling);
        this._cache.pivotMatrixUpdated = false;
        this._currentRenderId = this._scene.getRenderId();
        //this._isDirty = false;

        // Scaling
        Matrix.ScalingToRef(this.scaling.x, this.scaling.y, this.scaling.z, this._localScaling);

        // Rotation
        if (this.rotationQuaternion != null) {
            this.rotationQuaternion.toRotationMatrix(this._localRotation);
            this._cache.rotationQuaternion.copyFrom(this.rotationQuaternion);
        } else {
            Matrix.RotationYawPitchRollToRef(this.rotation.y, this.rotation.x, this.rotation.z, this._localRotation);
            this._cache.rotation.copyFrom(this.rotation);
        }

        // Translation
        if (this.infiniteDistance && this.parent == null) {
            var camera = this._scene.activeCamera;
            /*var cameraWorldMatrix = camera.getWorldMatrix();

            var cameraGlobalPosition = new Vector3(cameraWorldMatrix.m[12], cameraWorldMatrix.m[13], cameraWorldMatrix.m[14]);*/

            Matrix.TranslationToRef(this.position.x + camera.position.x, this.position.y + camera.position.y, this.position.z + camera.position.z, this._localTranslation);
        } else {
            Matrix.TranslationToRef(this.position.x, this.position.y, this.position.z, this._localTranslation);
        }

        // Composing transformations
        this._pivotMatrix.multiplyToRef(this._localScaling, this._localPivotScaling);
        this._localPivotScaling.multiplyToRef(this._localRotation, this._localPivotScalingRotation);

        // Billboarding
        if (this.billboardMode != AbstractMesh.BILLBOARDMODE_NONE) {
            var localPosition:Vector3 = this.position.clone();
            var zero:Vector3 = this._scene.activeCamera.position.clone();

            if (this.parent != null && this.parent.position != null) {
                localPosition.addInPlace(this.parent.position);
                Matrix.TranslationToRef(localPosition.x, localPosition.y, localPosition.z, this._localTranslation);
            }

            if (this.billboardMode & AbstractMesh.BILLBOARDMODE_ALL == AbstractMesh.BILLBOARDMODE_ALL) {
                zero = this._scene.activeCamera.position;
            } else {
                if ((this.billboardMode & AbstractMesh.BILLBOARDMODE_X) != 0)
                    zero.x = localPosition.x + Engine.epsilon;
                if ((this.billboardMode & AbstractMesh.BILLBOARDMODE_Y) != 0)
                    zero.y = localPosition.y + Engine.epsilon;
                if ((this.billboardMode & AbstractMesh.BILLBOARDMODE_Z) != 0)
                    zero.z = localPosition.z + Engine.epsilon;
            }

            Matrix.LookAtLHToRef(localPosition, zero, Vector3.Up(), this._localBillboard);
            this._localBillboard.m[12] = this._localBillboard.m[13] = this._localBillboard.m[14] = 0;

            this._localBillboard.invert();

            this._localPivotScalingRotation.multiplyToRef(this._localBillboard, this._localWorld);
            this._rotateYByPI.multiplyToRef(this._localWorld, this._localPivotScalingRotation);
        }

        this._localPivotScalingRotation.multiplyToRef(this._localTranslation, this._localWorld);
        // Parent
        if (this.parent != null && this.parent.getWorldMatrix() != null && this.billboardMode == AbstractMesh.BILLBOARDMODE_NONE) {
            /*this._localPivotScalingRotation.multiplyToRef(this._localTranslation, this._localWorld);
			var parentWorld = this.parent.getWorldMatrix();
			this._localWorld.multiplyToRef(parentWorld, this._worldMatrix);*/
            this._localWorld.multiplyToRef(this.parent.getWorldMatrix(), this._worldMatrix);
        } else {

            this._worldMatrix.copyFrom(this._localWorld);
            //this._localPivotScalingRotation.multiplyToRef(this._localTranslation, this._worldMatrix);
        }

        // Bounding info
        this._updateBoundingInfo();

        // Absolute position
        this._absolutePosition.copyFromFloats(this._worldMatrix.m[12], this._worldMatrix.m[13], this._worldMatrix.m[14]);
        return this._worldMatrix;
    }

    inline public function locallyTranslate(vector3:Vector3):Void {
        this.computeWorldMatrix();

        this.position = Vector3.TransformCoordinates(vector3, this._localWorld);
    }

    inline public function lookAt(targetPoint:Vector3, yawCor:Float = 0, pitchCor:Float = 0, rollCor:Float = 0):Void {
        /// <summary>Orients a mesh towards a target point. Mesh must be drawn facing user.</summary>
        /// <param name="targetPoint" type="BABYLON.Vector3">The position (must be in same space as current mesh) to look at</param>
        /// <param name="yawCor" type="Number">optional yaw (y-axis) correction in radians</param>
        /// <param name="pitchCor" type="Number">optional pitch (x-axis) correction in radians</param>
        /// <param name="rollCor" type="Number">optional roll (z-axis) correction in radians</param>
        /// <returns>Mesh oriented towards targetMesh</returns>


        var dv = targetPoint.subtract(this.position);
        var yaw = -Math.atan2(dv.z, dv.x) - Math.PI / 2;
        var len = Math.sqrt(dv.x * dv.x + dv.z * dv.z);
        var pitch = Math.atan2(dv.y, len);
        this.rotationQuaternion = Quaternion.RotationYawPitchRoll(yaw + yawCor, pitch + pitchCor, rollCor);
    }


    inline public function bindAndDraw(subMesh:SubMesh, effect:Effect, wireframe:Bool) {
        // todo
        var engine:Engine = this._scene.getEngine();

        // Wireframe
        var indexToBind = this._indexBuffer;
        var useTriangles = true;

        if (wireframe) {
            indexToBind = subMesh.getLinesIndexBuffer(this._indices, engine);
            useTriangles = false;
        }

        // VBOs
        engine.bindMultiBuffers(this._vertexBuffers, indexToBind, effect);

        // Draw order
        engine.draw(useTriangles, useTriangles ? subMesh.indexStart : 0, useTriangles ? subMesh.indexCount : subMesh.linesIndexCount);
    }

    inline public function setLocalTranslation(vector3:Vector3) {
        this.computeWorldMatrix();
        var worldMatrix = this._worldMatrix.clone();
        worldMatrix.setTranslation(Vector3.Zero());

        this.position = Vector3.TransformCoordinates(vector3, worldMatrix);
    }

    inline public function getLocalTranslation():Vector3 {
        this.computeWorldMatrix();
        var invWorldMatrix = this._worldMatrix.clone();
        invWorldMatrix.setTranslation(Vector3.Zero());
        invWorldMatrix.invert();

        return Vector3.TransformCoordinates(this.position, invWorldMatrix);
    }
   
	inline public function createOrUpdateSubmeshesOctree(maxCapacity = 64, maxDepth = 2): Array<AbstractMesh> {
		   //Todo
		    trace(this.position);
            if (this._submeshesOctree == null) {
                this._submeshesOctree = new Octree(maxCapacity);
            }

            this.computeWorldMatrix(true);            

            // Update octree
            var bbox = this.getBoundingInfo().boundingBox;
            this._submeshesOctree.update(bbox.minimumWorld, bbox.maximumWorld, cast this.subMeshes);

            return this._submeshesOctree;
    }

    inline public function intersectsMesh(mesh:Mesh, precise:Bool):Bool {
        var ret = false;
        if (this._boundingInfo == null || mesh._boundingInfo == null) {
            ret = false;
        } else {
            ret = this._boundingInfo.intersects(mesh._boundingInfo, precise);
        }
        return ret;
    }

    inline public function intersectsPoint(point:Vector3):Bool {
        var ret = false;
        if (this._boundingInfo != null) {
            ret = this._boundingInfo.intersectsPoint(point);
        }
        return ret;
    }

    public function intersects(ray:Ray, fastCheck:Bool = false):PickingInfo {
        var pickingInfo = new PickingInfo();

        if (this._boundingInfo == null || !ray.intersectsSphere(this._boundingInfo.boundingSphere) || !ray.intersectsBox(this._boundingInfo.boundingBox)) {
            return pickingInfo;
        }

        this._generatePointsArray();

        var distance:Float = Math.POSITIVE_INFINITY;

        for (index in 0...this.subMeshes.length) {
            var subMesh = this.subMeshes[index];

            // Bounding test
            if (this.subMeshes.length > 1 && !subMesh.canIntersects(ray))
                continue;

            var currentDistance = subMesh.intersects(ray, this._positions, this._indices, fastCheck);

            if (currentDistance > 0) {
                if (fastCheck || currentDistance < distance) {
                    distance = currentDistance;

                    if (fastCheck) {
                        break;
                    }
                }
            }
        }

        if (distance >= 0 && distance < Math.POSITIVE_INFINITY) {
            // Get picked point
            var world:Matrix = this.getWorldMatrix();
            var worldOrigin:Vector3 = Vector3.TransformCoordinates(ray.origin, world);
            var direction:Vector3 = ray.direction.clone();
            direction.normalize();
            direction = direction.scale(distance);
            var worldDirection:Vector3 = Vector3.TransformNormal(direction, world);

            var pickedPoint:Vector3 = worldOrigin.add(worldDirection);

            // Return result
            pickingInfo.hit = true;
            pickingInfo.distance = Vector3.Distance(worldOrigin, pickedPoint);
            pickingInfo.pickedPoint = pickedPoint;
            pickingInfo.pickedMesh = cast(this, Mesh);
            return pickingInfo;
        }

        return pickingInfo;
    }

    public function clone(name:String, newParent:Node = null, doNotCloneChildren:Bool = false):AbstractMesh {
        return null;
    }


    public function releaseSubMeshes():Void {
        if (this.subMeshes != null) {
            while (this.subMeshes.length > 0) {
                if (Tools.isDebug) {
                    trace('releaseSubMeshes');
                }
                this.subMeshes[0].dispose();
            }
        } else {
            if (Tools.isDebug) {
                trace('new releaseSubMeshes');
            }
            this.subMeshes = new Array<SubMesh>();
        }
    }

    public function dispose(doNotRecurse:Bool = false) {
        if (this._vertexBuffers != null) {
            for (key in this._vertexBuffers.keys()) {
                this._vertexBuffers.get(key).dispose();
                this._vertexBuffers.remove(key);
            }
            this._vertexBuffers = null;
        }

        if (this._indexBuffer != null) {
            this._scene.getEngine()._releaseBuffer(this._indexBuffer);
            this._indexBuffer = null;
        }

        // Remove from scene
        //var index = this._scene.meshes.indexOf(this);
        //this._scene.meshes.splice(index, 1);
        this._scene.meshes.remove(this);

        if (!doNotRecurse) {
            // Particles
            var index:Int = 0;
            while (index < this._scene.particleSystems.length) {
                if (this._scene.particleSystems[index].emitter == this) {
                    this._scene.particleSystems[index].dispose();
                    index--;
                }
                index++;
            }

            // Children
            var objects = this._scene.meshes.slice(0);
            for (index in 0...objects.length) {
                if (objects[index].parent == this) {
                    objects[index].dispose();
                }
            }
        }

        this._isDisposed = true;

        // Callback
        if (this.onDispose != null) {
            this.onDispose();
        }
    }


    public static function ComputeNormal(positions:Array<Float>, normals:Array<Float>, indices:Array<Int>) {
        var positionVectors:Array<Vector3> = [];
        var facesOfVertices:Array<Array<Int>> = [];

        var index:Int = 0;

        while (index < positions.length) {
            var vector3 = new Vector3(positions[index], positions[index + 1], positions[index + 2]);
            positionVectors.push(vector3);
            facesOfVertices.push([]);
            index += 3;
        }

        // Compute normals
        var facesNormals:Array<Vector3> = [];
        for (index in 0...Std.int(indices.length / 3)) {
            var i1 = indices[index * 3];
            var i2 = indices[index * 3 + 1];
            var i3 = indices[index * 3 + 2];

            var p1 = positionVectors[i1];
            var p2 = positionVectors[i2];
            var p3 = positionVectors[i3];

            var p1p2 = p1.subtract(p2);
            var p3p2 = p3.subtract(p2);

            facesNormals[index] = Vector3.Normalize(Vector3.Cross(p1p2, p3p2));
            facesOfVertices[i1].push(index);
            facesOfVertices[i2].push(index);
            facesOfVertices[i3].push(index);
        }

        for (index in 0...positionVectors.length) {
            var faces:Array<Int> = facesOfVertices[index];

            var normal:Vector3 = Vector3.Zero();
            for (faceIndex in 0...faces.length) {
                normal.addInPlace(facesNormals[faces[faceIndex]]);
            }

            normal = Vector3.Normalize(normal.scale(1.0 / faces.length));

            normals[index * 3] = normal.x;
            normals[index * 3 + 1] = normal.y;
            normals[index * 3 + 2] = normal.z;
        }
    }

}
