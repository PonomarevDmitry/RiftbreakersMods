local autofire_weapon = require("lua/items/weapons/autofire_weapon.lua")

class 'auto_heavy_plasma_weapon' ( autofire_weapon )

function auto_heavy_plasma_weapon:__init()
    autofire_weapon.__init(self,self)
end

function auto_heavy_plasma_weapon:OnInit()
    autofire_weapon.OnInit(self)
    self:CreateShieldStateMachine()
end

function auto_heavy_plasma_weapon:OnLoad()
    autofire_weapon.OnLoad( self )
    self:CreateShieldStateMachine()
end

function auto_heavy_plasma_weapon:CreateShieldStateMachine()
    if self.fsm == nil then
        self.fsm = self:CreateStateMachine()
        self.fsm:AddState("shield", { enter="OnShieldEnter", execute="OnShieldExecute", exit="OnShieldExit", interval=0.1 } )
        self.fsm:AddState("dummy", {} )
    end
end

function auto_heavy_plasma_weapon:OnShieldEnter( state )

end

function auto_heavy_plasma_weapon:OnShieldExecute( state, dt )
    if state:GetDuration() > 0.3 and not self.shieldCreated then
        self:CreateShield()
    end
end

function auto_heavy_plasma_weapon:OnShieldExit( state )
    self:RemoveShield()
end

function auto_heavy_plasma_weapon:CreateShield()
    local db = EntityService:GetOrCreateDatabase( self.owner )
    if db ~= nil then
        local counter = db:GetIntOrDefault( "heavy_plasma_shield_counter", 0 )
        if counter == 0 then
            self.shield = EntityService:SpawnAndAttachEntity( "items/weapons/heavy_plasma_shield", self.owner, "be_body_upper", EntityService:GetTeam( self.owner ) )
            db:SetInt( "heavy_plasma_shield_counter", 1 )
            db:SetInt( "heavy_plasma_shield_ent", self.shield )
        else
            db:SetInt( "heavy_plasma_shield_counter", counter + 1 )
        end
    end
    self.shieldCreated = true
end

function auto_heavy_plasma_weapon:RemoveShield()
    if self.shieldCreated then
        local db = EntityService:GetOrCreateDatabase( self.owner )
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

function auto_heavy_plasma_weapon:OnActivate()
    autofire_weapon.OnActivate(self)
    self.fsm:ChangeState( "shield" )
end

function auto_heavy_plasma_weapon:OnDeactivate()
    autofire_weapon.OnDeactivate(self)
    self.fsm:ChangeState( "dummy" )
    return true
end

function auto_heavy_plasma_weapon:OnUnequipped()
    autofire_weapon.OnUnequipped( self )
    if self.shieldCreated then
        self:RemoveShield()
        self.shieldCreated = false
    end
end

return auto_heavy_plasma_weapon
