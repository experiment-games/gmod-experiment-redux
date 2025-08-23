local PLUGIN = PLUGIN

do
	local COMMAND = {}

	COMMAND.description = "Set the frequency of the stationary radio you are looking at, or a specific handheld radio."
	COMMAND.arguments = {
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	}

	function COMMAND:OnRun(client, frequency, handheldItemID)
		if (Schema.util.Throttle("SetFrequency", 2, client)) then
			client:Notify("You must wait a moment before setting the frequency again!")
			return
		end

		local success, fault = PLUGIN:ValidateFrequency(frequency)

		if (not success) then
			return client:Notify(fault)
		end

		if (handheldItemID) then
			local item = ix.item.instances[handheldItemID]

			if (not item or item:GetOwner() ~= client) then
				client:Notify("You do not own this handheld radio!")
				return
			end

			item:SetData("frequency", frequency)
			hook.Run("PlayerSetFrequency", client, frequency)

			-- client:EmitSound("ambient/levels/prison/radio_random12.wav")
			client:Notify("You have set your radio frequency to " .. frequency .. ".")

			return
		end

		local trace = client:GetEyeTraceNoCursor()
		local radio = trace.Entity

		if (not IsValid(radio) or radio:GetClass() ~= "exp_stationary_radio") then
			client:Notify("You must be looking at a stationary radio to set its frequency!")
			return
		end

		if (trace.HitPos:Distance(client:GetShootPos()) > ix.config.Get("maxInteractionDistance")) then
			client:Notify("This stationary radio is too far away!")
			return
		end

		radio:ChangeFrequency(frequency)
		hook.Run("PlayerSetFrequency", client, frequency, radio)

		client:Notify("You have set this stationary radio's frequency to " .. frequency .. ".")
	end

	ix.command.Add("SetFrequency", COMMAND)
end
