#define VISION_PREPARE_TIME 30 MINUTES
#define VISION_CHOP_MONEY_NEEDED_TO_SAVE 10000
#define CHOP_VISION_TYPE "CHOP VISION"
#define VISION_OBJECTIVE_LOSS FALSE
#define VISION_OBJECTIVE_WIN TRUE

var/global/list/places_to_spawn_chop_vision = global.communications_list
var/global/list/intention_visions_types
var/global/list/intentional_vision_owner_by_type
var/global/list/successed_victorious_visions
var/global/list/previous_laws_vision_types
var/global/list/active_law_papers
var/global/list/active_chop_brains

/proc/get_job_name_by_stamp_type(stamp_type)
	if(stamp_type == /obj/item/weapon/stamp/cap) . = JOB_CAPTAIN
	else if(stamp_type == /obj/item/weapon/stamp/hop) . = JOB_HOP
	else if(stamp_type == /obj/item/weapon/stamp/sec/hos) . = JOB_HOS
	else if(stamp_type == /obj/item/weapon/stamp/eng/ce) . = JOB_CHIEF_ENGINEER
	else if(stamp_type == /obj/item/weapon/stamp/sci/rd) . = JOB_RD
	else if(stamp_type == /obj/item/weapon/stamp/med/cmo) . = JOB_CMO
	else . = null

/datum/job/qm/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, alt_title)
	. = ..()
	if(!islist(global.previous_laws_vision_types))
		return
	if(!(CHOP_VISION_TYPE in global.previous_laws_vision_types))
		return
	if(!islist(global.active_chop_brains))
		global.active_chop_brains = list()
	global.active_chop_brains += H.mind

/datum/job/cargo_tech/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, alt_title)
	. = ..()
	if(!islist(global.previous_laws_vision_types))
		return
	if(!(CHOP_VISION_TYPE in global.previous_laws_vision_types))
		return
	if(!islist(global.active_chop_brains))
		global.active_chop_brains = list()
	global.active_chop_brains += H.mind

/datum/job/mining/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, alt_title)
	. = ..()
	if(!islist(global.previous_laws_vision_types))
		return
	if(!(CHOP_VISION_TYPE in global.previous_laws_vision_types))
		return
	if(!islist(global.active_chop_brains))
		global.active_chop_brains = list()
	global.active_chop_brains += H.mind

/datum/job/recycler/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, alt_title)
	. = ..()
	if(!islist(global.previous_laws_vision_types))
		return
	if(!(CHOP_VISION_TYPE in global.previous_laws_vision_types))
		return
	if(!islist(global.active_chop_brains))
		global.active_chop_brains = list()
	global.active_chop_brains += H.mind

/obj/item/weapon/paper/weapons_for_gruztorg
	name = "Разрешение на работу ЧОП"
	info = {"<h1 style="text-align: center;"Разрешение на работу ЧОП></h1>
	<p>Данный документ подтверждает, что держатель документа (далее Сотрудник) является сотрудником охранного предприятия Карго.</p>
	<p>Сотрудник имеет право на владение и использование пистолета W&J PP и/или флешера и средств личной защиты в целях охраны активов Карго.</p>
	<p>При неправомерном применении спецсредств офицеры охраны имеют право изъять пистолет, флешер и средства личной защиты.</p>"}

/obj/item/weapon/paper/weapons_for_gruztorg/atom_init()
	. = ..()
	var/obj/item/weapon/stamp/centcomm/S = new
	S.stamp_paper(src, "CentComm Logistics Department")

/proc/equip_cargo_industries_by_arms(mob/user_reciever)
	var/mob/living/carbon/human/H = user_reciever
	H.equip_or_collect(new /obj/item/clothing/suit/armor/vest(H), SLOT_WEAR_SUIT)
	H.equip_or_collect(new /obj/item/weapon/paper/weapons_for_gruztorg(H), SLOT_IN_BACKPACK)
	if(H.get_species() != HUMAN)
		H.equip_or_collect(new /obj/item/device/flash(H), SLOT_IN_BACKPACK)
	else
		H.equip_or_collect(new /obj/item/weapon/gun/projectile/automatic/pistol/wjpp(H), SLOT_S_STORE)
		H.equip_or_collect(new /obj/item/ammo_box/magazine/wjpp/rubber(H), SLOT_IN_BACKPACK)
		H.equip_or_collect(new /obj/item/ammo_box/magazine/wjpp/rubber(H), SLOT_IN_BACKPACK)

/datum/outfit/job/qm/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(!islist(global.previous_laws_vision_types))
		return
	if(!(CHOP_VISION_TYPE in global.previous_laws_vision_types))
		return
	equip_cargo_industries_by_arms(H)

/datum/outfit/job/cargo_tech/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(!islist(global.previous_laws_vision_types))
		return
	if(!(CHOP_VISION_TYPE in global.previous_laws_vision_types))
		return
	equip_cargo_industries_by_arms(H)

/datum/outfit/job/mining/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(!islist(global.previous_laws_vision_types))
		return
	if(!(CHOP_VISION_TYPE in global.previous_laws_vision_types))
		return
	equip_cargo_industries_by_arms(H)

/datum/outfit/job/recycler/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(!islist(global.previous_laws_vision_types))
		return
	if(!(CHOP_VISION_TYPE in global.previous_laws_vision_types))
		return
	equip_cargo_industries_by_arms(H)

/proc/is_vision_succession_true(type)
	if(type != CHOP_VISION_TYPE)
		return VISION_OBJECTIVE_LOSS
	//Case 1
	if(global.cargo_account.money < VISION_CHOP_MONEY_NEEDED_TO_SAVE)
		return VISION_OBJECTIVE_LOSS
	//Case 2
	if(!islist(global.active_chop_brains))
		return VISION_OBJECTIVE_LOSS
	var/mob/chop_holder = null
	for(var/datum/mind/M as anything in global.active_chop_brains)
		if(QDELETED(M))
			continue
		if(iscarbon(M.current))
			var/mob/living/carbon/C = M.current
			if(C.restrained())
				continue
		var/turf/location = get_turf(M.current.loc)
		if(!location)
			continue
		var/area/check_area = location.loc
		if(!istype(check_area, /area/shuttle/escape/centcom))
			continue
		chop_holder = M.current
	//at least 1 man for keeping law true
	if(isnull(chop_holder))
		return VISION_OBJECTIVE_LOSS
	// law paper needs stamps or signs of heads to decline law
	for(var/obj/item/weapon/paper/active_law_paper/P as anything in global.active_law_papers)
		if(QDELETED(P))
			continue
		if(P.is_law_decline_fullfill())
			return VISION_OBJECTIVE_LOSS

	return VISION_OBJECTIVE_WIN

/proc/is_completion_of_vision_success(type)
	if(type != CHOP_VISION_TYPE)
		return VISION_OBJECTIVE_LOSS
	//copypaste Escape on the shuttle objective
	var/mob/living/carbon/human/owner_vision = intentional_vision_owner_by_type[CHOP_VISION_TYPE]
	var/datum/mind/owner = owner_vision.mind
	if(QDELETED(owner_vision))
		return VISION_OBJECTIVE_LOSS
	if(issilicon(owner.current))
		return VISION_OBJECTIVE_LOSS
	if(!owner.current || owner.current.stat == DEAD)
		return VISION_OBJECTIVE_LOSS
	var/turf/location = get_turf(owner.current.loc)
	if(!location)
		return VISION_OBJECTIVE_LOSS
	if(iscarbon(owner.current))
		var/mob/living/carbon/C = owner.current
		if(C.restrained())
			return VISION_OBJECTIVE_LOSS
	var/area/check_area = location.loc
	if(!istype(check_area, /area/shuttle/escape/centcom))
		return VISION_OBJECTIVE_LOSS
	var/obj/item/weapon/paper/vision/V = locate(/obj/item/weapon/paper/vision, get_turf(owner_vision))
	if(isnull(V))
		return VISION_OBJECTIVE_LOSS
	if(type != V.type_of_vision)
		return VISION_OBJECTIVE_LOSS
	return VISION_OBJECTIVE_WIN

//for ticker
/proc/try_success_vision()
	if(islist(global.intention_visions_types))
		for(var/declared_vision in global.intention_visions_types)
			var/we_get_goal = global.is_completion_of_vision_success(declared_vision)
			if(!we_get_goal)
				continue
			if(!islist(global.successed_victorious_visions))
				global.successed_victorious_visions = list()
			global.successed_victorious_visions += declared_vision

	if(islist(global.previous_laws_vision_types))
		for(var/already_active_law_vision in global.previous_laws_vision_types)
			var/we_get_goal = global.is_vision_succession_true(already_active_law_vision)
			if(we_get_goal)
				continue
			global.previous_laws_vision_types -= already_active_law_vision

/proc/chop_declared(mob/user, obj/item/weapon/paper/vision/task)
	to_chat(world, "[task.type_of_vision] ACTIVATE BY [user]")

	if(!islist(global.intention_visions_types))
		global.intention_visions_types = list()
	global.intention_visions_types += task.type_of_vision

	if(!islist(global.intentional_vision_owner_by_type))
		global.intentional_vision_owner_by_type[0] = list()
	global.intentional_vision_owner_by_type[task.type_of_vision] = user

/obj/item/weapon/paper/vision
	name = "Vision of CHOP"
	var/type_of_vision = CHOP_VISION_TYPE

/obj/item/weapon/paper/vision/proc/called_chop(mob/user)

	global.chop_declared(user, src)

/obj/item/weapon/paper/active_law_paper
	var/rejecting_votes_needed = 3
	var/list/disaproves_headstuffs_job_list = list()
	var/list/decline_stamp_headstuffs_type_list = list()
	var/static/list/acceptable_type_stamps_for_declining = list(/obj/item/weapon/stamp/cap,
																/obj/item/weapon/stamp/hop,
																/obj/item/weapon/stamp/sec/hos,
																/obj/item/weapon/stamp/eng/ce,
																/obj/item/weapon/stamp/sci/rd,
																/obj/item/weapon/stamp/med/cmo)

/obj/item/weapon/paper/active_law_paper/proc/make_disaprove_to_vision(mob/user)
	var/datum/job/user_job = SSjob.GetJob(user.mind.assigned_role)
	if(isnull(user_job))
		return
	if(!(user_job in SSjob.heads_positions))
		return
	if(user_job in disaproves_headstuffs_job_list)
		return
	disaproves_headstuffs_job_list += user_job

/obj/item/weapon/paper/active_law_paper/proc/make_decline_by_stamp_to_vision(mob/user, obj/item/weapon/stamp/used_stamp)
	if(acceptable_type_stamps_for_declining.len > 1)
		if(!(used_stamp.type in acceptable_type_stamps_for_declining))
			return
	if(used_stamp.type in decline_stamp_headstuffs_type_list)
		return
	decline_stamp_headstuffs_type_list += used_stamp.type

/obj/item/weapon/paper/active_law_paper/proc/is_law_decline_fullfill()
	if(disaproves_headstuffs_job_list.len > rejecting_votes_needed)
		return TRUE
	if(decline_stamp_headstuffs_type_list.len > rejecting_votes_needed)
		return TRUE
	//check sum of signs and stamps on vision
	var/list/rejected_votes_from_headstuff_by_jobname = list()
	for(var/stamp in decline_stamp_headstuffs_type_list)
		var/jobname_string = get_job_name_by_stamp_type(stamp)
		if(isnull(jobname_string))
			continue
		rejected_votes_from_headstuff_by_jobname += jobname_string

	for(var/datum/job/job as anything in disaproves_headstuffs_job_list)
		if(job.title in rejected_votes_from_headstuff_by_jobname)
			continue
		rejected_votes_from_headstuff_by_jobname += job.title

	if(rejected_votes_from_headstuff_by_jobname >= rejecting_votes_needed)
		return TRUE
	return FALSE


/obj/machinery/computer/communications/proc/get_info_about_visions()
	if(!islist(global.previous_laws_vision_types))
		return
	for(var/law in global.previous_laws_vision_types)
		if(law == CHOP_VISION_TYPE)
			var/obj/item/weapon/paper/active_law_paper/P = new(loc)
			P.info = "Chop on the station"
			//P.update_icon()
			global.active_law_papers += P

/obj/machinery/computer/communications/atom_init()
	. = ..()
	get_info_about_visions()

/obj/machinery/computer/communications/attackby(obj/item/W, mob/user, params)
	. = ..()
	ask_chop(user)

/obj/machinery/computer/communications/proc/ask_chop(mob/user)
	if(world.has_round_finished())
		to_chat(user, "Its round end")
		return
	if(world.is_round_preparing())
		to_chat(user, "No round yet")
		return
	if(SSshuttle.online || SSshuttle.location != 0)
		to_chat(user, "Шаттл используется")
		return
	if(world.time > VISION_PREPARE_TIME)
		to_chat(user, "COUNCIL ON THE VACATION")
		return
	//show everyone copy of vision
	for(var/obj/machinery/computer/communications/C in global.places_to_spawn_chop_vision)
		if(C.stat & (BROKEN | NOPOWER))
			continue
		var/obj/item/weapon/paper/vision/V = new(C.loc)
		V.info = "CHOP IS CALLED"
		//V.update_icon()
	//let him cook with original paper
	var/obj/item/weapon/paper/vision/P = new(user.loc)
	user.put_in_hands(P)
	P.called_chop(user)
	P.info = "CHOP IS CALLED"
	//P.update_icon()



// The communications computer
/obj/machinery/computer/communications
	name = "Communications Console"
	cases = list("консоль коммуникаций", "консоли коммуникаций", "консоли коммуникаций", "консоль коммуникаций", "консолью коммуникаций", "консоли коммуникаций")
	desc = "Эта консоль обладает важным функционалом по управлению станцией."
	icon_state = "comm"
	light_color = "#0099ff"
	req_access = list(access_heads)
	circuit = /obj/item/weapon/circuitboard/communications
	allowed_checks = ALLOWED_CHECK_NONE
	var/prints_intercept = 1
	var/authenticated = 0
	var/list/messagetitle = list()
	var/list/messagetext = list()
	var/currmsg = 0
	var/aicurrmsg = 0
	var/state = STATE_DEFAULT
	var/aistate = STATE_DEFAULT
	var/message_cooldown = 0
	var/centcomm_message_cooldown = 0
	var/tmp_alertlevel = 0
	var/last_seclevel_change = 0 // prevents announcement sounds spam
	var/last_announcement = 0    // ^ ^ ^
	var/const/STATE_DEFAULT = 1
	var/const/STATE_CALLSHUTTLE = 2
	var/const/STATE_CANCELSHUTTLE = 3
	var/const/STATE_MESSAGELIST = 4
	var/const/STATE_VIEWMESSAGE = 5
	var/const/STATE_DELMESSAGE = 6
	var/const/STATE_STATUSDISPLAY = 7
	var/const/STATE_ALERT_LEVEL = 8
	var/const/STATE_CONFIRM_LEVEL = 9
	var/const/STATE_CREWTRANSFER = 10

	var/status_display_freq = "1435"
	var/stat_msg1
	var/stat_msg2

	var/datum/announcement/station/command/announcement = new

	required_skills = list(/datum/skill/command = SKILL_LEVEL_PRO)

/obj/machinery/computer/communications/atom_init()
	. = ..()
	communications_list += src

/obj/machinery/computer/communications/Destroy()
	communications_list -= src

	for(var/obj/machinery/computer/communications/commconsole in communications_list)
		if(istype(commconsole.loc, /turf))
			return ..()

	for(var/obj/item/weapon/circuitboard/communications/commboard in circuitboard_communications_list)
		if(istype(commboard.loc,/turf) || istype(commboard.loc,/obj/item/weapon/storage))
			return ..()

	for(var/mob/living/silicon/ai/shuttlecaller as anything in ai_list)
		if(shuttlecaller.stat == CONSCIOUS && shuttlecaller.client && istype(shuttlecaller.loc,/turf))
			return ..()

	if(sent_strike_team)
		return ..()

	SSshuttle.incall(2)
	log_game("All the AIs, comm consoles and boards are destroyed. Shuttle called.")
	message_admins("All the AIs, comm consoles and boards are destroyed. Shuttle called.")
	SSshuttle.announce_emer_called.play()

	return ..()

/obj/machinery/computer/communications/attackby(obj/item/W, mob/user, params)
	. = ..()
	try_log_in(W, user)

/obj/machinery/computer/communications/proc/try_log_in(obj/item/A, mob/user)
	var/obj/item/weapon/card/id/I
	if(A)
		if(!istype(A, /obj/item/weapon/card/id))
			return FALSE
		I = A
	else
		I = user.get_active_hand()
		if(istype(I, /obj/item/device/pda))
			var/obj/item/device/pda/pda = I
			I = pda.id
		if(!istype(I))
			return FALSE
	if(check_access(I))
		authenticated = 1
	if((access_captain in I.access) || (access_hop in I.access) || (access_hos in I.access))
		authenticated = 2
	return TRUE

/obj/machinery/computer/communications/Topic(href, href_list)
	. = ..()
	if(!.)
		return

	if (!is_station_level(z))
		to_chat(usr, "<span class='warning'><b>Невозможно установить соединение</b>:</span> Вы слишком далеко от станции!")
		return FALSE
	if(!href_list["operation"])
		return FALSE

	var/obj/item/weapon/circuitboard/communications/CM = circuit
	switch(href_list["operation"])
		// main interface
		if("main")
			src.state = STATE_DEFAULT
		if("login")
			var/mob/M = usr
			if(isobserver(M))
				authenticated = 2
			else
				if(!try_log_in(null, M))
					if(iscarbon(M))
						var/mob/living/carbon/C = M
						try_log_in(C.get_slot_ref(SLOT_WEAR_ID), C)
			updateUsrDialog()
			return
		if("logout")
			authenticated = 0

		if("swipeidseclevel")
			var/mob/M = usr
			var/obj/item/weapon/card/id/I = M.get_active_hand()
			if(last_seclevel_change > world.time)
				to_chat(usr, "<span class='warning'>Красный индикатор загорелся на консоли. Вероятно, вы не можете сменить код тревоги так быстро!</span>")
				return
			else
				last_seclevel_change = world.time + 1 MINUTE
			if (istype(I, /obj/item/device/pda))
				var/obj/item/device/pda/pda = I
				I = pda.id
			if (I && istype(I))
				if(access_heads in I.access) //Let heads change the alert level.
					var/old_level = security_level
					if(!tmp_alertlevel) tmp_alertlevel = SEC_LEVEL_GREEN
					if(tmp_alertlevel < SEC_LEVEL_GREEN) tmp_alertlevel = SEC_LEVEL_GREEN
					if(tmp_alertlevel > SEC_LEVEL_BLUE) tmp_alertlevel = SEC_LEVEL_BLUE //Cannot engage delta with this
					set_security_level(tmp_alertlevel)
					if(security_level != old_level)
						//Only notify the admins if an actual change happened
						log_game("[key_name(usr)] has changed the security level to [code_name_eng[security_level]].")
						message_admins("[key_name_admin(usr)] has changed the security level to [code_name_eng[security_level]]. [ADMIN_JMP(usr)]")
						switch(security_level)
							if(SEC_LEVEL_GREEN)
								feedback_inc("alert_comms_green",1)
							if(SEC_LEVEL_BLUE)
								feedback_inc("alert_comms_blue",1)
					tmp_alertlevel = 0
				else
					to_chat(usr, "У вас недостаточно прав для выполнения этой операции!")
					tmp_alertlevel = 0
				state = STATE_DEFAULT
			else
				to_chat(usr, "Проведите своей ID-картой.")

		if("announce")
			if(src.authenticated == 2)
				if(last_announcement > world.time)
					to_chat(usr, "<span class='warning'>На консоли мигает красный индикатор. Вероятно, вы не можете делать оповещения так быстро!</span>")
					return
				else
					last_announcement = world.time + 1 MINUTE
				var/input = sanitize(input(usr, "Передайте оповещение, которое прозвучит на всю станцию.", "Приоритетное оповещение") as null|message, extra = FALSE)
				if(!input || !(usr in view(1,src)))
					return
				announcement.play(input) //This should really tell who is, IE HoP, CE, HoS, RD, Captain
				log_say("[key_name(usr)] has made a captain announcement: [input]")
				message_admins("[key_name_admin(usr)] has made a captain announcement. [ADMIN_JMP(usr)]")

		if("callshuttle")
			src.state = STATE_DEFAULT
			if(src.authenticated)
				src.state = STATE_CALLSHUTTLE
		if("callshuttle2")
			if(src.authenticated)
				call_shuttle_proc(usr)
				if(SSshuttle.online)
					post_status("shuttle")
			src.state = STATE_DEFAULT
		if("cancelshuttle")
			src.state = STATE_DEFAULT
			if(src.authenticated)
				src.state = STATE_CANCELSHUTTLE
		if("cancelshuttle2")
			if(src.authenticated)
				cancel_call_proc(usr)
			src.state = STATE_DEFAULT
		if("messagelist")
			src.currmsg = 0
			src.state = STATE_MESSAGELIST
		if("viewmessage")
			src.state = STATE_VIEWMESSAGE
			if (!src.currmsg)
				if(href_list["message-num"])
					src.currmsg = text2num(href_list["message-num"])
				else
					src.state = STATE_MESSAGELIST
		if("delmessage")
			src.state = (src.currmsg) ? STATE_DELMESSAGE : STATE_MESSAGELIST
		if("delmessage2")
			if(src.authenticated)
				if(src.currmsg)
					var/title = src.messagetitle[src.currmsg]
					var/text  = src.messagetext[src.currmsg]
					messagetitle.Remove(title)
					messagetext.Remove(text)
					if(src.currmsg == src.aicurrmsg)
						src.aicurrmsg = 0
					src.currmsg = 0
				src.state = STATE_MESSAGELIST
			else
				src.state = STATE_VIEWMESSAGE
		if("status")
			src.state = STATE_STATUSDISPLAY

		// Status display stuff
		if("setstat")
			switch(href_list["statdisp"])
				if("message")
					post_status("message", stat_msg1, stat_msg2)
				if("alert")
					post_status("alert", href_list["alert"])
				if("default")
					post_status("default")
				else
					post_status(href_list["statdisp"])

		if("setmsg1")
			stat_msg1 = sanitize(input("Линия 1", "Введите текст оповещения", stat_msg1) as text|null, MAX_LNAME_LEN)
			updateDialog()
		if("setmsg2")
			stat_msg2 = sanitize(input("Линия 2", "Введите текст оповещения", stat_msg2) as text|null, MAX_LNAME_LEN)
			updateDialog()

		// OMG CENTCOMM LETTERHEAD
		if("MessageCentcomm")
			if(src.authenticated==2)
				if(CM.cooldown)
					to_chat(usr, "<span class='warning'>Рекалибровка систем связи. Пожалуйста, подождите.</span>")
					return
				var/input = sanitize(input(usr, "Передайте оповещение Центкому через квантовую связь. Этот процесс является крайне затратным, потому злоупотребление им приведёт к вашему... увольнению. Передача сообщения не гарантирует ответ. Между сообщениями есть промежуток в 30 секунд, поэтому они должны содержать полную информацию.", "Чтобы отменить, отправьте пустое сообщение.", ""))
				if(!input || !(usr in view(1,src)))
					return
				Centcomm_announce(input, usr)
				to_chat(usr, "<span class='notice'>Сообщение отправлено.</span>")
				log_say("[key_name(usr)] has made an IA Centcomm announcement: [input]")
				CM.cooldown = 55


		// OMG SYNDICATE ...LETTERHEAD
		if("MessageSyndicate")
			if((src.authenticated==2) && (src.emagged))
				if(CM.cooldown)
					to_chat(usr, "<span class='warning'>Обработка информации. Ожидайте.</span>")
					return
				var/input = sanitize(input(usr, "Передайте оповещение \[НЕИЗВЕСТНЫМ\] через систему квантовой связи. Эта передача является крайне затратной, потому злоупотребление ею приведёт к... расторжению контракта. Передача сообщения не гарантирует ответ. Между сообщениями есть промежуток в 30 секунд, поэтому они должны содержать полную информацию.", "Чтобы отменить, отправьте пустое сообщение.", ""))
				if(!input || !(usr in view(1,src)))
					return
				Syndicate_announce(input, usr)
				to_chat(usr, "<span class='notice'>Сообщение отправлено!</span>")
				log_say("[key_name(usr)] has made a Syndicate announcement: [input]")
				CM.cooldown = 55 //about one minute

		if("RestoreBackup")
			to_chat(usr, "Резервные данные маршрутизации восстановлены!")
			src.emagged = 0
			updateDialog()



		// AI interface
		if("ai-main")
			src.aicurrmsg = 0
			src.aistate = STATE_DEFAULT
		if("ai-callshuttle")
			src.aistate = STATE_CALLSHUTTLE
		if("ai-callshuttle2")
			call_shuttle_proc(usr)
			src.aistate = STATE_DEFAULT
		if("ai-messagelist")
			src.aicurrmsg = 0
			src.aistate = STATE_MESSAGELIST
		if("ai-viewmessage")
			src.aistate = STATE_VIEWMESSAGE
			if (!src.aicurrmsg)
				if(href_list["message-num"])
					src.aicurrmsg = text2num(href_list["message-num"])
				else
					src.aistate = STATE_MESSAGELIST
		if("ai-delmessage")
			src.aistate = (src.aicurrmsg) ? STATE_DELMESSAGE : STATE_MESSAGELIST
		if("ai-delmessage2")
			if(src.aicurrmsg)
				var/title = src.messagetitle[src.aicurrmsg]
				var/text  = src.messagetext[src.aicurrmsg]
				messagetitle.Remove(title)
				messagetext.Remove(text)
				if(src.currmsg == src.aicurrmsg)
					src.currmsg = 0
				src.aicurrmsg = 0
			src.aistate = STATE_MESSAGELIST
		if("ai-status")
			src.aistate = STATE_STATUSDISPLAY

		if("securitylevel")
			src.tmp_alertlevel = text2num( href_list["newalertlevel"] )
			if(!tmp_alertlevel) tmp_alertlevel = 0
			state = STATE_CONFIRM_LEVEL

		if("changeseclevel")
			state = STATE_ALERT_LEVEL
	updateUsrDialog()

/obj/machinery/computer/communications/emag_act(mob/user)
	if(emagged)
		return FALSE
	src.emagged = 1
	to_chat(user, "Вы шифруете схемы маршрутизации связи!")
	return TRUE

/obj/machinery/computer/communications/ui_interact(mob/user)
	if (!SSmapping.has_level(z))
		to_chat(user, "<span class='warning'><b>Невозможно установить соединение</b>:</span> Вы слишком далеко от станции!")
		return

	var/dat = ""
	if (SSshuttle.online && SSshuttle.location == 0)
		dat += "<B>Аварийный шаттл</B>\n<BR>\nРасчетное время прибытия [shuttleeta2text()]<BR>"

	if (issilicon(user))
		var/dat2 = interact_ai(user) // give the AI a different interact proc to limit its access
		if(dat2)
			dat += dat2
			var/datum/browser/popup = new(user, "communications", "Коммуникационная консоль", 400, 500)
			popup.set_content(dat)
			popup.open()
		return

	switch(src.state)
		if(STATE_DEFAULT)
			if (src.authenticated)
				dat += "<BR><A href='byond://?src=\ref[src];operation=logout'>Выйти из системы</A>"
				if (src.authenticated==2)
					dat += "<BR><A href='byond://?src=\ref[src];operation=announce'>Сделать оповещение</A>"
					if(src.emagged == 0)
						dat += "<BR><A href='byond://?src=\ref[src];operation=MessageCentcomm'>Отправить экстренное сообщение Центкому</A>"
					else
						dat += "<BR><A href='byond://?src=\ref[src];operation=MessageSyndicate'>Отправить экстренное сообщение \[НЕИЗВЕСТНО\]</A>"
						dat += "<BR><A href='byond://?src=\ref[src];operation=RestoreBackup'>Восстановить резервные данные маршрутизации</A>"

				dat += "<BR><A href='byond://?src=\ref[src];operation=changeseclevel'>Сменить код тревоги</A>"
				if(SSshuttle.location==0)
					if (SSshuttle.online)
						dat += "<BR><A href='byond://?src=\ref[src];operation=cancelshuttle'>Отменить вызов шаттла</A>"
					else
						dat += "<BR><A href='byond://?src=\ref[src];operation=callshuttle'>Вызвать экстренный шаттл</A>"

				dat += "<BR><A href='byond://?src=\ref[src];operation=status'>Установить статус дисплея</A>"
			else
				dat += "<BR><A href='byond://?src=\ref[src];operation=login'>Авторизоваться</A>"
			dat += "<BR><A href='byond://?src=\ref[src];operation=messagelist'>Список сообщений</A>"
		if(STATE_CALLSHUTTLE)
			dat += "Вы уверены, что хотите вызвать шаттл? <A href='byond://?src=\ref[src];operation=callshuttle2'>ДА</A> | <A href='byond://?src=\ref[src];operation=main'>НЕТ</A>"
		if(STATE_CANCELSHUTTLE)
			dat += "Вы уверены, что хотите отозвать шаттл? <A href='byond://?src=\ref[src];operation=cancelshuttle2'>ДА</A> | <A href='byond://?src=\ref[src];operation=main'>НЕТ</A>"
		if(STATE_MESSAGELIST)
			dat += "Сообщения:"
			for(var/i = 1; i<=src.messagetitle.len; i++)
				dat += "<BR><A href='byond://?src=\ref[src];operation=viewmessage;message-num=[i]'>[src.messagetitle[i]]</A>"
		if(STATE_VIEWMESSAGE)
			if (src.currmsg)
				dat += "<B>[src.messagetitle[src.currmsg]]</B><BR><BR>[src.messagetext[src.currmsg]]"
				if (src.authenticated)
					dat += "<BR><BR><A href='byond://?src=\ref[src];operation=delmessage'>Удалить"
			else
				src.state = STATE_MESSAGELIST
				attack_hand(user)
				return
		if(STATE_DELMESSAGE)
			if (src.currmsg)
				dat += "Вы уверены, что хотите удалить это сообщение? <A href='byond://?src=\ref[src];operation=delmessage2'>ДА</A> | <A href='byond://?src=\ref[src];operation=viewmessage'>НЕТ</A>"
			else
				src.state = STATE_MESSAGELIST
				attack_hand(user)
				return
		if(STATE_STATUSDISPLAY)
			dat += "Установить текст на дисплеях<BR>"
			dat += "<A href='byond://?src=\ref[src];operation=setstat;statdisp=blank'>Очистить</A><BR>"
			dat += "<A href='byond://?src=\ref[src];operation=setstat;statdisp=default'>По умолчанию</A><BR>"
			dat += "<A href='byond://?src=\ref[src];operation=setstat;statdisp=shuttle'>Расчетное время до прибытия шаттла</A><BR>"
			dat += "<A href='byond://?src=\ref[src];operation=setstat;statdisp=message'>Сообщение</A>"
			dat += "<ul><li> Линия 1: <A href='byond://?src=\ref[src];operation=setmsg1'>[ stat_msg1 ? stat_msg1 : "(none)"]</A>"
			dat += "<li> Линия 2: <A href='byond://?src=\ref[src];operation=setmsg2'>[ stat_msg2 ? stat_msg2 : "(none)"]</A></ul><br>"
			dat += " Alert: <A href='byond://?src=\ref[src];operation=setstat;statdisp=alert;alert=redalert'>Красный код тревоги</A> |"
			dat += " <A href='byond://?src=\ref[src];operation=setstat;statdisp=alert;alert=lockdown'>Карантин</A> |"
			dat += " <A href='byond://?src=\ref[src];operation=setstat;statdisp=alert;alert=biohazard'>Биологическая угроза</A><BR><HR>"
		if(STATE_ALERT_LEVEL)
			dat += "Текущий код тревоги: [code_name_ru[security_level]]<BR>"
			if(security_level == SEC_LEVEL_DELTA)
				dat += "<font color='red'><b>Активирован механизм самоуничтожения. Деактивируйте механизм для снижения кода или эвакуируйтесь.</b></font>"
			else
				dat += "<A href='byond://?src=\ref[src];operation=securitylevel;newalertlevel=[SEC_LEVEL_BLUE]'>Синий</A><BR>"
				dat += "<A href='byond://?src=\ref[src];operation=securitylevel;newalertlevel=[SEC_LEVEL_GREEN]'>Зелёный</A>"
		if(STATE_CONFIRM_LEVEL)
			dat += "Текущий код тревоги: [code_name_ru[security_level]]<BR>"
			dat += "Подтвердить смену кода тревоги на: [code_name_ru[tmp_alertlevel]]<BR>"
			dat += "<A href='byond://?src=\ref[src];operation=swipeidseclevel'>Проведите ID-картой</A> для смены кода.<BR>"

	dat += "<BR>[(src.state != STATE_DEFAULT) ? "<A href='byond://?src=\ref[src];operation=main'>Главное меню</A> | " : ""]"

	var/datum/browser/popup = new(user, "communications", "Коммуникационная консоль", 400, 500)
	popup.set_content(dat)
	popup.open()


/obj/machinery/computer/communications/proc/interact_ai(mob/living/silicon/ai/user)
	var/dat = ""
	switch(src.aistate)
		if(STATE_DEFAULT)
			if(SSshuttle.location==0 && !SSshuttle.online)
				dat += "<BR><A href='byond://?src=\ref[src];operation=ai-callshuttle'>Вызвать экстренный шаттл</A>"
			dat += "<BR><A href='byond://?src=\ref[src];operation=ai-messagelist'>Список сообщений</A>"
			dat += "<BR><A href='byond://?src=\ref[src];operation=ai-status'>Установить текст на дисплеях</A>"
		if(STATE_CALLSHUTTLE)
			dat += "Вы уверены, что хотите вызвать экстренный шаттл? <A href='byond://?src=\ref[src];operation=ai-callshuttle2'>ДА</A> | <A href='byond://?src=\ref[src];operation=ai-main'>НЕТ</A>"
		if(STATE_MESSAGELIST)
			dat += "Messages:"
			for(var/i = 1; i<=src.messagetitle.len; i++)
				dat += "<BR><A href='byond://?src=\ref[src];operation=ai-viewmessage;message-num=[i]'>[src.messagetitle[i]]</A>"
		if(STATE_VIEWMESSAGE)
			if (src.aicurrmsg)
				dat += "<B>[src.messagetitle[src.aicurrmsg]]</B><BR><BR>[src.messagetext[src.aicurrmsg]]"
				dat += "<BR><BR><A href='byond://?src=\ref[src];operation=ai-delmessage'>Удалить сообщение</A>"
			else
				src.aistate = STATE_MESSAGELIST
				attack_hand(user)
				return null
		if(STATE_DELMESSAGE)
			if(src.aicurrmsg)
				dat += "Вы уверены, что хотите удалить это сообщение? <A href='byond://?src=\ref[src];operation=ai-delmessage2'>ДА</A> | <A href='byond://?src=\ref[src];operation=ai-viewmessage'>НЕТ</A>"
			else
				src.aistate = STATE_MESSAGELIST
				attack_hand(user)
				return

		if(STATE_STATUSDISPLAY)
			dat += "Установить текст на дисплеях<BR>"
			dat += "<A href='byond://?src=\ref[src];operation=setstat;statdisp=blank'>Очистить</A><BR>"
			dat += "<A href='byond://?src=\ref[src];operation=setstat;statdisp=default'>Прилёт шаттла</A><BR>"
			dat += "<A href='byond://?src=\ref[src];operation=setstat;statdisp=shuttle'>Время прибытия шаттла</A><BR>"
			dat += "<A href='byond://?src=\ref[src];operation=setstat;statdisp=message'>Режим передачи сообщений</A>"
			dat += "<ul><li> Линия 1: <A href='byond://?src=\ref[src];operation=setmsg1'>[ stat_msg1 ? stat_msg1 : "(пусто)"]</A>"
			dat += "<li> Линия 2: <A href='byond://?src=\ref[src];operation=setmsg2'>[ stat_msg2 ? stat_msg2 : "(пусто)"]</A></ul><br>"
			dat += "Alert: <A href='byond://?src=\ref[src];operation=setstat;statdisp=alert;alert=default'>Стандартный режим</A> |"
			dat += " <A href='byond://?src=\ref[src];operation=setstat;statdisp=alert;alert=redalert'>Красный код тревоги</A> |"
			dat += " <A href='byond://?src=\ref[src];operation=setstat;statdisp=alert;alert=lockdown'>Изоляция</A> |"
			dat += " <A href='byond://?src=\ref[src];operation=setstat;statdisp=alert;alert=biohazard'>Биологическая опасность</A><BR><HR>"


	dat += "<BR>[(src.aistate != STATE_DEFAULT) ? "<A href='byond://?src=\ref[src];operation=ai-main'>Главное меню</A> | " : ""]"
	return dat

/proc/call_shuttle_proc(mob/user)
	if ((!( SSticker ) || SSshuttle.location))
		return

	if(sent_strike_team == 1)
		to_chat(user, "Центком отказал в запросе шаттла на станцию. Все контракты расторгнуты.")
		return

	if(world.time < 6000) // Ten minute grace period to let the game get going without lolmetagaming. -- TLE
		var/time_to_stay = round((6000-world.time)/600)
		to_chat(user, "Шаттл находится на дозаправке. Пожалуйста, подождите еще [time_to_stay] [pluralize_russian(time_to_stay, "минута", "минуты", "минут")] до повторного вызова.")
		return

	if(SSshuttle.direction == -1)
		to_chat(user, "Аварийный шаттл возвращается к отделению Центкома, вызов невозможен.")
		return

	if(SSshuttle.online)
		to_chat(user, "Аварийный шаттл уже вызван.")
		return

	SSshuttle.incall()
	log_game("[key_name(user)] has called the shuttle.")
	message_admins("[key_name_admin(user)] has called the shuttle. [ADMIN_JMP(user)]")
	SSshuttle.announce_emer_called.play()

	make_maint_all_access(FALSE)

	return

/proc/init_shift_change(mob/user, force = 0)
	if((!( SSticker ) || SSshuttle.location))
		return

	if(SSshuttle.direction == -1)
		to_chat(user, "Шаттл возвращается к Центкому, вызов невозможен.")
		return

	if(SSshuttle.online)
		to_chat(user, "Шаттл уже вызван.")
		return

	// if force is 0, some things may stop the shuttle call
	if(!force)
		if(SSshuttle.deny_shuttle)
			to_chat(user, "Центком не имеет доступного шаттла в этом секторе, пожалуйста, подождите.")
			return

		if(sent_strike_team == 1)
			to_chat(user, "Центком отказал в запросе шаттла на станцию. Все контракты расторгнуты.")
			return


		if(world.time < 54000) // 30 minute grace period to let the game get going
			var/time_to_stay = round((54000-world.time)/600)
			to_chat(user, "Шаттл находится на дозаправке. Пожалуйста, подождите еще [time_to_stay] [PLUR_MINUTES_IN(time_to_stay)] до повторного вызова.")//may need to change "/600"
			return

	SSshuttle.shuttlealert(1)
	SSshuttle.incall()
	log_game("[key_name(user)] has called the shuttle.")
	message_admins("[key_name_admin(user)] has called the shuttle. [ADMIN_JMP(user)]")
	SSshuttle.announce_crew_called.play()

	return

/proc/cancel_call_proc(mob/user)
	if ((!( SSticker ) || SSshuttle.location || SSshuttle.direction == 0))
		to_chat(user, "Консоль не отвечает.")
		return

	if (SSshuttle.alert == 1)
		to_chat(user, "Отказано в доступе: невозможно отозвать шаттл транспортировки экипажа")
		return

	if(SSshuttle.timeleft() < 300)
		to_chat(user, "Шаттл близко. Отменять запрос уже поздно.")
		return

	if(SSshuttle.direction != -1 && SSshuttle.online) //check that shuttle isn't already heading to centcomm
		SSshuttle.recall()
		log_game("[key_name(user)] has recalled the shuttle.")
		message_admins("[key_name_admin(user)] has recalled the shuttle. [ADMIN_JMP(user)]")

		if(timer_maint_revoke_id)
			deltimer(timer_maint_revoke_id)
			timer_maint_revoke_id = 0
		timer_maint_revoke_id = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(revoke_maint_all_access), FALSE), 600, TIMER_UNIQUE|TIMER_STOPPABLE) // Want to give them time to get out of maintenance.

		return 1
	return

/obj/machinery/computer/communications/proc/post_status(command, data1, data2)

	var/datum/radio_frequency/frequency = radio_controller.return_frequency(1435)

	if(!frequency) return

	var/datum/signal/status_signal = new
	status_signal.source = src
	status_signal.transmission_method = 1
	status_signal.data["command"] = command

	switch(command)
		if("message")
			status_signal.data["msg1"] = data1
			status_signal.data["msg2"] = data2
			log_admin("STATUS: [src.fingerprintslast] set status screen message with [src]: [data1] [data2]")
			//message_admins("STATUS: [user] set status screen with [PDA]. Message: [data1] [data2]")
		if("alert")
			status_signal.data["picture_state"] = data1

	frequency.post_signal(src, status_signal)


/obj/machinery/computer/communications/evac
	name = "Shuttle communications console"
	desc = "This can be used for various important functions."
	icon_state = "erokez"
	state_broken_preset = "erokezb"
	state_nopower_preset = "erokez0"
