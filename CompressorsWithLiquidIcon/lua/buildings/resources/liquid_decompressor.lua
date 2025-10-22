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

    BuildingService:ClearDecompressor(self.entity, true)

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "UnequipItemRequest", "OnUnequipItemRequest" )
    self.postfix = self.data:GetStringOrDefault( "postfix", "_storage")
    EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel", 1, "default" )

    self.decompressorVersion = 1

    if ( is_server and is_client ) then
        self:CreateMenuEntity()
    end

    self:registerBuildMenuTracker()
end

function liquid_decompressor:OnLoad()
    building.OnLoad(self)
    local version = self.decompressorVersion or 0
    if ( version < 1) then
        self:RegisterHandler( self.entity, "UnequipItemRequest", "OnUnequipItemRequest" )
    end
    self.decompressorVersion = 1

    self.showLiquidIcon = self.showLiquidIcon or 0
    if ( is_server and is_client ) then
        self:CreateMenuEntity()
    end

    self:registerBuildMenuTracker()
end

function liquid_decompressor:UpdateWorkingStatus()
    if ( EntityService:IsAlive( self.item ) ) then
        BuildingService:EnableBuilding( self.entity )
    else
        BuildingService:DisableBuilding( self.entity )
    end

    self:PopulateSpecialActionInfo()
end

function liquid_decompressor:OnBuildingEnd()
    self:UpdateWorkingStatus()
    building.OnBuildingEnd(self)
end

function liquid_decompressor:CreateMenuEntity()

    local menuBlueprintName = "misc/decompressor_liquid_menu"

    local menuEntity = nil

    local children = EntityService:GetChildren( self.entity, true )
    for child in Iter(children) do

        local blueprintName = EntityService:GetBlueprintName( child )
        if ( blueprintName == menuBlueprintName and EntityService:GetParent( child ) == self.entity ) then

            menuEntity = child

            break
        end
    end

    if ( menuEntity == nil ) then

        local team = EntityService:GetTeam( self.entity )
        menuEntity = EntityService:SpawnAndAttachEntity(menuBlueprintName, self.entity, team)
    end

    if ( menuEntity ~= nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == menuBlueprintName and child ~= menuEntity ) then
                EntityService:RemoveEntity( child )
            end
        end
        end

    if ( menuEntity == nil or menuEntity == INVALID_ID or not EntityService:IsAlive( menuEntity ) ) then
        return
    end

    if ( not EntityService:HasComponent( menuEntity, "LuaComponent" ) ) then

        QueueEvent( "RecreateComponentFromBlueprintRequest", menuEntity, "LuaComponent" )
end

    --local sizeSelf = EntityService:GetBoundsSize( self.entity )
    --EntityService:SetPosition( menuEntity, 0, sizeSelf.y + 3, 0 )

    local menuDB = EntityService:GetOrCreateDatabase( menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("liquid_visible", 0)
    end
end

function liquid_decompressor:PopulateSpecialActionInfo()

    if ( self:IsCompressedResourceFilled() ) then

        if ( self.compressorNonWorking ~= nil ) then
            EntityService:RemoveEntity(self.compressorNonWorking)
            self.compressorNonWorking = nil
        end

        return
    end

    self.data:SetString("action_icon", "gui/hud/resource_icons/compressed_resources_bigger" )

    if ( self.compressorNonWorking == nil ) then
        self.compressorNonWorking = EntityService:SpawnAndAttachEntity("misc/compressor_minimap_icon_non_working_blue", self.entity)
    end
end

function liquid_decompressor:IsCompressedResourceFilled()

    if ( self.item == INVALID_ID or self.item == nil ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName( self.item )
    blueprintName = blueprintName or ""

    if ( blueprintName == "" ) then
        return false
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        return false
    end

    local inventoryComp = blueprint:GetComponent("InventoryItemComponent")
    if ( inventoryComp == nil ) then
        return false
    end

    local inventoryCompRef = reflection_helper(inventoryComp)
    if ( inventoryCompRef == nil ) then
        return false
    end

    local itemBiggerIcon = inventoryCompRef.bigger_icon

    self.data:SetString("action_icon", itemBiggerIcon )

    return true
end

function liquid_decompressor:registerBuildMenuTracker()

    self:UnregisterHandlers( "LuaGlobalEvent" )

    self:UnregisterHandlers( "EnterBuildMenuEvent" )
    self:UnregisterHandlers( "EnterFighterModeEvent" )
end

function liquid_decompressor:OnLuaGlobalEventCompressorsShowHideIcon()
    -- Legacy Empty function
end

function liquid_decompressor:OnEnterBuildMenuEvent( evt )
    -- Legacy Empty function
end

function liquid_decompressor:OnEnterFighterModeEvent( evt )
    -- Legacy Empty function
end

function liquid_decompressor:Refresh()

    BuildingService:ReplaceProductionByCompressedItem( self.entity, self.item, self.lastResource, self.attachment, self.production, self.consumption )
    self:UpdateWorkingStatus()

    local info = EntityService:GetResourceAmount( self.item )
    self.lastResource = info.first
    self.resource = self.lastResource:gsub( "_compressed", "" )

    if (IsNullOrEmpty(self.resource)) then
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel", 1, "default" )
    else
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .. self.postfix, 1, "default" )
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .."_fresnel", 1, "fresnel" )
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

function liquid_decompressor:OnRemove()
end

function liquid_decompressor:OnRelease()

    if ( self.compressorNonWorking ~= nil and self.compressorNonWorking ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.compressorNonWorking )
        self.compressorNonWorking = nil
    end

    if ( building.OnRelease ) then
        building.OnRelease( self )
    end
end

return liquid_decompressor