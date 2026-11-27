// =============================================================
//  Recipient dublu pentru boabe - DeLonghi Magnifica Start ECAM 220.21.B
//  Se pune IN recipientul original de boabe. Doua compartimente (A / B),
//  un disc selector la iesire alege din care compartiment cad boabele
//  in rasnita. Rotesti butonul de sus cu 180 de grade ca sa schimbi.
//
//  MASOARA-TI APARATUL si ajusteaza parametrii de mai jos inainte de print!
//  Piese: "cutie", "selector" (disc + ax), "buton", sau "tot" (previzualizare)
// =============================================================

piesa = "tot";            // "cutie" | "selector" | "buton" | "tot"

// ---- Dimensiuni de masurat (mm) ----
lungime      = 120;   // latimea exterioara a insertului (stanga-dreapta), putin sub deschiderea recipientului
adancime     = 90;    // adancimea exterioara (fata-spate)
inaltime     = 70;    // de la gura de iesire pana la buza de sus; trebuie sa incapa sub capac
raza_colt    = 12;    // rotunjirea colturilor, ca la recipientul original
iesire_d     = 40;    // diametrul interior al gurii de iesire (sa intre in gatul rasnitei)
iesire_x     = 0;     // decalajul gurii fata de centrul insertului (daca rasnita nu e pe centru)
iesire_y     = 0;
gura_h       = 8;     // inaltimea tubului de iesire
buza_lat     = 4;     // cat iese buza de sprijin peste marginea recipientului (0 = fara buza)
buza_gros    = 2;

// Decupaj pentru butonul de reglaj al macinarii (e IN recipient, spate-dreapta).
// Pune decupaj_x/y = 0 daca insertul nu il acopera.
decupaj_x    = 30;    // pe lungime
decupaj_y    = 30;    // pe adancime

// ---- Constructie ----
perete       = 2;
coloana_d    = 12;    // coloana centrala prin care trece axul
ax_d         = 8;
joc          = 0.4;   // toleranta ax / alezaj (marcheaza 0.3-0.5 dupa imprimanta)
disc_gros    = 2.5;
disc_joc     = 0.6;   // spatiul dintre gura si disc
deschidere   = 150;   // unghiul fantei din disc (grade, < 180)

$fn = 96;
eps = 0.01;
ox = iesire_x; oy = iesire_y;

// ---------- forme 2D ----------
module contur() {
    difference() {
        offset(r = raza_colt) offset(delta = -raza_colt)
            square([lungime, adancime], center = true);
        if (decupaj_x > 0 && decupaj_y > 0)
            translate([lungime/2 - decupaj_x, adancime/2 - decupaj_y])
                offset(r = 3) offset(delta = -3)
                    square([decupaj_x + 10, decupaj_y + 10]);
    }
}

// palnie: de la dreptunghiul de sus pana la cercul de iesire
module palnie(off, sus = 0) {
    hull() {
        translate([0, 0, inaltime - eps + sus])
            linear_extrude(eps) offset(delta = off)
                offset(r = raza_colt) offset(delta = -raza_colt)
                    square([lungime, adancime], center = true);
        translate([ox, oy, gura_h]) cylinder(d = iesire_d + 2*(off + perete), h = eps);
    }
}

module cutie() {
    difference() {
        union() {
            // corpul exterior al palniei, taiat dupa contur (cu decupaj)
            intersection() {
                palnie(0);
                linear_extrude(inaltime) contur();
            }
            // tubul de iesire
            translate([ox, oy, 0]) cylinder(d = iesire_d + 2*perete, h = gura_h + eps);
            // buza de sprijin
            if (buza_lat > 0)
                translate([0, 0, inaltime - buza_gros])
                    linear_extrude(buza_gros)
                        difference() {
                            offset(delta = buza_lat) contur();
                            offset(delta = -perete) contur();
                        }
        }
        // golul interior
        intersection() {
            palnie(-perete, 5);
            translate([0, 0, gura_h]) linear_extrude(inaltime + 5) offset(delta = -perete) contur();
        }
        translate([ox, oy, -eps]) cylinder(d = iesire_d, h = gura_h + 2*eps);
        translate([ox, oy, -1]) cylinder(d = ax_d + 2*joc, h = inaltime + 2);
    }
    // peretele despartitor (pe axa X = iesire_x) + coloana axului
    difference() {
        intersection() {
            union() {
                translate([ox - perete/2, -adancime, 0]) cube([perete, 2*adancime, inaltime]);
                translate([ox, oy, 0]) cylinder(d = coloana_d, h = inaltime);
            }
            union() {
                palnie(-perete/2);
                translate([ox, oy, 0]) cylinder(d = iesire_d + perete, h = gura_h + eps);
            }
            linear_extrude(inaltime) offset(delta = -perete/2) contur();
        }
        translate([ox, oy, -1]) cylinder(d = ax_d + 2*joc, h = inaltime + 2);
    }
    // litere A / B pe buza
    for (s = [[-1, "A"], [1, "B"]])
        translate([s[0] * lungime/4, -adancime/2 + perete/2 - buza_lat/2, inaltime])
            linear_extrude(0.8) text(s[1], size = 4.5, halign = "center", valign = "center",
                                     font = "Liberation Sans:style=Bold");
}

// disc + ax, o singura piesa. Fanta e orientata spre -X (compartimentul A) cand sageata butonului arata A.
lung_ax = inaltime + disc_joc + 10;
module selector() {
    difference() {
        cylinder(d = iesire_d + 2*perete + 4, h = disc_gros);
        // fanta in forma de sector
        translate([0, 0, -1]) linear_extrude(disc_gros + 2)
            difference() {
                intersection() {
                    circle(d = iesire_d);
                    rotate(180 - deschidere/2)
                        polygon([[0,0], for (a = [0:5:deschidere]) iesire_d * [cos(a), sin(a)]]);
                }
                circle(d = coloana_d);
            }
    }
    // ax cu teşitura plata (D) sus pentru buton
    difference() {
        cylinder(d = ax_d, h = disc_gros + lung_ax);
        translate([ax_d/2 - 1.2, -ax_d, disc_gros + lung_ax - 9]) cube([ax_d, 2*ax_d, 10]);
    }
}

module buton() {
    difference() {
        union() {
            cylinder(d = 26, h = 10);
            // sageata indicatoare (spre -X = fanta discului)
            translate([0, 0, 0]) linear_extrude(10)
                polygon([[-11, -5], [-21, 0], [-11, 5]]);
        }
        translate([0, 0, -eps]) linear_extrude(9 + eps)
            intersection() {
                circle(d = ax_d + 0.3);
                translate([-ax_d, -ax_d]) square([ax_d - 1.2 + ax_d/2 + 0.15, 2*ax_d]);
            }
        // striatii pentru aderenta
        for (a = [0:20:359]) rotate(a) translate([13, 0, -1]) cylinder(d = 2, h = 12);
    }
}

if (piesa == "cutie")    cutie();
if (piesa == "selector") selector();
if (piesa == "buton")    rotate([180, 0, 0]) buton();   // se printeaza cu fata in jos
if (piesa == "tot") {
    color("SaddleBrown", 0.85) cutie();
    color("Orange") translate([ox, oy, -disc_joc - disc_gros]) selector();
    color("DimGray") translate([ox, oy, inaltime + 1]) buton();
}

// verificare unghi palnie (boabele au nevoie de minim ~40 grade fata de orizontala)
_rise = inaltime - gura_h;
_run  = max(lungime/2 + abs(ox), adancime/2 + abs(oy)) - iesire_d/2;
echo(str("Unghi minim palnie: ", atan(_rise / _run), " grade (tinta >= 40)"));
