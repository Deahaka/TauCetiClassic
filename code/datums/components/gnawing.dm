/datum/component/gnawing
	var/mob/living/simple_animal/animal
	var/loc
	var/list/attack

/datum/component/gnawing/Initialize()
	START_PROCESSING(SSgnaw, src)

/datum/component/gnawing/process()
	animal = parent
	loc = locate(parent)
	attack = animal.get_unarmed_attack()
	if(animal.stat != CONSCIOUS)
		return
	for(var/obj/structure/cable/C in loc)
    	C.health -= attack["damage"]
		C.check_health()

/datum/component/gnawing/Destroy()
	STOP_PROCESSING(SSgnaw, src)
	return ..()
