local ok, ep = pcall( require, "lua/entity_patcher.lua" )

local pipes_radius_autoexec = function( evt )
    if not ok then
        LogService:Log( "Fail to load module [lua/entity_patcher.lua] --> [pipe_junction ++]" )
        ConsoleService:Write( "Fail to load module [lua/entity_patcher.lua] --> [pipe_junction ++]" )
        return
    end

    ep.mod_name = "[pipe junction ++]"
    if ExecuteOnceGuard( ep.mod_name ) then
        return
    end

    local PipelineRadius = function( radius )
        return {
            radius_name = "pipeline",
            min_radius = radius or 0,
            min_radius_effect = "voice_over/announcement/building_too_close"
        }
    end

    local patch = {
        {
            name = "buildings/resources/pipe_connector_t",
            data = {
                BuildingDesc = PipelineRadius()
            }
        },
        {
            name = "buildings/resources/pipe_connector_x",
            data = {
                BuildingDesc = PipelineRadius()
            }
        },
        {
            name = "buildings/resources/pipe_corner",
            data = {
                BuildingDesc = PipelineRadius()

            }
        },
        {
            name = "buildings/resources/pipe_ground",
            data = {
                BuildingDesc = PipelineRadius()
            }
        },
        {
            name = "buildings/resources/pipe_straight",
            data = {
                BuildingDesc = PipelineRadius()
            }
        },
        {
            name = "buildings/resources/pipe_straight_windowless",
            data = {
                BuildingDesc = PipelineRadius()
            }
        },
        {
            name = "buildings/resources/pipe_junction_second",
            data = {
                GridCullerComponent = {
                    Shapes = {
                        Box = {
                            ep.t:BoxShape( 6, 2, 2 )
                        }
                    }
                }
            }
        },
        {
            name = "buildings/resources/pipe_junction",
            data = {
                GridCullerComponent = {
                    Shapes = {
                        Box = {
                            ep.t:BoxShape( 2, 2, 6 )
                        }
                    }
                },
                BuildingDesc = PipelineRadius( 4 )
            }
        }
    }
    ep:ApplyOrdered( patch )
end

pipes_radius_autoexec()
