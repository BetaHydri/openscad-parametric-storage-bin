// ============================================================
//  Parametric Open-Front Storage Bin
//  (low front wall + diagonal chamfer on side walls)
//  Units: millimetres
//  MakerWorld Parametric Maker compatible
// ============================================================

/* [Printer / Build Volume] */
// Printer preset. "Custom" uses the max_* values below; presets override them.
printer = "H2D"; // [P1S, P2S, H2C, H2D, Custom]
// Custom max build width (X) in mm — used only when printer = "Custom"
max_build_x = 350; // [100:1:500]
// Custom max build depth (Y) in mm — used only when printer = "Custom"
max_build_y = 320; // [100:1:500]
// Custom max build height (Z) in mm — used only when printer = "Custom"
max_build_z = 325; // [100:1:500]

/* [Outer Dimensions] */
// Width (left-right) in mm (auto-capped to printer build X)
width = 120;        // [40:1:500]
// Depth (front-back) in mm (auto-capped to printer build Y)
depth = 100;        // [40:1:500]
// Total height (back wall) in mm (auto-capped to printer build Z)
height = 70;        // [20:1:500]

/* [Front Opening] */
// Height of the short front wall in mm (auto-capped to height - 5)
front_height = 30;  // [5:1:495]
// Length of the diagonal chamfer on the side walls (along Y, from the front). 0 = vertical step. Auto-capped to depth - wall.
chamfer_len = 35;   // [0:1:495]

/* [Walls] */
// Side / front / back wall thickness in mm
wall = 2.0;         // [1.2:0.1:4.0]
// Floor thickness in mm
floor_t = 2.0;      // [1.2:0.1:4.0]

/* [Stacking] */
// Make bins stackable: adds a lip on top (back + rear sides) and a matching
// recess in the floor underside. Costs NO interior volume — only ~lip height
// of total stack height. Set to 0 to disable.
stackable = 0;          // [0:Off, 1:On]
// Height of the stacking lip / depth of the underside recess (mm)
stack_lip_h = 3.0;      // [1.0:0.1:8.0]
// Horizontal clearance between lip and recess, per side (mm). Increase for
// looser fit, decrease for tighter.
stack_clearance = 0.2;  // [0.1:0.05:0.6]

/* [Cosmetic] */
// Outer bottom edge chamfer (elephant-foot relief) in mm
bottom_chamfer = 0.6;  // [0:0.1:2.0]

/* [Quality] */
// Render smoothness ($fn). Higher = smoother but slower.
$fn = 64;           // [16:8:128]

// ============================================================
//  Printer build-volume lookup (X, Y, Z in mm)
//  Update here if Bambu publishes revised specs.
// ============================================================
_bv =
    (printer == "P1S") ? [256, 256, 256] :
    (printer == "P2S") ? [256, 256, 256] :
    (printer == "H2C") ? [330, 320, 325] :
    (printer == "H2D") ? [350, 320, 325] :
                         [max_build_x, max_build_y, max_build_z]; // Custom

_max_x = _bv[0];
_max_y = _bv[1];
_max_z = _bv[2];

// ============================================================
//  Internal clamped values (keep geometry valid for any UI input)
// ============================================================
// Clamp outer dims to selected printer build volume first
_width  = min(width,  _max_x);
_depth  = min(depth,  _max_y);
_height = min(height, _max_z);

_fh = min(front_height, _height - 5);                  // front wall < back wall
_cl = max(0, min(chamfer_len, _depth - wall));         // chamfer fits in depth
_wall   = min(wall,   min(_width, _depth) / 2 - 1);    // walls fit in footprint
_floor  = min(floor_t, _height - 1);                   // floor < height

// Stacking lip clamped so it never exceeds available wall height or floor.
_lip_h = max(0, min(stack_lip_h, min(_height - _fh - 1, _floor - 0.4)));

// ============================================================
//  Geometry
// ============================================================

// `stack` / `lip_h` / `clearance` default to the file-scope params so the
// MakerWorld Customizer keeps working. External scripts that `use <>` this
// file can override them per call (see docs/_render-stacked.scad).
module bin(stack=stackable, lip_h=_lip_h, clearance=stack_clearance) {
    difference() {
        union() {
            // Floor
            cube([_width, _depth, _floor]);

            // Back wall (full height)
            translate([0, _depth - _wall, 0])
                cube([_width, _wall, _height]);

            // Front wall (short)
            cube([_width, _wall, _fh]);

            // Left side wall
            side_wall();

            // Right side wall (mirrored)
            translate([_width, 0, 0])
                mirror([1, 0, 0])
                    side_wall();
        }

        // Outer bottom chamfer (elephant-foot relief)
        if (bottom_chamfer > 0) bottom_chamfer_cut();

        // Stacking interface (lip on top + recess on bottom)
        if (stack && lip_h > 0) {
            top_lip_cut(lip_h);
            bottom_recess_cut(lip_h, clearance);
        }
    }
}

// One side wall, sitting at x = 0 .. _wall.
// 2D profile drawn in the YZ-plane, then extruded in X.
module side_wall() {
    pts = [
        [0,      0],           // front-bottom
        [_depth, 0],           // back-bottom
        [_depth, _height],     // back-top
        [_cl,    _height],     // start of diagonal
        [0,      _fh],         // top of front wall
    ];

    rotate([90, 0, 90])
        linear_extrude(height = _wall)
            polygon(points = pts);
}

// 45° chamfer around the outer bottom perimeter (4 triangular prisms)
module bottom_chamfer_cut() {
    c = bottom_chamfer;
    // Front
    translate([-0.01, -0.01, -0.01])
        rotate([0, 90, 0])
            linear_extrude(height = _width + 0.02)
                polygon([[0,0],[c,0],[0,c]]);
    // Back
    translate([-0.01, _depth + 0.01, -0.01])
        rotate([0, 90, 0])
            linear_extrude(height = _width + 0.02)
                polygon([[0,0],[c,0],[0,-c]]);
    // Left
    translate([-0.01, -0.01, -0.01])
        rotate([-90, 0, 90])
            linear_extrude(height = _depth + 0.02)
                polygon([[0,0],[c,0],[0,c]]);
    // Right
    translate([_width + 0.01, -0.01, -0.01])
        rotate([-90, 0, 90])
            linear_extrude(height = _depth + 0.02)
                polygon([[0,0],[-c,0],[0,c]]);
}

// ----- Stacking helpers -------------------------------------
// Shave the OUTER half of the top of the back wall + side walls down to
// rim level (z = _height - h), leaving the INNER half as the lip. The
// outer cut spans the FULL side-wall length (y in [0, _depth]); where the
// original chamfered profile sits below rim level it is simply unaffected.
// No wedges or sub-chamfers — a stacked bin's outer wall meets the lower
// bin's outer wall flush all the way around.
module top_lip_cut(h=_lip_h) {
    w2 = _wall / 2;        // outer half-thickness we cut away
    eps = 0.01;
    // Back wall outer half
    translate([-eps, _depth - w2, _height - h])
        cube([_width + 2*eps, w2 + eps, h + eps]);
    // Left side wall outer half — full length, straight cut at rim level.
    translate([-eps, -eps, _height - h])
        cube([w2 + eps, _depth + 2*eps, h + eps]);
    // Right side wall outer half — full length, straight cut at rim level.
    translate([_width - w2, -eps, _height - h])
        cube([w2 + 2*eps, _depth + 2*eps, h + eps]);

    // Front chamfer region (y in [0, _cl]): cut the INNER half of each
    // side wall flat at rim level too. The wall's chamfered top already
    // dips below rim level over most of this range, but the inner-half
    // slope still pokes above rim near y = _cl. This shave guarantees a
    // clean rim across the whole front so the recess in the upper bin's
    // floor only needs to span the lip (y in [_cl, _depth]).
    translate([w2 - eps, -eps, _height - h])
        cube([w2 + 2*eps, _cl + eps, h + eps]);
    translate([_width - _wall - eps, -eps, _height - h])
        cube([w2 + 2*eps, _cl + eps, h + eps]);
}

// Pocket in the floor underside that mates with the lip of the bin below.
// Left/right recesses only span the lip region (y in [_cl, _depth]); the
// front chamfer region of the lower bin is shaved flat at rim level by
// top_lip_cut so no clearance is needed there.
module bottom_recess_cut(h=_lip_h, cl=stack_clearance) {
    w2  = _wall / 2;       // lip thickness
    eps = 0.01;
    // Back lip recess (inner half of back-wall footprint, + clearance)
    translate([-cl, _depth - _wall - cl, -eps])
        cube([_width + 2*cl, w2 + 2*cl, h + eps]);
    // Left side lip recess — only as long as the lip itself
    translate([w2 - cl, _cl - cl, -eps])
        cube([w2 + 2*cl, _depth - _cl + 2*cl, h + eps]);
    // Right side lip recess — only as long as the lip itself
    translate([_width - _wall - cl, _cl - cl, -eps])
        cube([w2 + 2*cl, _depth - _cl + 2*cl, h + eps]);
}

bin();
