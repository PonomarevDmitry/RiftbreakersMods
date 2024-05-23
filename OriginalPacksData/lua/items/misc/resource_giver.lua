local item = require("lua/items/item.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

class 'resource_giver' ( item )

function resource_giver:__init()
	item.__init(self,self)
end

function resource_giver:OnInit()
	self:RegisterHandler( self.entity, "PickedUpItemRequest", 	 "OnPickedUpItemRequest" )	

	self.added = false;
end

function resource_giver:GetSizePostfix( size )
	local sizeIncrement = math.min( (size - 1) / 10, 0.35 )
	if ( size == 1 ) then
		return "", 1 + sizeIncrement
	elseif( size <= 5 ) then
		return "", 1 + sizeIncrement
	elseif ( size <= 10 ) then
		return "", 1 + sizeIncrement
	else
		return "", 1 + sizeIncrement
	end
end

function resource_giver:OnDrop()

	local resource = EntityService:GetResourceAmount( self.entity )
	if Assert( resource.second > 0, "ERROR: resource_giver.lua is only supported on entities with ResourceComponent!" ) then
		local multiplier = self.data:GetFloatOrDefault( "resource_multiplier", 1 )
		if multiplier ~= 1.0 then
			EntityService:ChangeResourceAmount(self.entity, resource.second * multiplier );
		end
	end

	local resource = EntityService:GetResourceAmount( self.entity )
	local amount = resource.second;

	local meshName = EntityService:GetMeshName( self.item )
	local materialName = EntityService:GetOverridenMaterial( self.item )

	if (string.find( meshName, resource.first ) ~= nil ) then
		local postfix, size = self:GetSizePostfix( amount )
		local newMesh = string.gsub( meshName, resource.first, resource.first .. postfix )
		EntityService:ChangeMesh( self.item, newMesh ) 
		EntityService:ChangeMaterial( self.item, materialName )
		EntityService:SetScale( self.item, size, size ,size )
		EntityService:SetPhysicsScale( self.entity, size, size ,size )
		return
	end

end

function resource_giver:OnPickUp( owner )
	self:AddResources(owner)
	EntityService:RemoveEntity( self.entity )
end

function resource_giver:AddResources(owner)
	if ( self.added ) then
		return
	end
	self.added = true
	local resource = EntityService:GetResourceAmount( self.entity )
	if resource.second > 0 then

		local playerReferenceComponent = EntityService:GetComponent(owner, "PlayerReferenceComponent")
		local owner = 0
		if (playerReferenceComponent) then
			local helper = reflection_helper(playerReferenceComponent)
			owner = helper.player_id
		end
		PlayerService:AddResourceAmount( owner , resource.first, resource.second, false )
	end
end

function resource_giver:OnPickedUpItemRequest( evt )
	self:AddResources( evt:GetInventory() )
end

function resource_giver:IsPickable( owner )
	if ( self.data:GetIntOrDefault("check_fitting", 1) == 0 ) then
		return true
	end
	return ItemService:CanFitResourceGiver( owner, self.entity )	
end

return resource_giver
