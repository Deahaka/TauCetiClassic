/datum/component/sharpening
	var/default_force = 0
	var/current_sharpness = 0
	var/max_sharpness = 0
	var/affect_modifier = FALSE
	var/sprite_modified = FALSE
	var/mask = null

/datum/component/sharpening/Initialize(_default_force = 0, _max_sharpness = 0, _affect_modifier = FALSE, _mask = null)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE

	/*
	max_sharpness = 0 is means the ability to sharpen indefinitely.
	unfortunately, no increase sharpening by bumping in wall.
	*/
	default_force = _default_force
	max_sharpness = _max_sharpness
	affect_modifier = _affect_modifier
	mask = _mask

	RegisterSignal(parent, list(COMSIG_PARENT_EXAMINE), .proc/get_info)
	RegisterSignal(parent, list(COMSIG_ATTACKED_BY_SHARP_ITEM), .proc/try_increase)
	RegisterSignal(parent, list(COMSIG_ITEM_ATTACK), .proc/make_blunt)


/datum/component/sharpening/proc/get_info()
	var/obj/item/I = parent
	if((current_sharpness / max_sharpness) > 0)
		I.visible_message("<span class='warning'>[I] looks deformed, like it has been sharpened!</span>" )
	//to do peredatt usera i emu smsky

/datum/component/sharpening/proc/chance_to_break()
	var/chance = default_force + current_sharpness
	if(prob(chance))
		make_blunt()

/datum/component/sharpening/proc/make_blunt()
	var/random_broke = rand(1,5)
	current_sharpness -= random_broke
	if(current_sharpness < 0)
		current_sharpness = 0
	var/damage = default_force + current_sharpness
	update_damage(damage)

/datum/component/sharpening/proc/try_increase()
	chance_to_break()
	if(!can_increase())
		return
	current_sharpness++
	var/damage = default_force + current_sharpness
	update_damage(damage)
	update_icon()

/datum/component/sharpening/proc/update_damage(amount)
	if(amount < 0)
		return
	var/obj/item/I = parent
	I.force = amount
	if(!affect_modifier)
		return
	if(I.force == default_force)
		I.edge = FALSE
		I.sharp = FALSE
	else
		I.edge = TRUE
		I.sharp = TRUE

/datum/component/sharpening/proc/can_increase()
	if(!max_sharpness)
		return TRUE
	if(current_sharpness >= max_sharpness)
		return FALSE
	return TRUE

/datum/component/sharpening/proc/update_icon()
	if(sprite_modified)
		return
	var/obj/item/I = parent
	var/source = I.icon
	var/sprite = I.icon_state
	var/icon/image = new(source, sprite)
	var/broken_mask = mask
	if(!mask)
		broken_mask = pick("broken", "broken1", "broken2", "broken3")
	var/icon/broken_outline = icon('icons/obj/drinks.dmi',broken_mask)
	image.Blend(broken_outline, ICON_OVERLAY, 1, 1)
	image.SwapColor(rgb(255, 0, 220, 255), rgb(0, 0, 0, 0))
	I.icon = image
	sprite_modified = TRUE

/datum/component/sharpening/Destroy()
	UnregisterSignal(parent, list(COMSIG_PARENT_EXAMINE))
	UnregisterSignal(parent, list(COMSIG_ITEM_ATTACK))
	UnregisterSignal(parent, list(COMSIG_ATTACKED_BY_SHARP_ITEM))
	return ..()
