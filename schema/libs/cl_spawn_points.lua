Schema.spawnPoints = ix.util.GetOrCreateLibrary("spawnPoints", {
	spawns = {},
})

hook.Add("HUDPaint", "expSpawnPointsHUDPaint", function()
	local client = LocalPlayer()

	if (not IsValid(client)) then
		return
	end

	local isChoosingSpawn = client:GetNetVar("expChoosingSpawn", false)

	if (not isChoosingSpawn) then
		if (Schema.spawnPoints.fadeSpawnToZero and Schema.spawnPoints.fadeSpawnToZero > CurTime()) then
			local alpha = 255 - math.TimeFraction(
				Schema.spawnPoints.fadeSpawnToZero - 1,
				Schema.spawnPoints.fadeSpawnToZero,
				CurTime()
			) * 255
			local scrW, scrH = ScrW(), ScrH()

			surface.SetDrawColor(0, 0, 0, alpha)
			surface.DrawRect(0, 0, scrW, scrH)
		end

		return
	end

	local scrW, scrH = ScrW(), ScrH()

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, scrW, scrH)

	Schema.spawnPoints.fadeSpawnToZero = CurTime() + 1
end)

net.Receive("expSpawnSelectOpen", function()
	local spawns = net.ReadTable()
	local panel = vgui.Create("expSpawnSelection")

	Schema.spawnPoints.spawns = spawns

	panel:SetSpawns(spawns)

	hook.Run("OnSpawnSelectOpen", panel)
end)

net.Receive("expSpawnSelectResponse", function()
	local status = net.ReadUInt(4)

	if (status == Schema.spawnPoints.spawnResult.OK) then
		if (IsValid(ix.gui.spawnSelection)) then
			ix.gui.spawnSelection:Remove()
		end

		hook.Run("OnSpawnSelectSuccess")
	elseif (status == Schema.spawnPoints.spawnResult.FAIL) then
		ix.gui.spawnSelection:Rebuild()
	else
		ix.util.SchemaErrorNoHalt("An unknown error occurred. (TODO)\n")
	end
end)
