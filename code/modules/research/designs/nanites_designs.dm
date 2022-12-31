///////////////////////////////////
//////////Nanite Devices///////////
///////////////////////////////////
/datum/design/nanite_remote
	name = "Nanite Remote"
	desc = "Allows for the construction of a nanite remote."
	id = "nanite_remote"
	build_type = PROTOLATHE
	materials = list(MAT_GLASS = 1500, MAT_METAL = 1500, MAT_DIAMOND = 500)
	build_path = /obj/item/nanite_remote
	category = list("Tools")

/datum/design/nanite_scanner
	name = "Nanite Scanner"
	desc = "Allows for the construction of a nanite scanner."
	id = "nanite_scanner"
	build_type = PROTOLATHE
	materials = list(MAT_GLASS = 1500, MAT_METAL = 1500, MAT_SILVER = 1500)
	build_path = /obj/item/device/nanite_scanner
	category = list("Tools")

/datum/design/nanite_disk
	name = "Nanite Program Disk"
	desc = "Stores nanite programs."
	id = "nanite_disk"
	build_type = PROTOLATHE
	materials = list(MAT_METAL = 100, MAT_GLASS = 100)
	build_path = /obj/item/disk/nanite_program
	category = list("Electronics")

