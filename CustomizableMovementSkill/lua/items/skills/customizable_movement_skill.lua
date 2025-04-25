require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local item = require("lua/items/item.lua")

class 'customizable_movement_skill' ( item )

function customizable_movement_skill:__init()
    item.__init(self,self)
end

function customizable_movement_skill:OnInit()

    if ( self.machine == nil ) then
        self:InitThrowStateMachine()
    end
end

function customizable_movement_skill:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end

    if ( self.machine == nil ) then
        self:InitThrowStateMachine()
    end
end

function customizable_movement_skill:InitThrowStateMachine()

    self.machine = self:CreateStateMachine()
    self.machine:AddState( "dash", { execute="OnDashExecute" } )
end

function customizable_movement_skill:OnEquipped()
    self.lastPosition = nil
end

function customizable_movement_skill:OnUnequipped()
    self.lastPosition = nil
end

function customizable_movement_skill:OnActivate()

    if ( self.machine == nil ) then
        self:InitThrowStateMachine()
    end

    local explosionStart = self:GetModBlueprintName(2)
    if ( explosionStart and explosionStart ~= "" ) then

        self:SpawnExplosion( explosionStart )
    end
    

    local trailType = self:GetModBlueprintName(4)
    if ( trailType and trailType ~= "" ) then

        self.trailTime = self.data:GetFloatOrDefault( "trail_time", 1 )
        self.trailSpacing = self.data:GetFloatOrDefault( "trail_spacing", 1 )
        self.trailExtend = self.data:GetFloatOrDefault( "trail_extend_time", 0.5 )
        self.trailEffect = self.data:GetStringOrDefault( "trail_effect", "" )
    end

    local movementType = self:GetModBlueprintName(1)
    if ( movementType == nil or movementType == "" ) then
        movementType = "items/customizable_movement_skill_mods/type_dash_item"
    end

    if ( movementType == "items/customizable_movement_skill_mods/type_jump_item" ) then
    
        EntityService:Dash( self.owner, self.item )

        self.set = false
        self.lastPosition = nil

        --self.machine:ChangeState("dash")
    else
    
        EntityService:Dash( self.owner, self.item )

        self.set = false
        self.lastPosition = nil

        self.machine:ChangeState("dash")
    end
end

function customizable_movement_skill:CanActivate()

    if ( item.CanActivate ) then
        item.CanActivate(self)
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        return false
    end

    return true
end

function customizable_movement_skill:OnDashExecute( state )

    if ( EntityService:IsAlive( self.owner ) == false ) then
        self.set = true
        state:Exit()
        return
    end
    
    self.trailSpacing = self.trailSpacing or 0

    if ( self.lastPosition == nil ) then

        self.lastPosition = EntityService:GetPosition( self.owner )
        self.lastPosition.y = EnvironmentService:GetTerrainHeight(self.lastPosition)

        self:SpawnTrailEffect()

    else
        local currentPosition = EntityService:GetPosition( self.owner )
        currentPosition.y = EnvironmentService:GetTerrainHeight(currentPosition)

        local distance = Distance( currentPosition, self.lastPosition )

        if ( distance >= self.trailSpacing  ) then

            self.lastPosition = currentPosition
            self.lastPosition.x = self.lastPosition.x + RandFloat( -0.5, 0.5 )
            self.lastPosition.z = self.lastPosition.z + RandFloat( -0.5, 0.5 )

            self:SpawnTrailEffect()
        end
    end

    if (self.set == false and EntityService:IsDashing( self.owner ) == false ) then
    
        self.trailExtend = self.trailExtend or 0

        state:SetDurationLimit( self.trailExtend )
        self.set = true

        local explosionEnd = self:GetModBlueprintName(3)
        if ( explosionEnd and explosionEnd ~= "" ) then

            self:SpawnExplosion( explosionEnd )
        end
    end 
end

function customizable_movement_skill:SpawnTrailEffect()

    if ( self.trailEffect == nil or self.trailEffect == "" ) then
        return
    end

    local spot = EntityService:GetPosition( self.owner )
    spot.y = EnvironmentService:GetTerrainHeight(spot)

    local trail = EntityService:SpawnEntity( self.trailEffect, spot, "" )

    ItemService:SetItemCreator( trail, EntityService:GetBlueprintName(self.entity) )

    EntityService:PropagateEntityOwner( trail, self.owner )
    EntityService:DissolveEntity( trail, self.trailTime, 1.0 )
end

function customizable_movement_skill:SpawnExplosion(modExplosionBlueprint)

    local selfBlueprint = EntityService:GetBlueprintName( self.entity )

    local team = EntityService:GetTeam( self.owner )

    local database = EntityService:GetBlueprintDatabase( modExplosionBlueprint )



    local explosionBlueprint = database:GetStringOrDefault( "bp", "" )
    local att = database:GetStringOrDefault( "att", "" )

    local radiusBp = database:GetStringOrDefault( "radius_bp", "")
    local radiusSize = database:GetFloatOrDefault( "radius_size", 0 )
    local radiusLifeTime = database:GetFloatOrDefault( "radius_lifetime", 0 )



    local spawned = EntityService:SpawnEntity( explosionBlueprint, self.owner, att, team )

    EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )

    ItemService:SetItemCreator( spawned, selfBlueprint )
    EntityService:PropagateEntityOwner( spawned, self.owner )

    EntityService:FadeEntity( spawned, DD_FADE_IN, 0.5 )

    if ( radiusBp ~= "" ) then

        local points = FindService:GetSpotsInRadius( self.owner, 0, radiusSize )

        for pos in Iter(points) do

            local trail = EntityService:SpawnEntity( radiusBp, pos, team )

            ItemService:SetItemCreator( trail, selfBlueprint )
            EntityService:PropagateEntityOwner( trail, self.owner )

            EntityService:DissolveEntity( trail, radiusLifeTime, 1.0 )
        end
    end
end

function customizable_movement_skill:GetModBlueprintName(slotNumber)

    local modItemBlueprint = self.data:GetStringOrDefault("customizable_movement_skill_MOD_" .. tostring(slotNumber), "") or ""

    if ( modItemBlueprint == nil or modItemBlueprint == "" ) then
        return ""
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then
        return ""
    end

    return modItemBlueprint
end

return customizable_movement_skill