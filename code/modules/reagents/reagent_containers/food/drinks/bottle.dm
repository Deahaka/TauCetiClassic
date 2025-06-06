#define IS_NOT_MOLOTOV 0
#define IS_MOLOTOV 1
#define IS_LIT 2

///////////////////////////////////////////////Alchohol bottles! -Agouri //////////////////////////
//Functionally identical to regular drinks. The only difference is that the default bottle size is 100. - Darem
//Bottles now weaken and break when smashed on people's heads. - Giacom

/obj/item/weapon/reagent_containers/food/drinks/bottle
	amount_per_transfer_from_this = 10
	volume = 100
	item_state = "broken_beer" //Generic held-item sprite until unique ones are made.
	var/const/duration = 13 //Directly relates to the 'weaken' duration. Lowered by armor (i.e. helmets)
	var/is_glass = 1 //Whether the 'bottle' is made of glass or not so that milk cartons dont shatter when someone gets hit by it
	var/is_transparent = 1 //Determines whether an overlay of liquid should be added to bottle when it fills

	var/stop_spin_bottle = FALSE //Gotta stop the rotation.

	var/molotov_state = IS_NOT_MOLOTOV
	var/lit_time = null
	resistance_flags = CAN_BE_HIT
	max_integrity = 1 //glass is very fragile

/obj/item/weapon/reagent_containers/food/drinks/bottle/atom_init()
	. = ..()
	if (!is_glass)
		verbs -= /obj/item/weapon/reagent_containers/food/drinks/bottle/verb/spin_bottle

/obj/item/weapon/reagent_containers/food/drinks/bottle/verb/spin_bottle()
	set name = "Spin bottle"
	set category = "Object"
	set src in view(1)

	if(!ishuman(usr))  //Checking human and status
		return
	if(usr.incapacitated())
		return
	if(usr.is_busy())
		return

	if(!stop_spin_bottle)
		if(usr.get_active_hand() == src || usr.get_inactive_hand() == src)
			usr.drop_from_inventory(src)

		visible_message("<span class='warning'>[usr] spins \the [src]!</span>")
		if(isturf(loc))
			var/speed = rand(1, 3)
			var/loops
			var/sleep_not_stacking
			switch(speed) //At a low speed, the bottle should not make 10 loops
				if(3)
					loops = rand(7, 10)
					sleep_not_stacking = 40
				if(1 to 2)
					loops = rand(10, 15)
					sleep_not_stacking = 25

			stop_spin_bottle = TRUE
			playsound(src, 'sound/items/glass_containers/bottle_spin.ogg', VOL_EFFECTS_MASTER)
			SpinAnimation(speed, loops, pick(0, 1)) //SpinAnimation(speed, loops, clockwise, segments)
			transform = turn(matrix(), dir2angle(pick(alldirs)))
			sleep(sleep_not_stacking) //Not stacking
			stop_spin_bottle = FALSE

/obj/item/weapon/reagent_containers/food/drinks/bottle/pickup(mob/living/user)
	. = ..()
	animate(src, transform = null, time = 0) //Restore bottle to its original position
	if(reagents.total_volume > 0)
		playsound(user, 'sound/items/glass_containers/bottle_take-liquid.ogg', VOL_EFFECTS_MASTER)
	else
		playsound(user, 'sound/items/glass_containers/bottle_take-empty.ogg', VOL_EFFECTS_MASTER)

/obj/item/weapon/reagent_containers/food/drinks/bottle/dropped(mob/user)
	. = ..()
	if(isturf(loc) && (user.loc != loc))
		if(reagents.total_volume > 0)
			playsound(user, 'sound/items/glass_containers/bottle_put-liquid.ogg', VOL_EFFECTS_MASTER)
		else
			playsound(user, 'sound/items/glass_containers/bottle_put-empty.ogg', VOL_EFFECTS_MASTER)

/obj/item/weapon/reagent_containers/food/drinks/bottle/proc/blend_icon(obj/item/weapon/broken_bottle/bottle)
	var/icon/I = new('icons/obj/drinks.dmi', icon_state)
	I.Blend(bottle.broken_outline, ICON_OVERLAY, rand(5), 1)
	I.SwapColor(rgb(255, 0, 220, 255), rgb(0, 0, 0, 0))
	bottle.icon = I

/obj/item/weapon/reagent_containers/food/drinks/bottle/proc/smash(mob/living/target, mob/living/user)

	//Creates a shattering noise and replaces the bottle with a broken_bottle
	user.drop_item()
	var/obj/item/weapon/broken_bottle/B = new /obj/item/weapon/broken_bottle(user.loc)
	user.put_in_active_hand(B)
	if(prob(33))
		new/obj/item/weapon/shard(target.loc) // Create a glass shard at the target's location!
	B.icon_state = src.icon_state

	blend_icon(B)

	playsound(src, pick(SOUNDIN_SHATTER), VOL_EFFECTS_MASTER)
	user.put_in_active_hand(B)
	transfer_fingerprints_to(B)
	if(molotov_state == IS_LIT)
		var/turf/T = get_turf(target)
		T.hotspot_expose(1000, 500)

	qdel(src)

/obj/item/weapon/reagent_containers/food/drinks/bottle/on_reagent_change()
	if(is_glass && is_transparent)
		update_icon()

/obj/item/weapon/reagent_containers/food/drinks/bottle/update_icon()
	show_filler_on_icon(3, 24, 0)
	cut_overlays()
	if(molotov_state == IS_MOLOTOV)
		add_overlay(image(icon, "molotov"))
	if(molotov_state == IS_LIT)
		add_overlay(image(icon, "molotov_lit"))

/obj/item/weapon/reagent_containers/food/drinks/bottle/proc/can_smash()
	return is_glass

/obj/item/weapon/reagent_containers/food/drinks/bottle/attack(mob/living/target, mob/living/user, def_zone)
	if(user.a_intent != INTENT_HARM || !can_smash())
		return ..()

	if(!target)
		return

	force = 15 //Smashing bottles over someoen's head hurts.

	var/armor_block = 0 //Get the target's armour values for normal attack damage.
	var/armor_duration = 0 //The more force the bottle has, the longer the duration.

	//Calculating duration and calculating damage.
	if(ishuman(target))

		var/mob/living/carbon/human/H = target
		armor_block = H.run_armor_check(def_zone, MELEE) // For normal attack damage

		//Calculating the weakening duration for the target.
		if(def_zone == BP_HEAD)
			armor_duration = (duration - armor_block) + force

	else
		//Only humans can have armour, right?
		armor_block = target.run_armor_check(def_zone, MELEE)
		if(def_zone == BP_HEAD)
			armor_duration = duration + force
	armor_duration /= 10

	//Apply the damage!
	target.apply_damage(force, BRUTE, def_zone, armor_block)

	// You are going to knock someone out for longer if they are not wearing a helmet.
	if(def_zone == BP_HEAD && iscarbon(target))

		//Display an attack message.
		if(target != user)
			user.visible_message("<span class='warning'><B>[target] has been hit over the head with a bottle of [src.name], by [user]!</B></span>")
		else
			user.visible_message("<span class='warning'><B>[target] hit himself with a bottle of [src.name] on the head!</B></span>")
		//Weaken the target for the duration that we calculated and divide it by 5.
		if(armor_duration)
			target.apply_effect(min(armor_duration, 10) , WEAKEN) // Never weaken more than a flash!

	else
		//Default attack message and don't weaken the target.
		if(target != user)
			user.visible_message("<span class='warning'><B>[target] has been attacked with a bottle of [src.name], by [user]!</B></span>")
		else
			user.visible_message("<span class='warning'><B>[target] has attacked himself with a bottle of [src.name]!</B></span>")

	//Attack logs
	target.log_combat(user, "smashed with a [name], reagents: [reagentlist(src)] (INTENT: [uppertext(user.a_intent)])")

	//The reagents in the bottle splash all over the target, thanks for the idea Nodrak
	if(src.reagents)
		for(var/mob/O in viewers(user, null))
			O.show_message(text("<span class='notice'><B>The contents of the [src] splashes all over [target]!</B></span>"), 1)
		reagents.standard_splash(target, user = user)

	//Finally, smash the bottle. This kills (del) the bottle.
	smash(target, user)

	// We're smashing the bottle into mob's face. There's no need for an afterattack.
	return TRUE

/obj/item/weapon/reagent_containers/food/drinks/bottle/afterattack(atom/target, mob/user, proximity, params)
	. = ..()
	if(target.is_open_container())
		if(reagents.total_volume && target.reagents.total_volume < target.reagents.maximum_volume)
			playsound(user, 'sound/items/glass_containers/bottle_pouring.ogg', VOL_EFFECTS_MASTER, 800)

/obj/item/weapon/reagent_containers/food/drinks/bottle/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(..())
		return
	if(is_glass)
		var/obj/item/weapon/broken_bottle/BB =  new /obj/item/weapon/broken_bottle(loc)
		blend_icon(BB)
		playsound(src, pick(SOUNDIN_SHATTER), VOL_EFFECTS_MASTER)
		new /obj/item/weapon/shard(loc)
		reagents.standard_splash(loc)
		if(molotov_state == IS_LIT)
			var/turf/T = get_turf(hit_atom)
			T.hotspot_expose(1000, 500)
			if(isliving(hit_atom))
				var/mob/living/L = hit_atom
				L.IgniteMob()
		qdel(src)

/obj/item/weapon/reagent_containers/food/drinks/bottle/bullet_act(obj/item/projectile/Proj, def_zone)
	if(Proj.checkpass(PASSGLASS))
		return PROJECTILE_FORCE_MISS

	return ..()

/obj/item/weapon/reagent_containers/food/drinks/bottle/deconstruct()
	var/obj/item/weapon/broken_bottle/BB =  new /obj/item/weapon/broken_bottle(loc)
	blend_icon(BB)
	BB.pixel_x = rand(-5, 5)
	BB.pixel_y = rand(-5, 5)
	playsound(src, pick(SOUNDIN_SHATTER), VOL_EFFECTS_MASTER)
	var/obj/item/weapon/shard/S = new(loc)
	if(prob(75))
		S.throw_at(get_step(src, pick(alldirs)), rand(1, 6), 2)
	S.pixel_x = rand(-5, 5)
	S.pixel_y = rand(-5, 5)
	reagents.standard_splash(loc)
	..()

/obj/item/weapon/reagent_containers/food/drinks/bottle/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/cloth) && is_glass && molotov_state == IS_NOT_MOLOTOV)
		var/obj/item/stack/sheet/cloth/C = I
		C.use(1)
		molotov_state = IS_MOLOTOV
		flags ^= OPENCONTAINER
		to_chat(user, "<span class='notice'You stuff some cloth into the bottleneck.</span>")

	if(istype(I, /obj/item/weapon/lighter))
		var/obj/item/weapon/lighter/L = I
		if(L.lit && molotov_state == IS_MOLOTOV)
			molotov_state = IS_LIT
			lit_time = world.time + rand(200, 400)
			user.visible_message("<span class='warning'>[user] lights up a molotov!</span>")
			playsound(src, 'sound/items/torch.ogg', VOL_EFFECTS_MASTER)
			START_PROCESSING(SSobj, src)

	update_icon()

/obj/item/weapon/reagent_containers/food/drinks/bottle/process()
	if(world.time >= lit_time)
		throw_impact(loc)

/obj/item/weapon/reagent_containers/food/drinks/bottle/attack_self(mob/user)
	if(molotov_state == IS_MOLOTOV)
		new /obj/item/stack/sheet/cloth(user.loc)
		molotov_state = IS_NOT_MOLOTOV
		flags |= OPENCONTAINER
		update_icon()

//Keeping this here for now, I'll ask if I should keep it here.
/obj/item/weapon/broken_bottle
	name = "Broken Bottle"
	desc = "A bottle with a sharp broken bottom."
	w_class = SIZE_TINY
	icon = 'icons/obj/drinks.dmi'
	icon_state = "broken_bottle"
	force = 9.0
	throwforce = 5.0
	throw_speed = 3
	throw_range = 5
	item_state = "beer"
	attack_verb = list("stabbed", "slashed", "attacked")
	sharp = 1
	edge = 0
	var/icon/broken_outline = icon('icons/obj/drinks.dmi', "broken")
	resistance_flags = CAN_BE_HIT
	max_integrity = 1 //glass is very fragile

/obj/item/weapon/broken_bottle/attack(mob/living/carbon/M, mob/living/carbon/user)
	playsound(src, 'sound/weapons/bladeslice.ogg', VOL_EFFECTS_MASTER)
	return ..()

/obj/item/weapon/broken_bottle/after_throw(datum/callback/callback)
	..()
	deconstruct()

/obj/item/weapon/broken_bottle/bullet_act(obj/item/projectile/Proj, def_zone)
	if(Proj.checkpass(PASSGLASS))
		return PROJECTILE_FORCE_MISS

	return ..()

/obj/item/weapon/broken_bottle/deconstruct()
	playsound(src, pick(SOUNDIN_SHATTER), VOL_EFFECTS_MASTER)
	var/obj/item/weapon/shard/S = new(loc)
	if(prob(75))
		S.throw_at(get_step(src, pick(alldirs)), rand(1, 6), 2)
	S.pixel_x = rand(-5, 5)
	S.pixel_y = rand(-5, 5)
	..()

/obj/item/weapon/reagent_containers/food/drinks/bottle/gin
	name = "Griffeater Gin"
	desc = "A bottle of high quality gin, produced in the New London Space Station."
	icon_state = "ginbottle"
	list_reagents = list("gin" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/whiskey
	name = "Uncle Git's Special Reserve"
	desc = "A premium single-malt whiskey, gently matured inside the tunnels of a nuclear shelter. TUNNEL WHISKEY RULES."
	icon_state = "whiskeybottle"
	list_reagents = list("whiskey" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/vodka
	name = "Tunguska Triple Distilled"
	desc = "Aah, vodka. Prime choice of drink AND fuel by Russians worldwide."
	icon_state = "vodkabottle"
	list_reagents = list("vodka" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/tequilla
	name = "Caccavo Guaranteed Quality Tequilla"
	desc = "Made from premium petroleum distillates, pure thalidomide and other fine quality ingredients!"
	icon_state = "tequillabottle"
	list_reagents = list("tequilla" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/bottleofnothing
	name = "Bottle of Nothing"
	desc = "A bottle filled with nothing."
	icon_state = "bottleofnothing"
	list_reagents = list("nothing" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/patron
	name = "Wrapp Artiste Patron"
	desc = "Silver laced tequilla, served in space night clubs across the galaxy."
	icon_state = "patronbottle"
	list_reagents = list("patron" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/rum
	name = "Captain Pete's Cuban Spiced Rum"
	desc = "This isn't just rum, oh no. It's practically GRIFF in a bottle."
	icon_state = "rumbottle"
	list_reagents = list("rum" = 100)
/obj/item/weapon/reagent_containers/food/drinks/bottle/champagne
	name = "Duc de Paris Brut"
	desc = "Boisson elegante. Servir froid."
	icon_state = "chambottle"
	list_reagents = list("champagne" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/holywater
	name = "Holy Flask"
	desc = "A flask of the chaplain's water."
	icon_state = "holyflask"
	list_reagents = list("water" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/vermouth
	name = "Goldeneye Vermouth"
	desc = "Sweet, sweet dryness~"
	icon_state = "vermouthbottle"
	list_reagents = list("vermouth" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/kahlua
	name = "Robert Robust's Coffee Liqueur"
	desc = "A widely known, Mexican coffee-flavoured liqueur. In production since 1936, HONK"
	icon_state = "kahluabottle"
	list_reagents = list("kahlua" = 100)
	is_transparent = 0

/obj/item/weapon/reagent_containers/food/drinks/bottle/goldschlager
	name = "College Girl Goldschlager"
	desc = "Because they are the only ones who will drink 100 proof cinnamon schnapps."
	icon_state = "goldschlagerbottle"
	list_reagents = list("goldschlager" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/cognac
	name = "Chateau De Baton Premium Cognac"
	desc = "A sweet and strongly alchoholic drink, made after numerous distillations and years of maturing. You might as well not scream 'SHITCURITY' this time."
	icon_state = "cognacbottle"
	list_reagents = list("cognac" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/wine
	name = "Doublebeard Bearded Special Wine"
	desc = "A faint aura of unease and asspainery surrounds the bottle."
	icon_state = "winebottle"
	list_reagents = list("wine" = 100)
	is_transparent = 0

/obj/item/weapon/reagent_containers/food/drinks/bottle/absinthe
	name = "Jailbreaker Verte"
	desc = "One sip of this and you just know you're gonna have a good time."
	icon_state = "absinthebottle"
	list_reagents = list("absinthe" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/melonliquor
	name = "Emeraldine Melon Liquor"
	desc = "A bottle of 46 proof Emeraldine Melon Liquor. Sweet and light."
	icon_state = "melonliquorbottle"
	list_reagents = list("melonliquor" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/bluecuracao
	name = "Miss Blue Curacao"
	desc = "A fruity, exceptionally azure drink. Does not allow the imbiber to use the fifth magic."
	icon_state = "bluecuracaobottle"
	list_reagents = list("bluecuracao" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/grenadine
	name = "Briar Rose Grenadine Syrup"
	desc = "Sweet and tangy, a bar syrup used to add color or flavor to drinks."
	icon_state = "grenadinebottle"
	list_reagents = list("grenadine" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/pwine
	name = "Warlock's Velvet"
	desc = "What a delightful packaging for a surely high quality wine! The vintage must be amazing!"
	icon_state = "pwinebottle"
	list_reagents = list("pwine" = 100)
	is_transparent = 0

//////////////////////////JUICES AND STUFF ///////////////////////

/obj/item/weapon/reagent_containers/food/drinks/bottle/orangejuice
	name = "Orange Juice"
	desc = "Full of vitamins and deliciousness!"
	icon_state = "orangejuice"
	item_state = "carton"
	list_reagents = list("orangejuice" = 100)
	is_glass = 0

/obj/item/weapon/reagent_containers/food/drinks/bottle/cream
	name = "Milk Cream"
	desc = "It's cream. Made from milk. What else did you think you'd find in there?"
	icon_state = "cream"
	item_state = "carton"
	list_reagents = list("cream" = 100)
	is_glass = 0

/obj/item/weapon/reagent_containers/food/drinks/bottle/tomatojuice
	name = "Tomato Juice"
	desc = "Well, at least it LOOKS like tomato juice. You can't tell with all that redness."
	icon_state = "tomatojuice"
	item_state = "carton"
	list_reagents = list("tomatojuice" = 100)
	is_glass = 0

/obj/item/weapon/reagent_containers/food/drinks/bottle/limejuice
	name = "Lime Juice"
	desc = "Sweet-sour goodness."
	icon_state = "limejuice"
	item_state = "carton"
	list_reagents = list("limejuice" = 100)
	is_glass = 0

/obj/item/weapon/reagent_containers/food/drinks/bottle/ale
	name = "Magm-Ale"
	desc = "A true dorf's drink of choice."
	icon_state = "alebottle"
	list_reagents = list("ale" = 100)

/obj/item/weapon/reagent_containers/food/drinks/bottle/beer
	name = "Space Beer"
	desc = "Contains only water, malt and hops."
	icon_state = "beer"
	list_reagents = list("beer" = 100)

