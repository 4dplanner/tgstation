/*
	This datum should be used for handling mineral contents of machines and whatever else is supposed to hold minerals and make use of them.

	Variables:
		amount - raw amount of the mineral this container is holding, calculated by the defined value MINERAL_MATERIAL_AMOUNT=2000.
		max_amount - max raw amount of mineral this container can hold.
		sheet_type - type of the mineral sheet the container handles, used for output.
		parent - object that this container is being used by, used for output.
		MAX_STACK_SIZE - size of a stack of mineral sheets. Constant.
*/

/datum/component/material_container
	var/total_amount = 0
	var/max_amount
	var/sheet_type
	var/list/materials //Map of key = material ref | Value = amount
	var/show_on_examine
	var/disable_attackby
	var/list/allowed_typecache
	var/last_inserted_id
	var/precise_insertion = FALSE
	var/datum/callback/precondition
	var/datum/callback/after_insert

/datum/component/material_container/Initialize(list/mat_list, max_amt = 0, _show_on_examine = FALSE, list/allowed_types, datum/callback/_precondition, datum/callback/_after_insert, _disable_attackby)
	materials = list()
	max_amount = max(0, max_amt)
	show_on_examine = _show_on_examine
	disable_attackby = _disable_attackby

	if(allowed_types)
		if(ispath(allowed_types) && allowed_types == /obj/item/stack)
			allowed_typecache = GLOB.typecache_stack
		else
			allowed_typecache = typecacheof(allowed_types)

	precondition = _precondition
	after_insert = _after_insert

	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, .proc/OnAttackBy)
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, .proc/OnExamine)

	var/list/possible_mats = list()
	for(var/mat_type in subtypesof(/datum/material))
		possible_mats += mat_type

	for(var/mat in possible_mats)
		to_chat(world,"[mat]")
		var/datum/material/M = SSmaterials.get_material(mat)
		for(var/i in M.categories)
			if(mat_list.Find(i))
				materials[SSmaterials.get_material(i)] = 0

/datum/component/material_container/proc/OnExamine(datum/source, mob/user)
	if(show_on_examine)
		for(var/I in materials)
			var/datum/material/M = I
			var/amt = get_material_amount(I)
			if(amt)
				to_chat(user, "<span class='notice'>It has [amt] units of [lowertext(M.name)] stored.</span>")

/datum/component/material_container/proc/OnAttackBy(datum/source, obj/item/I, mob/living/user)
	var/list/tc = allowed_typecache
	if(disable_attackby)
		return
	if(user.a_intent != INTENT_HELP)
		return
	if(I.item_flags & ABSTRACT)
		return
	if((I.flags_1 & HOLOGRAM_1) || (I.item_flags & NO_MAT_REDEMPTION) || (tc && !is_type_in_typecache(I, tc)))
		to_chat(user, "<span class='warning'>[parent] won't accept [I]!</span>")
		return
	. = COMPONENT_NO_AFTERATTACK
	var/datum/callback/pc = precondition
	if(pc && !pc.Invoke(user))
		return
	var/material_amount = get_item_material_amount(I)
	if(!material_amount)
		to_chat(user, "<span class='warning'>[I] does not contain sufficient amounts of metal or glass to be accepted by [parent].</span>")
		return
	if(!has_space(material_amount))
		to_chat(user, "<span class='warning'>[parent] is full. Please remove metal or glass from [parent] in order to insert more.</span>")
		return
	user_insert(I, user)

/datum/component/material_container/proc/user_insert(obj/item/I, mob/living/user)
	set waitfor = FALSE
	var/requested_amount
	var/active_held = user.get_active_held_item()  // differs from I when using TK
	if(istype(I, /obj/item/stack) && precise_insertion)
		var/atom/current_parent = parent
		var/obj/item/stack/S = I
		requested_amount = input(user, "How much do you want to insert?", "Inserting [S.singular_name]s") as num|null
		if(isnull(requested_amount) || (requested_amount <= 0))
			return
		if(QDELETED(I) || QDELETED(user) || QDELETED(src) || parent != current_parent || user.physical_can_use_topic(current_parent) < UI_INTERACTIVE || user.get_active_held_item() != active_held)
			return
	if(!user.temporarilyRemoveItemFromInventory(I))
		to_chat(user, "<span class='warning'>[I] is stuck to you and cannot be placed into [parent].</span>")
		return
	var/inserted = insert_item(I, stack_amt = requested_amount)
	if(inserted)
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			to_chat(user, "<span class='notice'>You insert [inserted] [S.singular_name][inserted>1 ? "s" : ""] into [parent].</span>")
			if(!QDELETED(I) && I == active_held && !user.put_in_hands(I))
				stack_trace("Warning: User could not put object back in hand during material container insertion, line [__LINE__]! This can lead to issues.")
				I.forceMove(user.drop_location())
		else
			to_chat(user, "<span class='notice'>You insert a material total of [inserted] into [parent].</span>")
			qdel(I)
		if(after_insert)
			after_insert.Invoke(I.type, last_inserted_id, inserted)
	else if(I == active_held)
		user.put_in_active_hand(I)

//For inserting an amount of material
/datum/component/material_container/proc/insert_amount(amt, mat)
	if(amt > 0 && has_space(amt))
		var/total_amount_saved = total_amount
		if(mat)
			materials[mat] += amt
		else
			for(var/i in materials)
				materials[i] += amt
				total_amount += amt
		return (total_amount - total_amount_saved)
	return FALSE

/datum/component/material_container/proc/insert_stack(obj/item/stack/S, amt, multiplier = 1)
	if(isnull(amt))
		amt = S.amount

	if(amt <= 0)
		return FALSE

	if(amt > S.amount)
		amt = S.amount

	var/material_amt = get_item_material_amount(S)
	if(!material_amt)
		return FALSE

	amt = min(amt, round(((max_amount - total_amount) / material_amt)))
	if(!amt)
		return FALSE

	last_inserted_id = insert_materials(S,amt * multiplier)
	S.use(amt)
	return amt

/datum/component/material_container/proc/insert_item(obj/item/I, multiplier = 1, stack_amt)
	if(!I)
		return FALSE
	if(istype(I, /obj/item/stack))
		return insert_stack(I, stack_amt, multiplier)

	var/material_amount = get_item_material_amount(I)
	if(!material_amount || !has_space(material_amount))
		return FALSE

	last_inserted_id = insert_materials(I, multiplier)
	return material_amount

/datum/component/material_container/proc/insert_materials(obj/item/I, multiplier = 1) //for internal usage only
	var/primary_mat
	var/max_mat_value = 0
	for(var/MAT in materials)
		materials[MAT] += I.used_materials[MAT] * multiplier
		total_amount += I.used_materials[MAT] * multiplier
		if(I.materials[MAT] > max_mat_value)
			primary_mat = MAT
	return primary_mat

//For consuming material
//cats is a list of types of categories of materials to use and the corresponding amounts, example: list(MAT_CATEGORY_IRON=100, MAT_CATEGORY_GLASS=200)
/datum/component/material_container/proc/use_amount(list/cats, multiplier=1)
	if(!cats || !cats.len)
		return FALSE

	var/list/used_mats
	for(var/i in cats)
		var/datum/material/M = get_best_mat_of_category(i)
		if(materials[M] < (cats[i] * multiplier))
			return FALSE
		used_mats += M

	var/total_amount_save = total_amount

	for(var/i in cats)
		total_amount_save -= use_amount_cat(cats[i] * multiplier, i)

	return total_amount_save - total_amount


/datum/component/material_container/proc/use_amount_cat(amt, cat)
	var/datum/material/M = get_best_mat_of_category(cat)
	var/amount = materials[M]
	if(amount >= amt)
		materials[M] -= amt
		total_amount -= amt
		return amt
	return FALSE

/datum/component/material_container/proc/use_amount_mat(amt, mat)
	var/datum/material/M = mat
	var/amount = materials[mat]
	if(M)
		if(amount >= amt)
			materials[mat] -= amt
			total_amount -= amt
			return amt
	return FALSE


/datum/component/material_container/proc/transer_amt_to(var/datum/component/material_container/T, amt, mat)
	if((amt==0)||(!T)||(!mat))
		return FALSE
	if(amt<0)
		return T.transer_amt_to(src, -amt, mat)
	var/tr = min(amt, materials[mat],T.can_insert_amount(amt, mat))
	if(tr)
		use_amount_mat(tr, mat)
		T.insert_amount(tr, mat)
		return tr
	return FALSE

/datum/component/material_container/proc/can_insert_amount(amt, id)
	if(amt && id)
		var/datum/material/M = materials[id]
		if(M)
			if((total_amount + amt) <= max_amount)
				return amt
			else
				return	(max_amount-total_amount)

//For spawning mineral sheets; internal use only
/datum/component/material_container/proc/retrieve(sheet_amt, datum/material/M, target = null)
	if(!M.sheet_type)
		return 0
	if(sheet_amt <= 0)
		return 0

	if(!target)
		target = get_turf(parent)
	if(materials[M] < (sheet_amt * MINERAL_MATERIAL_AMOUNT))
		sheet_amt = round(materials[M] / MINERAL_MATERIAL_AMOUNT)
	var/count = 0
	while(sheet_amt > MAX_STACK_SIZE)
		new M.sheet_type(target, MAX_STACK_SIZE)
		count += MAX_STACK_SIZE
		use_amount_mat(sheet_amt * MINERAL_MATERIAL_AMOUNT, M)
		sheet_amt -= MAX_STACK_SIZE
	if(sheet_amt >= 1)
		new M.sheet_type(target, sheet_amt)
		count += sheet_amt
		use_amount_mat(sheet_amt * MINERAL_MATERIAL_AMOUNT, M)
	return count

/datum/component/material_container/proc/retrieve_sheets(sheet_amt, mat, target = null)
	return retrieve(sheet_amt, mat, target)

/datum/component/material_container/proc/retrieve_amount(amt, id, target)
	return retrieve_sheets(amount2sheet(amt), id, target)

/datum/component/material_container/proc/retrieve_all(target = null)
	var/result = 0
	for(var/MAT in materials)
		var/amount = materials[MAT]
		result += retrieve_sheets(amount2sheet(amount), MAT, target)
	return result

/datum/component/material_container/proc/has_space(amt = 0)
	return (total_amount + amt) <= max_amount

/datum/component/material_container/proc/has_materials(list/mats, multiplier=1)
	if(!mats || !mats.len)
		return FALSE

	for(var/MAT in mats)
		var/amount = materials[MAT]
		if(amount < (mats[MAT] * multiplier))
			return FALSE
	return TRUE

/datum/component/material_container/proc/amount2sheet(amt)
	if(amt >= MINERAL_MATERIAL_AMOUNT)
		return round(amt / MINERAL_MATERIAL_AMOUNT)
	return FALSE

/datum/component/material_container/proc/sheet2amount(sheet_amt)
	if(sheet_amt > 0)
		return sheet_amt * MINERAL_MATERIAL_AMOUNT
	return FALSE

/datum/component/material_container/proc/get_material_amount(material)
	return materials[material]

/datum/component/material_container/proc/get_best_mat_of_category(category) //This gets the material with the highest count of a certain category.
	var/datum/material/best_match

	for(var/i in SSmaterials.get_materials_of_category(category))
		var/amount = materials[i]
		if(!best_match || amount >= materials[i])
			best_match = i

	return best_match

/datum/component/material_container/proc/get_category_amount(category)
	return materials[get_best_mat_of_category(category)]


//returns the amount of material relevant to this container;
//if this container does not support glass, any glass in 'I' will not be taken into account
/datum/component/material_container/proc/get_item_material_amount(obj/item/I)
	if(!istype(I))
		return FALSE
	var/material_amount = 0
	for(var/MAT in I.used_materials)
		material_amount += I.used_materials[MAT]
	return material_amount