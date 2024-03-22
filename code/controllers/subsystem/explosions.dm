var/global/list/cellauto_cells = list()
/// A wrapper for [/atom/proc/ex_act] for tg compability, we can need it in the future for signals and contents_explosion
#define EX_ACT(target, args...)\
	target.ex_act(##args);

#define SS_PRIORITY_CELLAUTO 600

SUBSYSTEM_DEF(cellauto)
	name  = "Cellular Automata"
	wait  = 0.05 SECONDS
	priority = SS_PRIORITY_CELLAUTO
	flags = SS_NO_INIT

	var/list/currentrun = list()

/datum/controller/subsystem/cellauto/stat_entry(msg)
	msg = "C: [global.cellauto_cells.len]"
	return ..()

/datum/controller/subsystem/cellauto/fire(resumed = FALSE)
	if(!resumed)
		currentrun = global.cellauto_cells.Copy()

	while(currentrun.len)
		var/datum/automata_cell/C = currentrun[currentrun.len]
		currentrun.len--

		if(!C || QDELETED(C))
			continue

		C.update_state()

		if(MC_TICK_CHECK)
			return

/turf
	var/list/datum/automata_cell/autocells

/turf/proc/get_cell(type)
	for(var/datum/automata_cell/C in autocells)
		if(istype(C, type))
			return C
	return null

/*
	Each datum represents a single cellular automataton

	Cell death is just the cell being deleted.
	So if you want a cell to die, just qdel it.
*/

// No neighbors
#define NEIGHBORS_NONE  0
// Cardinal neighborhood
#define NEIGHBORS_CARDINAL 1
// Ordinal neighborhood
#define NEIGHBORS_ORDINAL  2
// Note that NEIGHBORS_CARDINAL | NEIGHBORS_ORDINALS gives you all 8 surrounding neighbors

/datum/automata_cell
	// Which turf is the cell contained in
	var/turf/in_turf = null

	// What type of neighborhood do we use?
	// This affects what neighbors you'll get passed in update_state()
	var/neighbor_type = NEIGHBORS_CARDINAL

/datum/automata_cell/New(turf/T)
	..()

	if(!istype(T))
		qdel(src)
		return

	// Attempt to merge the two cells if they end up in the same turf
	var/datum/automata_cell/C = T.get_cell(type)
	if(C && merge(C))
		qdel(src)
		return

	in_turf = T
	LAZYADD(in_turf.autocells, src)

	global.cellauto_cells += src

	birth()

/datum/automata_cell/Destroy()
	. = ..()

	if(!QDELETED(in_turf))
		LAZYREMOVE(in_turf.autocells, src)
		in_turf = null

	global.cellauto_cells -= src

	death()

// Called when the cell is created
/datum/automata_cell/proc/birth()
	return

// Called when the cell is deleted/when it dies
/datum/automata_cell/proc/death()
	return

// Transfer this automata cell to another turf
/datum/automata_cell/proc/transfer_turf(turf/new_turf)
	if(QDELETED(new_turf))
		return

	if(!QDELETED(in_turf))
		LAZYREMOVE(in_turf.autocells, src)
		in_turf = null

	in_turf = new_turf
	LAZYADD(in_turf.autocells, src)

// Use this proc to merge this cell with another one if the other cell enters the same turf
// Return TRUE if this cell should survive the merge (the other one will die/be qdeleted)
// Return FALSE if this cell should die and be replaced by the other cell
/datum/automata_cell/proc/merge(datum/automata_cell/other_cell)
	return TRUE

// Returns a list of neighboring cells
// This is called by and results are passed to update_state by the cellauto subsystem
/datum/automata_cell/proc/get_neighbors()
	if(QDELETED(in_turf))
		return

	var/list/neighbors = list()

	// Get cardinal neighbors
	if(neighbor_type & NEIGHBORS_CARDINAL)
		for(var/dir in global.cardinal)
			var/turf/T = get_step(in_turf, dir)
			if(QDELETED(T))
				continue

			// Only add neighboring cells of the same type
			for(var/datum/automata_cell/C in T.autocells)
				if(istype(C, type))
					neighbors += C

	// Get ordinal/diagonal neighbors
	if(neighbor_type & NEIGHBORS_ORDINAL)
		for(var/dir in global.cornerdirs)
			var/turf/T = get_step(in_turf, dir)
			if(QDELETED(T))
				continue

			for(var/datum/automata_cell/C in T.autocells)
				if(istype(C, type))
					neighbors += C

	return neighbors

// Create a new cell in the given direction
// Obviously override this if you want custom propagation,
// but I figured this is pretty useful as a basic propagation function
/datum/automata_cell/proc/propagate(dir)
	if(!dir)
		return

	var/turf/T = get_step(in_turf, dir)
	if(QDELETED(T))
		return

	// Create the new cell
	var/datum/automata_cell/C = new type(T)
	return C

// Update the state of this cell
/datum/automata_cell/proc/update_state(list/turf/neighbors)
	// just fucking DIE
	qdel(src)

/*
	Cellular automaton explosions!

	Often in life, you can't have what you wish for. This is one massive, huge,
	gigantic, gaping exception. With this, you get EVERYTHING you wish for.

	This thing is AWESOME. It's made with super simple rules, and it still produces
	highly complex explosions because it's simply emergent behavior from the rules.
	If that didn't amaze you (it should), this also means the code is SUPER short,
	and because cellular automata is handled by a subsystem, this doesn't cause
	lagspikes at all.

	Enough nerd enthusiasm about this. Here's how it actually works:

		1. You start the explosion off with a given power

		2. The explosion begins to propagate outwards in all 8 directions

		3. Each time the explosion propagates, it loses power_falloff power

		4. Each time the explosion propagates, atoms in the tile the explosion is in
		may reduce the power of the explosion by their explosive resistance

	That's it. There are some special rules, though, namely:

		* If the explosion occurred in a wall, the wave is strengthened
		with power *= reflection_multiplier and reflected back in the
		direction it came from

		* If two explosions meet, they will either merge into an amplified
		or weakened explosion
*/

#define EXPLOSION_FALLOFF_SHAPE_LINEAR 0
#define EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL  1
#define EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL_HALF 2

/datum/automata_cell/explosion
	// Explosions only spread outwards and don't need to know their neighbors to propagate properly
	neighbor_type = NEIGHBORS_NONE

	// Power of the explosion at this cell
	var/power = 0
	// How much will the power drop off when the explosion propagates?
	var/power_falloff = 20
	// Falloff shape is used to determines whether or not the falloff will change during the explosion traveling.
	var/falloff_shape = EXPLOSION_FALLOFF_SHAPE_LINEAR
	// How much power does the explosion gain (or lose) by bouncing off walls?
	var/reflection_power_multiplier = 0.4

	//Diagonal cells have a small delay when branching off from a non-diagonal cell. This helps the explosion look circular
	var/delay = 0

	// Which direction is the explosion traveling?
	// Note that this will be null for the epicenter
	var/direction = null

	// Whether or not the explosion should merge with other explosions
	var/should_merge = TRUE

	// For stat tracking and logging purposes
	var/datum/cause_data/explosion_cause_data

	// Workaround to account for the fact that this is subsystemized
	// See on_turf_entered
	var/list/atom/exploded_atoms = list()

	var/obj/effect/particle_effect/shockwave/shockwave = null

// If we're on a fake z teleport, teleport over
/datum/automata_cell/explosion/birth()
	shockwave = new(in_turf)

	var/obj/effect/step_trigger/teleporter_vector/V = locate() in in_turf
	if(!V)
		return

	var/turf/new_turf = locate(in_turf.x + V.vector_x, in_turf.y + V.vector_y, in_turf.z)
	transfer_turf(new_turf)

/datum/automata_cell/explosion/death()
	if(shockwave)
		qdel(shockwave)

// Compare directions. If the other explosion is traveling in the same direction,
// the explosion is amplified. If not, it's weakened
/datum/automata_cell/explosion/merge(datum/automata_cell/explosion/E)
	// Non-merging explosions take priority
	if(!should_merge)
		return TRUE

	// The strongest of the two explosions should survive the merge
	// This prevents a weaker explosion merging with a strong one,
	// the strong one removing all the weaker one's power and just killing the explosion
	var/is_stronger = (power >= E.power)
	var/datum/automata_cell/explosion/survivor = is_stronger ? src : E
	var/datum/automata_cell/explosion/dying = is_stronger ? E : src

	// Two epicenters merging, or a new epicenter merging with a traveling wave
	if((!survivor.direction && !dying.direction) || (survivor.direction && !dying.direction))
		survivor.power += dying.power

	// A traveling wave hitting the epicenter weakens it
	if(!survivor.direction && dying.direction)
		survivor.power -= dying.power

	// Two traveling waves meeting each other
	// Note that we don't care about waves traveling perpendicularly to us
	// I.e. they do nothing

	// Two waves traveling the same direction amplifies the explosion
	if(survivor.direction == dying.direction)
		survivor.power += dying.power

	// Two waves travling towards each other weakens the explosion
	if(survivor.direction == global.reverse_dir[dying.direction])
		survivor.power -= dying.power

	return is_stronger

// Get a list of all directions the explosion should propagate to before dying
/datum/automata_cell/explosion/proc/get_propagation_dirs(reflected)
	var/list/propagation_dirs = list()

	// If the cell is the epicenter, propagate in all directions
	if(isnull(direction))
		return global.alldirs

	var/dir = reflected ? global.reverse_dir[direction] : direction

	if(dir in global.cardinal)
		propagation_dirs += list(dir, turn(dir, 45), turn(dir, -45))
	else
		propagation_dirs += dir

	return propagation_dirs

// If you need to set vars on the new cell other than the basic ones
/datum/automata_cell/explosion/proc/setup_new_cell(datum/automata_cell/explosion/E)
	if(E.shockwave)
		E.shockwave.alpha = E.power
	return

/datum/automata_cell/explosion/update_state(list/turf/neighbors)
	if(delay > 0)
		delay--
		return
	// The resistance here will affect the damage taken and the falloff in the propagated explosion
	var/resistance = max(0, in_turf.explosive_resistance)
	for(var/atom/A in in_turf)
		resistance += max(0, A.explosive_resistance)

	// Blow stuff up
	if(istype(in_turf, /turf/simulated/floor))
		var/turf/simulated/floor/F = in_turf
		F.break_tile()
	//INVOKE_ASYNC(in_turf, TYPE_PROC_REF(/atom, ex_act), EXPLODE_HEAVY, direction)
	for(var/atom/A in in_turf)
		if(A in exploded_atoms)
			continue
		if(A.gc_destroyed)
			continue
		if(istype(A, /obj/machinery/door/firedoor))
			continue
		EX_ACT(A, EXPLODE_HEAVY)
		//INVOKE_ASYNC(A, TYPE_PROC_REF(/atom, ex_act), EXPLODE_HEAVY, direction)
		exploded_atoms += A

	var/reflected = FALSE

	// Epicenter is inside a wall if direction is null.
	// Prevent it from slurping the entire explosion
	if(!isnull(direction))
		// Bounce off the wall in the opposite direction, don't keep phasing through it
		// Notice that since we do this after the ex_act()s,
		// explosions will not bounce if they destroy a wall!
		if(power < resistance)
			reflected = TRUE
			power *= reflection_power_multiplier
		else
			power -= resistance

	if(power <= 0)
		qdel(src)
		return

	// Propagate the explosion
	var/list/to_spread = get_propagation_dirs(reflected)
	for(var/dir in to_spread)
		// Diagonals are longer, that should be reflected in the power falloff
		var/dir_falloff = 1
		if(dir in global.cornerdirs)
			dir_falloff = 1.414

		if(isnull(direction))
			dir_falloff = 0

		var/new_power = power - (power_falloff * dir_falloff)

		// Explosion is too weak to continue
		if(new_power <= 0)
			continue

		var/new_falloff = power_falloff
		// Handle our falloff function.
		switch(falloff_shape)
			if(EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL)
				new_falloff += new_falloff * dir_falloff
			if(EXPLOSION_FALLOFF_SHAPE_EXPONENTIAL_HALF)
				new_falloff += (new_falloff*0.5) * dir_falloff

		var/datum/automata_cell/explosion/E = propagate(dir)
		if(E)
			E.power = new_power
			E.power_falloff = new_falloff
			E.falloff_shape = falloff_shape

			// Set the direction the explosion is traveling in
			E.direction = dir
			//Diagonal cells have a small delay when branching off the center. This helps the explosion look circular
			if(!direction && (dir in global.cornerdirs))
				E.delay = 1

			setup_new_cell(E)

	// We've done our duty, now die pls
	qdel(src)

/*
The issue is that between the cell being birthed and the cell processing,
someone could potentially move through the cell unharmed.

To prevent that, we track all atoms that enter the explosion cell's turf
and blow them up immediately once they do.

When the cell processes, we simply don't blow up atoms that were tracked
as having entered the turf.
*/

/datum/automata_cell/explosion/proc/on_turf_entered(atom/movable/A)
	// Once is enough
	if(A in exploded_atoms)
		return

	exploded_atoms += A

	// Note that we don't want to make it a directed ex_act because
	// it could toss them back and make them get hit by the explosion again
	if(A.gc_destroyed)
		return

	INVOKE_ASYNC(A, TYPE_PROC_REF(/atom, ex_act), EXPLODE_HEAVY, null)

// I'll admit most of the code from here on out is basically just copypasta from DOREC
#define EXPLOSION_MAX_POWER 5000
// Spawns a cellular automaton of an explosion
/proc/cell_explosion(turf/epicenter, power, falloff, falloff_shape = EXPLOSION_FALLOFF_SHAPE_LINEAR, direction)
	if(!istype(epicenter))
		epicenter = get_turf(epicenter)

	if(!epicenter)
		return

	falloff = max(falloff, power/100)

	//msg_admin_attack("Explosion with Power: [power], Falloff: [falloff], Shape: [falloff_shape] in [epicenter.loc.name] ([epicenter.x],[epicenter.y],[epicenter.z]).", epicenter.x, epicenter.y, epicenter.z)

	playsound(epicenter, pick(SOUNDIN_EXPLOSION_ECHO), 100, 1, round(power^2,1))

	if(power >= 300) //Make BIG BOOMS
		playsound(epicenter, "bigboom", 80, 1, max(round(power,1),7))
	else
		playsound(epicenter, "explosion", 90, 1, max(round(power,1),7))

	var/datum/automata_cell/explosion/E = new /datum/automata_cell/explosion(epicenter)
	if(power > EXPLOSION_MAX_POWER)
		log_debug("exploded with force of [power]. Overriding to capacity of [EXPLOSION_MAX_POWER].")
		power = EXPLOSION_MAX_POWER

	// something went wrong :(
	if(QDELETED(E))
		return

	E.power = power
	E.power_falloff = falloff
	E.falloff_shape = falloff_shape
	E.direction = direction

	if(power >= 100) // powerful explosions send out some special effects
		epicenter = get_turf(epicenter) // the ex_acts might have changed the epicenter
		//create_shrapnel(epicenter, rand(5,9), , ,/datum/ammo/bullet/shrapnel/light/effect/ver1, explosion_cause_data)
		//create_shrapnel(epicenter, rand(5,9), , ,/datum/ammo/bullet/shrapnel/light/effect/ver2, explosion_cause_data)

/obj/effect/particle_effect/shockwave
	name = "shockwave"
	icon = 'icons/effects/effects.dmi'
	icon_state = "smoke"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = FLY_LAYER

/* Simple object type, calls a proc when "stepped" on by something */

/obj/effect/step_trigger/teleporter_vector
	var/vector_x = 0 //Teleportation vector
	var/vector_y = 0
	var/vector_z = 0
	affect_ghosts = 1

/obj/effect/step_trigger/teleporter_vector/Trigger(atom/movable/A)
	if(A && A.loc)
		var/lx = A.x
		var/ly = A.y
		var/target = locate(A.x + vector_x, A.y + vector_y, A.z)
		//var/target_dir = get_dir(A, target)

		if(istype(A,/mob))
			var/mob/AM = A
			sleep(AM.movement_delay() + 0.4) //Make the transition as seamless as possible

		if(!Adjacent(A, locate(lx, ly, A.z))) //If the subject has moved too quickly, abort - this prevents double jumping
			return

		for(var/mob/M in target) //If the target location is obstructed, abort
			if(!M.CanPass(A, target))
				return

		A.x += vector_x
		A.y += vector_y
		A.z += vector_z





















SUBSYSTEM_DEF(explosions)
	name = "Explosions"
	init_order = SS_INIT_EXPLOSIONS
	priority = SS_PRIORITY_EXPLOSIONS
	wait = SS_WAIT_EXPLOSION
	flags = SS_TICKER | SS_NO_INIT | SS_SHOW_IN_MC_TAB
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/cost_lowturf = 0
	var/cost_medturf = 0
	var/cost_highturf = 0
	var/cost_flameturf = 0

	var/cost_low_mov_atom = 0
	var/cost_med_mov_atom = 0
	var/cost_high_mov_atom = 0

	var/list/lowturf = list()
	var/list/medturf = list()
	var/list/highturf = list()
	var/list/flameturf = list()

	var/list/low_mov_atom = list()
	var/list/med_mov_atom = list()
	var/list/high_mov_atom = list()

	var/currentpart = SSEXPLOSIONS_TURFS

	// cap, usual ratio ~1:2:3:3:3
	var/MAX_EX_DEVESTATION_RANGE = 3
	var/MAX_EX_HEAVY_RANGE = 7
	var/MAX_EX_LIGHT_RANGE = 14
	var/MAX_EX_FLASH_RANGE = 14
	var/MAX_EX_FLAME_RANGE = 14

/datum/controller/subsystem/explosions/stat_entry(msg)
	msg += "C:{"
	msg += "LT:[round(cost_lowturf, 1)]|"
	msg += "MT:[round(cost_medturf, 1)]|"
	msg += "HT:[round(cost_highturf, 1)]|"
	msg += "FT:[round(cost_flameturf, 1)]|"

	msg += "LO:[round(cost_low_mov_atom, 1)]|"
	msg += "MO:[round(cost_med_mov_atom, 1)]|"
	msg += "HO:[round(cost_high_mov_atom, 1)]|"

	msg += "} "

	msg += "AMT:{"
	msg += "LT:[lowturf.len]|"
	msg += "MT:[medturf.len]|"
	msg += "HT:[highturf.len]|"
	msg += "FT:[flameturf.len]||"

	msg += "LO:[low_mov_atom.len]|"
	msg += "MO:[med_mov_atom.len]|"
	msg += "HO:[high_mov_atom.len]|"

	msg += "} "
	return ..()

/datum/controller/subsystem/explosions/proc/is_exploding()
	return (lowturf.len || medturf.len || highturf.len || flameturf.len || low_mov_atom.len || med_mov_atom.len || high_mov_atom.len)

/**
 * Makes a given atom explode.
 *
 * Arguments:
 * - [epicenter][/turf]: The turf that's exploding.
 * - devastation_range: The range at which the effects of the explosion are at their strongest.
 * - heavy_impact_range: The range at which the effects of the explosion are relatively severe.
 * - light_impact_range: The range at which the effects of the explosion are relatively weak.
 * - flash_range: The range at which the explosion flashes people.
 * - adminlog: Whether to log the explosion/report it to the administration.
 * - ignorecap: Whether to ignore the relevant bombcap. Defaults to FALSE.
 * - flame_range: The range at which the explosion should produce hotspots.
 * - silent: Whether to generate/execute sound effects.
 * - smoke: Whether to generate a smoke cloud provided the explosion is powerful enough to warrant it.
 * - explosion_cause: [Optional] The atom that caused the explosion, when different to the origin. Used for logging.
 */
/proc/explosion(turf/epicenter, devastation_range = 0, heavy_impact_range = 0, light_impact_range = 0, flash_range = null, flame_range = null, adminlog = TRUE, ignorecap = FALSE, silent = FALSE, smoke = TRUE, atom/explosion_cause = null)
	. = SSexplosions.explode(arglist(args))

/**
 * Makes a given turf explode. Now on the explosions subsystem!
 *
 * Arguments:
 * - [epicenter][/turf]: The turf that's exploding.
 * - devastation_range: The range at which the effects of the explosion are at their strongest.
 * - heavy_impact_range: The range at which the effects of the explosion are relatively severe.
 * - light_impact_range: The range at which the effects of the explosion are relatively weak.
 * - flash_range: The range at which the explosion flashes people.
 * - adminlog: Whether to log the explosion/report it to the administration.
 * - ignorecap: Whether to ignore the relevant bombcap. Defaults to FALSE.
 * - flame_range: The range at which the explosion should produce hotspots.
 * - silent: Whether to generate/execute sound effects.
 * - smoke: Whether to generate a smoke cloud provided the explosion is powerful enough to warrant it.
 * - explosion_cause: [Optional] The atom that caused the explosion, when different to the origin. Used for logging.
 */
/datum/controller/subsystem/explosions/proc/explode(turf/epicenter, devastation_range = 0, heavy_impact_range = 0, light_impact_range = 0, flash_range = null, flame_range = null, adminlog = TRUE, ignorecap = FALSE, silent = FALSE, smoke = TRUE, atom/explosion_cause = null)

	SSStatistics.add_explosion_stat(epicenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, flame_range)

	propagate_blastwave(arglist(args))
	return

/**
 * Handles the effects of an explosion originating from a given point.
 *
 * Primarily handles popagating the balstwave of the explosion to the relevant turfs.
 * Also handles the fireball from the explosion.
 * Also handles the smoke cloud from the explosion.
 * Also handles sfx and screenshake.
 *
 * Arguments:
 * - [epicenter][/atom]: The location of the explosion rounded to the nearest turf.
 * - devastation_range: The range at which the effects of the explosion are at their strongest.
 * - heavy_impact_range: The range at which the effects of the explosion are relatively severe.
 * - light_impact_range: The range at which the effects of the explosion are relatively weak.
 * - flash_range: The range at which the explosion flashes people.
 * - adminlog: Whether to log the explosion/report it to the administration.
 * - ignorecap: Whether to ignore the relevant bombcap. Defaults to TRUE for some mysterious reason.
 * - flame_range: The range at which the explosion should produce hotspots.
 * - silent: Whether to generate/execute sound effects.
 * - smoke: Whether to generate a smoke cloud provided the explosion is powerful enough to warrant it.
 * - explosion_cause: The atom that caused the explosion. Used for logging.
 */
/datum/controller/subsystem/explosions/proc/propagate_blastwave(atom/epicenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, flame_range, adminlog, ignorecap, silent, smoke, explosion_cause)
	epicenter = get_turf(epicenter)
	if(!epicenter)
		return

	if(isnull(flame_range))
		flame_range = light_impact_range
	if(isnull(flash_range))
		flash_range = devastation_range

	var/orig_max_distance = max(devastation_range, heavy_impact_range, light_impact_range, flash_range, flame_range)

	if(!ignorecap)
		devastation_range = min(MAX_EX_DEVESTATION_RANGE , devastation_range)
		heavy_impact_range = min(MAX_EX_HEAVY_RANGE, heavy_impact_range)
		light_impact_range = min(MAX_EX_LIGHT_RANGE, light_impact_range)
		flash_range = min(MAX_EX_FLASH_RANGE, flash_range)
		flame_range = min(MAX_EX_FLAME_RANGE, flame_range)

	var/max_range = max(devastation_range, heavy_impact_range, light_impact_range, flame_range)

	if(adminlog)
		message_admins("Explosion with size (Devast: [devastation_range], Heavy: [heavy_impact_range], Light: [light_impact_range]) in area [epicenter.loc.name] ([COORD(epicenter)] - [ADMIN_JMP(epicenter)])")
		log_game("Explosion with size ([devastation_range], [heavy_impact_range], [light_impact_range]) in area [epicenter.loc.name]")

	SEND_SIGNAL(src, COMSIG_EXPLOSIONS_EXPLODE, epicenter, devastation_range, heavy_impact_range, light_impact_range)

	var/x0 = epicenter.x
	var/y0 = epicenter.y

	// Play sounds; we want sounds to be different depending on distance so we will manually do it ourselves.
	// Stereo users will also hear the direction of the explosion!

	// Calculate far explosion sound range. Only allow the sound effect for heavy/devastating explosions.
	// 3/7/14 will calculate to 80 + 35

	var/far_dist = 0
	far_dist += heavy_impact_range * 10
	far_dist += devastation_range * 20

	if(!silent)
		shake_the_room(epicenter, near_distance = orig_max_distance, far_distance = far_dist, quake_factor = devastation_range, echo_factor = heavy_impact_range)

	if(heavy_impact_range > 1)
		var/datum/effect/system/explosion/explosion_effect = new
		var/practicles_num = max(devastation_range * 2, heavy_impact_range)
		explosion_effect.set_up(epicenter, practicles_num)
		INVOKE_ASYNC(explosion_effect, TYPE_PROC_REF(/datum/effect/system/explosion, start))

		if(smoke)
			var/datum/effect/effect/system/smoke_spread/bad/smoke_effect = new
			var/smoke_num = max(devastation_range, round(sqrt(heavy_impact_range)))
			smoke_effect.set_up(smoke_num, 0, epicenter)
			addtimer(CALLBACK(smoke_effect, TYPE_PROC_REF(/datum/effect/effect/system/smoke_spread, start)), 5)

	if(flash_range)
		for(var/mob/living/Mob_to_flash in viewers(flash_range, epicenter))
			Mob_to_flash.flash_eyes()

	var/list/affected_turfs = prepare_explosion_turfs(max_range, epicenter)

	// this list is setup in the form position -> block for that position
	// we assert that turfs will be processed closed to farthest, so we can build this as we go along
	// This is gonna be an array, index'd by turfs
	var/list/cached_exp_block = list()

	//lists are guaranteed to contain at least 1 turf at this point
	//we presuppose that we'll be iterating away from the epicenter
	for(var/turf/explode as anything in affected_turfs)
		var/our_x = explode.x
		var/our_y = explode.y
		var/dist = HYPOTENUSE(our_x, our_y, x0, y0)

		// Using this pattern, block will flow out from blocking turfs, essentially caching the recursion
		// This is safe because if get_step_towards is ever anything but caridnally off, it'll do a diagonal move
		// So we always sample from a "loop" closer
		// It's kind of behaviorly unimpressive that that's a problem for the future
		if(config.reactionary_explosions)
			// resistance actually just "pushing" turf from explosion range
			var/resistance = explode.explosive_resistance // should we use armor instead?
			for(var/atom/A in explode) // tg has a way to optimize it, but it's soo tg so i don't want to port it
				if(A.explosive_resistance)
					resistance += A.explosive_resistance

			if(explode == epicenter)
				cached_exp_block[explode] = resistance / 4 // inner explosion - resistance less effective
			else
				var/our_block = cached_exp_block[get_step_towards(explode, epicenter)]
				dist += our_block + resistance / 2 // use half of own resistance, full resistance for turfs behind
				cached_exp_block[explode] = our_block + resistance

		var/severity = EXPLODE_NONE
		if(dist < devastation_range)
			severity = EXPLODE_DEVASTATE
		else if(dist < heavy_impact_range)
			severity = EXPLODE_HEAVY
		else if(dist < light_impact_range)
			severity = EXPLODE_LIGHT

		switch(severity)
			if(EXPLODE_DEVASTATE)
				SSexplosions.highturf += explode
			if(EXPLODE_HEAVY)
				SSexplosions.medturf += explode
			if(EXPLODE_LIGHT)
				SSexplosions.lowturf += explode

		if(prob(40) && dist < flame_range && !isspaceturf(explode) && !explode.density)
			flameturf += explode

// Explosion SFX defines...
/// The probability that a quaking explosion will make the station creak per unit. Maths!
#define QUAKE_CREAK_PROB 30
/// The probability that an echoing explosion will make the station creak per unit.
#define ECHO_CREAK_PROB 5
/// Time taken for the hull to begin to creak after an explosion, if applicable.
#define CREAK_DELAY (5 SECONDS)
/// Lower limit for far explosion SFX volume.
#define FAR_LOWER 40
/// Upper limit for far explosion SFX volume.
#define FAR_UPPER 60
/// The probability that a distant explosion SFX will be a far explosion sound rather than an echo. (0-100)
#define FAR_SOUND_PROB 75
/// The upper limit on screenshake amplitude for nearby explosions.
#define NEAR_SHAKE_CAP 5
/// The upper limit on screenshake amplifude for distant explosions.
#define FAR_SHAKE_CAP 1.5
/// The duration of the screenshake for nearby explosions.
#define NEAR_SHAKE_DURATION (1.5 SECONDS)
/// The duration of the screenshake for distant explosions.
#define FAR_SHAKE_DURATION (1 SECONDS)
/// The lower limit for the randomly selected hull creaking volume.
#define CREAK_LOWER_VOL 55
/// The upper limit for the randomly selected hull creaking volume.
#define CREAK_UPPER_VOL 70

/**
 * Handles the sfx and screenshake caused by an explosion.
 *
 * Arguments:
 * - [epicenter][/turf]: The location of the explosion.
 * - near_distance: How close to the explosion you need to be to get the full effect of the explosion.
 * - far_distance: How close to the explosion you need to be to hear more than echos.
 * - quake_factor: Main scaling factor for screenshake.
 * - echo_factor: Whether to make the explosion echo off of very distant parts of the station.
 * - creaking: Whether to make the station creak. Autoset if null.
 * - [near_sound][/sound]: The sound that plays if you are close to the explosion.
 * - [far_sound][/sound]: The sound that plays if you are far from the explosion.
 * - [echo_sound][/sound]: The sound that plays as echos for the explosion.
 * - [creaking_sound][/sound]: The sound that plays when the station creaks during the explosion.
 * - [hull_creaking_sound][/sound]: The sound that plays when the station creaks after the explosion.
 */
/datum/controller/subsystem/explosions/proc/shake_the_room(turf/epicenter, near_distance, far_distance, quake_factor, echo_factor, creaking, near_sound = pick(SOUNDIN_EXPLOSION), far_sound = pick(SOUNDIN_EXPLOSION_FAR), echo_sound = pick(SOUNDIN_EXPLOSION_ECHO), creaking_sound = pick(SOUNDIN_EXPLOSION_CREAK), hull_creaking_sound = pick(SOUNDIN_CREAK))
	var/blast_z = epicenter.z
	if(isnull(creaking)) // Autoset creaking.
		var/on_station = SSmapping.level_trait(epicenter.z, ZTRAIT_STATION)
		if(on_station && prob((quake_factor * QUAKE_CREAK_PROB) + (echo_factor * ECHO_CREAK_PROB))) // Huge explosions are near guaranteed to make the station creak and whine, smaller ones might.
			creaking = TRUE // prob over 100 always returns true
		else
			creaking = FALSE

	for(var/mob/listener as anything in global.player_list)
		var/turf/listener_turf = get_turf(listener)
		if(!listener_turf || listener_turf.z != blast_z)
			continue

		var/distance = get_dist(epicenter, listener_turf)
		if(epicenter == listener_turf)
			distance = 0
		var/base_shake_amount = sqrt(near_distance / (distance + 1))
		if(distance <= round(near_distance + world.view - 2, 1)) // If you are close enough to see the effects of the explosion first-hand (ignoring walls)
			listener.playsound_local(epicenter, near_sound, VOL_EFFECTS_MASTER, vol = 100, vary = TRUE)
			if(base_shake_amount > 0)
				shake_camera(listener, NEAR_SHAKE_DURATION, clamp(base_shake_amount, 0, NEAR_SHAKE_CAP))

		else if(distance < far_distance) // You can hear a far explosion if you are outside the blast radius. Small explosions shouldn't be heard throughout the station.
			var/far_volume = clamp(far_distance / 2, FAR_LOWER, FAR_UPPER)
			if(creaking)
				listener.playsound_local(epicenter, creaking_sound, VOL_EFFECTS_MASTER, vol = far_volume, vary = TRUE, voluminosity = FALSE, distance_multiplier = 0)
			else if(prob(FAR_SOUND_PROB)) // Sound variety during meteor storm/tesloose/other bad event
				listener.playsound_local(epicenter, far_sound, VOL_EFFECTS_MASTER, vol = far_volume, vary = TRUE, voluminosity = FALSE, distance_multiplier = 0)
			else
				listener.playsound_local(epicenter, echo_sound, VOL_EFFECTS_MASTER, vol = far_volume, vary = TRUE, voluminosity = FALSE, distance_multiplier = 0)

			if(base_shake_amount || quake_factor)
				base_shake_amount = max(base_shake_amount, quake_factor * 3, 0) // Devastating explosions rock the station and ground
				shake_camera(listener, FAR_SHAKE_DURATION, min(base_shake_amount, FAR_SHAKE_CAP))

		else if(!isspaceturf(listener_turf) && echo_factor) // Big enough explosions echo through the hull.
			var/echo_volume
			if(quake_factor)
				echo_volume = 60
				shake_camera(listener, FAR_SHAKE_DURATION, clamp(quake_factor / 4, 0, FAR_SHAKE_CAP))
			else
				echo_volume = 40
			listener.playsound_local(epicenter, echo_sound, VOL_EFFECTS_MASTER, vol = echo_volume, vary = TRUE, distance_multiplier = 0)

		if(creaking) // 5 seconds after the bang (~duration of SOUNDIN_EXPLOSION_CREAK), the station begins to creak
			listener.playsound_local_timed(CREAK_DELAY, epicenter, hull_creaking_sound, volume_channel = VOL_EFFECTS_MASTER, vol = rand(CREAK_LOWER_VOL, CREAK_UPPER_VOL), vary = TRUE, voluminosity = FALSE, distance_multiplier = 0)

#undef CREAK_DELAY
#undef QUAKE_CREAK_PROB
#undef ECHO_CREAK_PROB
#undef FAR_UPPER
#undef FAR_LOWER
#undef FAR_SOUND_PROB
#undef NEAR_SHAKE_CAP
#undef FAR_SHAKE_CAP
#undef NEAR_SHAKE_DURATION
#undef FAR_SHAKE_DURATION
#undef CREAK_LOWER_VOL
#undef CREAK_UPPER_VOL

/// Returns a list of turfs in X range from the epicenter
/// Returns in a unique order, spiraling outwards
/// This is done to ensure our progressive cache of blast resistance is always valid
/// This is quite fast
/proc/prepare_explosion_turfs(range, turf/epicenter)
	var/list/outlist = list()
	// Add in the center
	outlist += epicenter

	var/our_x = epicenter.x
	var/our_y = epicenter.y
	var/our_z = epicenter.z

	var/max_x = world.maxx
	var/max_y = world.maxy
	for(var/i in 1 to range)
		var/lowest_x = our_x - i
		var/lowest_y = our_y - i
		var/highest_x = our_x + i
		var/highest_y = our_y + i
		// top left to one before top right
		if(highest_y <= max_y)
			outlist += block(
				locate(max(lowest_x, 1), highest_y, our_z),
				locate(min(highest_x - 1, max_x), highest_y, our_z))
		// top right to one before bottom right
		if(highest_x <= max_x)
			outlist += block(
				locate(highest_x, min(highest_y, max_y), our_z),
				locate(highest_x, max(lowest_y + 1, 1), our_z))
		// bottom right to one before bottom left
		if(lowest_y >= 1)
			outlist += block(
				locate(min(highest_x, max_x), lowest_y, our_z),
				locate(max(lowest_x + 1, 1), lowest_y, our_z))
		// bottom left to one before top left
		if(lowest_x >= 1)
			outlist += block(
				locate(lowest_x, max(lowest_y, 1), our_z),
				locate(lowest_x, min(highest_y - 1, max_y), our_z))

	return outlist

/datum/controller/subsystem/explosions/fire(resumed = 0)
	if(!is_exploding())
		return
	var/timer
	Master.current_ticklimit = TICK_LIMIT_RUNNING //force using the entire tick if we need it.

	if(currentpart == SSEXPLOSIONS_TURFS)
		currentpart = SSEXPLOSIONS_MOVABLES

		timer = TICK_USAGE_REAL
		var/list/low_turf = lowturf
		lowturf = list()
		for(var/turf/turf_thing as anything in low_turf)
			EX_ACT(turf_thing, EXPLODE_LIGHT)
		cost_lowturf = MC_AVERAGE(cost_lowturf, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))

		timer = TICK_USAGE_REAL
		var/list/med_turf = medturf
		medturf = list()
		for(var/turf/turf_thing as anything in med_turf)
			EX_ACT(turf_thing, EXPLODE_HEAVY)
		cost_medturf = MC_AVERAGE(cost_medturf, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))

		timer = TICK_USAGE_REAL
		var/list/high_turf = highturf
		highturf = list()
		for(var/turf/turf_thing as anything in high_turf)
			EX_ACT(turf_thing, EXPLODE_DEVASTATE)
		cost_highturf = MC_AVERAGE(cost_highturf, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))

		timer = TICK_USAGE_REAL
		var/list/flame_turf = flameturf
		flameturf = list()
		for(var/turf/turf_thing as anything in flame_turf)
			//Mostly for ambience!
			new /obj/effect/firewave(turf_thing)
		cost_flameturf = MC_AVERAGE(cost_flameturf, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))

		if(low_turf.len || med_turf.len || high_turf.len)
			Master.laggy_byond_map_update_incoming()

	if(currentpart == SSEXPLOSIONS_MOVABLES)

		timer = TICK_USAGE_REAL
		var/list/local_high_mov_atom = high_mov_atom
		high_mov_atom = list()
		//todo: maybe check for atom.simulated and ABSTRACT flag, currently it calls ex_act for lighting
		for(var/atom/movable/movable_thing as anything in local_high_mov_atom)
			if(QDELETED(movable_thing))
				continue
			EX_ACT(movable_thing, EXPLODE_DEVASTATE)
		cost_high_mov_atom = MC_AVERAGE(cost_high_mov_atom, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))

		timer = TICK_USAGE_REAL
		var/list/local_med_mov_atom = med_mov_atom
		med_mov_atom = list()
		for(var/atom/movable/movable_thing as anything in local_med_mov_atom)
			if(QDELETED(movable_thing))
				continue
			EX_ACT(movable_thing, EXPLODE_HEAVY)
		cost_med_mov_atom = MC_AVERAGE(cost_med_mov_atom, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))

		timer = TICK_USAGE_REAL
		var/list/local_low_mov_atom = low_mov_atom
		low_mov_atom = list()
		for(var/atom/movable/movable_thing as anything in local_low_mov_atom)
			if(QDELETED(movable_thing))
				continue
			EX_ACT(movable_thing, EXPLODE_LIGHT)
		cost_low_mov_atom = MC_AVERAGE(cost_low_mov_atom, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))

	currentpart = SSEXPLOSIONS_TURFS
