#define METEOR_COOLDOWN 30 MINUTES
#define SHIELD_COOLDOWN 30 SECONDS

#define DIRECTION_NORTH "North"
#define DIRECTION_SOUTH "South"
#define DIRECTION_EAST "East"
#define DIRECTION_WEST "West"
#define DIRECTION_ALL "360"
#define DIRECTION_NONE "None"

var/global/meteor_danger_active = TRUE
var/global/list/radars = list()
var/global/list/shielders = list()

ADD_TO_GLOBAL_LIST(/obj/machinery/computer/radar, radars)
/obj/machinery/computer/radar
	var/last_saved_time = 30

/obj/machinery/computer/radar/atom_init()
	. = ..()
	START_PROCESSING(SSmachines, src)

/obj/machinery/computer/radar/examine(mob/user)
	to_chat(user, "<span class='warning'>[SSmeteorize.setup_message_for_crew()]! Направление: [SSmeteorize.meteor_direction].</span>")

/obj/machinery/computer/radar/proc/announce_for_viewers()
	audible_message("<span class='warning'>[SSmeteorize.setup_message_for_crew()]!</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "New message!")

/obj/machinery/computer/radar/process()
	var/awaiting_time = SSmeteorize.get_minutes()
	if(awaiting_time < 1)
		if(last_saved_time < awaiting_time)
			return
		announce_for_viewers()
	else if(awaiting_time < 5)
		if(last_saved_time < awaiting_time)
			return
		announce_for_viewers()
	else if(awaiting_time < 10)
		if(last_saved_time < awaiting_time)
			return
		announce_for_viewers()
	last_saved_time = awaiting_time

/obj/machinery/computer/radar/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	examine(user)

SUBSYSTEM_DEF(meteorize)
	name = "Meteorize"
	wait = METEOR_COOLDOWN
	init_order = SS_INIT_DEFAULT
	flags = SS_NO_INIT

	var/endtime = 0
	var/list/protected_areas = list()
	var/protected_direction = DIRECTION_NONE
	var/meteor_direction = DIRECTION_NONE
	var/roundstart = TRUE

/datum/controller/subsystem/meteorize/proc/set_endtime()
	endtime = world.timeofday + wait

/datum/controller/subsystem/meteorize/proc/add_more_protected_areas(areatype)
	protected_areas += areatype

/datum/controller/subsystem/meteorize/proc/set_protected_area(areatype)
	clear_protected_areas()
	add_more_protected_areas(areatype)

/datum/controller/subsystem/meteorize/proc/clear_protected_areas()
	protected_areas.Cut()

/datum/controller/subsystem/meteorize/proc/setup_meteor_direction()
	return pick(DIRECTION_NORTH, DIRECTION_SOUTH, DIRECTION_EAST, DIRECTION_WEST)

/datum/controller/subsystem/meteorize/proc/get_minutes()
	return round((endtime - world.timeofday) / 600)

//First fire in roundstart
/datum/controller/subsystem/meteorize/fire()
	set_endtime()
	if(!global.meteor_danger_active)
		return
	for(var/obj/machinery/computer/radar/R as anything in global.radars)
		R.last_saved_time = wait / 10
	if(roundstart)
		roundstart = FALSE
		meteor_direction = setup_meteor_direction()
		return
	if(meteor_direction != protected_direction)
		if(protected_direction != DIRECTION_ALL)
			spawn_meteors(10, meteors_catastrophic)
	meteor_direction = setup_meteor_direction()

/datum/controller/subsystem/meteorize/proc/setup_message_for_crew()
	var/data = "Возможное столкновение с метеором через: "
	var/time = get_minutes()
	data += "[time] "
	switch(time)
		if(1)
			data += "минуту"
		if(2 to 4)
			data += "минуты"
		else
			data += "минут"
	return data

/atom/proc/station_shield_effect()
	return FALSE

/mob/living/carbon/human/station_shield_effect()
	SSincinerating.incinerating |= src
	return TRUE

/mob/living/carbon/human/Destroy()
	SSincinerating.incinerating -= src
	return ..()

/mob/living/proc/incinerating_process()
	adjustFireLoss(20)
	adjust_fire_stacks(3)
	IgniteMob()

SUBSYSTEM_DEF(incinerating)
	name = "Incinerating"

	priority = SS_PRIORITY_OBJECTS

	flags = SS_POST_FIRE_TIMING | SS_NO_INIT

	var/list/affected_areas = list()
	var/list/incinerating = list()
	var/list/currentrun = list()

/datum/controller/subsystem/incinerating/stat_entry()
	..("P:[incinerating.len]")

/datum/controller/subsystem/incinerating/fire(resumed = 0)
	if(!resumed)
		currentrun = incinerating.Copy()
	var/list/run_list = currentrun

	while(run_list.len)

		var/mob/living/thing = run_list[run_list.len]
		run_list.len--

		if(!QDELETED(thing))
			if(get_area(thing) in affected_areas)
				thing.incinerating_process()
		else
			incinerating -= thing

		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/incinerating/Recover()
	if(istype(SSincinerating.incinerating))
		incinerating = SSincinerating.incinerating

ADD_TO_GLOBAL_LIST(/obj/machinery/computer/shield_activator, shielders)
/obj/machinery/computer/shield_activator
	var/selected_targetzone = DIRECTION_NONE
	//Write your zones, selecting multiple would require a bit of rewriting
	var/list/safespaces = list(
		DIRECTION_NORTH = /area/station/maintenance/starboardsolar,
		DIRECTION_SOUTH = /area/station/maintenance/auxsolarport,
		DIRECTION_EAST = /area/station/maintenance/auxsolarstarboard,
		DIRECTION_WEST = /area/station/maintenance/portsolar
	)
	COOLDOWN_DECLARE(activate_shield)

/obj/machinery/computer/shield_activator/proc/setup_browsewindow(dat)
	var/datum/browser/popup = new(usr, "computer", "Shield Activate", 400, 500)
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/shield_activator/proc/get_userwindow_content()
	var/dat = ""
	dat += "<center>Selected Direction: [selected_targetzone].</center><BR>"
	dat += "<center><A href='?src=\ref[src];select_target=1'>Select Targetzone</A></center><BR>"
	if(COOLDOWN_FINISHED(src, activate_shield))
		dat += "<center><A href='?src=\ref[src];activate=1'>Activate</A></center><BR>"
	else
		dat += "Recharging: [COOLDOWN_TIMELEFT(src, activate_shield) / 10] sec."
	return dat

/obj/machinery/computer/shield_activator/ui_interact(mob/user)
	setup_browsewindow(get_userwindow_content())

/obj/machinery/computer/shield_activator/proc/stop_burning()
	SSincinerating.incinerating.Cut()
	SSmeteorize.clear_protected_areas()
	SSmeteorize.protected_direction = DIRECTION_NONE

/obj/machinery/computer/shield_activator/proc/burn_them_out()
	if(selected_targetzone == DIRECTION_ALL)
		SSmeteorize.clear_protected_areas()
		for(var/i in safespaces)
			var/areatypefromlist = safespaces[i]
			SSmeteorize.add_more_protected_areas(areatypefromlist)
	else if(selected_targetzone == DIRECTION_NONE)
		SSmeteorize.clear_protected_areas()
	else
		SSmeteorize.set_protected_area(safespaces[selected_targetzone])
	SSincinerating.affected_areas.Cut()
	for(var/area in SSmeteorize.protected_areas)
		var/area/target_area = get_area_by_type(area)
		SSincinerating.affected_areas += target_area
		var/list/contents = target_area.GetAreaAllContents()
		var/list/area_atoms = shuffle(contents)
		for(var/atom/A as anything in area_atoms)
			A.station_shield_effect()

/obj/machinery/computer/shield_activator/Topic(href, href_list)
	..()
	if(href_list["select_target"])
		var/choice = input(usr, "Select Target", "Changing") as null|anything in list(DIRECTION_NORTH, DIRECTION_SOUTH, DIRECTION_EAST, DIRECTION_WEST, DIRECTION_ALL)
		if(choice)
			selected_targetzone = choice
	if(href_list["activate"])
		if(COOLDOWN_FINISHED(src, activate_shield))
			SSmeteorize.protected_direction = selected_targetzone
			burn_them_out()
			for(var/obj/machinery/computer/shield_activator/S as anything in shielders)
				COOLDOWN_START(S, activate_shield, METEOR_COOLDOWN)
			addtimer(CALLBACK(src, PROC_REF(stop_burning)), SHIELD_COOLDOWN)
	setup_browsewindow(get_userwindow_content())
