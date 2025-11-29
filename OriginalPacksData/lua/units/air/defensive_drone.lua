require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'defensive_drone' ( base_drone )

function defensive_drone:__init()
	base_drone.__init(self,self)
end

function defensive_drone:FindActionTarget()
    return INVALID_ID
end

function defensive_drone:FillInitialParams()
    if self.data:HasFloat("drone_search_radius") then
        self.search_radius = self.data:GetFloat("drone_search_radius")
    else
        self.search_radius = self.data:GetFloat("search_radius")
    end

    self.search_component = self.data:GetStringOrDefault("search_component", "ProjectileAmmoComponent");
    self.search_interval = self.data:GetFloatOrDefault("search_interval", 0.3);

    self.lightning_effect = self.data:GetStringOrDefault("lightning_effect", "effects/buildings_and_machines/drone_defensive_lightning");
    self.lightning_hit_effect = self.data:GetStringOrDefault("lightning_effect", "effects/buildings_and_machines/drone_defensive_lightning_hit");

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState( "finder", { execute="OnFinderExecute" });

    self.fsm:ChangeState("finder")

    self:SetEmissiveUniform( 0.0 )
end

local function GetProjectileHitEffect(target_entity)
    local projectile = EntityService:GetComponent(target_entity, "ProjectileAmmoComponent")
    if projectile == nil then
        return nil
    end

    local component = reflection_helper( projectile )
    if component.on_resisted_hit_effect ~= "" then
        return component.on_resisted_hit_effect
    end

    if component.on_world_hit_effect ~= "" then
        return component.on_world_hit_effect
    end

    return nil
end

function defensive_drone:ShootLightningAtTarget(target_entity)
    self:SetEmissiveUniform( 0.0 )

    local drone_position = EntityService:GetPosition(self.entity)
    local target_position = EntityService:GetPosition(target_entity)

    local lightning = EntityService:SpawnEntity( self.lightning_effect, self.entity, "")
    local component = reflection_helper(EntityService:GetComponent(lightning, "LightningDataComponent"))

    local container = rawget(component.lighning_vec, "__ptr");
    
    local instance = nil
    if ( container:GetItemCount() == 0 ) then
        instance = reflection_helper(container:CreateItem())
    else 
        instance = reflection_helper(container:GetItem(0))
    end

    local direction = VectorMulByNumber( Normalize( VectorSub( target_position, drone_position ) ), 2.0 )
    drone_position = VectorAdd(drone_position, direction)

    instance.start_point.x = drone_position.x
    instance.start_point.y = drone_position.y
    instance.start_point.z = drone_position.z

    instance.end_point.x = target_position.x
    instance.end_point.y = target_position.y
    instance.end_point.z = target_position.z

    local projectile_effect = GetProjectileHitEffect(target_entity)
    if projectile_effect ~= nil then
        EntityService:SpawnEntity( projectile_effect, target_position.x, target_position.y, target_position.z, "")
    else
        EntityService:SpawnEntity( self.lightning_hit_effect, drone_position.x, drone_position.y, drone_position.z, "")
    end

    EntityService:RemoveEntity(target_entity)
end

function defensive_drone:SetEmissiveUniform( factor )
    local value =  math.min( 1.0, factor )

    local entities = EntityService:GetChildren( self.entity, false )
    Insert(entities, self.entity)

    for entity in Iter( entities ) do
        EntityService:SetGraphicsUniform( entity, "cGlowFactor", value )
       -- EntityService:SetGraphicsUniform( entity, "cEmissiveFactor", value * 16.0 )
    end
end

function defensive_drone:OnFinderExecute(state)
    if state:GetDuration() < self.search_interval then
        return self:SetEmissiveUniform( state:GetDuration() / self.search_interval )
    end

    self.dron_temp_owner = self:GetDroneOwnerTarget();

    self.predicate = self.predicate or {
        signature=self.search_component,
        filter = function(entity)
            return EntityService:IsInTeamRelation(self.dron_temp_owner, entity, "hostility")
        end
    };

    local entities = FindService:FindEntitiesByPredicateInRadius( self.entity, self.search_radius, self.predicate );
    local target = FindClosestEntity( self.entity, entities );
    if target == INVALID_ID then
        return
    end

    -- reset existing duration
    state:SetDurationLimit(self.search_interval)
    state:ClearDurationLimit()

    self:ShootLightningAtTarget(target)
end

function defensive_drone:OnInit()
    self:FillInitialParams();
end

function defensive_drone:OnLoad()
    self:FillInitialParams();
    
    base_drone.OnLoad( self )
end

return defensive_drone;
