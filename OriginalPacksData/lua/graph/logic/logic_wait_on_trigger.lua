require("lua/utils/string_utils.lua")
require("lua/utils/data_flow.lua")

class 'logic_wait_on_trigger' ( LuaGraphNode )

function logic_wait_on_trigger:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_on_trigger:init()
    self.triggers = {}
end

function logic_wait_on_trigger:OnLoad()
    if self.triggerEntity and ( not self.triggers or #self.triggers == 0 ) then
        self.triggers = { self.triggerEntity }
    end
end

function logic_wait_on_trigger:Activated()
	local triggerName = self.data:GetStringOrDefault("trigger_name", "")	
	if self.data:HasString("in_entities") then
        self.entities = GetEntitiesFromString( self.data:GetString("in_entities") )
    else
		self.entities = FindService:FindEntitiesByName(triggerName)
	end
	
	if Assert( #self.entities > 0, "ERROR: entity with name: `" .. triggerName .. "` not found!" ) then
		self.filterTeam = self.data:GetStringOrDefault( "filter_team", ""  )
		self.filterType = self.data:GetStringOrDefault( "filter_type", "" )
		self.filterBlueprint = self.data:GetStringOrDefault( "filter_blueprint", "" )
	
		for entity in Iter(self.entities) do
			self:RegisterHandler( entity, "EnteredTriggerEvent", "OnEnteredTriggerEvent" );
		end
	
		self.triggers = self.entities;
	end	
end

function logic_wait_on_trigger:Deactivated()
    for entity in Iter(self.triggers) do
        self:UnregisterHandler( entity, "EnteredTriggerEvent", "OnEnteredTriggerEvent"  );
    end
end

function logic_wait_on_trigger:OnEnteredTriggerEvent( evt )
    local entity = evt:GetOtherEntity()
	--LogService:Log("TRIGGER BLUEPRINT CHECK " .. EntityService:GetBlueprintName( entity ))
	--LogService:Log("TRIGGER BLUEPRINT FILTER " .. self.filterBlueprint)

    -- filter entities by TEAM
    if not IsNullOrEmpty( self.filterTeam ) then

        if not EntityService:CompareTeam( entity, self.filterTeam ) then
            return
        end
    end

    -- filter entities by TYPE
    if not IsNullOrEmpty( self.filterType ) then
        if not EntityService:CompareType( entity, self.filterType ) then
            return
        end
    end
	
	 -- filter entities by BLUEPRINT - including inheritance
    if not IsNullOrEmpty( self.filterBlueprint ) then
        if not EntityService:IsDerivedFromBlueprint( entity, self.filterBlueprint ) then			
            return
        end
    end

    self:SetFinished()
end

return logic_wait_on_trigger