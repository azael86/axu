// Suport agățat tip inel (ca suportul original OASE) pentru FiltoSmart 60
// Inel oval care cuprinde partea de jos a filtrului + 2 stâlpi cu cârlige în J
// care se agață peste geamul acvariului. Toate valorile în mm.
//
// Printare: în picioare (inelul pe pat). Suport DOAR sub cârlige
// (buza care intră în acvariu); restul se printează fără suport. PETG.

/* [Filtru] */
filtru_L = 150;      // lungimea filtrului (paralel cu geamul)
filtru_l = 90;       // lățimea filtrului (perpendicular pe geam)
filtru_H = 164;      // înălțimea filtrului
joc      = 1.5;      // joc pe fiecare parte
raza_capete = 45;    // raza capetelor rotunjite (max = (filtru_l+2*joc)/2)

/* [Acvariu] */
geam_grosime = 6;    // grosimea geamului (MĂSOARĂ-L!)
geam_joc     = 1;    // joc suplimentar pentru geam / silicon
sub_margine  = 20;   // cât de jos stă capacul filtrului sub marginea geamului
buza_carlig  = 40;   // cât coboară cârligul în interiorul acvariului

/* [Construcție] */
perete_inel  = 3;    // grosimea inelului
inaltime_inel = 40;  // înălțimea inelului
buza_jos     = 4;    // buză interioară jos pe care se sprijină filtrul (0 = fără)
grosime_stalp = 6;   // grosimea stâlpilor și a cârligelor
latime_stalp = 25;   // lățimea stâlpilor
decupaj_cablu = true; // crestătură la un capăt (cablu / furtun)

$fn = 96;

// ---- derivate ----
int_L = filtru_L + 2*joc;
int_l = filtru_l + 2*joc;
r_int = min(raza_capete, int_l/2);
g = geam_grosime + geam_joc;
z_jos = -(filtru_H + sub_margine) - (buza_jos > 0 ? perete_inel : 0);
y0 = grosime_stalp;            // de aici începe interiorul inelului (spre exterior)

// Coordonate: X de-a lungul geamului, Y spre exterior (geamul în Y ∈ [-g,0]),
// Z sus (Z = 0 = muchia de sus a geamului).

module oval2d(L, l, r) {
    hull() for (x = [r, L - r], y = [r, l - r]) translate([x, y]) circle(r);
}

module inel() {
    translate([0, y0, z_jos]) difference() {
        union() {
            // banda ovală
            linear_extrude(inaltime_inel) difference() {
                offset(perete_inel) oval2d(int_L, int_l, r_int);
                oval2d(int_L, int_l, r_int);
            }
            // buza de jos (înclinată 45° ca să nu necesite suport)
            if (buza_jos > 0) difference() {
                linear_extrude(perete_inel + buza_jos) offset(perete_inel) oval2d(int_L, int_l, r_int);
                translate([0, 0, perete_inel - 0.01])
                    hull() {
                        linear_extrude(0.01) offset(-buza_jos) oval2d(int_L, int_l, r_int);
                        translate([0, 0, buza_jos]) linear_extrude(0.02) oval2d(int_L, int_l, r_int);
                    }
                translate([0, 0, -1]) linear_extrude(perete_inel + 2) offset(-buza_jos) oval2d(int_L, int_l, r_int);
            }
        }
        // crestătură pentru cablu la capătul din stânga
        if (decupaj_cablu)
            translate([-perete_inel - 1, int_l/2, inaltime_inel - 14])
                rotate([0, 90, 0]) hull() {
                    cylinder(d = 9, h = perete_inel + 2);
                    translate([-20, 0, 0]) cylinder(d = 9, h = perete_inel + 2);
                }
    }
    // perete spate drept, îngroșat, lipit de geam (umple între stâlpi și inel)
    translate([r_int, 0, z_jos]) cube([int_L - 2*r_int, y0, inaltime_inel]);
}

module stalp_cu_carlig() {
    // stâlp vertical, lipit de geam
    translate([0, 0, z_jos]) cube([latime_stalp, grosime_stalp, -z_jos + grosime_stalp]);
    // puntea peste geam
    translate([0, -g - grosime_stalp, 0]) cube([latime_stalp, g + grosime_stalp, grosime_stalp]);
    // buza din interiorul acvariului, cu vârf rotunjit
    translate([0, -g - grosime_stalp, -buza_carlig + grosime_stalp/2])
        cube([latime_stalp, grosime_stalp, buza_carlig + grosime_stalp/2]);
    translate([0, -g - grosime_stalp/2, -buza_carlig + grosime_stalp/2])
        rotate([0, 90, 0]) cylinder(d = grosime_stalp, h = latime_stalp);
}

module suport() {
    union() {
        inel();
        // stâlpii stau la capetele părții drepte a inelului
        for (x = [r_int, int_L - r_int])
            translate([x - latime_stalp/2, 0, 0]) stalp_cu_carlig();
    }
}

suport();

// Previzualizare (doar F5)
%translate([0, y0, -(filtru_H + sub_margine)]) linear_extrude(filtru_H) oval2d(int_L, int_l, r_int);
%translate([-30, -geam_grosime, -260]) cube([int_L + 60, geam_grosime, 260]);
