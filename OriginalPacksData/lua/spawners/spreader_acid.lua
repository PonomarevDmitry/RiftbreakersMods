require ( "lua/utils/table_utils.lua" )
require ( "lua/utils/numeric_utils.lua" )

local spreader = require("lua/spawners/spreader.lua");
class 'spreader_acid' ( spreader )

function spreader_acid:__init()
	spreader.__init(self,self)
end

function spreader_acid:init()	
	spreader.init(self,self)

    self.testCheck = self:CreateStateMachine();
	self.testCheck:AddState( "check", { execute="OnCheckExecute", interval=2.0 } );
    self.testCheck:ChangeState("check")
    self.isImmortal = false;
    self.lastAmountOfStations = false

end

function spreader_acid:OnLoad()
    spreader.OnLoad(self)
    self.isImmortal = self.isImmortal or false
    local amount = false
    if ( self.isImmortal ) then
        amount = true
    end
    self.lastAmountOfStations = self.lastAmountOfStations or amount
    self.createStealthComponent = not EntityService:GetComponent(self.entity, "StealthComponent")
end

function spreader_acid:OnCheckExecute()
    if self.createStealthComponent then
        self.createStealthComponent = false
        EntityService:CreateComponent(self.entity, "StealthComponent")
    end

    local entities = FindService:FindEntitiesByNameInRadius( self.entity, "research_station", 25.0 )
    local working = false;
    for building in Iter(entities) do
        working = working or BuildingService:IsWorking( building )
    end
    self.scanning = working
    local amountOfStations = #entities > 0
    if ( working == false ) then
        if ( self.isImmortal == true ) then
		    EntityService:ChangeType( self.entity, "ground_unit" )
		    EntityService:SetTeam( self.entity, "enemy" )
	        QueueEvent("RecreateComponentFromBlueprintRequest", self.entity, "PhysicsComponent" )
            self.isImmortal = false
        end
        EffectService:DestroyEffectsByGroup(self.entity, "scanning")
    else
        if ( EffectService:HasEffectByGroup( self.entity, "scanning" ) == false ) then    
	    	EffectService:AttachEffects(self.entity, "scanning")
	    end
        if ( self.isImmortal == false ) then
		    EntityService:RemoveComponent( self.entity, "TypeComponent" )
		    EntityService:RemoveComponent( self.entity, "TeamComponent" )
            EntityService:ChangePhysicsGroupId( self.entity, "world_destructible" )
            HealthService:SetImmortality( self.entity,true )
            self.isImmortal = true
        end
    end
    if ( amountOfStations ~= self.lastAmountOfStations) then
        HealthService:SetImmortality( self.entity, amountOfStations )
        self.lastAmountOfStations = amountOfStations
    end
end

function spreader_acid:OnDestroyRequest( evt )
    spreader.OnDestroyRequest( self, evt )
	EntityService:RevealVegetation( self.entity )
    EntityService:SetName(self.entity, "")
end


return spreader_acid