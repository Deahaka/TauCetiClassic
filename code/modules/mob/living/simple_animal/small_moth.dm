/mob/living/simple_animal/small_moth
	name = "Young moth"
	icon = 'icons/mob/animal.dmi'
	health = 40
	maxHealth = 40

	icon_living = "small_moth"
	icon_dead = "small_moth_dead"
	icon_gib = "small_moth_gib"

	response_help   = "hugs"
	response_disarm = "gently pushes"
	response_harm   = "punches"

	/*var/minbodytemp = 250
	var/maxbodytemp = 350*/
	heat_damage_per_tick = 9 // amount of damage applied if animal's body temperature is higher than maxbodytemp

	speed = 0

	has_head = TRUE
	has_arm = TRUE
	has_leg = TRUE

/*mob/living/simple_animal/proc/SA_attackable(target_mob)
	if (isliving(target_mob))
		var/mob/living/L = target_mob
		if(!L.stat && L.health >= 0)
			return FALSE
	if (istype(target_mob, /obj/mecha))
		var/obj/mecha/M = target_mob
		if(M.occupant)
			return FALSE
	if (isbot(target_mob))
		var/obj/machinery/bot/B = target_mob
		if(B.health > 0)
			return FALSE
	return TRUE*/

/mob/living/simple_animal/crawl()
	return TRUE
