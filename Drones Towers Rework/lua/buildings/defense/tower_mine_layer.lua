require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'tower_mine_layer' ( drone_spawner_building )

function tower_mine_layer:__init()
    drone_spawner_building.__init(self,self)
end

function tower_mine_layer:OnInit()

    if ( drone_spawner_building.OnInit ) then
        drone_spawner_building.OnInit(self)
    end

    self.lifting_drones = 0

    LogService:Log("OnInit self.entity " .. tostring(self.entity))

    self:CreateDronePoint("OnInit")
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "onDronePointChange" )
    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )
    self:RegisterHandler( self.entity, "OperateActionMenuEvent", "OnOperateActionMenuEvent")
end

function tower_mine_layer:OnLoad()

    if ( drone_spawner_building.OnLoad ) then
        drone_spawner_building.OnLoad(self)
    end

    LogService:Log("OnLoad self.entity " .. tostring(self.entity))

    self:CreateDronePoint("OnLoad")
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "onDronePointChange" )
    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )
    self:RegisterHandler( self.entity, "OperateActionMenuEvent", "OnOperateActionMenuEvent")
end

function tower_mine_layer:CreateDronePoint(text)

    if ( self.pointEntity == nil ) then

        local pointX = self.data:GetFloatOrDefault("drone_point_entity_x", 0)
        local pointZ = self.data:GetFloatOrDefault("drone_point_entity_z", 0)
    
        LogService:Log(text .. " CreateDronePoint pointX " .. tostring(pointX) .. " pointZ " .. tostring(pointZ))

        self.pointEntity = EntityService:SpawnAndAttachEntity( "buildings/defense/tower_drone_point", self.entity )
        EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )
    
        LogService:Log(text .. " CreateDronePoint drone_point_entity " .. tostring(self.pointEntity))
    end

    EntityService:SetName( self.pointEntity, "drone_point_entity" )

    self.data:SetInt("drone_point_entity", self.pointEntity)
end

function tower_mine_layer:onDronePointChange(evt)

    local eventName = evt:GetEvent()
    local eventDatabase = evt:GetDatabase()
    local eventEntity = evt:GetEntity()

    if ( eventEntity ~= self.entity ) then
        return
    end

    if ( eventName ~= "DronePointChangeEvent" ) then
        return
    end

    local transform = EntityService:GetWorldTransform( self.entity )

    local pointX = eventDatabase:GetFloat("point_x") - transform.position.x
    local pointZ = eventDatabase:GetFloat("point_z") - transform.position.z

    self.data:SetFloat("drone_point_entity_x", pointX)
    self.data:SetFloat("drone_point_entity_z", pointZ)
    
    LogService:Log("onDronePointChange pointX " .. tostring(pointX) .. " pointZ " .. tostring(pointZ))

    local transform = EntityService:GetWorldTransform( self.entity )

    self:CreateDronePoint("onDronePointChange")

    EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        self:SpawnDrones()
    end
end

function tower_mine_layer:UpdateDisplayRadiusVisibility( show, entity )

    self.display_radius_requesters = self.display_radius_requesters or {}

    self:CreateDronePoint("UpdateDisplayRadiusVisibility")

    if show then
        if self.display_radius_requesters[ entity ] then
            return
        end

        self.display_radius_requesters[ entity ] = true

        local count = 0
        for entityTemp,_ in pairs(self.display_radius_requesters) do
            count = count + 1
        end

        if count == 1 then
            EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" );

            local component = reflection_helper( EntityService:CreateComponent(self.pointEntity,"DisplayRadiusComponent") )
            component.min_radius = self.display_radius_size.min;
            component.max_radius = self.display_radius_size.max;
            component.max_radius_blueprint = self.display_effect_blueprint;
        end
    else
        self.display_radius_requesters[ entity ] = nil

        local count = 0
        for entityTemp,_ in pairs(self.display_radius_requesters) do
            count = count + 1
        end
        
        if count == 0 then
            EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" )
        end
    end
end

function tower_mine_layer:OnDroneLiftingStarted()
    self.lifting_drones = self.lifting_drones + 1
    self.data:SetInt("lifting_drones", self.lifting_drones)
end

function tower_mine_layer:OnDroneLiftingEnded()
    self.lifting_drones = self.lifting_drones - 1
    self.data:SetInt("lifting_drones", self.lifting_drones)
end

function tower_mine_layer:SpawnDrones()

    self:CleanupDrones()

    self.lifting_drones = 0
    self.data:SetInt("lifting_drones", self.lifting_drones)

    local DRONE_FADE_TIME = 0.3

    local isActive = self.data:GetIntOrDefault( "activated", 0 ) == 1;

    local blueprints = Split( self.drone_blueprint, ",") 

    local droneIdx = 0

    local towerMinesArray = self:GetMinesArray()

    for attachment in Iter( self.drone_landing_spots ) do

        for towerMineBlueprint in Iter( towerMinesArray ) do

            for i=1,self.drone_per_attachment do

                local drone_blueprint = blueprints[ (droneIdx % #blueprints) + 1 ]

                local drone = EntityService:SpawnEntity( drone_blueprint, attachment, EntityService:GetTeam(self.entity) )

                EntityService:SetScale( drone, 0.75,0.75,0.75 )

                UnitService:SetCurrentTarget( drone, "owner", attachment )

                if self.drones_visible then
                    QueueEvent( "FadeEntityInRequest", drone, DRONE_FADE_TIME )
                else
                    QueueEvent( "FadeEntityOutRequest", drone, 1 )
                end
            
                self:RegisterHandler( drone, "DroneLandingStartedEvent", "_OnDroneLandingStartedEvent" )
                self:RegisterHandler( drone, "DroneLandingEndedEvent", "_OnDroneLandingEndedEvent" )
                self:RegisterHandler( drone, "DroneLiftingStartedEvent", "_OnDroneLiftingStartedEvent" )
                self:RegisterHandler( drone, "DroneLiftingEndedEvent", "_OnDroneLiftingEndedEvent" )
                self:DroneSpawned( drone )

                local database = EntityService:GetDatabase( drone )
                database:SetInt("drone_id", droneIdx )
                database:SetFloat("drone_search_radius", self.drone_search_radius )
                database:SetString("plant_blueprint", towerMineBlueprint )

                droneIdx = droneIdx + 1

                Insert( self.drones, drone )

                self:UpdateActiveDrones( drone, isActive )
            end
        end
    end
end

function tower_mine_layer:GetMinesArray()

    local DEFAULT_MINE_BLUEPRINT = "units/drones/drone_mine_root";

    local result = {}

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")

    if ( equipmentComponent ) then

        local equipment = reflection_helper( equipmentComponent ).equipment[1]

        local slots = equipment.slots
        for i=1,slots.count do

            local slot = slots[i]

            local mineBlueprint = DEFAULT_MINE_BLUEPRINT

            for i=1,slot.subslots.count do

                local entities = slot.subslots[i]

                local entity = entities[1]
                if entity and entity.id then

                    local blueprintDatabase = EntityService:GetBlueprintDatabase( entity.id )

                    if ( blueprintDatabase and blueprintDatabase:HasString("mine_blueprint") ) then

                        mineBlueprint = blueprintDatabase:GetString("mine_blueprint")
                    end
                end
            end

            Insert(result, mineBlueprint)
        end
    else
        Insert(result, DEFAULT_MINE_BLUEPRINT)
    end

    return result
end

function tower_mine_layer:OnItemEquippedEvent( evt )

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        self:SpawnDrones()
    end
end

function tower_mine_layer:OnItemUnequippedEvent( evt )

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        self:SpawnDrones()
    end
end

function tower_mine_layer:OnOperateActionMenuEvent()

    local blueprintArray = {
        "items/tower_mines/drone_mine_root",
        "items/tower_mines/drone_mine_root_acid",
        "items/tower_mines/drone_mine_root_cryogenic",
        "items/tower_mines/drone_mine_root_incendiary"
    }

    for blueprintName in Iter( blueprintArray ) do

        local item = ItemService:GetFirstItemForBlueprint( self.entity, blueprintName )

        if item == INVALID_ID then
            ItemService:AddItemToInventory( self.entity, blueprintName )
        end
    end

    local owner = self.data:GetIntOrDefault( "owner", 0 )

    local player = PlayerService:GetPlayerControlledEnt( owner )

    for blueprintName in Iter( blueprintArray ) do

        local item = ItemService:GetFirstItemForBlueprint( player, blueprintName )

        if item == INVALID_ID then
            ItemService:AddItemToInventory( player, blueprintName )
        end
    end
end

return tower_mine_layer
