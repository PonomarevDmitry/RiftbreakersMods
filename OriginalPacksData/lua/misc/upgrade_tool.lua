
local tool = require("lua/misc/tool.lua")

class 'upgrade_tool' ( tool )

function upgrade_tool:__init()
    tool.__init(self,self)
end

function upgrade_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_upgrade", self.entity)
    self.popupShown = false
end

function upgrade_tool:OnPreInit()
    self.initialScale = {x=2,y=1,z=2}
end

function upgrade_tool:AddedToSelection( entity )

end
function upgrade_tool:FilterSelectedEntities( selectedEntities ) 

    local entities = {}
    for  ent in Iter(selectedEntities ) do
        local buildingComponent = EntityService:GetComponent(ent, "BuildingComponent")
        if ( buildingComponent == nil ) then goto continue end
        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode == BM_COMPLETED ) then 
            Insert(entities, ent)
        end

        ::continue::
    end

    return entities
end

function upgrade_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function upgrade_tool:OnUpdate()
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
 