-- no namespace definition required
-- patches error thrown by this mission when the issuing entity is nil
stashedFirstPhaseBeginServer = mission.phases[1].onBeginServer
mission.phases[1].onBeginServer = function()
    if Entity(mission.data.giver.id) == nil then
        eprint("rglx_patch_investigatemissingfreighters: " .. player.name .. " (#" .. player.index .. ") has a broken mission, issuing entity is falsey. terminating mission!")
        abortMissionGiverIsGone() -- use the function boxelware included instead of just calling terminate() since that's what that's doing anyway...
    end
    stashedFirstPhaseBeginServer()
end