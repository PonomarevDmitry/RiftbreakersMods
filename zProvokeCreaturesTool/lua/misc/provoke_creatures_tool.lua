local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'provoke_creatures_tool' ( tool )

function provoke_creatures_tool:__init()
    tool.__init(self,self)
end

function provoke_creatures_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_provoke_creatures_tool", self.entity)

    self.scaleMap = {
        1,
    }

    self.currentValue = 100
    self.stepValue = 5

    self.configName = "$provoke_creatures_tool_config"

    local selectorDB = EntityService:GetDatabase( self.selector )
    if ( selectorDB ) then
        self.currentValue = selectorDB:GetIntOrDefault(self.configName, self.currentValue)
    end

    self:UpdateMarker()
end

function provoke_creatures_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function provoke_creatures_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function provoke_creatures_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function provoke_creatures_tool:AddedToSelection( entity )
end

function provoke_creatures_tool:RemovedFromSelection( entity )
end

function provoke_creatures_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -change
    end

    local delta = change * self.stepValue

    local newValue = self.currentValue + delta

    if( newValue <= self.stepValue ) then
        newValue = self.stepValue
    end

    self.currentValue = newValue

    local selectorDB = EntityService:GetDatabase( self.selector )
    if ( selectorDB ) then
        selectorDB:SetInt(self.configName, newValue)
    end

    self:UpdateMarker()
end

function provoke_creatures_tool:UpdateMarker()    

    local markerDB = EntityService:GetDatabase( self.childEntity )
    if ( markerDB == nil ) then
        return
    end

    markerDB:SetString("message_text", tostring(self.currentValue))
    markerDB:SetInt("message_visible", 1)
end

function provoke_creatures_tool:OnActivateSelectorRequest()

    EffectService:SpawnEffect( self.entity, "effects/enemies_generic/wave_start" )

    EntityService:ChangeAIGroupsToAggressive( self.entity, self.currentValue, false )
end

return provoke_creatures_tool
