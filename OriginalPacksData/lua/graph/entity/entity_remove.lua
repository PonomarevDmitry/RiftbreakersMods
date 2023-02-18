class 'entity_remove' ( LuaGraphNode )

function entity_remove:__init()
    LuaGraphNode.__init(self, self)
end

function entity_remove:init()
end

function entity_remove:Activated()		
	local targetName = ""
	local targetGroup = ""
	local targetType = ""
	local targetBlueprint = ""
	self.dissolveState = self.data:GetStringOrDefault("dissolve_state", "false")
	self.dissolveDuration = self.data:GetFloatOrDefault("dissolve_duration", 1 )
	
	--local objectId = FindService:FindEntityByGroup( "grupowe_budynki" )	
	--local objectId = FindService:FindEntityByName( "super_budynek" )
	--local targetType = self.data:GetString("target_type")	
	--local objectId = FindService:FindEntityByType( targetType )
	--LogService:Log(tostring(objectId))
	--CameraService:FollowEntity( objectId )
	--EntityService:RemoveEntity( objectId )
	
	--if self.data:HasString( "target_name" ) then
		targetName = self.data:GetString("target_name")	
		--LogService:Log(targetName)
		if targetName ~= "" then			
			local objectId = FindService:FindEntitiesByName( targetName )		
			for i = 1, #objectId do				
				--LogService:Log("Removing entiy with name " .. targetName .. " entityID " .. tostring(objectId))
				self:RemoveEntity( objectId[i] )								
			end
			self:SetFinished()
			return
		end
	--elseif self.data:HasString( "target_group" ) then
		targetGroup = self.data:GetString("target_group")	
		if targetGroup ~= "" then
			local objectId = FindService:FindEntitiesByGroup( targetGroup )		
			if #objectId > 0 then								
				for i = 1, #objectId do				
					self:RemoveEntity( objectId[i] )								
				end
			end				
			self:SetFinished()
			return
		end
	--elseif self.data:HasString( "target_type" ) then
		targetType = self.data:GetString("target_type")	
		if targetType ~= "" then
			local objectId = FindService:FindEntitiesByType( targetType )		
			if #objectId > 0 then								
				for i = 1, #objectId do				
					self:RemoveEntity( objectId[i] )								
				end
			end				
			self:SetFinished()
			return
		end
	--elseif self.data:HasString( "target_blueprint" ) then
		targetBlueprint = self.data:GetString("target_blueprint")	
		if targetBlueprint ~= "" then
			local objectId = FindService:FindEntitiesByBlueprint( targetBlueprint )		
			if #objectId > 0 then								
				for i = 1, #objectId do				
					self:RemoveEntity( objectId[i] )								
				end
			end				
			self:SetFinished()
			return
		end
	--end	
	
end

function entity_remove:RemoveEntity( entityId )
	--LogService:Log("Hello from Remove Entity")
	if self.dissolveState == "true" then
		--LogService:Log("Remove Entity with dissolve")
		EntityService:DissolveEntity( entityId, self.dissolveDuration )
	else
		--LogService:Log("Remove Entity without dissolve")
		EntityService:RemoveEntity( entityId )
	end
end

return entity_remove