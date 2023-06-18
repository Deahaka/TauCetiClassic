#define SPAWN_CD 15 MINUTES

/datum/faction/traitor/auto
	name = "AutoTraitors"
	accept_latejoiners = TRUE
	roletype = /datum/role/traitor/auto
	initroletype = /datum/role/traitor/auto
	var/next_try = 0
	var/list/traitors_disqualified = list()

/datum/faction/traitor/auto/can_setup(num_players)
	var/max_traitors = 1
	var/traitor_prob = 0
	max_traitors = round(num_players / 10) + 1
	traitor_prob = (num_players - (max_traitors - 1) * 10) * 10

	if(config.traitor_scaling)
		max_roles = max_traitors - 1 + prob(traitor_prob)
		log_mode("Number of traitors: [max_roles]")
		message_admins("Players counted: [num_players]  Number of traitors chosen: [max_roles]")
	else
		max_roles = max(1, min(num_players, traitors_possible))

	return TRUE

/datum/faction/traitor/auto/proc/traitorcheckloop()
	log_mode("Try add new autotraitor.")
	if(SSshuttle.departed)
		log_mode("But shuttle was departed.")
		return

	if(SSshuttle.online) //shuttle in the way, but may be revoked
		addtimer(CALLBACK(src, .proc/traitorcheckloop), SPAWN_CD)
		log_mode("But shuttle was online.")
		return

	var/list/possible_autotraitor = list()
	var/playercount = 0
	var/traitorcount = 0

	for(var/mob/living/player as anything in living_list)
		if (player.client && player.mind && player.stat != DEAD && (is_station_level(player.z) || is_mining_level(player.z)))
			playercount++
			if(isanyantag(player))
				traitorcount++
			else if((player.client && (required_pref in player.client.prefs.be_role)) && !jobban_isbanned(player, "Syndicate") && !jobban_isbanned(player, required_pref) && !role_available_in_minutes(player, required_pref) && !player.ismindprotect())
				if(!possible_autotraitor.len || !possible_autotraitor.Find(player))
					possible_autotraitor += player

	for(var/mob/living/player in possible_autotraitor)
		if(!player.mind || !player.client)
			possible_autotraitor -= player
			continue
		for(var/job in list("Cyborg", "Security Officer", "Security Cadet", "Warden", "Velocity Officer", "Velocity Chief", "Velocity Medical Doctor"))
			if(player.mind.assigned_role == job)
				possible_autotraitor -= player

	var/max_traitors = 1
	var/traitor_prob = 0
	max_traitors = round(playercount / 10) + 1 + traitors_disqualified.len
	traitor_prob = (playercount - (max_traitors - 1) * 10) * 5
	if(traitorcount < max_traitors - 1)
		traitor_prob += 50

	if(traitorcount < max_traitors)
		if(prob(traitor_prob))
			log_mode("Making a new Traitor.")
			if(!possible_autotraitor.len)
				log_mode("No potential traitors.  Cancelling new traitor.")
				addtimer(CALLBACK(src, .proc/traitorcheckloop), SPAWN_CD)
				return

			var/mob/living/newtraitor = pick(possible_autotraitor)
			add_faction_member(src, newtraitor, TRUE, TRUE)

	addtimer(CALLBACK(src, .proc/traitorcheckloop), SPAWN_CD)

/datum/faction/traitor/auto/OnPostSetup()
	addtimer(CALLBACK(src, .proc/traitorcheckloop), SPAWN_CD)
	return ..()

/datum/faction/traitor/auto/latespawn(mob/M)
	to_chat(world, "Latespawn go")
	var/list/list_of_all_traitors = list()
	//Catch roles from current traitor gamemode
	var/datum/faction/traitor/T = find_faction_by_type(/datum/faction/traitor)
	if(T)
		to_chat(world, "No faction")
		for(var/datum/role/members in members)
			list_of_all_traitors += members.antag.current
	//Count roles from current early created faction
	for(var/datum/role/R in members)
		list_of_all_traitors += R.antag.current
	to_chat(world, "traitors [list_of_all_traitors.len]")
	var/list/disqualified = list()
	for(var/mob/agents in list_of_all_traitors)
		if(iscarbon(M))
			var/mob/living/carbon/C = agents
			if(C.handcuffed)
				disqualified += C
				continue
		if(!ishuman(agents))
			disqualified += agents
			continue
		if(M.stat == DEAD)
			disqualified += agents
	to_chat(world, "discq [disqualified.len]")
	for(var/failed_agent in disqualified)
		if(!(failed_agent in traitors_disqualified))
			traitors_disqualified += failed_agent
	to_chat(world, "max_roles now [max_roles]")
	//Signal that you need agents from game_mode/latespawn() or traitorcheckloop()
	max_roles = list_of_all_traitors.len + traitors_disqualified.len
	to_chat(world, "max_roles after [max_roles]")
#undef SPAWN_CD
