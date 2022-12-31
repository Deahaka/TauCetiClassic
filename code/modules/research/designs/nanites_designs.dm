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

//circuit boards

/datum/design/board/nanite_chamber
	name = "Nanite Chamber"
	desc = "The circuit board for a Nanite Chamber."
	id = "nanite_chamber"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/machine/nanite_chamber
	materials = list(MAT_METAL = 1500, MAT_GLASS = 3000, MAT_SILVER = 150, "sacid" = 20)
	category = list("Machine")

/datum/design/board/public_nanite_chamber
	name = "Public Nanite Chamber Board"
	desc = "The circuit board for a Public Nanite Chamber."
	id = "public_nanite_chamber"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/machine/public_nanite_chamber
	materials = list(MAT_METAL = 1500, MAT_GLASS = 3000, MAT_SILVER = 150, "sacid" = 20)
	category = list("Machine")

/datum/design/board/nanite_programmer
	name = "Nanite Programmer Board"
	desc = "The circuit board for a Nanite Programmer."
	id = "nanite_programmer"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/machine/nanite_programmer
	materials = list(MAT_METAL = 1500, MAT_GLASS = 3000, MAT_SILVER = 150, "sacid" = 20)
	category = list("Machine")

/datum/design/board/nanite_program_hub
	name = "Nanite Program Hub Board"
	desc = "The circuit board for a Nanite Program Hub."
	id = "nanite_program_hub"
	build_type = IMPRINTER
	build_path = /obj/item/circuitboard/machine/nanite_program_hub
	materials = list(MAT_METAL = 1500, MAT_GLASS = 3000, MAT_SILVER = 150, "sacid" = 20)
	category = list("Machine")
