RegisterGlobalEventHandler("PlayerCreatedEvent", function(arg)

	local player = PlayerService:GetPlayerControlledEnt( 0 )

	if	( player == nil ) then
		return
	end

	local skillName = "items/skills/energy_connector_walk"

	if ( ItemService:GetItemCount( player, skillName ) > 0 ) then
		return
	end

	PlayerService:AddItemToInventory( 0, skillName )
end)
