local ITEM = ITEM

ITEM.name = "Vegetable Oil"
ITEM.price = 55
ITEM.shipmentSize = 5
ITEM.model = "models/props_junk/garbage_plasticbottle002a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A bottle of vegetable oil, it isn't very tasty."
ITEM.useSound = "npc/barnacle/barnacle_gulp1.wav"

ITEM.functions.Drink = {
	OnRun = function(item)
		local client = item.player

		client:Notify("You drink the vegetable oil.")

		if (item.useSound) then
			client:EmitSound(item.useSound)
		end

		timer.Simple(1, function()
			if (IsValid(client) and client:Alive()) then
				client:TakeDamage(15, client, game.GetWorld())
			end
		end)
	end
}
