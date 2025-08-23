Schema.entityMarker = ix.util.GetOrCreateLibrary("entityMarker")

util.AddNetworkString("expEntityMarkerForce")

function Schema.entityMarker.MarkForPlayer(client, entity)
	if (not IsValid(entity)) then
		return
	end

	net.Start("expEntityMarkerForce")
	net.WriteUInt(entity:EntIndex(), MAX_EDICT_BITS)
	net.WriteBool(true)
	net.Send(client)
end

function Schema.entityMarker.UnmarkForPlayer(client, entity)
	if (not IsValid(entity)) then
		return
	end

	net.Start("expEntityMarkerForce")
	net.WriteUInt(entity:EntIndex(), MAX_EDICT_BITS)
	net.WriteBool(false)
	net.Send(client)
end
