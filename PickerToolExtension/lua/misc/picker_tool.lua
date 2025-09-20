local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/picker_tool_last_selected_blueprints_utils.lua")

class 'picker_tool' ( tool )

function picker_tool:__init()
    tool.__init(self,self)
end

function picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_picker", self.entity)
    self.menuEntity = EntityService:SpawnAndAttachEntity("misc/picker_tool/picker_tool_menu", self.entity)

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)

    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.selectedResourceComponents = {}

    self:FillSelectedBlueprints()

    self.previousMarkedRuins = {}
    -- Radius from player to highlight
    self.radiusShowRuins = 100.0

    self.list_name = "$picker_tool.last_selected_buildings"

    self.modeBuilding = 0
    self.modeBuildingLastSelected = 100

    self.defaultModesArray = { self.modeBuilding }

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeBuilding

    self.healingToolExists = ResourceManager:ResourceExists( "EntityBlueprint", "buildings/tools/heal_neutral_tool" ) and (mod_picker_tool_extension_heal_neutral_tool ~= nil and mod_picker_tool_extension_heal_neutral_tool == 1);
    self.activateBioAnomaliesExists = ResourceManager:ResourceExists( "EntityBlueprint", "buildings/tools/spawner_activate" ) and (mod_picker_tool_extension_spawner_activate_tool ~= nil and mod_picker_tool_extension_spawner_activate_tool == 1);
    self.wrecksEraserExists = ResourceManager:ResourceExists( "EntityBlueprint", "buildings/tools/eraser_wrecks" ) and (mod_picker_tool_extension_eraser_wrecks_tool ~= nil and mod_picker_tool_extension_eraser_wrecks_tool == 1);
    self.minesEraserExists = ResourceManager:ResourceExists( "EntityBlueprint", "buildings/tools/eraser_mines" ) and (mod_picker_tool_extension_eraser_mines_tool ~= nil and mod_picker_tool_extension_eraser_mines_tool == 1);
    self.rocksEraserExists = ResourceManager:ResourceExists( "EntityBlueprint", "buildings/tools/eraser_rocks" ) and (mod_picker_tool_extension_eraser_rocks_tool ~= nil and mod_picker_tool_extension_eraser_rocks_tool == 1);
    self.lootCollectorExists = ResourceManager:ResourceExists( "EntityBlueprint", "buildings/tools/loot_collecting" ) and (mod_picker_tool_extension_loot_collecting_tool ~= nil and mod_picker_tool_extension_loot_collecting_tool == 1);

    self.floorRebuilderExists = ResourceManager:ResourceExists( "EntityBlueprint", "buildings/tools/floor_rebuilder" );
    self.ruinsEraserExists = ResourceManager:ResourceExists( "EntityBlueprint", "buildings/tools/sell_2_ruins_eraser" ) and (mod_picker_tool_extension_ruins_eraser_tool ~= nil and mod_picker_tool_extension_ruins_eraser_tool == 1);

    self.floraEraserExists = ResourceManager:ResourceExists( "EntityBlueprint", "buildings/tools/eraser_flora" ) and (mod_picker_tool_extension_eraser_flora_tool ~= nil and mod_picker_tool_extension_eraser_flora_tool == 1);
    self.floraFertilizerExists = ResourceManager:ResourceExists( "EntityBlueprint", "buildings/tools/fertilizer_flora" ) and (mod_picker_tool_extension_fertilizer_flora_tool ~= nil and mod_picker_tool_extension_fertilizer_flora_tool == 1);

    self:SetBuildingIcon()
end

function picker_tool:SetBuildingIcon()

    local messageText = ""
    local buildingIconVisible = 0
    local buildingIcon = ""

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        local indexBuilding = self.selectedMode - self.modeBuildingLastSelected

        local buildingNumber = #self.lastSelectedBuildingsArray - indexBuilding

        local buildingBlueprint = self.lastSelectedBuildingsArray[buildingNumber]

        self.lastSelectedBuilding = buildingBlueprint

        local menuIcon, buildingDescRef = self:GetMenuIcon( buildingBlueprint )

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1

            messageText = "${gui/hud/picker_tool/last_building} " .. tostring(indexBuilding + 1) .. ":\n${" .. buildingDescRef.localization_id .. "}"
        end
    else

        --messageText = self:GetLastBuildinsDescription()
    end

    local markerDB = EntityService:GetOrCreateDatabase( self.menuEntity )
    
    markerDB:SetInt("building_icon_visible", buildingIconVisible)
    markerDB:SetString("building_icon", buildingIcon)
    markerDB:SetString("message_text", messageText)
end

function picker_tool:GetLastBuildinsDescription()

    local buildingsIcons = ""

    local lineLength = 0
    local maxLineLength = 40

    for i=#self.lastSelectedBuildingsArray,1,-1 do

        local buildingBlueprint = self.lastSelectedBuildingsArray[i]

        local menuIcon, buildingDescRef = self:GetMenuIcon( buildingBlueprint )

        if ( menuIcon == "" ) then
            goto labelContinue
        end

        if ( lineLength > 0 ) then

            lineLength = lineLength + 1
            buildingsIcons = buildingsIcons .. " "
        end

        local countStringLen = 2

        if ( lineLength + countStringLen + 1 > maxLineLength ) then

            buildingsIcons = buildingsIcons .. "\n"
            lineLength = 0

        else
            buildingsIcons = buildingsIcons .. " "
            lineLength = lineLength + 1
        end

        lineLength = lineLength + countStringLen

        buildingsIcons = buildingsIcons .. '<img="' .. menuIcon .. '">'

        ::labelContinue::
    end

    return buildingsIcons
end

function picker_tool:FillSelectedBlueprints()

    self.resourceBluprintsNames = {

        "carbonium_factory",
        "steel_factory",
        "rare_element_mine",

        "liquid_pump",

        "bio_condenser",

        "geothermal_powerplant",
        "gas_extractor",

        "carbonium_powerplant",
    }

    self.resourceVolumeBluprintsNames = {

        "carbonium_factory",
        "steel_factory",
        "rare_element_mine",

        "geothermal_powerplant",
        "gas_extractor",

        "carbonium_powerplant",
    }

    local isCampaignBiome = MissionService:IsCampaignBiome()

    if ( isCampaignBiome ) then
        self:AddExpanedArsenalCampaignEntities( self.resourceBluprintsNames )
        self:AddExpanedArsenalCampaignEntities( self.resourceVolumeBluprintsNames )

        self:AddExpanedArsenalSurvivalEntities( self.resourceBluprintsNames )
        self:AddExpanedArsenalSurvivalEntities( self.resourceVolumeBluprintsNames )
    else
        self:AddExpanedArsenalSurvivalEntities( self.resourceBluprintsNames )
        self:AddExpanedArsenalSurvivalEntities( self.resourceVolumeBluprintsNames )

        self:AddExpanedArsenalCampaignEntities( self.resourceBluprintsNames )
        self:AddExpanedArsenalCampaignEntities( self.resourceVolumeBluprintsNames )
    end

    self.selectedBluprintsHash = {

        ["wind_turbine"] = "buildings/energy/wind_turbine",
        ["solar_panels"] = "buildings/energy/solar_panels",

        ["floor_desert_1x1"] = "buildings/decorations/floor_desert_1x1",

        ["floor_acid_1x1"] = "buildings/decorations/floor_acid_1x1",

        ["cryo_station"] = "buildings/main/cryo_station",

        ["carbonium_factory"] = "buildings/resources/carbonium_factory",
        ["steel_factory"] = "buildings/resources/steel_factory",
        ["rare_element_mine"] = "buildings/resources/rare_element_mine",

        ["carbonium_powerplant"] = "buildings/energy/carbonium_powerplant",

        ["liquid_pump"] = "buildings/resources/liquid_pump",

        ["geothermal_powerplant"] = "buildings/energy/geothermal_powerplant",

        ["gas_extractor"] = "buildings/resources/gas_extractor",

        ["bio_condenser"] = "buildings/resources/bio_condenser",

        -- Expaned Arsenal Entities
        ["acid_refinery"] = "buildings/resources/acid_refinery",
        ["magma_lifter"] = "buildings/resources/magma_lifter",
        ["supercoolant_siphon"] = "buildings/resources/supercoolant_siphon",

        ["morphium_extractor"] = "buildings/resources/morphium_extractor",

        ["survival_acid_refinery"] = "buildings/resources/survival_acid_refinery",
        ["survival_magma_lifter"] = "buildings/resources/survival_magma_lifter",
        ["survival_supercoolant_siphon"] = "buildings/resources/survival_supercoolant_siphon",
    }
end

function picker_tool:AddExpanedArsenalCampaignEntities( list )

    Insert( list, "acid_refinery" )
    Insert( list, "magma_lifter" )
    Insert( list, "supercoolant_siphon" )

    Insert( list, "morphium_extractor" )
end

function picker_tool:AddExpanedArsenalSurvivalEntities( list )

    Insert( list, "survival_acid_refinery" )
    Insert( list, "survival_magma_lifter" )
    Insert( list, "survival_supercoolant_siphon" )
end

function picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function picker_tool:AddedToSelection( entity )

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        self.selectedResourceComponents = self.selectedResourceComponents or {}

        if ( not EntityService:HasComponent( entity, "WaterVolumeComponent" ) ) then

            local childrenList = EntityService:GetChildren( entity, false )

            for childResource in Iter( childrenList ) do

                if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
                    goto labelContinue
                end

                if ( not EntityService:HasComponent( childResource, "SelectableComponent" ) ) then
                    goto labelContinue
                end

                if ( IndexOf( self.selectedResourceComponents, childResource ) == nil ) then
                    Insert( self.selectedResourceComponents, childResource )
                end

                QueueEvent( "SelectEntityRequest", childResource )

                ::labelContinue::
            end
        end

    elseif ( EntityService:HasComponent( entity, "ResourceComponent" ) ) then

        if ( EntityService:HasComponent( entity, "SelectableComponent" ) ) then
            QueueEvent( "SelectEntityRequest", entity )
        end

    elseif ( self.healingToolExists and EntityService:HasComponent( entity, "HealthComponent" ) and self.isNeutralUnit(entity, self.player) ) then

        if ( EntityService:HasComponent( entity, "SelectableComponent" ) ) then
            QueueEvent( "SelectEntityRequest", entity )
        end
    elseif ( self.activateBioAnomaliesExists and self.isBioAnomaly(entity) ) then

        self:SetEntitySelectedMaterial( entity, "hologram/current" )

    elseif ( self.wrecksEraserExists and self.isWreck(entity) ) then

        self:SetEntitySelectedMaterial( entity, "hologram/grey" )

    elseif ( self.minesEraserExists and self.isLandMine(entity) ) then

        self:SetEntitySelectedMaterial( entity, "hologram/deny" )
        
    elseif ( self.rocksEraserExists and self.isRock(entity) ) then

        self:SetEntitySelectedMaterial( entity, "hologram/active" )

    elseif ( ( self.floraEraserExists or self.floraFertilizerExists ) and self.isFlora(entity) ) then

        self:SetEntitySelectedMaterial( entity, "hologram/pass" )

    elseif ( self.lootCollectorExists and self.isLoot(entity, self.player) ) then

    else

        self:SetEntitySelectedMaterial( entity, "hologram/current" )
    end
end

function picker_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function picker_tool:RemoveEntitySelectedMaterial( entity )

    EntityService:RemoveMaterial( entity, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function picker_tool:RemovedFromSelection( entity )

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        self.selectedResourceComponents = self.selectedResourceComponents or {}

        if ( not EntityService:HasComponent( entity, "WaterVolumeComponent" ) ) then

            local childrenList = EntityService:GetChildren( entity, false )

            for childResource in Iter( childrenList ) do

                if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
                    goto labelContinue
                end

                if ( not EntityService:HasComponent( childResource, "SelectableComponent" ) ) then
                    goto labelContinue
                end

                if ( IndexOf( self.selectedResourceComponents, childResource ) ~= nil ) then
                    Remove( self.selectedResourceComponents, childResource )
                end

                QueueEvent( "DeselectEntityRequest", childResource )

                ::labelContinue::
            end
        end

    elseif ( EntityService:HasComponent( entity, "ResourceComponent" ) ) then

        if ( EntityService:HasComponent( entity, "SelectableComponent" ) ) then
            QueueEvent( "DeselectEntityRequest", entity )
        end

    elseif ( self.healingToolExists and EntityService:HasComponent( entity, "HealthComponent" ) and self.isNeutralUnit(entity, self.player) ) then

        if ( EntityService:HasComponent( entity, "SelectableComponent" ) ) then
            QueueEvent( "DeselectEntityRequest", entity )
        end
    elseif ( self.activateBioAnomaliesExists and self.isBioAnomaly(entity) ) then

        self:RemoveEntitySelectedMaterial( entity )

    elseif ( self.wrecksEraserExists and self.isWreck(entity) ) then

        self:RemoveEntitySelectedMaterial( entity )

    elseif ( self.minesEraserExists and self.isLandMine(entity) ) then

        self:RemoveEntitySelectedMaterial( entity )

    elseif ( self.rocksEraserExists and self.isRock(entity) ) then

        self:RemoveEntitySelectedMaterial( entity )

    elseif ( ( self.floraEraserExists or self.floraFertilizerExists ) and self.isFlora(entity) ) then

        self:RemoveEntitySelectedMaterial( entity )

    elseif ( self.lootCollectorExists and self.isLoot(entity, self.player) ) then

    else

        self:RemoveEntitySelectedMaterial( entity )
    end
end

function picker_tool:OnUpdate()

    self:HighlightRuins()

    for entity in Iter( self.selectedEntities ) do

        self:AddedToSelection( entity )
    end
end

function picker_tool:FindEntitiesToSelect( selectorComponent )

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then
        return {}
    end

    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local selectorPosition = selectorComponent.position

    local boundsSizeMin = { x=1.0, y=4.0, z=1.0 }
    local boundsSizeMax = { x=1.0, y=100.0, z=1.0 }
    
    local scaleVectorMin = VectorMulByNumber(boundsSizeMin, self.currentScale - 0.5)
    local scaleVectorMax = VectorMulByNumber(boundsSizeMax, self.currentScale - 0.5)

    local minScaleHalf = VectorSub(selectorPosition, scaleVectorMin)
    local maxScaleHalf = VectorAdd(selectorPosition, scaleVectorMax)

    scaleVectorMin = VectorMulByNumber(boundsSizeMin, self.currentScale)
    scaleVectorMax = VectorMulByNumber(boundsSizeMax, self.currentScale)

    local min = VectorSub(selectorPosition, scaleVectorMin)
    local max = VectorAdd(selectorPosition, scaleVectorMax)

    scaleVectorMin = VectorMulByNumber(boundsSizeMin, self.currentScale + 1)
    scaleVectorMax = VectorMulByNumber(boundsSizeMax, self.currentScale + 1)

    local minPlus = VectorSub(selectorPosition, scaleVectorMin)
    local maxPlus = VectorAdd(selectorPosition, scaleVectorMax)

    local sorter = function( lhs, rhs )
        local position1 = EntityService:GetPosition( lhs )
        local position2 = EntityService:GetPosition( rhs )
        local distance1 = Distance( selectorPosition, position1 )
        local distance2 = Distance( selectorPosition, position2 )
        return distance1 < distance2
    end

    self:AddRuins( selectedItems, minScaleHalf, maxScaleHalf, sorter )

    self:AddResourceVolumes( selectedItems, minScaleHalf, maxScaleHalf, sorter )

    self:AddResourceComponents( selectedItems, minScaleHalf, maxScaleHalf, sorter )

    if ( self.activateBioAnomaliesExists ) then
        self:AddBioAnomalies( selectedItems, min, max, sorter )
    end

    if ( self.healingToolExists ) then
        self:AddNeutralUnits( selectedItems, min, max, sorter )
    end

    if ( self.wrecksEraserExists ) then
        self:AddWrecks( selectedItems, minPlus, maxPlus, sorter )
    end

    if ( self.minesEraserExists ) then
        self:AddMines( selectedItems, minPlus, maxPlus, sorter )
    end

    if ( self.rocksEraserExists ) then
        self:AddRocks( selectedItems, minScaleHalf, maxScaleHalf, sorter )
    end

    if ( self.floraEraserExists or self.floraFertilizerExists ) then
        self:AddFlora( selectedItems, min, max, sorter )
    end

    if ( self.lootCollectorExists ) then
        self:AddLoot( selectedItems, min, max, sorter )
    end

    return selectedItems
end

function picker_tool:AddRuins( selectedItems, min, max )

    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    ConcatUnique( selectedItems, ruins )
end

function picker_tool:AddResourceVolumes( selectedItems, min, max, sorter )

    local resourceVolumeEntities = {}

    local predicate = {

        signature="ResourceVolumeComponent"
    }

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( resourceVolumeEntities, entity ) ~= nil ) then
            goto labelContinue
        end

        if ( not self.isResourceVolume(entity) ) then
            goto labelContinue
        end

        Insert( resourceVolumeEntities, entity )

        ::labelContinue::
    end

    table.sort(resourceVolumeEntities, sorter)

    ConcatUnique( selectedItems, resourceVolumeEntities )
end

function picker_tool:AddResourceComponents( selectedItems, min, max, sorter )

    local resourceComponents = {}

    local predicate = {

        signature="ResourceComponent"
    }

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( resourceComponents, entity ) ~= nil ) then
            goto labelContinue
        end

        Insert( resourceComponents, entity )

        ::labelContinue::
    end

    table.sort(resourceComponents, sorter)

    ConcatUnique( selectedItems, resourceComponents )
end

function picker_tool:AddNeutralUnits( selectedItems, min, max, sorter )

    local result = {}

    local predicate = {

        signature = "HealthComponent",

        filter = function(entity)

            if ( not EntityService:IsAlive(entity) ) then
                return false
            end

            if ( not HealthService:IsAlive(entity) ) then
                return false
            end

            if ( EntityService:IsInTeamRelation(self.player, entity, "hostility") ) then

                return false
            end

            local healthComponent = EntityService:GetComponent( entity, "HealthComponent")

            local healthComponentRef = reflection_helper( healthComponent )
            if ( healthComponentRef.max_health < 10 ) then
                return false
            end

            if ( EntityService:HasComponent( entity, "AIUnitComponent" ) or EntityService:HasComponent( entity, "NeutralUnitComponent" ) ) then

                return true
            end

            return false
        end
    }

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end

    table.sort(result, sorter)

    ConcatUnique( selectedItems, result )
end

function picker_tool:AddBioAnomalies( selectedItems, min, max, sorter )

    local result = {}

    local tempCollection = FindService:FindEntitiesByGroupInBox( "loot_container", min, max )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto labelContinue
        end

        local idComponentName = EntityService:GetName( entity )

        -- Ignore Into Dark Anomaly to do not create a soft lock. 
        if ( idComponentName == "dlc_2_anomaly" or idComponentName == "swamp_harvest_anomaly" ) then
            goto labelContinue
        end

        local interactiveComponent = EntityService:GetConstComponent( entity, "InteractiveComponent" )
        if ( interactiveComponent == nil ) then
            goto labelContinue
        end

        local interactiveComponentRef = reflection_helper( interactiveComponent )
        if ( interactiveComponentRef.slot ~= "HARVESTER" ) then
            goto labelContinue
        end

        local databaseEntity = EntityService:GetOrCreateDatabase( entity )
        if ( databaseEntity == nil ) then
            goto labelContinue
        end
            
        if ( not databaseEntity:HasString("wave_logic_file") and not databaseEntity:HasString("boss_logic_file") ) then

            goto labelContinue
        end

        if ( databaseEntity:HasString("forced_group") ) then

            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end

    table.sort(result, sorter)

    ConcatUnique( selectedItems, result )
end

function picker_tool:AddWrecks( selectedItems, min, max, sorter )

    local result = {}
    
    local aabb = {}
    aabb.min = min
    aabb.max = max

    local tempCollection = FindService:FindEntitiesByTeamInBox( "wreck", aabb )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end

    table.sort(result, sorter)

    ConcatUnique( selectedItems, result )
end

function picker_tool:AddMines( selectedItems, min, max, sorter )

    local result = {}

    local predicate = {

        signature="TerrainAffectedComponent",

        filter = function(entity)

            local terrainAffectedComponent = EntityService:GetComponent( entity, "TerrainAffectedComponent" )
            if( terrainAffectedComponent == nil ) then
                return false
            end

            local name = terrainAffectedComponent:GetField("name"):GetValue()
            if ( name ~= "mine" ) then
                return false
            end

            return true
        end
    }
    
    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end

    table.sort(result, sorter)

    ConcatUnique( selectedItems, result )
end

function picker_tool:AddFlora( selectedItems, min, max, sorter )

    local result = {}

    local predicate = {

        signature = "TypeComponent",

        filter = function(entity)

            local blueprintName = EntityService:GetBlueprintName(entity)

            if ( EntityService:CompareType( entity, "flora" ) ) then
                return true
            end

            if ( mod_flora_eraser_enable_creeper and mod_flora_eraser_enable_creeper == 1 ) then

                if ( string.find(blueprintName, "units/ground/cosmic_crystal_creeper_branch" ) ~= nil ) then

                    return true
                end

                if ( string.find(blueprintName, "units/ground/crystal_creeper_branch" ) ~= nil ) then

                    return true
                end

                if ( string.find(blueprintName, "units/ground/creeper_branch" ) ~= nil ) then

                    return true
                end
            end

            return false
        end
    }

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end



    predicate = {
        signature = "VegetationLifecycleEnablerComponent"
    }

    tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue2
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue2
        end

        if ( not EntityService:HasComponent( entity, "VegetationLifecycleEnablerComponent") ) then
            goto labelContinue2
        end

        Insert( result, entity )

        ::labelContinue2::
    end





    table.sort(result, sorter)

    ConcatUnique( selectedItems, result )
end

function picker_tool:AddRocks( selectedItems, min, max, sorter )

    local result = {}

    local predicate = {

        filter = function( entity )

            local blueprintName = EntityService:GetBlueprintName( entity )
            if ( blueprintName == "" or blueprintName == nil ) then
                return false
            end
        
            local stringIndex = string.find( blueprintName, "props/rocks/" )
        
            if ( stringIndex == nil or stringIndex ~= 1 ) then
                return false
            end

            if ( EntityService:GetComponent( entity, "PhysicsComponent") ~= nil ) then

                local groupId = EntityService:GetPhysicsGroupId( entity )

                if ( groupId == "destructible" ) then

                    return true
                else
                    return false
                end
            end

            return true
        end
    }
    
    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end

    table.sort(result, sorter)

    ConcatUnique( selectedItems, result )
end

function picker_tool:AddLoot( selectedItems, min, max, sorter )

    local result = {}

    local predicate = {

        signature = "BlueprintComponent,IdComponent,ParentComponent",

        filter = function(entity)

            local entity_name = EntityService:GetName(entity);
            if ( entity_name ~= "#loot#" ) then
                return false;
            end

            if ( not EntityService:IsAlive(entity) ) then
                return false
            end

            local test_entity = EntityService:GetParent( entity )
            if ( test_entity == INVALID_ID ) then
                test_entity = entity
            end

            if EntityService:GetComponent( test_entity, "PhysicsComponent") == nil then
                return false
            end

            return ItemService:CanFitResourceGiver( self.player, test_entity )
        end
    }
    
    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end

    table.sort(result, sorter)

    ConcatUnique( selectedItems, result )
end

function picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        if ( IndexOf( entities, entity ) ~= nil ) then
            goto labelContinue
        end

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        if ( buildingDesc == nil ) then
            goto labelContinue
        end

        if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) == false ) then
            goto labelContinue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
            goto labelContinue
        end

        Insert(entities, entity)

        ::labelContinue::
    end

    return entities
end

picker_tool.isBuilding = function( entity )
    if( EntityService:GetGroup( entity ) == "##ruins##" ) then

        return false
    end

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        return false
    end

    if ( EntityService:HasComponent( entity, "ResourceComponent" ) ) then

        return false
    end

    return true
end

picker_tool.isRuins = function ( entity )

    if( EntityService:GetGroup( entity ) == "##ruins##" ) then

        return true
    end

    return false
end

picker_tool.isResource = function ( entity )

    if ( EntityService:HasComponent( entity, "ResourceComponent" ) ) then

        return true
    end

    return false
end

picker_tool.isResourceVolume = function ( entity )

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        local childrenList = EntityService:GetChildren( entity, false )

        for childResource in Iter( childrenList ) do

            if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
                goto labelContinue
            end

            local resourceValue = EntityService:GetResourceAmount( childResource )
            if ( resourceValue.second > 0 ) then

                return true
            end

            ::labelContinue::
        end
    end

    return false
end

picker_tool.isNeutralUnit = function ( entity, player )

    if ( entity == nil or entity == INVALID_ID ) then

        return false
    end

    if ( not EntityService:HasComponent( entity, "HealthComponent" ) )  then
        return false
    end

    local healthComponent = EntityService:GetComponent( entity, "HealthComponent")

    local healthComponentRef = reflection_helper( healthComponent )
    if ( healthComponentRef.max_health < 10 ) then
        return false
    end

    if ( EntityService:HasComponent( entity, "AIUnitComponent" ) or EntityService:HasComponent( entity, "NeutralUnitComponent" ) ) then

        if ( not EntityService:IsInTeamRelation(player, entity, "hostility") ) then

            if ( HealthService:IsAlive(entity) ) then
                return true
            end
        end
    end

    return false
end

picker_tool.isBioAnomaly = function( entity )

    if ( entity == nil or entity == INVALID_ID ) then

        return false
    end

    local entityGroup = EntityService:GetGroup( entity )

    if ( entityGroup ~= "loot_container" ) then

        return false
    end

    local idComponentName = EntityService:GetName( entity )

    -- Ignore Into Dark Anomaly to do not create a soft lock. 
    if ( idComponentName == "dlc_2_anomaly" or idComponentName == "swamp_harvest_anomaly" ) then
        return false
    end

    local interactiveComponent = EntityService:GetConstComponent( entity, "InteractiveComponent" )
    if ( interactiveComponent == nil ) then
        return false
    end

    local interactiveComponentRef = reflection_helper( interactiveComponent )
    if ( interactiveComponentRef.slot ~= "HARVESTER" ) then
        return false
    end

    local databaseEntity = EntityService:GetOrCreateDatabase( entity )
    if ( databaseEntity == nil ) then
        return false
    end
            
    if ( not databaseEntity:HasString("wave_logic_file") and not databaseEntity:HasString("boss_logic_file") ) then

        return false
    end

    if ( databaseEntity:HasString("forced_group") ) then

        return false
    end

    return true
end

picker_tool.isWreck = function( entity )

    if ( EntityService:HasComponent( entity, "TeamComponent" ) ) then
            
        if ( EntityService:GetTeam( entity ) == EntityService:GetTeam("wreck") ) then
            
            return true
        end
    end
    
    if ( EntityService:HasComponent( entity, "WreckTeamComponent" ) ) then
            
        return true
    end

    return false
end

picker_tool.isLandMine = function( entity )

    if ( EntityService:HasComponent( entity, "TerrainAffectedComponent" ) ) then
            
        local terrainAffectedComponent = EntityService:GetComponent( entity, "TerrainAffectedComponent" )

        if( terrainAffectedComponent ~= nil ) then

            local name = terrainAffectedComponent:GetField("name"):GetValue()
            if ( name == "mine" ) then

                return true
            end
        end
    end

    return false
end

picker_tool.isRock = function( entity )

    local blueprintName = EntityService:GetBlueprintName( entity )
    if ( blueprintName == "" or blueprintName == nil ) then
        return false
    end
        
    local stringIndex = string.find( blueprintName, "props/rocks/" )
        
    if ( stringIndex == nil or stringIndex ~= 1 ) then
        return false
    end

    if ( EntityService:GetComponent( entity, "PhysicsComponent") ~= nil ) then

        local groupId = EntityService:GetPhysicsGroupId( entity )

        if ( groupId == "destructible" ) then

            return true
        else
            return false
        end
    end

    return true
end

picker_tool.isLoot = function ( entity, player )

    if ( entity == nil or entity == INVALID_ID ) then

        return false
    end

    local entity_name = EntityService:GetName(entity)
    if ( entity_name ~= "#loot#" ) then
        return false
    end

    local test_entity = EntityService:GetParent( entity )
    if ( test_entity == INVALID_ID ) then
        test_entity = entity
    end

    if EntityService:GetComponent( test_entity, "PhysicsComponent") == nil then
        return false
    end

    return ItemService:CanFitResourceGiver( player, test_entity )
end

picker_tool.isFlora = function( entity )

    if ( entity == nil or entity == INVALID_ID ) then

        return false
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( EntityService:HasComponent( entity, "TypeComponent") ) then

        if ( EntityService:CompareType( entity, "flora" ) ) then
            return true
        end
    end

    if ( mod_flora_eraser_enable_creeper and mod_flora_eraser_enable_creeper == 1 ) then

        if ( string.find(blueprintName, "units/ground/cosmic_crystal_creeper_branch" ) ~= nil ) then

            return true
        end

        if ( string.find(blueprintName, "units/ground/crystal_creeper_branch" ) ~= nil ) then

            return true
        end

        if ( string.find(blueprintName, "units/ground/creeper_branch" ) ~= nil ) then

            return true
        end
    end

    if ( EntityService:HasComponent( entity, "VegetationLifecycleEnablerComponent") ) then

        return true
    end

    return false
end

function picker_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        if ( self:ChangeSelectorToBlueprint(self.lastSelectedBuilding) ) then

            return
        end

        return
    end

    if ( self:ChangeSelectorToEntityByFilter( self.isBuilding ) ) then
        return
    end

    if ( self:ChangeSelectorToRuins() ) then
        return
    end



    if ( self:ChangeSelectorToEntityByFilter( self.isResource ) ) then
        return
    end



    if ( self.activateBioAnomaliesExists ) then

        if ( self:ChangeSelectorToTargetBlueprintByFilter( self.isBioAnomaly, "buildings/tools/spawner_activate", true ) ) then
            return
        end
    end



    local currentEntityPosition = EntityService:GetPosition( self.entity )

    if ( self:CheckPositionForInOutAttachment( currentEntityPosition ) ) then

        local blueprintName = "buildings/resources/pipe_straight"

        if ( self:ChangeSelectorToBlueprint( blueprintName ) ) then
            return
        end
    end





    if ( self.rocksEraserExists ) then

        if ( self:ChangeSelectorToTargetBlueprintByFilter( self.isRock, "buildings/tools/eraser_rocks", true ) ) then
            return
        end
    end

    if ( self.wrecksEraserExists ) then

        if ( self:ChangeSelectorToTargetBlueprintByFilter( self.isWreck, "buildings/tools/eraser_wrecks", true ) ) then
            return
        end
    end

    if ( self.minesEraserExists ) then

        if ( self:ChangeSelectorToTargetBlueprintByFilter( self.isLandMine, "buildings/tools/eraser_mines", true ) ) then
            return
        end
    end

    if ( self.lootCollectorExists ) then

        if ( self:ChangeSelectorToTargetBlueprintByFilter( self.isLoot, "buildings/tools/loot_collecting", true ) ) then
            return
        end
    end

    if ( self.healingToolExists ) then

        if ( self:ChangeSelectorToTargetBlueprintByFilter( self.isNeutralUnit, "buildings/tools/heal_neutral_tool", true ) ) then
            return
        end
    end
    
    if ( self.floraEraserExists or self.floraFertilizerExists ) then

        if ( self:ChangeSelectorToFlora() ) then
            return
        end
    end



    local terrainCellEntityId = EnvironmentService:GetTerrainCell(currentEntityPosition)

    if ( EntityService:HasComponent( terrainCellEntityId, "GameplayResourceLayerComponent")) then

        local gameplayResourceLayerComponentRef = reflection_helper(EntityService:GetComponent(terrainCellEntityId, "GameplayResourceLayerComponent"))

        if ( gameplayResourceLayerComponentRef.resource ~= nil and gameplayResourceLayerComponentRef.resource.resource ~= nil and gameplayResourceLayerComponentRef.resource.resource.id ~= nil ) then

            local resourceId = gameplayResourceLayerComponentRef.resource.resource.id or ""

            if ( resourceId ~= "" ) then

                local blueprintName = self:GetMineBlueprintName( resourceId, self.resourceBluprintsNames ) or ""

                if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
                    return
                end
            end
        end
    end








    if ( self:ChangeSelectorToEntityByFilter( self.isResourceVolume ) ) then
        return
    end

    

    local currentBiome = MissionService:GetCurrentBiomeName()

    if ( currentBiome == "caverns" ) then

        local minModificator = 0.05

        local windModificator = BuildingService:GetWindPowerModificator( self.entity )
        if ( windModificator >= minModificator ) then

            local lowName = "wind_turbine"
            local defaultBlueprintName = self.selectedBluprintsHash[lowName]

            local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

            if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
                return
            end
        end

        local solarModificator = BuildingService:GetSolarPowerModificator( self.entity )
        if ( solarModificator >= minModificator ) then

            local lowName = "solar_panels"
            local defaultBlueprintName = self.selectedBluprintsHash[lowName]

            local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

            if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
                return
            end
        end
    end








    if ( self:ChangeSelectorToFloor( currentEntityPosition ) ) then
        return
    end



    local terrainType, overrideTerrains = self:GetTerrainTypes( terrainCellEntityId )

    local isQuickSand = (terrainType == "quicksand")
    local hasDesertFloor = (IndexOf( overrideTerrains, "desert_floor" ) ~= nil)

    if ( isQuickSand and not hasDesertFloor ) then

        local lowName = "floor_desert_1x1"
        local defaultBlueprintName = self.selectedBluprintsHash[lowName]

        local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

        if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
            return
        end
    end

    local isCreeperArea = (IndexOf( overrideTerrains, "creeper_area" ) ~= nil)
    if ( isCreeperArea ) then

        local lowName = "floor_acid_1x1"
        local defaultBlueprintName = self.selectedBluprintsHash[lowName]

        local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

        if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
            return
        end
    end

    local isCryoGround = ( IndexOf( overrideTerrains, "cryo_ground" ) )
    local isHotGround = ( terrainType == "magma_hot_ground" or terrainType == "magma_very_hot_ground" or IndexOf( overrideTerrains, "magma_hot_ground" ) ~= nil or IndexOf( overrideTerrains, "magma_very_hot_ground" ) ~= nil )

    local isFloor = false
    for overrideTerrainType in Iter( overrideTerrains ) do

        if ( string.find(overrideTerrainType, "floor") ~= nil ) then

            isFloor = true
        end
    end

    if ( isHotGround and not isCryoGround and not isFloor ) then

        local lowName = "cryo_station"
        local defaultBlueprintName = self.selectedBluprintsHash[lowName]

        local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

        if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
            return
        end
    end

    


    if ( currentBiome == "acid" ) then

        local lowName = "floor_acid_1x1"
        local defaultBlueprintName = self.selectedBluprintsHash[lowName]

        local blueprintName = self:GetSelectorBlueprintName( lowName, defaultBlueprintName )

        if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
            return
        end
    end
end

function picker_tool:ChangeSelectorToRuins()

    for entity in Iter( self.selectedEntities ) do

        if ( not self.isRuins(entity) ) then
            goto labelContinue
        end

        local blueprintName = self:GetLinkedEntityBlueprint( entity ) or ""

        if ( blueprintName == "" ) then
            goto labelContinue
        end

        local currentTime = GetLogicTime()

        if ( self.ruinsEraserExists ) then

            local lastBlueprintName, lastEntityId = self:GetLastBlueprint("ruins", currentTime)

            if ( lastBlueprintName == blueprintName and entity == lastEntityId ) then

                if ( self:ChangeSelectorToBlueprint( "buildings/tools/sell_2_ruins_eraser", true ) ) then

                    self:SetLastBlueprint("ruins", currentTime, "buildings/tools/sell_2_ruins_eraser", entity)
                    return true
                end
            end
        end

        if ( self:ChangeSelectorToBlueprint( blueprintName ) ) then

            if ( self.ruinsEraserExists ) then
                self:SetLastBlueprint("ruins", currentTime, blueprintName, entity)
            end

            return true
        end

        ::labelContinue::
    end

    return false
end

function picker_tool:ChangeSelectorToFlora()

    for entity in Iter( self.selectedEntities ) do

        if ( not self.isFlora(entity) ) then
            goto labelContinue
        end

        local currentTime = GetLogicTime()

        local lastBlueprintName, lastEntityId = self:GetLastBlueprint("flora", currentTime)

        if ( self.floraEraserExists and (not self.floraFertilizerExists or lastBlueprintName ~= "buildings/tools/eraser_flora" or entity ~= lastEntityId ) ) then

            if ( self:ChangeSelectorToBlueprint( "buildings/tools/eraser_flora", true ) ) then

                self:SetLastBlueprint("flora", currentTime, "buildings/tools/eraser_flora", entity)

                return true
            end
        end

        if ( self.floraFertilizerExists and (not self.floraEraserExists or lastBlueprintName ~= "buildings/tools/fertilizer_flora" or entity ~= lastEntityId ) ) then

            if ( self:ChangeSelectorToBlueprint( "buildings/tools/fertilizer_flora", true ) ) then

                self:SetLastBlueprint("flora", currentTime, "buildings/tools/fertilizer_flora", entity)

                return true
            end
        end

        ::labelContinue::
    end

    return false
end

function picker_tool:ChangeSelectorToFloor( currentEntityPosition )

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, 0.5)

    local min = VectorSub(currentEntityPosition, scaleVector)
    local max = VectorAdd(currentEntityPosition, scaleVector)

    local possibleSelectedEnts = FindService:FindFloorsByBox( min, max )

    for entity in Iter( possibleSelectedEnts ) do

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto labelContinue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        if string.find( blueprintName, "4" ) then

            blueprintName = string.gsub( blueprintName, "4", "1" )

        elseif string.find( blueprintName, "3" ) then

            blueprintName = string.gsub( blueprintName, "3", "1" )

        elseif string.find( blueprintName, "2" ) then

            blueprintName = string.gsub( blueprintName, "2", "1" )
        end
                    
        local currentTime = GetLogicTime()

        if ( self.floorRebuilderExists ) then

            local lastBlueprintName, lastEntityId = self:GetLastBlueprint("floor", currentTime)

            if ( lastBlueprintName == blueprintName and entity == lastEntityId ) then

                if ( self:ChangeSelectorToBlueprint( "buildings/tools/floor_rebuilder", true ) ) then

                    self:SetLastBlueprint("floor", currentTime, "buildings/tools/floor_rebuilder", entity)
                    return true
                end
            end
        end

        if ( self:ChangeSelectorToBlueprint( blueprintName ) ) then

            if ( self.floorRebuilderExists ) then
                self:SetLastBlueprint("floor", currentTime, blueprintName, entity)
            end

            return true
        end

        ::labelContinue::
    end

    return false
end

function picker_tool:CheckPositionForInOutAttachment( currentEntityPosition )

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local vectorBounds = VectorMulByNumber(boundsSize, 4)

    local min = VectorSub(currentEntityPosition, vectorBounds)
    local max = VectorAdd(currentEntityPosition, vectorBounds)

    local possibleSelectedEnts = FindService:FindGridOwnersByBox( min, max )

    for entity in Iter( possibleSelectedEnts ) do

        local blueprintName = EntityService:GetBlueprintName( entity )

        --LogService:Log("blueprintName " .. blueprintName)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto labelContinue
        end

        local blueprint = ResourceManager:GetBlueprint( blueprintName )
        if ( blueprint == nil ) then
            goto labelContinue
        end

        local entityPerimeter = self:GetEntityArea( entity )

        local entityPerimeterPositions = self:GetPerimeterPositions( entityPerimeter )

        local resourceStorageComponent = blueprint:GetComponent( "ResourceStorageComponent")
        if ( resourceStorageComponent ~= nil ) then

            local resourceStorageRef = reflection_helper( resourceStorageComponent )
            if ( self:CheckEntityResourceStorageDesc( entity, currentEntityPosition, resourceStorageRef, entityPerimeter, entityPerimeterPositions ) ) then

                return true
            end
        end

        local resourceConverterDesc = blueprint:GetComponent("ResourceConverterDesc")
        if ( resourceConverterDesc ~= nil ) then

            local resourceConverterRef = reflection_helper(resourceConverterDesc)
            if ( resourceConverterRef ~= nil ) then

                --LogService:Log("blueprintName " .. blueprintName .. " resourceConverterRef " .. tostring(resourceConverterRef))

                if ( self:CheckEntityResourceConvererDesc( entity, currentEntityPosition, resourceConverterRef, entityPerimeter, entityPerimeterPositions ) ) then

                    return true
                end
            end
        end

        ::labelContinue::
    end

    return false
end

function picker_tool:GetEntityArea( entity )

    local entityPosition = EntityService:GetPosition( entity )

    local entityPerimeter = {}

    entityPerimeter.y = entityPosition.y

    entityPerimeter.minX = nil
    entityPerimeter.maxX = nil

    entityPerimeter.minZ = nil
    entityPerimeter.maxZ = nil

    local gridCullerComponent = EntityService:GetComponent( entity, "GridCullerComponent" )

    local gridCullerComponentRef = reflection_helper(gridCullerComponent)

    local indexes = gridCullerComponentRef.terrain_cell_entities
    for i=1,indexes.count do

        local idx = indexes[i].id

        local position = FindService:GetCellOrigin(idx)

        if ( entityPerimeter.minX == nil or entityPerimeter.minX > position.x ) then

            entityPerimeter.minX = position.x
        end

        if ( entityPerimeter.maxX == nil or entityPerimeter.maxX < position.x ) then

            entityPerimeter.maxX = position.x
        end

        if ( entityPerimeter.minZ == nil or entityPerimeter.minZ > position.z ) then

            entityPerimeter.minZ = position.z
        end

        if ( entityPerimeter.maxZ == nil or entityPerimeter.maxZ < position.z ) then

            entityPerimeter.maxZ = position.z
        end
    end


    entityPerimeter.minX = entityPerimeter.minX - 2
    entityPerimeter.maxX = entityPerimeter.maxX + 2

    entityPerimeter.minZ = entityPerimeter.minZ - 2
    entityPerimeter.maxZ = entityPerimeter.maxZ + 2

    return entityPerimeter
end

function picker_tool:GetPerimeterPositions( entityPerimeter )

    local result = {}

    local value = entityPerimeter.minZ + 2

    while (value < entityPerimeter.maxZ) do

        local newPosition = {}

        newPosition.x = entityPerimeter.maxX
        newPosition.y = entityPerimeter.y
        newPosition.z = value

        Insert(result, newPosition)

        --EntityService:SpawnEntity( "effects/auto_mines_laying/mine_created", newPosition, EntityService:GetTeam( self.entity ))

        value = value + 2
    end
    


    value = entityPerimeter.maxX - 2

    while (value > entityPerimeter.minX) do

        local newPosition = {}

        newPosition.x = value
        newPosition.y = entityPerimeter.y
        newPosition.z = entityPerimeter.maxZ

        Insert(result, newPosition)

        --EntityService:SpawnEntity( "effects/auto_mines_laying/mine_created", newPosition, EntityService:GetTeam( self.entity ))

        value = value - 2
    end
    


    value = entityPerimeter.maxZ - 2

    while (value > entityPerimeter.minZ) do

        local newPosition = {}

        newPosition.x = entityPerimeter.minX
        newPosition.y = entityPerimeter.y
        newPosition.z = value

        Insert(result, newPosition)

        --EntityService:SpawnEntity( "effects/auto_mines_laying/mine_created", newPosition, EntityService:GetTeam( self.entity ))

        value = value - 2
    end
    


    value = entityPerimeter.minX + 2

    while (value < entityPerimeter.maxX) do

        local newPosition = {}

        newPosition.x = value
        newPosition.y = entityPerimeter.y
        newPosition.z = entityPerimeter.minZ

        Insert(result, newPosition)

        --EntityService:SpawnEntity( "effects/auto_mines_laying/mine_created", newPosition, EntityService:GetTeam( self.entity ))

        value = value + 2
    end

    return result
end

function picker_tool:GetDistanceXZ( vector1, vector2 )
    local vector = {}
    vector.x = (vector2.x - vector1.x)
    vector.z = (vector2.z - vector1.z)
    return math.sqrt( vector.x * vector.x + vector.z * vector.z)
end

function picker_tool:CheckEntityResourceStorageDesc( entity, currentEntityPosition, resourceStorageRef, entityPerimeter, entityPerimeterPositions )

    if ( resourceStorageRef.Storages == nil or resourceStorageRef.Storages.count <= 0 ) then

        return false
    end

    local count = resourceStorageRef.Storages.count

    for i=1,count do

        local storage = resourceStorageRef.Storages[i]

        if ( storage.attachment == nil or storage.attachment.count == 0 ) then

            goto labelContinue
        end

        for attachmentIndex = 1,storage.attachment.count do
                                
            local attachmentName = storage.attachment[attachmentIndex]
                                    
            if ( attachmentName ~= nil and attachmentName ~= "" ) then

                local attachmentPosition = self:GetEntityAttachmentPosition(entity, attachmentName)

                local nearPerimeterPosition = self:GetNearPerimeterPosition(attachmentPosition, entityPerimeterPositions)

                local min,max = self:GetAttachmentBox(nearPerimeterPosition, entityPerimeter)
                
                if ( min.x <= currentEntityPosition.x and currentEntityPosition.x <= max.x and min.z <= currentEntityPosition.z and currentEntityPosition.z <= max.z ) then

                    return true
                end
            end
        end

        ::labelContinue::
    end

    return false
end

function picker_tool:GetEntityAttachmentPosition( entity, attachmentName )

    local attachmentHash = CalcHash(attachmentName)

    local effectComponent = EntityService:GetComponent( entity, "EffectComponent")
    if ( effectComponent ~= nil ) then

        local effectComponentRef = reflection_helper( effectComponent )

        if ( effectComponentRef.effects ~= nil and effectComponentRef.effects.count > 0 ) then
                
            for index = 1,effectComponentRef.effects.count do
                
                local effectRef = effectComponentRef.effects[index]
                    
                if ( effectRef.entity ~= nil and effectRef.entity.id ~= nil and effectRef.group ~= nil and effectRef.group.hash ~= nil ) then

                    if ( tostring(attachmentHash) == tostring(effectRef.group.hash) ) then

                        return EntityService:GetPosition(effectRef.entity.id)
                    end
                end
            end
        end
    end


    return EntityService:GetPosition(entity, attachmentName)
end

function picker_tool:CheckEntityResourceConvererDesc( entity, currentEntityPosition, resourceConverterRef, entityPerimeter, entityPerimeterPositions )

    local inValue = resourceConverterRef["in"]
    if ( inValue ~= nil and inValue.count > 0 ) then
                    
        if ( self:NearLocalAttachment( entity, currentEntityPosition, inValue, entityPerimeter, entityPerimeterPositions ) ) then

            return true
        end
    end

    local outValue = resourceConverterRef["out"]
    if ( outValue ~= nil and outValue.count > 0 ) then
                    
        if ( self:NearLocalAttachment( entity, currentEntityPosition, outValue, entityPerimeter, entityPerimeterPositions ) ) then

            return true
        end
    end

    return false
end

function picker_tool:NearLocalAttachment( entity, currentEntityPosition, converterArray, entityPerimeter, entityPerimeterPositions )

    for index = 1,converterArray.count do
                
        local gameResource = converterArray[index]

        if ( gameResource == nil or gameResource.value == nil or gameResource.value <= 0 ) then

            goto labelContinue
        end

        if ( EntityService:HasComponent( entity, "PipeComponent" ) ) then

            return true
        end

        --if ( gameResource.group ~= 1 and gameResource.group ~= 8 and gameResource.group ~= 12 ) then
        --
        --    goto labelContinue
        --end

        if ( gameResource.attachment == nil or gameResource.attachment.count == 0 ) then

            goto labelContinue
        end

        for attachmentIndex = 1,gameResource.attachment.count do
                                
            local attachmentName = gameResource.attachment[attachmentIndex]
                                    
            if ( attachmentName ~= nil and attachmentName ~= "" ) then

                local attachmentPosition = self:GetEntityAttachmentPosition(entity, attachmentName)

                local nearPerimeterPosition = self:GetNearPerimeterPosition(attachmentPosition, entityPerimeterPositions)

                local min,max = self:GetAttachmentBox(nearPerimeterPosition, entityPerimeter)
                
                if ( min.x <= currentEntityPosition.x and currentEntityPosition.x <= max.x and min.z <= currentEntityPosition.z and currentEntityPosition.z <= max.z ) then

                    return true
                end
            end
        end

        ::labelContinue::
    end

    return false
end

function picker_tool:GetNearPerimeterPosition( attachmentPosition, entityPerimeterPositions )

    local result = nil
    local minDistance = nil

    for newPosition in Iter( entityPerimeterPositions ) do
                
        local distance = self:GetDistanceXZ( attachmentPosition, newPosition )

        if ( minDistance == nil or distance < minDistance ) then

            minDistance = distance
            result = newPosition
        end
    end

    return result
end

function picker_tool:GetAttachmentBox(nearPerimeterPosition, entityPerimeter )

    local min = {}
    local max = {}

    min.x = 0
    min.z = 0
    
    max.x = 0
    max.z = 0

    if ( nearPerimeterPosition.x == entityPerimeter.minX ) then

        min.x = nearPerimeterPosition.x - 3
        max.x = nearPerimeterPosition.x + 1
    
        min.z = nearPerimeterPosition.z - 3
        max.z = nearPerimeterPosition.z + 3

    elseif ( nearPerimeterPosition.x == entityPerimeter.maxX ) then

        min.x = nearPerimeterPosition.x - 1
        max.x = nearPerimeterPosition.x + 3
    
        min.z = nearPerimeterPosition.z - 3
        max.z = nearPerimeterPosition.z + 3

    elseif ( nearPerimeterPosition.z == entityPerimeter.minZ ) then

        min.x = nearPerimeterPosition.x - 3
        max.x = nearPerimeterPosition.x + 3
    
        min.z = nearPerimeterPosition.z - 3
        max.z = nearPerimeterPosition.z + 1

    elseif ( nearPerimeterPosition.z == entityPerimeter.maxZ ) then

        min.x = nearPerimeterPosition.x - 3
        max.x = nearPerimeterPosition.x + 3
    
        min.z = nearPerimeterPosition.z - 1
        max.z = nearPerimeterPosition.z + 3
    end

    --EntityService:SpawnEntity( "effects/auto_mines_laying/mine_created", {x=min.x, y=0, z=min.z}, EntityService:GetTeam( self.entity ))
    --EntityService:SpawnEntity( "effects/auto_mines_laying/mine_created", {x=min.x, y=0, z=max.z}, EntityService:GetTeam( self.entity ))
    --EntityService:SpawnEntity( "effects/auto_mines_laying/mine_created", {x=max.x, y=0, z=min.z}, EntityService:GetTeam( self.entity ))
    --EntityService:SpawnEntity( "effects/auto_mines_laying/mine_created", {x=max.x, y=0, z=max.z}, EntityService:GetTeam( self.entity ))

    return min,max
end

function picker_tool:GetTerrainTypes( terrainCellEntityId )

    local terrainType = ""
    local overrideTerrains = {}

    if ( terrainCellEntityId ~= nil and terrainCellEntityId ~= INVALID_ID ) then

        local terrainTypeLayerComponent = EntityService:GetComponent( terrainCellEntityId, "TerrainTypeLayerComponent" )

        if ( terrainTypeLayerComponent ~= nil ) then

            local terrainTypeLayerComponentRef = reflection_helper(terrainTypeLayerComponent)

            --LogService:Log("terrainTypeLayerComponentRef " .. tostring(terrainTypeLayerComponentRef))

            if ( terrainTypeLayerComponentRef.terrain_type and terrainTypeLayerComponentRef.terrain_type.resource and terrainTypeLayerComponentRef.terrain_type.resource.name ) then

                terrainType = terrainTypeLayerComponentRef.terrain_type.resource.name
            end
        end

        local overrideTerrainComponent = EntityService:GetComponent( terrainCellEntityId, "OverrideTerrainComponent" )

        if ( overrideTerrainComponent ~= nil ) then

            local overrideTerrainComponentRef = reflection_helper(overrideTerrainComponent)

            --LogService:Log("overrideTerrainComponentRef " .. tostring(overrideTerrainComponentRef))

            if ( overrideTerrainComponentRef.terrain_overrides ) then

                for i=1,overrideTerrainComponentRef.terrain_overrides.count do

                    local terrainTypeHolder = overrideTerrainComponentRef.terrain_overrides[i]

                    if ( terrainTypeHolder and terrainTypeHolder.resource and terrainTypeHolder.resource.name ) then

                        if ( IndexOf( overrideTerrains, terrainTypeHolder.resource.name ) == nil ) then
                            Insert( overrideTerrains, terrainTypeHolder.resource.name )
                        end
                    end
                end
            end
        end
    end

    --LogService:Log("terrainCellEntityId " .. tostring(terrainCellEntityId) .. " terrainType " .. tostring(terrainType) .. " overrideTerrains " .. table.concat( overrideTerrains, "," ))

    return terrainType, overrideTerrains
end

function picker_tool:ChangeSelectorToEntityByFilter( filterFunc )

    for entity in Iter( self.selectedEntities ) do

        if ( filterFunc(entity, self.player) ) then

            local blueprintName = self:GetLinkedEntityBlueprint( entity ) or ""

            if ( blueprintName ~= "" and self:ChangeSelectorToBlueprint( blueprintName ) ) then
                return true
            end
        end
    end

    return false
end

function picker_tool:ChangeSelectorToTargetBlueprintByFilter( filterFunc, targetBlueprint, ignoreBuildCosts )

    ignoreBuildCosts = ignoreBuildCosts or false

    for entity in Iter( self.selectedEntities ) do

        if ( filterFunc(entity, self.player) ) then

            if ( self:ChangeSelectorToBlueprint( targetBlueprint, ignoreBuildCosts ) ) then
                return true
            end
        end
    end

    return false
end

function picker_tool:GetLinkedEntityBlueprint( entity )

    if( EntityService:GetGroup( entity ) == "##ruins##" ) then

        local database = EntityService:GetOrCreateDatabase( entity )

        if ( database and database:HasString("blueprint") ) then

            return database:GetString("blueprint") or ""
        end
    end

    if ( EntityService:HasComponent( entity, "ResourceComponent" ) ) then

        local resourceId = self:GetLinkedResource(entity)

        if ( resourceId ~= "" ) then

            local blueprintName = self:GetMineBlueprintName( resourceId, self.resourceBluprintsNames ) or ""

            return blueprintName
        end
    end

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        local resourceId = self:GetLinkedResource(entity)

        if ( resourceId ~= "" ) then

            local blueprintName = self:GetMineBlueprintName( resourceId, self.resourceVolumeBluprintsNames ) or ""

            return blueprintName
        end
    end

    return EntityService:GetBlueprintName(entity)
end

function picker_tool:ChangeSelectorToBlueprint( blueprintName, ignoreBuildCosts )

    ignoreBuildCosts = ignoreBuildCosts or false

    if ( blueprintName == "" ) then
        return false
    end

    blueprintName = self:CorrectBlueprintExceptions(blueprintName)

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    local baseDesc = BuildingService:FindBaseBuilding( blueprintName )
    if  (baseDesc ~= nil ) then
        buildingDesc = baseDesc
    end

    local buildingDescHelper = reflection_helper(buildingDesc)

    if ( not ignoreBuildCosts ) then

        if ( buildingDescHelper.build_cost == nil or buildingDescHelper.build_cost.resource == nil or buildingDescHelper.build_cost.resource.count == nil or buildingDescHelper.build_cost.resource.count <= 0 ) then
            return false
        end
    end

    blueprintName = buildingDescHelper.bp

    blueprintName = self:CorrectBlueprintExceptions(blueprintName)

    buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    local buildingDescHelper = reflection_helper(buildingDesc)

    QueueEvent( "ChangeSelectorRequest", self.selector, buildingDescHelper.bp, buildingDescHelper.ghost_bp )

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( lowName == blueprintName ) then
        lowName = buildingDescHelper.name
    end

    --LogService:Log("lowName " .. tostring(lowName) .. " buildingDescHelper.name " .. tostring(buildingDescHelper.name))

    BuildingService:SetBuildingLastLevel( self.playerId, lowName, buildingDescHelper.name )

    QueueEvent("ChangeBuildingRequest", self.selector, lowName )

    return true
end

function picker_tool:CorrectBlueprintExceptions( blueprintName )

    if ( blueprintName == "buildings/resources/pipe_straight_windowless" ) then

        return "buildings/resources/pipe_straight"
    end

    if ( blueprintName == "buildings/defense/wall_vine_straight_02" or blueprintName == "buildings/defense/wall_vine_straight_03" ) then

        return "buildings/defense/wall_vine_straight_01"
    end

    if ( blueprintName == "buildings/defense/wall_vine_straight_02_lvl_2" or blueprintName == "buildings/defense/wall_vine_straight_03_lvl_2" ) then

        return "buildings/defense/wall_vine_straight_01_lvl_2"
    end

    if ( blueprintName == "buildings/defense/wall_vine_straight_02_lvl_3" or blueprintName == "buildings/defense/wall_vine_straight_03_lvl_3" ) then

        return "buildings/defense/wall_vine_straight_01_lvl_3"
    end

    return blueprintName
end

function picker_tool:GetMineBlueprintName( resourceId, selectedBluprintsNames )

    if ( resourceId == "" ) then

        return ""
    end

    local maxDeltaLast = 1

    for lowName in Iter( selectedBluprintsNames ) do

        local defaultBlueprintName = self.selectedBluprintsHash[lowName]

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", defaultBlueprintName ) ) then
            goto labelContinue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( defaultBlueprintName )
        if ( buildingDesc == nil ) then
            goto labelContinue
        end

        local buildingDescRef = reflection_helper( buildingDesc )

        local resourceRequirement = buildingDescRef.resource_requirement
        if ( resourceRequirement == nil or resourceRequirement.count <= 0 ) then
            goto labelContinue
        end

        local isResourceRequired = self:IsResourceRequired( resourceRequirement, resourceId )
        if ( not isResourceRequired ) then
            goto labelContinue
        end

        if ( resourceId == "mud_vein" or resourceId == "carbon_vein" ) then

            local currentTime = GetLogicTime()

            local lastLowName, lastTime = self:GetLastVeinExtractor(resourceId)
            
            local delta = currentTime - lastTime

            if ( lastLowName == lowName and delta < maxDeltaLast ) then

                goto labelContinue
            end

            self:SetLastVeinExtractor(resourceId, lowName, currentTime)
        end

        do
            return self:GetSelectorBlueprintName( lowName, defaultBlueprintName )
        end

        ::labelContinue::
    end

    --if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) and EntityService:CompareType( entity, "water" ) ) then
    --
    --    local lowName = "liquid_pump"
    --    local defaultBlueprintName = self.selectedBluprintsHash[lowName]
    --
    --    return self:GetSelectorBlueprintName( lowName, defaultBlueprintName )
    --end

    return ""
end

function picker_tool:GetLinkedResource( entity )

    local resourceComponent = EntityService:GetComponent( entity, "ResourceComponent" )
    if ( resourceComponent ~= nil ) then

        local resourceComponentRef = reflection_helper( resourceComponent )

        if ( resourceComponentRef.type ~= nil and resourceComponentRef.type.resource ~= nil and resourceComponentRef.type.resource.id ~= nil ) then

            local resourceId = resourceComponentRef.type.resource.id or ""

            if ( resourceId ~= "" ) then
                return resourceId
            end
        end
    end

    local resourceVolumeComponent = EntityService:GetComponent( entity, "ResourceVolumeComponent" )
    if ( resourceVolumeComponent ~= nil ) then

        local resourceVolumeComponentRef = reflection_helper( resourceVolumeComponent )

        if ( resourceVolumeComponentRef.type ~= nil and resourceVolumeComponentRef.type.resource ~= nil and resourceVolumeComponentRef.type.resource.id ~= nil ) then

            local resourceId = resourceVolumeComponentRef.type.resource.id or ""

            if ( resourceId ~= "" ) then
                return resourceId
            end
        end
    end

    return ""
end

function picker_tool:IsResourceRequired( resourceRequirement, resourceId )

    for i = 1,resourceRequirement.count do

        local resource = resourceRequirement[i]

        if ( resource ~= nil and resource ~= "" ) then

            if ( resource == resourceId ) then

                return true
            end
        end
    end

    return false
end

function picker_tool:GetSelectorBlueprintName( lowName, defaultBlueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", defaultBlueprintName ) ) then
        return ""
    end

    return self:GetMaxAvailableLevel( defaultBlueprintName )
end

function picker_tool:GetMaxAvailableLevel( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return ""
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingRef = reflection_helper( buildingDesc )
    if ( buildingRef == nil ) then
        return ""
    end

    if ( buildingRef.upgrade ~= nil and buildingRef.upgrade ~= "" ) then

        if ( self:IsBlueprintAvailable( buildingRef.upgrade ) ) then

            return self:GetMaxAvailableLevel( buildingRef.upgrade )
        end
    end

    return blueprintName
end

function picker_tool:IsBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return true
    end

    local researchName = self:GetResearchForUpgrade( blueprintName ) or ""
    if ( researchName ~= "" ) then

        if ( PlayerService:IsResearchUnlocked( PlayerService:GetLeadingPlayer(), researchName ) ) then
            return true
        end
    end

    return false
end

function picker_tool:GetResearchForUpgrade( blueprintName )

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    local categories = researchComponent.research

    for i=1,categories.count do

        local category = categories[i]
        local category_nodes = category.nodes

        for j=1,category_nodes.count do

            local node = category_nodes[j]

            local awards = node.research_awards
            for k=1,awards.count do

                if awards[k].blueprint == blueprintName then

                    return node.research_name
                end
            end
        end
    end

    return ""
end

function picker_tool:HighlightRuins()

    local ruinsList = self:FindBuildingRuins()

    self.previousMarkedRuins = self.previousMarkedRuins or {}

    -- Remove highlighting from previous ruins
    for ruinEntity in Iter( self.previousMarkedRuins ) do

        -- If the ruin is not included in the new list
        if ( IndexOf( ruinsList, ruinEntity ) ~= nil ) then
            goto labelContinue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto labelContinue
        end

        self:RemoveEntitySelectedMaterial( ruinEntity )

        ::labelContinue::
    end

    for ruinEntity in Iter( ruinsList ) do

        self:SetEntitySelectedMaterial( ruinEntity, "hologram/grey" )
    end

    self.previousMarkedRuins = ruinsList
end

function picker_tool:FindBuildingRuins()

    local ruinsList = FindService:FindEntitiesByGroupInRadius( self.player, "##ruins##", self.radiusShowRuins )

    local result = {}

    for ruinEntity in Iter( ruinsList ) do

        if ( IndexOf( result, ruinEntity ) ~= nil ) then
            goto labelContinue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto labelContinue
        end

        local database = EntityService:GetOrCreateDatabase( ruinEntity )
        if ( database == nil ) then
            goto labelContinue
        end

        if ( not database:HasString("blueprint") ) then
            goto labelContinue
        end

        local ruinsBlueprint = database:GetString("blueprint")
        if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
            goto labelContinue
        end

        Insert( result, ruinEntity )

        ::labelContinue::
    end

    return result
end

function picker_tool:OnRelease()

    if ( self.selectedResourceComponents ~= nil) then

        for childResource in Iter( self.selectedResourceComponents ) do
            QueueEvent( "DeselectEntityRequest", childResource )
        end
    end
    self.selectedResourceComponents = {}

    -- Remove highlighting from ruins
    if ( self.previousMarkedRuins ~= nil) then

        for ruinEntity in Iter( self.previousMarkedRuins ) do

            self:RemoveEntitySelectedMaterial( ruinEntity )
        end
    end
    self.previousMarkedRuins = {}

    EntityService:RemoveEntity(self.menuEntity)

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

function picker_tool:GetLastVeinExtractor(resourceId)

    local parameterName = "$picker_tool_last_" .. resourceId .. "_extractor_blueprint"
    local parameterTimeName = "$picker_tool_last_" .. resourceId .. "_extractor_blueprint_time"

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    local lowName = ""
    local timeValue = 0

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        lowName = selectorDB:GetStringOrDefault(parameterName, "") or ""
        timeValue = selectorDB:GetFloatOrDefault(parameterTimeName, 0)
    end

    if ( lowName == "" ) then

        if ( CampaignService.GetCampaignData ) then
        
            local campaignDatabase = CampaignService:GetCampaignData()
            if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
                lowName = campaignDatabase:GetStringOrDefault(parameterName, "") or ""
                timeValue = campaignDatabase:GetFloatOrDefault(parameterTimeName, 0)
            end
        end
    end

    timeValue = timeValue or 0

    return lowName, timeValue
end

function picker_tool:SetLastVeinExtractor(resourceId, lowName, timeValue)

    local parameterName = "$picker_tool_last_" .. resourceId .. "_extractor_blueprint"
    local parameterTimeName = "$picker_tool_last_" .. resourceId .. "_extractor_blueprint_time"

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    if ( selectorDB ) then

        selectorDB:SetString(parameterName, lowName)
        selectorDB:SetFloat(parameterTimeName, timeValue)
    end

    if ( CampaignService.GetCampaignData ) then
    
        local campaignDatabase = CampaignService:GetCampaignData()
        if ( campaignDatabase ) then
            campaignDatabase:SetString( parameterName, lowName )
            campaignDatabase:SetFloat( parameterTimeName, timeValue )
        end
    end
end

function picker_tool:FillLastBuildingsList(defaultModesArray, modeBuildingLastSelected, selector)

    self.lastSelectedBuildingsArray = LastSelectedBlueprintsListUtils:GetCurrentList(self.list_name, selector)

    if ( self.selectedBuildingBlueprint ~= "" and self.selectedBuildingBlueprint ~= nil and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        LastSelectedBlueprintsListUtils:RemoveBuildingAndUpgradesFromList(self.lastSelectedBuildingsArray, self.selectedBuildingBlueprint)
    end

    local modeValuesArray = Copy(defaultModesArray)

    for index=0,#self.lastSelectedBuildingsArray-1 do

        Insert(modeValuesArray, (modeBuildingLastSelected + index))
    end

    return modeValuesArray
end

function picker_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local selectedMode = self:CheckModeValueExists(self.selectedMode)

    local index = IndexOf( self.modeValuesArray, selectedMode )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #self.modeValuesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = self.modeValuesArray[newIndex]

    self.selectedMode = newValue

    self:SetBuildingIcon()
end

function picker_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function picker_tool:GetMenuIcon( blueprintName )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return ""
    end

    local menuIcon = self:GetBuildingMenuIcon( blueprintName, buildingDescRef )

    return menuIcon,buildingDescRef
end

function picker_tool:GetBuildingMenuIcon( blueprintName, buildingDescRef )

    self.cacheBlueprintsMenuIcons = self.cacheBlueprintsMenuIcons or {}

    if ( self.cacheBlueprintsMenuIcons[blueprintName] == nil ) then

        self.cacheBlueprintsMenuIcons[blueprintName] = self:CalculateBuildingMenuIcon( blueprintName, buildingDescRef )
    end

    return self.cacheBlueprintsMenuIcons[blueprintName]
end

function picker_tool:CalculateBuildingMenuIcon( blueprintName, buildingDescRef )

    local menuIcon = ""

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if ( baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper( baseBuildingDesc )

        menuIcon = baseBuildingDescRef.menu_icon or ""

        if ( menuIcon ~= "" ) then
            return menuIcon
        end
    end


    menuIcon = buildingDescRef.menu_icon or ""

    if ( menuIcon ~= "" ) then
        return menuIcon
    end

    if ( buildingDescRef.connect.count > 0 ) then

        for i=1,buildingDescRef.connect.count do

            local connectRecord = buildingDescRef.connect[i]

            for j=1,connectRecord.value.count do

                local connectBlueprintName = connectRecord.value[j]

                if ( not ResourceManager:ResourceExists( "EntityBlueprint", connectBlueprintName ) ) then
                    goto labelContinue
                end

                local connectBuildingDesc = BuildingService:GetBuildingDesc( connectBlueprintName )
                if ( connectBuildingDesc == nil ) then
                    goto labelContinue
                end

                local connectBuildingDescRef = reflection_helper( connectBuildingDesc )
                if ( connectBuildingDescRef == nil ) then
                    goto labelContinue
                end

                local menuIcon = connectBuildingDescRef.menu_icon or ""

                if ( menuIcon ~= "" ) then
                    return menuIcon
                end
            end

            ::labelContinue::
        end
    end

    return ""
end

function picker_tool:GetLastBlueprint(suffix, currentTime)

    local parameterName = "$picker_tool_last_" .. suffix .. "_blueprint"
    local parameterTimeName = "$picker_tool_last_" .. suffix .. "_blueprint_time"
    local parameterEntityName = "$picker_tool_last_" .. suffix .. "_blueprint_entity"

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    local lastValue = ""
    local lastTimeValue = 0
    local lastEntityId = INVALID_ID

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        lastValue = selectorDB:GetStringOrDefault(parameterName, "") or ""
        lastTimeValue = selectorDB:GetFloatOrDefault(parameterTimeName, 0)
        lastEntityId = selectorDB:GetIntOrDefault(parameterEntityName, INVALID_ID)
    end

    if ( lastValue == "" ) then

        if ( CampaignService.GetCampaignData ) then
        
            local campaignDatabase = CampaignService:GetCampaignData()
            if ( campaignDatabase and campaignDatabase:HasString(parameterName) ) then
                lastValue = campaignDatabase:GetStringOrDefault(parameterName, "") or ""
                lastTimeValue = campaignDatabase:GetFloatOrDefault(parameterTimeName, 0)
                lastEntityId = campaignDatabase:GetIntOrDefault(parameterEntityName, INVALID_ID)
            end
        end
    end

    lastTimeValue = lastTimeValue or 0

    local maxDeltaLast = 1

    local delta = currentTime - lastTimeValue

    --LogService:Log("currentTime " .. tostring(currentTime) .. "      currentTime+maxDeltaLast " .. tostring(currentTime+maxDeltaLast).. "      delta " .. tostring(delta))

    if ( delta >= maxDeltaLast ) then

        lastValue = ""
        lastEntityId = INVALID_ID
    end

    return lastValue, lastEntityId
end

function picker_tool:SetLastBlueprint(suffix, timeValue, blueprintName, entityId)

    timeValue = timeValue or 0
    entityId = entityId or INVALID_ID

    local parameterName = "$picker_tool_last_" .. suffix .. "_blueprint"
    local parameterTimeName = "$picker_tool_last_" .. suffix .. "_blueprint_time"
    local parameterEntityName = "$picker_tool_last_" .. suffix .. "_blueprint_entity"

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    if ( selectorDB ) then

        selectorDB:SetString(parameterName, blueprintName)
        selectorDB:SetFloat(parameterTimeName, timeValue)
        selectorDB:SetInt(parameterEntityName, entityId)
    end

    if ( CampaignService.GetCampaignData ) then
    
        local campaignDatabase = CampaignService:GetCampaignData()
        if ( campaignDatabase ) then
            campaignDatabase:SetString( parameterName, blueprintName )
            campaignDatabase:SetFloat( parameterTimeName, timeValue )
            campaignDatabase:SetInt( parameterEntityName, entityId )
        end
    end
end

return picker_tool