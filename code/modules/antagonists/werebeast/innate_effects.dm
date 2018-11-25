
/datum/antagonist/werebeast/apply_innate_effects(mob/living/mob_override)
	.=..()
	var/mob/living/M = mob_override || owner.current
	RegisterSignal(M, COMSIG_MOB_DEATH, .proc/sync_death)
	if(!communicate_button)
		communicate_button = new
		communicate_button.team = team
	communicate_button.Grant(M)

/datum/antagonist/werebeast/remove_innate_effects(mob/living/mob_override)
	.=..()
	var/mob/living/M = mob_override || owner.current
	communicate_button.Remove(M)
	UnregisterSignal(M, COMSIG_MOB_DEATH)

/datum/antagonist/werebeast/host/apply_innate_effects(mob/living/mob_override)
	.=..()
	var/mob/living/M = mob_override || owner.current
	beast_button = new
	beast_button.team = team
	beast_button.Grant(M)

/datum/antagonist/werebeast/host/remove_innate_effects(mob/living/mob_override)
	.=..()
	var/mob/living/M = mob_override || owner.current
	beast_button.Remove(M)
