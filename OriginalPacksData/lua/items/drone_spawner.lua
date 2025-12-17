require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local item = require("lua/items/item.lua")
class 'drone_spawner' ( item )

local RARITY_BLUEPRINT_SUFFIX = 
{
    [WR_STANDARD] = "_standard",
    [WR_ADVANCED] = "_advanced",
    [WR_SUPERIOR] = "_superior",
    [WR_EXTREME] = "_extreme",
}

local DRONE_TYPE = { "repair_drone", "attack_drone", "defense_drone", "loot_drone" }

function drone_spawner:__init()
	item.__init(self,self)
end

local function GetDronesCountStat( stats, stat )
    for i=1,stats.count do
        local item = stats[i];
        if item.key == stat then
            return item.value.mod_value;
        end
    end

    return 0
end

local function GetDroneBlueprint( drone_type, rarity )
    local blueprint_suffix = ( RARITY_BLUEPRINT_SUFFIX[ rarity ] or "_extreme" );
    local stat_drone_blueprints = 
    {
        [EntityModType.repair_drone]     = "units/drones/drone_player_repair" .. blueprint_suffix,             -- stat RepairDrone
        [EntityModType.attack_drone]     = "units/drones/drone_player_offensive".. blueprint_suffix,           -- stat AttackDrone
        [EntityModType.defense_drone]    = "units/drones/drone_player_defensive".. blueprint_suffix,           -- stat DefensiveDrone
        [EntityModType.loot_drone]       = "units/drones/drone_player_loot_collector".. blueprint_suffix,      -- stat LootDrone
    };

    local drone_blueprint = stat_drone_blueprints[ EntityModType[drone_type] ]
    Assert( drone_blueprint ~= nil, "ERROR: failed to match drone blueprint for drone type: '" .. drone_type .. "'");
    return drone_blueprint or "error"
end

function drone_spawner:SpawnDroneBlueprint( blueprint, count )
    local team = EntityService:GetTeam(self.owner)

    local droneLifeTime = nil
    if self.data:HasFloat("drone_lifetime") then
        local timeElapsed = GetLogicTime() - self.trigger_time
        droneLifeTime = self.data:GetFloat("drone_lifetime") - timeElapsed

        if droneLifeTime <= 0 then
            return
        end
    end

    for i=1,count do
        local position = EntityService:GetPosition(self.owner)
        position.x = position.x + RandFloat( 1.0, 5.0 )
        position.y = position.y + RandFloat( 7.0, 8.0 )
        position.z = position.z + RandFloat( 1.0, 5.0 )

        local drone = EntityService:SpawnEntity( blueprint, position, team);
        EntityService:Rotate( drone, 0.0, 1.0, 0.0, RandFloat(0.0, 360.0))
        UnitService:SetCurrentTarget( drone, "owner", self.owner );

        QueueEvent( "EnableDroneRequest", drone)
        EntityService:FadeEntity( drone, DD_FADE_IN, 2.0 )

	    EffectService:AttachEffects(drone, "fly")
        ItemService:SetItemReference( drone, self.entity, EntityService:GetBlueprintName( self.entity ))
        EntityService:PropagateEntityOwner( drone, self.entity )
        if droneLifeTime then
            EntityService:CreateOrSetLifetime(drone, droneLifeTime, "normal")
        end

        Insert(self.spawned_drones,drone)
    end
end

function drone_spawner:init()
	item.init(self)

    self.owner = EntityService:GetParent(self.entity)
    self.spawned_drones = {}

    if not self.data:HasString("drone_spawn_trigger") then
        local item_component = EntityService:GetConstComponent(self.entity, "InventoryItemComponent")
        if item_component ~= nil then

            local component = reflection_helper( item_component )
            if component.type == "consumable" or component.type == "skill" then
                self.data:SetString("drone_spawn_trigger", "item_activated")
            else
                self.data:SetString("drone_spawn_trigger", "item_equipped")
            end
        else
            self.data:SetString("drone_spawn_trigger", "spawn")
        end
    end

    if self:IsTriggeredOn( "spawn" ) then
        self:SpawnDrones()
    end
end

function drone_spawner:OnLoad()
    item.OnLoad(self)

    self.trigger_time = self.trigger_time or 0
    if self.data:GetIntOrDefault( "equipped", 0 ) == 0 then
        return
    end

    self:OnUnequipped()

    if self.owner == EntityService:GetParent(self.entity) then
        self:OnEquipped()
    end
end

function drone_spawner:SpawnDrones(respawn)
    self:DespawnDrones()

    if not respawn then
        self.trigger_time = GetLogicTime()
    end

    if not self.data:HasString("drone_blueprint") then
        local drone_rarity = WR_EXTREME;
        local drone_mod_stats = nil

        local component = EntityService:GetConstComponent(self.entity, "EntityModComponent")
        if component ~= nil then
            drone_rarity = reflection_helper( component ).rarity
            drone_mod_stats = reflection_helper( component ).entity_mods
        else
            component = EntityService:GetConstComponent(self.entity, "InventoryItemComponent")
            if component ~= nil then
                drone_rarity = reflection_helper( component ).rarity
            end
        end

        for drone_type in Iter( DRONE_TYPE ) do
            local drone_count = tonumber( self.data:GetStringOrDefault(drone_type, "0") )
            if drone_mod_stats ~= nil then
                drone_count = drone_count + GetDronesCountStat(drone_mod_stats, EntityModType[drone_type])
            end

            if drone_count > 0 then
                local drone_blueprint = GetDroneBlueprint( drone_type, drone_rarity )
                self:SpawnDroneBlueprint(drone_blueprint, drone_count)
            end
        end
    else
        self:SpawnDroneBlueprint(self.data:GetString("drone_blueprint"), self.data:GetIntOrDefault("drone_count", 1))
    end

    if not respawn and #self.spawned_drones > 0 then
        EffectService:SpawnEffects(self.entity, self.data:GetStringOrDefault("drone_spawn_trigger", "item_equipped") )
    end
end

function drone_spawner:DespawnDrones()
    for drone in Iter(self.spawned_drones) do
        if ItemService:IsItemReference( drone, self.entity ) then
            QueueEvent( "DisableDroneRequest", drone )
            QueueEvent( "EmitStateMachineEventRequest", drone, "state_dead" )
            QueueEvent( "DissolveEntityRequest", drone, 0.5, 0.0 )
            EntityService:RequestDestroyPattern( drone, "lifetime", false)
        end
    end

    self.spawned_drones = {}
end

function drone_spawner:IsTriggeredOn(action)
    return self.data:GetStringOrDefault("drone_spawn_trigger", "item_equipped" ) == action
end

function drone_spawner:OnActivate()
    if not self:IsTriggeredOn("item_activated") then
        return
    end

    self.trigger_time = GetLogicTime()

    self:UnregisterHandlers( "RiftTeleportStartEvent" )
    self:UnregisterHandlers( "RiftTeleportEndEvent" )
    
    self:RegisterHandler( self.owner, "RiftTeleportStartEvent",     "OnRiftTeleportStartEvent" )
    self:RegisterHandler( self.owner, "RiftTeleportEndEvent",       "OnRiftTeleportEndEvent" )

    self:SpawnDrones()
end

function drone_spawner:OnEquipped()
    if not self:IsTriggeredOn("item_equipped") then
        return
    end

    self:UnregisterHandlers( "RiftTeleportStartEvent" )
    self:UnregisterHandlers( "RiftTeleportEndEvent" )
    
    self:RegisterHandler( self.owner, "RiftTeleportStartEvent",     "OnRiftTeleportStartEvent" )
    self:RegisterHandler( self.owner, "RiftTeleportEndEvent",       "OnRiftTeleportEndEvent" )

    self:SpawnDrones()
end

function drone_spawner:OnUnequipped()
    self:UnregisterHandlers( "RiftTeleportStartEvent" )
    self:UnregisterHandlers( "RiftTeleportEndEvent" )

    self:DespawnDrones()
end

function drone_spawner:OnRiftTeleportStartEvent()
    self:DespawnDrones()
end

function drone_spawner:OnRiftTeleportEndEvent()
    self:SpawnDrones(true)
end

function drone_spawner:OnRelease()
    self:DespawnDrones()

    if item.OnRelease then
        item.OnRelease(self)
    end
end

return drone_spawner