// Render two stacked bins for the README preview.
// Usage:
//   openscad -o docs/preview-stacked.png --imgsize=1200,800 \
//            --colorscheme=Tomorrow --camera=80,60,40,55,0,40,520 \
//            -D relief_enabled=1 \
//            docs/_render-stacked.scad

use <../storage-bin.scad>;

// `use` does not import top-level variables — duplicate the few we need
// (matches storage-bin.scad defaults).
_HEIGHT = 70;
_LIP_H  = 3.0;

// Bottom bin with stacking interface and relief texture enabled
bin(stack=true);

// Top bin lifted so the inner lip slots into the underside recess
translate([0, 0, _HEIGHT - _LIP_H])
    bin(stack=true);
