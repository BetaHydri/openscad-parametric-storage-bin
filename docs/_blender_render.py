"""
Blender headless script: raytrace storage-bin STL(s) with Cycles.
Usage (single bin → preview.png):
  blender --background --python docs/_blender_render.py
Usage (stacked pair → preview-stacked.png):
  blender --background --python docs/_blender_render.py -- --stacked
"""
import bpy
import math
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
STL_PATH = os.path.join(SCRIPT_DIR, "model.stl")

# Parse --stacked flag (after Blender's --)
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
STACKED = "--stacked" in argv

OUT_PATH = os.path.join(SCRIPT_DIR, "preview-stacked.png" if STACKED else "preview.png")

# Bin dimensions (must match storage-bin.scad defaults)
BIN_HEIGHT_M = 0.070   # 70 mm
STACK_LIP_M  = 0.003   # 3 mm

# ── Clean scene ──────────────────────────────────────────────
bpy.ops.wm.read_factory_settings(use_empty=True)

# ── Import STL ───────────────────────────────────────────────
bpy.ops.wm.stl_import(filepath=STL_PATH)
obj = bpy.context.selected_objects[0]
obj.name = "StorageBin_Bottom"

# Center and scale (STL is in mm, Blender uses m → scale 0.001)
obj.scale = (0.001, 0.001, 0.001)
bpy.ops.object.transform_apply(scale=True)

# Move origin to geometry center, then place on ground plane
bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
bbox = obj.bound_box
min_z = min(v[2] for v in bbox)
obj.location.z -= min_z  # sit on z=0

# ── Second bin (stacked on top) ──────────────────────────────
all_objects = [obj]
if STACKED:
    bpy.ops.wm.stl_import(filepath=STL_PATH)
    obj2 = bpy.context.selected_objects[0]
    obj2.name = "StorageBin_Top"
    obj2.scale = (0.001, 0.001, 0.001)
    bpy.ops.object.transform_apply(scale=True)
    bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
    bbox2 = obj2.bound_box
    min_z2 = min(v[2] for v in bbox2)
    obj2.location.z = -min_z2 + (BIN_HEIGHT_M - STACK_LIP_M)
    all_objects.append(obj2)

# ── Matte PLA material (Bambu steel-blue) ────────────────────
mat = bpy.data.materials.new("PLA_Blue")
mat.use_nodes = True
nodes = mat.node_tree.nodes
links = mat.node_tree.links
nodes.clear()

output = nodes.new("ShaderNodeOutputMaterial")
principled = nodes.new("ShaderNodeBsdfPrincipled")

# Steel-blue PLA — sRGB values (Blender interprets Base Color as sRGB automatically)
principled.inputs["Base Color"].default_value = (0.15, 0.33, 0.50, 1.0)
principled.inputs["Roughness"].default_value = 0.45
principled.inputs["Specular IOR Level"].default_value = 0.4

links.new(principled.outputs["BSDF"], output.inputs["Surface"])

# Apply material + smooth-by-angle shading (softens grooves, keeps box edges sharp)
for o in all_objects:
    o.data.materials.append(mat)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    try:
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(50))
    except AttributeError:
        bpy.ops.object.shade_smooth()
    o.select_set(False)

# ── Ground plane (shadow catcher for realistic contact shadows) ──
bpy.ops.mesh.primitive_plane_add(size=2.0, location=(0, 0, 0))
ground = bpy.context.active_object
ground.name = "Ground"
ground_mat = bpy.data.materials.new("GroundMat")
ground_mat.use_nodes = True
gn = ground_mat.node_tree.nodes
gl = ground_mat.node_tree.links
gn.clear()
g_out = gn.new("ShaderNodeOutputMaterial")
g_bsdf = gn.new("ShaderNodeBsdfDiffuse")
g_bsdf.inputs["Color"].default_value = (0.9, 0.9, 0.9, 1.0)
gl.new(g_bsdf.outputs["BSDF"], g_out.inputs["Surface"])
ground.data.materials.append(ground_mat)
ground.is_shadow_catcher = True

# ── Camera ───────────────────────────────────────────────────
cam_data = bpy.data.cameras.new("Camera")
cam_data.lens = 50
cam_obj = bpy.data.objects.new("Camera", cam_data)
bpy.context.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj

# Position camera — front-left 3/4 view to show chamfer on BOTH bins
# (matches the original OpenSCAD preview angle)
if STACKED:
    cam_obj.location = (-0.12, -0.18, 0.20)   # front-left, elevated
else:
    cam_obj.location = (-0.08, -0.14, 0.12)

cam_data.lens = 45  # slightly wider for full framing

# Point camera at center of the stack/bin
import mathutils
if STACKED:
    target = mathutils.Vector((
        0.06,    # center of bin width (120mm / 2)
        0.05,    # mid-depth (100mm / 2)
        (BIN_HEIGHT_M - STACK_LIP_M) * 0.45
    ))
else:
    target = mathutils.Vector((
        0.06,
        0.05,
        BIN_HEIGHT_M * 0.4
    ))
direction = target - cam_obj.location
rot_quat = direction.to_track_quat('-Z', 'Y')
cam_obj.rotation_euler = rot_quat.to_euler()

# ── Lighting: 3-point studio ────────────────────────────────
# Key light (warm, soft, upper-right — casts main shadow)
key = bpy.data.lights.new("KeyLight", type='AREA')
key.energy = 2.0
key.size = 0.35         # moderately soft shadow edge
key.color = (1.0, 0.96, 0.90)
key_obj = bpy.data.objects.new("KeyLight", key)
key_obj.location = (0.30, -0.20, 0.35)
bpy.context.collection.objects.link(key_obj)
# Track-to for precise aim
ttk = key_obj.constraints.new('TRACK_TO')
ttk.target = all_objects[-1] if STACKED else obj
ttk.track_axis = 'TRACK_NEGATIVE_Z'
ttk.up_axis = 'UP_Y'

# Fill light (cool, upper-left — softens shadow contrast)
fill = bpy.data.lights.new("FillLight", type='AREA')
fill.energy = 1.0
fill.size = 1.0         # very broad & diffuse for interior fill
fill.color = (0.88, 0.92, 1.0)
fill_obj = bpy.data.objects.new("FillLight", fill)
fill_obj.location = (-0.25, -0.10, 0.25)
bpy.context.collection.objects.link(fill_obj)
ttf = fill_obj.constraints.new('TRACK_TO')
ttf.target = all_objects[-1] if STACKED else obj
ttf.track_axis = 'TRACK_NEGATIVE_Z'
ttf.up_axis = 'UP_Y'

# Rim / back light (defines silhouette edge)
rim = bpy.data.lights.new("RimLight", type='AREA')
rim.energy = 1.5
rim.size = 0.20
rim.color = (1.0, 1.0, 1.0)
rim_obj = bpy.data.objects.new("RimLight", rim)
rim_obj.location = (-0.10, 0.30, 0.30)
bpy.context.collection.objects.link(rim_obj)
ttr = rim_obj.constraints.new('TRACK_TO')
ttr.target = all_objects[-1] if STACKED else obj
ttr.track_axis = 'TRACK_NEGATIVE_Z'
ttr.up_axis = 'UP_Y'

# Sun light (directional — angled to shine INTO the open front of the bins)
sun = bpy.data.lights.new("SunLight", type='SUN')
sun.energy = 1.5           # gentle directional fill for interiors
sun.angle = math.radians(5)  # soft shadow edge
sun.color = (1.0, 0.98, 0.95)
sun_obj = bpy.data.objects.new("SunLight", sun)
# Shine from front-above-left → into the open front
sun_obj.rotation_euler = (math.radians(45), math.radians(-10), math.radians(160))
bpy.context.collection.objects.link(sun_obj)

# Interior fill lights — small point lights inside each bin to prevent black holes
for idx, o in enumerate(all_objects):
    interior = bpy.data.lights.new(f"InteriorFill_{idx}", type='POINT')
    interior.energy = 1.5
    interior.color = (0.85, 0.90, 1.0)  # cool fill
    interior.shadow_soft_size = 0.05
    int_obj = bpy.data.objects.new(f"InteriorFill_{idx}", interior)
    # Place inside the bin, centered horizontally, mid-height
    int_obj.location = (
        o.location.x + 0.06,   # center of 120mm bin
        o.location.y + 0.05,   # ~50mm from front
        o.location.z + 0.035   # mid-height
    )
    bpy.context.collection.objects.link(int_obj)

# ── World: subtle gradient background ────────────────────────
world = bpy.data.worlds.new("World")
bpy.context.scene.world = world
world.use_nodes = True
wn = world.node_tree.nodes
wl = world.node_tree.links
wn.clear()
w_out = wn.new("ShaderNodeOutputWorld")
w_bg = wn.new("ShaderNodeBackground")
w_bg.inputs["Color"].default_value = (0.90, 0.92, 0.96, 1.0)
w_bg.inputs["Strength"].default_value = 0.15  # minimal ambient
wl.new(w_bg.outputs["Background"], w_out.inputs["Surface"])

# ── Render settings (Cycles path tracer) ─────────────────────
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 256
scene.cycles.use_denoising = True
scene.render.resolution_x = 1200
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.filepath = OUT_PATH

scene.view_settings.view_transform = 'Filmic'
scene.view_settings.look = 'None'
scene.view_settings.exposure = 0.0

# Prefer GPU if available, fall back to CPU
prefs = bpy.context.preferences.addons.get('cycles')
if prefs:
    cprefs = prefs.preferences
    cprefs.compute_device_type = 'NONE'  # CPU fallback
    # Try GPU backends
    for dev_type in ('CUDA', 'OPTIX', 'HIP', 'METAL', 'ONEAPI'):
        try:
            cprefs.compute_device_type = dev_type
            cprefs.get_devices()
            if any(d.type != 'CPU' for d in cprefs.devices):
                scene.cycles.device = 'GPU'
                for d in cprefs.devices:
                    d.use = True
                break
        except Exception:
            continue

# ── Render ───────────────────────────────────────────────────
bpy.ops.render.render(write_still=True)
print(f"Render saved to {OUT_PATH}")
