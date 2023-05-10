local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'upgrade_tool' ( tool )

function upgrade_tool:__init()
    tool.__init(self,self)
end

function upgrade_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_upgrade", self.entity)
    self.popupShown = false
    
    -- List of buildings highlighted for upgrade
    self.previousMarkedBuildings = {}
    -- Radius from player to highlight buildings for upgrade
    self.radiusShowBuildingsToUpgrade = 100.0
end

function upgrade_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function upgrade_tool:AddedToSelection( entity )

end

function upgrade_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function upgrade_tool:OnRelease()
    tool.OnRelease(self)
    
    -- Remove highlighting from buildings
    if ( self.previousMarkedBuildings ~= nil) then
        for ent in Iter( self.previousMarkedBuildings ) do
        
            self:RemovedFromSelection( ent )
        end
    end
    
    self.previousMarkedBuildings = {}
end

function upgrade_tool:OnUpdate()
    
    -- Buildings within a radius radiusShowBuildingsToUpgrade from player to highlight
    local buildings = self:FindUpgradableBuildings()
    
    if ( self.previousMarkedBuildings == nil) then    
        self.previousMarkedBuildings = {}
    end
    
    -- Remove highlighting from previous buildings    
    for ent in Iter( self.previousMarkedBuildings ) do
    
        -- If the building is not included in the new list
        if ( IndexOf( buildings, ent ) == nil ) then
            self:RemovedFromSelection( ent )
        end
    end
    
    for entity in Iter( buildings ) do
        
        -- Highlight building if it can be upgraded
        local skinned = EntityService:IsSkinned(entity)
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_active", "selected")
        end 
    end
    
    self.previousMarkedBuildings = buildings
    
    self.repairCosts = {}
    for entity in Iter(self.selectedEntities ) do
        local skinned = EntityService:IsSkinned(entity)
        if ( BuildingService:CanUpgrade( entity, self.playerId )) then
            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
            end
        else
            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_deny", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_deny", "selected")
            end
        end
        
        local list = BuildingService:GetUpgradeCosts( entity, self.playerId )
        for resourceCost in Iter(list) do
            if ( self.repairCosts[resourceCost.first] == nil ) then
               self.repairCosts[resourceCost.first ] = resourceCost.second 
            else
               self.repairCosts[resourceCost.first ] = self.repairCosts[resourceCost.first ] + resourceCost.second 
            end
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    if ( onScreen ) then
        BuildingService:OperateUpgradeCosts( self.infoChild, self.playerId, self.repairCosts)
        BuildingService:OperateUpgradeCosts( self.corners, self.playerId, {})
    else
        BuildingService:OperateUpgradeCosts( self.infoChild , self.playerId,{})
        BuildingService:OperateUpgradeCosts( self.corners, self.playerId, self.repairCosts)
    end
end

function upgrade_tool:FindUpgradableBuildings()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)    
    
    -- Buildings within a radius radiusShowBuildingsToUpgrade from player to highlight
    local buildings = FindService:FindEntitiesByTypeInRadius( player, "building", self.radiusShowBuildingsToUpgrade )
    
    local markedAbleToUpgrade = {}
    
    for entity in Iter( buildings ) do
    
        -- Skip buildins from self.selectedEntities
        if ( IndexOf( self.selectedEntities, entity ) == nil ) then
        
            -- Highlight building if it can be upgraded
            if ( BuildingService:CanUpgrade( entity, self.playerId )) then
            
                Insert(markedAbleToUpgrade, entity )       
            end
        end       
    end
    
    return markedAbleToUpgrade    
end

function upgrade_tool:OnRotate()
end

function upgrade_tool:OnActivateEntity( entity )
    if (  not BuildingService:CanUpgrade( entity, self.playerId )) then
        return
    end
    
    local buildingName = EntityService:GetBlueprintName( entity)
    local buildingDesc = BuildingService:GetBuildingDesc(buildingName )
    if ( buildingDesc and reflection_helper(buildingDesc).limit_name == "hq" ) then
        if( self.popupShown == false ) then
            GuiService:OpenPopup(entity, "gui/popup/popup_ingame_2buttons", "gui/hud/tutorial/hq_upgrade_confirm")
            self.popupShown = true
            self:RegisterHandler(entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")
        end
    else
        QueueEvent("UpgradeBuildingRequest", entity, self.playerId )
    end
end


function upgrade_tool:OnGuiPopupResultEvent( evt)
    if ( evt:GetResult() == "button_yes" ) then
        QueueEvent("UpgradeBuildingRequest", evt:GetEntity(), self.playerId )
    end
    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    self.popupShown = false
end

return upgrade_tool
 