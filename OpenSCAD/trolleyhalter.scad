// Trolleyhalter fuer GPS mit Magnet
// Eine Stahl-Beilagscheibe wird oben eingeklickt (Magnet-Aufnahme),
// unten sitzt ein Sattel fuer das Trolley-Rohr. Befestigung mit
// Kabelbindern durch Oesen auf beiden Seiten, um das Rohr herum.
//
// Druck: so wie exportiert (Sattel auf dem Druckbett, Scheibenseite oben),
// keine Stuetzen noetig. PETG oder ASA empfohlen (Flex der Laschen, UV).

/* [Beilagscheibe] */
washer_d    = 44;    // Aussendurchmesser (gemessen ca. 44 mm)
washer_hole = 14.5;  // Lochdurchmesser (gemessen ca. 14-15 mm)
washer_t    = 3;     // Dicke
fit_clear   = 0.3;   // Spiel am Aussendurchmesser

/* [Schnapplaschen] */
clip_count  = 4;     // Anzahl Laschen
clip_angle  = 24;    // Breite einer Lasche in Grad
clip_t      = 1.2;   // Wandstaerke der Lasche (duenner = weicher)
clip_gap    = 0.8;   // Freischnitt hinter / neben der Lasche
lip_in      = 0.6;   // Ueberstand der Rastnase ueber den Scheibenrand
lip_h       = 0.9;   // Hoehe der Rastnase ueber der Scheibe
lip_clear   = 0.1;   // Luft zwischen Scheibe und Rastnase

/* [Rohr] */
tube_d      = 40;    // Rohrdurchmesser des Trolleys
pad_t       = 0;     // Dicke einer optionalen Gummi-Zwischenlage (z.B. 1)
saddle_frac = 0.35;  // Wie tief der Sattel das Rohr umgreift (Anteil vom Durchmesser)

/* [Kabelbinder-Oesen] */
eyelet_count = 1;    // Oesen pro Seite (1 = mittig, 2 = vorne + hinten)
strap_w      = 12;   // Lochlaenge (breite Kabelbinder bis ~12 mm, auch doppelt)
strap_t      = 3;    // Lochbreite (Kabelbinder-Dicke + Luft)
eyelet_wall  = 3;    // Materialstaerke um das Loch
eyelet_h     = 5;    // Dicke der Oese
eyelet_pitch = 26;   // Abstand der Oesen entlang dem Rohr (bei 2 Oesen)

/* [Gehaeuse] */
outer_wall  = 1.6;   // Aussenwand hinter den Laschen
floor_t     = 3;     // Boden unter der Scheibe (ueber dem Rohrscheitel)
chamfer     = 0.8;

$fn = 120;

// ---- abgeleitete Masse ----
pocket_r = washer_d / 2 + fit_clear;
wall     = clip_t + clip_gap + outer_wall;
body_r   = pocket_r + wall;
body_d   = 2 * body_r;
tube_r   = tube_d / 2 + pad_t;
saddle_h = tube_d * saddle_frac;

pocket_z = floor_t;                      // Taschenboden
body_h   = pocket_z + washer_t;          // Scheibe liegt buendig mit der Oberkante
relief_z = 0.6;                          // Unterkante der Laschen-Freischnitte

// Breite des Sattelblocks so, dass die Unterseite des Pucks
// mit max. 45 Grad abfaellt (druckbar ohne Stuetzen)
chord    = 2 * sqrt(tube_r * tube_r - pow(tube_r - saddle_h, 2));
saddle_w = max(chord + 6, body_d - 2 * saddle_h);

module puck() {
    cylinder(r = body_r, h = body_h - chamfer);
    translate([0, 0, body_h - chamfer])
        cylinder(r1 = body_r, r2 = body_r - chamfer, h = chamfer);
}

module saddle_block() {
    intersection() {
        translate([-body_r, -saddle_w / 2, -saddle_h])
            cube([body_d, saddle_w, saddle_h + 0.01]);
        translate([0, 0, -saddle_h]) cylinder(r = body_r, h = saddle_h + 0.01);
    }
}

module body() {
    hull() {
        puck();
        saddle_block();
    }
}

// Rohr entlang X, Scheitel bei z = 0. Oben abgeflachte Tropfenform,
// damit die Wölbung beim Druck nur eine kurze Bruecke braucht.
module tube_cut() {
    rotate([0, 90, 0])
        linear_extrude(height = 2 * body_d, center = true)
            intersection() {
                hull() {
                    translate([tube_r, 0]) circle(r = tube_r);
                    translate([tube_r - tube_r * sqrt(2), 0])
                        square(0.01, center = true);
                }
                // Abflachung am Scheitel (z = 0 entspricht x = 0 nach rotate)
                translate([0, -tube_d]) square([4 * tube_d, 2 * tube_d]);
            }
}

// Oesen links und rechts vom Rohr, unten am Sattel. Der Kabelbinder
// laeuft senkrecht durch das Loch und um das Rohr herum.
eyelet_xs  = eyelet_count == 1 ? [0] : [-eyelet_pitch / 2, eyelet_pitch / 2];
eyelet_len = strap_w + 2 * eyelet_wall;            // entlang dem Rohr
hole_y     = saddle_w / 2 + eyelet_h + 1;          // Innenkante Loch, frei von der Schraege
eyelet_y   = hole_y + strap_t + eyelet_wall;       // Aussenkante Oese

module eyelets() {
    for (sy = [-1, 1], x = eyelet_xs)
        mirror([0, sy < 0 ? 1 : 0, 0])
            translate([x, 0, -saddle_h])
                hull() {
                    translate([-eyelet_len / 2, 0, 0])
                        cube([eyelet_len, 0.01, eyelet_h]);
                    for (dx = [-1, 1])
                        translate([dx * (eyelet_len / 2 - eyelet_wall), eyelet_y - eyelet_wall, 0])
                            cylinder(r = eyelet_wall, h = eyelet_h);
                }
}

module eyelet_holes() {
    for (sy = [-1, 1], x = eyelet_xs)
        mirror([0, sy < 0 ? 1 : 0, 0])
            translate([x - strap_w / 2, hole_y, -saddle_h - 1])
                cube([strap_w, strap_t, eyelet_h + 2]);
}

module ring_sector(r_in, r_out, z0, h, a0, a) {
    translate([0, 0, z0])
        rotate([0, 0, a0])
            rotate_extrude(angle = a)
                translate([r_in, 0]) square([r_out - r_in, h]);
}

module washer_pocket() {
    translate([0, 0, pocket_z]) {
        cylinder(r = pocket_r, h = body_h);
    }
}

// Freischnitte, die aus der Taschenwand federnde Laschen machen
module clip_reliefs() {
    gap_a  = clip_gap / (pocket_r + clip_t) * 180 / PI;   // Seitenschlitz in Grad
    for (i = [0 : clip_count - 1]) {
        a = i * 360 / clip_count;
        // hinter der Lasche
        ring_sector(pocket_r + clip_t, pocket_r + clip_t + clip_gap,
                    relief_z, body_h, a - clip_angle / 2 - gap_a, clip_angle + 2 * gap_a);
        // seitlich
        for (s = [-1, 1])
            ring_sector(pocket_r - 0.01, pocket_r + clip_t + 0.01,
                        relief_z, body_h,
                        a + s * clip_angle / 2 - (s < 0 ? gap_a : 0), gap_a);
    }
}

// Rastnasen oben auf den Laschen: innen 45-Grad-Einfuehrschraege,
// unten flache Rastkante (druckt als 0.6 mm Ueberhang, kein Problem)
module clip_lips() {
    for (i = [0 : clip_count - 1]) {
        a = i * 360 / clip_count;
        translate([0, 0, body_h + lip_clear])
            rotate([0, 0, a - clip_angle / 2])
                rotate_extrude(angle = clip_angle)
                    polygon([
                        [pocket_r - lip_in, 0],
                        [pocket_r + clip_t, 0],
                        [pocket_r + clip_t, lip_h],
                        [pocket_r - lip_in + lip_h * 0.6, lip_h],
                    ]);
        // Steg zwischen Lasche und Nase (fuellt den Spalt lip_clear)
        ring_sector(pocket_r, pocket_r + clip_t, body_h - 0.01, lip_clear + 0.02,
                    a - clip_angle / 2, clip_angle);
    }
}

// Zentrierzapfen im Scheibenloch
module center_peg() {
    translate([0, 0, pocket_z - 0.01])
        cylinder(d1 = washer_hole - 0.2, d2 = washer_hole - 1.2, h = washer_t - 0.4);
}

module holder() {
    difference() {
        union() {
            body();
            eyelets();
        }
        tube_cut();
        eyelet_holes();
        washer_pocket();
        clip_reliefs();
    }
    clip_lips();
    center_peg();
}

module washer_preview() {
    %translate([0, 0, pocket_z])
        difference() {
            cylinder(d = washer_d, h = washer_t);
            translate([0, 0, -1]) cylinder(d = washer_hole, h = washer_t + 2);
        }
}

// Druckausrichtung: Sattel unten auf dem Bett
translate([0, 0, saddle_h]) {
    holder();
    washer_preview();
}
