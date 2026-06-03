// Render two stacked bins for the README preview.
// Usage:
//   openscad -o docs/preview-stacked.png --imgsize=1200,800 \
//            --colorscheme=Tomorrow --camera=80,60,40,55,0,40,520 \
//            -D relief_enabled=1 \
//            docs/_render-stacked.scad

// `use` (not `include`) so we don't pull in storage-bin.scad's top-level
// `bin();` call. Relief is passed explicitly because `use` does not
// propagate the file-scope `relief_enabled` variable into `bin()`.
use <../storage-bin.scad>;

_HEIGHT = 70;
_LIP_H  = 3.0;

// Bottom bin with stacking interface and relief texture enabled
bin(stack=true, relief=true);

// Top bin lifted so the inner lip slots into the underside recess
translate([0, 0, _HEIGHT - _LIP_H])
    bin(stack=true, relief=true);
