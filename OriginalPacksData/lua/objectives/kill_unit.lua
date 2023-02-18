class 'kill_unit' ( LuaObjectiveScript )

function kill_unit:__init()
	LuaObjectiveScript.__init(self,self)
end

function kill_unit:UpdateProgress( progress )
    self.progress_current = progress;

    self.data:SetInt("progress_current", self.progress_current);

    if self.progress_current >= self.progressMax then
        ObjectiveService:FinishObjectiveByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
        self:UnregisterHandler( event_sink, "EntityKilledEvent", "OnEntityKilledEvent" )
    end
end

function kill_unit:init()
    self.progress_max = self.data:GetInt("count");
    self.data:SetInt("progress_max", self.progress_max);

    self.required_blueprint = self.data:GetString("blueprint");
    self.data:SetString("unit_blueprint_name", self.required_blueprint);

    self:RegisterHandler( event_sink, "EntityKilledEvent", "OnEntityKilledEvent" )

    self:UpdateProgress( 0 )
end

function kill_unit:OnEntityKilledEventEvent( evt )
    if self.required_blueprint == evt:GetBlueprint() then
        self:UpdateProgress( self.progress_current + 1)
    end
end

return kill_unit