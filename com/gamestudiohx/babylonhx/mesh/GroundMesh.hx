package com.gamestudiohx.babylonhx.mesh;

import com.gamestudiohx.babylonhx.mesh.VertexData;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
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


class GroundMesh extends Mesh {

        public var generateOctree = false;
        private var _worldInverse = new Matrix();
        public var _subdivisions: Float;

        public function new(name:String, scene:Scene) {
            super(name, scene);
        }

        public function subdivisions():Float {
            return this._subdivisions;
        }

        public function optimize(chunksCount:Int): Void {
            this.subdivide(this._subdivisions);
            this.createOrUpdateSubmeshesOctree(32);
        }

        public function getHeightAtCoordinates(x: Int, z: Int):Float {
            var ray = new Ray(new Vector3(x, this.getBoundingInfo().boundingBox.maximumWorld.y + 1, z), new Vector3(0, -1, 0));

            this.getWorldMatrix().invertToRef(this._worldInverse);

            ray = Ray.Transform(ray, this._worldInverse);

            var pickInfo = this.intersects(ray);

            if (pickInfo.hit) {
                return pickInfo.pickedPoint.y;
            }

            return 0;
        }
}
