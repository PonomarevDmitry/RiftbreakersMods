local building = require("lua/buildings/building.lua")
class 'gravitational_hyper_lens' ( building )
require("lua/utils/string_utils.lua")

function gravitational_hyper_lens:__init()
	building.__init(self)
end

function gravitational_hyper_lens:OnInit()
	self.maskString = self.data:GetStringOrDefault( "minimap_reveal_mask", "none" )
	local buildingComponent = EntityService:GetConstComponent( self.entity ,"BuildingDesc")
	local helper = reflection_helper(buildingComponent)
	self.name = helper.limit_name
	self.megastructureWorking = false
end

function gravitational_hyper_lens:OnActivate()
	if ( self.megastructureWorking ) then
		return
	end
	self.megastructureWorking = true
	local data = CampaignService:GetCampaignData()
	data:SetFloat( self.name, data:GetFloatOrDefault(self.name, 0 ) + 1 )
	QueueEvent( "SetFroceRevealMaskRequest", self.entity, self.maskString )	
end

function gravitational_hyper_lens:RemoveComponent()
	if ( not self.megastructureWorking ) then
		return
	end
	self.megastructureWorking = false
	local data = CampaignService:GetCampaignData()
	data:SetFloat( self.name, data:GetFloatOrDefault(self.name, 0 ) - 1 )
	QueueEvent( "SetFroceRevealMaskRequest", self.entity, "" )	
end

function gravitational_hyper_lens:OnDeactivate()
	self:RemoveComponent()
end

function gravitational_hyper_lens:OnRemove()
	self:RemoveComponent()
end

return gravitational_hyper_lens
