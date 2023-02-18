require("lua/utils/string_utils.lua")

class 'wait_on_trigger' ( LuaObjectiveScript )

function wait_on_trigger:__init()
	LuaObjectiveScript.__init(self,self)
end

function wait_on_trigger:init()

    local triggerName = self.data:GetString( "trigger_name" )

    local entities = FindService:FindEntitiesByName( triggerName )
    Assert( #entities > 0, "ERROR: entity with name: `" .. triggerName .. "` not found!" );
    
    self.triggerEntity = entities[1];
    
    self.filterTeam = self.data:GetStringOrDefault( "team", ""  );
    self.filterType = self.data:GetStringOrDefault( "type", "" )

    self:RegisterHandler( self.triggerEntity, "EnteredTriggerEvent", "OnEnteredTriggerEvent");
end

function wait_on_trigger:OnEnteredTriggerEvent( evt )
    local entity = evt:GetOtherEntity()

    -- filter entities by TEAM
    if not IsNullOrEmpty( self.filterTeam ) then
        if not EntityService:CompareTeam( entity ) ~= self.filterTeam then
            return
        end
    end

    -- filter entities by TYPE
    if not IsNullOrEmpty( self.filterType ) then
        if not EntityService:CompareType( entity, self.filterType ) then
            return
        end
    end

    ObjectiveService:FinishObjectiveByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
    self:UnregisterHandler( self.triggerEntity, "EnteredTriggerEvent", "OnEnteredTriggerEvent" );
end

return wait_on_trigger