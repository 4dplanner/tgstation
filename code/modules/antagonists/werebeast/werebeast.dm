 #define BEAST_HOLDER "beast_holder"
/datum/antagonist/werebeast
	var/datum/team/werebeast/team

/datum/antagonist/werebeast/host
	name = "Wwerebeast host"
	antagpanel_category = "Werewolves"

	var/datum/action/innate/beast_form/beast_button

/datum/antagonist/werebeast/beast
	name = "Werebeast"
	antagpanel_category = "Werewolves"

/datum/team/werebeast
	var/beast_type = /mob/living/simple_animal/hostile/gorilla
	var/obj/beast_holder

	var/datum/mind/host_mind
	var/datum/mind/beast_mind

	var/mob/living/host
	var/mob/living/beast

	var/mob/living/stored
	var/mob/living/active

	var/death_syncing = FALSE //to prevent death sync loops

/datum/action/innate/beast_form/
	name = "Beast form"
	desc = "GRARGH"

	var/datum/team/werebeast/team


/datum/action/innate/beast_form/Activate()
	if(team.active==team.host)
		team.beast_form()
	else
		team.human_form()

/datum/antagonist/werebeast/create_team(datum/team/werebeast/_team)
	. = ..()
	team = _team

/datum/antagonist/werebeast/host/create_team(datum/team/werebeast/_team)
	. = ..()
	team.host_mind = owner
	team.host = owner.current

/datum/antagonist/werebeast/beast/create_team(datum/team/werebeast/_team)
	. = ..()
	team.beast_mind = owner

/datum/antagonist/werebeast/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	RegisterSignal(M, COMSIG_MOB_DEATH, .proc/sync_death)

/datum/antagonist/werebeast/host/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	UnregisterSignal(M, COMSIG_MOB_DEATH)

/datum/antagonist/werebeast/beast/on_gain()
	.=..()	
	SSticker.mode.werebeast_beasts += owner
	team.update_bodies()
	team.human_form()
	START_PROCESSING(SSprocessing, team)

/datum/antagonist/werebeast/host/on_gain()
	.=..()
	SSticker.mode.werebeast_hosts += owner


/datum/antagonist/werebeast/proc/sync_death(mob/source, var/gibbed)
	if(team.death_syncing)
		return
	team.death_syncing = TRUE

	for(var/_M in team.members)
		var/datum/mind/M = _M
		if (M != owner)
			if(M.current)
				if(gibbed)
					M.current.gib()
				else
					M.current.death()

	team.death_syncing = FALSE

/datum/antagonist/werebeast/host/apply_innate_effects(mob/living/mob_override)
	.=..()
	var/mob/living/M = mob_override || owner.current
	if(!beast_button)
		beast_button = new
		beast_button.team = team
	beast_button.Grant(M)

/datum/antagonist/werebeast/host/remove_innate_effects(mob/living/mob_override)
	.=..()
	var/mob/living/M = mob_override || owner.current
	beast_button.Remove(M)

/datum/team/werebeast/proc/switch_form(mob/living/_active, mob/living/_stored)
	if(stored)
		stored.remove_trait(TRAIT_NOBREATH, BEAST_HOLDER)

	active=_active
	stored=_stored

	var/atom/loc = beast_holder.loc.loc
	active.forceMove(loc)
	beast_holder.forceMove(active)
	stored.forceMove(beast_holder)

	stored.add_trait(TRAIT_NOBREATH, BEAST_HOLDER) //even with the revives, suffocating gives an annoying status effect and a bad moodlet

/datum/team/werebeast/proc/beast_form()
	switch_form(beast, host)

/datum/team/werebeast/proc/human_form()
	switch_form(host, beast)

/datum/team/werebeast/proc/update_bodies()
	host = host_mind.current
	if(host)
		if(!beast_holder)
			beast_holder = new(host)
		else
			beast_holder.forceMove(host)
		if(!beast)
			generate_beast()
		human_form()
	else
		stack_trace("Werebeast had no host")
		

/datum/team/werebeast/proc/generate_beast()
	var/mob/living/old = beast_mind.current
	beast = new beast_type(beast_holder)
	beast_mind.transfer_to(beast, TRUE)
	if(old)
		qdel(old)

/datum/antagonist/werebeast/host/on_body_transfer(var/mob/living/old_current, var/mob/living/current)
	. = ..()	
	team.update_bodies()

/datum/team/werebeast/process()
	if(active && active.stat != DEAD)
		if(stored)
			stored.revive(TRUE)
