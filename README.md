BabylonHx
=========
<img src="https://api.travis-ci.org/babylonhx/babylonHX.svg?branch=master" />

WIP
Update this version BabylonHx is under rapid development so if you download this and want to use it as a lib for one of the examples it will break. 
But all Examples except Ex3 have a stable version of BabylonHx.  That being said if you want to help please do.

I am trying to get this version to catch up to the new version of BabylonJS.  Complete with PostProcessing Rendering, Shader Materials, Geometry Class etc...

=========

BabylonHx is a direct port of BabylonJs engine to Haxe/OpenFL. 
It supports (almost) all features of the original.

Right now openGLES 3 devices have a huge speed increase they run at around 120 fps although openGLES 2 devices run around 7 fps and that is abysmal performance so I am tring to track down the reason for the performance issues but if you are using an openGLES3 + device you will be able to achieve 60+ fps.

**IMPORTANT:** 
This was orginally authored by @vujadin this is a forked version of https://github.com/vujadin/BabylonHx I am trying to update this version to be as close as possible to the current version of babylonJS.
Use this settings in your application.xml file for mobile targets to work (thanks @labe-me):<br/>
***&lt;window require-shaders="true" hardware="true" depth-buffer="true" /&gt;***


*Not supported features:*


  * Video textures
  * Image flipping (images have to be flipped by 'hand')
  * Incremental loading (because of OpenFL and its way of handling assets)
  * Support for drag'n'drop
  * Physics


And probably a few more things ...

Visit http://babylonjs.com/ for more info about the engine.

**Known bugs (major ones):**

  * Currently works with <a href="https://github.com/seacloud9/BabylonHx/tree/master/samples/ds.babylonHxEx1">Example 1</a> targets Mac, Neko, HTML5 now works again,~~HTML5 is broken most likely due to an float array 32 issue.~~
  <br /><a href="https://github.com/seacloud9/BabylonHx/tree/master/samples/ds.babylonHxEx1">
  <img src="https://raw.githubusercontent.com/seacloud9/BabylonHx/master/samples/ds.babylonHxEx1/screenshot1.jpg" style="max-width:100%" /></a>
  * Currently works with <a href="https://github.com/seacloud9/BabylonHx/tree/master/samples/ds.babylonHxEx2">Example 2</a> targets Mac, Neko, HTML5 now works again,~~HTML5 is broken most likely due to an float array 32 issue.~~.
  <br /><a href="https://github.com/seacloud9/BabylonHx/tree/master/samples/ds.babylonHxEx2">
  <img src="https://raw.githubusercontent.com/seacloud9/BabylonHx/master/samples/ds.babylonHxEx2/screenshot1.jpg" style="max-width:100%"/>
  </a><br />
  * Currently works with <a href="https://github.com/seacloud9/BabylonHx/tree/master/samples/ds.babylonHxEx3">Example 3</a> targets Mac, Neko, HTML5.
  <br /><a href="https://github.com/seacloud9/BabylonHx/tree/master/samples/ds.babylonHxEx3">
  <img src="https://raw.githubusercontent.com/seacloud9/BabylonHx/master/samples/ds.babylonHxEx3/screenshot1.jpg" style="max-width:100%"/>
  </a><br />

**TODO:**
  
  1. com/gamestudiohx/babylonhx/Engine.hx - evaluate native targets and images for normal maps
  2. com/gamestudiohx/babylonhx/tools/SceneLoader.hx - evaluate parse light specifically intensity and add range
  3. Fix computeWorldMatrix seems to affect parent child relationships 
  4. Fix issue with textures for some reason most examples require a texture to properly display in native devices (similar to 1)
  5. Fix issue html5 postprocessing and lights (similar to 2)
  6. Create a Blender3D plugin to autogenerate a Babylon file export and have a viewer via Blender3d (export kha haxe style).
  7. Speedup the code and Optimize (openGLES2 targets are slow very slow 3 is 120fps)
  8. Add the vertex class aka babylon.csg.ts
  9. Instanced Material Rendering
  10. Double check new draw calls for platforms
  12. Double check vertexBuffer class
  13. Fix various scene and engine bugs
  14. Mesh.clone() fix deep copy in tools as it does not work properly
  15. Fix bug with lights (similar to 2)
  16. Code refactor - remove reflections from critical places and general code cleanup ***



