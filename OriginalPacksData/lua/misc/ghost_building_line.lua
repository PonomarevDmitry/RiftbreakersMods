local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")

class 'ghost_building_line' ( ghost )

function ghost_building_line:__init()
    ghost.__init(self,self)
end

function ghost_building_line:OnInit()
    self.linesEntities = {}
    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
end

function ghost_building_line:OnUpdate()
    self.buildCost = {}

    if ( self.buildStartPosition ) then
        local currentTransform = EntityService:GetWorldTransform( self.entity )
        
        local newPositions = BuildingService:FindPathByBlueprint(self.buildStartPosition, currentTransform, self.blueprint )

        if ( #self.linesEntities > #newPositions ) then
            for i=#self.linesEntities,#newPositions + 1,-1 do 
                EntityService:RemoveEntity(self.linesEntities[i])
                self.linesEntities[i] = nil
            end
        elseif ( #self.linesEntities < #newPositions ) then
            for i=#self.linesEntities + 1 ,#newPositions do
                local lineEnt = EntityService:SpawnEntity(self.ghostBlueprint, newPositions[i], EntityService:GetTeam(self.entity) );
                EntityService:RemoveComponent(lineEnt, "LuaComponent")
                Insert(self.linesEntities, lineEnt)
            end
        end
        Assert(#self.linesEntities == #newPositions, "ERROR: something wrong with line positioning: " .. tostring(#self.linesEntities) .. "/" .. tostring(#newPositions))
        for i=1,#newPositions do
            local transform = {}
            transform.scale = {x=1,y=1,z=1}
            transform.orientation = currentTransform.orientation
            transform.position = newPositions[i]
            
            local entity = self.linesEntities[i];
            self:CheckEntityBuildable(entity, transform, false, i, false)
            EntityService:SetPosition( entity, newPositions[i])
            EntityService:SetOrientation(entity, transform.orientation )
            BuildingService:CheckAndFixBuildingConnection(entity)
        end

        local list = BuildingService:GetBuildCosts( self.blueprint, self.playerId )
        for resourceCost in Iter(list) do
            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first ] = resourceCost.second * #newPositions 
            else
               self.buildCost[resourceCost.first ] = self.buildCost[resourceCost.first ] + ( resourceCost.second * #newPositions ) 
            end
        end
    else
        local transform = EntityService:GetWorldTransform( self.entity )
        local testBuildable = self:CheckEntityBuildable( self.entity , transform, false )
       -- BuildingService:CheckAndFixBuildingConnection(self.entity)

    end
    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    end
    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost)
    else
        BuildingService:OperateBuildCosts( self.infoChild , self.playerId,{})
    end
end

function ghost_building_line:FinishLineBuild()
    EntityService:SetVisible( self.entity , true )
    local count = #self.linesEntities -- 6
    local step = count
    if ( count > 5 )  then
        local additionalCubesCount = math.ceil( count / 5 ) 
        step = math.ceil( count / additionalCubesCount) 
    end

    local database = EntityService:GetBlueprintDatabase( self.blueprint)
    local randomRotation = database:GetIntOrDefault("random_rotation", 0 )

    for i=1,count do
        local ghost = self.linesEntities[i]
        local createCube = i == 1 or i == count or i % step == 0
        --LogService:Log(tostring(i) .. ":" .. tostring(step) .. ":" .. tostring(createCube))
        local transform = EntityService:GetWorldTransform( ghost )
        if ( randomRotation == 1 ) then
            local angle = {0, 90, 180, 270}
            local randomAngle = angle[RandInt(1,4)]
            transform.orientation = CreateQuaternion( {x=0,y=1,z=0}, randomAngle )
        end
        local buildingComponent = reflection_helper(EntityService:GetComponent( ghost, "BuildingComponent"))
       
        local testBuildable = self:CheckEntityBuildable( ghost , transform, false, i )
        if ( testBuildable.flag == CBF_CAN_BUILD ) then
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube, {} )
        elseif( testBuildable.flag == CBF_OVERRIDES ) then
            for entityToSell in Iter(testBuildable.entities_to_sell) do
                QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
            end
            self:BuildBuilding(transform)
            
        elseif( testBuildable.flag == CBF_REPAIR  ) then
            QueueEvent("ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId)
        end
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}
    self.buildStartPosition = nil
end

function ghost_building_line:OnActivate()
    if ( self.buildStartPosition == nil ) then
        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.entity , false )
    else
        self:FinishLineBuild() 
    end

end

function ghost_building_line:OnDeactivate()
    self:FinishLineBuild()
end

function ghost_building_line:OnRelease()
    for ghost in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}

    EntityService:RemoveEntity(self.infoChild)
end

return ghost_building_line
 