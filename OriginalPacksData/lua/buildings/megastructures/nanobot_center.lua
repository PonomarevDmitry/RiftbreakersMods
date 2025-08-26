local building = require("lua/buildings/building.lua")
class 'nanobot_center' ( building )

function nanobot_center:__init()
	building.__init(self)
end

function nanobot_center:OnInit()
	self.team = EntityService:GetTeam(self.entity )
	self.numberOfAiCores = self.data:GetIntOrDefault( "number_of_ai_cores", 20 )
	local buildingComponent = EntityService:GetConstComponent( self.entity ,"BuildingDesc")
	local helper = reflection_helper(buildingComponent)
	self.name = helper.limit_name
	self.megastructureWorking = false
end

function nanobot_center:OnActivate()
	if ( self.megastructureWorking ) then
		return
	end
	self.megastructureWorking = true
	local data = CampaignService:GetCampaignData()
	data:SetFloat( self.name, data:GetFloatOrDefault(self.name, 0 ) + 1 )
	local teamEntity = PlayerService:GetGlobalTeamEntity(self.team )
	BuildingService:CreateResourceStorageComponent( teamEntity, "ai", self.numberOfAiCores,"")
end

function nanobot_center:RemoveComponent()
	if ( not self.megastructureWorking ) then
		return
	end
	self.megastructureWorking = false

	local data = CampaignService:GetCampaignData()
	data:SetFloat( self.name, data:GetFloatOrDefault(self.name, 0) - 1 )
	local teamEntity = PlayerService:GetGlobalTeamEntity(self.team )
	BuildingService:DecreaseResourceStorage( teamEntity, "ai", self.numberOfAiCores,"")
end

function nanobot_center:OnDeactivate()
	self:RemoveComponent()
end

function nanobot_center:OnRemove()
	self:RemoveComponent()
end

return nanobot_center
