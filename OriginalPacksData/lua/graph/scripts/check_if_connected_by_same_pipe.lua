class 'check_if_connected_by_same_pipe' ( LuaGraphNode )
require("lua/utils/string_utils.lua")
require("lua/utils/find_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/enumerables.lua")

function check_if_connected_by_same_pipe:__init()
    LuaGraphNode.__init(self, self)
end

function check_if_connected_by_same_pipe:init()
    self.sm = self:CreateStateMachine()
	self.sm:AddState( "execute", { from="*", execute="OnExecute" } )
end

function check_if_connected_by_same_pipe:Activated()
    self.sm:ChangeState( "execute")
end

function check_if_connected_by_same_pipe:OnExecute( state )
    local searchType = "Blueprint"
    local searchValue = "buildings/main/seismic_laboratory"
    local radius = 10
    local targetType = "Name"
    local spotCount = 1
    local resourceName = "water"
    local objectiveName = "anoryxian.pipeline"

    local targetValues = 
    {
        "site_A",
        "site_B",
        "site_C",
        "site_D"
    };

    objectiveName = self.parent:CreateGraphUniqueString( objectiveName )

	local objectiveID = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( objectiveName  )
	if objectiveID == INVALID_OBJECTIVE_ID and self.created == nil then
        return
    elseif objectiveID == INVALID_OBJECTIVE_ID then
        self:SetFinished()
    end
    self.created = true

    local laboratories = {}
    for site in Iter(targetValues ) do
        local entities = FindEntitiesByTarget(searchType, searchValue, 0, radius, targetType, site )
        if ( #entities ~= spotCount ) then goto continue end

        Concat(laboratories, entities )
        ::continue::
    end

    local haveAllEnts = #laboratories == (spotCount * #targetValues )

    if (haveAllEnts == true ) then
        haveAllEnts = BuildingService:IsSameConnection( laboratories, resourceName )
    end

    if ( haveAllEnts ) then
		ObjectiveService:SetObjectiveStatusByObjectiveId( objectiveID,StringToObjectiveStatus("OBJECTIVE_SUCCESS")     )
    else
		ObjectiveService:SetObjectiveStatusByObjectiveId( objectiveID,StringToObjectiveStatus("OBJECTIVE_IN_PROGRESS")     )
    end

end

return check_if_connected_by_same_pipe