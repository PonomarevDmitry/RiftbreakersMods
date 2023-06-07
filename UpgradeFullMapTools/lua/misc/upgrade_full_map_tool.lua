local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'upgrade_full_map_tool' ( tool )

function upgrade_full_map_tool:__init()
    tool.__init(self,self)
end

function upgrade_full_map_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function upgrade_full_map_tool:OnInit()

    local markerName = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity( markerName, self.entity )

    self.scaleMap = {
        1,
    }

    self.categoryName = self.data:GetStringOrDefault("category_name", "") or ""

    self.selectedCategory = ""

    local markerDB = EntityService:GetDatabase( self.childEntity )

    if ( self.categoryName ~= "" ) then

        markerDB:SetInt("building_visible", 1)

        local selectorDB = EntityService:GetDatabase( self.selector )

        self.selectedCategory = selectorDB:GetStringOrDefault( self.categoryName, "" ) or ""

        if ( self.selectedCategory ~= "" ) then

            local menuIcon = "gui/hud/building_icons/" .. self.selectedCategory ..  "_structures_neutral"

            markerDB:SetString("building_icon", menuIcon)
            markerDB:SetString("message_text", "")
        else

            markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("message_text", "gui/hud/upgrade_full_map/category_not_selected")
        end
    else

        markerDB:SetString("message_text", "")
        markerDB:SetInt("building_visible", 0)
    end
end

function upgrade_full_map_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function upgrade_full_map_tool:AddedToSelection( entity )
end

function upgrade_full_map_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function upgrade_full_map_tool:OnUpdate()

    self.upgradeCosts = {}

    local upgradeCostsEntities = {}

    for entity in Iter( self.selectedEntities ) do

        if ( upgradeCostsEntities[entity] ~= nil ) then
            goto continue
        end

        upgradeCostsEntities[entity] = true

        local skinned = EntityService:IsSkinned(entity)



        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        if ( buildingDescRef.limit_name == "hq" ) then

            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_active", "selected")
            end

            goto continue
        end

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_pass", "selected" )
        end

        if ( not BuildingService:IsBuildingFinished( entity ) ) then
            goto continue
        end

        local list = BuildingService:GetUpgradeCosts( entity, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.upgradeCosts[resourceCost.first] == nil ) then
                self.upgradeCosts[resourceCost.first] = 0
            end

            self.upgradeCosts[resourceCost.first] = self.upgradeCosts[resourceCost.first] + resourceCost.second
        end

        ::continue::
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )
    if ( onScreen ) then
        BuildingService:OperateUpgradeCosts( self.infoChild, self.playerId, self.upgradeCosts )
        BuildingService:OperateUpgradeCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateUpgradeCosts( self.infoChild, self.playerId, {} )
        BuildingService:OperateUpgradeCosts( self.corners, self.playerId, self.upgradeCosts )
    end
end

function upgrade_full_map_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        if ( not EntityService:HasComponent( entity, "BuildingComponent" ) ) then
            goto continue
        end

        if ( not EntityService:HasComponent( entity, "SelectableComponent" ) ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef == nil ) then
            goto continue
        end

        if ( self.categoryName ~= "" ) then

            if ( buildingDescRef.category ~= self.selectedCategory ) then

                goto continue
            end
        end

        if ( not BuildingService:CanUpgrade( entity, self.playerId ) ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    local distances = {}

    for entity in Iter( result ) do
        distances[entity] = EntityService:GetDistanceBetween( self.entity, entity )
    end

    local sorter = function( lh, rh )
        return distances[lh] < distances[rh]
    end

    table.sort(result, sorter)

    return result
end

function upgrade_full_map_tool:OnActivateSelectorRequest()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        if ( buildingDescRef.limit_name == "hq" ) then
            goto continue
        end

        if ( not BuildingService:IsBuildingFinished( entity ) ) then
            goto continue
        end

        QueueEvent( "UpgradeBuildingRequest", entity, self.playerId )

        ::continue::
    end
end

function upgrade_full_map_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

function upgrade_full_map_tool:OnRotateSelectorRequest(evt)
end

return upgrade_full_map_tool