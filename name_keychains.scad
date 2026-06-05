// =====================================================================
//  Name Key-Hangers  (3D-printable bubble-letter keychains)
// ---------------------------------------------------------------------
//  Give it a list of names and it builds one connected, printable tag
//  per name, each with a hole at the front for a metal clip / keyring.
//
//  REQUIRES OpenSCAD 2021.01 or newer  (it uses textmetrics() to measure
//  the text so the ring and backing can be placed automatically).
// =====================================================================

use <Bungee-Regular.ttf>;

// ----------------------- USER SETTINGS -------------------------------
//names = ["Echo", "Zulu", "Juliet", "India", "Hotel"];        // <-- put any number of names here

names = ["Jur", "Irene", "Zoey", "Emma"];        // <-- put any number of names 

// --- Letters ---
font           = "Bungee";    // bundled — is in this directory.
                                    // Other fat fonts (install first):
                                    //   "Fredoka One", "Baloo 2",
                                    //   "Bauhaus 93", "Chewy"
text_size      = 20;               // letter height in mm
thickness      = 8;                // base depth / thickness of the tag in mm
letter_spacing = 0.7;             // <1 squeezes letters so they touch
// Extra pull on letters 2..n so thin pairs (I+r, Z+o, J+u) still fuse in 3D.
// Increase if a gap remains; decrease if letters look too squashed.
letter_join_overlap = 1.2;

// --- Random letter heights ---
height_min = thickness * 0.8;     // shortest a letter can be
height_max = thickness * 1.3;     // tallest a letter can be
height_seed = 42;                  // change this number for a different pattern

// --- How the letters stay joined into ONE solid piece ---
//   "backing" = thin flat plate behind everything (most reliable)
//   "bar"     = thin strip along the bottom of the letters
//   "none"    = rely only on fat letters overlapping (best looks,
//               but check the letters actually touch before printing!)
connection_mode   = "none";
backing_thickness = 1.2;           // used by "backing"
backing_margin    = 1.5;           // how far the plate sticks out past text
bar_height        = 3.0;           // used by "bar"

// --- Ring / hole for the clip ---
ring_outer_d   = 13;
ring_hole_d    = 6;                // metal clip passes through this hole
ring_gap       = 1.0;              // distance from ring to first letter
ring_height    = 1.5;
neck_width     = 6;                // width of the connector to the letters

// --- Layout when several names are made at once ---
name_gap = 12;                     // vertical space between tags (mm)

$fn = 64;                          // roundness of circles


// --------------------------- HELPERS ---------------------------------

// Returns the first n characters of string s as a new string.
function str_prefix(s, n) = n == 0 ? "" : str(str_prefix(s, n-1), s[n-1]);

// Stable seed from the name so each tag gets its own height pattern.
function name_height_seed(s, i = 0, acc = 0) =
    i >= len(s) ? height_seed + acc :
    name_height_seed(s, i + 1, acc + ord(s[i]));


// --------------------------- MODULES ---------------------------------

// Flat ring (a disc with a hole) that the metal clip hooks onto.
module ring() {
    linear_extrude(height = ring_height)
        difference() {
            circle(d = ring_outer_d);
            circle(d = ring_hole_d);
        }
}

// A single finished tag for one name, drawn starting at the origin.
module name_tag(name) {

    // Measure the rendered text so we can place things precisely.
    tm  = textmetrics(text    = name,
                       size    = text_size,
                       font    = font,
                       halign  = "left",
                       valign  = "center",
                       spacing = letter_spacing);

    tw  = tm.size[0];              // text width
    th  = tm.size[1];              // text height
    tx0 = tm.position[0];          // left edge of the text
    ty0 = tm.position[1];          // bottom edge of the text
    cy  = ty0 + th / 2;            // vertical centre of the text

    ring_cx = tx0 - ring_gap - ring_outer_d / 2;   // ring centre x
    overlap = 6;                                 // ensures parts fuse

    // One random height per letter (seed varies per name).
    letter_heights = rands(height_min, height_max, len(name), name_height_seed(name));

    union() {
    
        // 1) Each letter extruded to its own height.
        //    Prefix-width gives the x-advance to where character i starts.
        for (i = [0 : len(name) - 1]) {
            prefix_w = i == 0 ? 0 :
                textmetrics(text    = str_prefix(name, i),
                            size    = text_size,
                            font    = font,
                            halign  = "left",
                            valign  = "center",
                            spacing = letter_spacing).size[0];

            x = prefix_w - (i > 0 ? letter_join_overlap : 0);

            linear_extrude(height = letter_heights[i])
                translate([x, 0, 0])
                    text(name[i], size = text_size, font = font,
                         halign = "left", valign = "center",
                         spacing = letter_spacing);
                         
            linear_extrude(ring_height) {
                translate([x, 0, 0])
                    offset(backing_margin) {
                        fill() {
                            text(name[i], size = text_size, font = font,
                            halign = "left", valign = "center",
                            spacing = letter_spacing);
                    }
                }
            }
    
        }

        // 2) The ring at the front
        translate([ring_cx, cy, 0]) ring();

        // 3) Connector neck joining the ring to the first letter
        translate([ring_cx+ring_hole_d/2, cy - neck_width / 2, 0])
            cube([(tx0 + overlap) - ring_cx-ring_hole_d/2, neck_width, ring_height]);

        // 4) Whatever keeps all the letters joined together
        if (connection_mode == "backing")
            linear_extrude(height = backing_thickness)
                hull()
                    offset(r = backing_margin)
                        text(name, size = text_size, font = font,
                             halign = "left", valign = "center",
                             spacing = letter_spacing);

        if (connection_mode == "bar")
            translate([tx0 - overlap, ty0 - 0.5, 0])
                cube([tw + 2 * overlap, bar_height, thickness]);
        // "none" -> nothing extra is added
    }
}


// ----------------------- BUILD ALL NAMES -----------------------------

for (i = [0 : len(names) - 1])
    translate([0, -i * (text_size + name_gap), 0])
        name_tag(names[i]);
