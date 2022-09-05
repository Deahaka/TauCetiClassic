/mob/living/simple_animal/small_moth
	name = "Young moth"
	icon = 'icons/mob/animal.dmi'
	desc = ""
	health = 10
	maxHealth = 10

	icon_state = "small_moth"
	icon_living = "small_moth"
	icon_dead = "small_moth_dead"

	response_help   = "hugs"
	response_disarm = "gently pushes"
	response_harm   = "punches"

	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/candy/fudge/moth_meat = 3)

	minbodytemp = 288
	maxbodytemp = 301
	heat_damage_per_tick = 9

	speed = 3

	has_head = TRUE
	has_arm = TRUE
	has_leg = TRUE
	var/stage = 1

/mob/living/simple_animal/small_moth/atom_init()
	. = ..()
	addtimer(CALLBACK(src, .proc/handle_evolving), 1200, TIMER_UNIQUE)

/mob/living/simple_animal/small_moth/Life()
	. = ..()
	var/matrix/Mx = matrix()
	switch(stage)
	if(1)
		Mx.Scale(0.75)
		Mx.Translate(0,-5)
	if(2)
		Mx.Scale(0.8)
		Mx.Translate(0,-4)
	if(3)
		Mx.Scale(1)
		Mx.Translate(0,0)
	transform = Mx
	default_transform = Mx

/mob/living/simple_animal/small_moth/proc/handle_evolving()
	if(stage < 4)
		addtimer(CALLBACK(src, .proc/handle_evolving), 1200, TIMER_UNIQUE)
		stage++
		if(2)
			maxHealth = 20
			speed = 2
		if(3)
			maxHealth = 40
			speed = 1
		return
	if(!mind || !client || !stat || !key)
		return
	var/mob/living/carbon/human/moth/M = new(loc)
	mind.transfer_to(M)
	qdel(src)

/mob/living/simple_animal/mouse/rat/newborn_moth
	name = "Newborn moth"
	real_name = "Newborn moth"
	desc = ""

	health = 5
	maxHealth = 5

	icon_state = "newmorn_moth"
	icon_living = "newmorn_moth"
	icon_dead = "small_moth_dead"
	icon_move = null

	speak_chance = 0
	speak = list("Chirp!", "Chirp?")
	speak_emote = list()
	emote_hear = list()
	emote_see = list()

	response_help   = "hugs"
	response_disarm = "gently pushes"
	response_harm   = "punches"

	butcher_results = list(/obj/item/weapon/reagent_containers/food/snacks/candy/fudge/moth_meat = 1)

	minbodytemp = 288
	maxbodytemp = 301
	heat_damage_per_tick = 9

	holder_type = null
	faction = "neutral"
	ventcrawler = 2

	has_arm = FALSE
	has_leg = FALSE

/mob/living/simple_animal/mouse/rat/newborn_moth/atom_init()
	. = ..()
	addtimer(CALLBACK(src, .proc/handle_evolving), 1200, TIMER_UNIQUE)

/mob/living/simple_animal/mouse/rat/newborn_moth/proc/handle_evolving()
	if(!stat)
		return
	if(!key || !client || !mind)
		addtimer(CALLBACK(src, .proc/handle_evolving), 1200, TIMER_UNIQUE)
		return
	var/mob/living/simple_animal/small_moth/moth = new(loc)
	mind.transfer_to(moth)
	qdel(src)

/mob/living/simple_animal/mouse/rat/newborn_moth/death()
	if(butcher_results)
		for(var/path in butcher_results)
			for(var/i = 1 to butcher_results[path])
				new path(loc)
	qdel(src)


//sweet to attract hungry assistants
/obj/item/weapon/reagent_containers/food/snacks/candy/fudge/moth_meat
	name = "Moth meat"
	desc = "Meat. Sometimes liquid, sometimes jelly-like, sometimes crunchy and sweet. Despite the texture, it smells delicious."
	icon_state = "xenomeat"
	filling_color = "#cadaba"
