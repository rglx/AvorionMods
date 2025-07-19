-- namespace rglxServerLibSeparatedChatLog
rglxServerLibSeparatedChatLog = {}
local self = rglxServerLibSeparatedChatLog

-- rglx's separated chatlog server mod
-- copies all chatlogs to a separate file, with some additional channel information applied as well.
-- technically this script only needs access to Server() and to set callbacks, but for cleanliness's sake we're attaching at the galaxy level instead.



if onServer() then

	-- http://lua-users.org/wiki/StringRecipes
	local function starts_with(str, start)
		return str:sub(1, #start) == start
	end

	local function ends_with(str, ending)
		return ending == "" or str:sub(-#ending) == ending
	end
	-- doesn't need to be running on the client

	function rglxServerLibSeparatedChatLog.initialize()
		local server = Server()
		local galaxy = Galaxy()
		-- register the three callbacks we need
		server:registerCallback("onChatMessage", "onChatMessage")
		server:registerCallback("onPlayerLogIn", "onPlayerLogIn")
		server:registerCallback("onPlayerLogOff", "onPlayerLogOff")
		galaxy:registerCallback("onPlayerCreated", "onPlayerCreated")
		-- header for this server's session
		rglxServerLibSeparatedChatLog.writeTextToFile("<Server>\t-1\t[Server]\tChat logging begun.")
	end

	-- shim functions so we can standardize log output easier
	function rglxServerLibSeparatedChatLog.onPlayerLogIn(playerIndex)
		rglxServerLibSeparatedChatLog.onChatMessage(playerIndex,true,4)
	end

	function rglxServerLibSeparatedChatLog.onPlayerLogOff(playerIndex)
		rglxServerLibSeparatedChatLog.onChatMessage(playerIndex,false,4)
	end

	function rglxServerLibSeparatedChatLog.onPlayerCreated(playerIndex)
		rglxServerLibSeparatedChatLog.onChatMessage(playerIndex,false,5)
	end

	function rglxServerLibSeparatedChatLog.onChatMessage(playerIndex, text, channel)
		-- index and text are self explanatory
		-- channel can be: 0 = galaxywide, 1 = sectorwide, 2 = that player's group, or 3 = that player's alliance
		local player = Player(playerIndex) -- get our player object
		local channelString = false

		if player == nil then
			eprint("rglx_ServerLib_SeparatedChatLog: received an invalid player index for a message")
			return
		end

		-- determine where our message is going and grab some more information if needed
		if channel == 0 then
			-- galaxywide chat
			channelString = "Galaxy"
		elseif channel == 1 then
			-- sector-wide chat, we'll need the coordinates
			coordinatesX, coordinatesY = player:getSectorCoordinates()
			channelString = "Sector(".. coordinatesX .. ":" .. coordinatesY .. ")"
		elseif channel == 2 then
			-- grouped chat, if someone wants to investigate closer they can use a player group info fetcher like the one in the commands pack
			-- players can still try to message groups but not actually get anywhere
			channelString = "Group"
		elseif channel == 3 then
			-- alliance chat, which we should denote in the log.
			if player.allianceIndex == nil then
				-- players can still try to message alliances without being in them, and the server will tell them otherwise for it
				channelString = "Alliance"
			else
				channelString = "Alliance(" .. player.allianceIndex .. ")"
			end
		elseif channel == 4 then
			channelString = "LogInOut"
			-- login/out message. shim functions specify true or false for whichever direction
			if text == true then
				text = "Joined the galaxy."
			else
				text = "Left the galaxy."
			end
		elseif channel == 5 then
			channelString = "Create"
			text = "created!"
		else
			eprint("rglx_ServerLib_SeparatedChatLog: got a message with a bad channel number")
			return
		end

		-- something tells me it's not exactly intentional but a command is reported as a chat message to the server
		-- additionally commands can be run in the context of other "channels" for some reason, so if you've switched to alliance chat and you run a command, technically the command that's sent to the server is sent in the context of your alliance chat.
		if starts_with(text,"/") then
			-- someone attempting to run a command
			if starts_with(text,"/w ") or starts_with(text,"/whisper ") then
				-- someone whispering someone else
				-- confusing output but i don't want to bother writing a regexp for capturing quoted text to put the whisper target in a different line.
				channelString = "Whisper"
			else
				channelString = "Command"
				-- categorize commands someplace else
			end
		end

		-- don't need to include a timestamp, the logwriter does that for us
		-- we also want to clean up whitespace here, since the game isn't filtering certain kinds of linebreaks and whitespace, but is just rendering it badly
		local outputMessage = "<" .. player.name .. ">\t" .. playerIndex .. "\t[" .. channelString .. "]\t" .. text:gsub("%s+"," ")

		-- and write out
		rglxServerLibSeparatedChatLog.writeTextToFile(outputMessage)


	end

	function rglxServerLibSeparatedChatLog.writeTextToFile(message)
		local server = Server()
		local logFileHandle = io.open(server.folder .. "/" .. "serverlog chat-all.log","a+")
		if logFileHandle ~= nil then
			local nowAppTime = appTime() -- provided by avorion scripting API, and completely overlooked most of the time
			nowAppTime = (nowAppTime - math.floor(nowAppTime)) * 1000000 -- Get appTime and convert to microseconds
			logFileHandle:write(os.date("%Y-%m-%d %X.") .. string.format("%06d", nowAppTime) .. "\t" .. message .. "\n")
			io.close(logFileHandle)
		else
			eprint("rglx_ServerLib_SeparatedChatLog: ERROR! could not open log file for writing.")
		end
	end

else
	print("rglx_ServerLib_SeparatedChatLog: dont load this on your client- its for servers only.")
end