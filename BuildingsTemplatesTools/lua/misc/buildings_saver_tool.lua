local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'buildings_saver_tool' ( ghost )

function buildings_saver_tool:__init()
    ghost.__init(self,self)
end

function buildings_saver_tool:OnInit()

    local boundsSize = EntityService:GetBoundsSize( self.selector)
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue")

    local transform = EntityService:GetWorldTransform( self.entity )
    EntityService:SetVisible( self.entity , true )
    self:CheckEntityBuildable( self.entity , transform )

    self:RegisterHandler( INVALID_ID, "BuildingStartEvent", "OnBuildingStartEvent" )

    self.template_name = self.data:GetString("template_name")

    self.templateEntities = {}

    local team = EntityService:GetTeam(self.entity)
    local currentTransform = EntityService:GetWorldTransform( self.entity )

    self:SpawnBuildinsTemplates( team, currentTransform.position )

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
end

function buildings_saver_tool:OnBuildingStartEvent( evt )
    if ( evt:GetPlayerId() ~= self.playerId or not self.activated) then
        return
    end

    local transform = EntityService:GetWorldTransform( evt:GetEntity() )
    self:SetLastBuildSpot(transform)
end

function buildings_saver_tool:SpawnBuildinsTemplates( team, currentPosition )

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return
    end

    local templateString = campaignDatabase:GetStringOrDefault( self.template_name, "" )

    LogService:Log("SpawnBuildinsTemplates template_name " .. self.template_name .. " templateString " .. templateString )

    if ( templateString == nil or templateString == "" ) then
        return
    end

    local templatesArray = Split( templateString, "|" )

    for template in Iter( templatesArray ) do
        
        self:SpawnTemplate( template, currentPosition, team )
    end

    local firstBuildingTemplate = self.templateEntities[1]
    local firstEntity = firstBuildingTemplate.entity

    local gridSize = BuildingService:GetBuildingGridSize( firstEntity )

    EntityService:SetScale( self.entity, gridSize.x, 1, gridSize.z)
end

function buildings_saver_tool:SpawnTemplate( template, currentPosition, team )

    LogService:Log("SpawnTemplate template " .. template )

    local valuesArray = Split( template, "," )

    local buildingTemplate = {}

    local blueprint = valuesArray[1]

    buildingTemplate.blueprint = blueprint

    buildingTemplate.positionX = tonumber( valuesArray[2] )
    buildingTemplate.positionZ = tonumber( valuesArray[3] )

    buildingTemplate.orientationX = tonumber( valuesArray[4] )
    buildingTemplate.orientationY = tonumber( valuesArray[5] )
    buildingTemplate.orientationZ = tonumber( valuesArray[6] )
    buildingTemplate.orientationW = tonumber( valuesArray[7] )

    LogService:Log("SpawnTemplate blueprint " .. blueprint )

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( blueprint ) )

    LogService:Log("SpawnTemplate buildingDesc " .. tostring(buildingDesc) )

    buildingTemplate.buildingDesc = buildingDesc

    local newPosition = {}
                
    newPosition.x = currentPosition.x + buildingTemplate.positionX
    newPosition.y = currentPosition.y
    newPosition.z = currentPosition.z + buildingTemplate.positionZ

    local orientation = {}
                
    orientation.x = buildingTemplate.orientationX
    orientation.y = buildingTemplate.orientationY
    orientation.z = buildingTemplate.orientationZ
    orientation.w = buildingTemplate.orientationW

    buildingTemplate.orientation = orientation

    local buildingEntity = nil

    if ( buildingDesc.ghost_bp ~= "" and buildingDesc.ghost_bp ~= nil ) then

        buildingEntity = EntityService:SpawnEntity( buildingDesc.ghost_bp, newPosition, team )
    else
        buildingEntity = EntityService:SpawnEntity( buildingDesc.bp, newPosition, team )
    end

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )
    EntityService:SetOrientation( buildingEntity, orientation )

    EntityService:ChangeMaterial( buildingEntity, "selector/hologram_blue" )

    buildingTemplate.entity = buildingEntity

    Insert( self.templateEntities, buildingTemplate )
end

function buildings_saver_tool:SetLastBuildSpot(transform)
    local selectorComponent = EntityService:GetComponent( self.selector, "BuildingSelectorComponent")
    local container = selectorComponent:GetField("last_build_pos"):ToContainer()
    local item = container:GetItem(0)
    if ( item == nil ) then item = container:CreateItem() end

    local itemHelper = reflection_helper(item)
    itemHelper.x = transform.position.x
    itemHelper.y = transform.position.y
    itemHelper.z = transform.position.z
end

function buildings_saver_tool:OnUpdate()

    self.buildCost = {}

    local currentTransform = EntityService:GetWorldTransform( self.entity )
    local currentPosition = currentTransform.position

    self:CheckEntityBuildable( self.entity , currentTransform, false )

    for i=1,#self.templateEntities do

        local buildingTemplate = self.templateEntities[i]

        local newPosition = {}
                
        newPosition.x = currentPosition.x + buildingTemplate.positionX
        newPosition.y = currentPosition.y
        newPosition.z = currentPosition.z + buildingTemplate.positionZ

        local transform = {}

        transform.scale = { x=1, y=1, z=1 }
        transform.orientation = buildingTemplate.orientation
        transform.position = newPosition
            
        local entity = buildingTemplate.entity

        local testBuildable = self:CheckEntityBuildable(entity, transform, false, i, false)

        EntityService:SetPosition( entity, newPosition )
        EntityService:SetOrientation(entity, transform.orientation )
        BuildingService:CheckAndFixBuildingConnection(entity)

        local list = BuildingService:GetBuildCosts( buildingTemplate.blueprint, self.playerId )

        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + resourceCost.second
        end
    end

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end

    if ( self.activated  ) then

        self:FinishLineBuild()
    end
end

function buildings_saver_tool:FinishLineBuild()
    
    local count = #self.templateEntities
    
    if ( count > 0 ) then

        for i=1,count do

            local buildingTemplate = self.templateEntities[i]
            
            self:BuildEntity(buildingTemplate)
        end
    end
end

function buildings_saver_tool:BuildEntity(buildingTemplate)

    local entity = buildingTemplate.entity

    local transform = EntityService:GetWorldTransform( entity )
       
    local testBuildable = self:CheckEntityBuildable( entity , transform, false )

    if ( testBuildable == nil ) then

        return
    end

    if ( testBuildable.flag == CBF_TO_CLOSE ) then

        if ( self.toCloseAnnoucement ~= "" ) then
            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, self.toCloseAnnoucement, entity, false)
        end

        return testBuildable.flag

    elseif( testBuildable.flag == CBF_LIMITS ) then

        QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/building_limit", entity, false )

        return testBuildable.flag
    end

    local missingResources = testBuildable.missing_resources
    if ( missingResources.count  > 0 ) then
        if ( missingResources.count  > 1 ) then
            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/not_enough_resources", entity, false )
        elseif ( self.annoucements[missingResources[1]] ~= nil and self.annoucements[missingResources[1]] ~= "" ) then
            QueueEvent("PlayTimeoutSoundRequest",INVALID_ID, 5.0, self.annoucements[missingResources[1]],entity , false )
        end

        return testBuildable.flag
    end

    local buildingComponent = reflection_helper( EntityService:GetComponent( entity, "BuildingComponent" ) )

    if ( testBuildable.flag == CBF_CAN_BUILD ) then
        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, true )
    elseif( testBuildable.flag == CBF_OVERRIDES ) then
        for entityToSell in Iter(testBuildable.entities_to_sell) do
            QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
        end
        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, true )
    elseif( testBuildable.flag == CBF_REPAIR  ) then
        QueueEvent("ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId)
    end

    return testBuildable.flag
end

function buildings_saver_tool:ClearLastBuildPos()
    local selectorComponent = EntityService:GetComponent( self.selector, "BuildingSelectorComponent")
    local container = selectorComponent:GetField("last_build_pos"):ToContainer()
    local item = container:GetItem(0)
    if ( item ~= nil ) then
         container:EraseItem(0)
    end
end

function buildings_saver_tool:OnDeactivate()
    self:ClearLastBuildPos()
end

function buildings_saver_tool:OnRelease()
    self:ClearLastBuildPos()

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
    end

    for buildingTemplate in Iter(self.templateEntities) do

        EntityService:RemoveEntity(buildingTemplate.entity)
        buildingTemplate.entity = nil
    end

    self.templateEntities = {}
end

return buildings_saver_tool
 