class 'entity_immortal' ( LuaGraphNodeSelector )
require("lua/utils/find_utils.lua")

function entity_immortal:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function entity_immortal:init()	
end

function entity_immortal:Activated()
    self.nodeEnabled = true    
   
    self.searchRadius = self.data:GetFloat("search_radius")
    self.searchTarget = self.data:GetString("search_target")
    
	self.state = self.data:GetString("state")
	if self.state == "true" then
		self.state = true
	elseif self.state == "false" then
		self.state = false
	else
		Assert( false, "ERROR: Unknown Immortality State - skipping logic block" )
		self:SetFinished()
		return
	end
    
    if self.searchTarget ~= "" then
        self.searchTarget = FindService:FindEntityByName( self.searchTarget )
    end
    
    self.targetName = ""
    self.targetGroup = ""
    self.targetType = ""
    self.targetBlueprint = ""    
    if self.data:HasString( "target_name" ) then
        self.targetName = self.data:GetString("target_name")
    end
    if self.data:HasString( "target_group" ) then
        self.targetGroup = self.data:GetString("target_group")
    end
    if self.data:HasString( "target_type" ) then
        self.targetType = self.data:GetString("target_type")
    end
    if self.data:HasString( "target_blueprint" ) then
        self.targetBlueprint = self.data:GetString("target_blueprint")
    end        
    
   -- LogService:Log("comparison_type " ..    self.data:GetString("comparison_type") );
    --LogService:Log("count " ..              tostring(self.data:GetInt("count"))    );
    --LogService:Log("search_radius " ..      tostring(self.data:GetFloat("search_radius")) );
    --LogService:Log("wait_until_dead " ..    self.data:GetString("wait_until_dead") );
    --LogService:Log("search_target " ..      self.data:GetString("search_target") );
    --LogService:Log("target_name " ..        self.data:GetString("target_name") );
    --LogService:Log("target_group " ..       self.data:GetString("target_group") );
    --LogService:Log("target_type " ..        self.data:GetString("target_type") );
    --LogService:Log("target_blueprint " ..   self.data:GetString("target_blueprint") );
	
	self.entities = self:Find()	
	
	for entity in Iter(self.entities) do
		HealthService:SetImmortality( entity, self.state )
	end	
	
	self:SetFinished("true")
end

function entity_immortal:Find()    
    -- Search anywhere on the map
    if self.searchRadius == 0 then
        if self.targetName ~= "" then        
            return { FindService:FindEntityByName( self.targetName ) }
        elseif self.targetGroup ~= "" then        
            return FindService:FindEntitiesByGroup( self.targetGroup )
        elseif self.targetType ~= "" then        
            return FindService:FindEntitiesByType( self.targetType )    
        elseif self.targetBlueprint ~= "" then
            return FindService:FindEntitiesByBlueprint( self.targetBlueprint )
        end
    -- Search in radius
    else 
        if self.targetName ~= "" then        
            return { FindService:FindEntityByNameInDistance( self.searchTarget, self.targetName, self.searchRadius ) }
        elseif self.targetGroup ~= "" then        
            return FindService:FindEntitiesByGroupInRadius( self.searchTarget, self.targetGroup, self.searchRadius )            
        elseif self.targetType ~= "" then                
            return FindService:FindEntitiesByTypeInRadius( self.searchTarget, self.targetType, self.searchRadius )            
        elseif self.targetBlueprint ~= "" then
            return FindService:FindEntitiesByBlueprintInRadius( self.searchTarget, self.targetBlueprint, self.searchRadius )            
        end
    end

    return INVALID_ID;
end

function entity_immortal:OnDisablenodes( event )
    self.nodeEnabled = false
end

function entity_immortal:OnDisableNamednode( event )
    if self.data:GetString( "self_id" ) == event:GetObject() then
        self.nodeEnabled = false
    end
end

return entity_immortal