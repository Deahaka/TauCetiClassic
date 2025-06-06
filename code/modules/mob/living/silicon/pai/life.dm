/mob/living/silicon/pai/Life()
	if (src.stat == DEAD)
		return
	if(src.cable)
		if(get_dist(src, src.cable) > 1)
			visible_message("<span class='warning'>The data cable rapidly retracts back into its spool.</span>", blind_message = "<span class='warning'>You hear a click and the sound of wire spooling rapidly.</span>")
			QDEL_NULL(src.cable)
			hacksuccess = FALSE
			hackobj = null
	else
		if(hacksuccess && !src.hackobj)
			hacksuccess = FALSE
	if(usetime && world.time >= usetime)
		run_interact()

	add_ingame_age()
	regular_hud_updates()

	if(silence_time)
		if(world.timeofday >= silence_time)
			silence_time = null
			to_chat(src, "<font color=green>Communication circuit reinitialized. Speech and messaging functionality restored.</font>")

/mob/living/silicon/pai/updatehealth()
	health = 100 - getBruteLoss() - getFireLoss()

/mob/living/silicon/pai/IgniteMob(mob/living/silicon/pai/P)
	return FALSE //No we're not flammable
