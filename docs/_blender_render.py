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

# ── Matte PLA material (Bambu steel-blue, FDM layer-line bump) ──
mat = bpy.data.materials.new("PLA_Blue")
mat.use_nodes = True
nodes = mat.node_tree.nodes
links = mat.node_tree.links
nodes.clear()

output = nodes.new("ShaderNodeOutputMaterial")
principled = nodes.new("ShaderNodeBsdfPrincipled")

# Bambu PLA Basic steel-blue — use sRGB hex #2B5278 converted to linear:
# R=0.169^2.2=0.023, G=0.322^2.2=0.084, B=0.471^2.2=0.189  → too dark
# Instead, set a visually correct mid-blue that renders well under studio light
principled.inputs["Base Color"].default_value = (0.05, 0.12, 0.28, 1.0)
principled.inputs["Roughness"].default_value = 0.38
principled.inputs["Specular IOR Level"].default_value = 0.5
principled.inputs["Coat Weight"].default_value = 0.12
principled.inputs["Coat Roughness"].default_value = 0.25

# FDM layer-line bump via fine horizontal wave texture
tex_coord = nodes.new("ShaderNodeTexCoord")
mapping = nodes.new("ShaderNodeMapping")
mapping.inputs["Scale"].default_value = (1.0, 1.0, 500.0)  # fine Z stripes = layer lines
links.new(tex_coord.outputs["Object"], mapping.inputs["Vector"])

wave = nodes.new("ShaderNodeTexWave")
wave.wave_type = 'BANDS'
wave.bands_direction = 'Z'
wave.inputs["Scale"].default_value = 800.0      # ~0.2 mm layers at model scale
wave.inputs["Distortion"].default_value = 0.3   # slight irregularity
wave.inputs["Detail"].default_value = 2.0
wave.inputs["Detail Roughness"].default_value = 0.5
links.new(mapping.outputs["Vector"], wave.inputs["Vector"])

bump = nodes.new("ShaderNodeBump")
bump.inputs["Strength"].default_value = 0.08    # very subtle, just enough for realism
bump.inputs["Distance"].default_value = 0.001
links.new(wave.outputs["Fac"], bump.inputs["Height"])
links.new(bump.outputs["Normal"], principled.inputs["Normal"])

links.new(principled.outputs["BSDF"], output.inputs["Surface"])

# Apply material and smooth shading to all bins
for o in all_objects:
    o.data.materials.append(mat)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    try:
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(30))
    except AttributeError:
        bpy.ops.object.shade_smooth()
    o.select_set(False)

# ── Ground plane (subtle shadow catcher) ─────────────────────
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
g_bsdf.inputs["Color"].default_value = (0.95, 0.95, 0.95, 1.0)
gl.new(g_bsdf.outputs["BSDF"], g_out.inputs["Surface"])
ground.data.materials.append(ground_mat)
ground.is_shadow_catcher = True

# ── Camera ───────────────────────────────────────────────────
cam_data = bpy.data.cameras.new("Camera")
cam_data.lens = 50
cam_obj = bpy.data.objects.new("Camera", cam_data)
bpy.context.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj

# Position camera — further back for stacked view
if STACKED:
    cam_obj.location = (0.28, -0.24, 0.20)
else:
    cam_obj.location = (0.22, -0.18, 0.14)

# Point camera at center of the stack/bin
import mathutils
if STACKED:
    target = mathutils.Vector((
        obj.location.x,
        obj.location.y,
        (BIN_HEIGHT_M - STACK_LIP_M) / 2  # center of stacked pair
    ))
else:
    target = obj.location.copy()
direction = target - cam_obj.location
rot_quat = direction.to_track_quat('-Z', 'Y')
cam_obj.rotation_euler = rot_quat.to_euler()

# ── Lighting: 3-point studio ────────────────────────────────
# Key light (warm, soft, upper-right — casts main shadow)
key = bpy.data.lights.new("KeyLight", type='AREA')
key.energy = 8
key.size = 0.4          # moderately soft shadow edge
key.color = (1.0, 0.95, 0.88)
key_obj = bpy.data.objects.new("KeyLight", key)
key_obj.location = (0.25, -0.20, 0.35)
bpy.context.collection.objects.link(key_obj)
# Track-to for precise aim
ttk = key_obj.constraints.new('TRACK_TO')
ttk.target = all_objects[-1] if STACKED else obj
ttk.track_axis = 'TRACK_NEGATIVE_Z'
ttk.up_axis = 'UP_Y'

# Fill light (cool, upper-left — softens shadow contrast)
fill = bpy.data.lights.new("FillLight", type='AREA')
fill.energy = 3
fill.size = 0.9         # broad & diffuse
fill.color = (0.85, 0.90, 1.0)
fill_obj = bpy.data.objects.new("FillLight", fill)
fill_obj.location = (-0.22, -0.28, 0.22)
bpy.context.collection.objects.link(fill_obj)
ttf = fill_obj.constraints.new('TRACK_TO')
ttf.target = all_objects[-1] if STACKED else obj
ttf.track_axis = 'TRACK_NEGATIVE_Z'
ttf.up_axis = 'UP_Y'

# Rim / back light (defines silhouette edge)
rim = bpy.data.lights.new("RimLight", type='AREA')
rim.energy = 4
rim.size = 0.25
rim.color = (1.0, 1.0, 1.0)
rim_obj = bpy.data.objects.new("RimLight", rim)
rim_obj.location = (-0.08, 0.30, 0.28)
bpy.context.collection.objects.link(rim_obj)
ttr = rim_obj.constraints.new('TRACK_TO')
ttr.target = all_objects[-1] if STACKED else obj
ttr.track_axis = 'TRACK_NEGATIVE_Z'
ttr.up_axis = 'UP_Y'

# ── World: subtle gradient background ────────────────────────
world = bpy.data.worlds.new("World")
bpy.context.scene.world = world
world.use_nodes = True
wn = world.node_tree.nodes
wl = world.node_tree.links
wn.clear()
w_out = wn.new("ShaderNodeOutputWorld")
w_bg = wn.new("ShaderNodeBackground")
w_bg.inputs["Color"].default_value = (0.85, 0.85, 0.88, 1.0)
w_bg.inputs["Strength"].default_value = 0.05  # minimal ambient — shadows stay dark
wl.new(w_bg.outputs["Background"], w_out.inputs["Surface"])

# ── Render settings (Cycles path tracer) ─────────────────────
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 256            # faster iteration
scene.cycles.use_denoising = True
scene.render.resolution_x = 1200
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.film_transparent = True  # transparent background
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.filepath = OUT_PATH

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
