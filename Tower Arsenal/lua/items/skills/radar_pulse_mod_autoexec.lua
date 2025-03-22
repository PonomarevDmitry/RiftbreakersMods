RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

	if ( not PlayerService:HasGlobalAward( "items/skills/radar_pulse_mod_item" ) ) then
		PlayerService:AddGlobalAward( "items/skills/radar_pulse_mod_item", false )
	end
end)