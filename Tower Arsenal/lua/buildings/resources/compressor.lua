local building = require("lua/buildings/building.lua")
require("lua/utils/string_utils.lua")
class 'compressor' ( building )

function compressor:__init()
	building.__init(self,self)
end

function compressor:OnInit()
	self:RegisterHandler( self.entity, "BuildingModifiedEvent",  "OnBuildingModifiedEvent" )
	
	self.resource = ""
	self.postfix = self.data:GetStringOrDefault( "postfix", "_pipe")
end

function compressor:OnBuildingEnd()
	self:FixMaterial()
end

function compressor:FixMaterial() 
	local resourceConverterComponent = EntityService:GetComponent( self.entity, "ResourceConverterComponent")
	if ( resourceConverterComponent == nil ) then
		self.resource = ""
	else
		self.resource = resourceConverterComponent:GetField("last_ore_produced"):GetValue()
	end

    self.resource = self.resource:gsub( "_compressed", "" )


	if (IsNullOrEmpty(self.resource)) then
		EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel" , 1, "default" )
	else
		EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .. self.postfix , 1, "default" )
		EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .."_fresnel" , 1, "fresnel" )
	end
end

function compressor:CanEnableSpecialAction()
	return true
end

function compressor:OnBuildingModifiedEvent( evt )
	self:FixMaterial()
end

return compressor