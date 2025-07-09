local building = require("lua/buildings/building.lua")
class 'hydroponic_lab' ( building )

function hydroponic_lab:__init()
	building.__init(self)
end

function hydroponic_lab:OnInit()
	local buildingComponent = EntityService:GetConstComponent( self.entity ,"BuildingDesc")
	local helper = reflection_helper(buildingComponent)
	self.name = helper.limit_name
	self.hydroponic_labWorking = false
    EntityService:DisableComponent(self.entity, "BiomeModificatorComponent")
end

function hydroponic_lab:OnActivate()
	if ( self.hydroponic_labWorking ) then
		return
	end
	self.hydroponic_labWorking = true

	local data = CampaignService:GetCampaignData()
	
	data:SetFloat( self.name, data:GetFloatOrDefault(self.name, 0) + 1 )
    EntityService:EnableComponent(self.entity, "BiomeModificatorComponent")
end

function hydroponic_lab:RemoveComponent()
	if ( not self.hydroponic_labWorking ) then
		return
	end
	self.hydroponic_labWorking = false

	local data = CampaignService:GetCampaignData()
	data:SetFloat( self.name, data:GetFloatOrDefault(self.name, 0) - 1 )
    EntityService:DisableComponent(self.entity, "BiomeModificatorComponent")
end

function hydroponic_lab:OnDeactivate()
	self:RemoveComponent()
end

function hydroponic_lab:OnRemove()
	self:RemoveComponent()
end

return hydroponic_lab
