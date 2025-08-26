local building = require("lua/buildings/building.lua")
class 'arcology_workshop' ( building )

function arcology_workshop:__init()
	building.__init(self)
end

function arcology_workshop:OnInit()
	local buildingComponent = EntityService:GetConstComponent( self.entity ,"BuildingDesc")
	local helper = reflection_helper(buildingComponent)
	self.name = helper.limit_name

	self.checkerMachine = self:CreateStateMachine()
	self.checkerMachine:AddState( "working", { execute="OnExecute", interval=1 } )
	self.checkerMachine:ChangeState( "working" )
	self.megastructureWorking = false

    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
	self:RegisterHandler( self.entity , "SpecialBuildingActionRequest", "OnSpecialAction" )
    BuildingService:DisableBuilding( self.entity )
    self.active  = false
    self.activated = false

    self.children = EntityService:GetChildren( self.entity, false )
end

function arcology_workshop:OnActivate()
    if ( self.megastructureWorking ) then
        return
    end
	self.megastructureWorking = true
    for child in Iter( self.children ) do
        self:EnableChild( child )
    end
    --LogService:Log( "Arcology workshop activated." )
end

function arcology_workshop:RemoveComponent()
    if ( not self.megastructureWorking ) then
        return
    end
	self.megastructureWorking = false

    --LogService:Log( "Arcology workshop deactivated." )
end

function arcology_workshop:OnDeactivate()
	self:RemoveComponent()
end

function arcology_workshop:OnRemove()
	self:RemoveComponent()
end

function arcology_workshop:SpecialAction()
    if  ( self.activated ) then
        return
    end
    --LogService:Log( "Arcology workshop activated." )
    self.activated = true
    self.data:SetInt("is_special_action_enabled",0)
    BuildingService:EnableBuilding( self.entity )
    local data = CampaignService:GetCampaignData()
    data:SetFloat("ArcologyWorkshopActivated", 1.0)
	QueueEvent( "LuaGlobalEvent", event_sink, "ArcologyWorkshopActivated", {} )
end

function arcology_workshop:OnInteractWithEntityRequest( event )
    self:SpecialAction()
end

function arcology_workshop:CanEnableSpecialAction()
    return self.active and not self.activated
end

function arcology_workshop:OnSpecialAction()
    self:SpecialAction()
end

function arcology_workshop:EnableChild( child )
    local childrenData = EntityService:GetDatabase( child)
    if ( childrenData == nil ) then
        return
    end

    EffectService:AttachDelayedEffects(child, "working", 0.1)	
	EffectService:AttachDelayedEffects(child, "powered", 0.1)	
	childrenData:SetFloat("is_working", 1.0 )
	childrenData:SetInt("power", 1.0 )
	childrenData:SetInt("resource", 1.0 )
	EntityService:SetGraphicsUniform( child, "cGlowFactor", 1 )
end

function arcology_workshop:DisableChild(  child)
    local childrenData = EntityService:GetDatabase( child)
    if ( childrenData == nil ) then
        return
    end

    EffectService:DestroyEffectsByGroup(child, "powered")
	childrenData:SetFloat("is_working", 0.0 )
	childrenData:SetInt("power", 0.0 )
	childrenData:SetInt("resource", 0.0 )
	EffectService:DestroyEffectsByGroup(child, "working")	
	EntityService:SetGraphicsUniform( child, "cGlowFactor", 0 )
end

function arcology_workshop:OnExecute()
    
    local data = CampaignService:GetCampaignData()

    local arcology_workshops = 
    {
        "gravitational_hyper_lens",
        "hydroponic_lab",
        "nanobot_center"
    }

    local allWorking = true
    for item in Iter( arcology_workshops ) do
        if ( data:GetFloatOrDefault( item, 0 ) == 0 ) then
            allWorking= false
        end
    end

    local objectiveId = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( "global.arcology_megastructures.arcology_progress" )
    local objectiveStatus = ObjectiveService:GetObjectiveStatus( objectiveId )
    allWorking = allWorking and objectiveStatus ~= OBJECTIVE_SUCCESS
    allWorking = allWorking and BuildingService:IsBuildingPowered( self.entity ) and BuildingService:IsResourceSupplied( self.entity ) and BuildingService:IsPlayerWorking( self.entity )

    if ( allWorking == true ) then
	    data:SetFloat( self.name, 1)
        self.active = true
        if ( self.activated ) then
            --LogService:Log( "Arcology workshop is already activated, enabling building." )
            BuildingService:EnableBuilding( self.entity )
            self.data:SetInt("is_special_action_enabled",0)
            self.active = true
        else
            --LogService:Log( "Arcology workshop is not activated, enabling interactive component." )
	        EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 1 )
            for child in Iter( self.children ) do
                EntityService:SetGraphicsUniform( child, "cGlowFactor", 1 )
            end
            EntityService:EnableComponent( self.entity, "InteractiveComponent")
            self.data:SetInt("is_special_action_enabled",1)
        end
    else
        --LogService:Log( "Arcology workshop is not working, disabling interactive component." )
        self.active = false
        EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 0 )
        for child in Iter( self.children ) do
            self:DisableChild( child )
        end
        EntityService:DisableComponent( self.entity, "InteractiveComponent")
        BuildingService:DisableBuilding( self.entity )
    	data:SetFloat( self.name, 0 )
        self.data:SetInt("is_special_action_enabled",0)

    end
end

return arcology_workshop
