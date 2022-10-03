/datum/component/live_food
	var/list/food_consistance = list()
	//var/total_volume = 0	//used for finding max health of mob

/datum/component/live_food/Initialize(list/_butcher_results = list(), list/_list_reagents = list())
	if(!istype(parent, /obj/item/weapon/holder))
		return COMPONENT_INCOMPATIBLE
	//create default meat
	if(!_butcher_results.len)
		var/obj/item/S = new /obj/item/weapon/reagent_containers/food/snacks/meat(parent)
		food_consistance += S
	else
		for(var/path in _butcher_results)
			for(var/i = 1 to _butcher_results[path])
				var/obj/item/B = new path(parent)
				food_consistance += B
	//set recieved reagents to products
	if(_list_reagents.len)
		for(var/obj/item/weapon/reagent_containers/food/F in food_consistance)
			F.list_reagents = _list_reagents

	RegisterSignal(src, COMSIG_ITEM_ATTACK, .proc/bite)

/datum/component/live_food/proc/bite(mob/living/D, mob/living/user, def_zone)
	tram_consistance()
	if(!food_consistance.len)
		qdel(src)
	var/obj/item/weapon/reagent_containers/food/M = pick(food_consistance)
	if(istype(M, /obj/item/weapon/reagent_containers/food/snacks))
		var/obj/item/weapon/reagent_containers/food/snacks/S = M
		S.On_Consume(user)
	health_damage()
	update_reagents()

/datum/component/live_food/proc/tram_consistance()
	for(var/obj/item/C in food_consistance)
		if(!C || !C.reagents || !C.reagents.total_volume)
			food_consistance -= C

/datum/component/live_food/proc/update_reagents()
	for(var/obj/item/weapon/reagent_containers/food/P in food_consistance)
		if(!P.reagents.total_volume)
			qdel(P)

/datum/component/live_food/proc/health_damage()
	var/mob/living/Q = parent
	Q.adjustBruteLoss(15)

/datum/component/live_food/Destroy()
	UnregisterSignal(src, COMSIG_PARENT_ATTACKBY)
	return ..()
