
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
	if(team.active==team.host)
		team.beast_form()
	else
		team.human_form()
