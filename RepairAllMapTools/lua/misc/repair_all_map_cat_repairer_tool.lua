local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'repair_all_map_cat_repairer_tool' ( tool )

function repair_all_map_cat_repairer_tool:__init()
    tool.__init(self,self)
end

function repair_all_map_cat_repairer_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function repair_all_map_cat_repairer_tool:OnInit()

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

            markerDB:SetString("message_text", "")

            local menuIcon = "gui/hud/building_icons/" .. self.selectedCategory ..  "_structures_neutral"

            if ( ResourceManager:ResourceExists("Material", menuIcon) ) then

                markerDB:SetString("building_icon", menuIcon)
            else

                markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
            end
        else

            markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("message_text", "gui/hud/repair_all_map/building_category_not_selected")
        end
    else

        markerDB:SetString("message_text", "")
        markerDB:SetInt("building_visible", 0)
    end
end

function repair_all_map_cat_repairer_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function repair_all_map_cat_repairer_tool:AddedToSelection( entity )
end

function repair_all_map_cat_repairer_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function repair_all_map_cat_repairer_tool:OnUpdate()

    self.upgradeCosts = {}

    local upgradeCostsEntities = {}

    for entity in Iter( self.selectedEntities ) do

        if ( upgradeCostsEntities[entity] ~= nil ) then
            goto continue
        end

        upgradeCostsEntities[entity] = true

        local skinned = EntityService:IsSkinned(entity)



        local blueprintName = self:GetBlueprintName( entity )
        if ( blueprintName == "" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

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

function repair_all_map_cat_repairer_tool:FindEntitiesToSelect( selectorComponent )

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

        local blueprintName = self:GetBlueprintName( entity )

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


        local healthComponent = EntityService:GetComponent(entity, "HealthComponent")
        if ( healthComponent == nil ) then
            goto continue
        end

        local healthComponentRef = reflection_helper(healthComponent)

        if ( healthComponentRef.health < healthComponentRef.max_health ) then
            Insert(result, entity)
            goto continue
        end

        local database = EntityService:GetDatabase( entity )
        if ( database and database:HasInt("number_of_activations")) then

            local currentNumberOfActivations =  database:GetInt("number_of_activations")

            local blueprintDatabase = EntityService:GetBlueprintDatabase( entity )
            local maxNumberOfActivations = blueprintDatabase:GetInt("number_of_activations")

            if ( maxNumberOfActivations > currentNumberOfActivations ) then
                Insert(result, entity)
            end
        end

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

function repair_all_map_cat_repairer_tool:OnActivateSelectorRequest()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do

        if ( EntityService:GetGroup( entity ) == "##ruins##" ) then

            local database = EntityService:GetDatabase( entity )
            if ( database ) then

                local ruinsBlueprint = database:GetString("blueprint")

                local transform = EntityService:GetWorldTransform( entity )

                QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, ruinsBlueprint, transform, true )
            end
        else
            local child = EntityService:GetChildByName(entity, "##repair##")

            if ( BuildingService:CanAffordRepair( entity, self.playerId, -1 ) and not EntityService:IsAlive(child) ) then

                local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
                if ( buildingComponent ~= nil ) then

                    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
                    if ( mode ~= 2 ) then
                        return
                    end
                end

                QueueEvent( "ScheduleRepairBuildingRequest", entity, self.playerId )

                local database = EntityService:GetDatabase( entity )
                if ( database and database:HasInt("number_of_activations")) then

                    local currentNumberOfActivations =  database:GetInt("number_of_activations")

                    local blueprintDatabase = EntityService:GetBlueprintDatabase( entity )
                    local maxNumberOfActivations = blueprintDatabase:GetInt("number_of_activations")

                    if ( maxNumberOfActivations > currentNumberOfActivations ) then
                        database:SetInt("number_of_activations", maxNumberOfActivations)
                    end
                end
            end
        end
    end
end

function repair_all_map_cat_repairer_tool:GetBlueprintName( entity )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if( EntityService:GetGroup( entity ) == "##ruins##" ) then

        local database = EntityService:GetDatabase( entity )

        if ( database and database:HasString("blueprint") ) then

            blueprintName = database:GetString("blueprint")
        end
    end

    blueprintName = blueprintName or ""

    return blueprintName
end

function repair_all_map_cat_repairer_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

function repair_all_map_cat_repairer_tool:OnRotateSelectorRequest(evt)
end

return repair_all_map_cat_repairer_tool