/obj/item/clothing/glasses/sunglasses/hud/chaplain
	name = "faithful sunglasses"
	desc = "Sometimes you just feel like watching them ghosts sin."

	icon_state = "faith_glasses"
	item_state = "faith_glasses"
	item_state_world = "faith_glasses_w"

	var/next_assessment = 0
	var/assessment_cooldown = 6 SECONDS

	hud_types = list(DATA_HUD_HOLY)
	item_action_types = list(/datum/action/item_action/hands_free/assess_holyness)

/datum/action/item_action/hands_free/assess_holyness
	name = "Assess Holyness"

/obj/item/clothing/glasses/sunglasses/hud/chaplain/proc/gen_holy_overlay(turf/simulated/floor/F)
	var/image/I = image('icons/effects/effects.dmi', "holy_land")
	if(F.holy.religion != usr.my_religion)
		I.color = "#dc143c"
	I.alpha = 0
	I.loc = F
	return I

/obj/item/clothing/glasses/sunglasses/hud/chaplain/proc/animate_holy_overlay(image/holy_overlay)
	animate(holy_overlay, alpha = 200, time = assessment_cooldown * 0.2)
	sleep(assessment_cooldown * 0.6)
	if(QDELING(src))
		return
	animate(holy_overlay, alpha = 0, time = assessment_cooldown  * 0.2)

/obj/item/clothing/glasses/sunglasses/hud/chaplain/attack_self(mob/user)
	assess_holyness(user)

/obj/item/clothing/glasses/sunglasses/hud/chaplain/proc/assess_holyness(mob/user = usr)
	set name = "Assess Holyness"
	set desc = "Scan your surrounding area on subject of holy land."
	set category = "Object"

	if(user.incapacitated())
		return

	if(!user.client)
		return

	if(!user.mind || !user.mind.holy_role)
		to_chat(user, "<span class='notice'>You do not know how this works.</span>")
		return

	if(next_assessment > world.time)
		return
	next_assessment = world.time + assessment_cooldown

	playsound(src, 'sound/items/faith_scan.ogg', VOL_EFFECTS_MASTER)

	var/turf/T = get_turf(user)
	for(var/turf/simulated/floor/F in RANGE_TURFS(12, T))
		if(!F.holy)
			continue
		var/image/I = gen_holy_overlay(F)
		INVOKE_ASYNC(src, PROC_REF(animate_holy_overlay), I)
		flick_overlay(I, list(user.client), assessment_cooldown)
