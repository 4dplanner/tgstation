/datum/game_mode
	var/list/datum/mind/werebeast_hosts = list()
	var/list/datum/mind/werebeast_beasts = list()
	var/list/datum/team/werebeast/werebeast_teams = list()

/datum/game_mode/werebeasts
	name = "werebeasts"
	config_tag = "werebeasts"
	restricted_jobs = list("AI", "Cyborg")
	var/list/datum/team/werebeast/pre_werebeast_teams = list()


/datum/game_mode/werebeasts/pre_setup()
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs
	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		restricted_jobs += "Assistant"

	var/list/datum/mind/possible_hosts = get_players_for_role(ROLE_WOLF_HOST)
	var/list/datum/mind/possible_beasts = get_players_for_role(ROLE_WOLF_BEAST)

	var/num_teams = 2

	while(num_teams)
		if(!possible_hosts.len)
			to_chat(world, "NOT ENOUGH HOSTS");
			break
		else
			to_chat(world, "ENOUGH HOSTS");

		var/datum/mind/host = antag_pick(possible_hosts)
		possible_hosts -= host
		possible_beasts -= host

		//check is after host pick in case the host picked was the only available beast
		if(!possible_beasts.len) 
			to_chat(world, "NOT ENOUGH BEASTS");
			break

		var/datum/mind/beast = antag_pick(possible_hosts)
		possible_beasts -= beast
		possible_hosts -= beast

		antag_candidates -= beast
		antag_candidates -= host //don't kill their antag roll just because there wasn't a beast

		for (var/datum/mind/M in list(beast,host))
			M.restricted_roles = restricted_jobs
		beast.assigned_role = "WOLF"

		var/datum/team/werebeast/team = new

		team.host_mind = host
		team.add_member(host)
		team.beast_mind = beast
		team.add_member(beast)


		pre_werebeast_teams += team
	
	return ..()

/datum/game_mode/werebeasts/post_setup()
	for(var/_T in pre_werebeast_teams)
		to_chat(world, "activating team")
		var/datum/team/werebeast/team=_T
		team.host_mind.add_antag_datum(/datum/antagonist/werebeast/host, team)
		team.beast_mind.add_antag_datum(/datum/antagonist/werebeast/beast, team)
	return ..()
