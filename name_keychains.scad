// =====================================================================
//  Name Key-Hangers  (3D-printable bubble-letter keychains)
// ---------------------------------------------------------------------
//  Give it a list of names and it builds one connected, printable tag
//  per name, each with a hole at the front for a metal clip / keyring.
//
//  REQUIRES OpenSCAD 2021.01 or newer  (it uses textmetrics() to measure
//  the text so the ring and backing can be placed automatically).
// =====================================================================


// ----------------------- USER SETTINGS -------------------------------
names = ["HOLLY", "DAVID"];        // <-- put any number of names here

// --- Letters ---
font           = "Sniglet";    // bundled — Sniglet.ttf is in this directory.
                                    // Other fat fonts (install first):
                                    //   "Fredoka One", "Baloo 2",
                                    //   "Bauhaus 93", "Chewy"
text_size      = 20;               // letter height in mm
thickness      = 6;                // base depth / thickness of the tag in mm
letter_spacing = 0.75;             // <1 squeezes letters so they touch

// --- Random letter heights ---
height_min = thickness * 0.8;     // shortest a letter can be
height_max = thickness * 1.3;     // tallest a letter can be
height_seed = 42;                  // change this number for a different pattern

// --- How the letters stay joined into ONE solid piece ---
//   "backing" = thin flat plate behind everything (most reliable)
//   "bar"     = thin strip along the bottom of the letters
//   "none"    = rely only on fat letters overlapping (best looks,
//               but check the letters actually touch before printing!)
connection_mode   = "backing";
backing_thickness = 1.2;           // used by "backing"
backing_margin    = 1.5;           // how far the plate sticks out past text
bar_height        = 3.0;           // used by "bar"

// --- Ring / hole for the clip ---
ring_outer_d   = 13;
ring_hole_d    = 6;                // metal clip passes through this hole
ring_gap       = 1.0;              // distance from ring to first letter
neck_width     = 6;                // width of the connector to the letters

// --- Layout when several names are made at once ---
name_gap = 12;                     // vertical space between tags (mm)

$fn = 64;                          // roundness of circles


// --------------------------- HELPERS ---------------------------------

// Returns the first n characters of string s as a new string.
function str_prefix(s, n) = n == 0 ? "" : str(str_prefix(s, n-1), s[n-1]);


// --------------------------- MODULES ---------------------------------

// Flat ring (a disc with a hole) that the metal clip hooks onto.
module ring() {
    linear_extrude(height = thickness)
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
    overlap = 1.5;                                 // ensures parts fuse

    // One random height per letter.
    letter_heights = rands(height_min, height_max, len(name), height_seed);

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

            linear_extrude(height = letter_heights[i])
                translate([prefix_w, 0, 0])
                    text(name[i], size = text_size, font = font,
                         halign = "left", valign = "center",
                         spacing = letter_spacing);
        }

        // 2) The ring at the front
        translate([ring_cx, cy, 0]) ring();

        // 3) Connector neck joining the ring to the first letter
        translate([ring_cx, cy - neck_width / 2, 0])
            cube([(tx0 + overlap) - ring_cx, neck_width, thickness]);

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
