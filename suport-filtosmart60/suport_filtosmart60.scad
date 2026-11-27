// Suport agățat pe acvariu pentru filtrul OASE FiltoSmart 60
// Dimensiuni filtru (OASE): 150 x 90 x 164 mm (L x l x H)
//
// Suportul se agață pe marginea geamului acvariului (cârlige peste geam),
// iar filtrul stă într-un coș pe exteriorul acvariului.
// Toate valorile sunt în mm și pot fi modificate mai jos.
//
// Printare recomandată: culcat pe o parte laterală (fără suporturi),
// PETG, 4 perimetre, 25-30% infill.

/* [Filtru] */
filtru_L = 150;      // lungimea filtrului (paralel cu geamul)
filtru_l = 90;       // lățimea filtrului (perpendicular pe geam)
filtru_H = 164;      // înălțimea filtrului
joc      = 2;        // joc pe fiecare parte

/* [Acvariu] */
geam_grosime = 6;    // grosimea geamului acvariului (MĂSOARĂ-L!)
geam_joc     = 1;    // joc suplimentar pentru geam / silicon
carlig_interior = 30; // cât coboară cârligul în interiorul acvariului
sub_margine  = 20;   // cât de jos stă capacul filtrului sub marginea geamului

/* [Construcție] */
perete   = 4;        // grosime pereți
latime_carlig = 30;  // lățimea fiecărui cârlig
perete_cos = 45;     // înălțimea pereților coșului (față / lateral față)
fante    = true;     // fante de aerisire / scurgere în podea

$fn = 48;

// ---- valori derivate ----
int_L = filtru_L + 2*joc;
int_l = filtru_l + 2*joc;
ext_L = int_L + 2*perete;
z_podea = -(filtru_H + sub_margine);   // fața de sus a podelei
g = geam_grosime + geam_joc;            // deschiderea cârligului

// Sistem de coordonate:
//  X = de-a lungul geamului, Y = spre exterior (geamul ocupă Y ∈ [-g, 0]),
//  Z = sus (Z = 0 este muchia de sus a geamului).

module placa_spate() {
    // stă lipită de fața exterioară a geamului
    translate([0, 0, z_podea - perete])
        cube([ext_L, perete, -z_podea + perete + perete]);
}

module carlig() {
    // punte peste geam
    translate([0, -g - perete, 0]) cube([latime_carlig, g + 2*perete, perete]);
    // buză interioară
    translate([0, -g - perete, -carlig_interior])
        cube([latime_carlig, perete, carlig_interior + perete]);
}

module podea() {
    difference() {
        translate([0, 0, z_podea - perete])
            cube([ext_L, perete + int_l + perete, perete]);
        if (fante) {
            nr = floor(int_L / 16);
            pas = int_L / nr;
            for (i = [0 : nr - 1])
                translate([perete + pas*(i + 0.5) - 3, perete + 12, z_podea - perete - 1])
                    hull() {
                        translate([3, 0, 0]) cylinder(r = 3, h = perete + 2);
                        translate([3, int_l - 24, 0]) cylinder(r = 3, h = perete + 2);
                    }
        }
    }
}

module perete_fata() {
    translate([0, perete + int_l, z_podea - perete])
        cube([ext_L, perete, perete_cos + perete]);
}

module perete_lateral() {
    // triunghiular: înalt la spate (rigidizare), scund în față
    y_fata = perete + int_l + perete;
    z0 = z_podea - perete;
    z_sus_spate = -sub_margine - 10;
    rotate([90, 0, 90])
        linear_extrude(perete)
            polygon([
                [0, z0],
                [y_fata, z0],
                [y_fata, z_podea + perete_cos],
                [perete + 20, z_sus_spate],
                [0, z_sus_spate]
            ]);
}

module suport() {
    union() {
        placa_spate();
        carlig();
        translate([ext_L - latime_carlig, 0, 0]) carlig();
        podea();
        perete_fata();
        perete_lateral();
        translate([ext_L - perete, 0, 0]) perete_lateral();
    }
}

suport();

// Previzualizare filtru (doar în F5, nu apare în STL)
%translate([perete + joc, perete + joc, z_podea]) cube([filtru_L, filtru_l, filtru_H]);
// Previzualizare geam
%translate([-20, -geam_grosime, -250]) cube([ext_L + 40, geam_grosime, 250]);
