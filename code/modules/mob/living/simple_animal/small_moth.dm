/mob/living/simple_animal/small_moth
	name = "Young moth"
	icon = 'icons/mob/animal.dmi'
	desc = ""
	health = 40
	maxHealth = 40

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

	speed = 0

	has_head = TRUE
	has_arm = TRUE
	has_leg = TRUE

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
	speed = 0
	faction = "neutral"
	ventcrawler = 2

	has_arm = FALSE
	has_leg = FALSE

	var/body_color //brown, gray and white, leave blank for random
	var/changes_color = FALSE
	var/can_emote_snuffles = FALSE

/mob/living/simple_animal/mouse/rat/newborn_moth/atom_init()
	. = ..()

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
