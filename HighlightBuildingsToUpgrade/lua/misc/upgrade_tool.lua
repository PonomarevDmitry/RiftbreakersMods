local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'upgrade_tool' ( tool )

function upgrade_tool:__init()
    tool.__init(self,self)
end

function upgrade_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_upgrade", self.entity)
    self.popupShown = false
    self.timeoutTime = nil

    -- List of buildings highlighted for upgrade
    self.previousMarkedBuildings = {}
    -- Radius from player to highlight buildings for upgrade
    self.radiusShowBuildingsToUpgrade = 100.0

    self.currentTick = 0
    self.tickMod = 5
end

function upgrade_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function upgrade_tool:AddedToSelection( entity )

end

function upgrade_tool:FilterSelectedEntities( selectedEntities ) 

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local buildingComponent = EntityService:GetComponent(entity, "BuildingComponent")
        if ( buildingComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode == BM_COMPLETED ) then
            Insert(entities, entity)
        end

        ::continue::
    end

    return entities
end

function upgrade_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function upgrade_tool:OnUpdate()

    self:HighlightBuildingsToUpgrade()

    self.upgradeCosts = {}

    local upgradeCostsEntities = {}

    for entity in Iter( self.selectedEntities ) do

        if ( upgradeCostsEntities[entity] == nil ) then

            upgradeCostsEntities[entity] = true

            if ( BuildingService:CanUpgrade( entity, self.playerId ) ) then

                self:SetEntitySelectedMaterial( entity, "hologram/pass" )

            else

                self:SetEntitySelectedMaterial( entity, "hologram/deny" )
            end

            local list = BuildingService:GetUpgradeCosts( entity, self.playerId )
            for resourceCost in Iter(list) do

                if ( self.upgradeCosts[resourceCost.first] == nil ) then
                   self.upgradeCosts[resourceCost.first] = 0
                end

                self.upgradeCosts[resourceCost.first] = self.upgradeCosts[resourceCost.first] + resourceCost.second
            end
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )
    if ( onScreen ) then
        BuildingService:OperateUpgradeCosts( self.infoChild, self.playerId, self.upgradeCosts )
        BuildingService:OperateUpgradeCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateUpgradeCosts( self.infoChild, self.playerId, {} )
        BuildingService:OperateUpgradeCosts( self.corners, self.playerId, self.upgradeCosts )
    end
end

function upgrade_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function upgrade_tool:HighlightBuildingsToUpgrade()

    local performFind = (self.currentTick % self.tickMod) == 0

    if ( performFind ) then

        self.currentTick = 0
    end

    self.currentTick = self.currentTick + 1

    if ( not performFind ) then

        return
    end

    -- Buildings within a radius radiusShowBuildingsToUpgrade from player to highlight
    local buildings = self:FindUpgradableBuildings()

    self.previousMarkedBuildings = self.previousMarkedBuildings or {}

    -- Remove highlighting from previous buildings
    for entity in Iter( self.previousMarkedBuildings ) do

        -- If the building is not included in the new list
        if ( IndexOf( buildings, entity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, entity ) ~= nil ) then
            goto continue
        end

        self:RemovedFromSelection( entity )

        ::continue::
    end

    for entity in Iter( buildings ) do

        -- Skip buildins from self.selectedEntities
        if ( IndexOf( self.selectedEntities, entity ) == nil ) then

            -- Highlight building if it can be upgraded
            self:SetEntitySelectedMaterial( entity, "hologram/active" )
        end
    end

    self.previousMarkedBuildings = buildings
end

function upgrade_tool:FindUpgradableBuildings()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    -- Buildings within a radius radiusShowBuildingsToUpgrade from player to highlight
    local buildings = FindService:FindEntitiesByTypeInRadius( player, "building", self.radiusShowBuildingsToUpgrade )

    local result = {}
    local hashResult = {}

    for entity in Iter( buildings ) do

        -- Skip buildins from result
        if ( hashResult[entity] == true ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent(entity, "BuildingComponent")
        if ( buildingComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode ~= BM_COMPLETED ) then
            goto continue
        end

        -- Highlight building if it can be upgraded
        if ( not BuildingService:CanUpgrade( entity, self.playerId ) ) then
            goto continue
        end

        Insert( result, entity )
        hashResult[entity] = true

        ::continue::
    end

    return result
end

function upgrade_tool:OnRotate()
end

function upgrade_tool:OnActivateEntity( entity )

    if ( not BuildingService:CanUpgrade( entity, self.playerId ) ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )
    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

    if ( buildingDesc and reflection_helper(buildingDesc).limit_name == "hq" ) then

        if ( CampaignService:GetCurrentCampaignType() == "story" ) then

            if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
                return
            end

            if( self.popupShown == false ) then

                GuiService:OpenPopup(entity, "gui/popup/popup_ingame_2buttons", "gui/hud/tutorial/hq_upgrade_confirm")
                self.popupShown = true
                self:RegisterHandler(entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")
            end
        else
            QueueEvent("UpgradeBuildingRequest", entity, self.playerId )
        end
        
    else
        QueueEvent( "UpgradeBuildingRequest", entity, self.playerId )
    end
end

function upgrade_tool:OnGuiPopupResultEvent( evt )

    local cooldown = 1

    self.timeoutTime = GetLogicTime() + cooldown

    if ( evt:GetResult() == "button_yes" ) then
        QueueEvent( "UpgradeBuildingRequest", evt:GetEntity(), self.playerId )
    end

    self:UnregisterHandler( evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent" )
    self.popupShown = false
end

function upgrade_tool:OnRelease()

    -- Remove highlighting from buildings
    if ( self.previousMarkedBuildings ~= nil ) then
        for ent in Iter( self.previousMarkedBuildings ) do

            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedBuildings = {}

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return upgrade_tool