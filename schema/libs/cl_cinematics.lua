Schema.cinematics = ix.util.GetOrCreateCommonLibrary("cinematics", nil, {
	cinematicData = {},
	currentScene = nil
})

function Schema.cinematics.IsInScene(sceneID)
	if (not Schema.cinematics.currentScene) then
		return false
	end

	return Schema.cinematics.currentScene.uniqueID == sceneID
end

--- Draws a cinematic fade-in effect.
--- @param fadeTime? number
function Schema.cinematics.FadeIn(fadeTime)
	fadeTime = fadeTime or Schema.cinematics.CINEMATIC_FADE_TIME

	Schema.cinematics.cinematicData.fadeIn = {
		startTime = CurTime(),
		duration = fadeTime,
		active = true
	}

	Schema.cinematics.cinematicData.fadeOut = nil
end

--- Draws a cinematic fade-out effect.
--- @param fadeTime? number
--- @param callback? function
function Schema.cinematics.FadeOut(fadeTime, callback)
	fadeTime = fadeTime or Schema.cinematics.CINEMATIC_FADE_TIME

	Schema.cinematics.cinematicData.fadeOut = {
		startTime = CurTime(),
		duration = fadeTime,
		active = true,
		callback = callback
	}

	Schema.cinematics.cinematicData.fadeIn = nil
end

--- Clears all fade effects.
function Schema.cinematics.ClearFadeEffects()
	Schema.cinematics.cinematicData.fadeIn = nil
	Schema.cinematics.cinematicData.fadeOut = nil
end

--- Sets fog to display for a cinematic scene.
--- @param fogStart number
--- @param fogEnd number
--- @param color? Color
--- @param density? number
function Schema.cinematics.SetFogData(fogStart, fogEnd, color, density)
	Schema.cinematics.cinematicData.fogData = {
		fogStart = fogStart,
		fogEnd = fogEnd,
		color = color or Color(255, 255, 255),
		density = density or 0.5
	}
end

--- Clears the fog data for cinematic scenes.
function Schema.cinematics.ClearFogData()
	Schema.cinematics.cinematicData.fogData = nil
end

--- Sets the black and white effect for a cinematic scene.
--- @param enabled boolean
function Schema.cinematics.SetBlackAndWhite(enabled)
	Schema.cinematics.cinematicData.blackAndWhite = enabled
end

--- Shows cinematic text on the screen.
--- @param textData string|table<{text:string, delay:number?, duration:number?, horizontalAlignment:TEXT_ALIGN?, verticalAlignment:TEXT_ALIGN?}>
--- @param duration? number
--- @param horizontalAlignment? TEXT_ALIGN
--- @param verticalAlignment? TEXT_ALIGN
function Schema.cinematics.ShowCinematicText(textData, duration, horizontalAlignment, verticalAlignment)
	if (type(textData) == "string") then
		duration = duration or Schema.cinematics.CINEMATIC_TEXT_DURATION
		horizontalAlignment = horizontalAlignment or TEXT_ALIGN_LEFT
		verticalAlignment = verticalAlignment or TEXT_ALIGN_BOTTOM

		Schema.cinematics.cinematicData.textDisplay = {
			text = textData,
			startTime = CurTime(),
			duration = duration,
			alpha = 255,
			horizontalAlignment = horizontalAlignment,
			verticalAlignment = verticalAlignment
		}
		return
	end

	if (type(textData) == "table") then
		local processedEntries = {}
		local currentTime = 0

		for i, entry in ipairs(textData) do
			local delay = entry.delay or 0
			local text = entry.text
			local displayDuration = entry.duration or Schema.cinematics.CINEMATIC_TEXT_DURATION
			local horizontalAlignment = entry.horizontalAlignment or TEXT_ALIGN_LEFT
			local verticalAlignment = entry.verticalAlignment or TEXT_ALIGN_BOTTOM

			currentTime = currentTime + delay

			table.insert(processedEntries, {
				text = text,
				startTime = CurTime() + currentTime,
				duration = displayDuration,
				horizontalAlignment = horizontalAlignment,
				verticalAlignment = verticalAlignment,
				alpha = 255,
				index = i
			})
		end

		Schema.cinematics.cinematicData.textDisplayArray = processedEntries
		Schema.cinematics.cinematicData.textDisplay = nil
		return
	end
end

--- Plays a cinematic sound.
--- @param soundPath string
--- @param volume? number
--- @param fadeInTime? number
--- @return boolean
function Schema.cinematics.PlayCinematicSound(soundPath, volume, fadeInTime)
	volume = volume or 1.0
	fadeInTime = fadeInTime or 0

	Schema.cinematics.StopCinematicSound()

	local filter = nil
	Schema.cinematics.cinematicSound = CreateSound(game.GetWorld(), soundPath, filter)

	if not Schema.cinematics.cinematicSound then
		ErrorNoHalt("Failed to create cinematic sound: " .. soundPath)
		return false
	end

	Schema.cinematics.cinematicSound:SetSoundLevel(0)

	if fadeInTime > 0 then
		Schema.cinematics.cinematicSound:PlayEx(0, 100)
		Schema.cinematics.cinematicSound:ChangeVolume(volume, fadeInTime)
	else
		Schema.cinematics.cinematicSound:PlayEx(volume, 100)
	end

	Schema.cinematics.cinematicData.currentSound = {
		sound = Schema.cinematics.cinematicSound,
		volume = volume,
		isPlaying = true
	}

	return true
end

--- Fades the cinematic sound to a target volume, calling the callback when done.
--- @param fadeTime? number
--- @param targetVolume? number
--- @param callback? function
--- @return boolean
function Schema.cinematics.FadeCinematicSound(fadeTime, targetVolume, callback)
	if not Schema.cinematics.cinematicSound or not Schema.cinematics.cinematicData.currentSound then
		if callback then callback() end
		return false
	end

	fadeTime = fadeTime or 2.0
	targetVolume = targetVolume or 0

	Schema.cinematics.cinematicSound:ChangeVolume(targetVolume, fadeTime)

	Schema.cinematics.cinematicData.currentSound.fadeCallback = callback
	Schema.cinematics.cinematicData.currentSound.fadeEndTime = CurTime() + fadeTime
	Schema.cinematics.cinematicData.currentSound.fadeTargetVolume = targetVolume

	return true
end

--- Stops the cinematic sound.
--- @param fadeTime? number
function Schema.cinematics.StopCinematicSound(fadeTime)
	if not Schema.cinematics.cinematicSound then
		return
	end

	if fadeTime and fadeTime > 0 then
		Schema.cinematics.FadeCinematicSound(fadeTime, 0, function()
			if Schema.cinematics.cinematicSound then
				Schema.cinematics.cinematicSound:Stop()
				Schema.cinematics.cinematicSound = nil
				Schema.cinematics.cinematicData.currentSound = nil
			end
		end)
	else
		Schema.cinematics.cinematicSound:Stop()
		Schema.cinematics.cinematicSound = nil
		Schema.cinematics.cinematicData.currentSound = nil
	end
end

--- Sets the volume of the cinematic sound.
--- @param volume number
--- @return boolean
function Schema.cinematics.SetCinematicSoundVolume(volume)
	if not Schema.cinematics.cinematicSound or not Schema.cinematics.cinematicData.currentSound then
		return false
	end

	Schema.cinematics.cinematicSound:ChangeVolume(volume, 0)
	Schema.cinematics.cinematicData.currentSound.volume = volume
	return true
end

--- Checks if the cinematic sound is currently playing.
--- @return boolean
function Schema.cinematics.IsCinematicSoundPlaying()
	return Schema.cinematics.cinematicSound and Schema.cinematics.cinematicData.currentSound and
		Schema.cinematics.cinematicData.currentSound.isPlaying
end

--- Calculates the alpha value for cinematic text, used internally to control text fading.
--- @param startTime number
--- @param duration number
--- @param baseAlpha number
--- @return number
function Schema.cinematics.CalculateTextAlpha(startTime, duration, baseAlpha)
	local fadeInTime = 0.5
	local fadeOutTime = 1
	local elapsed = CurTime() - startTime
	local alpha = baseAlpha

	if (elapsed < fadeInTime) then
		alpha = alpha * (elapsed / fadeInTime)
	elseif (elapsed > duration - fadeOutTime) then
		alpha = alpha * ((duration - elapsed) / fadeOutTime)
	end

	return alpha
end

--- Calculates the vertical start position for cinematic text such that there is enough
--- room to show all text on screen if it is bottom aligned.
--- @param activeEntries table
--- @param scrH number
--- @param verticalAlignment TEXT_ALIGN
--- @return number
function Schema.cinematics.CalculateVerticalStartPosition(activeEntries, scrH, verticalAlignment)
	local lineHeight = 40
	local totalHeight = (#activeEntries) * lineHeight
	local padding = 50

	local startY

	if verticalAlignment == TEXT_ALIGN_TOP then
		startY = padding
	elseif verticalAlignment == TEXT_ALIGN_CENTER then
		startY = (scrH - totalHeight) / 2
	else
		startY = scrH - totalHeight - padding
	end

	startY = math.max(padding, startY)
	startY = math.min(scrH - totalHeight - padding, startY)

	return startY
end

--- Draws cinematic text on the screen.
--- @param text string
--- @param horizontalAlignment TEXT_ALIGN
--- @param verticalAlignment TEXT_ALIGN
--- @param alpha number
--- @param scrW number
--- @param scrH number
--- @param index number
--- @param baseY number
function Schema.cinematics.DrawCinematicText(
	text,
	horizontalAlignment,
	verticalAlignment,
	alpha,
	scrW,
	scrH,
	index,
	baseY
)
	local font = "ixBigFontOutlined"
	local lineHeight = 40
	local yOffset = (index - 1) * lineHeight

	surface.SetFont(font)

	local x, y
	local textAlign = TEXT_ALIGN_LEFT

	if horizontalAlignment == TEXT_ALIGN_CENTER then
		x = scrW * .5
		textAlign = TEXT_ALIGN_CENTER
	elseif horizontalAlignment == TEXT_ALIGN_RIGHT then
		x = scrW - 50
		textAlign = TEXT_ALIGN_RIGHT
	else
		x = 50
		textAlign = TEXT_ALIGN_LEFT
	end

	y = baseY + yOffset

	draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, alpha * 0.8), textAlign, TEXT_ALIGN_TOP)
	draw.SimpleText(text, font, x, y, Color(255, 255, 255, alpha), textAlign, TEXT_ALIGN_TOP)
end

--- Calculates bloom intensity for fading effects.
--- @param fadeType string
--- @param progress number
--- @return number
function Schema.cinematics.CalculateBloomIntensity(fadeType, progress)
	local maxBloom = 2.5
	local minBloom = 0.0

	if fadeType == "fadeIn" then
		local easedProgress = 1 - math.pow(1 - progress, 3)
		return maxBloom * (1 - easedProgress) + minBloom * easedProgress
	elseif fadeType == "fadeOut" then
		return maxBloom * progress + minBloom * (1 - progress)
	end

	return minBloom
end

--[[
	Hooks
--]]

hook.Add("RenderScreenspaceEffects", "expCinematicsRenderScreenspaceEffects", function()
	if (Schema.cinematics.cinematicData.blackAndWhite and IsValid(LocalPlayer())) then
		local tab = {}
		tab["$pp_colour_addr"] = 0
		tab["$pp_colour_addg"] = 0
		tab["$pp_colour_addb"] = 0
		tab["$pp_colour_brightness"] = 0
		tab["$pp_colour_contrast"] = 1.2
		tab["$pp_colour_colour"] = 0
		tab["$pp_colour_mulr"] = 0
		tab["$pp_colour_mulg"] = 0
		tab["$pp_colour_mulb"] = 0

		DrawColorModify(tab)
	end

	local bloomIntensity = 0
	local shouldApplyBloom = false

	if (Schema.cinematics.cinematicData.fadeIn and Schema.cinematics.cinematicData.fadeIn.active) then
		local fadeData = Schema.cinematics.cinematicData.fadeIn
		local elapsed = CurTime() - fadeData.startTime
		local progress = math.Clamp(elapsed / fadeData.duration, 0, 1)

		bloomIntensity = Schema.cinematics.CalculateBloomIntensity("fadeIn", progress)
		shouldApplyBloom = true
	end

	if (Schema.cinematics.cinematicData.fadeOut and Schema.cinematics.cinematicData.fadeOut.active) then
		local fadeData = Schema.cinematics.cinematicData.fadeOut
		local elapsed = CurTime() - fadeData.startTime
		local progress = math.Clamp(elapsed / fadeData.duration, 0, 1)

		bloomIntensity = Schema.cinematics.CalculateBloomIntensity("fadeOut", progress)
		shouldApplyBloom = true
	end

	if (shouldApplyBloom and bloomIntensity > 0) then
		local darken = math.max(0.2, 1 - (bloomIntensity * 0.4))
		local multiply = bloomIntensity
		local sizeX = math.min(8, bloomIntensity * 3)
		local sizeY = math.min(8, bloomIntensity * 3)
		local passes = math.min(3, math.ceil(bloomIntensity))
		local colorMultiply = 1

		DrawBloom(darken, multiply, sizeX, sizeY, passes, colorMultiply, 1, 1, 1)
	end
end)

hook.Add("Think", "expCinematicsThink", function()
	if (Schema.cinematics.currentScene) then
		if (Schema.cinematics.currentScene.OnThink) then
			Schema.cinematics.currentScene:OnThink()
		end
	end

	if (Schema.cinematics.cinematicData.fadeOut and Schema.cinematics.cinematicData.fadeOut.active) then
		local fadeData = Schema.cinematics.cinematicData.fadeOut
		local elapsed = CurTime() - fadeData.startTime

		if (elapsed >= fadeData.duration) then
			fadeData.active = false

			if (fadeData.callback and type(fadeData.callback) == "function") then
				fadeData.callback()
			end
		end
	end

	if (Schema.cinematics.cinematicData.fadeIn and Schema.cinematics.cinematicData.fadeIn.active) then
		local fadeData = Schema.cinematics.cinematicData.fadeIn
		local elapsed = CurTime() - fadeData.startTime

		if (elapsed >= fadeData.duration) then
			fadeData.active = false
			Schema.cinematics.cinematicData.fadeIn = nil
		end
	end

	if Schema.cinematics.cinematicData.currentSound and Schema.cinematics.cinematicData.currentSound.fadeCallback then
		local soundData = Schema.cinematics.cinematicData.currentSound

		if CurTime() >= soundData.fadeEndTime then
			local callback = soundData.fadeCallback
			soundData.fadeCallback = nil
			soundData.fadeEndTime = nil

			if soundData.fadeTargetVolume <= 0 then
				soundData.isPlaying = false
			end

			if callback then
				callback()
			end
		end
	end
end)

hook.Add("HUDPaint", "expCinematicsHUDPaint", function()
	local scrW, scrH = ScrW(), ScrH()

	if (Schema.cinematics.currentScene and Schema.cinematics.currentScene.OnDraw) then
		Schema.cinematics.currentScene:OnDraw(scrW, scrH)
	end

	if (Schema.cinematics.cinematicData.textDisplay) then
		local textData = Schema.cinematics.cinematicData.textDisplay
		local text = textData.text
		local alpha = textData.alpha or 255
		local startTime = textData.startTime
		local duration = textData.duration
		local horizontalAlignment = textData.horizontalAlignment or textData.alignment or TEXT_ALIGN_LEFT
		local verticalAlignment = textData.verticalAlignment or TEXT_ALIGN_BOTTOM

		if (CurTime() - startTime > duration) then
			Schema.cinematics.cinematicData.textDisplay = nil
			return
		end

		alpha = Schema.cinematics.CalculateTextAlpha(startTime, duration, alpha)

		local singleEntryArray = { { index = 1 } }
		local baseY = Schema.cinematics.CalculateVerticalStartPosition(singleEntryArray, scrH, verticalAlignment)

		Schema.cinematics.DrawCinematicText(text, horizontalAlignment, verticalAlignment, alpha, scrW, scrH, 1, baseY)
	end

	if (Schema.cinematics.cinematicData.textDisplayArray) then
		local activeEntries = {}
		local allEntries = Schema.cinematics.cinematicData.textDisplayArray

		for i, entry in ipairs(allEntries) do
			local currentTime = CurTime()
			local startTime = entry.startTime
			local duration = entry.duration

			if (currentTime >= startTime and currentTime <= startTime + duration) then
				table.insert(activeEntries, entry)
			end
		end

		if (#activeEntries > 0) then
			-- Group active entries by vertical alignment
			local topEntries = {}
			local centerEntries = {}
			local bottomEntries = {}

			for i, entry in ipairs(activeEntries) do
				local verticalAlignment = entry.verticalAlignment or TEXT_ALIGN_BOTTOM
				if verticalAlignment == TEXT_ALIGN_TOP then
					table.insert(topEntries, entry)
				elseif verticalAlignment == TEXT_ALIGN_CENTER then
					table.insert(centerEntries, entry)
				else
					table.insert(bottomEntries, entry)
				end
			end

			-- Draw each group with its own base position
			local function drawTextGroup(entries, alignment)
				if #entries == 0 then return end

				local baseY = Schema.cinematics.CalculateVerticalStartPosition(entries, scrH, alignment)

				for i, entry in ipairs(entries) do
					local startTime = entry.startTime
					local duration = entry.duration
					local alpha = Schema.cinematics.CalculateTextAlpha(startTime, duration, entry.alpha)
					local horizontalAlignment = entry.horizontalAlignment or TEXT_ALIGN_LEFT

					-- Use the entry's position within its alignment group for Y offset calculation
					Schema.cinematics.DrawCinematicText(entry.text, horizontalAlignment, alignment, alpha, scrW, scrH, i,
						baseY)
				end
			end

			drawTextGroup(topEntries, TEXT_ALIGN_TOP)
			drawTextGroup(centerEntries, TEXT_ALIGN_CENTER)
			drawTextGroup(bottomEntries, TEXT_ALIGN_BOTTOM)
		else
			Schema.cinematics.cinematicData.textDisplayArray = nil
		end
	end

	local shouldDrawBlack = false
	local fadeAlpha = 0

	if (Schema.cinematics.cinematicData.fadeIn and Schema.cinematics.cinematicData.fadeIn.active) then
		local fadeData = Schema.cinematics.cinematicData.fadeIn
		local elapsed = CurTime() - fadeData.startTime
		local progress = math.Clamp(elapsed / fadeData.duration, 0, 1)

		fadeAlpha = math.max(fadeAlpha, 255 * (1 - progress))
		shouldDrawBlack = true
	end

	if (Schema.cinematics.cinematicData.fadeOut and Schema.cinematics.cinematicData.fadeOut.active) then
		local fadeData = Schema.cinematics.cinematicData.fadeOut
		local elapsed = CurTime() - fadeData.startTime
		local progress = math.Clamp(elapsed / fadeData.duration, 0, 1)

		fadeAlpha = math.max(fadeAlpha, 255 * progress)
		shouldDrawBlack = true
	end

	if (Schema.cinematics.cinematicData.fadeOut and not Schema.cinematics.cinematicData.fadeOut.active and
			Schema.cinematics.cinematicData.fadeOut.callback) then
		fadeAlpha = 255
		shouldDrawBlack = true
	end

	if (shouldDrawBlack) then
		surface.SetDrawColor(0, 0, 0, fadeAlpha)
		surface.DrawRect(0, 0, scrW, scrH)
	end
end)

hook.Add("SetupWorldFog", "FlashbackFogHook", function()
	if (not Schema.cinematics.cinematicData.fogData) then
		return
	end

	render.FogMode(MATERIAL_FOG_LINEAR)

	local fogData = Schema.cinematics.cinematicData.fogData

	render.FogStart(fogData.fogStart)
	render.FogEnd(fogData.fogEnd)
	render.FogColor(fogData.color.r, fogData.color.g, fogData.color.b)
	render.FogMaxDensity(fogData.density)

	return true
end)

hook.Add("SetupSkyboxFog", "FlashbackSkyboxFogHook", function(skyboxScale)
	if (not Schema.cinematics.cinematicData.fogData) then
		return
	end

	local fogData = Schema.cinematics.cinematicData.fogData

	render.FogMode(MATERIAL_FOG_LINEAR)
	render.FogStart(fogData.fogStart * skyboxScale)
	render.FogEnd(fogData.fogEnd * skyboxScale)
	render.FogColor(fogData.color.r, fogData.color.g, fogData.color.b)
	render.FogMaxDensity(fogData.density)

	return true
end)

--[[
	Network messages
--]]

net.Receive("ixCinematicFadeIn", function()
	local fadeTime = net.ReadFloat()
	Schema.cinematics.FadeIn(fadeTime)
end)

net.Receive("ixCinematicFadeOut", function()
	local fadeTime = net.ReadFloat()
	local hasCallback = net.ReadBool()
	local blackPeriod = net.ReadFloat()
	local callbackData = nil

	if (hasCallback) then
		callbackData = {
			client = LocalPlayer(),
			sceneID = net.ReadString(),
			blackPeriod = blackPeriod
		}
	end

	Schema.cinematics.FadeOut(fadeTime, function()
		if (callbackData) then
			timer.Simple(callbackData.blackPeriod, function()
				net.Start("ixCinematicFadeComplete")
				net.WriteString(callbackData.sceneID)
				net.SendToServer()
			end)
		end
	end)
end)

net.Receive("ixCinematicSetBlackWhite", function()
	local enabled = net.ReadBool()

	Schema.cinematics.SetBlackAndWhite(enabled)
end)

net.Receive("ixCinematicShowText", function()
	local text = net.ReadString()
	local duration = net.ReadFloat()

	Schema.cinematics.ShowCinematicText(text, duration)
end)

net.Receive("ixCinematicEnterScene", function()
	local sceneID = net.ReadString()
	local scene = Schema.cinematics.Get(sceneID)

	if (scene) then
		Schema.cinematics.currentScene = scene

		if (scene.OnEnterLocalPlayer) then
			scene:OnEnterLocalPlayer()
		end
	end
end)

net.Receive("ixCinematicLeaveScene", function()
	local scene = Schema.cinematics.currentScene

	if (scene) then
		if (scene.OnLeaveLocalPlayer) then
			scene:OnLeaveLocalPlayer()
		end

		Schema.cinematics.currentScene = nil
	end

	Schema.cinematics.ClearFadeEffects()
	Schema.cinematics.ClearFogData()
	Schema.cinematics.SetBlackAndWhite(false)
	Schema.cinematics.cinematicData.textDisplay = nil
	Schema.cinematics.cinematicData.textDisplayArray = nil
end)
