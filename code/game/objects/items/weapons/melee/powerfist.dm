/obj/item/weapon/melee/powerfist
	name = "power-fist"
	desc = "A metal gauntlet with a piston-powered ram ontop for that extra 'ompfh' in your punch."
	icon_state = "powerfist"
	force = 20
	throwforce = 10
	throw_range = 7
	var/base_force = 0
	var/click_delay = 1.5
	var/fisto_setting = 1
	var/gasperfist = 3
	var/obj/item/weapon/tank/tank = null //Tank used for the gauntlet's piston-ram.

/obj/item/weapon/melee/powerfist/atom_init()
	. = ..()
	base_force = force

/obj/item/weapon/melee/powerfist/examine(mob/user)
	. = ..()
	if(!in_range(user, src))
		. += span_notice("You'll need to get closer to see any more.")
		return
	if(tank)
		. += span_notice("[icon2html(tank, user)] It has \a [tank] mounted onto it.")


/obj/item/weapon/melee/powerfist/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/weapon/tank))
		if(!tank)
			var/obj/item/tank/internals/IT = W
			if(IT.volume <= 3)
				to_chat(user, span_warning("\The [IT] is too small for \the [src]."))
				return
			updateTank(W, 0, user)
	else if(iswrench(W))
		switch(fisto_setting)
			if(1)
				fisto_setting = 2
			if(2)
				fisto_setting = 3
			if(3)
				fisto_setting = 1
		W.play_tool_sound(src)
		to_chat(user, span_notice("You tweak \the [src]'s piston valve to [fisto_setting]."))
	else if(isscrewdriver(W))
		if(tank)
			updateTank(tank, 1, user)

/obj/item/weapon/melee/powerfist/proc/updateTank(obj/item/tank/internals/thetank, removing = 0, mob/living/carbon/human/user)
	if(removing)
		if(!tank)
			to_chat(user, "<span class='notice'>\The [src] currently has no tank attached to it.</span>")
			return
		to_chat(user, "<span class='notice'>You detach \the [thetank] from \the [src].</span>")
		tank.forceMove(get_turf(user))
		user.put_in_hands(tank)
		tank = null
	if(!removing)
		if(tank)
			to_chat(user, "<span class='warning'>\The [src] already has a tank.</span>")
			return
		if(!user.transferItemToLoc(thetank, src))
			return
		to_chat(user, "<span class='notice'>You hook \the [thetank] up to \the [src]</span>")
		tank = thetank

/obj/item/weapon/melee/powerfist/attack(mob/living/target, mob/living/user)
	if(!tank)
		to_chat(user, "<span class='warning'>\The [src] can't operate without a source of gas!</span>")
		return FALSE
	var/datum/gas_mixture/gasused = tank.remove_air(gasperfist * fisto_setting)
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	T.assume_air(gasused)
	if(!gasused)
		force = base_force / 5
		if(..())
			playsound(loc, 'sound/weapons/punch1.ogg', VOL_EFFECTS_MASTER)
			user.visible_message("<span class='warning'>The [user]'s [src] emits a thud when it hits a [target]!</span>", \
								"<span class='warning'>You punched [target], but [src]'s tank is empty!</span>")
	if(!molar_cmp_equals(gasused.total_moles(), gasperfist * fisto_setting))
		force = base_force / 2
		if(..())
			to_chat(user, span_warning("\The [src]'s piston-ram lets out a weak hiss, it needs more gas!"))
			playsound(src, 'sound/effects/refill.ogg', VOL_EFFECTS_MASTER)
			user.visible_message("<span class='warning'>[user]'s punch strikes with force!</span>", \
			"<span class='warning'>\The [src]'s piston-ram lets out a weak hiss, it needs more gas!</span>")
			return TRUE
		return FALSE

	force = base_force * fisto_setting
	if(..())
		target.visible_message("<span class='warning'>[user]'s powerfist lets out a loud hiss as they punch [target.name]!</span>",
							"<span class='userdanger'>You cry out in pain as [user]'s punch flings you backwards!</span>",
							"<span class='warning'>You hear a mechanical-hydraulic impact</span>")
		new /obj/item/effect/kinetic_blast(target.loc)
		playsound(src, 'sound/weapons/guns/resonator_blast.ogg', VOL_EFFECTS_MASTER)
		playsound(src, 'sound/weapons/genhit2.ogg', VOL_EFFECTS_MASTER)

		var/atom/throw_target = get_edge_target_turf(target, get_dir(src, get_step_away(target, src)))

		target.throw_at(throw_target, 5 * fisto_setting, 0.5 + (fisto_setting / 2))

		user.SetNextMove(CLICK_CD_MELEE)
		return TRUE
	return FALSE
