-- rglx's tweak to require a certain percentage of online players for behemoth events to spawn

BehemothEvent.requiredPlayersInPercentage = 0.1 -- require 0.1% of your server's player slots to be occupied
-- obviously you should write a non-workshop serverside mod that changes this value to your liking
-- with this default value it should allow the behemoths to spawn if you have one player connected and one thousand playerslots (which is completely infeasible with the current understanding of computing and how horrifically inefficient the server runs)

-- namespace BehemothEvent
BehemothEvent.BehemothsPlayerRequirement_stashed_update = BehemothEvent.update -- stash existing function
function BehemothEvent.update(timeStep)
	local server = Server()

	-- before we do anything, we need to ensure the following:
	-- A) a behemoth isn't spawned somewhere already
	-- B) a behemoth WILL spawn with this occurence of the command
	-- C) the galaxy is old enough for a behemoth to exist (two hours, at the least)
	-- D) finally, we need to make sure we don't have any behemoths already present
	-- once those conditions are met, we can prevent the spawning of the behemoth for this tick, and reset the timer
	-- we also need to be sure that we're doing this transparently to prevent other mods from being affected by our changes.

	local timerTest = nil
	if server.runtime >= 2 * 60 * 60 then
		-- we want to *copy* it here, not directly modify the value, otherwise when the original update function runs we'll get two operations done on the timer which is not good.
		timerTest = data.countDown - timeStep
	end

	if timerTest >= 0 then -- our test on the timer is less than zero, either a behemoth will spawn, or will de-spawn
		if data.currentlyAttackedSector == nil then
			-- a sector is not under attack. that means, this tick, a behemoth will be spawning. that is, if we don't interfere.
			-- so let's go ahead and interfere: check player count
			local occupiedPlayerslotsPercentage = server.players / ( server.maxPlayers * 100 ) -- calculate currently occupied player slotcount percentage
			if occupiedPlayerslotsPercentage < BehemothEvent.requiredPlayersInPercentage then
				--print("rglx_ServerLib_BehemothsPlayerRequirement: required playercount not met, pre-empting Behemoth spawn...")
				-- we don't have enough players online for the event to spawn
				-- let's reset the timer back to the two hour interval
				data.countDown = ( 2 * 60 * 60 ) + timeStep -- two hours, in seconds, plus the time step that gets subtracted
				-- then continue and allow the original script's code to run
				-- that way we're not interfering with anything
			--else
				--print("rglx_ServerLib_BehemothsPlayerRequirement: required playercount is being met, allowing Behemoth spawn")
			end
		end
	end

	-- run original code, if we got this far without interference
	BehemothEvent.BehemothsPlayerRequirement_stashed_update(timeStep)
end

print("rglx_ServerLib_BehemothsPlayerRequirement: now requiring a playercount of " .. BehemothEvent.requiredPlayersInPercentage .. "% of " .. Server().maxPlayers .. " for Behemoths to spawn.")