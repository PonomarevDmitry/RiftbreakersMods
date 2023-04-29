RegisterGlobalEventHandler("PlayerCreatedEvent", function(arg)

	local player = PlayerService:GetPlayerControlledEnt( 0 )

	if	( player == nil ) then
		return
	end

	local skillName = "items/skills/energy_connector_trail"

	local itemCount = ItemService:GetItemCount( player, skillName )

	--LogService:Log("skillName " .. skillName .. " itemCount " .. tostring(itemCount))

	if ( itemCount > 0 ) then
		return
	end

	PlayerService:AddItemToInventory( 0, skillName )
end)
