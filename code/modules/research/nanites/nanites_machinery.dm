//CircuitBoards

/obj/item/weapon/circuitboard/nanite_chamber_control
	name = "Nanite Chamber Control (Computer Board)"
	build_path = /obj/machinery/computer/nanite_chamber_control

/obj/item/weapon/circuitboard/nanite_cloud_controller
	name = "Nanite Cloud Control (Computer Board)"
	build_path = /obj/machinery/computer/nanite_cloud_controller

/obj/item/weapon/circuitboard/nanite_chamber
	name = "Nanite Chamber (Machine Board)"
	build_path = /obj/machinery/nanite_chamber
	req_components = list(
		/obj/item/weapon/stock_parts/scanning_module = 2,
		/obj/item/weapon/stock_parts/micro_laser = 2,
		/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/public_nanite_chamber
	name = "Public Nanite Chamber (Machine Board)"
	build_path = /obj/machinery/public_nanite_chamber
	var/cloud_id = 1
	req_components = list(/obj/item/weapon/stock_parts/micro_laser = 2,
						/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/public_nanite_chamber/examine(mob/user)
	. = ..()
	to_chat(user, "Cloud ID is currently set to [cloud_id].")

/obj/item/weapon/circuitboard/nanite_program_hub
	name = "Nanite Program Hub (Machine Board)"
	build_path = /obj/machinery/nanite_program_hub
	req_components = list(
		/obj/item/weapon/stock_parts/matter_bin = 1,
		/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/nanite_programmer
	name = "Nanite Programmer (Machine Board)"
	build_path = /obj/machinery/nanite_programmer
	req_components = list(
		/obj/item/weapon/stock_parts/manipulator = 2,
		/obj/item/weapon/stock_parts/micro_laser = 2,
		/obj/item/weapon/stock_parts/scanning_module = 1)

//Machines

/obj/machinery/nanite_chamber
	name = "nanite chamber"
	desc = "A device that can scan, reprogram, and inject nanites."
	icon = 'icons/obj/machines/nanite_chamber.dmi'
	icon_state = "nanite_chamber"
	use_power = IDLE_POWER_USE
	anchored = TRUE
	density = TRUE
	idle_power_usage = 50
	active_power_usage = 300
	var/obj/machinery/computer/nanite_chamber_control/console
	var/locked = FALSE
	var/breakout_time = 1200
	var/scan_level
	var/busy = FALSE
	var/busy_icon_state
	var/busy_message
	var/message_cooldown = 0

/obj/machinery/nanite_chamber/RefreshParts()
	scan_level = 0
	for(var/obj/item/weapon/stock_parts/scanning_module/P in component_parts)
		scan_level += P.rating

/obj/machinery/nanite_chamber/proc/set_busy(status, message, working_icon)
	busy = status
	busy_message = message
	busy_icon_state = working_icon
	update_icon()

/obj/machinery/nanite_chamber/proc/set_safety(threshold)
	if(!occupant)
		return
	SEND_SIGNAL(occupant, COMSIG_NANITE_SET_SAFETY, threshold)

/obj/machinery/nanite_chamber/proc/set_cloud(cloud_id)
	if(!occupant)
		return
	SEND_SIGNAL(occupant, COMSIG_NANITE_SET_CLOUD, cloud_id)

/obj/machinery/nanite_chamber/proc/inject_nanites()
	if(stat & (NOPOWER|BROKEN))
		return
	if((stat & MAINT) || panel_open)
		return
	if(!occupant || busy)
		return

	var/locked_state = locked
	locked = TRUE

	//TODO OMINOUS MACHINE SOUNDS
	set_busy(TRUE, "Initializing injection protocol...", "[initial(icon_state)]_raising")
	addtimer(CALLBACK(src, .proc/set_busy, TRUE, "Analyzing host bio-structure...", "[initial(icon_state)]_active"),20)
	addtimer(CALLBACK(src, .proc/set_busy, TRUE, "Priming nanites...", "[initial(icon_state)]_active"),40)
	addtimer(CALLBACK(src, .proc/set_busy, TRUE, "Injecting...", "[initial(icon_state)]_active"),70)
	addtimer(CALLBACK(src, .proc/set_busy, TRUE, "Activating nanites...", "[initial(icon_state)]_falling"),110)
	addtimer(CALLBACK(src, .proc/complete_injection, locked_state),130)

/obj/machinery/nanite_chamber/proc/complete_injection(locked_state)
	//TODO MACHINE DING
	locked = locked_state
	set_busy(FALSE)
	if(!occupant)
		return
	occupant.AddComponent(/datum/component/nanites, 100)

/obj/machinery/nanite_chamber/proc/remove_nanites(datum/nanite_program/NP)
	if(stat & (NOPOWER|BROKEN))
		return
	if((stat & MAINT) || panel_open)
		return
	if(!occupant || busy)
		return

	var/locked_state = locked
	locked = TRUE

//TODO OMINOUS MACHINE SOUNDS
	set_busy(TRUE, "Initializing cleanup protocol...", "[initial(icon_state)]_raising")
	addtimer(CALLBACK(src, .proc/set_busy, TRUE, "Analyzing host bio-structure...", "[initial(icon_state)]_active"),20)
	addtimer(CALLBACK(src, .proc/set_busy, TRUE, "Pinging nanites...", "[initial(icon_state)]_active"),40)
	addtimer(CALLBACK(src, .proc/set_busy, TRUE, "Initiating graceful self-destruct sequence...", "[initial(icon_state)]_active"),70)
	addtimer(CALLBACK(src, .proc/set_busy, TRUE, "Removing debris...", "[initial(icon_state)]_falling"),110)
	addtimer(CALLBACK(src, .proc/complete_removal, locked_state),130)

/obj/machinery/nanite_chamber/proc/complete_removal(locked_state)
	//TODO MACHINE DING
	locked = locked_state
	set_busy(FALSE)
	if(!occupant)
		return
	SEND_SIGNAL(occupant, COMSIG_NANITE_DELETE)

/obj/machinery/nanite_chamber/update_icon()
	cut_overlays()

	if((stat & MAINT) || panel_open)
		add_overlay("maint")

	else if(!(stat & (NOPOWER|BROKEN)))
		if(busy || locked)
			add_overlay("red")
			if(locked)
				add_overlay("bolted")
		else
			add_overlay("green")

	//running and someone in there
	if(occupant)
		if(busy)
			icon_state = busy_icon_state
		else
			icon_state = initial(icon_state)+ "_occupied"
		return

	//running
	icon_state = initial(icon_state)+ (state_open ? "_open" : "")

/obj/machinery/nanite_chamber/power_change()
	..()
	update_icon()

/obj/machinery/nanite_chamber/proc/toggle_open(mob/user)
	if(panel_open)
		to_chat(user, "<span class='notice'>Close the maintenance panel first.</span>")
		return

	if(state_open)
		close_machine()
		return

	else if(locked)
		to_chat(user, "<span class='notice'>The bolts are locked down, securing the door shut.</span>")
		return

	open_machine()

/obj/machinery/nanite_chamber/container_resist(mob/living/user)
	if(!locked)
		open_machine()
		return
	if(busy)
		return
	user.SetNextMove(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message("<span class='notice'>You see [user] kicking against the door of [src]!</span>", \
						"<span class='notice'>You lean on the back of [src] and start pushing the door open... (this will take about [DisplayTimeText(breakout_time)].)</span>", \
						"<span class='italics'>You hear a metallic creaking from [src].</span>")
	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || state_open || !locked || busy)
			return
		locked = FALSE
		user.visible_message("<span class='warning'>[user] successfully broke out of [src]!</span>", \
							"<span class='notice'>You successfully break out of [src]!</span>")
		open_machine()

/obj/machinery/nanite_chamber/close_machine(mob/living/carbon/user)
	if(!state_open)
		return FALSE

	..(user)
	return TRUE

/obj/machinery/nanite_chamber/open_machine()
	if(state_open)
		return FALSE

	..()

	return TRUE

/obj/machinery/nanite_chamber/relaymove(mob/user as mob)
	if(user.stat || locked)
		if(message_cooldown <= world.time)
			message_cooldown = world.time + 50
			to_chat(user, "<span class='warning'>[src]'s door won't budge!</span>")
		return
	open_machine()

/obj/machinery/nanite_chamber/attackby(obj/item/I, mob/user, params)
	if(!occupant && default_deconstruction_screwdriver(user, icon_state, icon_state, I))//sent icon_state is irrelevant...
		update_icon()//..since we're updating the icon here, since the scanner can be unpowered when opened/closed
		return

	if(default_pry_open(I))
		return

	if(default_deconstruction_crowbar(I))
		return

	return ..()

/obj/machinery/nanite_chamber/interact(mob/user)
	toggle_open(user)

/obj/machinery/nanite_chamber/MouseDrop_T(mob/target, mob/user)
	if(user.stat || user.lying || !Adjacent(user) || !user.Adjacent(target) || !iscarbon(target) || !user.IsAdvancedToolUser())
		return
	close_machine(target)

//Nanite Chamber Computer
/obj/machinery/computer/nanite_chamber_control
	name = "nanite chamber control console"
	desc = "Controls a connected nanite chamber. Can inoculate nanites, load programs, and analyze existing nanite swarms."
	var/obj/machinery/nanite_chamber/chamber
	var/obj/item/disk/nanite_program/disk
	circuit = /obj/item/weapon/circuitboard/nanite_chamber_control
	icon_state = "nanite_chamber_control"

/obj/machinery/computer/nanite_chamber_control/atom_init()
	. = ..()
	find_chamber()

/obj/machinery/computer/nanite_chamber_control/proc/find_chamber()
	for(var/direction in global.cardinal)
		var/C = locate(/obj/machinery/nanite_chamber, get_step(src, direction))
		if(C)
			var/obj/machinery/nanite_chamber/NC = C
			chamber = NC
			NC.console = src

/obj/machinery/computer/nanite_chamber_control/interact()
	if(!chamber)
		find_chamber()
	..()

/obj/machinery/computer/nanite_chamber_control/tgui_interact(mob/user, datum/tgui/ui)
	SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "nanite_chamber_control", name) //, 550, 800, master_ui, state)
		ui.open()

/obj/machinery/computer/nanite_chamber_control/tgui_data(mob/user)
	var/list/data = list()

	if(!chamber)
		data["status_msg"] = "No chamber detected."
		return data

	if(!chamber.occupant)
		data["status_msg"] = "No occupant detected."
		return data

	var/mob/living/L = chamber.occupant

	/*if(!(MOB_ORGANIC in L.mob_biotypes) && !(MOB_UNDEAD in L.mob_biotypes))
		data["status_msg"] = "Occupant not compatible with nanites."
		return data*/

	if(chamber.busy)
		data["status_msg"] = chamber.busy_message
		return data

	data["scan_level"] = chamber.scan_level
	data["locked"] = chamber.locked
	data["occupant_name"] = chamber.occupant.name

	SEND_SIGNAL(L, COMSIG_NANITE_UI_DATA, data, chamber.scan_level)

	return data

/obj/machinery/computer/nanite_chamber_control/tgui_act(action, list/params)
	if(..())
		return
	switch(action)
		if("toggle_lock")
			chamber.locked = !chamber.locked
			chamber.update_icon()
			. = TRUE
		if("set_safety")
			var/threshold = input("Set safety threshold (0-500):", name, null) as null|num
			if(!isnull(threshold))
				chamber.set_safety(clamp(round(threshold, 1),0,500))
				playsound(src, "terminal_type", 25, 0)
			. = TRUE
		if("set_cloud")
			var/cloud_id = input("Set cloud ID (1-100, 0 to disable):", name, null) as null|num
			if(!isnull(cloud_id))
				chamber.set_cloud(clamp(round(cloud_id, 1),0,100))
				//playsound(src, "terminal_type", 25, 0)
			. = TRUE
		if("connect_chamber")
			find_chamber()
			. = TRUE
		if("remove_nanites")
			//playsound(src, 'sound/machines/terminal_prompt.ogg', 25, FALSE)
			chamber.remove_nanites()
			. = TRUE
		if("nanite_injection")
			//playsound(src, 'sound/machines/terminal_prompt.ogg', 25, 0)
			chamber.inject_nanites()
			. = TRUE

//Nanite Cloud Controller
/obj/machinery/computer/nanite_cloud_controller
	name = "nanite cloud controller"
	desc = "Stores and controls nanite cloud backups."
	circuit = /obj/item/weapon/circuitboard/nanite_cloud_controller
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "nanite_cloud_controller"
	var/obj/item/disk/nanite_program/disk
	var/list/datum/nanite_cloud_backup/cloud_backups = list()
	var/current_view = 0 //0 is the main menu, any other number is the page of the backup with that ID

/obj/machinery/computer/nanite_cloud_controller/Destroy()
	QDEL_LIST(cloud_backups) //rip backups
	eject()
	return ..()

/obj/machinery/computer/nanite_cloud_controller/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/disk/nanite_program))
		var/obj/item/disk/nanite_program/N = I
		if(disk)
			eject(user)
		if(user.drop_from_inventory(N, src))
			to_chat(user, "<span class='notice'>You insert [N] into [src]</span>")
			//playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, 0)
			disk = N
	else
		..()

/obj/machinery/computer/nanite_cloud_controller/proc/eject(mob/living/user)
	if(!disk)
		return
	if(!istype(user) || !Adjacent(user) ||!user.put_in_active_hand(disk))
		disk.forceMove(loc)
	disk = null

/obj/machinery/computer/nanite_cloud_controller/proc/get_backup(cloud_id)
	for(var/I in cloud_backups)
		var/datum/nanite_cloud_backup/backup = I
		if(backup.cloud_id == cloud_id)
			return backup

/obj/machinery/computer/nanite_cloud_controller/proc/generate_backup(cloud_id, mob/user)
	if(SSnanites.get_cloud_backup(cloud_id, TRUE))
		to_chat(user, "<span class='warning'>Cloud ID already registered.</span>")
		return

	var/datum/nanite_cloud_backup/backup = new(src)
	var/datum/component/nanites/cloud_copy = new(backup)
	backup.cloud_id = cloud_id
	backup.nanites = cloud_copy

/obj/machinery/computer/nanite_cloud_controller/tgui_interact(mob/user, datum/tgui/ui)
	SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "nanite_cloud_control", name) //, 600, 800, master_ui, state)
		ui.open()

/obj/machinery/computer/nanite_cloud_controller/tgui_data(mob/user)
	var/list/data = list()
	if(disk)
		data["has_disk"] = TRUE
		var/list/disk_data = list()
		var/datum/nanite_program/P = disk.program
		if(P)
			data["has_program"] = TRUE
			disk_data["name"] = P.name
			disk_data["desc"] = P.desc
			disk_data["use_rate"] = P.use_rate
			disk_data["can_trigger"] = P.can_trigger
			disk_data["trigger_cost"] = P.trigger_cost
			disk_data["trigger_cooldown"] = P.trigger_cooldown / 10

			disk_data["activated"] = P.activated
			disk_data["activation_delay"] = P.activation_delay
			disk_data["timer"] = P.timer
			disk_data["activation_code"] = P.activation_code
			disk_data["deactivation_code"] = P.deactivation_code
			disk_data["kill_code"] = P.kill_code
			disk_data["trigger_code"] = P.trigger_code
			disk_data["timer_type"] = P.get_timer_type_text()

			var/list/extra_settings = list()
			for(var/X in P.extra_settings)
				var/list/setting = list()
				setting["name"] = X
				setting["value"] = P.get_extra_setting(X)
				extra_settings += list(setting)
			disk_data["extra_settings"] = extra_settings
			if(extra_settings.len)
				disk_data["has_extra_settings"] = TRUE
			if(istype(P, /datum/nanite_program/sensor))
				var/datum/nanite_program/sensor/sensor = P
				if(sensor.can_rule)
					disk_data["can_rule"] = TRUE
		data["disk"] = disk_data

	data["current_view"] = current_view
	if(current_view)
		var/datum/nanite_cloud_backup/backup = get_backup(current_view)
		if(backup)
			var/datum/component/nanites/nanites = backup.nanites
			data["cloud_backup"] = TRUE
			var/list/cloud_programs = list()
			var/id = 1
			for(var/datum/nanite_program/P in nanites.programs)
				var/list/cloud_program = list()
				cloud_program["name"] = P.name
				cloud_program["desc"] = P.desc
				cloud_program["id"] = id
				cloud_program["use_rate"] = P.use_rate
				cloud_program["can_trigger"] = P.can_trigger
				cloud_program["trigger_cost"] = P.trigger_cost
				cloud_program["trigger_cooldown"] = P.trigger_cooldown / 10
				cloud_program["activated"] = P.activated
				cloud_program["activation_delay"] = P.activation_delay
				cloud_program["timer"] = P.timer
				cloud_program["timer_type"] = P.get_timer_type_text()
				cloud_program["activation_code"] = P.activation_code
				cloud_program["deactivation_code"] = P.deactivation_code
				cloud_program["kill_code"] = P.kill_code
				cloud_program["trigger_code"] = P.trigger_code
				var/list/rules = list()
				var/rule_id = 1
				for(var/X in P.rules)
					var/datum/nanite_rule/nanite_rule = X
					var/list/rule = list()
					rule["display"] = nanite_rule.display()
					rule["program_id"] = id
					rule["id"] = rule_id
					rules += list(rule)
					rule_id++
				cloud_program["rules"] = rules
				if(rules.len)
					cloud_program["has_rules"] = TRUE

				var/list/extra_settings = list()
				for(var/X in P.extra_settings)
					var/list/setting = list()
					setting["name"] = X
					setting["value"] = P.get_extra_setting(X)
					extra_settings += list(setting)
				cloud_program["extra_settings"] = extra_settings
				if(extra_settings.len)
					cloud_program["has_extra_settings"] = TRUE
				id++
				cloud_programs += list(cloud_program)
			data["cloud_programs"] = cloud_programs
	else
		var/list/backup_list = list()
		for(var/X in cloud_backups)
			var/datum/nanite_cloud_backup/backup = X
			var/list/cloud_backup = list()
			cloud_backup["cloud_id"] = backup.cloud_id
			backup_list += list(cloud_backup)
		data["cloud_backups"] = backup_list
	return data

/obj/machinery/computer/nanite_cloud_controller/tgui_act(action, list/params)
	if(..())
		return
	switch(action)
		if("eject")
			eject(usr)
			. = TRUE
		if("set_view")
			current_view = text2num(params["view"])
			. = TRUE
		if("create_backup")
			var/cloud_id = input("Choose a cloud ID (1-100):", name, null) as null|num
			if(!isnull(cloud_id))
				//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
				cloud_id = clamp(round(cloud_id, 1),1,100)
				generate_backup(cloud_id, usr)
			. = TRUE
		if("delete_backup")
			var/datum/nanite_cloud_backup/backup = get_backup(current_view)
			if(backup)
				//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
				qdel(backup)
			. = TRUE
		if("upload_program")
			if(disk && disk.program)
				var/datum/nanite_cloud_backup/backup = get_backup(current_view)
				if(backup)
					//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
					var/datum/component/nanites/nanites = backup.nanites
					nanites.add_program(disk.program.copy())
			. = TRUE
		if("remove_program")
			var/datum/nanite_cloud_backup/backup = get_backup(current_view)
			if(backup)
				//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
				var/datum/component/nanites/nanites = backup.nanites
				var/datum/nanite_program/P = nanites.programs[text2num(params["program_id"])]
				qdel(P)
			. = TRUE
		if("add_rule")
			if(disk && disk.program && istype(disk.program, /datum/nanite_program/sensor))
				var/datum/nanite_program/sensor/rule_template = disk.program
				if(!rule_template.can_rule)
					return
				//for logs
				//var/datum/nanite_cloud_backup/backup = get_backup(current_view)
				//if(backup)
					//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
					//var/datum/component/nanites/nanites = backup.nanites
					//var/datum/nanite_program/P = nanites.programs[text2num(params["program_id"])]
					//var/datum/nanite_rule/rule = rule_template.make_rule(P)
			. = TRUE
		if("remove_rule")
			var/datum/nanite_cloud_backup/backup = get_backup(current_view)
			if(backup)
				//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
				var/datum/component/nanites/nanites = backup.nanites
				var/datum/nanite_program/P = nanites.programs[text2num(params["program_id"])]
				var/datum/nanite_rule/rule = P.rules[text2num(params["rule_id"])]
				rule.remove()
			. = TRUE

/datum/nanite_cloud_backup
	var/cloud_id = 0
	var/datum/component/nanites/nanites
	var/obj/machinery/computer/nanite_cloud_controller/storage

/datum/nanite_cloud_backup/New(obj/machinery/computer/nanite_cloud_controller/_storage)
	storage = _storage
	storage.cloud_backups += src
	SSnanites.cloud_backups += src

/datum/nanite_cloud_backup/Destroy()
	storage.cloud_backups -= src
	SSnanites.cloud_backups -= src
	return ..()

//Nanite Hijacker
/obj/item/nanite_hijacker
	name = "nanite remote control" //fake name
	desc = "A device that can load nanite programming disks, edit them at will, and imprint them to nanites remotely."
	w_class = SIZE_SMALL
	icon = 'icons/obj/device.dmi'
	icon_state = "nanite_remote"
	flags = NOBLUDGEON
	var/obj/item/disk/nanite_program/disk
	var/datum/nanite_program/program

/obj/item/nanite_hijacker/AltClick(mob/user)
	. = ..()
	if(!CanUseTopic(user))
		return
	if(disk)
		eject()

/obj/item/nanite_hijacker/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/disk/nanite_program))
		var/obj/item/disk/nanite_program/N = I
		if(disk)
			eject()
		if(user.drop_from_inventory(N, src))
			to_chat(user, "<span class='notice'>You insert [N] into [src]</span>")
			disk = N
			program = N.program
	else
		..()

/obj/item/nanite_hijacker/proc/eject(mob/living/user)
	if(!disk)
		return
	if(!istype(user) || !Adjacent(user) || !user.put_in_any_hand_if_possible(disk))
		disk.forceMove(loc)
	disk = null
	program = null

/obj/item/nanite_hijacker/afterattack(atom/target, mob/user, etc)
	if(!disk || !disk.program)
		return
	if(isliving(target))
		var/success = SEND_SIGNAL(target, COMSIG_NANITE_ADD_PROGRAM, program.copy())
		switch(success)
			if(NONE)
				to_chat(user, "<span class='notice'>You don't detect any nanites in [target].</span>")
			if(COMPONENT_PROGRAM_INSTALLED)
				to_chat(user, "<span class='notice'>You insert the currently loaded program into [target]'s nanites.</span>")
			if(COMPONENT_PROGRAM_NOT_INSTALLED)
				to_chat(user, "<span class='warning'>You try to insert the currently loaded program into [target]'s nanites, but the installation fails.</span>")

//Same UI as the nanite programmer, as it pretty much does the same
/obj/item/nanite_hijacker/tgui_interact(mob/user, datum/tgui/ui)
	SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "nanite_programmer", "Internal Nanite Programmer") //, 420, 800, master_ui, state)
		ui.open()

/obj/item/nanite_hijacker/tgui_data(mob/user)
	var/list/data = list()
	data["has_disk"] = istype(disk)
	data["has_program"] = istype(program)
	if(program)
		data["name"] = program.name
		data["desc"] = program.desc
		data["use_rate"] = program.use_rate
		data["can_trigger"] = program.can_trigger
		data["trigger_cost"] = program.trigger_cost
		data["trigger_cooldown"] = program.trigger_cooldown / 10

		data["activated"] = program.activated
		data["activation_delay"] = program.activation_delay
		data["timer"] = program.timer
		data["activation_code"] = program.activation_code
		data["deactivation_code"] = program.deactivation_code
		data["kill_code"] = program.kill_code
		data["trigger_code"] = program.trigger_code
		data["timer_type"] = program.get_timer_type_text()

		var/list/extra_settings = list()
		for(var/X in program.extra_settings)
			var/list/setting = list()
			setting["name"] = X
			setting["value"] = program.get_extra_setting(X)
			extra_settings += list(setting)
		data["extra_settings"] = extra_settings
		if(extra_settings.len)
			data["has_extra_settings"] = TRUE

	return data

/obj/item/nanite_hijacker/tgui_act(action, list/params)
	if(..())
		return
	switch(action)
		if("eject")
			eject(usr)
			. = TRUE
		if("toggle_active")
			program.activated = !program.activated //we don't use the activation procs since we aren't in a mob
			if(program.activated)
				program.activation_delay = 0
			. = TRUE
		if("set_code")
			var/new_code = input("Set code (0000-9999):", name, null) as null|num
			if(!isnull(new_code))
				new_code = clamp(round(new_code, 1),0,9999)
			else
				return

			var/target_code = params["target_code"]
			switch(target_code)
				if("activation")
					program.activation_code = clamp(round(new_code, 1),0,9999)
				if("deactivation")
					program.deactivation_code = clamp(round(new_code, 1),0,9999)
				if("kill")
					program.kill_code = clamp(round(new_code, 1),0,9999)
				if("trigger")
					program.trigger_code = clamp(round(new_code, 1),0,9999)
			. = TRUE
		if("set_extra_setting")
			program.set_extra_setting(usr, params["target_setting"])
			. = TRUE
		if("set_activation_delay")
			var/delay = input("Set activation delay in seconds (0-1800):", name, program.activation_delay) as null|num
			if(!isnull(delay))
				delay = clamp(round(delay, 1),0,1800)
				program.activation_delay = delay
				if(delay)
					program.activated = FALSE
			. = TRUE
		if("set_timer")
			var/timer = input("Set timer in seconds (10-3600):", name, program.timer) as null|num
			if(!isnull(timer))
				if(!timer == 0)
					timer = clamp(round(timer, 1),10,3600)
				program.timer = timer
			. = TRUE
		if("set_timer_type")
			var/new_type = input("Choose the timer effect","Timer Effect") as null|anything in list("Deactivate","Self-Delete","Trigger","Reset Activation Timer")
			if(new_type)
				switch(new_type)
					if("Deactivate")
						program.timer_type = NANITE_TIMER_DEACTIVATE
					if("Self-Delete")
						program.timer_type = NANITE_TIMER_SELFDELETE
					if("Trigger")
						program.timer_type = NANITE_TIMER_TRIGGER
					if("Reset Activation Timer")
						program.timer_type = NANITE_TIMER_RESET
			. = TRUE

//Nanite Program Hub
/obj/machinery/nanite_program_hub
	name = "nanite program hub"
	desc = "Compiles nanite programs from the techweb servers and downloads them into disks."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "nanite_program_hub"
	use_power = IDLE_POWER_USE
	anchored = TRUE
	density = TRUE

	var/obj/item/disk/nanite_program/disk
	var/datum/research/linked_techweb
	var/current_category = "Main"
	var/detail_view = FALSE
	var/categories = list(
						list(name = "Utility Nanites"),
						list(name = "Medical Nanites"),
						list(name = "Sensor Nanites"),
						list(name = "Augmentation Nanites"),
						list(name = "Suppression Nanites"),
						list(name = "Weaponized Nanites")
						)

/obj/machinery/nanite_program_hub/atom_init()
	. = ..()
	for(var/obj/machinery/computer/rdconsole/RD in RDcomputer_list)
		if(RD.id == 1)
			linked_techweb = RD.files

/obj/machinery/nanite_program_hub/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/disk/nanite_program))
		var/obj/item/disk/nanite_program/N = I
		if(disk)
			eject(user)
		if(user.drop_from_inventory(N, src))
			to_chat(user, "<span class='notice'>You insert [N] into [src]</span>")
			//playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, 0)
			disk = N
	else
		..()

/obj/machinery/nanite_program_hub/proc/eject(mob/living/user)
	if(!disk)
		return
	if(!istype(user) || !Adjacent(user) || !user.put_in_active_hand(disk))
		disk.forceMove(loc)
	disk = null

/obj/machinery/nanite_program_hub/tgui_interact(mob/user, datum/tgui/ui)
	SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "nanite_program_hub", name) //, 500, 700, master_ui, state)
		ui.set_autoupdate(FALSE) //to avoid making the whole program list every second
		ui.open()

/obj/machinery/nanite_program_hub/tgui_data(mob/user)
	var/list/data = list()
	if(disk)
		data["has_disk"] = TRUE
		var/list/disk_data = list()
		var/datum/nanite_program/P = disk.program
		if(P)
			data["has_program"] = TRUE
			disk_data["name"] = P.name
			disk_data["desc"] = P.desc
		data["disk"] = disk_data

	data["detail_view"] = detail_view
	data["category"] = current_category

	if(current_category != "Main")
		var/list/program_list = list()
		for(var/i in linked_techweb.researched_tech)
			var/datum/design/nanites/D = linked_techweb.known_designs[i]
			if(!istype(D))
				continue
			if(current_category in D.category)
				var/list/program_design = list()
				program_design["id"] = D.id
				program_design["name"] = D.name
				program_design["desc"] = D.desc
				program_list += list(program_design)
		data["program_list"] = program_list
	else
		data["categories"] = categories

	return data

/obj/machinery/nanite_program_hub/tgui_act(action, list/params)
	if(..())
		return
	switch(action)
		if("eject")
			eject(usr)
			. = TRUE
		if("download")
			if(!disk)
				return
			var/datum/design/nanites/downloaded = linked_techweb.IsResearched(params["program_id"]) //check if it's a valid design
			if(!istype(downloaded))
				return
			if(disk.program)
				qdel(disk.program)
			disk.program = new downloaded.program_type
			disk.name = "[initial(disk.name)] \[[disk.program.name]\]"
			//playsound(src, 'sound/machines/terminal_prompt.ogg', 25, 0)
			. = TRUE
		if("set_category")
			var/new_category = params["category"]
			current_category = new_category
			. = TRUE
		if("toggle_details")
			detail_view = !detail_view
			. = TRUE
		if("clear")
			if(disk && disk.program)
				qdel(disk.program)
				disk.program = null
				disk.name = initial(disk.name)
			. = TRUE

//Nanite Programmer
/obj/machinery/nanite_programmer
	name = "nanite programmer"
	desc = "A device that can edit nanite program disks to adjust their functionality."
	var/obj/item/disk/nanite_program/disk
	var/datum/nanite_program/program
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "nanite_programmer"
	use_power = IDLE_POWER_USE
	anchored = TRUE
	density = TRUE

/obj/machinery/nanite_programmer/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/disk/nanite_program))
		var/obj/item/disk/nanite_program/N = I
		if(disk)
			eject(user)
		if(user.drop_from_inventory(N, src))
			to_chat(user, "<span class='notice'>You insert [N] into [src]</span>")
			//playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, 0)
			disk = N
			program = N.program
	else
		..()

/obj/machinery/nanite_programmer/proc/eject(mob/living/user)
	if(!disk)
		return
	if(!istype(user) || !Adjacent(user) || !user.put_in_active_hand(disk))
		disk.forceMove(loc)
	disk = null
	program = null

/obj/machinery/nanite_programmer/tgui_interact(mob/user, datum/tgui/ui)
	SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "nanite_programmer", name) //, 600, 800, master_ui, state)
		ui.open()

/obj/machinery/nanite_programmer/tgui_data(mob/user)
	var/list/data = list()
	data["has_disk"] = istype(disk)
	data["has_program"] = istype(program)
	if(program)
		data["name"] = program.name
		data["desc"] = program.desc
		data["use_rate"] = program.use_rate
		data["can_trigger"] = program.can_trigger
		data["trigger_cost"] = program.trigger_cost
		data["trigger_cooldown"] = program.trigger_cooldown / 10

		data["activated"] = program.activated
		data["activation_delay"] = program.activation_delay
		data["timer"] = program.timer
		data["activation_code"] = program.activation_code
		data["deactivation_code"] = program.deactivation_code
		data["kill_code"] = program.kill_code
		data["trigger_code"] = program.trigger_code
		data["timer_type"] = program.get_timer_type_text()

		var/list/extra_settings = list()
		for(var/X in program.extra_settings)
			var/list/setting = list()
			setting["name"] = X
			setting["value"] = program.get_extra_setting(X)
			extra_settings += list(setting)
		data["extra_settings"] = extra_settings
		if(extra_settings.len)
			data["has_extra_settings"] = TRUE

	return data

/obj/machinery/nanite_programmer/tgui_act(action, list/params)
	if(..())
		return
	switch(action)
		if("eject")
			eject(usr)
			. = TRUE
		if("toggle_active")
			playsound(src, "terminal_type", 25, 0)
			program.activated = !program.activated //we don't use the activation procs since we aren't in a mob
			if(program.activated)
				program.activation_delay = 0
			. = TRUE
		if("set_code")
			var/new_code = input("Set code (0000-9999):", name, null) as null|num
			if(!isnull(new_code))
				playsound(src, "terminal_type", 25, 0)
				new_code = clamp(round(new_code, 1),0,9999)
			else
				return

			playsound(src, "terminal_type", 25, 0)
			var/target_code = params["target_code"]
			switch(target_code)
				if("activation")
					program.activation_code = clamp(round(new_code, 1),0,9999)
				if("deactivation")
					program.deactivation_code = clamp(round(new_code, 1),0,9999)
				if("kill")
					program.kill_code = clamp(round(new_code, 1),0,9999)
				if("trigger")
					program.trigger_code = clamp(round(new_code, 1),0,9999)
			. = TRUE
		if("set_extra_setting")
			program.set_extra_setting(usr, params["target_setting"])
			playsound(src, "terminal_type", 25, 0)
			. = TRUE
		if("set_activation_delay")
			var/delay = input("Set activation delay in seconds (0-1800):", name, program.activation_delay) as null|num
			if(!isnull(delay))
				playsound(src, "terminal_type", 25, 0)
				delay = clamp(round(delay, 1),0,1800)
				program.activation_delay = delay
				if(delay)
					program.activated = FALSE
			. = TRUE
		if("set_timer")
			var/timer = input("Set timer in seconds (10-3600):", name, program.timer) as null|num
			if(!isnull(timer))
				playsound(src, "terminal_type", 25, 0)
				if(!timer == 0)
					timer = clamp(round(timer, 1),10,3600)
				program.timer = timer
			. = TRUE
		if("set_timer_type")
			var/new_type = input("Choose the timer effect","Timer Effect") as null|anything in list("Deactivate","Self-Delete","Trigger","Reset Activation Timer")
			if(new_type)
				playsound(src, "terminal_type", 25, 0)
				switch(new_type)
					if("Deactivate")
						program.timer_type = NANITE_TIMER_DEACTIVATE
					if("Self-Delete")
						program.timer_type = NANITE_TIMER_SELFDELETE
					if("Trigger")
						program.timer_type = NANITE_TIMER_TRIGGER
					if("Reset Activation Timer")
						program.timer_type = NANITE_TIMER_RESET
			. = TRUE

//Public Chamber
/obj/machinery/public_nanite_chamber
	name = "public nanite chamber"
	desc = "A device that can rapidly implant cloud-synced nanites without an external operator."
	icon = 'icons/obj/machines/nanite_chamber.dmi'
	icon_state = "nanite_chamber"
	use_power = IDLE_POWER_USE
	anchored = TRUE
	density = TRUE
	idle_power_usage = 50
	active_power_usage = 300

	var/cloud_id = 1
	var/locked = FALSE
	var/breakout_time = 1200
	var/busy = FALSE
	var/busy_icon_state
	var/message_cooldown = 0

/obj/machinery/public_nanite_chamber/proc/set_busy(status, working_icon)
	busy = status
	busy_icon_state = working_icon
	update_icon()

/obj/machinery/public_nanite_chamber/proc/inject_nanites()
	if(stat & (NOPOWER|BROKEN))
		return
	if((stat & MAINT) || panel_open)
		return
	if(!occupant || busy)
		return

	var/locked_state = locked
	locked = TRUE

	//TODO OMINOUS MACHINE SOUNDS
	set_busy(TRUE, "[initial(icon_state)]_raising")
	addtimer(CALLBACK(src, .proc/set_busy, TRUE, "[initial(icon_state)]_active"),20)
	addtimer(CALLBACK(src, .proc/set_busy, TRUE, "[initial(icon_state)]_falling"),60)
	addtimer(CALLBACK(src, .proc/complete_injection, locked_state),80)

/obj/machinery/public_nanite_chamber/proc/complete_injection(locked_state)
	//TODO MACHINE DING
	locked = locked_state
	set_busy(FALSE)
	if(!occupant)
		return
	occupant.AddComponent(/datum/component/nanites, 75, cloud_id)

/obj/machinery/public_nanite_chamber/update_icon()
	cut_overlays()

	if((stat & MAINT) || panel_open)
		add_overlay("maint")

	else if(!(stat & (NOPOWER|BROKEN)))
		if(busy || locked)
			add_overlay("red")
			if(locked)
				add_overlay("bolted")
		else
			add_overlay("green")



	//running and someone in there
	if(occupant)
		if(busy)
			icon_state = busy_icon_state
		else
			icon_state = initial(icon_state)+ "_occupied"
		return

	//running
	icon_state = initial(icon_state)+ (state_open ? "_open" : "")

/obj/machinery/public_nanite_chamber/power_change()
	. = ..()
	update_icon()

/obj/machinery/public_nanite_chamber/proc/toggle_open(mob/user)
	if(panel_open)
		to_chat(user, "<span class='notice'>Close the maintenance panel first.</span>")
		return

	if(state_open)
		close_machine()
		return

	else if(locked)
		to_chat(user, "<span class='notice'>The bolts are locked down, securing the door shut.</span>")
		return

	open_machine()

/obj/machinery/public_nanite_chamber/container_resist(mob/living/user)
	if(!locked)
		open_machine()
		return
	if(busy)
		return
	user.SetNextMove(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message("<span class='notice'>You see [user] kicking against the door of [src]!</span>", \
		"<span class='notice'>You lean on the back of [src] and start pushing the door open... (this will take about [DisplayTimeText(breakout_time)].)</span>", \
		"<span class='italics'>You hear a metallic creaking from [src].</span>")
	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || state_open || !locked || busy)
			return
		locked = FALSE
		user.visible_message("<span class='warning'>[user] successfully broke out of [src]!</span>", \
			"<span class='notice'>You successfully break out of [src]!</span>")
		open_machine()

/obj/machinery/public_nanite_chamber/close_machine(mob/living/carbon/user)
	if(!state_open)
		return FALSE

	..()

	. = TRUE

	addtimer(CALLBACK(src, .proc/try_inject_nanites), 30) //If someone is shoved in give them a chance to get out before the injection starts

/obj/machinery/public_nanite_chamber/proc/try_inject_nanites()
	if(occupant)
		var/mob/living/L = occupant
		if(SEND_SIGNAL(L, COMSIG_HAS_NANITES))
			return
		/*if((MOB_ORGANIC in L.mob_biotypes) || (MOB_UNDEAD in L.mob_biotypes))
		*/
		inject_nanites()

/obj/machinery/public_nanite_chamber/open_machine()
	if(state_open)
		return FALSE

	..()

	return TRUE

/obj/machinery/public_nanite_chamber/relaymove(mob/user as mob)
	if(user.stat || locked)
		if(message_cooldown <= world.time)
			message_cooldown = world.time + 50
			to_chat(user, "<span class='warning'>[src]'s door won't budge!</span>")
		return
	open_machine()

/obj/machinery/public_nanite_chamber/attackby(obj/item/I, mob/user, params)
	if(!occupant && default_deconstruction_screwdriver(user, icon_state, icon_state, I))//sent icon_state is irrelevant...
		update_icon()//..since we're updating the icon here, since the scanner can be unpowered when opened/closed
		return

	if(default_pry_open(I))
		return

	if(default_deconstruction_crowbar(I))
		return

	return ..()

/obj/machinery/public_nanite_chamber/interact(mob/user)
	toggle_open(user)

/obj/machinery/public_nanite_chamber/MouseDrop_T(mob/target, mob/user)
	if(user.stat || user.lying || !Adjacent(user) || !user.Adjacent(target) || !iscarbon(target) || !user.IsAdvancedToolUser())
		return
	close_machine(target)
