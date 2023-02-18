local building = require("lua/buildings/building.lua")
require("lua/utils/string_utils.lua")
class 'pipe_straight' ( building )

function pipe_straight:__init()
	building.__init(self,self)
end

function pipe_straight:OnInit()
	self:RegisterHandler( self.entity, "SpecialBuildingActionRequest",  "OnSpecialBuildingActionRequest" )
	self:RegisterHandler( self.entity, "BuildingModifiedEvent",  "OnBuildingModifiedEvent" )
	
	self.resource = ""
	self.postfix = self.data:GetStringOrDefault( "postfix", "_pipe")
end

function pipe_straight:OnBuildingEnd()
	self:FixMaterial()
end

function pipe_straight:FixMaterial() 
	local pipeComponent = EntityService:GetComponent( self.entity, "PipeComponent")
	if (pipeComponent == nil ) then
		self.resource = ""
	else
		self.resource = pipeComponent:GetField("resource_name"):GetValue()
	end

	if (IsNullOrEmpty(self.resource)) then
		EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel" , 1, "default" )
	else
		EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .. self.postfix , 1, "default" )
		EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .."_fresnel" , 1, "fresnel" )
	end
end

function pipe_straight:CanEnableSpecialAction()
	return true
end

function pipe_straight:OnSpecialBuildingActionRequest( evt )
	BuildingService:ClearResourceGraphs( self.entity )
end

function pipe_straight:OnBuildingModifiedEvent( evt )
	self:FixMaterial()
end

function  pipe_straight:OnLoad()
	building.OnLoad( self )
	if ( self.pipeSm ~= nil ) then
		self:DestroyStateMachine( self.pipeSm )
		self.pipeSm = nil
	end
end

return pipe_straight