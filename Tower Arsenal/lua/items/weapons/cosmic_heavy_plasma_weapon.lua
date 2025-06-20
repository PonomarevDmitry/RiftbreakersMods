local charge_weapon = require("lua/items/weapons/charge_weapon.lua")

class 'cosmic_heavy_plasma_weapon' ( charge_weapon )

function cosmic_heavy_plasma_weapon:__init()
    charge_weapon.__init(self,self)
end

function cosmic_heavy_plasma_weapon:OnInit()
    self:CreateShieldStateMachine()
end

function cosmic_heavy_plasma_weapon:OnLoad()
    charge_weapon.OnLoad( self )
    self:CreateShieldStateMachine()
end

function cosmic_heavy_plasma_weapon:CreateShieldStateMachine()
    if self.fsm == nil then
        self.fsm = self:CreateStateMachine()
        self.fsm:AddState("shield", { enter="OnShieldEnter", execute="OnShieldExecute", exit="OnShieldExit", interval=0.1 } )
        self.fsm:AddState("dummy", {} )
    end
end

function cosmic_heavy_plasma_weapon:OnShieldEnter( state )

end

function cosmic_heavy_plasma_weapon:OnShieldExecute( state, dt )
    if state:GetDuration() > 0.3 and not self.shieldCreated then 
        self:CreateShield()
    end
end

function cosmic_heavy_plasma_weapon:OnShieldExit( state )
    self:RemoveShield()
end

function cosmic_heavy_plasma_weapon:CreateShield()
    local db = EntityService:GetDatabase( self.owner )
    if db ~= nil then
        local counter = db:GetIntOrDefault( "heavy_plasma_shield_counter", 0 )
        if counter == 0 then 
            self.shield = EntityService:SpawnAndAttachEntity( "items/weapons/cosmic_heavy_plasma_shield", self.owner, "be_body_upper", EntityService:GetTeam( self.owner ) )
            db:SetInt( "heavy_plasma_shield_counter", 1 )
            db:SetInt( "heavy_plasma_shield_ent", self.shield )
        else
            db:SetInt( "heavy_plasma_shield_counter", counter + 1 )
        end
    end
    self.shieldCreated = true
end

function cosmic_heavy_plasma_weapon:RemoveShield()
    if self.shieldCreated then
        local db = EntityService:GetDatabase( self.owner )
        if db ~= nil then
    		if db:HasInt( "heavy_plasma_shield_counter" ) then
    			local counter = db:GetInt( "heavy_plasma_shield_counter" )
    			if counter <= 1 then
    				self.shield = db:GetInt( "heavy_plasma_shield_ent" )
    				if EntityService:IsAlive( self.shield ) == true then
    					EntityService:RemoveEntity( self.shield );
    				end
    				db:SetInt( "heavy_plasma_shield_counter", 0 )
    				db:SetInt( "heavy_plasma_shield_ent", INVALID_ID )
    			else
    			   db:SetInt( "heavy_plasma_shield_counter", counter - 1 )
    			end
    		end
        end
        self.shieldCreated = false
    end
end

function cosmic_heavy_plasma_weapon:OnActivate()
    WeaponService:StartCharge( self.item )
    self.fsm:ChangeState( "shield" )
end

function cosmic_heavy_plasma_weapon:OnDeactivate()
    WeaponService:StopCharge( self.item )
    self.fsm:ChangeState( "dummy" )
    return true
end

function cosmic_heavy_plasma_weapon:OnUnequipped()
    weapon.OnUnequipped( self )
    if self.shieldCreated then 
        self:RemoveShield()
        self.shieldCreated = false
    end
end

return cosmic_heavy_plasma_weapon
