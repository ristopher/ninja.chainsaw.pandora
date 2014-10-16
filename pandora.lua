scriptId = 'ninja.chainsaw.pandora'

-- Mappings
-- Fingers Spread - (spacebar) Toggle Play / Pause
-- Wave Right - (right arrow) Skip to next song
-- Wave Left - Unassigned
-- Fist (rotate right) - (up arrow) volume up
-- Fist (rotate inside) - (down arrow) volume down
-- Thumb to Pinky - Enable for commands

-- Effects

-- Variables
volumeTick = 0
volumeTickMax = 20
debugFlag = 1

function debugMsg(consoleMsg)
	if debugFlag == 1 then
		myo.debug(consoleMsg)
	end
end

function pausePlay()
    myo.keyboard("space", "press")
end

function skipSong()
    myo.keyboard("right_arrow", "press")
end

function volumeUp()
	if volumeTick < 1 then
		myo.keyboard("up_arrow", "press")
		volumeTick = volumeTickMax
	else 
		volumeTick = volumeTick - 1
	end
	debugMsg("up")
	debugMsg("volumeTick is" .. volumeTick)
	extendUnlock()
end

function volumeDown()
	if volumeTick < 1 then
		myo.keyboard("down_arrow", "press")
		volumeTick = 10
	else 
		volumeTick = volumeTick - 1
	end
	debugMsg("volumeTick is" .. volumeTick)
	debugMsg("down")
	extendUnlock()
end

-- Helpers

function conditionallySwapWave(pose)
    if myo.getArm() == "left" then
        if pose == "waveIn" then
            pose = "waveOut"
        elseif pose == "waveOut" then
            pose = "waveIn"
        end
    end
    return pose
end

-- Unlock mechanism

function unlock()
    enabled = true
    extendUnlock()
end

function extendUnlock()
    enabledSince = myo.getTimeMilliseconds()
end


-- Triggers

function onPoseEdge(pose, edge)
    if pose == "thumbToPinky" then
        -- Pitch... 0.30750495195389
        -- Yaw... 2.7852053642273
        --myo.debug("Pitch... "..currentPitch)
        --myo.debug("Yaw... "..currentYaw)
        -- myo.debug("Roll... "..currentRoll)
        if edge == "off" then
            enabled = true
            enabledSince = myo.getTimeMilliseconds()
        elseif edge == "on" and not enabled then
            -- Vibrate twice on unlock
            myo.vibrate("short")
            myo.vibrate("short")
        end
    end

    if enabled then
    --if enabled and edge == "on" then
        pose = conditionallySwapWave(pose)

        if pose == "waveOut" and edge == "on" then
            myo.vibrate("short")
            enabled = false
            skipSong()
        end
        if pose == "waveIn" and edge == "on" then
            if currentYaw > 1.5 then
               -- myo.debug('great than 1.5 '..currentYaw)
            else
                --myo.debug('less than 1.5 '..currentYaw)
            end
            --myo.vibrate("short")
            enabled = false
            --archiveConversation()
        end
        if pose == "fist" and edge == "on" then
			
			debugMsg("Pitch... "..currentPitch)
			debugMsg("Yaw... "..currentYaw)
			debugMsg("Roll... "..currentRoll)
            myo.vibrate("short")
            startRoll = currentRoll
			if currentRoll > startRoll then
				volumeDirection = "down"
			else
				volumeDirection = "up"
			end
			
			--if edge == "off" then
			--	enabled = false
			--end
			
			--enabled = false
			--extendUnlock()
            --nextOlderMessage()
        end
		
		if pose == "fist" and edge == "off" then
			volumeDirection = ""
		end
        if pose == "fingersSpread" then
           -- myo.debug("hey.. "..currentYaw)
            if edge == "off" and currentPitch < 0.1 then
                myo.vibrate("medium")
                enabled = true
                pausePlay()
            elseif edge == "off" and currentPitch > 0.2 then
                myo.vibrate("short")
                enabled = true
                pausePlay()
            end
        end
    end
end

-- All timeouts in milliseconds
ENABLED_TIMEOUT = 2200
currentYaw = 0
currentPitch = 0
currentRoll = 0

function onPeriodic()
    currentYaw = myo.getYaw()
    currentPitch = myo.getPitch()
    currentRoll = myo.getRoll()
	
	--myo.debug("Pitch... "..currentPitch)
    --myo.debug("Yaw... "..currentYaw)
    --myo.debug("Roll... "..currentRoll)
        
	
	local now = myo.getTimeMilliseconds()
    
   if enabled then

        if myo.getTimeMilliseconds() - enabledSince > ENABLED_TIMEOUT then
            enabled = false
        end
		
		if enabled == true and (volumeDirection == "up" or volumeDirection == "down") then
			--Double Check direction
			if currentRoll > startRoll then
				volumeDirection = "down"
				volumeUp()
			else
				volumeDirection = "up"
				volumeDown()
			end
		end
    end
end

function onForegroundWindowChange(app, title)
    debugMsg(title)
    local wantActive = false
    activeApp = ""
    if platform == "MacOS" then
        wantActive = string.match(title, "Pandora %- Google Chrome$") or
                     string.match(title, "^Pandora")
        activeApp = "Pandora"
    elseif platform == "Windows" then
        wantActive = string.match(title, "Pandora %- Google Chrome$") or
                     string.match(title, "^Pandora")
        activeApp = "Pandora"
    end
    return wantActive
end

function activeAppName()
    return activeApp
end

function onActiveChange(isActive)
    if not isActive then
        enabled = false
    end
end
