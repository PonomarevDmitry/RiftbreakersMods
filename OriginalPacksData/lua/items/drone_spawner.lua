require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local item = require("lua/items/item.lua")
class 'drone_spawner' ( item )

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

    return nil
end

local function GetBlueprintSuffix( rarity )
    local suffixes = 
    {
        [WR_STANDARD] = "_standard",
        [WR_ADVANCED] = "_advanced",
        [WR_SUPERIOR] = "_superior",
        [WR_EXTREME] = "_extreme",
    }

    local suffix = suffixes[ rarity ]
    if suffix == nil then
        return ""
    end
    return suffix
end

function drone_spawner:SpawnDroneBlueprint( blueprint, count )
    local team = EntityService:GetTeam(self.owner)

    for i=1,count do
        
        local position = EntityService:GetPosition(self.owner)
        position.x = position.x + RandFloat( 1.0, 5.0 )
        position.y = position.y + RandFloat( 7.0, 8.0 )
        position.z = position.z + RandFloat( 1.0, 5.0 )

        local drone = EntityService:SpawnEntity( blueprint, position, team);
        EntityService:Rotate( drone, 0.0, 1.0, 0.0, RandFloat(0.0, 360.0))
        UnitService:SetCurrentTarget( drone, "owner", self.owner );

        QueueEvent( "EnableDroneRequest", drone)
		QueueEvent( "FadeEntityInRequest", drone, 2.0 )

	    EffectService:AttachEffects(drone, "fly")
        
        Insert(self.spawned_drones,drone)
    end
end

function drone_spawner:init()
	item.init(self)

    self.spawned_drones = {}
end

function drone_spawner:OnLoad()
    item.OnLoad(self)

    self:OnUnequipped()

    if self.owner == EntityService:GetParent(self.entity) and self.data:GetIntOrDefault( "equipped", 0 ) == 1 then
        self:OnEquipped()
    end
end

function drone_spawner:SpawnDrones()
    self:DespawnDrones()

    if not self.data:HasString("drone_blueprint") then
        local modComponent = EntityService:GetComponent(self.entity, "EntityModComponent")
        if modComponent == nil then
            return
        end

        local rarity = reflection_helper( modComponent ).rarity

        local blueprint_suffix = GetBlueprintSuffix(rarity)
        local stat_drone_blueprints = 
        {
            [EntityModType.repair_drone]     = "units/drones/drone_player_repair" .. blueprint_suffix,             -- stat RepairDrone
            [EntityModType.attack_drone]     = "units/drones/drone_player_offensive".. blueprint_suffix,           -- stat AttackDrone
            [EntityModType.defense_drone]    = "units/drones/drone_player_defensive".. blueprint_suffix,           -- stat DefensiveDrone
            [EntityModType.loot_drone]       = "units/drones/drone_player_loot_collector".. blueprint_suffix,      -- stat LootDrone
        };

        local stats = reflection_helper( modComponent ).entity_mods
        for stat, blueprint in pairs(stat_drone_blueprints) do
            local count = GetDronesCountStat(stats, stat)
            if count ~= nil then
                self:SpawnDroneBlueprint(blueprint, count)
            end
        end
    else
        self:SpawnDroneBlueprint(self.data:GetString("drone_blueprint"), self.data:GetIntOrDefault("drone_count", 1))
    end
end

function drone_spawner:DespawnDrones()
    for drone in Iter(self.spawned_drones) do
        if UnitService:GetCurrentTarget( drone, "owner" ) ~= INVALID_ID then
            QueueEvent( "DisableDroneRequest", drone )
            QueueEvent( "EmitStateMachineEventRequest", drone, "state_dead" )
            QueueEvent( "DissolveEntityRequest", drone, 0.5, 0.0 )
        end
    end

    self.spawned_drones = {}
end

function drone_spawner:OnEquipped()
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
    self:SpawnDrones()
end

function drone_spawner:OnRelease()
    self:DespawnDrones()
end

return drone_spawner