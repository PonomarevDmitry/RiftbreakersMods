local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")
require("lua/utils/database_utils.lua")

class 'activate_all_bioanomalies' ( item )

function activate_all_bioanomalies:__init()
    item.__init(self,self)
end

function activate_all_bioanomalies:OnEquipped()
    self.duration = 0.0
end

function activate_all_bioanomalies:OnActivate()

    self.duration = self.duration or 0.0



    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    self.activateAfter = database:GetFloat("activate_after")

    if ( 0 <= self.duration and self.duration <= self.activateAfter ) then

        if ( self.timer == nil ) then

            self.penaltySpeedOwner = self.owner

            QueueEvent( "AddMaxSpeedModifierRequest", self.penaltySpeedOwner, "activate_all_bioanomalies_penalty", 0 )

            self.timer = BuildingService:CreateGuiTimer( self.owner, self.activateAfter )
        else

            BuildingService:SetGuiTimer( self.timer, self.duration )
        end

    elseif ( self.activateAfter < self.duration ) then

        if ( self.timer ~= nil ) then

            self:DestroyTimer()

            local activatedEntities = {}

            local entities = FindService:FindEntitiesByGroup( "loot_container" )

            for entity in Iter( entities ) do

                if ( entity == nil ) then
                    goto continue
                end

                if ( not EntityService:IsAlive( entity ) ) then
                    goto continue
                end

                if ( IndexOf( activatedEntities, entity ) ~= nil ) then
                    goto continue
                end

                local idComponentName = EntityService:GetName( entity )

                -- Ignore Into Dark Anomaly to do not create a soft lock. 
                if ( idComponentName == "dlc_2_anomaly" ) then
                    goto continue
                end

                local interactiveComponent = EntityService:GetConstComponent( entity, "InteractiveComponent" )
                if ( interactiveComponent == nil ) then
                    goto continue
                end

                local interactiveComponentRef = reflection_helper( interactiveComponent )
                if ( interactiveComponentRef.slot ~= "HARVESTER" ) then
                    goto continue
                end

                local minimapItemComponent = EntityService:GetComponent( entity, "MinimapItemComponent" )
                if ( minimapItemComponent ~= nil ) then
                    local minimapItemComponentRef = reflection_helper( minimapItemComponent )
                    minimapItemComponentRef.unknown_until_visible = false
                end

                local databaseEntity = EntityService:GetDatabase( entity )
                if ( databaseEntity ~= nil ) then
                    databaseEntity:SetFloat( "harvest_duration", 2.5 )
                end

                QueueEvent( "HarvestStartEvent", entity )

                EntityService:SpawnEntity( "items/consumables/radar_pulse", entity, "" )

                Insert( activatedEntities, entity )

                ::continue::
            end

            if ( self.owner ~= nil and self.owner ~= INVALID_ID ) then

                EffectService:SpawnEffect( self.owner, "effects/enemies_generic/wave_start" )

                local lootContainerDelayer = EntityService:SpawnEntity( "props/special/loot_containers/loot_container_delayer", self.owner, "" )

                local dbLootContainerDelayer = EntityService:GetDatabase( lootContainerDelayer )
                dbLootContainerDelayer:SetFloat( "delay", 0.2 )
                dbLootContainerDelayer:SetFloat( "aggressive_radius", 100 )
            end
        end
    end

    self.duration = self.duration + 1.0 / 30.0
end

function activate_all_bioanomalies:DestroyTimer()

    if ( self.timer ~= nil ) then

        EntityService:RemoveEntity( self.timer )
        self.timer = nil

        if ( self.penaltySpeedOwner ~= nil ) then

            QueueEvent( "RemoveMaxSpeedModifierRequest", self.penaltySpeedOwner, "activate_all_bioanomalies_penalty" )
        end
    end
end

function activate_all_bioanomalies:OnDeactivate()

    self:DestroyTimer()

    self.duration = 0.0

    return true
end

function activate_all_bioanomalies:OnUnequipped()

    self:DestroyTimer()

    if ( item.OnUnequipped ) then
        item.OnUnequipped( self )
    end
end

return activate_all_bioanomalies