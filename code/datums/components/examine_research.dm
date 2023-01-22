#define DIAGNOSTIC_EXTRA_CHECK "diagnostic"
#define SCIENCE_EXTRA_CHECK "science"

#define DEFAULT_SCIENCE_CONSOLE_ID 1
#define DEFAULT_ROBOT_CONSOLE_ID 2
#define DEFAULT_MINING_CONSOLE_ID 3

/datum/component/examine_research
	var/datum/research/linked_techweb
	var/points_value = 0
	var/extra_check

/datum/component/examine_research/Initialize(linked_techweb_id, research_value, _extra_check)
	//Current use for mechs and items
	if(!isobj(parent))
		return COMPONENT_INCOMPATIBLE
	for(var/obj/machinery/computer/rdconsole/RD in RDcomputer_list)
		if(RD.id == linked_techweb_id)
			linked_techweb = RD.files
	if(!istype(linked_techweb))
		return COMPONENT_NOT_ATTACHED
	points_value = research_value
	if(points_value <= 0)
		return COMPONENT_NOT_ATTACHED
	extra_check = _extra_check
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, .proc/begin_scan)

/datum/component/examine_research/proc/begin_scan(datum/source, mob/user)
	if(user.is_busy())
		return
	if(!success_check(extra_check, user))
		return
	to_chat(user, "<span class='notice'>You concentrate on scanning [parent].</span>")
	if(!do_after(user, 50, FALSE, parent))
		to_chat(user, "<span class='warning'>You stop scanning [parent].</span>")
		return
	if(calculate_research_value() <= 0)
		to_chat(user, "<span class='warning'>[parent] have no research value.</span>")
		return
	to_chat(user, "<span class='notice'>[parent] scan earned you [points_value] points.</span>")
	linked_techweb.research_points += points_value
	global.spented_examined_objects += parent

/datum/component/examine_research/proc/calculate_research_value()
	SIGNAL_HANDLER
	for(var/obj/object in global.spented_examined_objects)
		if(object.type == parent.type)
			return 0
	return points_value

/datum/component/examine_research/proc/success_check(check_define, mob/user)
	switch(check_define)
		if(DIAGNOSTIC_EXTRA_CHECK)
			var/mob/living/carbon/human/H = user
			if(H?.glasses)
				if(istype(H.glasses, /obj/item/clothing/glasses/hud/diagnostic))
					return TRUE
		if(SCIENCE_EXTRA_CHECK)
			var/mob/living/carbon/human/H = user
			if(H?.glasses)
				if(istype(H.glasses, /obj/item/clothing/glasses/science))
					return TRUE
		else
			return FALSE
