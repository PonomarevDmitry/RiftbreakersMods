require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local building = require("lua/buildings/building.lua")
class 'liquid_decompressor' ( building )

function liquid_decompressor:__init()
	building.__init(self,self)
end

function liquid_decompressor:OnInit()
	building.OnInit( self )

    self.item = INVALID_ID
    self.production = self.data:GetFloatOrDefault("production", 100 )
    self.consumption = self.data:GetFloatOrDefault("consumption", 1 )
    self.attachment = self.data:GetStringOrDefault("attachment", "att_out_1" )
    self.lastResource = ""

    local owner = self.data:GetIntOrDefault( "owner", 0)
    BuildingService:CheckAndAddAllCompressedresources( owner )
    BuildingService:ClearDecompressor(self.entity  )

	self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
	self.postfix = self.data:GetStringOrDefault( "postfix", "_storage")
    EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel" , 1, "default" )

end

function liquid_decompressor:OnLoad()
	building.OnLoad(self)
end

function liquid_decompressor:UpdateWorkingStatus()
    if ( EntityService:IsAlive( self.item )) then
        BuildingService:EnableBuilding( self.entity )
    else
        BuildingService:DisableBuilding( self.entity )
    end
end

function liquid_decompressor:OnBuildingEnd()
    self:UpdateWorkingStatus()
    building.OnBuildingEnd(self)
end

function liquid_decompressor:PopulateSpecialActionInfo()

end

function liquid_decompressor:OnItemEquippedEvent( evt )
	self.item = evt:GetItem()
    BuildingService:ReplaceProductionByCompressedItem(self.entity , self.item , self.lastResource , self.attachment, self.production, self.consumption )
    self:UpdateWorkingStatus()

    local info = EntityService:GetResourceAmount( self.item )
    self.lastResource = info.first
    self.resource = self.lastResource:gsub( "_compressed", "" )

    if (IsNullOrEmpty(self.resource)) then
		EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel" , 1, "default" )
	else
		EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .. self.postfix , 1, "default" )
		EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .."_fresnel" , 1, "fresnel" )
	end
end

return liquid_decompressor
