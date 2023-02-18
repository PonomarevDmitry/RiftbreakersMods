class 'wait_for_rift_activation' ( LuaGraphNode )

function wait_for_rift_activation:__init()
    LuaGraphNode.__init(self, self)
end

function wait_for_rift_activation:Update()
	local chargingState = _G["rift_station_charging_state"] or 0
	if chargingState > 0 then
		local waitOnActivation = self.data:GetIntOrDefault("activated", 0)
		if (  waitOnActivation > 0 and chargingState ~= 2 ) then
			return
		end
		self:SetFinished()
	end
end

return wait_for_rift_activation