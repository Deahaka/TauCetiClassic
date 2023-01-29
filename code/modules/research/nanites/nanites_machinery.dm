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
	board_type = "machine"
	req_components = list(
		/obj/item/weapon/stock_parts/scanning_module = 2,
		/obj/item/weapon/stock_parts/micro_laser = 2,
		/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/public_nanite_chamber
	name = "Public Nanite Chamber (Machine Board)"
	build_path = /obj/machinery/public_nanite_chamber
	board_type = "machine"
	var/cloud_id = 1
	req_components = list(/obj/item/weapon/stock_parts/micro_laser = 2,
						/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/public_nanite_chamber/examine(mob/user)
	. = ..()
	to_chat(user, "Cloud ID is currently set to [cloud_id].")

/obj/item/weapon/circuitboard/nanite_program_hub
	name = "Nanite Program Hub (Machine Board)"
	build_path = /obj/machinery/nanite_program_hub
	board_type = "machine"
	req_components = list(
		/obj/item/weapon/stock_parts/matter_bin = 1,
		/obj/item/weapon/stock_parts/manipulator = 1)

/obj/item/weapon/circuitboard/nanite_programmer
	name = "Nanite Programmer (Machine Board)"
	build_path = /obj/machinery/nanite_programmer
	board_type = "machine"
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
	layer = ABOVE_WINDOW_LAYER
	var/obj/machinery/computer/nanite_chamber_control/console
	var/locked = FALSE
	var/breakout_time = 1200
	var/scan_level = 0
	var/busy = FALSE
	var/busy_icon_state
	var/busy_message
	var/message_cooldown = 0

/obj/machinery/nanite_chamber/atom_init()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/weapon/circuitboard/nanite_chamber(null)
	component_parts += new /obj/item/weapon/stock_parts/scanning_module(null)
	component_parts += new /obj/item/weapon/stock_parts/scanning_module(null)
	component_parts += new /obj/item/weapon/stock_parts/micro_laser(null)
	component_parts += new /obj/item/weapon/stock_parts/micro_laser(null)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(null)
	RefreshParts()

/obj/machinery/nanite_chamber/RefreshParts()
	scan_level = 0
	for(var/obj/item/weapon/stock_parts/scanning_module/P in component_parts)
		scan_level += P.rating

/obj/machinery/nanite_chamber/examine(mob/user)
	. = ..()
	if(isobserver(user))
		to_chat(user, "<span_class='notice'>The status display reads: Scanning module has been upgraded to level <b>[scan_level]</b>.</span")

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

/obj/machinery/nanite_chamber/relaymove(mob/living/user, direction)
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
	if(close_machine(target))
		add_fingerprint(user)

//Nanite Chamber Computer
/obj/machinery/computer/nanite_chamber_control
	name = "nanite chamber control console"
	desc = "Controls a connected nanite chamber. Can inoculate nanites, load programs, and analyze existing nanite swarms."
	icon_state = "nanite_chamber_control"
	circuit = /obj/item/weapon/circuitboard/nanite_chamber_control
	var/obj/machinery/nanite_chamber/chamber
	var/obj/item/disk/nanite_program/disk
	var/detail_menu_view = "None"

/obj/machinery/computer/nanite_chamber_control/atom_init()
	. = ..()
	find_chamber()

/obj/machinery/computer/nanite_chamber_control/proc/find_chamber()
	for(var/direction in global.cardinal)
		var/C = locate(/obj/machinery/nanite_chamber, get_step(src, direction))
		if(C)
			var/obj/machinery/nanite_chamber/NC = C
			NC.console = src
			set_connected_chamber(NC)

/obj/machinery/computer/nanite_chamber_control/interact()
	if(!chamber)
		find_chamber()
	..()

//TODO: show programs
/obj/machinery/computer/nanite_chamber_control/proc/get_data()
	var/data = ""
	if(!chamber)
		data += "No chamber detected<br>"
		data += "<A href='?src=\ref[src];connect_chamber=1'>Try Connect Chamber</A><br>"
		return data
	if(!chamber.occupant)
		data += "No occupant detected<br>"
		data += "<A href='?src=\ref[src];connect_chamber=1'>Try Connect Chamber</A><br>"
		return data
	if(issilicon(chamber.occupant))
		data += "Occupant not compatible with nanites."
		return data
	if(ishuman(chamber.occupant))
		var/mob/living/carbon/human/H = chamber.occupant
		if(H.species)
			if(H.species.flags[NO_BLOOD])
				data += "Occupant not compatible with nanites."
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
		data += "<table border='1' width='100%'>"
		data += "<tr><th width = '45%'>Status</th><td width='55%'><div align='right'><A href='?src=\ref[src];remove_nanites=1'><span class='red'>Destroy Nanites</span></A></div></th></tr>"
		data += "<tr>"
		data += "<td width = '45%'>"
		data += "Nanite Volume: [data_handler.nanite_volume]<br>"
		data += "Grown Rate: [data_handler.regen_rate]<br>"
		data += "Synchronization: [data_handler.cloud_active ? "Actived" : "Deactivated"]<br>"
		data += "</td>"
		data += "<td width='55%'>"
		data += "Current Safety Treshold: <A href='?src=\ref[src];set_safety=1'>[data_handler.safety_threshold]</A><br>"
		data += "Cloud ID: <A href='?src=\ref[src];set_cloud=1'>[data_handler.cloud_id]</A><br>"
		data += "</td>"
		data += "</tr>"
		data += "</table>"
		data += "<br>"
		data += "Programs:<hr>"
		for(var/datum/nanite_program/P in data_handler.programs)
			data += "<A href='?src=\ref[src];details=[P.name]'>[P.name]</A><br>"
			if(detail_menu_view == P.name)
				data += "<table border='1' width='100%'>"
				data += "<tr><th width = '60%'>Description</th><td width='40%'>Nanite Volume</th></tr>"
				data += "<tr>"
				data += "<td width = '60%'>[P.desc]</td>"
				data += "<td width='40%'>"
				data += "Status: [P.activated ? "<span class='green'>Active</span>" : "<span class='red'>Inactive</span>"]<br>"
				data += "Nanite Consumed: [P.use_rate]/s<br>"
				data += "</td>"
				data += "</tr>"
				data += "</table>"
				if(scan_lvl >= 2)
					if(P.can_trigger)
						data += "<hr>"
						data += "Triggers:<br>"
						data += "<dd>"
						data += "Trigger Cost: [P.trigger_cost]<br>"
						data += "Trigger Cooldown: [P.trigger_cooldown / 10]<br>"
						if(P.timer_trigger)
							data += "Trigger Repeat Timer: [P.timer_trigger / 10]/s<br>"
						if(P.timer_trigger_delay)
							data += "Trigger Delay: [P.timer_trigger_delay / 10]/s<br>"
						data += "</dd>"
					if(P.timer_restart)
						data += "Timer Restart: [P.timer_restart / 10]/s<br>"
					if(P.timer_shutdown)
						data += "Timer Shutdown: [P.timer_shutdown / 10]/s<br>"
					if(scan_lvl >= 3)
						var/list/extra_detail_settings = P.get_extra_settings_frontend()
						if(extra_detail_settings.len)
							data += "<hr>"
							data += "Extra Settings:<br>"
							for(var/setting in extra_detail_settings)
								switch(setting["type"])
									if(NESTYPE_TEXT)
										data += "--- [setting["name"]]: [setting["value"] ? setting["value"] : "None"]<br>"
									if(NESTYPE_NUMBER)
										data += "--- [setting["name"]]: [setting["value"] ? setting["value"] : 1] [setting["unit"] ? setting["unit"] : ""]<br>"
									if(NESTYPE_BOOLEAN)
										data += "--- [setting["name"]]: [setting["value"] ? setting["true_text"] : setting["false_text"]]<br>"
									if(NESTYPE_TYPE)
										data += "--- [setting["name"]]: [setting["value"] ? setting["value"] : "None"]<br>"
						if(scan_lvl >= 4)
							data += "<hr>"
							data += "<table border='1' width='100%'>"
							data += "<tr><th width = '50%'>Codes</th><td width='50%'>Rules</th></tr>"
							data += "<tr>"
							data += "<td width = '50%'>"
							data += "Activation: [P.activation_code]<br>"
							data += "Deactivation: [P.deactivation_code]<br>"
							data += "Kill: [P.kill_code]<br>"
							if(P.can_trigger)
								data += "Trigger: [P.trigger_code]<br>"
							data += "</td>"
							data += "<td width='50%'>"
							var/list/rules = list()
							var/rule_id = 1
							for(var/datum/nanite_rule/nanite_rule in P.rules)
								var/list/rule = list()
								rule["display"] = nanite_rule.display()
								rule["id"] = rule_id
								rules += list(rule)
								rule_id++
							if(rules.len)
								for(var/my_rule in rules)
									data += "[my_rule["id"]]. [my_rule["display"]]<br>"
							else
								data += "No Active Rules<br>"
							data += "</td>"
							data += "</tr>"
							data += "</table>"
	else
		data += "No nanites detected.<br>"
		data += "<hr><A href='?src=\ref[src];nanite_injection=1'><span class='green'>Inject Nanites</span></A>"

	return data

/obj/machinery/computer/nanite_chamber_control/ui_interact(mob/user)
	if(chamber)
		chamber.RefreshParts()
	var/data = get_data()
	popup(user, data, name)

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
	if(href_list["details"])
		if(detail_menu_view == href_list["details"])
			detail_menu_view = "None"
		else
			detail_menu_view = href_list["details"]
	updateUsrDialog()

/obj/machinery/computer/nanite_chamber_control/proc/set_connected_chamber(new_chamber)
	if(chamber)
		UnregisterSignal(chamber, COMSIG_PARENT_QDELETING)
	chamber = new_chamber
	if(chamber)
		RegisterSignal(chamber, COMSIG_PARENT_QDELETING, .proc/react_to_chamber_del)

/obj/machinery/computer/nanite_chamber_control/proc/react_to_chamber_del(datum/source)
	SIGNAL_HANDLER
	set_connected_chamber(null)

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
	var/detail_menu_view = "None"

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
	var/disk_program_can_rule = FALSE
	if(has_disk)
		data += "Program disk: <A href='?src=\ref[src];eject=1'>Eject</A><br>"
		data += "<A href='?src=\ref[src];details=Disk'>Details</A><br>"
		if(disk.program)
			has_program = TRUE
			var/datum/nanite_program/disk_program = disk.program
			var/is_can_be_triggered = disk_program.can_trigger
			var/list/list_of_extra_settings = disk_program.get_extra_settings_frontend()
			if(list_of_extra_settings.len)
				if(istype(disk_program, /datum/nanite_program/sensor))
					var/datum/nanite_program/sensor/sensor = disk_program
					if(sensor.can_rule)
						disk_program_can_rule = TRUE
			if(detail_menu_view == "Disk")
				data += "<hr>"
				data += "[disk_program.name] [disk_program.activated ? "<span class='green'>Activated</span>" : "<span class='red'>Deactivated</span>"]<br>"
				data += "<hr>"

				data += "<table border='1' width='100%'>"
				data += "<tr><th width = '60%'>Description</th><td width='40%'>Nanite Volume</th></tr>"
				data += "<tr>"
				data += "<td width = '60%'>[disk_program.desc]</td>"
				data += "<td width='40%'>"
				data += "<div align='left'>"
				data += "Use Rate: [disk_program.use_rate]<br>"
				if(is_can_be_triggered)
					data += "Trigger Cost: [disk_program.trigger_cost]<br>"
					data += "Trigger Cooldown: [disk_program.trigger_cooldown / 10]<br>"
				data += "<div>"
				data += "</td>"
				data += "</tr>"
				data += "</table>"

				data += "<hr>"

				data += "<table border='1' width='100%'>"
				data += "<tr><th width = '50%'>Codes</th><td width='50%'>Delays</th></tr>"
				data += "<tr>"
				data += "<td width = '50%'>"
				data += "Activation: [disk_program.activation_code]<br>"
				data += "Deactivation: [disk_program.deactivation_code]<br>"
				data += "Kill: [disk_program.kill_code]<br>"
				data += "</td>"
				data += "<td width='50%'>"
				data += "Restart: [disk_program.timer_restart / 10]<br>"
				data += "Shutdown [disk_program.timer_shutdown / 10]<br>"
				data += "</td>"
				data += "</tr>"
				if(is_can_be_triggered)
					data += "<tr>"
					data += "<td width = '50%'>"
					data += "Trigger: [disk_program.trigger_code]<br>"
					data += "</td>"
					data += "<td width='50%'>"
					data += "Trigger Repeat Timer: [disk_program.timer_trigger / 10]<br>"
					data += "Trigger Delay: [disk_program.timer_trigger_delay / 10]<br>"
					data += "</td>"
					data += "</tr>"
				data += "</table>"
				for(var/setting in list_of_extra_settings)
					switch(setting["type"])
						if(NESTYPE_TEXT)
							data += "[setting["name"]]: [setting["value"] ? setting["value"] : "None"]<br>"
						if(NESTYPE_NUMBER)
							data += "[setting["name"]]: [setting["value"] ? setting["value"] : 1] [setting["unit"] ? setting["unit"] : ""]<br>"
						if(NESTYPE_BOOLEAN)
							data += "[setting["name"]]: [setting["value"] ? setting["true_text"] : setting["false_text"]]<br>"
						if(NESTYPE_TYPE)
							data += "[setting["name"]]: [setting["value"] ? setting["value"] : "None"]<br>"
		else
			data += "Inserted disk has no program<br>"
	//cant early return because there is 3 more buttons in menu
	else
		data += "No disk inserted<br>"

	if(current_view)
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
					rules += list(rule)
					rule_id++
				cloud_program["rules"] = rules
				if(rules.len)
					cloud_program["program_have_rules"] = TRUE
				var/list/extra_settings = P.get_extra_settings_frontend()
				cloud_program["extra_settings"] = extra_settings
				if(extra_settings.len)
					cloud_program["has_extra_settings"] = TRUE
				id++
				cloud_programs += list(cloud_program)
			data += "<hr>"
			data += "<h1 align='left'>Backup # [current_view] <A href='?src=\ref[src];return_view=1'>Return</A></h1><br>"
			if(cloud_programs.len)
				data += "<dd>"
				for(var/associative_program_list in cloud_programs)
					data += "[associative_program_list["id"]]. <A href='?src=\ref[src];details=[associative_program_list["name"]]'>[associative_program_list["name"]]</A> <A href='?src=\ref[src];remove_program=[associative_program_list["id"]]'>—</A> [associative_program_list["activated"] ? "<span class='green'>Activated</span>" : "<span class='red'>Deactivated</span>"]<br>"
					if(detail_menu_view == associative_program_list["name"])
						data += "<table border='1' width='100%'>"
						data += "<tr><th width = '60%'>Description</th><td width='40%'>Nanite Volume</th></tr>"
						data += "<tr>"
						data += "<td width = '60%'>[associative_program_list["desc"]]</td>"
						data += "<td width='40%'>"
						data += "<div align='left'>"
						data += "Use Rate: [associative_program_list["use_rate"]]<br>"
						if(associative_program_list["can_trigger"])
							data += "Trigger Cost: [associative_program_list["trigger_cost"]]<br>"
							data += "Trigger Cooldown: [associative_program_list["trigger_cooldown"]]<br>"
						data += "<div>"
						data += "</td>"
						data += "</tr>"
						data += "</table>"

						data += "<hr>"

						data += "<table border='1' width='100%'>"
						data += "<tr><th width = '50%'>Codes</th><td width='50%'>Delays</th></tr>"
						data += "<tr>"
						data += "<td width = '50%'>"
						data += "Activation: [associative_program_list["activation_code"]]<br>"
						data += "Deactivation: [associative_program_list["deactivation_code"]]<br>"
						data += "Kill: [associative_program_list["kill_code"]]<br>"
						data += "</td>"
						data += "<td width='50%'>"
						data += "Restart: [associative_program_list["timer_restart"]]<br>"
						data += "Shutdown [associative_program_list["timer_shutdown"]]<br>"
						data += "</td>"
						data += "</tr>"
						if(associative_program_list["can_trigger"])
							data += "<tr>"
							data += "<td width = '50%'>"
							data += "Trigger: [associative_program_list["trigger_code"]]<br>"
							data += "</td>"
							data += "<td width='50%'>"
							data += "Trigger Repeat Timer: [associative_program_list["timer_trigger"]]<br>"
							data += "Trigger Delay: [associative_program_list["timer_trigger_delay"]]<br>"
							data += "</td>"
							data += "</tr>"
						data += "</table>"
						data += "<hr>"
						if(associative_program_list["has_extra_settings"])
							data += "Extra Settings:<br>"
							var/list/extra_detail_settings = associative_program_list["extra_settings"]
							for(var/setting in extra_detail_settings)
								switch(setting["type"])
									if(NESTYPE_TEXT)
										data += "--- [setting["name"]]: [setting["value"] ? setting["value"] : "None"]<br>"
									if(NESTYPE_NUMBER)
										data += "--- [setting["name"]]: [setting["value"] ? setting["value"] : 1] [setting["unit"] ? setting["unit"] : ""]<br>"
									if(NESTYPE_BOOLEAN)
										data += "--- [setting["name"]]: [setting["value"] ? setting["true_text"] : setting["false_text"]]<br>"
									if(NESTYPE_TYPE)
										data += "--- [setting["name"]]: [setting["value"] ? setting["value"] : "None"]<br>"
							data += "<hr>"
					var/list/rules_list = associative_program_list["rules"]
					data += "Rules:<br>"
					if(associative_program_list["program_have_rules"])
						for(var/my_rule in rules_list)
							data += "--- [my_rule["display"]] <A href='?src=\ref[src];remove_rule=[associative_program_list["id"]];rule_id=[my_rule["id"]]'>—</A><br>"
					else
						data += "--- No Active Rules<br>"
					if(disk_program_can_rule)
						data += "<div align='right'><A href='?src=\ref[src];add_rule=[associative_program_list["id"]]'>Add Rule from Disk</A></div><br>"
					data += "<hr>"
				data += "</dd>"
			else
				data += "No cloud programs<br>"
			if(has_program)
				data += "<hr>"
				data += "<A href='?src=\ref[src];upload_program=1'>Upload Program from Disk</A><br>"
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
				data += "<center>Backup # <A href='?src=\ref[src];set_view=[backups["cloud_id"]]'>[backups["cloud_id"]]</A></center><br>"
		else
			data += "<center>No backups</center><br>"
	return data

/obj/machinery/computer/nanite_cloud_controller/ui_interact(mob/user)
	var/data = get_data()
	popup(user, data, name)

/obj/machinery/computer/nanite_cloud_controller/Topic(href, href_list)
	..()
	if(href_list["eject"])
		eject(usr)
	if(href_list["set_view"])
		if(!isnull(href_list["set_view"]))
			current_view = href_list["set_view"]
	//set_view=0 its ^^^ href_list["set_view"] = 0 and clause not working
	if(href_list["return_view"])
		current_view = 0
	if(href_list["update_new_backup_value"])
		var/backup_value = input("Set new ID for backup", name, null) as null|num
		if(!isnull(backup_value))
			new_backup_id = backup_value
	if(href_list["create_backup"])
		var/cloud_id = new_backup_id
		if(!isnull(cloud_id))
			cloud_id = clamp(round(cloud_id, 1),1,100)
			generate_backup(cloud_id, usr)
	if(href_list["delete_backup"])
		var/datum/nanite_cloud_backup/backup = get_backup(current_view)
		if(backup)
			qdel(backup)
	if(href_list["upload_program"])
		if(disk && disk.program)
			var/datum/nanite_cloud_backup/backup = get_backup(current_view)
			if(backup)
				var/datum/component/nanites/nanites = backup.nanites
				nanites.add_program(null, disk.program.copy())
	if(href_list["remove_program"])
		var/datum/nanite_cloud_backup/backup = get_backup(current_view)
		if(backup)
			var/nanite_program_id = text2num(href_list["remove_program"])
			var/datum/component/nanites/nanites = backup.nanites
			var/datum/nanite_program/P = nanites.programs[nanite_program_id]
			qdel(P)
	if(href_list["add_rule"])
		if(disk && disk.program && istype(disk.program, /datum/nanite_program/sensor))
			var/datum/nanite_program/sensor/rule_template = disk.program
			if(!rule_template.can_rule)
				return
			var/datum/nanite_cloud_backup/backup = get_backup(current_view)
			if(backup)
				var/datum/component/nanites/nanites = backup.nanites
				var/num = text2num(href_list["add_rule"])
				var/datum/nanite_program/P = nanites.programs[num]
				rule_template.make_rule(P)
	if(href_list["remove_rule"])
		var/datum/nanite_cloud_backup/backup = get_backup(current_view)
		if(backup)
			var/datum/component/nanites/nanites = backup.nanites
			var/num_P = text2num(href_list["remove_rule"])
			var/datum/nanite_program/P = nanites.programs[num_P]
			var/num_R = text2num(href_list["rule_id"])
			var/datum/nanite_rule/rule = P.rules[num_R]
			rule.remove()
	if(href_list["details"])
		if(detail_menu_view == href_list["details"])
			detail_menu_view = "None"
		else
			detail_menu_view = href_list["details"]
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
	component_parts = list()
	component_parts += new /obj/item/weapon/circuitboard/nanite_program_hub(null)
	component_parts += new /obj/item/weapon/stock_parts/matter_bin(null)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(null)

	for(var/obj/machinery/computer/rdconsole/RD in RDcomputer_list)
		if(RD.id == DEFAULT_ROBOT_CONSOLE_ID)
			linked_techweb = RD.files

/obj/machinery/nanite_program_hub/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/disk/nanite_program))
		var/obj/item/disk/nanite_program/N = I
		if(disk)
			eject(user)
		if(user.drop_from_inventory(N, src))
			to_chat(user, "<span class='notice'>You insert [N] into [src]</span>")
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
	data += "<div align='center'>Programs Hub</div>"
	data += "<hr>"
	data += "<A href='?src=\ref[src];category=1'>[current_category ? current_category : "Main Menu"]</A><br>"
	if(current_category != null)
		data += "<dd>"
		var/list/program_list = list()
		for(var/datum/design/nanites/D in linked_techweb.known_designs)
			if(current_category in D.category)
				program_list[D.name] = D
		for(var/program_name in program_list)
			data += "[program_name]<br>"
		data += "</dd>"
		data += "<hr>"
		if(program_list.len)
			data += "<h1><A href='?src=\ref[src];download=1'>Download Program</A></h1><br>"
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
			if(current_category in D.category)
				program_list[D.name] = D
		var/new_prog = input(usr, "Choose program for download", "Program Hub") as null|anything in program_list + "Cancel"
		if(new_prog && new_prog != "Cancel")
			var/datum/design/nanites/downloaded = program_list[new_prog]
			if(!istype(downloaded))
				return
			QDEL_NULL(disk.program)
			disk.program = new downloaded.program_type
			disk.name = "[initial(disk.name)] \[[disk.program.name]\]"
	if(href_list["category"])
		var/new_category = input(usr, "Choose category of program", "Select Type") as null|anything in categories + "Cancel"
		if(!new_category || new_category == "Cancel")
			new_category = "Main Menu"
		current_category = new_category
	if(href_list["clear"])
		if(disk)
			QDEL_NULL(disk.program)
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

/obj/machinery/nanite_programmer/atom_init()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/weapon/circuitboard/nanite_programmer(null)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(null)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(null)
	component_parts += new /obj/item/weapon/stock_parts/micro_laser(null)
	component_parts += new /obj/item/weapon/stock_parts/micro_laser(null)
	component_parts += new /obj/item/weapon/stock_parts/scanning_module(null)

/obj/machinery/nanite_programmer/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/disk/nanite_program))
		var/obj/item/disk/nanite_program/N = I
		if(user.drop_from_inventory(N, src))
			if(disk)
				eject(user)
			to_chat(user, "<span class='notice'>You insert [N] into [src]</span>")
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

	data += "<h1><div align='center'>[program.name] <A href='?src=\ref[src];eject=1'>Eject</A></div></h1><hr>"
	data += "<div align='center'>Info:</div>"

	data += "<table border='1' width='100%'>"
	data += "<tr><th width = '60%'>Description</th><td width='40%'>Nanite Volume</th></tr>"
	data += "<tr>"
	data += "<td width = '60%'>[program.desc]</td>"
	data += "<td width='40%'>"
	data += "<div align='left'>"
	data += "Use Rate: [program.use_rate]<br>"
	var/is_can_be_triggered = program.can_trigger
	if(is_can_be_triggered)
		data += "Trigger Cost: [program.trigger_cost]<br>"
		data += "Trigger Cooldown: [program.trigger_cooldown / 10]<br>"
	data += "<div>"
	data += "</td>"
	data += "</tr>"
	data += "</table>"

	data += "<hr>"
	data += "Settings <A href='?src=\ref[src];toggle_active=1'>[program.activated ? "<span class='green'>Active</span>" : "<span class='red'>Inactive</span>"]</A><br><hr>"

	data += "<table border='1' width='100%'>"
	data += "<tr><th width = '40%'>Codes</th><td width='60%'>Delays</th></tr>"
	data += "<tr>"
	data += "<td width = '40%'>"
	data += "Activation: <A href='?src=\ref[src];set_code=activation'>[program.activation_code]</A><br>"
	data += "Deactivation: <A href='?src=\ref[src];set_code=deactivation'>[program.deactivation_code]</A><br>"
	data += "Kill: <A href='?src=\ref[src];set_code=kill'>[program.kill_code]</A><br>"
	data += "</td>"
	data += "<td width='60%'>"
	data += "Restart timer: <A href='?src=\ref[src];set_restart_timer=1'>[program.timer_restart / 10]</A><br>"
	data += "Shutdown timer: <A href='?src=\ref[src];set_shutdown_timer=1'>[program.timer_shutdown / 10]</A><br>"
	data += "</td>"
	data += "</tr>"
	if(is_can_be_triggered)
		data += "<tr>"
		data += "<td width = '35%'>"
		data += "Trigger: <A href='?src=\ref[src];set_code=trigger'>[program.trigger_code]</A><br>"
		data += "</td>"
		data += "<td width='65%'>"
		data += "Trigger Repeat Timer: <A href='?src=\ref[src];set_trigger_timer=1'>[program.timer_trigger / 10]</A><br>"
		data += "Trigger Delay: <A href='?src=\ref[src];set_timer_trigger_delay=1'>[program.timer_trigger_delay / 10]</A><br>"
		data += "</td>"
		data += "</tr>"
	data += "</table>"
	data += "<hr>"
	data += "Special:<br>"
	data += "<dd>"
	var/list/extra_settings = program.get_extra_settings_frontend()
	for(var/setting in extra_settings)
		switch(setting["type"])
			if(NESTYPE_TEXT)
				data += "[setting["name"]]: <A href='?src=\ref[src];set_extra_setting=[setting["name"]]'>[setting["value"] ? setting["value"] : "None"]</A><br>"
			if(NESTYPE_NUMBER)
				data += "[setting["name"]]: <A href='?src=\ref[src];set_extra_setting=[setting["name"]]'>[setting["value"] ? setting["value"] : 1]</A> [setting["unit"] ? setting["unit"] : ""]<br>"
			if(NESTYPE_BOOLEAN)
				data += "[setting["name"]]: <A href='?src=\ref[src];set_extra_setting=[setting["name"]]'>[setting["value"] ? setting["true_text"] : setting["false_text"]]</A><br>"
			if(NESTYPE_TYPE)
				data += "[setting["name"]]: <A href='?src=\ref[src];set_extra_setting=[setting["name"]]'>[setting["value"] ? setting["value"] : "None"]</A><br>"
	data += "</dd>"
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
		var/list/extra_settings = program.get_extra_settings_frontend()
		for(var/setting in extra_settings)
			if(href_list["set_extra_setting"] == setting["name"])
				switch(setting["type"])
					if(NESTYPE_TEXT)
						var/input_text = input(usr, "Set extra setting's text:", name, null) as anything
						program.set_extra_setting(setting["name"], input_text)
					if(NESTYPE_NUMBER)
						var/number = input(usr, "Set extra setting's number in seconds ([setting["min"]]-[setting["max"]]):", name, 0) as null|num
						var/clamp_number = clamp(number, setting["min"], setting["max"])
						program.set_extra_setting(setting["name"], clamp_number)
					if(NESTYPE_BOOLEAN)
						program.set_extra_setting(setting["name"], !setting["value"])
					if(NESTYPE_TYPE)
						var/new_type = input(usr, "Choose extra setting's new type", "Select Type") as null|anything in setting["types"] + "Cancel"
						if(new_type && new_type != "Cancel")
							program.set_extra_setting(setting["name"], new_type)
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

/obj/machinery/public_nanite_chamber/atom_init()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/weapon/circuitboard/public_nanite_chamber(null)
	component_parts += new /obj/item/weapon/stock_parts/micro_laser(null)
	component_parts += new /obj/item/weapon/stock_parts/micro_laser(null)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(null)

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
		if(SEND_SIGNAL(L, COMSIG_HAS_NANITES) & COMPONENT_NANITES_DETECTED)
			return
		if(issilicon(L))
			return
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(H.species)
				if(H.species.flags[NO_BLOOD])
					return
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
