/* [General] */
Snaps = 10;

Part = "Set"; // [Male, Female, Set]

Resolution = 120; // [20:300]

/* [Values] */

// in mm
Diameter = 40;

// in mm (can be helpful to overcome printing-precission issues)
SnapFreeAreaDiameterLarge = 6;

// in mm
SnapFreeAreaDiameterSmall = 4;

// in mm
SnapHeight = 4;

// in mm (will be added to female GroundPlateThickness)
LeadHeight = 1.5;

// in mm (for smaller torosional force - this value is added to [SnapHeight] and then cut off)
CutTip = 0;

// in mm
ScrewHoleDiameter = 2;

// in mm
GroundPlateThickness = 2;

// in mm
Threshold = 1;

/* [Hide]*/

module singleSnap(snaps, h, ct, d, res, gpt) {
	// full height
	fh = h + ct;
	
	// original size
	angle = 180 / snaps;
	side = tan(angle) * d / 2;
	
	// adjusted size (necessary to overcome compilation issues)
	aH = fh + gpt / 2;
	ratio = aH / fh;
	aSide = side * ratio;

	translate([d/2,0,0]) {
		rotate([0,-90,0]) {
			linear_extrude(height = d/2,center = false, twist = 0, scale = [1,1e-308], slices = res) {
				polygon(
					points=[[aH, 0],[0, aSide],[0, -aSide]],
					paths=[[0,1,2]]
				);
			}
		}
	}
}

module allSnaps(snaps, h, ct, d, res, gpt) {
	intersection() {
		for(i = [0:snaps - 1]) {
			rotate((360 / snaps) * i, [0, 0, 1]) {
				singleSnap(snaps, h, ct, d, res, gpt);
			}
		}
		translate([0, 0, ct / 2]) {
			cylinder(h = h + gpt / 2, r = d / 2);
		}
	}
}

module fullDisc(female=true, snaps, h, lh, ct, d, res, snapfreel, snapfrees, gpt, screw, threshold) {
	union() {
		// 0.5 * gpt because of the necessary adjustment in singleSnap
		translate([0, 0, 0.5 * gpt - ct / 2]) {
			allSnaps(snaps, h, ct, d, res, gpt);
		}
		cylinder(h = gpt, d = d );
	}
}

module screwHole(h, gpt, screw) {
	translate([0, 0, -1]) {
		cylinder(h = h + gpt + 2, d = screw);
	}
}

module lock(h, snapfreel, snapfrees, lh) {
	usedsnapfreel = max(snapfreel, snapfrees);
	usedsnapfrees = min(snapfreel, snapfrees);
	cylinder(h = h + lh, d1 = usedsnapfreel, d2=usedsnapfrees);
}

module femaleDisc(snaps, h, lh, ct, d, res, snapfreel, snapfrees, gpt, screw, threshold) {
	difference() {
		difference() {
			// gpt = gpt + lh
			fullDisc(true, snaps, h, lh, ct, d, res, snapfreel, snapfrees, gpt + lh, screw, threshold);
			translate([0,0,gpt+h+lh]) {
				rotate([180,0,0]) {
					union() {
						// snapfree = snapfree + threshold / 2
						lock(h, snapfreel + threshold / 2, snapfrees + threshold / 2, lh);
						translate([0,0,-1]) {
							cylinder(h=1, d=max(snapfreel, snapfrees));
						}
					}
				}
			}
		}
		// gpt = gpt + lh
		screwHole(h, gpt + lh, screw);
	}
}

module maleDisc(snaps, h, lh, ct, d, res, snapfreel, snapfrees, gpt, screw, threshold) {
	difference() {
		union() {
			fullDisc(false, snaps, h, lh, ct, d, res, snapfreel, snapfrees, gpt, screw, threshold);
			translate([0,0,gpt]) {
				// snapfree = snapfree - threshold / 2
				lock(h, snapfreel - threshold / 2, snapfrees - threshold / 2, lh);
			}
		}
		screwHole(h + lh, gpt, screw);
	}
}

module singleMaleDisc(
	snaps = Snaps,
	d = Diameter,
	h = SnapHeight,
	lh = LeadHeight,
	ct = CutTip,
	res = Resolution,
	screw = ScrewHoleDiameter,
	gpt = GroundPlateThickness,
	snapfreel = SnapFreeAreaDiameterLarge,
	snapfrees = SnapFreeAreaDiameterSmall,
	threshold = Threshold
) {
	maleDisc(snaps, h, lh, ct, d, res, snapfreel, snapfrees, gpt, screw, threshold);
}

module singleFemaleDisc(
	snaps = Snaps,
	d = Diameter,
	h = SnapHeight,
	lh = LeadHeight,
	ct = CutTip,
	res = Resolution,
	screw = ScrewHoleDiameter,
	gpt = GroundPlateThickness,
	snapfreel = SnapFreeAreaDiameterLarge,
	snapfrees = SnapFreeAreaDiameterSmall,
	threshold = Threshold
) {
	femaleDisc(snaps, h, lh, ct, d, res, snapfreel, snapfrees, gpt, screw, threshold);
}

module discSet(
	snaps = Snaps,
	d = Diameter,
	h = SnapHeight,
	lh = LeadHeight,
	ct = CutTip,
	res = Resolution,
	screw = ScrewHoleDiameter,
	gpt = GroundPlateThickness,
	snapfreel = SnapFreeAreaDiameterLarge,
	snapfrees = SnapFreeAreaDiameterSmall,
	threshold = Threshold
) {
	translate([-d/2 - 1, 0, 0]) {
		maleDisc(snaps, h, lh, ct, d, res, snapfreel, snapfrees, gpt, screw, threshold);
	}
	translate([d/2 + 1, 0, 0]) {
		femaleDisc(snaps, h, lh, ct, d, res, snapfreel, snapfrees, gpt, screw, threshold);
	}
}

module generator(
	snaps = Snaps,
	d = Diameter,
	h = SnapHeight,
	lh = LeadHeight,
	ct = CutTip,
	screw = ScrewHoleDiameter,
	gpt = GroundPlateThickness,
	snapfreel = SnapFreeAreaDiameterLarge,
	snapfrees = SnapFreeAreaDiameterSmall,
	res = Resolution,
	part = Part,
	threshold = Threshold
) {
	$fn = res;
	if (part == "Male") {
		singleMaleDisc(snaps, d, h, lh, ct, res, screw, gpt, snapfreel, snapfrees, threshold);
	} else if (part == "Female") {
		singleFemaleDisc(snaps, d, h, lh, ct, res, screw, gpt, snapfreel, snapfrees, threshold);
	} else if (part == "Set") {
		discSet(snaps, d, h, lh, ct, res, screw, gpt, snapfreel, snapfrees, threshold);
	} else {
		// should not happen
		discSet(snaps, d, h, lh, ct, res, screw, gpt, snapfreel, snapfrees, threshold);
	}
}

generator(
	Snaps,
	Diameter,
	SnapHeight,
	LeadHeight,
	CutTip,
	ScrewHoleDiameter,
	GroundPlateThickness,
	SnapFreeAreaDiameterLarge,
	SnapFreeAreaDiameterSmall,
	Resolution,
	Part,
	Threshold
);

