local ITEM = ITEM

ITEM.name = "Bolt Generator"
ITEM.model = "models/props_combine/suit_charger001.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Protection"
ITEM.description = "Generates a steady rate of bolts over time and can be upgraded"
ITEM.maximum = 1
ITEM.noBusiness = true
ITEM.data = {
	upgrades = 0,
	power = 0,
}

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		if (self:GetData("placed")) then
			local panel = tooltip:AddRowAfter("name", "maximum")
			panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
			panel:SetText("Your Bolt Generator is placed in the world!")
			panel:SizeToContents()
		end

		local panel = tooltip:AddRowAfter("name", "upgrades")
		panel:SetBackgroundColor(derma.GetColor("Info", tooltip))
		panel:SetText("Upgrades: " .. self:GetData("upgrades", 0) .. "/" .. #self.generator.upgrades)
		panel:SizeToContents()
	end
end

ITEM.generator = {
	uniqueID = "exp_bolt_control_unit",
	health = 200,
	produce = 100, -- Base production
	power = 4,
	name = "Bolt Generator",
	upgrades = {
		{
			name = "Minor Augmentation",
			price = 350,
			produce = 50
		},
		{
			name = "Major Augmentation",
			price = 1000,
			produce = 100
		},
		{
			name = "Ultra Augmentation",
			price = 2500,
			produce = 200
		},
		{
			name = "Minor+",
			price = 5000,
			produce = 100,
			condition = function(client, entity)
				if (client ~= entity:GetItemOwner()) then
					return false, "You can not upgrade this CBU to a Master of Logistics upgrade!"
				end

				return Schema.perk.GetOwned("master_of_logistics", client),
					"You do not have the master of logistics perk!"
			end
		},
		{
			name = "Major+",
			price = 5000,
			produce = 200,
			condition = function(client, entity)
				if (client ~= entity:GetItemOwner()) then
					return false, "You can not upgrade this CBU to a Master of Logistics upgrade!"
				end

				return Schema.perk.GetOwned("master_of_logistics", client),
					"You do not have the master of logistics perk!"
			end
		},
		{
			name = "Ultra+",
			price = 5000,
			produce = 400,
			condition = function(client, entity)
				if (client ~= entity:GetItemOwner()) then
					return false, "You can not upgrade this CBU to a Master of Logistics upgrade!"
				end

				return Schema.perk.GetOwned("master_of_logistics", client),
					"You do not have the master of logistics perk!"
			end
		}
	}
}
