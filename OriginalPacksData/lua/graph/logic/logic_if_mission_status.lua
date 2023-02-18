class 'logic_if_mission_status' ( LuaGraphNodeSelector )
require("lua/utils/enumerables.lua")

function logic_if_mission_status:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_mission_status:init()
	self.eventName = "MissionStatusChangedEvent"	
end

function logic_if_mission_status:Update()		
   
    self.waitOnStatus = self.data:GetString("wait_on_status")    
    self.missionId = self.data:GetString("mission_id")    
    self.missionExists = self.data:GetStringOrDefault("mission_exists", "true" ) == "true"
    
    self.missionStatus = nil

    if self.waitOnStatus == "true" then
		self.waitStatusName = self.data:GetString("status_name")
		self.waitStatus = StringToMissionStatus( self.waitStatusName )
		
		self.missionStatus =  CampaignService:GetMissionStatus( self.missionId, self.missionExists )
		if ( self.waitStatus == self.missionStatus ) then
			self:SetFinished( self.waitStatusName )
		end
	else 
		self.missionStatus =  CampaignService:GetMissionStatus( self.missionId, self.missionExists )
		
		if self.missionStatus == MISSION_STATUS_WIN then
			self:SetFinished("win")
		elseif self.missionStatus == MISSION_STATUS_LOSE then
			self:SetFinished("lose")
		elseif self.missionStatus == MISSION_STATUS_IN_PROGRESS then
			self:SetFinished("in_progress")
		elseif self.missionStatus == MISSION_STATUS_NONE then
			self:SetFinished("none")
		else
			Assert( false, "Mission status corrupted " .. tostring(self.missionStatus ) )			
		end
	end
end

function logic_if_mission_status:OnMissionStatusChangedEvent( event )
end

function logic_if_mission_status:Deactivated()
	if self.waitOnStatus == "true" then
		self:UnregisterHandlers()
	end
end


return logic_if_mission_status