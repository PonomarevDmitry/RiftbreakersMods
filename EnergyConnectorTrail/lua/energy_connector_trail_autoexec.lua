RegisterGlobalEventHandler("PlayerCreatedEvent", function(arg)

	local playerId = evt:GetPlayerId()

	local player = PlayerService:GetPlayerControlledEnt( playerId )

	if	( player == nil ) then
		return
	end

	local skillName = "items/skills/energy_connector_trail"

	local itemCount = ItemService:GetItemCount( player, skillName )

	--LogService:Log("skillName " .. skillName .. " itemCount " .. tostring(itemCount))

	if ( itemCount > 0 ) then
		return
	end

	PlayerService:AddItemToInventory( playerId, skillName )
end)
