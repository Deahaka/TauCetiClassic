///////////////////////////////////
//////////Nanite Devices///////////
///////////////////////////////////
/datum/design/nanite_remote
	name = "Nanite Remote"
	desc = "Allows for the construction of a nanite remote."
	id = "nanite_remote"
	build_type = PROTOLATHE
	materials = list(MAT_GLASS = 1500, MAT_GOLD = 1500, MAT_DIAMOND = 500)
	build_path = /obj/item/nanite_remote
	category = list("Tools")

/datum/design/nanite_scanner
	name = "Nanite Scanner"
	desc = "Allows for the construction of a nanite scanner."
	id = "nanite_scanner"
	build_type = PROTOLATHE
	materials = list(MAT_GLASS = 1500, MAT_GOLD = 1500, MAT_SILVER = 1500)
	build_path = /obj/item/device/nanite_scanner
	category = list("Tools")

/datum/design/nanite_disk
	name = "Nanite Program Disk"
	desc = "Stores nanite programs."
	id = "nanite_disk"
	build_type = PROTOLATHE
	materials = list(MAT_GOLD = 100, MAT_GLASS = 100)
	build_path = /obj/item/disk/nanite_program
	category = list("Electronics")

//circuit boards

/datum/design/nanite_chamber
	name = "Nanite Chamber"
	desc = "The circuit board for a Nanite Chamber."
	id = "nanite_chamber"
	build_type = IMPRINTER
	build_path = /obj/item/weapon/circuitboard/nanite_chamber
	materials = list(MAT_GOLD = 1500, MAT_GLASS = 3000, MAT_DIAMOND = 150, "sacid" = 20)
	category = list("Machine")

/datum/design/public_nanite_chamber
	name = "Public Nanite Chamber Board"
	desc = "The circuit board for a Public Nanite Chamber."
	id = "public_nanite_chamber"
	build_type = IMPRINTER
	build_path = /obj/item/weapon/circuitboard/public_nanite_chamber
	materials = list(MAT_GOLD = 1500, MAT_GLASS = 3000, MAT_DIAMOND = 150, "sacid" = 20)
	category = list("Machine")

/datum/design/nanite_programmer
	name = "Nanite Programmer Board"
	desc = "The circuit board for a Nanite Programmer."
	id = "nanite_programmer"
	build_type = IMPRINTER
	build_path = /obj/item/weapon/circuitboard/nanite_programmer
	materials = list(MAT_GOLD = 1500, MAT_GLASS = 3000, MAT_DIAMOND = 150, "sacid" = 20)
	category = list("Machine")

/datum/design/nanite_program_hub
	name = "Nanite Program Hub Board"
	desc = "The circuit board for a Nanite Program Hub."
	id = "nanite_program_hub"
	build_type = IMPRINTER
	build_path = /obj/item/weapon/circuitboard/nanite_program_hub
	materials = list(MAT_GOLD = 1500, MAT_GLASS = 3000, MAT_DIAMOND = 150, "sacid" = 20)
	category = list("Machine")

//Nanites designs

/datum/design/nanites
	name = "None"
	desc = "Warn a coder if you see this."
	id = "default_nanites"
	build_type = NANITE_COMPILER
	construction_time = 50
	category = list()
	//research_icon = 'icons/obj/device.dmi'
	//research_icon_state = "nanite_program"
	var/program_type = /datum/nanite_program

////////////////////UTILITY NANITES//////////////////////////////////////

/datum/design/nanites/metabolic_synthesis
	name = "Metabolic Synthesis"
	desc = "The nanites use the metabolic cycle of the host to speed up their replication rate, using their extra nutrition as fuel."
	id = "metabolic_nanites"
	program_type = /datum/nanite_program/metabolic_synthesis
	category = list("Utility Nanites")

/datum/design/nanites/viral
	name = "Viral Replica"
	desc = "The nanites constantly send encrypted signals attempting to forcefully copy their own programming into other nanite clusters."
	id = "viral_nanites"
	program_type = /datum/nanite_program/viral
	category = list("Utility Nanites")

/datum/design/nanites/monitoring
	name = "Monitoring"
	desc = "The nanites monitor the host's vitals and location, sending them to the suit sensor network."
	id = "monitoring_nanites"
	program_type = /datum/nanite_program/monitoring
	category = list("Utility Nanites")

/datum/design/nanites/self_scan
	name = "Host Scan"
	desc = "The nanites display a detailed readout of a body scan to the host."
	id = "selfscan_nanites"
	program_type = /datum/nanite_program/self_scan
	category = list("Utility Nanites")

/datum/design/nanites/stealth
	name = "Stealth"
	desc = "The nanites hide their activity and programming from superficial scans."
	id = "stealth_nanites"
	program_type = /datum/nanite_program/stealth
	category = list("Utility Nanites")

/datum/design/nanites/nanite_debugging
	name = "Nanite Debugging"
	desc = "Enables various high-cost diagnostics in the nanites, making them able to communicate their program list to portable scanners. \
	Doing so uses some power, slightly decreasing their replication speed."
	id = "debugging_nanites"
	program_type = /datum/nanite_program/nanite_debugging

/datum/design/nanites/access
	name = "Subdermal ID"
	desc = "The nanites store the host's ID access rights in a subdermal magnetic strip. Updates when triggered, copying the host's current access."
	id = "access_nanites"
	program_type = /datum/nanite_program/access
	category = list("Utility Nanites")

/datum/design/nanites/relay
	name = "Relay"
	desc = "The nanites receive and relay long-range nanite signals."
	id = "relay_nanites"
	program_type = /datum/nanite_program/relay
	category = list("Utility Nanites")

/datum/design/nanites/repeater
	name = "Signal Repeater"
	desc = "When triggered, sends another signal to the nanites, optionally with a delay."
	id = "repeater_nanites"
	program_type = /datum/nanite_program/sensor/repeat
	category = list("Utility Nanites")

/datum/design/nanites/relay_repeater
	name = "Relay Signal Repeater"
	desc = "When triggered, sends another signal to a relay channel, optionally with a delay."
	id = "relay_repeater_nanites"
	program_type = /datum/nanite_program/sensor/relay_repeat
	category = list("Utility Nanites")

/datum/design/nanites/emp
	name = "Electromagnetic Resonance"
	desc = "The nanites cause an elctromagnetic pulse around the host when triggered. Will corrupt other nanite programs!"
	id = "emp_nanites"
	program_type = /datum/nanite_program/emp
	category = list("Utility Nanites")

/datum/design/nanites/spreading
	name = "Infective Exo-Locomotion"
	desc = "The nanites gain the ability to survive for brief periods outside of the human body, as well as the ability to start new colonies without an integration process; \
			resulting in an extremely infective strain of nanites."
	id = "spreading_nanites"
	program_type = /datum/nanite_program/spreading
	category = list("Utility Nanites")

/datum/design/nanites/mitosis
	name = "Mitosis"
	desc = "The nanites gain the ability to self-replicate, using bluespace to power the process, instead of drawing from a template. This rapidly speeds up the replication rate,\
			but it causes occasional software errors due to faulty copies. Not compatible with cloud sync."
	id = "mitosis_nanites"
	program_type = /datum/nanite_program/mitosis
	category = list("Utility Nanites")

////////////////////MEDICAL NANITES//////////////////////////////////////
/datum/design/nanites/regenerative
	name = "Accelerated Regeneration"
	desc = "The nanites boost the host's natural regeneration, increasing their healing speed."
	id = "regenerative_nanites"
	program_type = /datum/nanite_program/regenerative
	category = list("Medical Nanites")

/datum/design/nanites/regenerative_advanced
	name = "Bio-Reconstruction"
	desc = "The nanites manually repair and replace organic cells, acting much faster than normal regeneration. \
			However, this program cannot detect the difference between harmed and unharmed, causing it to consume nanites even if it has no effect."
	id = "regenerative_plus_nanites"
	program_type = /datum/nanite_program/regenerative_advanced
	category = list("Medical Nanites")

/datum/design/nanites/temperature
	name = "Temperature Adjustment"
	desc = "The nanites adjust the host's internal temperature to an ideal level."
	id = "temperature_nanites"
	program_type = /datum/nanite_program/temperature
	category = list("Medical Nanites")

/datum/design/nanites/purging
	name = "Blood Purification"
	desc = "The nanites purge toxins and chemicals from the host's bloodstream."
	id = "purging_nanites"
	program_type = /datum/nanite_program/purging
	category = list("Medical Nanites")

/datum/design/nanites/purging_advanced
	name = "Selective Blood Purification"
	desc = "The nanites purge toxins and dangerous chemicals from the host's bloodstream, while ignoring beneficial chemicals. \
			The added processing power required to analyze the chemicals severely increases the nanite consumption rate."
	id = "purging_plus_nanites"
	program_type = /datum/nanite_program/purging_advanced
	category = list("Medical Nanites")

/datum/design/nanites/brain_heal
	name = "Neural Regeneration"
	desc = "The nanites fix neural connections in the host's brain, reversing brain damage and minor traumas."
	id = "brainheal_nanites"
	program_type = /datum/nanite_program/brain_heal
	category = list("Medical Nanites")

/datum/design/nanites/brain_heal_advanced
	name = "Neural Reimaging"
	desc = "The nanites are able to backup and restore the host's neural connections, potentially replacing entire chunks of missing or damaged brain matter."
	id = "brainheal_plus_nanites"
	program_type = /datum/nanite_program/brain_heal_advanced
	category = list("Medical Nanites")

/datum/design/nanites/blood_restoring
	name = "Blood Regeneration"
	desc = "The nanites stimulate and boost blood cell production in the host."
	id = "bloodheal_nanites"
	program_type = /datum/nanite_program/blood_restoring
	category = list("Medical Nanites")

/datum/design/nanites/repairing
	name = "Mechanical Repair"
	desc = "The nanites fix damage in the host's mechanical limbs."
	id = "repairing_nanites"
	program_type = /datum/nanite_program/repairing
	category = list("Medical Nanites")

/datum/design/nanites/defib
	name = "Defibrillation"
	desc = "The nanites, when triggered, send a defibrillating shock to the host's heart."
	id = "defib_nanites"
	program_type = /datum/nanite_program/defib
	category = list("Medical Nanites")


////////////////////AUGMENTATION NANITES//////////////////////////////////////

/datum/design/nanites/nervous
	name = "Nerve Support"
	desc = "The nanites act as a secondary nervous system, reducing the amount of time the host is stunned."
	id = "nervous_nanites"
	program_type = /datum/nanite_program/nervous
	category = list("Augmentation Nanites")

/datum/design/nanites/hardening
	name = "Dermal Hardening"
	desc = "The nanites form a mesh under the host's skin, protecting them from melee and bullet impacts."
	id = "hardening_nanites"
	program_type = /datum/nanite_program/hardening
	category = list("Augmentation Nanites")

/datum/design/nanites/refractive
	name = "Dermal Refractive Surface"
	desc = "The nanites form a membrane above the host's skin, reducing the effect of laser and energy impacts."
	id = "refractive_nanites"
	program_type = /datum/nanite_program/refractive
	category = list("Augmentation Nanites")

/datum/design/nanites/coagulating
	name = "Rapid Coagulation"
	desc = "The nanites induce rapid coagulation when the host is wounded, dramatically reducing bleeding rate."
	id = "coagulating_nanites"
	program_type = /datum/nanite_program/coagulating
	category = list("Augmentation Nanites")

/datum/design/nanites/conductive
	name = "Electric Conduction"
	desc = "The nanites act as a grounding rod for electric shocks, protecting the host. Shocks can still damage the nanites themselves."
	id = "conductive_nanites"
	program_type = /datum/nanite_program/conductive
	category = list("Augmentation Nanites")

/datum/design/nanites/adrenaline
	name = "Adrenaline Burst"
	desc = "The nanites cause a burst of adrenaline when triggered, waking the host from stuns and temporarily increasing their speed."
	id = "adrenaline_nanites"
	program_type = /datum/nanite_program/adrenaline
	category = list("Augmentation Nanites")

/datum/design/nanites/mindshield
	name = "Mental Barrier"
	desc = "The nanites form a protective membrane around the host's brain, shielding them from abnormal influences while they're active."
	id = "mindshield_nanites"
	program_type = /datum/nanite_program/mindshield
	category = list("Augmentation Nanites")

////////////////////DEFECTIVE NANITES//////////////////////////////////////

/datum/design/nanites/glitch
	name = "Glitch"
	desc = "A heavy software corruption that causes nanites to gradually break down."
	id = "glitch_nanites"
	program_type = /datum/nanite_program/glitch
	category = list("Defective Nanites")

/datum/design/nanites/necrotic
	name = "Necrosis"
	desc = "The nanites attack internal tissues indiscriminately, causing widespread damage."
	id = "necrotic_nanites"
	program_type = /datum/nanite_program/necrotic
	category = list("Defective Nanites")

/datum/design/nanites/toxic
	name = "Toxin Buildup"
	desc = "The nanites cause a slow but constant toxin buildup inside the host."
	id = "toxic_nanites"
	program_type = /datum/nanite_program/toxic
	category = list("Defective Nanites")

/datum/design/nanites/suffocating
	name = "Hypoxemia"
	desc = "The nanites prevent the host's blood from absorbing oxygen efficiently."
	id = "suffocating_nanites"
	program_type = /datum/nanite_program/suffocating
	category = list("Defective Nanites")

/datum/design/nanites/brain_misfire
	name = "Brain Misfire"
	desc = "The nanites interfere with neural pathways, causing minor psychological disturbances."
	id = "brainmisfire_nanites"
	program_type = /datum/nanite_program/brain_misfire
	category = list("Defective Nanites")

/datum/design/nanites/skin_decay
	name = "Dermalysis"
	desc = "The nanites attack skin cells, causing irritation, rashes, and minor damage."
	id = "skindecay_nanites"
	program_type = /datum/nanite_program/skin_decay
	category = list("Defective Nanites")

/datum/design/nanites/nerve_decay
	name = "Nerve Decay"
	desc = "The nanites attack the host's nerves, causing lack of coordination and short bursts of paralysis."
	id = "nervedecay_nanites"
	program_type = /datum/nanite_program/nerve_decay
	category = list("Defective Nanites")

/datum/design/nanites/brain_decay
	name = "Brain-Eating Nanites"
	desc = "Damages brain cells, gradually decreasing the host's cognitive functions."
	id = "braindecay_nanites"
	program_type = /datum/nanite_program/brain_decay
	category = list("Defective Nanites")

////////////////////WEAPONIZED NANITES/////////////////////////////////////

/datum/design/nanites/flesh_eating
	name = "Cellular Breakdown"
	desc = "The nanites destroy cellular structures in the host's body, causing brute damage."
	id = "flesheating_nanites"
	program_type = /datum/nanite_program/flesh_eating
	category = list("Weaponized Nanites")

/datum/design/nanites/poison
	name = "Poisoning"
	desc = "The nanites deliver poisonous chemicals to the host's internal organs, causing toxin damage and vomiting."
	id = "poison_nanites"
	program_type = /datum/nanite_program/poison
	category = list("Weaponized Nanites")

/datum/design/nanites/memory_leak
	name = "Memory Leak"
	desc = "This program invades the memory space used by other programs, causing frequent corruptions and errors."
	id = "memleak_nanites"
	program_type = /datum/nanite_program/memory_leak
	category = list("Weaponized Nanites")

/datum/design/nanites/aggressive_replication
	name = "Aggressive Replication"
	desc = "Nanites will consume organic matter to improve their replication rate, damaging the host."
	id = "aggressive_nanites"
	program_type = /datum/nanite_program/aggressive_replication
	category = list("Weaponized Nanites")

/datum/design/nanites/meltdown
	name = "Meltdown"
	desc = "Causes an internal meltdown inside the nanites, causing internal burns inside the host as well as rapidly destroying the nanite population.\
			Sets the nanites' safety threshold to 0 when activated."
	id = "meltdown_nanites"
	program_type = /datum/nanite_program/meltdown
	category = list("Weaponized Nanites")

/datum/design/nanites/cryo
	name = "Cryogenic Treatment"
	desc = "The nanites rapidly skin heat through the host's skin, lowering their temperature."
	id = "cryo_nanites"
	program_type = /datum/nanite_program/cryo
	category = list("Weaponized Nanites")

/datum/design/nanites/pyro
	name = "Sub-Dermal Combustion"
	desc = "The nanites cause buildup of flammable fluids under the host's skin, then ignites them."
	id = "pyro_nanites"
	program_type = /datum/nanite_program/pyro
	category = list("Weaponized Nanites")

/datum/design/nanites/heart_stop
	name = "Heart-Stopper"
	desc = "Stops the host's heart when triggered; restarts it if triggered again."
	id = "heartstop_nanites"
	program_type = /datum/nanite_program/heart_stop
	category = list("Weaponized Nanites")

/datum/design/nanites/explosive
	name = "Chain Detonation"
	desc = "Blows up all the nanites inside the host in a chain reaction when triggered."
	id = "explosive_nanites"
	program_type = /datum/nanite_program/explosive
	category = list("Weaponized Nanites")

////////////////////SUPPRESSION NANITES//////////////////////////////////////

/datum/design/nanites/shock
	name = "Electric Shock"
	desc = "The nanites shock the host when triggered. Destroys a large amount of nanites!"
	id = "shock_nanites"
	program_type = /datum/nanite_program/shocking
	category = list("Suppression Nanites")

/datum/design/nanites/stun
	name = "Neural Shock"
	desc = "The nanites pulse the host's nerves when triggered, inapacitating them for a short period."
	id = "stun_nanites"
	program_type = /datum/nanite_program/stun
	category = list("Suppression Nanites")

/datum/design/nanites/sleepy
	name = "Sleep Induction"
	desc = "The nanites cause rapid narcolepsy when triggered."
	id = "sleep_nanites"
	program_type = /datum/nanite_program/sleepy
	category = list("Suppression Nanites")

/datum/design/nanites/paralyzing
	name = "Paralysis"
	desc = "The nanites actively suppress nervous pulses, effectively paralyzing the host."
	id = "paralyzing_nanites"
	program_type = /datum/nanite_program/paralyzing
	category = list("Suppression Nanites")

/datum/design/nanites/fake_death
	name = "Death Simulation"
	desc = "The nanites induce a death-like coma into the host, able to fool most medical scans."
	id = "fakedeath_nanites"
	program_type = /datum/nanite_program/fake_death
	category = list("Suppression Nanites")

/datum/design/nanites/pacifying
	name = "Pacification"
	desc = "The nanites suppress the aggression center of the brain, preventing the host from causing direct harm to others."
	id = "pacifying_nanites"
	program_type = /datum/nanite_program/pacifying
	category = list("Suppression Nanites")

/datum/design/nanites/blinding
	name = "Blindness"
	desc = "The nanites suppress the host's ocular nerves, blinding them while they're active."
	id = "blinding_nanites"
	program_type = /datum/nanite_program/blinding
	category = list("Suppression Nanites")

/datum/design/nanites/mute
	name = "Mute"
	desc = "The nanites suppress the host's speech, making them mute while they're active."
	id = "mute_nanites"
	program_type = null //datum/nanite_program/mute
	category = list("Suppression Nanites")

/datum/design/nanites/voice
	name = "Skull Echo"
	desc = "The nanites echo a synthesized message inside the host's skull."
	id = "voice_nanites"
	program_type = /datum/nanite_program/comm/voice
	category = list("Suppression Nanites")

/datum/design/nanites/speech
	name = "Forced Speech"
	desc = "The nanites force the host to say a pre-programmed sentence when triggered."
	id = "speech_nanites"
	program_type = /datum/nanite_program/comm/speech
	category = list("Suppression Nanites")

/*
// See nanite_programs/suppression.dm
/datum/design/nanites/hallucination
	name = "Hallucination"
	desc = "The nanites make the host see and hear things that aren't real."
	id = "hallucination_nanites"
	program_type = /datum/nanite_program/comm/hallucination
	category = list("Suppression Nanites")
*/
////////////////////SENSOR NANITES//////////////////////////////////////

/datum/design/nanites/sensor_health
	name = "Health Sensor"
	desc = "The nanites receive a signal when the host's health is above/below a certain percentage."
	id = "sensor_health_nanites"
	program_type = /datum/nanite_program/sensor/health
	category = list("Sensor Nanites")

/datum/design/nanites/sensor_damage
	name = "Damage Sensor"
	desc = "The nanites receive a signal when a host's specific damage type is above/below a target value."
	id = "sensor_damage_nanites"
	program_type = /datum/nanite_program/sensor/damage
	category = list("Sensor Nanites")

/datum/design/nanites/sensor_crit
	name = "Critical Health Sensor"
	desc = "The nanites receive a signal when the host first reaches critical health."
	id = "sensor_crit_nanites"
	program_type = /datum/nanite_program/sensor/crit
	category = list("Sensor Nanites")

/datum/design/nanites/sensor_death
	name = "Death Sensor"
	desc = "The nanites receive a signal when they detect the host is dead."
	id = "sensor_death_nanites"
	program_type = /datum/nanite_program/sensor/death
	category = list("Sensor Nanites")

/datum/design/nanites/sensor_voice
	name = "Voice Sensor"
	desc = "Sends a signal when the nanites hear a determined word or sentence."
	id = "sensor_voice_nanites"
	program_type = /datum/nanite_program/sensor/voice
	category = list("Sensor Nanites")

/datum/design/nanites/sensor_nanite_volume
	name = "Nanite Volume Sensor"
	desc = "The nanites receive a signal when the nanite supply is above/below a certain percentage."
	id = "sensor_nanite_volume"
	program_type = /datum/nanite_program/sensor/nanite_volume
	category = list("Sensor Nanites")

// Circuits

/datum/design/board/nanite_chamber_control
	name = "Nanite Chamber Control"
	desc = "Allows for the construction of circuit boards used to build a new nanite chamber control console."
	id = "nanite_chamber_control"
	build_type = IMPRINTER
	build_path = /obj/item/weapon/circuitboard/nanite_chamber_control
	materials = list(MAT_GLASS = 1500, MAT_GOLD = 1500, MAT_DIAMOND = 500)
	category = list("Computer")

/datum/design/board/nanite_cloud_control
	name = "Nanite Cloud Control"
	desc = "Allows for the construction of circuit boards used to build a new nanite cloud control console."
	id = "nanite_cloud_control"
	build_type = IMPRINTER
	build_path = /obj/item/weapon/circuitboard/nanite_cloud_controller
	materials = list(MAT_GLASS = 1500, MAT_GOLD = 1500, MAT_DIAMOND = 500)
	category = list("Computer")

/datum/design/nanite_comm_remote
	name = "Nanite Communication Remote"
	desc = "Allows for the construction of a nanite communication remote."
	id = "nanite_comm_remote"
	build_type = PROTOLATHE
	build_path = /obj/item/nanite_remote/comm
	materials = list(MAT_GLASS = 500, MAT_METAL = 500)
	category = list("Electronics")

/*
// See nanite_programs/suppression.dm
/datum/design/nanites/good_mood
	name = "Happiness Enhancer"
	desc = "The nanites synthesize serotonin inside the host's brain, creating an artificial sense of happiness."
	id = "good_mood_nanites"
	program_type = /datum/nanite_program/good_mood
	category = list("Suppression Nanites")

/datum/design/nanites/bad_mood
	name = "Happiness Suppressor"
	desc = "The nanites suppress the production of serotonin inside the host's brain, creating an artificial state of depression."
	id = "bad_mood_nanites"
	program_type = /datum/nanite_program/bad_mood
	category = list("Suppression Nanites")
*/

/datum/design/nanites/nanite_sting
	name = "Nanite Sting"
	desc = "When triggered, projects a nearly invisible spike of nanites that attempts to infect a nearby non-host with a copy of the host's nanites cluster."
	id = "nanite_sting_nanites"
	program_type = /datum/nanite_program/nanite_sting
	category = list("Utility Nanites")

/datum/design/nanites/sensor_species
	name = "Species Sensor"
	desc = "When triggered, the nanites scan the host to determine their species and output a signal depending on the conditions set in the settings."
	id = "sensor_species_nanites"
	program_type = /datum/nanite_program/sensor/species
	category = list("Sensor Nanites")

/datum/design/nanites/dermal_button
	name = "Dermal Button"
	desc = "Displays a button on the host's skin, which can be used to send a signal to the nanites."
	id = "dermal_button_nanites"
	program_type = /datum/nanite_program/dermal_button
	category = list("Utility Nanites")

/datum/design/nanites/research
	name = "Distributed Computing"
	desc = "The nanites aid the research servers by performing a portion of its calculations, increasing research point generation."
	id = "research_nanites"
	program_type = /datum/nanite_program/research
	category = list("Utility Nanites")

/datum/design/nanites/researchplus
	name = "Neural Network"
	desc = "The nanites link the host's brains together forming a neural research network, that becomes more efficient with the amount of total hosts. Can be overloaded to increase research output."
	id = "researchplus_nanites"
	program_type = /datum/nanite_program/researchplus
	category = list("Utility Nanites")
