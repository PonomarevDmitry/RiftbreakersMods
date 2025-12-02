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
        
    self:RegisterHandler( self.entity, "TeleportAppearEnter",  "OnTeleportAppearEnter" )
    self:RegisterHandler( self.entity, "TeleportAppearExit",  "OnTeleportAppearExit" )
end

function customizable_movement_skill:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end

    if ( self.machine == nil ) then
        self:InitThrowStateMachine()
    end
        
    self:RegisterHandler( self.entity, "TeleportAppearEnter",  "OnTeleportAppearEnter" )
    self:RegisterHandler( self.entity, "TeleportAppearExit",  "OnTeleportAppearExit" )
end

function customizable_movement_skill:InitThrowStateMachine()

    self.machine = self:CreateStateMachine()
    self.machine:AddState( "dash", { execute="OnDashExecute", exit="OnDashExit" } )
    self.machine:AddState( "rolling", { from="*", enter="OnRollEnter", execute="OnRollExecute",exit="OnRollExit"} )
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

    local trailTypeBlueprint = self:GetModBlueprintName(4)
    if ( trailTypeBlueprint and trailTypeBlueprint ~= "" ) then

        local database = EntityService:GetBlueprintDatabase( trailTypeBlueprint )

        self.trailTime = database:GetFloatOrDefault( "trail_time", 1 )
        self.trailSpacing = database:GetFloatOrDefault( "trail_spacing", 1 )
        self.trailExtend = database:GetFloatOrDefault( "trail_extend_time", 0.5 )
        self.trailEffect = database:GetStringOrDefault( "trail_effect", "" ) or ""
    else
        self.trailTime = 1
        self.trailSpacing = 1
        self.trailExtend = 0.5
        self.trailEffect = ""
    end

    local movementType = self:GetModBlueprintName(1)
    if ( movementType == nil or movementType == "" ) then
        movementType = "items/customizable_movement_skill_mods/type_dash_item"
    end

    self:UnregisterHandler( self.owner, "RiftTeleportEndEvent", "OnOwnerRiftTeleportEndEvent" )
    self:UnregisterHandler( self.owner, "AnimationMarkerReached", "OnAnimationMarkerReached" )

    local databaseMovementType = EntityService:GetBlueprintDatabase( movementType )

    if ( movementType == "items/customizable_movement_skill_mods/type_teleport_item" ) then

        self.maxDistance = databaseMovementType:GetFloatOrDefault("distance", -1.0 )
        
        local pos = PlayerService:GetWeaponLookPoint( self.owner )

        local foundPos = PlayerService:FindPositionForTeleport( self.owner, pos, self.maxDistance )
        if ( foundPos.first ) then

            self:SpawnStartExplosion()
            self:SpawnStartMine()

            self:RegisterHandler( self.owner, "RiftTeleportEndEvent", "OnOwnerRiftTeleportEndEvent" )

            PlayerService:TeleportPlayer( self.owner, foundPos.second, 0.2, 0.1, 0.2 )
        else

            ItemService:ResetCooldown( self.entity, 0.0 )
        end

    elseif ( movementType == "items/customizable_movement_skill_mods/type_jump_item" ) then

        self:SpawnStartExplosion()
        self:SpawnStartMine()
    
        EntityService:Dash( self.owner, self.item )

        self.set = false
        self.lastPosition = nil

        --self.machine:ChangeState("dash")

    elseif ( movementType == "items/customizable_movement_skill_mods/type_dodge_roll_item" ) then

        self:SpawnStartExplosion()
        self:SpawnStartMine()

        self:RegisterHandler( self.owner, "AnimationMarkerReached", "OnAnimationMarkerReached" )

        local specialMovementDataComponent = EntityService:GetComponent( self.item, "SpecialMovementDataComponent" )
        if ( specialMovementDataComponent ~= nil ) then

            local specialMovementDataComponentRef = reflection_helper(specialMovementDataComponent)

            specialMovementDataComponentRef.param_name = "is_rolling"
            specialMovementDataComponentRef.start_effect = ""
            specialMovementDataComponentRef.continuous_effect = ""

            specialMovementDataComponentRef.block_aiming_dir = "1"
            specialMovementDataComponentRef.disable_unit_collision = "1"
        end

        self.rollSpeed = databaseMovementType:GetFloatOrDefault("roll_speed", 2.0 )

        local db = EntityService:GetOrCreateDatabase( self.owner )
        db:SetFloat( "roll_speed", self.rollSpeed )
    
        EntityService:Dash( self.owner, self.item )

        self.set = false
        self.lastPosition = nil

        self.machine:ChangeState("rolling")
    else

        self:SpawnStartExplosion()
        self:SpawnStartMine()

        local specialMovementDataComponent = EntityService:GetComponent( self.item, "SpecialMovementDataComponent" )
        if ( specialMovementDataComponent ~= nil ) then

            local specialMovementDataComponentRef = reflection_helper(specialMovementDataComponent)

            specialMovementDataComponentRef.param_name = "is_dashing"
            specialMovementDataComponentRef.start_effect = "dash_start_long"
            specialMovementDataComponentRef.continuous_effect = "dash_trail_long"

            specialMovementDataComponentRef.block_aiming_dir = "0"
            specialMovementDataComponentRef.disable_unit_collision = "0"

            --LogService:Log("specialMovementDataComponentRef " .. tostring(specialMovementDataComponentRef))
        end

        EntityService:Dash( self.owner, self.item )

        self.set = false
        self.lastPosition = nil

        self.machine:ChangeState("dash")
    end
end

function customizable_movement_skill:OnDashExecute( state )

    if ( EntityService:IsAlive( self.owner ) == false ) then
        self.set = true
        state:Exit()
        return
    end
    
    self.trailSpacing = self.trailSpacing or 1

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
    
        self.trailExtend = self.trailExtend or 0.5

        state:SetDurationLimit( self.trailExtend )
        self.set = true
    end 
end

function customizable_movement_skill:OnDashExit()

    self:SpawnEndExplosion()

    self:SpawnEndMine()
end

function customizable_movement_skill:OnRollEnter( state )
    EntityService:DisableCollisions( self.owner )
    HealthService:SetImmortality( self.owner, true )
    EntityService:ChangeCharacterControllerGroupId( self.owner, "debris" )
end

function customizable_movement_skill:OnRollExecute( state )

    if ( EntityService:IsAlive( self.owner ) == false ) then
        self.set = true
        state:Exit()
        return
    end
    
    self.trailSpacing = self.trailSpacing or 1

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
    
        self.trailExtend = self.trailExtend or 0.5

        state:SetDurationLimit( self.trailExtend )
        self.set = true
    end 
end

function customizable_movement_skill:OnRollExit()

    self.machine:Deactivate()

    self:UnregisterHandler( self.owner, "AnimationMarkerReached", "OnAnimationMarkerReached" )

    EntityService:EnableCollisions( self.owner )
    HealthService:SetImmortality( self.owner, false )
    EntityService:ChangeCharacterControllerGroupId( self.owner, "character" )

    self:SpawnEndExplosion()

    self:SpawnEndMine()
end

function customizable_movement_skill:OnAnimationMarkerReached(evt)
    if ( evt:GetMarkerName() == "roll_start" ) then
        self.machine:ChangeState("rolling")
    elseif ( evt:GetMarkerName() == "roll_end" ) then
        self.machine:Deactivate()
    end
end

function customizable_movement_skill:SpawnTrailEffect()

    self.trailEffect = self.trailEffect or ""

    if ( self.trailEffect == "" ) then
        return
    end

    local spot = EntityService:GetPosition( self.owner )
    spot.y = EnvironmentService:GetTerrainHeight(spot)

    local team = EntityService:GetTeam( self.owner )

    local trail = EntityService:SpawnEntity( self.trailEffect, spot, team )

    ItemService:SetItemCreator( trail, EntityService:GetBlueprintName(self.entity) )

    self.trailTime = self.trailTime or 1

    EntityService:PropagateEntityOwner( trail, self.owner )
    EntityService:DissolveEntity( trail, self.trailTime, 1.0 )
end

function customizable_movement_skill:SpawnStartExplosion()

    local explosionStart = self:GetModBlueprintName(2)
    if ( explosionStart and explosionStart ~= "" ) then

        self:SpawnExplosion( explosionStart )
    end
end

function customizable_movement_skill:SpawnEndExplosion()

    local explosionEnd = self:GetModBlueprintName(3)
    if ( explosionEnd and explosionEnd ~= "" ) then

        self:SpawnExplosion( explosionEnd )
    end
end

function customizable_movement_skill:SpawnExplosion(modExplosionBlueprint)

    local selfBlueprint = EntityService:GetBlueprintName( self.entity )

    local team = EntityService:GetTeam( self.owner )

    local database = EntityService:GetBlueprintDatabase( modExplosionBlueprint )


    local explosionBlueprint = database:GetStringOrDefault( "bp", "" )
    local att = database:GetStringOrDefault( "att", "" )


    local spawned = EntityService:SpawnEntity( explosionBlueprint, self.owner, att, team )

    EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )

    ItemService:SetItemCreator( spawned, selfBlueprint )
    EntityService:PropagateEntityOwner( spawned, self.owner )

    EntityService:FadeEntity( spawned, DD_FADE_IN, 0.5 )



    local radiusBp = database:GetStringOrDefault( "radius_bp", "") or ""
    local radiusSize = database:GetFloatOrDefault( "radius_size", 0 )
    local radiusLifeTime = database:GetFloatOrDefault( "radius_lifetime", 0 )

    if ( radiusBp == nil or radiusBp == "" ) then

        radiusBp = self.trailEffect
    end

    radiusBp = radiusBp or ""

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

function customizable_movement_skill:SpawnStartMine()

    local mineStart = self:GetModBlueprintName(5)
    if ( mineStart and mineStart ~= "" ) then

        self:SpawnMine( mineStart )
    end
end

function customizable_movement_skill:SpawnEndMine()

    local mineEnd = self:GetModBlueprintName(6)
    if ( mineEnd and mineEnd ~= "" ) then

        self:SpawnMine( mineEnd )
    end
end

function customizable_movement_skill:SpawnMine(modMineBlueprint)

    local team = EntityService:GetTeam( self.owner )

    local database = EntityService:GetBlueprintDatabase( modMineBlueprint )

    local mineBlueprintName = database:GetString("bp")


    local spot = EntityService:GetPosition( self.owner )

    spot.y = EnvironmentService:GetTerrainHeight(spot)

    local spawned = EntityService:SpawnEntity( mineBlueprintName, spot, team)

    --EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )

    ItemService:SetItemCreator( spawned, mineBlueprintName )
    EntityService:PropagateEntityOwner( spawned, self.owner )

    
    EntityService:SpawnEntity( "effects/customizable_movement_skill/mine_created", spawned, "" )


    local dissolveTime = database:GetFloatOrDefault( "dissolve", 0.3 )

    --QueueEvent( "FadeEntityInRequest", spawned, dissolveTime )
    EntityService:FadeEntity( spawned, DD_FADE_IN, dissolveTime )
end

function customizable_movement_skill:OnTeleportAppearEnter()
    self.data:SetInt("leaving", 1)
end

function customizable_movement_skill:OnTeleportAppearExit()
    self.data:SetInt("leaving", 0)
end

function customizable_movement_skill:OnOwnerRiftTeleportEndEvent()

    self:UnregisterHandler( self.owner, "RiftTeleportEndEvent", "OnOwnerRiftTeleportEndEvent" )

    self:SpawnEndExplosion()

    self:SpawnEndMine()
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