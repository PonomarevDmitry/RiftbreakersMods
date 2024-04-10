local item = require("lua/items/item.lua")

class 'ea_sentry_gun' ( item )

function ea_sentry_gun:__init()
	item.__init(self,self)
end

function ea_sentry_gun:OnInit()
	self.bp  = self.data:GetStringOrDefault("blueprint", "items/consumables/sentry_gun" )
	self.timeout = self.data:GetFloatOrDefault("timeout", 10 )
	self.lifeTimeFSM = self:CreateStateMachine()
	self.lifeTimeFSM:AddState( "Timer", { execute="OnTimerExecute" } )
end

function ea_sentry_gun:OnEquipped()
end

function ea_sentry_gun:OnActivate()
    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, self.bp, "", "")
    if ( pos.first == false ) then
        return
    end
    self.tower = PlayerService:BuildBuildingAtSpot(self.bp, pos.second )
	ItemService:SetItemCreator( self.tower, self.entity_blueprint );

    EntityService:CreateLifeTime( self.tower, self.timeout, "" )
    self.lifeTimeFSM:ChangeState( "Timer" )
end

function ea_sentry_gun:CanActivate()
	item.CanActivate( self )
    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        return false
    end
    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, self.bp, "", "")
    return pos.first
end

function ea_sentry_gun:OnLoad()
    item.OnLoad(self)
    self.bp = self.bp or self.data:GetStringOrDefault("blueprint", "items/consumables/sentry_gun" )
end

function ea_sentry_gun:OnTimerExecute( state )
    local lifetime = EntityService:GetLifeTime( self.tower )
	
    if (lifetime <= 0.1) then
        EntityService:RequestDestroyPattern( self.tower, "default", true )
    end
end

return ea_sentry_gun