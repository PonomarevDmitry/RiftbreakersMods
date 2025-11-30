require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'compressor_liquid_menu' ( LuaEntityObject )

function compressor_liquid_menu:__init()
    LuaEntityObject.__init(self, self)
end

function compressor_liquid_menu:init()

    self.parentBuilding = EntityService:GetParent( self.entity )

    self:RegisterEventHandlers()

    self.showMenu = 0

    local playerId = PlayerService:GetPlayerForEntity( self.parentBuilding )

    if ( PlayerService:IsInFighterMode( playerId ) ) then
        self.showMenu = 0
    else
        self.showMenu = 1
    end

    self:UpdateMenuIcons()
end

function compressor_liquid_menu:OnLoad()

    self.parentBuilding = EntityService:GetParent( self.entity )

    self:RegisterEventHandlers()

    self.showMenu = self.showMenu or 0

    self:UpdateMenuIcons()
end

function compressor_liquid_menu:RegisterEventHandlers()

    if ( self.parentBuilding == nil or self.parentBuilding == INVALID_ID or not EntityService:IsAlive( self.parentBuilding ) ) then
        return
    end

    self:RegisterHandler( self.parentBuilding, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.parentBuilding, "ItemUnequippedEvent", "OnItemUnequippedEvent" )

    self:RegisterHandler( self.parentBuilding, "StartBuildingEvent",  "OnStartBuildingEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingBuildEndEvent", "OnBuildingBuildEndEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingModifiedEvent", "OnBuildingModifiedEvent" )
    
    self:RegisterHandler( self.parentBuilding, "BuildingSellEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingOverrideEvent", "OnBuildingModifiedEvent" )

    self:RegisterHandler( self.parentBuilding, "ActivateBuildingEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "DeactivateBuildingEvent", "OnBuildingModifiedEvent" )

    self:RegisterHandler( self.parentBuilding, "ActivateResourceBuildingEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "DeactivateResourceBuildingEvent", "OnBuildingModifiedEvent" )

    self:RegisterHandler( self.parentBuilding, "BuildingPoweredEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingPowerOffEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingResourceGrantedEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingResourceMissingEvent", "OnBuildingModifiedEvent" )

    self:RegisterHandler( self.parentBuilding, "BuildingBuildEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "DestroyRequest", "OnBuildingModifiedEvent" )

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )
end

function compressor_liquid_menu:OnItemEquippedEvent( evt )

    self:UpdateMenuIcons()
end

function compressor_liquid_menu:OnItemUnequippedEvent( evt )

    self:UpdateMenuIcons()
end

function compressor_liquid_menu:OnStartBuildingEvent( evt )

    self:UpdateMenuIcons()
end

function compressor_liquid_menu:OnBuildingBuildEndEvent( evt )

    self:UpdateMenuIcons()
end

function compressor_liquid_menu:OnBuildingModifiedEvent( evt )

    self:UpdateMenuIcons()
end

function compressor_liquid_menu:OnEnterBuildMenuEvent( evt )

    self.showMenu = 1

    self:UpdateMenuIcons()
end

function compressor_liquid_menu:OnEnterFighterModeEvent( evt )

    self.showMenu = 0

    self:UpdateMenuIcons()
end

function compressor_liquid_menu:UpdateMenuIcons()

    if ( self.parentBuilding == nil or self.parentBuilding == INVALID_ID or not EntityService:IsAlive( self.parentBuilding ) ) then
        self.data:SetInt("liquid_visible", 0)
        return
    end

    if ( not self:IsCompressedResourceFilled() ) then

        self.data:SetString("liquid_icon", "gui/hud/resource_icons/compressed_resources_bigger")
        self.data:SetString("liquid_name", "gui/hud/messages/compressors_with_liquid_icon/connect_resource")
    end

    self:SetMenuVisible()
end

function compressor_liquid_menu:IsCompressedResourceFilled()

    local resource = ""

    local resourceConverterComponent = EntityService:GetComponent( self.parentBuilding, "ResourceConverterComponent" )
    if ( resourceConverterComponent == nil ) then
        resource = ""
    else
        resource = resourceConverterComponent:GetField("last_ore_produced"):GetValue()
    end

    resource = resource or ""

    if ( resource == "" ) then
        return false
    end

    resource = resource:gsub( "_compressed", "" )

    --LogService:Log("resource " .. tostring(resource))

    local isMissingResources = self:HasMissingResources( resource )
    if ( isMissingResources ) then
        --LogService:Log("isMissingResources")
        return false
    end



    

    local resourceDef = ResourceManager:GetResource("GameplayResourceDef", resource)
    if ( resourceDef == nil ) then
        --LogService:Log("resourceDef == nil")
        return false
    end

    local resourceDefRef = reflection_helper(resourceDef)

    local itemBiggerIcon = resourceDefRef.bigger_icon

    self.data:SetString("liquid_icon", itemBiggerIcon)
    self.data:SetString("liquid_name", "")

    return true
end

function compressor_liquid_menu:HasMissingResources( resource )

    local buildingStatusComponent = EntityService:GetComponent( self.parentBuilding, "BuildingStatusComponent" )
    if ( buildingStatusComponent == nil ) then
        return false
    end

    local buildingStatusComponentRef = reflection_helper( buildingStatusComponent )

    --LogService:Log("buildingStatusComponentRef " .. tostring(buildingStatusComponentRef))

    if ( buildingStatusComponentRef ~= nil and buildingStatusComponentRef.status and buildingStatusComponentRef.status.missing_resources and buildingStatusComponentRef.status.missing_resources.count > 0 ) then

        for i = 1,buildingStatusComponentRef.status.missing_resources.count do

            local missingResource = buildingStatusComponentRef.status.missing_resources[i] or ""

            if ( missingResource ~= "" and missingResource == resource ) then

                return true
            end
        end
    end

    return false
end

function compressor_liquid_menu:SetMenuVisible()

    if ( self.parentBuilding == nil or self.parentBuilding == INVALID_ID or not EntityService:IsAlive( self.parentBuilding ) ) then
        self.data:SetInt("liquid_visible", 0)
        return
    end

    local visible = 0

    self.showMenu = self.showMenu or 0

    if ( BuildingService:IsBuildingFinished( self.parentBuilding ) ) then
        visible = self.showMenu
    end

    self.data:SetInt("liquid_visible", visible)
end

return compressor_liquid_menu