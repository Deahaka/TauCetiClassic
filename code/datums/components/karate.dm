/datum/component/karate

/datum/component/karate/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(victim, list(COMSIG_KISSED_THE_WALL), .proc/side_kick)

/datum/component/karate/proc/side_kick(victim)
	var/living/carbon/human/H = victim
		if(prob(70))
			AdjustWeakened(1)
			make_dizzy(10)
			to_chat(H, "<span class='userdanger'>This power...</span>")

/datum/component/karate/Destroy()
	UnregisterSignal(parent, list(COMSIG_KISSED_THE_WALL))
	. = ..()
