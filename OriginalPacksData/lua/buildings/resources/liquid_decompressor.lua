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
    BuildingService:ClearDecompressor(self.entity, true  )

	self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
	self:RegisterHandler( self.entity, "UnequipItemRequest", "OnUnequipItemRequest" )
	self:RegisterHandler( self.entity, "SellBuildingRequest", "OnSellBuildingRequest" )
	self.postfix = self.data:GetStringOrDefault( "postfix", "_storage")
    EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel" , 1, "default" )

    self.decompressorVersion = 2
end

function liquid_decompressor:OnLoad()
	building.OnLoad(self)
    local version = self.decompressorVersion or 0
    if (  version < 1) then
	    self:RegisterHandler( self.entity, "UnequipItemRequest", "OnUnequipItemRequest" )
    end

    if ( version < 2 ) then
	    self:RegisterHandler( self.entity, "SellBuildingRequest", "OnSellBuildingRequest" )
    end
    self.decompressorVersion = 2


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

function liquid_decompressor:Refresh()
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

function liquid_decompressor:OnUnequipItemRequest( evt )
    self.item = INVALID_ID
    self:Refresh()
end

function liquid_decompressor:OnItemEquippedEvent( evt )
	self.item = evt:GetItem()
    self:Refresh()
end

function liquid_decompressor:OnDestroyRequest()
    building.OnDestroyRequest(self)
    BuildingService:ClearDecompressor(self.entity, false)
end

function liquid_decompressor:OnSellStart()
    BuildingService:ClearDecompressor(self.entity, false)
end

function liquid_decompressor:OnSellBuildingRequest()
    BuildingService:ClearDecompressor(self.entity, false)
end

function liquid_decompressor:OnRemove()
end
return liquid_decompressor
