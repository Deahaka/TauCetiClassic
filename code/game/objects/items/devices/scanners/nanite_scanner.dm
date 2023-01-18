/obj/item/device/nanite_scanner
	name = "nanite scanner"
	icon_state = "nanite_scanner"
	item_state = "nanite_remote"
	desc = "A hand-held body scanner able to detect nanites and their programming."
	flags = CONDUCT | NOBLUDGEON
	slot_flags = SLOT_FLAGS_BELT
	throwforce = 3
	w_class = SIZE_TINY
	throw_speed = 3
	throw_range = 7

/obj/item/device/nanite_scanner/attack(mob/living/M, mob/living/carbon/human/user)
	user.visible_message("<span class='notice'>[user] has analyzed [M]'s nanites.</span>")
	add_fingerprint(user)

	if(!(SEND_SIGNAL(M, COMSIG_NANITE_SCAN, user, TRUE) & COMPONENT_NANITES_DETECTED))
		to_chat(user, "<span class='info'>No nanites detected in the subject.</span>")
