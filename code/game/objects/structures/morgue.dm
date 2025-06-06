/* Morgue stuff
 * Contains:
 *		Morgue
 *		Morgue trays
 *		Creamatorium
 *		Creamatorium trays
 */

/*
 * Morgue
 */

/obj/structure/morgue
	name = "morgue"
	desc = "Used to keep bodies in untill someone fetches them."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "morgue1"
	dir = EAST
	density = TRUE
	anchored = TRUE

	var/obj/structure/m_tray/connected = null
	var/check_delay = 0
	var/beeper = TRUE // currently cooldown for sound is included with check_delay.
	var/emagged = FALSE

	max_integrity = 400
	resistance_flags = CAN_BE_HIT

/obj/structure/morgue/Destroy()
	QDEL_NULL(connected)
	return ..()

/obj/structure/morgue/examine(mob/user)
	..()
	to_chat(user, "<span class='notice'>The speaker is [beeper ? "enabled" : "disabled"]. Alt-click to toggle it.</span>")

/obj/structure/morgue/AltClick(mob/user)
	..()
	if(!CanUseTopic(user))
		return
	if(!user.IsAdvancedToolUser())
		to_chat(user, "<span class='warning'>You can not comprehend what to do with this.</span>")
		return
	beeper = !beeper
	to_chat(user, "<span class='notice'>You turn the speaker function [beeper ? "on" : "off"].</span>")

/obj/structure/morgue/proc/update()
	if (connected || emagged)
		STOP_PROCESSING(SSobj, src)
	else if (contents.len && !emagged)
		START_PROCESSING(SSobj, src)

/obj/structure/morgue/update_icon()
	if (connected)
		icon_state = "morgue0"
	else if (contents.len && !emagged)
		if (has_clonable_bodies())
			icon_state = "morgue4"
		else
			icon_state = "morgue2"
	else
		icon_state = "morgue1"

/obj/structure/morgue/ex_act(severity)
	switch(severity)
		if(EXPLODE_HEAVY)
			if(prob(50))
				return
		if(EXPLODE_LIGHT)
			if(prob(95))
				return

	for(var/atom/movable/A in src)
		A.forceMove(loc)
		switch(severity)
			if(EXPLODE_DEVASTATE)
				SSexplosions.high_mov_atom += A
			if(EXPLODE_HEAVY)
				SSexplosions.med_mov_atom += A
			if(EXPLODE_LIGHT)
				SSexplosions.low_mov_atom += A
	qdel(src)

/obj/structure/morgue/alter_health()
	return loc

/obj/structure/morgue/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/morgue/proc/has_clonable_bodies()
	var/list/compiled = recursive_mob_check(src, sight_check = FALSE, include_radio = FALSE) // Search for mobs in all contents.
	if(!length(compiled)) // No mobs?
		return FALSE

	for(var/mob/living/carbon/human/H in compiled)
		if(H.stat != DEAD || (NOCLONE in H.mutations) || HAS_TRAIT(H, TRAIT_INCOMPATIBLE_DNA) || !H.has_brain() || H.suiciding || !H.ckey || !H.mind)
			continue

		return TRUE
	return FALSE

/obj/structure/morgue/process()
	if(check_delay > world.time)
		return
	check_delay = world.time + 10 SECONDS

	if (!contents.len)
		update()
		return //nothing inside

	if (has_clonable_bodies())
		if(beeper)
			playsound(src, 'sound/weapons/guns/empty_alarm.ogg', VOL_EFFECTS_MASTER, null, FALSE)
		update_icon()
	else
		update()

/obj/structure/morgue/proc/close()
	if(!connected)
		return
	for(var/atom/movable/A in connected.loc)
		if(A.anchored)
			continue
		if(ismob(A))
			if(!isliving(A))
				continue
			var/mob/M = A
			M.instant_vision_update(1,src)
		A.loc = src
	playsound(src, 'sound/effects/roll.ogg', VOL_EFFECTS_MASTER, 10)
	playsound(src, 'sound/items/Deconstruct.ogg', VOL_EFFECTS_MASTER, 25)
	qdel(connected)
	connected = null
	update_icon()
	update()

/obj/structure/morgue/proc/move_contents(new_loc)
	for(var/atom/movable/A in src)
		A.forceMove(new_loc)
		if(ismob(A))
			var/mob/M = A
			M.instant_vision_update(0)

/obj/structure/morgue/proc/open()
	if (!connected)
		playsound(src, 'sound/items/Deconstruct.ogg', VOL_EFFECTS_MASTER, 25)
		playsound(src, 'sound/effects/roll.ogg', VOL_EFFECTS_MASTER, 10)
		connected = new /obj/structure/m_tray( loc )
		connected.Move(get_step(src, dir))
		connected.layer = BELOW_CONTAINERS_LAYER
		var/turf/T = get_step(src, dir)
		if (T.contents.Find(connected))
			connected.connected = src
			update_icon()
			move_contents(connected.loc)
			connected.icon_state = "morguet"
			connected.set_dir(dir)
		else
			qdel(connected)
			connected = null
		update()

/obj/structure/morgue/proc/toggle()
	if (connected)
		close()
	else
		open()

/obj/structure/morgue/attack_hand(mob/user)
	user.SetNextMove(CLICK_CD_INTERACT)
	toggle()
	add_fingerprint(user)
	return

/obj/structure/morgue/attackby(P, mob/user)
	if(istype(P, /obj/item/weapon/pen))
		var/t = sanitize_safe(input(user, "What would you like the label to be?", src.name, null)  as text, MAX_NAME_LEN)
		if (user.get_active_hand() != P)
			return
		if (!Adjacent(user))
			return
		add_fingerprint(user)

		if (t)
			src.name = text("Morgue- '[]'", t)
		else
			src.name = "Morgue"
	else
		..()

/obj/structure/morgue/deconstruct(disassembled)
	move_contents(loc)
	if(!(flags & NODECONSTRUCT))
		new /obj/item/stack/sheet/metal(loc, 5)
	..()

/obj/structure/morgue/emag_act(mob/user)
	if(emagged)
		return FALSE
	playsound(user, pick(SOUNDIN_SPARKS), VOL_EFFECTS_MASTER)
	to_chat(user, "<span class='warning'>You are overloading the body detection mechanism.</span>")
	emagged = TRUE
	update_icon()
	return TRUE

/obj/structure/morgue/relaymove(mob/user)
	if (user.incapacitated())
		return
	connected = new /obj/structure/m_tray( loc )
	step(connected, dir)
	connected.layer = BELOW_CONTAINERS_LAYER
	var/turf/T = get_step(src, dir)
	if (T.contents.Find(connected))
		connected.connected = src
		update_icon()
		for(var/atom/movable/A in src)
			A.loc = connected.loc
		connected.icon_state = "morguet"
	else
		qdel(connected)
		connected = null
	return


/*
 * Morgue tray
 */
/obj/structure/m_tray
	name = "morgue tray"
	desc = "Apply corpse before closing."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "morguet"
	density = TRUE
	layer = 2.0
	var/obj/structure/morgue/connected = null
	anchored = TRUE
	throwpass = 1

	max_integrity = 350
	resistance_flags = CAN_BE_HIT

/obj/structure/m_tray/Destroy()
	if(connected && connected.connected == src)
		connected.connected = null
	connected = null
	return ..()

/obj/structure/m_tray/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/m_tray/attack_hand(mob/user)
	user.SetNextMove(CLICK_CD_INTERACT)
	connected.close()
	add_fingerprint(user)

/obj/structure/m_tray/MouseDrop_T(atom/movable/O, mob/user)
	if (!istype(O, /atom/movable) || O.anchored)
		return
	if (!ismob(O) && !istype(O, /obj/structure/closet/body_bag))
		return
	if (!ismob(user) || user.incapacitated())
		return
	O.loc = src.loc
	if (user != O)
		for(var/mob/B in viewers(user, 3))
			if ((B.client && !( B.blinded )))
				to_chat(B, text("<span class='rose'>[] stuffs [] into []!</span>", user, O, src))
	return

/*
 * Crematorium
 */

/obj/structure/crematorium
	name = "crematorium"
	desc = "A human incinerator. Works well on barbeque nights."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "crema1"
	density = TRUE
	var/obj/structure/c_tray/connected = null
	anchored = TRUE
	var/cremating = FALSE
	var/id = 1
	var/locked = FALSE

/obj/structure/crematorium/atom_init()
	. = ..()
	crematorium_list += src

/obj/structure/crematorium/Destroy()
	crematorium_list -= src
	if(connected)
		qdel(connected)
		connected = null
	return ..()

/obj/structure/crematorium/proc/update()
	if (src.connected)
		src.icon_state = "crema0"
	else
		if (src.contents.len)
			src.icon_state = "crema2"
		else
			src.icon_state = "crema1"
	return

/obj/structure/crematorium/proc/start_cremation(mob/user)
	if(cremating)
		return

	if(contents.len <= 0)
		audible_message("<span class='rose'>You hear a hollow crackle.</span>")
		return

	if(!isemptylist(search_contents_for(/obj/item/weapon/disk/nuclear)))
		to_chat(user, "<span class='notice'>You get the feeling that you shouldn't cremate one of the items in the cremator.</span>")
		return

	audible_message("<span class='rose'>You hear a roar as the crematorium activates.</span>")

	cremating = TRUE
	locked = TRUE
	update_icon()

	for(var/mob/living/M in contents)
		if (M.stat != DEAD)
			M.emote("scream")
		M.log_combat(user, "cremated")
		M.death(1)
		M.ghostize(bancheck = TRUE)
		qdel(M)

	for(var/obj/O in contents)
		qdel(O)

	new /obj/effect/decal/cleanable/ash(src)

	addtimer(CALLBACK(src, .proc/finish_cremation), 10 SECONDS)

/obj/structure/crematorium/proc/finish_cremation()
	if(QDELETED(src))
		return

	cremating = FALSE
	locked = FALSE
	update_icon()
	playsound(src, 'sound/machines/ding.ogg', VOL_EFFECTS_MASTER)

/obj/structure/crematorium/ex_act(severity)
	switch(severity)
		if(EXPLODE_HEAVY)
			if(prob(50))
				return
		if(EXPLODE_LIGHT)
			if(prob(95))
				return

	for(var/atom/movable/A in src)
		A.forceMove(loc)
		switch(severity)
			if(EXPLODE_DEVASTATE)
				SSexplosions.high_mov_atom += A
			if(EXPLODE_HEAVY)
				SSexplosions.med_mov_atom += A
			if(EXPLODE_LIGHT)
				SSexplosions.low_mov_atom += A
	qdel(src)

/obj/structure/crematorium/alter_health()
	return src.loc

/obj/structure/crematorium/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/crematorium/proc/move_contents(new_loc)
	for(var/atom/movable/A as mob|obj in src)
		A.forceMove(new_loc)

/obj/structure/crematorium/attack_hand(mob/user)
//	if (cremating) AWW MAN! THIS WOULD BE SO MUCH MORE FUN ... TO WATCH
//		user.show_message("<span class='warning'>Uh-oh, that was a bad idea.</span>", 1)
//		//usr << "Uh-oh, that was a bad idea."
//		src:loc:poison += 20000000
//		src:loc:firelevel = src:loc:poison
//		return
	user.SetNextMove(CLICK_CD_INTERACT)
	if (cremating)
		to_chat(user, "<span class='rose'>It's locked.</span>")
		return
	if (connected && !locked)
		for(var/atom/movable/A in src.connected.loc)
			if(!A.anchored)
				A.loc = src
		playsound(src, 'sound/items/Deconstruct.ogg', VOL_EFFECTS_MASTER)
		qdel(src.connected)
		src.connected = null
	else if (!locked)
		playsound(src, 'sound/items/Deconstruct.ogg', VOL_EFFECTS_MASTER)
		src.connected = new /obj/structure/c_tray( src.loc )
		step(src.connected, SOUTH)
		src.connected.layer = BELOW_CONTAINERS_LAYER
		var/turf/T = get_step(src, SOUTH)
		if (T.contents.Find(src.connected))
			src.connected.connected = src
			src.icon_state = "crema0"
			move_contents(connected.loc)
			src.connected.icon_state = "cremat"
		else
			qdel(src.connected)
			src.connected = null
	add_fingerprint(user)
	update_icon()

/obj/structure/crematorium/attackby(P, mob/user)
	if(istype(P, /obj/item/weapon/pen))
		var/t = sanitize_safe(input(user, "What would you like the label to be?", src.name, null)  as text, MAX_NAME_LEN)
		if (user.get_active_hand() != P)
			return
		if (!Adjacent(usr))
			return
		add_fingerprint(user)
		if (t)
			src.name = text("Crematorium- '[]'", t)
		else
			src.name = "Crematorium"
	else
		..()

/obj/structure/crematorium/relaymove(mob/user)
	if (user.incapacitated() || locked)
		return
	src.connected = new /obj/structure/c_tray( src.loc )
	step(src.connected, SOUTH)
	src.connected.layer = BELOW_CONTAINERS_LAYER
	var/turf/T = get_step(src, SOUTH)
	if (T.contents.Find(src.connected))
		src.connected.connected = src
		src.icon_state = "crema0"
		for(var/atom/movable/A as mob|obj in src)
			A.loc = src.connected.loc
		src.connected.icon_state = "cremat"
	else
		qdel(src.connected)
		src.connected = null
	return

/obj/structure/crematorium/deconstruct(disassembled)
	move_contents(loc)
	if(!(flags & NODECONSTRUCT))
		new /obj/item/stack/sheet/metal(loc, 5)
	..()

/obj/structure/crematorium/update_icon()
	if(cremating)
		icon_state = "crema_active"
	else if(connected)
		icon_state = "crema0"
	else if(contents.len)
		icon_state = "crema2"
	else
		icon_state = "crema1"

/*
 * Crematorium tray
 */
/obj/structure/c_tray
	name = "crematorium tray"
	desc = "Apply body before burning."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "cremat"
	density = TRUE
	layer = 2.0
	var/obj/structure/crematorium/connected = null
	anchored = TRUE
	throwpass = 1

/obj/structure/c_tray/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/c_tray/attack_hand(mob/user)
	user.SetNextMove(CLICK_CD_RAPID)
	if (src.connected)
		for(var/atom/movable/A in loc)
			if (!A.anchored)
				A.loc = src.connected
		src.connected.connected = null
		connected.update()
		add_fingerprint(user)
		qdel(src)

/obj/structure/c_tray/MouseDrop_T(atom/movable/O, mob/user)
	if (!istype(O, /atom/movable) || O.anchored)
		return
	if (!ismob(O) && !istype(O, /obj/structure/closet/body_bag))
		return
	if (!ismob(user) || user.incapacitated())
		return
	O.loc = src.loc
	if (user != O)
		for(var/mob/B in viewers(user, 3))
			if ((B.client && !( B.blinded )))
				to_chat(B, text("<span class='rose'>[] stuffs [] into []!</span>", user, O, src))
			//Foreach goto(99)
	return

/obj/machinery/crema_switch/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	user.SetNextMove(CLICK_CD_MELEE)
	for (var/obj/structure/crematorium/C in crematorium_list)
		if (C.id == id)
			if (!C.cremating)
				for(var/mob/living/M in C.contents)
					user.attack_log += "\[[time_stamp()]\]<font color='red'> Cremated [M.name] ([M.ckey])</font>"
					message_admins("[user.name] ([user.ckey]) <font color='red'>Cremating</font> [M.name] ([M.ckey]). [ADMIN_JMP(user)]")
				C.start_cremation(user)
