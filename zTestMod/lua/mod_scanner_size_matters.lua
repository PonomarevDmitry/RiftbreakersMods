mod_scanner_size_matters = 1

function ScannerSizeMattersGetScansCount( entity )

    local scansCount = 1

    local size = EntityService:GetBoundsSize( entity )

    if ( size.x <= 2.5 ) then
        scansCount = 2
    elseif ( size.x <= 4.5 ) then
        scansCount = 4
    elseif ( size.x <= 9.5 ) then
        scansCount = 8
    else
        scansCount = 20
    end

    return scansCount
end