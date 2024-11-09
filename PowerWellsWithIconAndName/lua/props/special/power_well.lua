require("lua/utils/reflection.lua")

local player_modificator_source = require("lua/misc/player_modificator_source.lua")

class 'power_well' ( player_modificator_source )

function power_well:__init()
	player_modificator_source.__init(self,self)
end

function power_well:UpdateWorkingState()
    local working = 0
    if not self.activated and self.entities_in_trigger > 0 then
        working = 1
    end

    self.data:SetInt("working", working)

    local hasEffectsEnabled = EffectService:HasEffectByGroup( self.entity, "container") 
    if working ~= hasEffectsEnabled then
        if working then
            EffectService:AttachEffects( self.entity, "container")
        else
            EffectService:DestroyDelayedEffectsByGroup( self.entity, "container", 1.0 )
        end
    end
end

function power_well:init()
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )

    self:RegisterHandler( self.entity, "EnteredTriggerEvent", "OnEnteredTriggerEvent" )
    self:RegisterHandler( self.entity, "LeftTriggerEvent", "OnLeftTriggerEvent" )
	self:RegisterHandler( self.entity, "AnimationMarkerReached", "OnAnimationMarkerReached" ) 

    self.entities_in_trigger = 0
    self:UpdateWorkingState();

    self:SpawnIconEntity()
end

function power_well:OnLoad()
    
    if ( player_modificator_source.OnLoad ) then

        player_modificator_source.OnLoad(self)
    end

    self:SpawnIconEntity()
end

function power_well:OnAnimationMarkerReached(evt)
	EffectService:SpawnEffects(self.entity, evt:GetMarkerName())
end

function power_well:OnInteractWithEntityRequest( evt )
    if self.activated then
        return
    end

    CampaignService:UpdateAchievementProgress(ACHIEVEMENT_OPEN_POWER_WELLS, 1)

    self:AttachModificator(evt:GetOwner())

    self.activated = true;
    self:UpdateWorkingState();

    EntityService:RemoveEntity( self.entity, 2.0 )
end

function power_well:OnEnteredTriggerEvent(evt)
    self.entities_in_trigger = ( self.entities_in_trigger or 0 ) + 1

    self:UpdateWorkingState();
end

function power_well:OnLeftTriggerEvent(evt)
    self.entities_in_trigger = ( self.entities_in_trigger or 0 ) - 1

    self:UpdateWorkingState();
end

function power_well:SpawnIconEntity()

    local blueprintDatabase = EntityService:GetBlueprintDatabase( self.entity )
    if ( blueprintDatabase == nil ) then
        return
    end

    if ( not blueprintDatabase:HasString("blueprint") ) then
        return
    end

    local bonusBlueprintName = blueprintDatabase:GetString("blueprint")

    local bonusBlueprint = ResourceManager:GetBlueprint( bonusBlueprintName )
    if ( bonusBlueprint == nil ) then
        return
    end

    local skillLinkUnitComponent = bonusBlueprint:GetComponent("SkillLinkUnitComponent")
    if ( skillLinkUnitComponent == nil ) then
        return
    end

    local skillLinkUnitComponentRef = reflection_helper( skillLinkUnitComponent )



	local minimapItemComponent = EntityService:GetComponent( self.entity, "MinimapItemComponent" )
	if ( minimapItemComponent ~= nil ) then

		local minimapItemComponentRef = reflection_helper( minimapItemComponent )

        minimapItemComponentRef.icon_material = skillLinkUnitComponentRef.icon

        if ( minimapItemComponentRef.size ) then
            minimapItemComponentRef.size.x = 0.5
            minimapItemComponentRef.size.y = 0.5
        end

        EntityService:RemoveComponent( self.entity, "MinimapGuiComponent" )
	end





	local markerBlueprintName = "misc/power_well_icon_menu"

	local children = EntityService:GetChildren( self.entity, true )
	for child in Iter(children) do

		local blueprintName = EntityService:GetBlueprintName( child )

		if ( blueprintName == markerBlueprintName and EntityService:GetParent( child ) == self.entity ) then

			return
		end
	end

	local team = EntityService:GetTeam( self.entity )

	local iconEntity = EntityService:SpawnAndAttachEntity( markerBlueprintName, self.entity, team )

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    EntityService:SetPosition( iconEntity, 0, sizeSelf.y, 0 )

    local menuDB = EntityService:GetDatabase( iconEntity )
    if ( menuDB == nil ) then
        return
    end

    menuDB:SetString("power_well_icon", skillLinkUnitComponentRef.icon)
    menuDB:SetString("power_well_name", skillLinkUnitComponentRef.name)
end

return power_well