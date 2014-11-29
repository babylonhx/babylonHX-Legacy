import com.gamestudiohx.babylonhx.Node;
import com.gamestudiohx.babylonhx.Scene;
import com.gamestudiohx.babylonhx.Engine;
import com.gamestudiohx.babylonhx.animations.Animation;
import com.gamestudiohx.babylonhx.bones.Bone;
import com.gamestudiohx.babylonhx.bones.Skeleton;
import com.gamestudiohx.babylonhx.cameras.Camera;
import com.gamestudiohx.babylonhx.cameras.ArcRotateCamera;
import com.gamestudiohx.babylonhx.cameras.FreeCamera;
import com.gamestudiohx.babylonhx.cameras.TouchCamera;
import com.gamestudiohx.babylonhx.collisions.Collider;
import com.gamestudiohx.babylonhx.collisions.CollisionPlane;
import com.gamestudiohx.babylonhx.collisions.PickingInfo;
import com.gamestudiohx.babylonhx.culling.octrees.Octree;
import com.gamestudiohx.babylonhx.culling.octrees.OctreeBlock;
import com.gamestudiohx.babylonhx.culling.BoundingSphere;
import com.gamestudiohx.babylonhx.culling.BoundingInfo;
import com.gamestudiohx.babylonhx.culling.BoundingBox;
import com.gamestudiohx.babylonhx.layer.Layer;
import com.gamestudiohx.babylonhx.lensflare.LensFlare;
import com.gamestudiohx.babylonhx.lensflare.LensFlareSystem;
import com.gamestudiohx.babylonhx.lights.shadows.ShadowGenerator;
import com.gamestudiohx.babylonhx.lights.DirectionalLight;
import com.gamestudiohx.babylonhx.lights.PointLight;
import com.gamestudiohx.babylonhx.lights.HemisphericLight;
import com.gamestudiohx.babylonhx.lights.SpotLight;
import com.gamestudiohx.babylonhx.lights.Light;
import com.gamestudiohx.babylonhx.materials.textures.BaseTexture;
import com.gamestudiohx.babylonhx.materials.textures.CubeTexture;
import com.gamestudiohx.babylonhx.materials.textures.DynamicTexture;
import com.gamestudiohx.babylonhx.materials.textures.MirrorTexture;
import com.gamestudiohx.babylonhx.materials.textures.RenderTargetTexture;
import com.gamestudiohx.babylonhx.materials.textures.Texture;
import com.gamestudiohx.babylonhx.materials.Effect;
import com.gamestudiohx.babylonhx.materials.Material;
import com.gamestudiohx.babylonhx.materials.MultiMaterial;
import com.gamestudiohx.babylonhx.materials.ShaderMaterial;
import com.gamestudiohx.babylonhx.materials.StandardMaterial;
import com.gamestudiohx.babylonhx.mesh.AbstractMesh;
import com.gamestudiohx.babylonhx.mesh.SubMesh;
import com.gamestudiohx.babylonhx.mesh.Geometry;
import com.gamestudiohx.babylonhx.mesh.InstancedMesh;
import com.gamestudiohx.babylonhx.mesh.Mesh;
import com.gamestudiohx.babylonhx.mesh.VertexBuffer;
import com.gamestudiohx.babylonhx.mesh.VertexData;
import com.gamestudiohx.babylonhx.particles.Particle;
import com.gamestudiohx.babylonhx.particles.ParticleSystem;
import com.gamestudiohx.babylonhx.postprocess.BlackAndWhitePostProcess;
import com.gamestudiohx.babylonhx.postprocess.BlurPostProcess;
import com.gamestudiohx.babylonhx.postprocess.ConvolutionPostProcess;
import com.gamestudiohx.babylonhx.postprocess.FxaaPostProcess;
import com.gamestudiohx.babylonhx.postprocess.PassPostProcess;
import com.gamestudiohx.babylonhx.postprocess.PostProcess;
import com.gamestudiohx.babylonhx.postprocess.PostProcessManager;
import com.gamestudiohx.babylonhx.postprocess.RefractionPostProcess;
import com.gamestudiohx.babylonhx.rendering.BoundingBoxRenderer;
import com.gamestudiohx.babylonhx.rendering.RenderingGroup;
import com.gamestudiohx.babylonhx.rendering.RenderingManager;
import com.gamestudiohx.babylonhx.sprites.Sprite;
import com.gamestudiohx.babylonhx.sprites.SpriteManager;
import com.gamestudiohx.babylonhx.tools.math.Color4;
import com.gamestudiohx.babylonhx.tools.math.Vector3;
import com.gamestudiohx.babylonhx.tools.math.Color3;
import com.gamestudiohx.babylonhx.tools.math.Frustum;
import com.gamestudiohx.babylonhx.tools.math.Matrix;
import com.gamestudiohx.babylonhx.tools.math.Plane;
import com.gamestudiohx.babylonhx.tools.math.Quaternion;
import com.gamestudiohx.babylonhx.tools.math.Ray;
import com.gamestudiohx.babylonhx.tools.math.Vector2;
import com.gamestudiohx.babylonhx.tools.math.Viewport;
import com.gamestudiohx.babylonhx.tools.SceneLoader;
import com.gamestudiohx.babylonhx.tools.SmartArray;
import com.gamestudiohx.babylonhx.tools.Tools;


/**
 * Empty test.
 * Import all of BabylonHX classes to make sure everything compile,
 * and that all used openfl functionalities exists.
 */
class TestImport extends haxe.unit.TestCase
{
	public override function setup()
	{
	}

	public override function tearDown()
	{
	}
}