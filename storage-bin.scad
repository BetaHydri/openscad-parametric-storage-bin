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
// Shave the OUTER half of the top of the back wall + rear portion of the
// side walls, leaving the INNER half as an upward-protruding lip.
// The front of each side-wall top is sloped on its FULL thickness from
// the chamfer corner (z = _height at y = _cl) down to rim level
// (z = _height - h at y = _cl + taper). Without that wedge a vertical
// "nose" / step at y = _cl would prevent a stacked bin from sitting flat.
module top_lip_cut(h=_lip_h) {
    w2 = _wall / 2;        // outer half-thickness we cut away
    eps = 0.01;
    taper = h;             // 45° slope length, equals lip height
    // Back wall outer half
    translate([-eps, _depth - w2, _height - h])
        cube([_width + 2*eps, w2 + eps, h + eps]);
    // Left side wall outer half (starts AFTER the taper region so the
    // sloped top is not undercut by the rim).
    translate([-eps, _cl + taper, _height - h])
        cube([w2 + eps, _depth - _cl - taper + eps, h + eps]);
    // Right side wall outer half
    translate([_width - w2, _cl + taper, _height - h])
        cube([w2 + 2*eps, _depth - _cl - taper + eps, h + eps]);

    // Full-thickness 45° wedge that slopes the LEFT side wall top from
    // (y=_cl,        z=_height)       <- chamfer corner, no cut
    // down to
    // (y=_cl+taper,  z=_height - h)   <- rim level, matches outer cut.
    translate([-eps, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = _wall + 2*eps)
                polygon([[_cl,         _height + eps],
                         [_cl + taper, _height + eps],
                         [_cl + taper, _height - h]]);
    // Same wedge on the RIGHT side wall.
    translate([_width - _wall - eps, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = _wall + 2*eps)
                polygon([[_cl,         _height + eps],
                         [_cl + taper, _height + eps],
                         [_cl + taper, _height - h]]);

    // 45 deg chamfer on the FRONT face of the inner-half side-wall lip,
    // killing the sharp vertical "nose" at y = _cl + taper.  The lip now
    // ramps from rim level (z = _height - h) at y = _cl + taper up to
    // full lip height (z = _height) at y = _cl + taper + h.
    // Left side (inner half only: x = [0, w2]).
    translate([-eps, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = w2 + 2*eps)
                polygon([[_cl + taper,     _height + eps],
                         [_cl + taper + h, _height + eps],
                         [_cl + taper,     _height - h]]);
    // Right side (inner half only: x = [_width - w2, _width]).
    translate([_width - w2 - eps, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = w2 + 2*eps)
                polygon([[_cl + taper,     _height + eps],
                         [_cl + taper + h, _height + eps],
                         [_cl + taper,     _height - h]]);
}

// Pocket in the floor underside that mates with the lip of the bin below.
module bottom_recess_cut(h=_lip_h, cl=stack_clearance) {
    w2  = _wall / 2;       // lip thickness
    eps = 0.01;
    // Back lip recess (inner half of back-wall footprint, + clearance)
    translate([-cl, _depth - _wall - cl, -eps])
        cube([_width + 2*cl, w2 + 2*cl, h + eps]);
    // Left side lip recess
    translate([w2 - cl, _cl - cl, -eps])
        cube([w2 + 2*cl, _depth - _cl + cl, h + eps]);
    // Right side lip recess
    translate([_width - _wall - cl, _cl - cl, -eps])
        cube([w2 + 2*cl, _depth - _cl + cl, h + eps]);
}

bin();
