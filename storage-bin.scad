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

/* [Relief / Texture] */
// Add vertical groove lines to the outer wall surfaces
relief_enabled = 0;         // [0:Off, 1:On]
// Groove shape: Rectangular, V-groove (triangular), or Rounded (semicircular)
relief_style = 2;           // [0:Rectangular, 1:V-groove, 2:Rounded]
// Approximate total number of grooves around the full perimeter. Per wall
// the count is rounded to the nearest integer and centered symmetrically,
// so no groove ever falls on a corner.
relief_count = 240;         // [4:1:500]
// Depth of each groove into the wall surface (mm)
relief_depth = 0.6;         // [0.2:0.1:1.2]
// Width of each groove (mm)
relief_width = 1.0;         // [0.5:0.1:4.0]
// Minimum solid wall distance from each corner (mm). Keeps corners
// structurally strong and printable.
relief_corner = 1.0;        // [1.0:0.5:15.0]
// Apply to: 0 = All walls, 1 = Sides only, 2 = Front + Back only
relief_walls = 0;           // [0:All walls, 1:Sides only, 2:Front+Back only]

/* [Quality] */
// Render smoothness ($fn). Higher = smoother but slower.
$fn = 64;           // [16:8:128]

// ============================================================
//  Printer build-volume lookup (X, Y, Z in mm)
// ============================================================
_bv =
    (printer == "P1S") ? [256, 256, 256] :
    (printer == "P2S") ? [256, 256, 256] :
    (printer == "H2C") ? [330, 320, 325] :
    (printer == "H2D") ? [350, 320, 325] :
                         [max_build_x, max_build_y, max_build_z];

_max_x = _bv[0];
_max_y = _bv[1];
_max_z = _bv[2];

// ============================================================
//  Internal clamped values
// ============================================================
_width  = min(width,  _max_x);
_depth  = min(depth,  _max_y);
_height = min(height, _max_z);

_fh = min(front_height, _height - 5);
_cl = max(0, min(chamfer_len, _depth - wall));
_wall   = min(wall,   min(_width, _depth) / 2 - 1);
_floor  = min(floor_t, _height - 1);

_lip_h = max(0, min(stack_lip_h, min(_height - _fh - 1, _floor - 0.4)));

// Relief groove depth clamped to leave at least 0.4 mm of wall
_relief_depth = min(relief_depth, _wall - 0.4);

// ============================================================
//  Geometry
// ============================================================

module bin(stack=stackable, lip_h=_lip_h, clearance=stack_clearance, relief=relief_enabled) {
    difference() {
        union() {
            cube([_width, _depth, _floor]);

            translate([0, _depth - _wall, 0])
                cube([_width, _wall, _height]);

            cube([_width, _wall, _fh]);

            side_wall();

            translate([_width, 0, 0])
                mirror([1, 0, 0])
                    side_wall();
        }

        if (bottom_chamfer > 0) bottom_chamfer_cut();

        if (stack && lip_h > 0) {
            top_lip_cut(lip_h);
            bottom_recess_cut(lip_h, clearance);
        }

        if (relief && relief_count > 0) relief_grooves();
    }
}

module side_wall() {
    pts = [
        [0,      0],
        [_depth, 0],
        [_depth, _height],
        [_cl,    _height],
        [0,      _fh],
    ];

    rotate([90, 0, 90])
        linear_extrude(height = _wall)
            polygon(points = pts);
}

module bottom_chamfer_cut() {
    c = bottom_chamfer;
    translate([-0.01, -0.01, -0.01])
        rotate([0, 90, 0])
            linear_extrude(height = _width + 0.02)
                polygon([[0,0],[c,0],[0,c]]);
    translate([-0.01, _depth + 0.01, -0.01])
        rotate([0, 90, 0])
            linear_extrude(height = _width + 0.02)
                polygon([[0,0],[c,0],[0,-c]]);
    translate([-0.01, -0.01, -0.01])
        rotate([-90, 0, 90])
            linear_extrude(height = _depth + 0.02)
                polygon([[0,0],[c,0],[0,c]]);
    translate([_width + 0.01, -0.01, -0.01])
        rotate([-90, 0, 90])
            linear_extrude(height = _depth + 0.02)
                polygon([[0,0],[-c,0],[0,c]]);
}

// ----- Stacking helpers -------------------------------------
module top_lip_cut(h=_lip_h) {
    w2 = _wall / 2;
    eps = 0.01;
    translate([-eps, _depth - w2, _height - h])
        cube([_width + 2*eps, w2 + eps, h + eps]);
    translate([-eps, -eps, _height - h])
        cube([w2 + eps, _depth + 2*eps, h + eps]);
    translate([_width - w2, -eps, _height - h])
        cube([w2 + 2*eps, _depth + 2*eps, h + eps]);
    translate([w2 - eps, -eps, _height - h])
        cube([w2 + 2*eps, _cl + eps, h + eps]);
    translate([_width - _wall - eps, -eps, _height - h])
        cube([w2 + 2*eps, _cl + eps, h + eps]);
}

module bottom_recess_cut(h=_lip_h, cl=stack_clearance) {
    w2  = _wall / 2;
    eps = 0.01;
    translate([-cl, _depth - _wall - cl, -eps])
        cube([_width + 2*cl, w2 + 2*cl, h + eps]);
    translate([w2 - cl, _cl - cl, -eps])
        cube([w2 + 2*cl, _depth - _cl + 2*cl, h + eps]);
    translate([_width - _wall - cl, _cl - cl, -eps])
        cube([w2 + 2*cl, _depth - _cl + 2*cl, h + eps]);
}

// ----- Relief grooves ----------------------------------------
// 2D groove cross-section centered on X=0. Opening at Y=0, depth toward -Y.
module groove_profile_2d(w, d) {
    if (relief_style == 0) {
        translate([-w/2, -d]) square([w, d]);
    } else if (relief_style == 1) {
        polygon([[-w/2, 0], [w/2, 0], [0, -d]]);
    } else {
        intersection() {
            scale([w / (2 * max(d, 0.01)), 1])
                circle(r = d, $fn = 24);
            translate([-w/2 - 0.1, -d - 0.1])
                square([w + 0.2, d + 0.1]);
        }
    }
}

// Grooves distributed per-wall, symmetrically centered.
// All grooves per wall combined into a single extrusion to keep the CSG
// tree small — avoids the "200000 elements" normalization abort.
module relief_grooves() {
    eps = 0.01;
    gd  = _relief_depth;
    gw  = relief_width;
    cm  = relief_corner;

    perim   = 2 * (_width + _depth);
    spacing = perim / max(relief_count, 1);

    // --- Front wall (face at Y=0, grooves along X) ---
    if (relief_walls != 1) {
        usable = _width - 2 * cm;
        nf = max(0, round(usable / spacing));
        gh = _fh - _floor;
        if (nf > 0 && gh > 0 && usable > gw) {
            step = usable / nf;
            off  = cm + step / 2;
            translate([0, -eps, _floor])
                linear_extrude(height = gh + eps)
                    for (i = [0 : nf - 1])
                        translate([off + i * step, 0])
                            mirror([0, 1, 0])
                                groove_profile_2d(gw, gd + eps);
        }
    }

    // --- Right wall (face at X=_width, grooves along Y) ---
    if (relief_walls != 2) {
        usable = _depth - 2 * cm;
        nr = max(0, round(usable / spacing));
        gh = _height - _floor;
        if (nr > 0 && gh > 0 && usable > gw) {
            step = usable / nr;
            off  = cm + step / 2;
            translate([_width + eps, 0, _floor])
                linear_extrude(height = gh + eps)
                    for (i = [0 : nr - 1])
                        translate([0, off + i * step])
                            rotate([0, 0, -90])
                                groove_profile_2d(gw, gd + eps);
        }
    }

    // --- Back wall (face at Y=_depth, grooves along X) ---
    if (relief_walls != 1) {
        usable = _width - 2 * cm;
        nb = max(0, round(usable / spacing));
        gh = _height - _floor;
        if (nb > 0 && gh > 0 && usable > gw) {
            step = usable / nb;
            off  = cm + step / 2;
            translate([0, _depth + eps, _floor])
                linear_extrude(height = gh + eps)
                    for (i = [0 : nb - 1])
                        translate([off + i * step, 0])
                            groove_profile_2d(gw, gd + eps);
        }
    }

    // --- Left wall (face at X=0, grooves along Y) ---
    if (relief_walls != 2) {
        usable = _depth - 2 * cm;
        nl = max(0, round(usable / spacing));
        gh = _height - _floor;
        if (nl > 0 && gh > 0 && usable > gw) {
            step = usable / nl;
            off  = cm + step / 2;
            translate([-eps, 0, _floor])
                linear_extrude(height = gh + eps)
                    for (i = [0 : nl - 1])
                        translate([0, off + i * step])
                            rotate([0, 0, 90])
                                groove_profile_2d(gw, gd + eps);
        }
    }
}

bin();