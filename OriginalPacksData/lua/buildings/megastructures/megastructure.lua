local building = require("lua/buildings/building.lua")
class 'megastructure' ( building )

function megastructure:__init()
	building.__init(self)
end

function megastructure:OnInit()
	local buildingComponent = EntityService:GetConstComponent( self.entity ,"BuildingDesc")
	local helper = reflection_helper(buildingComponent)
	self.name = helper.limit_name
	self.megastructureWorking = false
end

function megastructure:OnActivate()
	if ( self.megastructureWorking ) then
		return
	end
	self.megastructureWorking = true

	local data = CampaignService:GetCampaignData()
	
	data:SetFloat( self.name, data:GetFloatOrDefault(self.name, 0) + 1 )
end

function megastructure:RemoveComponent()
	if ( not self.megastructureWorking ) then
		return
	end
	self.megastructureWorking = false

	local data = CampaignService:GetCampaignData()
	data:SetFloat( self.name, data:GetFloatOrDefault(self.name, 0) - 1 )
end

function megastructure:OnDeactivate()
	self:RemoveComponent()
end

function megastructure:OnRemove()
	self:RemoveComponent()
end

return megastructure
