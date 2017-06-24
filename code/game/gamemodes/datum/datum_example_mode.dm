/datum/game_mode/datum_example
	name = "DATUM EXAMPLE"
	config_tag = "datum"
	var/list/datum/antagonist/enemy_datums = list()
	var/list/list/datum/mind/antag_player_groups = list()
	var/list/datum/antagonist/antag_player_group_datums = list()


/datum/game_mode/datum_example/proc/load_antag_datums()
	enemy_datums += new ANTAG_DATUM_TRAITOR
	enemy_datums += new ANTAG_DATUM_IAA

/datum/game_mode/datum_example/pre_setup()
	WARNING("TIME TO BEGIN")
	load_antag_datums()
	var/initial_threat_level = num_players()
	var/threat_level = initial_threat_level 

	while(threat_level >= TRAITOR_THREAT_LEVEL)
		WARNING("TRYING TO MAKE AN ANTAG GROUP WITH THREAT LEVEL [threat_level]")	
		var/weight_allotment = min(threat_level,max(initial_threat_level/10, threat_level/2))
		WARNING("ALLOTED [weight_allotment]")	
		shuffle_inplace(enemy_datums)
		var/antag_selected = FALSE
		var/total_weight = 0
		for(var/datum/antagonist/enemy_datum in enemy_datums)
			WARNING("XD TIME FOR anOThER ONE")
			if((enemy_datum.antag_cost * enemy_datum.minimum_group_size)>weight_allotment)
				WARNING("EXPENSIVE DATUM SKIPPED")
				continue
			if(!prob(enemy_datum.relative_antag_chance))
				WARNING("NOT LUCKY DATUM")
				continue
			var/list/datum/mind/antag_candidates = get_players_for_role(enemy_datum.antag_flag, enemy_datum.minimum_group_size, enemy_datum) 
			WARNING("Got [length(antag_candidates)] CANDIDATES")
			if(length(antag_candidates) < enemy_datum.minimum_group_size)
				continue
			selectable_datums += enemy_datum
			total_weight += enemy_datum.relative_antag_chance
		if(!length(selectable_datums))
			break 			//Can't add any more threats

		var/selected_weight = rand(1,total_weight)
		var/current_datum
		while(selected_weight>0)
			current_datum = selectable_datums[0]
			selectable_datums -= current_datum
			selected_weight -= current_datum.relative_antag_chance

		var/enemy_count = max(weight_allotment/current_datum.antag_cost, current_datum.minimum_group_size)
		var/list/datum/mind/antag_candidates = get_players_for_role(current_datum.antag_flag, enemy_count, current_datum)
		enemy_count = length(antag_candidates)
		if(enemy_count < current_datum.minimum_group_size)
			continue
		WARNING("ENEMY COUNT [enemy_count]")
		shuffle_inplace(antag_candidates)
		var/to_antag = antag_candidates.Copy(1, enemy_count + 1)
		for(var/M in to_antag)
			var/datum/mind/mind = M
			mind.pending_antag_datums += current_datum
			mind.restricted_roles += current_datum.restricted_roles

		WARNING("Got [length(to_antag)] REAL CANDIDATES")
		antag_player_groups.Add(list(to_antag))
		antag_player_group_datums += current_datum
		threat_level -= current_datum.antag_cost * enemy_count
		antag_selected = TRUE
	WARNING("DONE WITH THIS")
	return 1


/datum/game_mode/datum_example/post_setup()
	WARNING("NOW POST")
	var/counter = 1
	for(var/P in antag_player_groups)
		var/list/datum/mind/player_group = P
		for(var/M in player_group)
			var/datum/mind/mind = M
			mind.pending_antag_datums -= antag_player_group_datums[counter]
		WARNING("USING ONE OF OUR FUN DATUMS on [length(player_group)] people")
		var/datum/antagonist/antag_datum = antag_player_group_datums[counter]
		antag_datum.create_antagonist_group(player_group)
		counter += 1
	

			
			
		
