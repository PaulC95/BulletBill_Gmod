--this part is for making kill icons
local icol = Color( 255, 255, 255, 255 )
if CLIENT then

	killicon.Add(  "test_rifle",		"vgui/hud/test_rifle", icol  )
	--			weapon name			location of weapon's kill icon, I just used the hud icon

end

--I always leave a note reminding me which weapon these sounds are for
--weapon name
sound.Add({
	name = 			"Weapon_Bill_Launcher.Single",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/rocket_shoot.wav"
})

sound.Add({
	name = 			"Weapon_Bill.Reload",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/rocket_reload.wav"
})

sound.Add({
	name = 			"Big_Bill.Defeated",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/smb_jump-super.wav"
})

sound.Add({
	name = 			"Small_Bill.Defeated",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/smb_jump-small.wav"
})

sound.Add({
	name = 			"Bill.Damage",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/smb_bump.wav"
})

sound.Add({
	name = 			"fly.big",
	channel = 		CHAN_STATIC,
	volume = 		1.0,
	sound = 			"weapons/loop_low.wav"
})

sound.Add({
	name = 			"fly.small",
	channel = 		CHAN_STATIC,
	volume = 		1.0,
	sound = 			"weapons/loop_high.wav"
})