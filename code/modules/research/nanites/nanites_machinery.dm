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
	var/scan_level = 0
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
	icon_state = "nanite_chamber_control"
	circuit = /obj/item/weapon/circuitboard/nanite_chamber_control
	var/obj/machinery/nanite_chamber/chamber
	var/obj/item/disk/nanite_program/disk
	var/details_view = FALSE

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

//TODO: show programs
/obj/machinery/computer/nanite_chamber_control/proc/get_data()
	var/data = ""
	if(!chamber)
		data += "No chamber detected"
		data += "<A href='?src=\ref[src];connect_chamber=1'>Try Connect Chamber</A><br>"
		return data
	if(!chamber.occupant)
		data += "No occupant detected"
		return data
	if(chamber.busy)
		data += "[chamber.busy_message]"
		return data
	var/mob/living/occupant = chamber.occupant
	var/datum/component/nanites/data_handler = occupant?.GetComponent(/datum/component/nanites)
	var/has_nanites = !isnull(data_handler)
	var/scan_lvl = chamber.scan_level
	data += "Scan Level: [chamber.scan_level]<br>"
	data += "Chamber: [occupant ? "<A href='?src=\ref[src];eject_occupant=1'>[occupant.name]</A>" : ""]<br>"
	data += "Lock: [chamber.locked ? "Engaged" : "Disengaged"]. <A href='?src=\ref[src];toggle_lock=1'>[chamber.locked ? "Unlock" : "Lock"]</A><br>"
	data += "<hr>"
	if(has_nanites)
		data += "Nanite Volume: [data_handler.nanite_volume]<br>"
		data += "Grown Rate: [data_handler.regen_rate]<br>"
		data += "Current Safety Treshold: [data_handler.safety_threshold] <A href='?src=\ref[src];set_safety=1'>Set Safety Threshold</A><br>"
		data += "Cloud ID: [data_handler.cloud_id] <A href='?src=\ref[src];set_cloud=1'>Set cloud ID</A><br>"
		data += "Synchronization: [data_handler.cloud_active ? "Actived" : "Deactivated"]<br>"
		if(scan_lvl >= 2)
			data += "<hr><A href='?src=\ref[src];det_view=1'>Details</A><br>"
		if(details_view)
			for(var/datum/nanite_program/P in data_handler.programs)
				data += "Program name: [P.name] Status: [P.activated ? "Activated" : "Deactivated"]<br>"
				data += "Use Rate: [P.use_rate]<br>"
				if(P.can_trigger)
					data += "Trigger Cost: [P.trigger_cost]<br>"
					data += "Trigger Cooldown: [P.trigger_cooldown / 10]<br>"
				if(scan_lvl >= 3)
					data += "Timer Restart: [P.timer_restart / 10]<br>"
					data += "Timer Shutdown: [P.timer_shutdown / 10]<br>"
					data += "Timer Trigger: [P.timer_trigger / 10]<br>"
					data += "Timer Trigger Delay: [P.timer_trigger_delay / 10]<br>"
					var/list/extra_settings = P.get_extra_settings_frontend()
					if(extra_settings.len)
						data += "<hr>Special Settings:<br>"
						for(var/settin in extra_settings)
							data += "[settin["name"]]: [settin["value"]]<br>"
				if(scan_lvl >= 4)
					data += "Activation Code: [P.activation_code]<br>"
					data += "Deactivation Code: [P.deactivation_code]<br>"
					data += "Kill Code: [P.kill_code]<br>"
					if(P.can_trigger)
						data += "Trigger Code: [P.trigger_code]<br>"
					if(P.rules.len)
						data += "<hr>Rules:<br>"
						var/rule_id = 1
						for(var/datum/nanite_rule/nanite_rule in P.rules)
							data += "[rule_id] - [nanite_rule.display()]"
							rule_id++
		data += "<hr><A href='?src=\ref[src];remove_nanites=1'><span class='red'>Destroy Nanites</span></A><br>"
	else
		data += "No nanites detected.<br>"
		data += "<hr><A href='?src=\ref[src];nanite_injection=1'><span class='green'>Inject Nanites</span></A>"

	return data

/obj/machinery/computer/nanite_chamber_control/ui_interact(mob/user)
	var/data = get_data()
	popup(user, data, name)

//TODO: Updating
/obj/machinery/computer/nanite_chamber_control/Topic(href, href_list)
	..()
	if(href_list["toggle_lock"])
		if(chamber.occupant && !chamber.state_open)
			chamber.locked = !chamber.locked
			chamber.update_icon()
	if(href_list["set_safety"])
		if(chamber.occupant && !chamber.state_open)
			var/threshold = input("Set safety threshold (0-500):", name, null) as null|num
			if(!isnull(threshold))
				chamber.set_safety(clamp(round(threshold, 1),0,500))
				playsound(src, "terminal_type", 25, 0)
	if(href_list["set_cloud"])
		if(chamber.occupant && !chamber.state_open)
			var/cloud_id = input("Set cloud ID (1-100, 0 to disable):", name, null) as null|num
			if(!isnull(cloud_id))
				chamber.set_cloud(clamp(round(cloud_id, 1),0,100))
				playsound(src, "terminal_type", 25, 0)
	if(href_list["connect_chamber"])
		find_chamber()
	if(href_list["remove_nanites"])
		if(chamber.occupant && !chamber.state_open)
			chamber.remove_nanites()
	if(href_list["nanite_injection"])
		if(chamber.occupant && !chamber.state_open)
			chamber.inject_nanites()
	if(href_list["eject_occupant"])
		if(chamber.occupant && !chamber.locked && !chamber.state_open)
			chamber.toggle_open()
	if(href_list["det_view"])
		details_view = !details_view
	updateUsrDialog()

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
	var/new_backup_id = 1

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
	var/ID_cloud = text2num(cloud_id)
	for(var/datum/nanite_cloud_backup/backup in cloud_backups)
		if(backup.cloud_id != ID_cloud)
			continue
		return backup

/obj/machinery/computer/nanite_cloud_controller/proc/generate_backup(cloud_id, mob/user)
	if(SSnanites.get_cloud_backup(cloud_id, TRUE))
		to_chat(user, "<span class='warning'>Cloud ID already registered.</span>")
		return

	var/datum/nanite_cloud_backup/backup = new(src)
	var/datum/component/nanites/cloud_copy = new(backup)
	backup.cloud_id = cloud_id
	backup.nanites = cloud_copy

/obj/machinery/computer/nanite_cloud_controller/proc/get_data()
	var/data = ""
	var/has_disk = !isnull(disk)
	var/has_program = FALSE
	var/can_rule = FALSE
	if(has_disk)
		data += "Program disk: <A href='?src=\ref[src];eject=1'>Eject</A><hr>"
		if(disk.program)
			var/datum/nanite_program/disk_program = disk.program
			has_program = TRUE
			var/is_can_be_triggered = disk_program.can_trigger
			data += "[disk_program.name] [disk_program.activated ? "<span class='green'>Activated</span>" : "<span class='red'>Deactivated</span>"]<br><hr>"
			data += "[disk_program.desc]<br>"
			data += "Use_rate: [disk_program.use_rate]<br>"
			if(is_can_be_triggered)
				data += "Trigger Cost: [disk_program.trigger_cost]<br>"
				data += "Trigger Cooldown: [disk_program.trigger_cooldown / 10]<br>"
			data += "<hr>"
			data += "Activation Code: [disk_program.activation_code]<br>"
			data += "Deactivation Code: [disk_program.deactivation_code]<br>"
			data += "Kill Code: [disk_program.kill_code]<br>"
			data += "<hr>"
			data += "Restart: [disk_program.timer_restart / 10]<br>"
			data += "Shutdown: [disk_program.timer_shutdown / 10]<br>"
			if(is_can_be_triggered)
				data += "Trigger Code: [disk_program.trigger_code]<br>"
				data += "Timer Trugger: [disk_program.timer_trigger / 10]<br>"
				data += "Timer Trigger Delay: [disk_program.timer_trigger_delay / 10]<br>"
			var/list/list_of_extra_settings = disk_program.get_extra_settings_frontend()
			if(list_of_extra_settings.len)
				if(istype(disk_program, /datum/nanite_program/sensor))
					var/datum/nanite_program/sensor/sensor = disk_program
					if(sensor.can_rule)
						can_rule = TRUE
		else
			data += "Inserted disk has no program<br>"
	//cant early return because there is 3 more buttons in menu
	else
		data += "No disk inserted<br>"
	var/has_rules = FALSE
	if(current_view)
		data += "<A href='?src=\ref[src];return_view=1'>Return</A><br>"
		var/datum/nanite_cloud_backup/backup = get_backup(current_view)
		if(backup)
			var/datum/component/nanites/nanites = backup.nanites
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
				cloud_program["timer_restart"] = P.timer_restart / 10
				cloud_program["timer_shutdown"] = P.timer_shutdown / 10
				cloud_program["timer_trigger"] = P.timer_trigger / 10
				cloud_program["timer_trigger_delay"] = P.timer_trigger_delay / 10

				cloud_program["activation_code"] = P.activation_code
				cloud_program["deactivation_code"] = P.deactivation_code
				cloud_program["kill_code"] = P.kill_code
				cloud_program["trigger_code"] = P.trigger_code
				var/list/rules = list()
				var/rule_id = 1
				for(var/datum/nanite_rule/nanite_rule in P.rules)
					var/list/rule = list()
					rule["display"] = nanite_rule.display()
					rule["program_id"] = id
					rule["id"] = rule_id
					rules += rule
					rule_id++
				cloud_program["rules"] = rules
				if(rules.len)
					has_rules = TRUE
				var/list/extra_settings = P.get_extra_settings_frontend()
				cloud_program["extra_settings"] = extra_settings
				if(extra_settings.len)
					cloud_program["has_extra_settings"] = TRUE
				id++
				cloud_programs += cloud_program
			if(cloud_programs.len)
				data += "Backup # [current_view]<br>"
				//I dont understand how i can throw all programs in backup -_-
				data += "[cloud_programs["name"]] <A href='?src=\ref[src];remove_program=[cloud_programs["name"]]'>Remove</A><br>"
				if(has_rules && can_rule)
					//not tested
					var/list/rules_list = cloud_programs["rules"]
					if(rules_list.len)
						data += "Rules:<br>"
						for(var/cloud_program in cloud_programs)
							data += "<A href='?src=\ref[src];add_rule=[cloud_program["id"]]'>Add Rule from Disk</A><br>"
							if(has_rules)
								for(var/nanite_rules in rules_list)
									data += "<A href='?src=\ref[src];remove_rule=[cloud_program["id"]];rule_id=[nanite_rules["id"]]'>Remove Rule Display:[nanite_rules["display"]]</A><br>"
							else
								data += "No Active Rules<br>"

				/*old code not worked
				for(var/programs in cloud_programs)
					to_chat(world, "programs is [programs]")
					for(var/x in programs)
						to_chat(world, "x is [x]")
						to_chat(world, "xrules is [x["rules"]]")*/
					/*var/list/rules_list = list()
					rules_list += programs["rules"]
					if(can_rule && has_rules && rules_list.len)
						data += "Rules:<br>"
						for(var/cloud_program in programs)
							data += "<A href='?src=\ref[src];add_rule=[cloud_program["id"]]'>Add Rule from Disk</A><br>"
							if(has_rules)
								for(var/nanite_rules in rules_list)
									data += "<A href='?src=\ref[src];remove_rule=[cloud_program["id"]];rule_id=[nanite_rules["id"]]'>Remove Rule Display:[nanite_rules["display"]]</A><br>"
							else
								data += "No Active Rules<br>"*/
			else
				data += "No cloud programs<br>"
			if(has_program)
				data += "<A href='?src=\ref[src];upload_program=1'>Upload From Disk</A><br>"
		else
			data += "ERROR: Backup not found<br>"
	else
		data += "<hr>Create Backup<br>"
		data += "Backup ID: <A href='?src=\ref[src];update_new_backup_value=1'>[new_backup_id]</A><br>"
		data += "<A href='?src=\ref[src];create_backup=1'>Create</A><br><hr>"
		var/list/backup_list = list()
		for(var/X in cloud_backups)
			var/datum/nanite_cloud_backup/backup = X
			var/list/cloud_backup = list()
			cloud_backup["cloud_id"] = backup.cloud_id
			backup_list += list(cloud_backup)
		if(backup_list.len)
			for(var/backups in backup_list)
				data += "Backup # <A href='?src=\ref[src];set_view=[backups["cloud_id"]]'>[backups["cloud_id"]]</A><br>"
		else
			data += "No backups<br>"
	return data

/obj/machinery/computer/nanite_cloud_controller/ui_interact(mob/user)
	var/data = get_data()
	popup(user, data, name)

/obj/machinery/computer/nanite_cloud_controller/Topic(href, href_list)
	..()
	if(href_list["eject"])
		eject(usr)
	if(href_list["set_view"])
		current_view = href_list["set_view"]
	//set_view=0 its ^^^ href_list["set_view"] = 0 and clause not working
	if(href_list["return_view"])
		current_view = 0
	if(href_list["update_new_backup_value"])
		var/backup_value = input("Set new ID for backup", name, null) as null|num
		new_backup_id = backup_value
	if(href_list["create_backup"])
		var/cloud_id = new_backup_id
		if(!isnull(cloud_id))
			//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
			cloud_id = clamp(round(cloud_id, 1),1,100)
			generate_backup(cloud_id, usr)
	if(href_list["delete_backup"])
		var/datum/nanite_cloud_backup/backup = get_backup(current_view)
		if(backup)
			//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
			qdel(backup)
	if(href_list["upload_program"])
		if(disk && disk.program)
			var/datum/nanite_cloud_backup/backup = get_backup(current_view)
			if(backup)
				//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
				var/datum/component/nanites/nanites = backup.nanites
				nanites.add_program(null, disk.program.copy())
	if(href_list["remove_program"])
		var/datum/nanite_cloud_backup/backup = get_backup(current_view)
		if(backup)
			//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
			var/nanite_program_name = href_list["remove_program"]
			var/datum/component/nanites/nanites = backup.nanites
			for(var/datum/nanite_program/program in nanites.programs)
				if(program.name == nanite_program_name)
					qdel(program)
			//var/datum/nanite_program/P = nanites.programs[nanite_program_id]
			//qdel(P)
	if(href_list["add_rule"])
		if(disk && disk.program && istype(disk.program, /datum/nanite_program/sensor))
			var/datum/nanite_program/sensor/rule_template = disk.program
			if(!rule_template.can_rule)
				return
			var/datum/nanite_cloud_backup/backup = get_backup(current_view)
			if(backup)
				//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
				var/datum/component/nanites/nanites = backup.nanites
				var/datum/nanite_program/P = nanites.programs[href_list["add_rule"]]
				rule_template.make_rule(P)
	if(href_list["remove_rule"])
		var/datum/nanite_cloud_backup/backup = get_backup(current_view)
		if(backup)
			//playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
			var/datum/component/nanites/nanites = backup.nanites
			var/datum/nanite_program/P = nanites.programs[href_list["remove_rule"]]
			var/datum/nanite_rule/rule = P.rules[href_list["rule_id"]]
			rule.remove()
	updateUsrDialog()

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

/*/Nanite Hijacker REMOVED WHY?
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
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NaniteProgrammer", "Internal Nanite Programmer")
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
*/
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
	var/current_category = ""
	var/categories = list("Utility Nanites",
						"Medical Nanites",
						"Sensor Nanites",
						"Augmentation Nanites",
						"Suppression Nanites",
						"Weaponized Nanites"
						)

/obj/machinery/nanite_program_hub/atom_init()
	. = ..()
	//TODO: isstationlevel????
	for(var/obj/machinery/computer/rdconsole/RD in RDcomputer_list)
		if(RD.id == 1)
			//Derelict have RDconsole with id = 1
			if(is_station_level(RD.z))
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

/obj/machinery/nanite_program_hub/proc/get_data()
	var/data = ""
	if(disk)
		data += "Program Disk: <A href='?src=\ref[src];eject=1'>Eject</A><br>"
		if(disk.program)
			var/datum/nanite_program/program = disk.program
			data += "Program Name: [program.name]<br>"
			data += "Description: [program.desc]<br>"
			data += "<A href='?src=\ref[src];clear=1'>Delete Program</A><br>"
		else
			data += "No Program Installed<br>"
	else
		data += "Insert a nanite program disk<br>"
		return data
	data += "<hr>"
	data += "Programs Hub<br>"
	data += "<hr>"
	data += "<A href='?src=\ref[src];category=1'>[current_category ? current_category : "Main Menu"]</A><br>"
	if(current_category != null)
		var/list/program_list = list()
		for(var/datum/design/nanites/D in linked_techweb.known_designs)
			if(!istype(D))
				continue
			if(current_category in D.category)
				program_list[D.name] = D
		for(var/program_name in program_list)
			data += "[program_name]<br>"
		data += "<hr>"
		if(program_list.len)
			data += "<A href='?src=\ref[src];download=1'>Download Program</A><br>"
	return data

/obj/machinery/nanite_program_hub/ui_interact(mob/user)
	var/data = get_data()
	popup(user, data, name)

/obj/machinery/nanite_program_hub/Topic(href, href_list)
	..()
	if(href_list["eject"])
		eject(usr)
	if(href_list["download"])
		if(!disk)
			return
		var/list/program_list = list()
		for(var/datum/design/nanites/D in linked_techweb.known_designs)
			if(!istype(D))
				continue
			if(current_category in D.category)
				program_list[D.name] = D
		var/new_prog = input(usr, "Choose program for download", "Program Hub") as null|anything in program_list + "Cancel"
		if(new_prog && new_prog != "Cancel")
			var/datum/design/nanites/downloaded = program_list[new_prog]
			if(!istype(downloaded))
				return
			if(disk.program)
				qdel(disk.program)
			disk.program = new downloaded.program_type
			disk.name = "[initial(disk.name)] \[[disk.program.name]\]"
			//playsound(src, 'sound/machines/terminal_prompt.ogg', 25, 0)
	if(href_list["category"])
		var/new_category = input(usr, "Choose category of program", "Select Type") as null|anything in categories + "Cancel"
		if(!new_category || new_category == "Cancel")
			new_category = "Main Menu"
		current_category = new_category
	if(href_list["clear"])
		if(disk && disk.program)
			qdel(disk.program)
			disk.program = null
			disk.name = initial(disk.name)
	updateUsrDialog()

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
		return
	return ..()

/obj/machinery/nanite_programmer/proc/eject(mob/living/user)
	if(!disk)
		return
	if(!istype(user) || !Adjacent(user) || !user.put_in_active_hand(disk))
		disk.forceMove(loc)
	disk = null
	program = null

/obj/machinery/nanite_programmer/proc/get_data()
	var/data = ""

	if(!istype(disk))
		data += "Insert a nanite program disk"
		return data
	if(!istype(program))
		data += "Blank Disk. Insert disk with downloaded program<br><hr>"
		data += "<A href='?src=\ref[src];eject=1'>Eject</A>"
		return data

	data += "[program.name] <A href='?src=\ref[src];eject=1'>Eject</A><br><hr>"
	data += "Info:<br><hr>"
	data += "[program.desc]<br>"
	data += "Use Rate: [program.use_rate]<br>"
	var/is_can_be_triggered = program.can_trigger
	if(is_can_be_triggered)
		data += "Trigger Cost: [program.trigger_cost]<br>"
		data += "Trigger Cooldown: [program.trigger_cooldown / 10]<br>"
	data += "<hr>"
	data += "Settings <A href='?src=\ref[src];toggle_active=1'>[program.activated ? "<span class='green'>Active</span>" : "<span class='red'>Inactive</span>"]</A><br><hr>"
	data += "Activation: <A href='?src=\ref[src];set_code=activation'>[program.activation_code]</A><br>"
	data += "Deactivation: <A href='?src=\ref[src];set_code=deactivation'>[program.deactivation_code]</A><br>"
	data += "Kill: <A href='?src=\ref[src];set_code=kill'>[program.kill_code]</A><br>"
	data += "Restart timer: <A href='?src=\ref[src];set_restart_timer=1'>[program.timer_restart / 10]</A><br>"
	data += "Shutdown timer: <A href='?src=\ref[src];set_shutdown_timer=1'>[program.timer_shutdown / 10]</A><br>"
	if(is_can_be_triggered)
		data += "Trigger: <A href='?src=\ref[src];set_code=trigger'>[program.trigger_code]</A><br>"
		data += "Trigger Repeat Timer: <A href='?src=\ref[src];set_trigger_timer=1'>[program.timer_trigger / 10]</A><br>"
		data += "Trigger Delay: <A href='?src=\ref[src];set_timer_trigger_delay=1'>[program.timer_trigger_delay / 10]</A><br>"

	var/list/extra_settings = program.get_extra_settings_frontend()
	for(var/setting in extra_settings)
		switch(setting["type"])
			if(NESTYPE_TEXT)
				data += "[setting["name"]]: <A href='?src=\ref[src];set_extra_setting=text'>[setting["value"] ? setting["value"] : "None"]</A><br>"
			if(NESTYPE_NUMBER)
				data += "[setting["name"]]: <A href='?src=\ref[src];set_extra_setting=number'>[setting["value"] ? setting["value"] : 1]</A> [setting["unit"] ? setting["unit"] : ""]<br>"
			if(NESTYPE_BOOLEAN)
				data += "[setting["name"]]: <A href='?src=\ref[src];set_extra_setting=bool'>[setting["value"] ? setting["true_text"] : setting["false_text"]]</A><br>"
			if(NESTYPE_TYPE)
				data += "[setting["name"]]: <A href='?src=\ref[src];set_extra_setting=type'>[setting["value"] ? setting["value"] : "None"]</A><br>"
	return data

/obj/machinery/nanite_programmer/ui_interact(mob/user)
	var/data = get_data()
	popup(user, data, name)

/obj/machinery/nanite_programmer/Topic(href, href_list)
	..()
	if(href_list["eject"])
		eject(usr)
	if(href_list["toggle_active"])
		playsound(src, "terminal_type", 25, 0)
		program.activated = !program.activated //we don't use the activation procs since we aren't in a mob
	if(href_list["set_code"])
		var/new_code = input("Set code (0000-9999):", name, null) as null|num
		if(!isnull(new_code))
			playsound(src, "terminal_type", 25, FALSE)
			new_code = clamp(round(new_code, 1),0,9999)
			switch(href_list["set_code"])
				if("activation")
					program.activation_code = clamp(round(new_code, 1),0,9999)
				if("deactivation")
					program.deactivation_code = clamp(round(new_code, 1),0,9999)
				if("kill")
					program.kill_code = clamp(round(new_code, 1),0,9999)
				if("trigger")
					program.trigger_code = clamp(round(new_code, 1),0,9999)
	if(href_list["set_extra_setting"])
		switch(href_list["set_extra_setting"])
			if("text")
				var/list/extra_settings = program.get_extra_settings_frontend()
				for(var/setting in extra_settings)
					if(setting["type"] == NESTYPE_TEXT)
						var/input_text = input(usr, "Set extra setting's text:", name, null) as anything
						program.set_extra_setting(setting["name"], input_text)
			if("number")
				var/list/extra_settings = program.get_extra_settings_frontend()
				for(var/setting in extra_settings)
					if(setting["type"] == NESTYPE_NUMBER)
						var/number = input(usr, "Set number in seconds ([setting["min"]]-[setting["max"]]):", name, 0) as null|num
						var/clamp_number = clamp(number, setting["min"], setting["max"])
						program.set_extra_setting(setting["name"], clamp_number)
			if("bool")
				var/list/extra_settings = program.get_extra_settings_frontend()
				for(var/setting in extra_settings)
					if(setting["type"] == NESTYPE_BOOLEAN)
						program.set_extra_setting(setting["name"], !setting["value"])
			if("type")
				var/list/extra_settings = program.get_extra_settings_frontend()
				for(var/setting in extra_settings)
					if(setting["type"] == NESTYPE_TYPE)
						var/new_type = input(usr, "Choose new type", "Select Type") as null|anything in setting["types"] + "Cancel"
						if(new_type && new_type != "Cancel")
							program.set_extra_setting(setting["name"], new_type)
		playsound(src, "terminal_type", 25, 0)
	if(href_list["set_restart_timer"])
		var/timer = input("Set restart timer in seconds (0-3600):", name, program.timer_restart / 10) as null|num
		if(!isnull(timer))
			playsound(src, "terminal_type", 25, 0)
			timer = clamp(round(timer, 1), 0, 3600)
			timer *= 10 //convert to deciseconds
			program.timer_restart = timer
	if(href_list["set_shutdown_timer"])
		var/timer = input("Set shutdown timer in seconds (0-3600):", name, program.timer_shutdown / 10) as null|num
		if(!isnull(timer))
			playsound(src, "terminal_type", 25, 0)
			timer = clamp(round(timer, 1), 0, 3600)
			timer *= 10 //convert to deciseconds
			program.timer_shutdown = timer
	if(href_list["set_trigger_timer"])
		var/timer = input("Set trigger repeat timer in seconds (0-3600):", name, program.timer_trigger / 10) as null|num
		if(!isnull(timer))
			playsound(src, "terminal_type", 25, FALSE)
			timer = clamp(round(timer, 1), 0, 3600)
			timer *= 10 //convert to deciseconds
			program.timer_trigger = timer
	if(href_list["set_timer_trigger_delay"])
		var/timer = input("Set trigger delay in seconds (0-3600):", name, program.timer_trigger_delay / 10) as null|num
		if(!isnull(timer))
			playsound(src, "terminal_type", 25, FALSE)
			timer = clamp(round(timer, 1), 0, 3600)
			timer *= 10 //convert to deciseconds
			program.timer_trigger_delay = timer
	updateUsrDialog()

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
