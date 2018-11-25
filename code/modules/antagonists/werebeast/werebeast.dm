 #define BEAST_HOLDER "beast_holder"
/datum/antagonist/werebeast
	var/datum/team/werebeast/team
	var/datum/action/innate/werebeast_communicate/communicate_button

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


/datum/antagonist/werebeast/host/greet()
	to_chat(owner.current, "<span class='userdanger'>You are the [owner.special_role].</span>")
	to_chat(owner.current, "<span class='userdanger'>Inside you is a ravenous beast just waiting to get out.</span>")
	to_chat(owner.current, "<span class='userdanger'>You can talk to the beast using the action button, but the beast has control over when they emerge. You'll be able to wrest back control, but only after a time...</span>")
	to_chat(owner.current, "<span class='userdanger'>You and the beast also have some tasks given to you by your mysterious new employers...</span>")
	owner.announce_objectives()

/datum/antagonist/werebeast/beast/on_gain()
	owner.special_role = "Werebeast"
	.=..()	
	SSticker.mode.werebeast_beasts += owner
	team.update_bodies()
	team.human_form()
	START_PROCESSING(SSprocessing, team)

/datum/antagonist/werebeast/host/on_gain()
	SSticker.mode.werebeast_hosts += owner
	owner.special_role = "Werebeast host"
	.=..()

/datum/antagonist/werebeast/create_team(datum/team/werebeast/_team)
	. = ..()
	team = _team

/datum/antagonist/werebeast/host/create_team(datum/team/werebeast/_team)
	. = ..()
	team.host = owner.current

/datum/antagonist/werebeast/proc/sync_death(mob/source, var/gibbed)
	if(team.death_syncing)
		return
	team.death_syncing = TRUE

	for(var/_M in team.members)
		var/datum/mind/M = _M
		if (M != owner) //don't kill them twice
			if(M.current)
				if(gibbed)
					M.current.gib()
				else
					M.current.death()

	team.death_syncing = FALSE

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
	beast.real_name = "THE BEAST"
	beast.name = "THE BEAST"
	beast.move_force = MOVE_FORCE_EXTREMELY_STRONG
	beast.maxHealth = 100
	beast.health = 100
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
