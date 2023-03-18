require("lua/utils/table_utils.lua")

class 'alien_tower_morph_EA' ( LuaEntityObject )

function alien_tower_morph_EA:__init()
    LuaEntityObject.__init(self,self)
end

function alien_tower_morph_EA:init()
	SetupUnitScale( self.entity, self.data )
    self.fsm = self:CreateStateMachine();
    self.fsm:AddState( "create", { enter="OnCreateEnter", execute="OnCreateExecute", exit="OnCreateExit", interval=0.5 } );
    self.fsm:ChangeState( "create" )  

    EntityService:SetVisible( self.entity, false );
end

function alien_tower_morph_EA:OnCreateEnter(state)
    --AnimationService:StartAnim( self.entity, "from_zero", false )
end

function alien_tower_morph_EA:OnCreateExecute(state)
    EntityService:SetVisible( self.entity, true );
    if not AnimationService:IsAnimActive( self.entity, "from_zero" ) then
        state:Exit()
    end
end

function alien_tower_morph_EA:OnCreateExit()
    local database = EntityService:GetDatabase( self.entity )
    EntityService:SpawnEntity( database:GetString( "blueprint" ) , self.entity, EntityService:GetTeam( self.entity ) )
    EntityService:RemoveEntity( self.entity )
end

return alien_tower_morph_EA
