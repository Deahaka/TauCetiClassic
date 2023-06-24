var/global/meteor_danger_active = FALSE //Enable meteor in ticker or whenever you need

SUBSYSTEM_DEF(meteorize)
	name = "Meteorize"
	wait = 3 MINUTES
	init_order = SS_INIT_DEFAULT
	flags = SS_NO_INIT

	var/endtime = 0
	var/list/protected_areas = list()

//First fire in roundstart
/datum/controller/subsystem/meteorize/fire()
	set_endtime()
	if(!global.meteor_danger_active)
		return

	addtimer(CALLBACK(src, PROC_REF(announce_crew)), 20 MINUTES)
	addtimer(CALLBACK(src, PROC_REF(announce_crew)), 25 MINUTES)
	addtimer(CALLBACK(src, PROC_REF(announce_crew)), 29 MINUTES)

	burn_them_out()

/datum/controller/subsystem/meteorize/proc/burn_them_out()
	SSincinerating.affected_areas.Cut()
	for(var/area in protected_areas)
		var/area/target_area = get_area_by_type(area)
		SSincinerating.affected_areas += target_area
		var/list/contents = target_area.GetAreaAllContents()
		var/list/area_atoms = shuffle(contents)
		for(var/atom/A as anything in area_atoms)
			A.station_shield_effect()
	addtimer(CALLBACK(src, PROC_REF(stop_burning)), 30 SECONDS)

/datum/controller/subsystem/meteorize/proc/stop_burning()
	SSincinerating.incinerating.Cut()

/datum/controller/subsystem/meteorize/proc/announce_crew()
	var/obj/item/device/radio/intercom/announcer = new /obj/item/device/radio/intercom(null)
	announcer.config(list("Common" = 1))
	announcer.autosay("[setup_message_for_crew()].", "Announcer", "Common", freq = radiochannels["Common"])
	qdel(announcer)

/datum/controller/subsystem/meteorize/proc/setup_message_for_crew()
	var/data = "Возможное столкновение с метеором через: "
	var/time = round((endtime - world.timeofday) / 600) * 10
	data += "[time] "
	switch(time)
		if(1)
			data += "минуту"
		if(2 to 4)
			data += "минуты"
		else
			data += "минут"
	return data

/datum/controller/subsystem/meteorize/proc/set_endtime()
	endtime = world.timeofday + wait

/datum/controller/subsystem/meteorize/proc/add_more_protected_areas(areatype)
	protected_areas += areatype

/datum/controller/subsystem/meteorize/proc/set_protected_area(areatype)
	clear_protected_areas()
	add_more_protected_areas(areatype)

/datum/controller/subsystem/meteorize/proc/clear_protected_areas()
	protected_areas.Cut()

//round((SSeconomy.endtime - world.timeofday) / 600) * 10

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
	//cache for sanic speed (lists are references anyways)
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
	if (istype(SSincinerating.incinerating))
		incinerating = SSincinerating.incinerating


/obj/machinery/computer/shield_activator
	//Write your zones, selecting multiple would require a bit of rewriting
	var/list/safespaces = list(
		"North" = /area/station/maintenance/starboardsolar,
		"South" = /area/station/maintenance/auxsolarport,
		"East" = /area/station/maintenance/auxsolarstarboard,
		"West" = /area/station/maintenance/portsolar
	)

/obj/machinery/computer/shield_activator/proc/setup_browsewindow(dat)
	var/datum/browser/popup = new(usr, "computer", "Shield Activate", 400, 500)
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/shield_activator/proc/get_userwindow_content()
	var/dat = ""
	dat += "<A href='?src=\ref[src];select_target=1'>Select Targetzone</A><BR>"
	return dat

/obj/machinery/computer/shield_activator/ui_interact(mob/user)
	setup_browsewindow(get_userwindow_content())

/obj/machinery/computer/shield_activator/Topic(href, href_list)
	..()
	if(href_list["select_target"])
		var/choice = input(usr, "Select Target", "Changing") as null|anything in list("North", "South", "East", "West", "360")
		if(choice)
			if(choice == "360")
				SSmeteorize.clear_protected_areas()
				for(var/i in safespaces)
					var/areatypefromlist = safespaces[i]
					SSmeteorize.add_more_protected_areas(areatypefromlist)
			else
				SSmeteorize.set_protected_area(safespaces[choice])
	setup_browsewindow(get_userwindow_content())
