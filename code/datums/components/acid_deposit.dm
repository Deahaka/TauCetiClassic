/datum/component/acid_deposit
	var/turf/center_turf
	var/endtime = -1
	var/strength_to_mob = 0
	var/strength_to_silicon = 0
	//var/list/acid_effects = list()

/datum/component/acid_deposit/Initialize(time_to_quenching = 30 MINUTES, _strength_to_mob = 50, _strength_to_silicon = 20)
	//if(isturf(parent))
	center_turf = parent
	//else
	//	center_turf = get_turf(parent)
	if(time_to_quenching > 0)
		endtime = world.time + time_to_quenching
		addtimer(CALLBACK(src, .proc/quenching_time), time_to_quenching, TIMER_STOPPABLE)
	strength_to_mob = _strength_to_mob
	strength_to_silicon = _strength_to_silicon
	center_turf.color = "#7CFC00"
	RegisterSignal(parent, list(COMSIG_MOVABLE_CROSSED, COMSIG_ATOM_ENTERED), .proc/create_wound)

/datum/component/acid_deposit/proc/create_area()
	//for(var/turf/T in range(5, center_turf))
	//	var/obj/structure/alien/strong_acid/A = new(T.loc, src)
	//	acid_effects += A
	//	RegisterSignal(T, list(COMSIG_MOVABLE_CROSSED, COMSIG_ATOM_ENTERED), .proc/create_wound)

/datum/component/acid_deposit/proc/create_wound(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(isrobot(AM))
		var/mob/living/silicon/robot/R = AM
		//damage to legs
		var/datum/robot_component/actuator/A = R.get_component("actuator")
		if(!A)
			return
		A.take_damage(electronics = strength_to_silicon)
	else if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		var/datum/species/S = all_species[H.get_species()]
		if(S?.flags[IS_PLANT])
			return
		else if(S?.flags[IS_SYNTHETIC])
			H.adjustFireLoss(strength_to_mob)
		else
			H.adjustToxLoss(strength_to_mob)
	else if(ismob(AM))
		var/mob/living/M = AM
		M.adjustToxLoss(strength_to_mob)
	else
		return

/datum/component/acid_deposit/proc/quenching_time()
	qdel(src)

/datum/component/acid_deposit/Destroy()
	center_turf.color = initial(center_turf.color)
	//for(var/i in acid_effects)
	//	qdel(i)
	//center_turf = null

	//	UnregisterSignal(parent, list(COMSIG_LOGIN, COMSIG_MOB_DIED, COMSIG_LOGOUT))
	return ..()

/*obj/structure/alien/strong_acid
	icon_state = "weednode"
	color = "#98BF64"
	//hot access
	var/datum/component/acid_deposit/source_comp

/obj/structure/alien/strong_acid/atom_init(datum/component/C)
	. = ..()
	source_comp = C
*/
