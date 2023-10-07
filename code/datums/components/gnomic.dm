#define COMSIG_MOB_CAN_PICKUP "mob_can_pickup"
	#define COMPONENT_MOB_CAN_NOT_PICKUP 1

/datum/component/gnomic
	var/original_size_atom = 0

/datum/component/gnomic/Initialize(deequip_mob_items = TRUE)
	var/atom/A = parent
	original_size_atom = A.resize_rev
	do_resize(deequip_mob_items)
	RegisterSignal(parent, list(COMSIG_MOB_CAN_PICKUP), PROC_REF(can_equip))

/datum/component/gnomic/proc/do_resize(deequip_mob_items)
	var/atom/A = parent
	A.resize = 0.5
	A.update_transform()
	if(ismob(A) && deequip_mob_items)
		var/mob/M = A
		var/Itemlist = M.get_equipped_items()
		for(var/obj/item/W in Itemlist)
			if(W.flags & NODROP || !W.canremove)
				continue
			M.drop_from_inventory(W)
		if(ishuman(A))
			var/mob/living/carbon/human/H = M
			H.socks = 23
			H.undershirt = 31
			H.underwear = 7
			H.update_body()

/datum/component/gnomic/proc/can_equip(datum/source, obj/item/I)
	SIGNAL_HANDLER
	if(I.w_class > SIZE_MINUSCULE)
		return COMPONENT_MOB_CAN_NOT_PICKUP

/datum/component/gnomic/Destroy()
	UnregisterSignal(parent, list(COMSIG_MOB_CAN_PICKUP))
	return ..()

