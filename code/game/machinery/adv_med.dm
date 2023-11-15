// Pretty much everything here is stolen from the dna scanner FYI


/obj/machinery/bodyscanner
	var/locked
	name = "Body Scanner"
	desc = "Используется для более детального анализа состояния пациента."
	icon = 'icons/obj/Cryogenic3.dmi'
	icon_state = "body_scanner_0"
	density = TRUE
	anchored = TRUE
	light_color = "#00ff00"
	required_skills = list(/datum/skill/medical = SKILL_LEVEL_NOVICE)

/obj/machinery/bodyscanner/power_change()
	..()
	if(!(stat & (BROKEN|NOPOWER)))
		set_light(2)
	else
		set_light(0)

/obj/machinery/bodyscanner/relaymove(mob/user)
	if(!user.incapacitated())
		open_machine()

/obj/machinery/bodyscanner/verb/eject()
	set src in oview(1)
	set category = "Object"
	set name = "Eject Body Scanner"

	if (usr.incapacitated())
		return
	open_machine()
	add_fingerprint(usr)
	return

/obj/machinery/bodyscanner/verb/move_inside()
	set src in oview(1)
	set category = "Object"
	set name = "Enter Body Scanner"

	if (usr.incapacitated())
		return
	if(!move_inside_checks(usr, usr))
		return
	close_machine(usr, usr)

/obj/machinery/bodyscanner/proc/move_inside_checks(mob/target, mob/user)
	if(occupant)
		to_chat(user, "<span class='userdanger'>Сканер уже занят кем-то!</span>")
		return FALSE
	if(!iscarbon(target))
		return FALSE
	if(target.abiotic())
		to_chat(user, "<span class='userdanger'>У пациента не должно быть чего-либо в руках.</span>")
		return FALSE
	if(!do_skill_checks(user))
		return
	return TRUE

/obj/machinery/bodyscanner/attackby(obj/item/weapon/grab/G, mob/user)
	if(!istype(G))
		return
	if(!move_inside_checks(G.affecting, user))
		return
	add_fingerprint(user)
	close_machine(G.affecting)
	playsound(src, 'sound/machines/analysis.ogg', VOL_EFFECTS_MASTER, null, FALSE)
	qdel(G)

/obj/machinery/bodyscanner/update_icon()
	icon_state = "body_scanner_[occupant ? "1" : "0"]"

/obj/machinery/bodyscanner/MouseDrop_T(mob/target, mob/user)
	if(user.incapacitated())
		return
	if(!user.IsAdvancedToolUser())
		to_chat(user, "<span class='warning'>Вы не можете понять, что с этим делать.</span>")
		return
	if(!move_inside_checks(target, user))
		return
	add_fingerprint(user)
	close_machine(target)
	playsound(src, 'sound/machines/analysis.ogg', VOL_EFFECTS_MASTER, null, FALSE)

/obj/machinery/bodyscanner/AltClick(mob/user)
	if(user.incapacitated() || !Adjacent(user))
		return
	if(!user.IsAdvancedToolUser())
		to_chat(user, "<span class='warning'>Вы не можете понять, что с этим делать.</span>")
		return
	if(occupant)
		open_machine()
		add_fingerprint(user)
		return
	var/mob/living/carbon/target = locate() in loc
	if(!target)
		return
	if(!move_inside_checks(target, user))
		return
	add_fingerprint(user)
	close_machine(target)
	playsound(src, 'sound/machines/analysis.ogg', VOL_EFFECTS_MASTER, null, FALSE)

/obj/machinery/bodyscanner/ex_act(severity)
	switch(severity)
		if(EXPLODE_HEAVY)
			if(prob(50))
				return
		if(EXPLODE_LIGHT)
			if(prob(75))
				return
	for(var/atom/movable/A in src)
		A.forceMove(loc)
		ex_act(severity)
	qdel(src)

/obj/machinery/bodyscanner/deconstruct(disassembled)
	for(var/atom/movable/A in src)
		A.forceMove(loc)
	..()

/obj/machinery/body_scanconsole/power_change()
	if(stat & BROKEN)
		icon_state = "body_scannerconsole-p"
	else if(powered())
		icon_state = initial(icon_state)
		stat &= ~NOPOWER
	else
		spawn(rand(0, 15))
			src.icon_state = "body_scannerconsole-p"
			stat |= NOPOWER
			update_power_use()
	update_power_use()

/obj/machinery/body_scanconsole
	var/obj/machinery/bodyscanner/connected
	var/known_implants = list(/obj/item/weapon/implant/chem, /obj/item/weapon/implant/death_alarm, /obj/item/weapon/implant/mind_protect/mindshield, /obj/item/weapon/implant/tracking, /obj/item/weapon/implant/mind_protect/loyalty, /obj/item/weapon/implant/obedience, /obj/item/weapon/implant/skill, /obj/item/weapon/implant/blueshield, /obj/item/weapon/implant/fake_loyal)
	var/delete
	name = "Body Scanner Console"
	icon = 'icons/obj/Cryogenic3.dmi'
	icon_state = "body_scannerconsole"
	anchored = TRUE
	var/next_print = 0
	var/storedinfo = null
	required_skills = list(/datum/skill/medical = SKILL_LEVEL_TRAINED)

/obj/machinery/body_scanconsole/atom_init()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/body_scanconsole/atom_init_late()
	connected = locate(/obj/machinery/bodyscanner) in orange(1, src)

/obj/machinery/body_scanconsole/ui_interact(mob/user)
	if(!ishuman(connected.occupant))
		to_chat(user, "<span class='warning'>Это устройство может сканировать только гуманоидные формы жизни.</span>")
		return
	if(!do_skill_checks(user))
		return
	var/dat

	if (src.connected) //Is something connected?
		var/mob/living/carbon/human/occupant = src.connected.occupant
		dat = "<font color='blue'><B>Информация о пациенте:</B></FONT><BR>" //Blah obvious
		if (istype(occupant)) //is there REALLY someone in there?
			var/t1
			switch(occupant.stat) // obvious, see what their status is
				if(0)
					t1 = "В сознании"
				if(1)
					t1 = "Без сознания"
				else
					t1 = "*Мёртв*"
			if (!ishuman(occupant))
				dat += "<font color='red'>Это устройство может сканировать только гуманоидных существ.</font>"
			else
				dat += text("<font color='[]'>\tЗдоровье %: [] ([])</font><BR>", (occupant.health > 50 ? "blue" : "red"), occupant.health, t1)

				if(ischangeling(occupant) && occupant.fake_death)
					dat += text("<font color='red'>Обнаружена аномальная биохимическая активность!</font><BR>")

				if(occupant.virus2.len)
					dat += text("<font color='red'>В кровотоке обнаружен вирусный патоген.</font><BR>")

				dat += text("<font color='[]'>\t-Механические %: []</font><BR>", (occupant.getBruteLoss() < 60 ? "blue" : "red"), occupant.getBruteLoss())
				dat += text("<font color='[]'>\t-Асфиксия %: []</font><BR>", (occupant.getOxyLoss() < 60 ? "blue" : "red"), occupant.getOxyLoss())
				dat += text("<font color='[]'>\t-Интоксикация %: []</font><BR>", (occupant.getToxLoss() < 60 ? "blue" : "red"), occupant.getToxLoss())
				dat += text("<font color='[]'>\t-Термические %: []</font><BR><BR>", (occupant.getFireLoss() < 60 ? "blue" : "red"), occupant.getFireLoss())

				dat += text("<font color='[]'>\tУровень облучения %: []</font><BR>", (occupant.radiation < 10 ?"blue" : "red"), occupant.radiation)
				dat += text("<font color='[]'>\tГенетическое повреждение тканей %: []</font><BR>", (occupant.getCloneLoss() < 1 ?"blue" : "red"), occupant.getCloneLoss())
				dat += text("<font color='[]'>\tПовреждение мозга %: []</font><BR>", (occupant.getBrainLoss() < 1 ?"blue" : "red"), occupant.getBrainLoss())
				var/occupant_paralysis = occupant.AmountParalyzed()
				dat += text("Парализован на %: [] (осталось [] секунд)<BR>", occupant_paralysis, round(occupant_paralysis / 4))
				dat += text("Температура тела: [occupant.bodytemperature-T0C]&deg;C ([occupant.bodytemperature*1.8-459.67]&deg;F)<BR><HR>")

				if(occupant.has_brain_worms())
					dat += "В лобной доле обнаружено новообразование, возможно злокачественное. Рекомендуется хирургическое вмешательство.<BR/>"

				var/blood_volume = occupant.blood_amount()
				var/blood_percent =  100.0 * blood_volume / BLOOD_VOLUME_NORMAL
				dat += text("<font color='[]'>\tУровень крови %: [] ([] юнитов)</font><BR>", (blood_volume >= BLOOD_VOLUME_SAFE ? "blue" : "red"), blood_percent, blood_volume)

				if(occupant.reagents)
					dat += text("Inaprovaline units: [] юнитов<BR>", occupant.reagents.get_reagent_amount("inaprovaline"))
					dat += text("Soporific (Sleep Toxin): [] юнитов<BR>", occupant.reagents.get_reagent_amount("stoxin"))
					dat += text("<font color='[]'>\tDermaline: [] юнитов</font><BR>", (occupant.reagents.get_reagent_amount("dermaline") < 30 ? "black" : "red"), occupant.reagents.get_reagent_amount("dermaline"))
					dat += text("<font color='[]'>\tBicaridine: [] юнитов</font><BR>", (occupant.reagents.get_reagent_amount("bicaridine") < 30 ? "black" : "red"), occupant.reagents.get_reagent_amount("bicaridine"))
					dat += text("<font color='[]'>\tDexalin: [] юнитов</font><BR>", (occupant.reagents.get_reagent_amount("dexalin") < 30 ? "black" : "red"), occupant.reagents.get_reagent_amount("dexalin"))

				dat += "<HR><A href='?src=\ref[src];print=1'>Распечатать отчет о состояние пациента</A><BR>"
				storedinfo = null
				dat += "<HR><table border='1'>"
				dat += "<tr>"
				dat += "<th>Часть тела</th>"
				dat += "<th>Термические</th>"
				dat += "<th>Механические</th>"
				dat += "<th>Другое</th>"
				dat += "</tr>"
				storedinfo += "<HR><table border='1'>"
				storedinfo += "<tr>"
				storedinfo += "<th>Часть тела</th>"
				storedinfo += "<th>Термические</th>"
				storedinfo += "<th>Механические</th>"
				storedinfo += "<th>Другое</th>"
				storedinfo += "</tr>"

				for(var/obj/item/organ/external/BP in occupant.bodyparts)

					dat += "<tr>"
					storedinfo += "<tr>"
					var/AN = ""
					var/open = ""
					var/infected = ""
					var/imp = ""
					var/bled = ""
					var/robot = ""
					var/splint = ""
					var/arterial_bleeding = ""
					var/rejecting = ""
					if(BP.status & ORGAN_ARTERY_CUT)
						arterial_bleeding = "<span class='red'><br><b>Артериальное кровотечение</b><br></span>"
					if(BP.status & ORGAN_SPLINTED)
						splint = "Наложена шина:"
					if(BP.status & ORGAN_BLEEDING)
						bled = "Кровотечение:"
					if(BP.status & ORGAN_BROKEN)
						AN = "[BP.broken_description]:"
					if(BP.is_robotic())
						robot = "Протез:"
					if(BP.open)
						open = "Вскрытое:"
					if(BP.is_rejecting)
						rejecting = "Генетическое отторжение:"
					switch (BP.germ_level)
						if (INFECTION_LEVEL_ONE to INFECTION_LEVEL_ONE_PLUS)
							infected = "Легкая инфекция:"
						if (INFECTION_LEVEL_ONE_PLUS to INFECTION_LEVEL_ONE_PLUS_PLUS)
							infected = "Легкая инфекция+:"
						if (INFECTION_LEVEL_ONE_PLUS_PLUS to INFECTION_LEVEL_TWO)
							infected = "Легкая инфекция++:"
						if (INFECTION_LEVEL_TWO to INFECTION_LEVEL_TWO_PLUS)
							infected = "Острая инфекция:"
						if (INFECTION_LEVEL_TWO_PLUS to INFECTION_LEVEL_TWO_PLUS_PLUS)
							infected = "Острая инфекция+:"
						if (INFECTION_LEVEL_TWO_PLUS_PLUS to INFECTION_LEVEL_THREE)
							infected = "Острая инфекция++:"
						if (INFECTION_LEVEL_THREE to INFINITY)
							infected = "Сепсис:"

					var/unknown_body = 0
					for(var/I in BP.implants)
						if(is_type_in_list(I,known_implants))
							imp += "[I] имплантирован:"
						else
							unknown_body++

					if(unknown_body || BP.hidden)
						imp += "Обнаружен инородный предмет:"
					if(!AN && !open && !infected && !imp)
						AN = "Не обнаружено:"
					if(!(BP.is_stump))
						var/burnDamText = BP.burn_dam > 0 ? "<span class='orange'>[BP.burn_dam]</span>" : "-/-"
						var/bruteDamText = BP.brute_dam > 0 ? "<span class='red'>[BP.brute_dam]</span>" : "-/-"
						dat += "<td>[BP.name]</td><td>[burnDamText]</td><td>[bruteDamText]</td><td>[robot][bled][AN][splint][open][infected][imp][arterial_bleeding][rejecting]</td>"
						storedinfo += "<td>[BP.name]</td><td>[burnDamText]</td><td>[bruteDamText]</td><td>[robot][bled][AN][splint][open][infected][imp][arterial_bleeding][rejecting]</td>"
					else
						dat += "<td>[parse_zone(BP.body_zone)]</td><td>-</td><td>-</td><td>Not Found</td>"
						storedinfo += "<td>[parse_zone(BP.body_zone)]</td><td>-</td><td>-</td><td>Not Found</td>"
					dat += "</tr>"
					storedinfo += "</tr>"
				for(var/missing_zone in occupant.get_missing_bodyparts())
					dat += "<tr>"
					storedinfo += "<tr>"
					dat += "<td>[parse_zone(missing_zone)]</td><td>-</td><td>-</td><td>Not Found</td>"
					storedinfo += "<td>[parse_zone(missing_zone)]</td><td>-</td><td>-</td><td>Not Found</td>"
					dat += "</tr>"
					storedinfo += "</tr>"
				for(var/obj/item/organ/internal/IO in occupant.organs)
					var/mech = "Органические:"
					var/organ_status = ""
					var/infection = ""
					if(IO.robotic == 1)
						mech = "Вспомогательные средства:"
					if(IO.robotic == 2)
						mech = "Механические:"

					if(istype(IO, /obj/item/organ/internal/heart))
						var/obj/item/organ/internal/heart/Heart = IO
						if(Heart.heart_status == HEART_FAILURE)
							organ_status = "Остановка сердца:"
						else if(Heart.heart_status == HEART_FIBR)
							organ_status = "Фибрилляция сердца:"

					if(istype(IO, /obj/item/organ/internal/lungs))
						if(occupant.is_lung_ruptured())
							organ_status = "Разрыв легкого:"

					switch (IO.germ_level)
						if (INFECTION_LEVEL_ONE to INFECTION_LEVEL_ONE_PLUS)
							infection = "Легкая инфекция:"
						if (INFECTION_LEVEL_ONE_PLUS to INFECTION_LEVEL_ONE_PLUS_PLUS)
							infection = "Легкая инфекция+:"
						if (INFECTION_LEVEL_ONE_PLUS_PLUS to INFECTION_LEVEL_TWO)
							infection = "Легкая инфекция++:"
						if (INFECTION_LEVEL_TWO to INFECTION_LEVEL_TWO_PLUS)
							infection = "Острая инфекция:"
						if (INFECTION_LEVEL_TWO_PLUS to INFECTION_LEVEL_TWO_PLUS_PLUS)
							infection = "Острая инфекция+:"
						if (INFECTION_LEVEL_TWO_PLUS_PLUS to INFECTION_LEVEL_THREE)
							infection = "Острая инфекция++:"
						if (INFECTION_LEVEL_THREE to INFINITY)
							infection = "Некроз:"

					if(!organ_status && !infection)
						infection = "Не обнаружено:"

					var/organ_damage_text = IO.damage > 0 ? "<span class='red'>[IO.damage]</span>" : "-/-"
					dat += "<tr>"
					dat += "<td>[IO.name]</td><td>N/A</td><td>[organ_damage_text]</td><td>[infection][organ_status]|[mech]</td><td></td>"
					dat += "</tr>"
					storedinfo += "<tr>"
					storedinfo += "<td>[IO.name]</td><td>N/A</td><td>[organ_damage_text]</td><td>[infection][organ_status]|[mech]</td><td></td>"
					storedinfo += "</tr>"
				dat += "</table>"
				storedinfo += "</table>"
				if(occupant.sdisabilities & BLIND)
					dat += text("<font color='red'>Обнаружена катаракта.</font><BR>")
					storedinfo += text("<font color='red'>Обнаружена катаракта.</font><BR>")
				if(HAS_TRAIT(occupant, TRAIT_NEARSIGHT))
					dat += text("<font color='red'>Обнаружено смещение сетчатки.</font><BR>")
					storedinfo += text("<font color='red'>Обнаружено смещение сетчатки.</font><BR>")
		else
			dat += "\The [src] is empty."
	else
		dat = "<font color='red'> Ошибка: Не подключен сканер тела.</font>"

	var/datum/browser/popup = new(user, "window=scanconsole", src.name, 530, 700, ntheme = CSS_THEME_LIGHT)
	popup.set_content(dat)
	popup.open()

/obj/machinery/body_scanconsole/Topic(href, href_list)
	. = ..()
	if(!.)
		return
	if(href_list["print"])
		if (next_print < world.time) //10 sec cooldown
			next_print = world.time + 10 SECONDS
			to_chat(usr, "<span class='notice'>Распечатка... Пожалуйста, подождите.</span>")
			playsound(src, 'sound/items/polaroid1.ogg', VOL_EFFECTS_MASTER, 20, FALSE)
			addtimer(CALLBACK(src, PROC_REF(print_scan), storedinfo), 1 SECOND)
		else
			to_chat(usr, "<span class='notice'>Консоль не может печатать так быстро!</span>")

/obj/machinery/body_scanconsole/proc/print_scan(additional_info)
	var/obj/item/weapon/paper/P = new(loc)
	if(!connected || !connected.occupant) // If while we were printing the occupant got out or our thingy did a boom.
		return
	var/mob/living/carbon/human/occupant = connected.occupant
	var/t1 = "<B>[occupant ? occupant.name : "Unknown"]'s</B> расширенный отчет сканера.<BR>"
	t1 += "Станционное время: <B>[worldtime2text()]</B><BR>"
	switch(occupant.stat) // obvious, see what their status is
		if(CONSCIOUS)
			t1 += "Status: <B>В сознании</B>"
		if(UNCONSCIOUS)
			t1 += "Status: <B>Без сознания</B>"
		else
			t1 += "Status: <B><span class='warning'>*Мёртв*</span></B>"
	t1 += additional_info
	P.info = t1
	P.name = "Результаты сканирования [occupant.name]"
	P.update_icon()

/obj/machinery/autodoc
	name = "improper autodoc medical system"
	desc = "A fancy machine developed to be capable of operating on people with some human intervention. However, the interface is rather complex and most of it would only be useful to trained medical personnel."
	icon = 'icons/obj/autodoc.dmi'
	icon_state = "bodyscanner"
	density = TRUE
	anchored = TRUE
	//coverage = 20
	//req_one_access = list(ACCESS_MARINE_MEDBAY, ACCESS_MARINE_CHEMISTRY, ACCESS_MARINE_MEDPREP)
	light_range = 1
	light_power = 0.5
//	light_color = LIGHT_COLOR_BLUE
	dir = EAST
	var/mob/living/carbon/human/occupant = null
	var/list/surgery_todo_list = list() //a list of surgeries to do.
//	var/surgery_t = 0 //Surgery timer in seconds.
	var/surgery = FALSE
	var/surgery_mod = 1 //What multiple to increase the surgery timer? This is used for any non-WO maps or events that are done.
	var/filtering = 0
	var/blood_transfer = 0
	var/heal_brute = 0
	var/heal_burn = 0
	var/heal_toxin = 0
	var/automaticmode = 0
	var/event = 0
	var/forceeject = FALSE

	var/obj/machinery/autodoc_console/connected

	//It uses power
	use_power = ACTIVE_POWER_USE
	idle_power_usage = 15
	active_power_usage = 120000 // It rebuilds you from nothing...

/obj/machinery/autodoc/atom_init()
	. = ..()
	update_icon()


/obj/machinery/bodyscanner/MouseDrop_T(mob/target, mob/user)
	close_machine(target)

/obj/machinery/autodoc/proc/go_out()
	for(var/i in contents)
		var/atom/movable/AM = i
		AM.forceMove(loc)
	occupant = null
	update_icon()

/obj/machinery/autodoc/Destroy()
	go_out()
	if(connected)
		connected.connected = null
		connected = null
	return ..()

/obj/machinery/autodoc/power_change()
	. = ..()
	if(is_operational() || !occupant)
		return
	visible_message("[src] engages the safety override, ejecting the occupant.")
	surgery = FALSE
	go_out()

/obj/machinery/autodoc/update_icon()
	. = ..()
	cut_overlays()
	if(stat & NOPOWER)
		set_light(0)
	else if(surgery || occupant)
		set_light(initial(light_range) + 1)
	else
		set_light(initial(light_range))
	var/mutable_appearance/appearance = mutable_appearance(icon, icon_state, ABOVE_LIGHTING_LAYER, ABOVE_LIGHTING_PLANE)
	//FLOAT_LAYER //appearance.color = GLOB.emissive_color
	add_overlay(appearance)

/obj/machinery/autodoc/process()
	if(!occupant)
		return

	if(occupant.stat == DEAD)
		//say("Patient has expired.")
		surgery = FALSE
		go_out()
		return

	if(!surgery)
		return

	// keep them alive
	var/updating_health = FALSE
	occupant.adjustToxLoss(-0.5) // pretend they get IV dylovene
	occupant.adjustOxyLoss(-occupant.getOxyLoss()) // keep them breathing, pretend they get IV dexalinplus
	if(filtering)
		var/filtered = 0
		for(var/datum/reagent/x in occupant.reagents.reagent_list)
			occupant.reagents.remove_reagent(x.type, 10) // same as sleeper, may need reducing
			filtered += 10
		if(!filtered)
			filtering = 0
			audible_message("<span class='warning'>Blood filtering complete.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
		else if(prob(10))
			visible_message("[src] whirrs and gurgles as the dialysis module operates.")
			to_chat(occupant, "<span class='info'>You feel slightly better.</span>")
	if(blood_transfer)
		audible_message("<span class='warning'>Blood reserves depleted, switching to fresh bag.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
		occupant.blood_add(8)
		if(prob(10))
			visible_message("[src] whirrs and gurgles as it tranfuses blood.")
			to_chat(occupant, "<span class='info'>You feel slightly less faint.</span>")
		else
			blood_transfer = 0
			audible_message("<span class='warning'>Blood transfer complete.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
	if(heal_brute)
		if(occupant.getBruteLoss() > 0)
			//occupant.heal_limb_damage(3, 0)
			updating_health = TRUE
			if(prob(10))
				visible_message("[src] whirrs and clicks as it stitches flesh together.")
				//to_chat(occupant, span_info("You feel your wounds being stitched and sealed shut."))
		else
			heal_brute = 0
			audible_message("<span class='warning'>Trauma repair surgery complete.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
	if(heal_burn)
		if(occupant.getFireLoss() > 0)
			occupant.heal_limb_damage(0, 3)
			updating_health = TRUE
			if(prob(10))
				visible_message("[src] whirrs and clicks as it grafts synthetic skin.")
				//to_chat(occupant, span_info("You feel your burned flesh being sliced away and replaced."))
		else
			heal_burn = 0
			audible_message("<span class='warning'>Skin grafts complete.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
	if(heal_toxin)
		if(occupant.getToxLoss() > 0)
			occupant.adjustToxLoss(-3)
			updating_health = TRUE
			if(prob(10))
				visible_message("[src] whirrs and gurgles as it kelates the occupant.")
				//to_chat(occupant, span_info("You feel slighly less ill."))
		else
			heal_toxin = 0
			audible_message("<span class='warning'>Chelation complete.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
	if(updating_health)
		occupant.updatehealth()

/obj/machinery/autodoc/proc/surgery_op()
	//This is called via href, let's avoid duplicate surgeries.
	if(surgery)
		return
	if(QDELETED(occupant) || occupant.stat == DEAD)
		if(!ishuman(occupant))
			stack_trace("Non-human occupant made its way into the autodoc: [occupant] | [occupant?.type].")
		visible_message("[src] buzzes.")
		go_out() //kick them out too.
		return

	visible_message("[src] begins to operate, the pod locking shut with a loud click.")
	surgery = TRUE
	update_icon()
	/*
	if(ADSURGERY_EYES)
		audible_message("<span class='warning'>Beginning corrective eye surgery.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
		if(S.unneeded)
			sleep(UNNEEDED_DELAY)
			audible_message("<span class='warning'>Procedure has been deemed unnecessary.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
			surgery_todo_list -= S
			continue
		if(istype(S.organ_ref,/datum/internal_organ/eyes))
			var/datum/internal_organ/eyes/E = S.organ_ref

			if(E.eye_surgery_stage == 0)
				sleep(EYE_CUT_MAX_DURATION)
				if(!surgery)
					break
				E.eye_surgery_stage = 1
				occupant.disabilities |= NEARSIGHTED // code\#define\mobs.dm

			if(E.eye_surgery_stage == 1)
				sleep(EYE_LIFT_MAX_DURATION)
				if(!surgery)
					break
				E.eye_surgery_stage = 2

			if(E.eye_surgery_stage == 2)
				sleep(EYE_MEND_MAX_DURATION)
				if(!surgery)
					break
				E.eye_surgery_stage = 3

			if(E.eye_surgery_stage == 3)
				sleep(EYE_CAUTERISE_MAX_DURATION)
				if(!surgery)
					break
				occupant.disabilities &= ~NEARSIGHTED
				occupant.disabilities &= ~BLIND
				E.heal_organ_damage(E.damage)
				E.eye_surgery_stage = 0
	*/
/obj/machinery/autodoc/proc/heal_arterial(obj/item/organ/external/BP)
	if(!(BP.status & ORGAN_ARTERY_CUT))
		return
	//open_incision(occupant, S.limb_ref)
	audible_message("<span class='warning'>Beginning internal bleeding procedure.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
	sleep(6 SECONDS)
	BP.status &= ~ORGAN_ARTERY_CUT
	//close_incision(occupant, S.limb_ref)

/obj/machinery/autodoc/proc/heal_broken_bp(obj/item/organ/external/BP)
	audible_message("<span class='warning'>Beginning broken bone procedure.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
	//open_incision(occupant, S.limb_ref)
	sleep(8 SECONDS)
	BP.status &= ~ORGAN_BROKEN
	BP.perma_injury = 0
	//close_incision(occupant, S.limb_ref)


/obj/machinery/autodoc/proc/heal_necrosis(obj/item/organ/external/BP)
	audible_message("<span class='warning'>Beginning necrotic tissue removal.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
	//open_incision(occupant, S.limb_ref)
	sleep(6 SECONDS)
	BP.status &= ~ORGAN_DEAD
	occupant.update_body()
	/*
	BP.open = 1
	BP.take_damage(1, 1, DAM_SHARP|DAM_EDGE, tool)
	BP.strap()
	*/
	//close_incision(occupant, S.limb_ref)
/obj/machinery/autodoc/proc/heal_shrapnel(obj/item/organ/external/BP)
	audible_message("<span class='warning'>Beginning foreign body removal.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
	//open_incision(occupant, S.limb_ref)
	//if(S.limb_ref.body_part == CHEST || S.limb_ref.body_part == HEAD)
	//	open_encased(occupant, S.limb_ref)
	for(var/obj/implanted_object in BP.implants)
		if(!istype(implanted_object,/obj/item/weapon/implant))	// We don't want to remove REAL implants. Just shrapnel etc.
			implanted_object.forceMove(BP.owner.loc)
			BP.implants -= implanted_object
			sleep(6 SECONDS)
		if(!surgery)
			break
	//if(S.limb_ref.body_part == CHEST || S.limb_ref.body_part == HEAD)
	//	close_encased(occupant, S.limb_ref)
	//close_incision(occupant, S.limb_ref)
/obj/machinery/autodoc/proc/heal_face(obj/item/organ/external/BP)
	if(!istype(BP, obj/item/organ/external/head))
		return
	audible_message("<span class='warning'>Beginning Facial Reconstruction Surgery.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "Next")
	BP.disfigured = 0
	sleep(6 SECONDS)





/obj/machinery/autodoc/proc/end_surgery()
	if(!surgery)
		return
	audible_message("<span class='warning'>Procedure complete.</span>", "<span class='notice'>You hear a quiet ping.</span>", world.view, list(), "End")
	visible_message("\The [src] clicks and opens up having finished the requested operations.")
	surgery = FALSE
	//go_out(AUTODOC_NOTICE_SUCCESS)


/obj/machinery/computer/autodoc_console
	name = "autodoc medical system control console"
	icon = 'icons/obj/machines/cryogenics.dmi'
	icon_state = "sleeperconsole"
	screen_overlay = "sleeperconsole_emissive"
	light_color = LIGHT_COLOR_EMISSIVE_RED
	req_one_access = list(ACCESS_MARINE_MEDBAY, ACCESS_MARINE_CHEMISTRY, ACCESS_MARINE_MEDPREP) //Valid access while locked
	density = FALSE
	idle_power_usage = 40
	dir = EAST
	var/obj/item/radio/headset/mainship/doc/radio
	var/obj/item/reagent_containers/blood/OMinus/blood_pack
	///connected autodoc
	var/obj/machinery/autodoc/connected = null

/obj/machinery/autodoc_console/interact(mob/user)
	. = ..()
	if(.)
		return

	var/dat = ""

	dat += "<hr><font color='#487553'><B>Occupant Statistics:</B></FONT><BR>"
	if(!connected.occupant)
		dat += "No occupant detected."
		var/datum/browser/popup = new(user, "autodoc", "<div align='center'>Autodoc Console</div>", 600, 600)
		popup.set_content(dat)
		popup.open()
		return

	var/t1
	switch(connected.occupant.stat)
		if(CONSCIOUS)
			t1 = "Conscious"
		if(UNCONSCIOUS)
			t1 = "<font color='#487553'>Unconscious</font>"
		if(DEAD)
			t1 = "<font color='#b54646'>*Dead*</font>"
	var/operating
	switch(connected.surgery)
		if(0)
			operating = "Not in surgery"
		if(1)
			operating = "<font color='#b54646'><B>SURGERY IN PROGRESS: MANUAL EJECTION ONLY TO BE ATTEMPTED BY TRAINED OPERATORS!</B></FONT>"
	dat += "[connected.occupant.health > 50 ? "<font color='#487553'>" : "<font color='#b54646'>"]\tHealth %: [round(connected.occupant.health)] ([t1])</FONT><BR>"
	var/pulse = connected.occupant.handle_pulse()
	dat += "[pulse == PULSE_NONE || pulse == PULSE_THREADY ? "<font color='#b54646'>" : "<font color='#487553'>"]\t-Pulse, bpm: [connected.occupant.get_pulse(GETPULSE_TOOL)]</FONT><BR>"
	dat += "[connected.occupant.getBruteLoss() < 60 ? "<font color='#487553'>" : "<font color='#b54646'>"]\t-Brute Damage %: [connected.occupant.getBruteLoss()]</FONT><BR>"
	dat += "[connected.occupant.getOxyLoss() < 60 ? "<font color='#487553'>" : "<font color='#b54646'>"]\t-Respiratory Damage %: [connected.occupant.getOxyLoss()]</FONT><BR>"
	dat += "[connected.occupant.getToxLoss() < 60 ? "<font color='#487553'>" : "<font color='#b54646'>"]\t-Toxin Content %: [connected.occupant.getToxLoss()]</FONT><BR>"
	dat += "[connected.occupant.getFireLoss() < 60 ? "<font color='#487553'>" : "<font color='#b54646'>"]\t-Burn Severity %: [connected.occupant.getFireLoss()]</FONT><BR>"

	dat += "<hr><a href='?src=[text_ref(src)];refresh=1'>Refresh Menu</a>"
	dat += "<hr><a href='?src=[text_ref(src)];ejectify=1'>Eject Patient</a>"
	if(!connected.surgery)
		if(connected.automaticmode)
			dat += "<hr>Manual Surgery Interface Unavaliable, Automatic Mode Engaged."
		else
			dat += "<hr>Manual Surgery Interface<hr>"
			dat += "<b>Trauma Surgeries</b>"
			dat += "<br>"
			if(isnull(surgeryqueue["brute"]))
				dat += "<a href='?src=[text_ref(src)];brute=1'>Surgical Brute Damage Treatment</a><br>"
			if(isnull(surgeryqueue["burn"]))
				dat += "<a href='?src=[text_ref(src)];burn=1'>Surgical Burn Damage Treatment</a><br>"
			dat += "<b>Orthopedic Surgeries</b>"
			dat += "<br>"
			if(isnull(surgeryqueue["broken"]))
				dat += "<a href='?src=[text_ref(src)];broken=1'>Broken Bone Surgery</a><br>"
			if(isnull(surgeryqueue["internal"]))
				dat += "<a href='?src=[text_ref(src)];internal=1'>Internal Bleeding Surgery</a><br>"
			if(isnull(surgeryqueue["shrapnel"]))
				dat += "<a href='?src=[text_ref(src)];shrapnel=1'>Foreign Body Removal Surgery</a><br>"
			if(isnull(surgeryqueue["missing"]))
				dat += "<a href='?src=[text_ref(src)];missing=1'>Limb Replacement Surgery</a><br>"
			dat += "<b>Organ Surgeries</b>"
			dat += "<br>"
			if(isnull(surgeryqueue["organdamage"]))
				dat += "<a href='?src=[text_ref(src)];organdamage=1'>Surgical Organ Damage Treatment</a><br>"
			if(isnull(surgeryqueue["organgerms"]))
				dat += "<a href='?src=[text_ref(src)];organgerms=1'>Organ Infection Treatment</a><br>"
			if(isnull(surgeryqueue["eyes"]))
				dat += "<a href='?src=[text_ref(src)];eyes=1'>Corrective Eye Surgery</a><br>"
			dat += "<b>Hematology Treatments</b>"
			dat += "<br>"
			if(isnull(surgeryqueue["blood"]))
				dat += "<a href='?src=[text_ref(src)];blood=1'>Blood Transfer</a><br>"
			if(isnull(surgeryqueue["toxin"]))
				dat += "<a href='?src=[text_ref(src)];toxin=1'>Toxin Damage Chelation</a><br>"
			if(isnull(surgeryqueue["dialysis"]))
				dat += "<a href='?src=[text_ref(src)];dialysis=1'>Dialysis</a><br>"
			if(isnull(surgeryqueue["necro"]))
				dat += "<a href='?src=[text_ref(src)];necro=1'>Necrosis Removal Surgery</a><br>"
			if(isnull(surgeryqueue["limbgerm"]))
				dat += "<a href='?src=[text_ref(src)];limbgerm=1'>Limb Disinfection Procedure</a><br>"
			dat += "<b>Special Surgeries</b>"
			dat += "<br>"
			if(isnull(surgeryqueue["facial"]))
				dat += "<a href='?src=[text_ref(src)];facial=1'>Facial Reconstruction Surgery</a><br>"
			if(isnull(surgeryqueue["open"]))
				dat += "<a href='?src=[text_ref(src)];open=1'>Close Open Incision</a><br>"

	var/datum/browser/popup = new(user, "autodoc", "<div align='center'>Autodoc Console</div>", 600, 600)
	popup.set_content(dat)
	popup.open()

/obj/machinery/autodoc_console/Topic(href, href_list)
	. = ..()
	if(.)
		return

	if(!connected)
		return

	if(href_list["ejectify"])
		connected.eject()

	if(!ishuman(connected.occupant))
		updateUsrDialog()
		return

	if(href_list["blood"])
		toggle_blood_transfer()

	if(href_list["eyes"])
		connected.surgery_op(eyes)
	/*
	if(href_list["organdamage"])
		var/list/choose_organ = list()
		for(var/i in connected.occupant.bodyparts)
			choose_organ += i
			for(var/x in L.internal_organs)
				var/datum/internal_organ/I = x
				if(I.robotic == ORGAN_ASSISTED || I.robotic == ORGAN_ROBOT)
					continue
				if(I.damage > 0)
					N.fields["autodoc_manual"] += create_autodoc_surgery(L,ORGAN_SURGERY,ADSURGERY_DAMAGE,0,I)
		connected.surgery_op()
	*/
	/*
	if(href_list["internal"])
		var/list/choose_organ = list()
		for(var/i in connected.occupant.bodyparts)
			var/datum/limb/L = i
			if(length(L.wounds))
				N.fields["autodoc_manual"] += create_autodoc_surgery(L,LIMB_SURGERY,ADSURGERY_INTERNAL)
		connected.surgery_op()
	*/
	/*
	if(href_list["broken"])
		var/list/choose_organ = list()
		for(var/i in connected.occupant.limbs)
			var/datum/limb/L = i
			if(L.limb_status & LIMB_BROKEN)
				N.fields["autodoc_manual"] += create_autodoc_surgery(L,LIMB_SURGERY,ADSURGERY_BROKEN)
		connected.surgery_op()
	*/
	if(href_list["necro"])
		for(var/i in connected.occupant.limbs)
			var/datum/limb/L = i
			if(L.limb_status & LIMB_NECROTIZED)
				N.fields["autodoc_manual"] += create_autodoc_surgery(L,LIMB_SURGERY,ADSURGERY_NECRO)

	if(href_list["shrapnel"])
		for(var/i in connected.occupant.limbs)
			var/datum/limb/L = i
			var/skip_embryo_check = FALSE
			var/obj/item/alien_embryo/A = locate() in connected.occupant
			for(var/I in L.implants)
				if(is_type_in_list(I, GLOB.known_implants))
					continue
				N.fields["autodoc_manual"] += create_autodoc_surgery(L, LIMB_SURGERY,ADSURGERY_SHRAPNEL)
				if(L.body_part == CHEST)
					skip_embryo_check = TRUE
			if(A && L.body_part == CHEST && !skip_embryo_check) //If we're not already doing a shrapnel removal surgery of the chest proceed.
				N.fields["autodoc_manual"] += create_autodoc_surgery(L, LIMB_SURGERY,ADSURGERY_SHRAPNEL)

	if(href_list["facial"])
		for(var/i in connected.occupant.limbs)
			var/datum/limb/L = i
			if(!istype(L, /datum/limb/head))
				continue
			var/datum/limb/head/J = L
			if(J.disfigured || J.face_surgery_stage)
				N.fields["autodoc_manual"] += create_autodoc_surgery(L, LIMB_SURGERY,ADSURGERY_FACIAL)
			else
				N.fields["autodoc_manual"] += create_autodoc_surgery(L, LIMB_SURGERY,ADSURGERY_FACIAL, 1)
			break

	if(href_list["open"])
		for(var/i in connected.occupant.limbs)
			var/datum/limb/L = i
			if(L.surgery_open_stage)
				N.fields["autodoc_manual"] += create_autodoc_surgery(L,LIMB_SURGERY,ADSURGERY_OPEN)
		if(href_list["open"])
			N.fields["autodoc_manual"] += create_autodoc_surgery(null,LIMB_SURGERY,ADSURGERY_OPEN,1)
	updateUsrDialog()
