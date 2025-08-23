--- Shared library that exposes effect functions, that can be used to script (without much Lua)
--- the effects to occur when starting an interaction, or on choosing a response.
--- @realm shared
Schema.npcEffect = ix.util.GetOrCreateLibrary("npcEffect", {
  stored = {},
})

--- @realm shared
--- @alias NpcEffectCallback fun(player: Player, parameters: table, npc: ExperimentNpc, npcEntity: Entity): any

--- @realm shared
--- @alias NpcEffect { name: string, uniqueID: string, parameters?: NpcParameter[], serverCallback: NpcEffectCallback }

--- @realm shared
--- @alias NpcEffectInfo { name: string, uniqueID: string, parameters: table<string, any> }

--- Registers a new effect for NPCs that can be selected for dynamically created
--- interactions.
--- @param effect NpcEffect
--- @return NpcEffect
--- @realm shared
function Schema.npcEffect.Register(effect)
  Schema.npcEffect.stored[effect.uniqueID] = effect

  if (not effect.parameters) then
    effect.parameters = {}
  end

  if (not effect.serverCallback or not isfunction(effect.serverCallback)) then
    Schema.Error("Effect %s does not have a serverCallback function", effect.uniqueID)
  end

  return effect
end

--- Returns all registered effects.
--- @return table<string, NpcEffect>
--- @realm shared
function Schema.npcEffect.GetAll()
  return Schema.npcEffect.stored
end

--- Returns a specific effect by its unique identifier.
--- @param uniqueID string
--- @return NpcEffect?
--- @realm shared
function Schema.npcEffect.Get(uniqueID)
  return Schema.npcEffect.stored[uniqueID]
end

if (SERVER) then
  --- Executes the given effects for the player, npc and npcEntity.
  --- @param effectsInfo? NpcEffectInfo[]
  --- @param player Player
  --- @param npcEntity Entity
  --- @realm server
  function Schema.npcEffect.Execute(effectsInfo, player, npcEntity)
    if (not effectsInfo) then
      return
    end

    local npc = npcEntity:GetNpcData()

    for _, effectInfo in ipairs(effectsInfo) do
      local effect = Schema.npcEffect.Get(effectInfo.uniqueID)

      if (not effect) then
        Schema.Error("Effect %s does not exist", effectInfo.uniqueID)
        continue
      end

      effect.serverCallback(player, effectInfo.parameters, npc, npcEntity)
    end
  end
end

Schema.npcEffect.Register({
  name = "Execute Lua",
  uniqueID = "executeLua",
  parameters = {
    {
      name = "Script",
      selectorType = {
        controlType = "DTextEntry",
        setupControl = function(control, value, npcEntity)
          control:SetMultiline(true)
          control:SetTall(128)
        end,
      },
    },
  },
  serverCallback = function(player, parameters, npc, npcEntity)
    Schema.RunString(parameters.Script)
  end,
})

Schema.npcEffect.Register({
  name = "Print to console",
  uniqueID = "printToConsole",
  parameters = {
    {
      name = "Text",
      selectorType = "string",
    },
  },
  serverCallback = function(player, parameters, npc, npcEntity)
    print(parameters.Text)
  end,
})

Schema.npcEffect.Register({
  name = "Print to chat (in radius)",
  uniqueID = "printToChat",
  parameters = {
    {
      name = "Class",
      selectorType = {
        controlType = "DComboBox",
        setupControl = function(control, value, npcEntity)
          control:SetSortItems(false)
          control:AddChoice("ic")
          control:AddChoice("event")
          control:AddChoice("npc_me")
          control:AddChoice("roll")
          -- Other classes that don't require a speaker (or support the data containing their name)
        end,
      },
    },
    {
      name = "SpeakerName",
      selectorType = {
        controlType = "DTextEntry",
        setupControl = function(control, value, npcEntity)
          control:SetValue(npcEntity:GetDisplayName())
        end,
      },
    },
    {
      name = "Text",
      selectorType = "string",
    },
    {
      name = "Radius",
      selectorType = {
        controlType = "DNumberWang",
        setupControl = function(control, value, npcEntity)
          control:SetMin(0)
          control:SetMax(10000)
          control:SetDecimals(0)
          control:SetValue(ix.config.Get("chatRange"))
        end,
      },
    },
  },
  serverCallback = function(player, parameters, npc, npcEntity)
    local text = parameters.Text
    local radius = parameters.Radius
    local class = parameters.Class
    local receivers = {}

    for _, nearbyClient in ipairs(ents.FindInSphere(npcEntity:GetPos(), radius)) do
      if (IsValid(nearbyClient) and nearbyClient:IsPlayer()) then
        table.insert(receivers, nearbyClient)
      end
    end

    ix.chat.Send(nil, class, text, false, receivers, {
      speakerName = parameters.SpeakerName,
      npcSpeakerEntity = npcEntity
    })
  end,
})

Schema.npcEffect.Register({
  name = "Give item",
  uniqueID = "giveItem",
  parameters = {
    {
      name = "ItemID",
      selectorType = "item",
    },
    {
      name = "Amount",
      selectorType = "number",
      default = 1,
    }
  },
  serverCallback = function(player, parameters, npc, npcEntity)
    local givenItemInstances = {}

    for i = 1, parameters.Amount do
      local itemInstance = Schema.item.CreateInstance(player, parameters.ItemID)
      local force, noMessage, noNetwork = true, true, true
      local success, fault = player:GiveItemInstance(itemInstance, force, noMessage, noNetwork)

      if (success) then
        table.insert(givenItemInstances, itemInstance)
      else
        ix.util.SchemaErrorNoHaltFormatted("Failed to give item: %s", fault)
      end
    end

    Schema.inventory.NetworkChanges(player, Schema.inventory.OP_ADDING, givenItemInstances)
  end,
})

Schema.npcEffect.Register({
  name = "Remove item",
  uniqueID = "removeItem",
  parameters = {
    {
      name = "ItemID",
      selectorType = "item",
    },
    {
      name = "Amount",
      selectorType = "number",
      default = 1,
    }
  },
  serverCallback = function(player, parameters, npc, npcEntity)
    local noMessage = true
    local success, fault = player:TakeAnyItemInstances(parameters.ItemID, parameters.Amount, noMessage)
    assert(success, fault)
  end,
})

Schema.npcEffect.Register({
  name = "Progression Change",
  uniqueID = "progressionChange",
  parameters = {
    {
      name = "ProgressionScope",
      selectorType = "progressionTrackerScope",
    },
    {
      name = "ProgressionKey",
      selectorType = "progressionTrackerKey",
    },
    {
      name = "Value",
      selectorType = "string",
    },
  },
  serverCallback = function(player, parameters, npc, npcEntity)
    local progressionScope = parameters.ProgressionScope
    local progressionKey = parameters.ProgressionKey
    local value = parameters.Value

    local converter = Schema.progression.GetTypeConverter(progressionScope, progressionKey)
    value = converter(value)

    Schema.progression.Change(player, progressionScope, progressionKey, value)
  end,
})

Schema.npcEffect.Register({
  name = "Play sound",
  uniqueID = "playSound",
  parameters = {
    {
      name = "Sound",
      selectorType = "string",
    },
  },
  serverCallback = function(player, parameters, npc, npcEntity)
    player:EmitSound(parameters.Sound)
  end,
})
