/proc/werebeast_communicate(var/other_name, var/mob/living/me, var/mob/living/other)
	var/input = stripped_input(me, "Please enter a message to tell the [other_name].", "Werebeast", "")
	if(!input)
		return

	var/my_message = "<b><i>[me]:<b><i><span class='holoparasite bold'>[input]</span>" //apply basic color/bolding

	to_chat(other, my_message)
	to_chat(me, my_message)
	for(var/M in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(M, me)
		to_chat(M, "[link] [my_message]")

	me.log_talk(input, LOG_SAY, tag="werebeast")

/datum/action/innate/werebeast_communicate
	name = "Communicate"
	desc = "A mental link"
	var/datum/team/werebeast/team


/datum/action/innate/werebeast_communicate/Activate()
	if(team.host && team.beast)
		if(team.host == owner)
			werebeast_communicate("beast", team.host, team.beast)
		else
			werebeast_communicate("host", team.beast, team.host)
		

/datum/action/innate/beast_form/
	name = "Beast form"
	desc = "GRARGH"

	var/datum/team/werebeast/team


/datum/action/innate/beast_form/Activate()
	if(team.active == team.beast)
		return
	if((team.last_switch + WEREBEAST_TRANSFORMATION_COOLDOWN) < world.time)
		team.beast_form()	
		team.reset_timers()

/datum/action/innate/host_form/
	name = "Human form"
	desc = "ehem"

	var/datum/team/werebeast/team

/datum/action/innate/host_form/Activate()
	if(team.active == team.host)
		return
	if((team.last_switch + WEREBEAST_TRANSFORMATION_COOLDOWN) < world.time)
		team.host_form()	
		team.reset_timers()
		team.last_switch = world.time
