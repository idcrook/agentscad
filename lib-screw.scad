/*
 * Copyright (c) 2019, Gilles Bouissac
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *   * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * 
 * Description: 3D printable screws library
 * Author:      Gilles Bouissac
 */
use <scad-utils/lists.scad>
use <scad-utils/transformations.scad>
use <list-comprehension-demos/skin.scad>
use <extensions.scad>
use <printing.scad>

// ----------------------------------------
//
//          Bolt and Nuts Shape API
//
// ----------------------------------------

// Bolt orientation is:
//      Head bottom at [0,0,0]
//      Head goes Z-
//      Thread goes Z+
// Nut orientation is opposite:
//      Head top at [0,0,0]
//      Head goes Z+

// Bolt passage loose on head to fit any type of head
//  p    : bolt params (M1_6(), M2(), M2_5(), M3(), etc...)
//  Note : This passage will NOT block the bolt
module libBoltPassage( p ) {
    drill     = p[I_TD]-p[I_TP]+gap() ;
    local_tl  = p[I_TL] ;
    local_tlp = p[I_TLP] ;
    local_hlp = p[I_HLP] ;
    local_hdp = p[I_HDP] ;
    libBoltImpl (
        drill,            local_tl,
        p[I_TDP],         local_tlp,
        local_hdp,        local_hlp
    );
}

// Nut passage loose on head to fit any type of nut
//  p    : nut params (M1_6(), M2(), M2_5(), M3(), etc...)
//  Note : This passage will NOT block the nut
module libNutPassage( p ) {
    local_hdp = p[I_HDP] ;
    local_hlp = p[I_HLP] ;
    translate( [0,0,+local_hlp ] )
        libBoltImpl (
            0,         0,
            0,         0,
            local_hdp, local_hlp
        );
}

// Hexagonal nut passage
//  p    : bolt params (M1_6(), M2(), M2_5(), M3(), etc...)
//  Note : his passage will block the nut
module libNutHexagonalPassage( p ) {
    local_hhd = p[I_HHD] ;
    local_hlp = p[I_HHL]+2*gap() ;
    translate( [0,0,+local_hlp/2 ] )
        cylinder( r=local_hhd/2+gap(), h=local_hlp, center=true, $fn=6 );
}

// Hexagonal nut passage
//  p    : bolt params (M1_6(), M2(), M2_5(), M3(), etc...)
//  Note : This passage will block the nut
module libNutSquarePassage( p ) {
    local_shw = p[I_HTS] ;
    local_slp = p[I_HHL]+2*gap() ;
    translate( [0,0,+local_slp/2 ] )
        cube( [local_shw+gap(),local_shw+gap(),local_slp], center=true );
}

// Bolt passage Tight on head for Allen head
//  p    : bolt params (M1_6(), M2(), M2_5(), M3(), etc...)
module libBoltAllenPassage( p ) {
    drill     = p[I_TD]-p[I_TP]+gap() ;
    local_tl  = p[I_TL] ;
    local_tlp = p[I_TLP] ;
    union() {
        libBoltImpl (
            drill,             local_tl+gap(),
            p[I_TDP],          local_tlp,
            p[I_AHD]+2*gap(),  p[I_HLP]
        );
    }
}

// Bolt passage Tight on head for Hexagonal head
//  p    : bolt params (M1_6(), M2(), M2_5(), M3(), etc...)
//  Note : This passage will block the bolt
module libBoltHexagonalPassage( p ) {
    drill     = p[I_TD]-p[I_TP]+gap() ;
    local_tl  = p[I_TL] ;
    local_tlp = p[I_TLP] ;
    union() {
        libBoltImpl (
            drill,             local_tl+gap(),
            p[I_TDP],          local_tlp,
            0,       0
        );
        translate( [0,0,-p[I_HLP]/2 ] )
            cylinder( r=p[I_HHD]/2+gap(), h=p[I_HLP], center=true, $fn=6 );
    }
}

// Bolt with Allen head
//  p    : Bolt params (M1_6(), M2(), M2_5(), M3(), etc...)
//  bt   : Bevel top of head
module libBoltAllen( p, bt=true ) {
    // +gap() for easier fitting with the tool
    tool_r   = p[I_ATS]/(2*cos(30))+gap();
    cone_h   = tool_r/2*tan(30);
    tool_l   = p[I_AHL]*2/3;
    local_tl = p[I_TL] ;
    difference() {
        union() {
            libBoltImpl (
                p[I_TD],   local_tl,
                0,         0,
                0,         0
            );
            translate( [0,0,-p[I_AHL]/2] )
            intersection() {
                cylinder( r=p[I_AHD]/2, h=p[I_AHL], center=true );
                libBevelShape(
                    p[I_AHL],
                    p[I_AHD]-2*(p[I_TD]/10)/tan(BEVEL_ALLEN_A),
                    a=BEVEL_ALLEN_A,
                    t=false,
                    b=bt);
            }
        }
        translate( [0,0,-p[I_AHL]-VGG] ) {
            cylinder( r=tool_r, h=tool_l, $fn=6 );
            translate( [0,0,tool_l] )
            cylinder( r1=tool_r, r2=0, h=cone_h, $fn=6 );

        }
    }
}

// Bolt with Hexagonal head
//  p    : bolt params (M1_6(), M2(), M2_5(), M3(), etc...)
//  bt   : Bevel top of head
//  bb   : Bevel bottom of head
module libBoltHexagonal( p, bt=true, bb=true ) {
    local_tl  = p[I_TL] ;
    local_hhd = p[I_HHD] ;
    local_hhl = p[I_HHL] ;
    union() {
        libBoltImpl (
            p[I_TD], local_tl,
            0,       0,
            0,       0
        );
        translate( [0,0,-local_hhl/2 ] )
        intersection() {
            // -gap() for easier fitting with the tool
            cylinder( r=(local_hhd-gap())/2, h=local_hhl, center=true, $fn=6 );
            libBevelShape( local_hhl, p[I_HTS]-2*gap()*cos(30), b=bt, t=bb );
        }
    }
}

// Hexagonal nut
//  p    : bolt params (M1_6(), M2(), M2_5(), M3(), etc...)
//  Note : This passage will prevent nut from turning
module libNutHexagonal( p, bt=true, bb=true ) {
    local_hhd = p[I_HHD] ;
    local_hhl = p[I_HHL] ;
    translate( [0,0,+local_hhl/2 ] )
        intersection() {
            difference() {
                // -gap() for easier fitting with the tool
                cylinder( r=(local_hhd-gap())/2, h=local_hhl, center=true, $fn=6 );
                cylinder( r=p[I_TAP]/2,  h=local_hhl+VGG, center=true );
            }
            libBevelShape( local_hhl, p[I_HTS]-2*gap()*cos(30), b=bt, t=bb );
        }
}

// Square nut
//  p    : bolt params (M1_6(), M2(), M2_5(), M3(), etc...)
//  shl  : square head length, <0 means use default hexagonal head length from p
//  Note : This passage will prevent nut from turning
module libNutSquare( p, bt=true, bb=true ) {
    local_shd = p[I_HTS] ;
    local_shl = p[I_HHL] ;

    translate( [0,0,+local_shl/2 ] )
        intersection() {
            difference() {
                // -gap() for easier fitting with the tool
                cube( [local_shd-gap(),local_shd-gap(),local_shl], center=true );
                cylinder( r=p[I_TAP]/2,  h=local_shl, center=true );
            }
            // libBevelShape( local_shl, local_shd-gap(), a=BEVEL_SQUARE_A, b=false );
            libBevelShape( local_shl, (local_shd-gap())/cos(45)-5*p[I_TD]/10, a=BEVEL_SQUARE_A, b=bt, t=bb );
            cylinder( r=(local_shd-gap())/(2*cos(45))-p[I_TD]/10,  h=local_shl, center=true );
        }
}

// l    : head length
// d    : diameter or tangent circle on top of head
// a    : beveling angle
// t    : true to get the top bevel
// b    : true to get the bottom bevel
module libBevelShape( l, d, a=BEVEL_HEXA_A, b=true, t=true ) {
    h  = (d/2)*tan(a);
    r  = (l+h)/tan(a);
    intersection() {
        if ( t ) {
            translate([0,0,-l/2])
            cylinder( r1=r, r2=0, h=(l+h) );
        }
        if ( b ) {
            translate([0,0,-h-l/2])
            cylinder( r1=0, r2=r, h=(l+h) );
        }
    }
}

// Guess what is the better standard thread from the given one
//   if td>0: will pick the first screw larger than the given value
//   if td<0: will pick the first screw smaller than the given value
EXCLUDED=1e100;
function screwGuess ( data,td,tl=-1,hdp=-1,hlp=-1,ahd=-1,ahl=-1,hhd=-1,hhl=-1,tdp=-1,tlp=-1) =
let (
    dists    = [ for( i=[0:len(data)-1] ) let ( diff=data[i][CTD]-abs(td) )
        ( diff==0 || sign(td)==0 || sign(td)==sign(diff) ) ? abs(diff) : EXCLUDED ],
    sorted   = sortIndexed(dists),
    filtered = [ for (a=sorted) if (a[0]!=EXCLUDED) a ],
    idx      = len(filtered)==0 ? undef : filtered[0][1]
)
libScrewDataCompletion(
    data = data,
    idx  = idx,
    n    = undef,
    p    = undef,
    td   = undef,
    tl   = tl,
    hdp  = hdp,
    hlp  = hlp,
    ahd  = ahd,
    ahl  = ahl,
    ats  = undef,
    hhd  = hhd,
    hhl  = hhl,
    tdp  = tdp,
    tlp  = tlp
);

// Clones a screw allowing to overrides some characteristics
function screwClone (data,p,tl=-1,hdp=-1,hlp=-1,ahd=-1,ahl=-1,hhd=-1,hhl=-1,tdp=-1,tlp=-1) =
libScrewDataCompletion(
    data = data,
    idx  = p[I_IDX],
    n    = p[I_NAME],
    p    = p[I_TP],
    td   = p[I_TD],
    tl   = tl<0  ? p[I_TL]  : tl,
    hdp  = hdp<0 ? p[I_HDP] : hdp,
    hlp  = hlp<0 ? p[I_HLP] : hlp,
    ahd  = ahd<0 ? p[I_AHD] : ahd,
    ahl  = ahl<0 ? p[I_AHL] : ahl,
    ats  = p[I_ATS],
    hhd  = hhd<0 ? p[I_HHD] : hhd,
    hhl  = hhl<0 ? p[I_HHL] : hhl,
    tdp  = tdp<0 ? p[I_TDP] : tdp,
    tlp  = tlp<0 ? p[I_TLP] : tlp
);

// Data accessors on data
function screwGetIdx(s)                 = s[I_IDX];
function screwGetName(s)                = s[I_NAME];
function screwGetTapD(s)                = s[I_TAP];
function screwGetPitch(s)               = s[I_TP];
function screwGetThreadD(s)             = s[I_TD];
function screwGetThreadDP(s)            = s[I_TDP];
function screwGetThreadL(s)             = s[I_TL];
function screwGetThreadLP(s)            = s[I_TLP];
function screwGetHeadDP(s)              = s[I_HDP];
function screwGetHeadLP(s)              = s[I_HLP];

function screwGetAllenHeadD(s)          = s[I_AHD];
function screwGetAllenHeadL(s)          = s[I_AHL];
function screwGetAllenToolSize(s)       = s[I_ATS];

function screwGetHexagonalHeadD(s)      = s[I_HHD];
function screwGetHexagonalHeadL(s)      = s[I_HHL];
function screwGetHexagonalToolSize(s)   = s[I_HTS];

function screwGetSquareHeadD(s)         = s[I_HTS];
function screwGetSquareHeadL(s)         = s[I_HHL];
function screwGetSquareToolSize(s)      = s[I_HTS];

// Values helpfull to draw threads
function screwGetFunctionalRadiuses(s)  = s[I_RADF];
function screwGetGlobalRadiuses(s)      = s[I_RADG];
function screwGetSmoothRadiuses(s)      = s[I_RADS];
function screwGetSmoothCenters(s)       = s[I_CENTR];
function screwGetFlatHalfLenght(s)      = s[I_FLAT];
function screwGetFlankAngle(s)          = s[I_ANGLE];

// ----------------------------------------
//
//        Bolt and Nuts Threaded API
//
// ----------------------------------------

// Renders an external thread (for bolts)
//   l: Thread length
//   f: Generates flat faces if true
module libThreadExternal ( screw, l=-1, f=true ) {
    local_l   = l<0 ? screwGetThreadL(screw) : l ;
    rotations = local_l/screwGetPitch(screw) + (f ? 1:-1) ;
    profile   = screwThreadProfile ( screw, I=false );
    clipL     = local_l;
    clipW     = screwGetThreadD(screw)+10;
    rotate([0,-90,0])
        translate([f?-screwGetPitch(screw):0,0,0])
        intersection() {
            skin( screwThreadSlices(profile, screwGetPitch(screw), rotations) );
            if ( f ) {
                translate([screwGetPitch(screw)+clipL/2,0,0])
                    cube([clipL, clipW, clipW],center=true);
            }
        }
}

// Renders an internal thread (for nuts)
//   l: Thread length
//   t: Thickness of cylinder containing the thread
//   f: Generates flat faces if true
module libThreadInternal ( screw, l=-1, t=-1, f=true ) {
    local_l   = l<0 ? screwGetThreadL(screw): l;
    rotations = local_l/screwGetPitch(screw) + (f ? 1:-1) ;
    profile   = screwThreadProfile ( screw, t=t, I=true );
    clipL     = local_l;
    clipW     = screwGetThreadD(screw)+10;
    rotate([0,-90,0])
        translate([f?-screwGetPitch(screw):0,0,0])
        intersection() {
            skin( screwThreadSlices(profile, screwGetPitch(screw), rotations) );
            if ( f ) {
                translate([screwGetPitch(screw)+clipL/2,0,0])
                    cube([clipL, clipW, clipW],center=true);
            }
        }
}

// Nut with Hexagonal head
//  bt   : Bevel top of head
//  bb   : Bevel bottom of head
module libNutHexagonalThreaded( screw, bt=true, bb=true ) {
    length = screwGetHexagonalHeadL(screw);
    libThreadInternal ( screw, length );
    difference() {
        libNutHexagonal(screw,bt=bt,bb=bb);
        libBoltPassage(screw);
    }
}

// Nut with Square head
//  bt   : Bevel top of head
//  bb   : Bevel bottom of head
module libNutSquareThreaded( screw, bt=true, bb=true ) {
    length = screwGetSquareHeadL(screw);
    libThreadInternal ( screw, length );
    difference() {
        libNutSquare(screw,bt=bt,bb=bb);
        libBoltPassage(screw);
    }
}

// Bolt with Hexagonal head
//  bt   : Bevel top of head
//  bb   : Bevel bottom of head
module libBoltHexagonalThreaded( screw, bt=true, bb=true ) {
    libThreadExternal ( screw );
    translate([0,0,0])
        libBoltHexagonal(screwClone(data=undef,p=screw,tl=0),bt=bt,bb=bb);
}

// Bolt with Allen head
//  bt   : Bevel top of head
module libBoltAllenThreaded( screw, bt=true ) {
    libThreadExternal ( screw );
    translate([0,0,0])
        libBoltAllen(screwClone(data=undef,p=screw,tl=0),bt=bt);
}

// ----------------------------------------
//
//    Implementation
//
// ----------------------------------------

// Renders a bolt with given parameters for Thread, Thread passage and Head
module libBoltImpl( td, tl, tdp, tlp, hd, hl ) {
    translate( [0,0,+(tl+tlp)/2 ] )
        cylinder( r=td/2, h=tl-tlp, center=true );
    translate( [0,0,+tlp/2 ] )
        cylinder( r=tdp/2, h=tlp+VGG, center=true );
    if ( hl>0 ) {
        translate( [0,0,-hl/2 ] )
            cylinder( r=hd/2, h=hl, center=true );
    }
}

VGG            = 0.01;  // Visual Glich Guard
MFG            = 0.001; // Manifold Guard
THREAD_ANGLE   = 60;    // Thread flanks V angle
BEVEL_HEXA_A   = 30;    // Hexagonal head bevel angle
BEVEL_SQUARE_A = 30;    // Square head bevel angle
BEVEL_ALLEN_A  = 30;    // Allen head bevel angle

I_IDX   =  0;
I_NAME  =  1;
I_TP    =  2; // Thread Pitch: Distance between threads
I_TAP   =  3; // Tap diameter
I_TD    =  4; // Thread Diameter
I_TDP   =  5; // Thread Passage Diameter
I_TL    =  6; // Thread Length
I_TLP   =  7; // Thread Passage Length
I_HDP   =  8; // Head Diameter Passage
I_HLP   =  9; // Head Length Passage
I_AHD   = 10; // Head Diameter for Allen head
I_AHL   = 11; // Head Length for Allen head
I_ATS   = 12; // Allen Tool Size
I_HHD   = 13; // Head Diameter for Hexagonal head
I_HHL   = 14; // Head Length for Hexagonal head
I_HTS   = 15; // Hexagonal Tool Size
I_RADF  = 16; // Functional thread enclosing radiuses (between flat parts)
I_RADG  = 17; // Global thread enclosing radiuses (with round parts)
I_FLAT  = 18; // Flat parts HALF length
I_RADS  = 19; // Smoothing parts Radiuses (circular parts)
I_CENTR = 20; // Centers of round parts
I_ANGLE = 21; // Thread flanks V angle

function libScrewDataCompletion( data,idx,n=undef,p=undef,td=undef,tl=undef,hdp=undef,hlp=undef,ahd=undef,ahl=undef,ats=undef,hhd=undef,hhl=undef,tdp=undef,tlp=undef ) = let (
    local_name = is_undef(n)   ? data[idx][CNAME]  : n,
    local_p    = is_undef(p)   ? data[idx][CPITCH] : p,
    local_td   = is_undef(td)  ? data[idx][CTD]    : td,
    local_tl   = is_undef(tl)  ? data[idx][CTL]    : tl,
    local_ahl  = is_undef(ahl) ? ( is_undef(data[idx][CAHL]) ? local_td                : data[idx][CAHL] ) : ahl,
    local_ats  = is_undef(ats) ? ( is_undef(data[idx][CATS]) ? local_td*3/4            : data[idx][CATS] ) : ats,
    local_hhl  = is_undef(hhl) ? ( is_undef(data[idx][CHHL]) ? local_td*7/10           : data[idx][CHHL] ) : hhl,
    local_hts  = is_undef(hhd) ? ( is_undef(data[idx][CHTS]) ? local_td*cos(30)*26/15  : data[idx][CHTS] ) : hhd*cos(30),
    local_ahd  = is_undef(ahd) ? ( is_undef(data[idx][CAHD]) ? local_hts               : data[idx][CAHD] ) : ahd,
    local_hdp  = is_undef(hdp) ? ( is_undef(data[idx][CHDP]) ? local_hts/cos(45)       : data[idx][CHDP] ) : hdp,
    local_hlp  = is_undef(hlp) ? ( is_undef(data[idx][CHLP]) ? local_ahl               : data[idx][CHLP] ) : hlp,
    local_hhd  = is_undef(hhd) ? local_hts/cos(30) : hhd,
    local_tlp  = (is_undef(tlp) || tlp>local_tl)   ? local_tl : tlp,

    // Metric screw profile is well defined by wikipedia:
    //   https://en.wikipedia.org/wiki/ISO_metric_screw_thread
    Theta     = THREAD_ANGLE/2,
    H         = local_p/(2*tan(Theta)),
    Rmaj      = local_td/2,
    Rmin      = Rmaj - 5*H/8,
    Fmin      = local_p/8, // Flat part half length on Dmin
    Fmaj      = local_p/16,
    RRmin     = Fmin/cos(Theta),
    RRmaj     = Fmaj/cos(Theta),
    Cmin      = [ Fmin+MFG, Rmin+RRmin*sin(Theta) ],
    Cmaj      = [ Fmin+local_p/2, Rmaj-RRmaj*sin(Theta) ],
    RTop      = Cmaj.y+RRmaj,
    RBot      = Cmin.y-RRmin,

    // reason for gap(): see thread drawing functions
    local_tdp = is_undef(tdp) ? 2*(RTop+gap()) : tdp
) [
    idx,
    local_name,
    local_p,                   // TP
    local_td-local_p,          // TAP
    local_td,                  // TD
    local_tdp,                 // TDP
    local_tl,                  // TL
    local_tlp,                 // TLP
    local_hdp,                 // HDP
    local_hlp,                 // HLP
    local_ahd,                 // AHD 
    local_ahl,                 // AHL
    local_ats,                 // ATS
    local_hhd,                 // HHD
    local_hhl,                 // HHL
    local_hts,                 // HTS
    [ Rmin,  Rmaj  ],          // RADF
    [ RBot,  RTop  ],          // RADE
    [ Fmin,  Fmaj  ],          // FLAT
    [ RRmin, RRmaj ],          // RADR
    [ Cmin,  Cmaj  ],          // CENTR
    THREAD_ANGLE               // ANGLE
];

//
// Raw input data (before completion) indexes
//
CNAME    =  0;
CPITCH   =  1; // Pitch (mm)
CTD      =  2; // Thread external Diameter (mm)
CTL      =  3; // Thread Length default value (mm)
CHDP     =  4; // Head Diameter Passage enough for any tool (mm)
CHLP     =  5; // Head Length Passage default value (mm)
CAHD     =  6; // Allen Head Diameter tight, do not allow tool passage, only head (mm)
CAHL     =  7; // Allen Head Length tight (mm)
CATS     =  8; // Allen Tool Size (mm)
// CHHD  = Hexagonal Head Diameter tight, do not allow tool passage, only head: Computed from CHTS: CHTS/cos(30)
CHHL     =  9; // Hexagonal Head Length tight (mm)
CHTS     = 10; // Hexagonal Tool Size (mm)

MXANGLE  = 60;

// Metric screw profile is well defined by wikipedia:
//   https://en.wikipedia.org/wiki/ISO_metric_screw_thread
//
// T: Optional Thickness of the cylinder holding internal thread (default: NOZZLE)
// I: Optional Internal (nut) profile if true, External (bolt) if false (default), 
function screwThreadProfile( data, t=-1, I=false ) =
    let (
        Theta  = screwGetFlankAngle(data)/2,
        p      = screwGetPitch(data),
        delta  = I ? +gap() : -gap(3/4),
        Rmaj   = screwGetFunctionalRadiuses(data)[1] + delta,
        Rmin   = screwGetFunctionalRadiuses(data)[0] + delta,
        RBot   = screwGetGlobalRadiuses(data)[0],
        Fmin   = screwGetFlatHalfLenght(data)[0],
        Fmaj   = screwGetFlatHalfLenght(data)[1],
        RRmin  = screwGetSmoothRadiuses(data)[0],
        RRmaj  = screwGetSmoothRadiuses(data)[1],
        Cmino  = screwGetSmoothCenters(data)[0],
        Cmajo  = screwGetSmoothCenters(data)[1],
        Cmin   = [Cmino.x+MFG,Cmino.y+delta],
        Cmaj   = [Cmajo.x,Cmajo.y+delta],

        Tmin   = (Rmin-RBot)+nozzle(1.5),
        Tloc   = (t<Tmin ? Tmin : t)
    )
    I ?
        flatten([
            [ [0+MFG,Rmaj+Tloc] ],
            [
                [ 0+MFG,      Rmin ],
                [ 2*Fmin,     Rmin ]
            ],
            screwThreadRounding( RRmaj, Cmaj, +(180-Theta), +(Theta) ),
            [ [ p, Rmin ], [ p, Rmaj+Tloc ] ]
        ])
    :
        flatten([
            [
                 [ 0+MFG,         0+MFG ]
                ,[ p,             0+MFG ]
                ,[ p,             Rmin ]
                ,[ Fmin+p/2+Fmaj, Rmaj ]
                ,[ Fmin+p/2-Fmaj, Rmaj ]
            ]
            ,screwThreadRounding( RRmin, Cmin, -(Theta), -(180-Theta) )
        ])
    ;
function screwThreadRounding( R, C, T1, T2) = [
    let ( range=T2-T1, step=range/($fn<10?1:$fn/10) )
    for ( a=[T1:step:T2] )
        [ C.x+R*cos(a), C.y+R*sin(a) ]
];
function screwThreadSlices( profile, pitch, rotations=1 ) = [
    let ( step=360/($fn<3?3:$fn) )
    for ( a=[-step/2:step:rotations*360+step/2] )
        transform(translation([a*pitch/360,0,0])*rotation([a,0,0]), profile )
];
