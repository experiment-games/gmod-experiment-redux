local PLUGIN = PLUGIN

util.AddNetworkString("expSetStructureBuilderBlueprint")
util.AddNetworkString("expBuildingRequestBuildStructure")

ix.util.AddResourceFile("materials/experiment-redux/blueprint.png")
ix.util.AddResourceFile("materials/experiment-redux/replacements/clipboard.vmt")

function PLUGIN:BuildStructure(client, item, position, angles)
	local structureBaseEntity = ents.Create("exp_structure")
	structureBaseEntity:SetStructure(client, item, position, angles)
	structureBaseEntity:Spawn()

	return structureBaseEntity
end

function PLUGIN:LearnBlueprint(client, uniqueID)
	local character = client:GetCharacter()

	if (not character) then
		return
	end

	local blueprintsLearned = character:GetData("blueprintsLearned", {})
	blueprintsLearned[uniqueID] = true
	character:SetData("blueprintsLearned", blueprintsLearned)
end

--[[
	Hooks
--]]

function PLUGIN:PostPlayerLoadout(client)
	client:Give("exp_structure_builder")
end

function PLUGIN:PlayerFillDefaultInventory(client, character, inventory)
	inventory:Add("crowbar", 1)
end

function PLUGIN:EntityTakeDamage(entity, damageInfo)
	local attacker = damageInfo:GetAttacker()

	if (not IsValid(attacker) or not attacker:IsPlayer()) then
		return
	end

	local weapon = attacker:GetActiveWeapon()

	if (not IsValid(weapon) or not weapon.ixItem) then
		return
	end

	if (not entity.IsStructureOrPart) then
		-- Crowbars should do extra damage to structures and bolt generators, but minimal damage to anything else
		if (weapon.ixItem.uniqueID == "crowbar") then
			if (entity.IsBoltGenerator) then
				damageInfo:ScaleDamage(1.1)
				Schema.achievement.Progress("freeman", attacker)
			else
				damageInfo:ScaleDamage(0.01)
			end
		end

		return
	end

	if (weapon.ixItem.uniqueID == "crowbar") then
		damageInfo:ScaleDamage(1.1)
		Schema.achievement.Progress("freeman", attacker)
	else
		-- Any other damage should be scaled down, to make the crowbar more interesting, especially bullet damage
		if (damageInfo:IsBulletDamage()) then
			damageInfo:ScaleDamage(0.1)
		else
			damageInfo:ScaleDamage(0.2)
		end
	end
end

-- Let's allow users to use structures as doors
function PLUGIN:PlayerUse(client, entity)
	if (not entity.IsStructureOrPart) then
		return
	end

	local parent = entity:GetParent()

	if (IsValid(parent)) then
		entity = parent
	end

	entity:TryUse(client)
end

--[[
	Net Messages
--]]

net.Receive("expSetStructureBuilderBlueprint", function(_, client)
	local uniqueID = net.ReadString()
	local itemTable = ix.item.list[uniqueID]

	local weapon = client:GetWeapon("exp_structure_builder")

	if (IsValid(weapon)) then
		weapon.ixItem = itemTable
		weapon:SetItemTable(itemTable)
	end
end)

net.Receive("expBuildingRequestBuildStructure", function(_, client)
	local position = net.ReadVector()
	local angles = net.ReadAngle()

	if (Schema.util.Throttle("BuildStructure", 2, client)) then
		return
	end

	local weapon = client:GetActiveWeapon()

	if (not IsValid(weapon) or weapon:GetClass() ~= "exp_structure_builder") then
		client:Notify("You must have the blueprint equipped.")
		return
	end

	local item = weapon.ixItem

	if (not item) then
		client:Notify("You have no blueprint selected to build!")
		return
	end

	local structures = ents.FindByClass("exp_structure")

	for _, structure in ipairs(structures) do
		local structureBuilder = structure:GetBuilder()

		if (IsValid(structureBuilder) and structureBuilder == client and structure:GetUnderConstruction()) then
			client:Notify("You are already building a structure. Finish that first.")
			return
		end
	end

	local isPlacementValid, otherStructureOrError = PLUGIN:GetPlacementValid(client, position, angles)

	if (not isPlacementValid) then
		client:Notify(otherStructureOrError)
		return
	end

	if (item.OnCanBuild and not item:OnCanBuild(client, position, angles)) then
		return
	end

	if (item.structureMaximum and client:IsObjectLimited(item.uniqueID, item.structureMaximum)) then
		client:Notify("You can not place this as you have reached the maximum amount of this structure!")
		return
	end

	if (item.structureOffset) then
		position = position + item.structureOffset
	end

	local structure = PLUGIN:BuildStructure(client, item, position, angles)
	local otherStructureGroundLevel = IsValid(otherStructureOrError) and otherStructureOrError:GetGroundLevel() or 0
	structure:SetGroundLevel(otherStructureGroundLevel + 1)

	structure:EmitSound("physics/wood/wood_box_impact_soft3.wav", 75, 70)

	client:Notify("You have constructed a structure blueprint, complete it by filling it with materials.")
end)
