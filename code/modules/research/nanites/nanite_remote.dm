#define REMOTE_MODE_OFF "Off"
#define REMOTE_MODE_SELF "Local"
#define REMOTE_MODE_TARGET "Targeted"
#define REMOTE_MODE_AOE "Area"
#define REMOTE_MODE_RELAY "Relay"

/obj/item/nanite_remote
	name = "nanite remote control"
	desc = "A device that can remotely control active nanites through wireless signals."
	w_class = SIZE_SMALL
	req_access = list(access_robotics)
	icon = 'icons/obj/device.dmi'
	icon_state = "nanite_remote"
	flags = NOBLUDGEON
	var/locked = FALSE //Can be locked, so it can be given to users with a set code and mode
	var/mode = REMOTE_MODE_OFF
	var/code = 0
	var/relay_code = 0
	var/emagged = FALSE
	var/current_program_name = "Program"

/obj/item/nanite_remote/examine(mob/user)
	. = ..()
	if(locked)
		to_chat(user, "<span class='notice'>It is locked.</span>")

/obj/item/nanite_remote/emag_act(mob/user)
	if(emagged)
		return
	to_chat(user, "<span class='warning'>You override [src]'s ID lock.</span>")
	emagged = TRUE
	if(locked)
		locked = FALSE
		update_icon()

/obj/item/nanite_remote/update_icon()
	. = ..()
	cut_overlays()
	if(locked)
		add_overlay("nanite_remote_locked")

/obj/item/nanite_remote/afterattack(atom/target, mob/user)
	user.SetNextMove(CLICK_CD_MELEE)
	switch(mode)
		if(REMOTE_MODE_OFF)
			return
		if(REMOTE_MODE_SELF)
			to_chat(user, "<span class='notice'>You activate [src], signaling the nanites in your bloodstream.<span>")
			signal_mob(user, code, key_name(user))
		if(REMOTE_MODE_TARGET)
			if(isliving(target) && (get_dist(target, get_turf(src)) <= 7))
				to_chat(user, "<span class='notice'>You activate [src], signaling the nanites inside [target].<span>")
				signal_mob(target, code, key_name(user))
		if(REMOTE_MODE_AOE)
			to_chat(user, "<span class='notice'>You activate [src], signaling the nanites inside every host around you.<span>")
			for(var/mob/living/L in view(user, 7))
				signal_mob(L, code, key_name(user))
		if(REMOTE_MODE_RELAY)
			to_chat(user, "<span class='notice'>You activate [src], signaling all connected relay nanites.<span>")
			signal_relay(code, relay_code, key_name(user))

/obj/item/nanite_remote/proc/signal_mob(mob/living/M, code, source)
	SEND_SIGNAL(M, COMSIG_NANITE_SIGNAL, code, source)

/obj/item/nanite_remote/proc/signal_relay(code, relay_code, source)
	for(var/datum/nanite_program/relay/N in SSnanites.nanite_relays)
		N.relay_signal(code, relay_code, source)

/obj/item/nanite_remote/proc/unlock_act(mob/user)
	if(allowed(user))
		to_chat(user, "<span class='notice'>You unlock [src].</span>")
		locked = FALSE
		update_icon()
	else
		to_chat(user, "<span class='warning'>Access denied.</span>")

/obj/item/nanite_remote/proc/get_data()
	var/data = ""
	data += "Lock: [locked ? "Engaged" : "Disengaged"] [locked ? "<A href='?src=\ref[src];unlock=1'>Unlock</A>" : "<A href='?src=\ref[src];lock=1'>Lock</A>"]<br>\n"
	if(!locked)
		data += "Code: <A href='?src=\ref[src];set_code=1'>[code]</A><br>\n"
		data += "Relay Code: <A href='?src=\ref[src];set_relay_code=1'>[relay_code]</A><br>\n"
		data += "Selected Mode: <A href='?src=\ref[src];select_mode=1'>[mode]</A><br>\n"
		data += "Name: <A href='?src=\ref[src];update_name=1'>[current_program_name]</A><br>\n"
	return data

/obj/item/nanite_remote/ui_interact(mob/user)
	var/data = get_data()
	popup(user, data, name)
	user.set_machine(src)

/obj/item/nanite_remote/Topic(href, href_list)
	..()
	if(!locked)
		if(href_list["set_code"])
			var/new_code = input("Set code (0000-9999):", name, code) as null|num
			if(!isnull(new_code))
				new_code = clamp(round(new_code, 1),0,9999)
				code = new_code
			updateSelfDialog()
		if(href_list["set_relay_code"])
			var/new_code = input("Set relay code (0000-9999):", name, code) as null|num
			if(!isnull(new_code))
				new_code = clamp(round(new_code, 1),0,9999)
				relay_code = new_code
			updateSelfDialog()
		if(href_list["update_name"])
			var/user_input = sanitize_safe(input("Enter a name for program", "Program Name", input_default(current_program_name)) as text)
			if(!isnull(user_input))
				current_program_name = user_input
			updateSelfDialog()
		if(href_list["select_mode"])
			var/changing_mode = tgui_alert(usr, "Select New Mode", "Set New Mode", list(REMOTE_MODE_OFF, REMOTE_MODE_SELF, REMOTE_MODE_TARGET, REMOTE_MODE_AOE, REMOTE_MODE_RELAY))
			if(changing_mode && changing_mode != mode)
				mode = changing_mode
			updateSelfDialog()
		if(href_list["lock"])
			if(!emagged)
				locked = TRUE
			update_icon()
			updateSelfDialog()
	if(href_list["unlock"])
		unlock_act(usr)
		updateSelfDialog()

/obj/item/nanite_remote/attack_self(mob/user)
	ui_interact(user)

/obj/item/nanite_remote/comm
	name = "nanite communication remote"
	desc = "A device that can send text messages to specific programs."
	icon_state = "nanite_comm_remote"
	var/comm_message = ""

/obj/item/nanite_remote/comm/afterattack(atom/target, mob/user)
	switch(mode)
		if(REMOTE_MODE_OFF)
			return
		if(REMOTE_MODE_SELF)
			to_chat(user, "<span class='notice'>You activate [src], signaling the nanites in your bloodstream.<span>")
			signal_mob(user, code, comm_message)
		if(REMOTE_MODE_TARGET)
			if(isliving(target) && (get_dist(target, get_turf(src)) <= 7))
				to_chat(user, "<span class='notice'>You activate [src], signaling the nanites inside [target].<span>")
				signal_mob(target, code, comm_message, key_name(user))
		if(REMOTE_MODE_AOE)
			to_chat(user, "<span class='notice'>You activate [src], signaling the nanites inside every host around you.<span>")
			for(var/mob/living/L in view(user, 7))
				signal_mob(L, code, comm_message, key_name(user))
		if(REMOTE_MODE_RELAY)
			to_chat(user, "<span class='notice'>You activate [src], signaling all connected relay nanites.<span>")
			signal_relay(code, relay_code, comm_message, key_name(user))

/obj/item/nanite_remote/comm/signal_mob(mob/living/M, code, source)
	SEND_SIGNAL(M, COMSIG_NANITE_COMM_SIGNAL, code, comm_message)

/obj/item/nanite_remote/comm/signal_relay(code, relay_code, source)
	for(var/X in SSnanites.nanite_relays)
		var/datum/nanite_program/relay/N = X
		N.relay_comm_signal(code, relay_code, comm_message)

/obj/item/nanite_remote/comm/get_data()
	var/data = ..()
	data += "Message is <A href='?src=\ref[src];set_message=1'>[comm_message ? comm_message : "None"]</A><br>\n"
	return data

/obj/item/nanite_remote/comm/Topic(href, href_list)
	..()
	if(!locked)
		if(href_list["set_message"])
			var/new_message = input("Enter new message", "Message", "") as text|null
			if(new_message)
				comm_message = new_message
			updateSelfDialog()

#undef REMOTE_MODE_OFF
#undef REMOTE_MODE_SELF
#undef REMOTE_MODE_TARGET
#undef REMOTE_MODE_AOE
#undef REMOTE_MODE_RELAY
