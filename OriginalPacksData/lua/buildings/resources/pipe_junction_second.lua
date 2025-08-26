class 'pipe_junction_second' ( LuaEntityObject )
require("lua/utils/string_utils.lua")

function pipe_junction_second:__init()
	LuaEntityObject.__init(self,self)
end

function pipe_junction_second:init()
    local parent = EntityService:GetParent( self.entity )
	self:RegisterHandler( parent, "BuildingModifiedEvent",  "OnBuildingModifiedEvent" )
	self:RegisterHandler( parent, "RecreateComponentFromBlueprintRequest",  "OnRecreateComponentFromBlueprintRequest" )
    
    self:RegisterHandler( self.entity, "BuildingModifiedEvent",  "OnBuildingModifiedEvent" )
	self:RegisterHandler( self.entity, "RecreateComponentFromBlueprintRequest",  "OnRecreateComponentFromBlueprintRequest" )
	
	self.resource = ""
	self.postfix = self.data:GetStringOrDefault( "postfix", "_pipe")
end

function pipe_junction_second:OnBuildingEnd()
	self:FixMaterial()
end

function pipe_junction_second:FixMaterial() 
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

function pipe_junction_second:OnBuildingModifiedEvent( evt )
	self:FixMaterial()
end

function pipe_junction_second:OnRecreateComponentFromBlueprintRequest( evt )
	self:FixMaterial()
end


return pipe_junction_second