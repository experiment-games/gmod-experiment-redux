--- Shared library that exposes condition functions, that can be used to script (without much Lua) the
--- conditions for an interaction set, interaction or response to be available to the player.
--- @realm shared
Schema.npcCondition = ix.util.GetOrCreateLibrary("npcCondition", {
  stored = {},
})

--- @realm shared
--- @alias SelectorControlSetup fun(control: Panel, value: any, npcEntity: Entity)

--- @realm shared
--- @alias SelectorType { controlType: string, findKey?: string, setupControl?: SelectorControlSetup, setupExtraButtons?: fun(entry: Panel, parent: Panel, npcEntity: Entity) }

--- @realm shared
--- @alias NpcParameter { selectorType: string|SelectorType, name: string, default?: any }

--- @realm shared
--- @class NpcCondition
--- @field uniqueID string
--- @field name string
--- @field selectorName string
--- @field selectorType string|SelectorType
--- @field serverCheck fun(player: Player, npcEntity: Entity, parameterOrParameters: any|table<string, any>):(boolean)
--- @field listViewFormatter fun(parameters: any, npc: ExperimentNpc, editor?: expNpcEditor):(string)?
--- @field parameters NpcParameter[]?

--- Registers a new condition for NPCs that can be selected for dynamically created
--- interactions.
--- @param condition NpcCondition
--- @return NpcCondition
--- @realm shared
function Schema.npcCondition.Register(condition)
  Schema.npcCondition.stored[condition.uniqueID] = condition

  if (not condition.parameters) then
    condition.parameters = {
      {
        selectorType = condition.selectorType,
        name = condition.uniqueID
      }
    }
  end

  if (not condition.listViewFormatter) then
    if (istable(condition.selectorType) and condition.selectorType.controlType == "expParameters") then
      condition.listViewFormatter = function(parameters, npc, editor)
        return util.TableToJSON(parameters)
      end
    end
  end

  return condition
end

local function requestProgressions(callback)
  Schema.npc.editorPanel.progressions = nil

  Schema.chunkedNetwork.Request("Progressions", {}, function(progressions, extraData)
    if (IsValid(Schema.npc.editorPanel)) then
      Schema.npc.editorPanel.progressions = progressions
    end

    callback(progressions)
  end)
end

--- Get the common selector types that are used in the NPC editor.
--- @return table<string, SelectorType>
--- @realm shared
function Schema.npcCondition.GetCommonSelectorTypes()
  local types = table.Copy({
    string = {
      controlType = "DTextEntry",
    },
    number = {
      controlType = "DNumberWang",
    },
    boolean = {
      controlType = "DCheckBox",
    },
    lua = {
      controlType = "DTextEntry",
      setupControl = function(control, value, npcEntity)
        control:SetMultiline(true)
        control:SetTall(50)
      end,
    },
    item = {
      controlType = "DComboBox",
      setupControl = function(control, value, npcEntity)
        for _, item in pairs(Schema.item.GetAll()) do
          control:AddChoice(item.name, item.uniqueID)
        end
      end,
    },
    progressionTrackerScope = {
      controlType = "DComboBox",
      findKey = "progressionTrackerScope",
      setupControl = function(control, value, npcEntity)
        control:SetSortItems(false)

        control.fill = function(progressions)
          control:Clear()
          control:SetEnabled(true)

          control.OnSelect = function(control, index, _, progressionTrackerScope)
            local progressionTrackerKeyControl = control:FindSiblingByFindKey("progressionTrackerKey")

            -- Remove all options and add new ones based on the selected progression tracker scope
            if (not progressionTrackerKeyControl or not IsValid(progressionTrackerKeyControl)) then
              print("No progression tracker key control found")
              return
            end

            progressionTrackerKeyControl:Clear()

            if (not progressionTrackerScope) then
              print("No progression tracker scope selected")
              return
            end

            local progressionTracker = Schema.npc.editorPanel.progressions[progressionTrackerScope]
                or Schema.progression.GetTracker(progressionTrackerScope)

            if (not progressionTracker) then
              ix.util.SchemaErrorNoHaltFormatted("Progression tracker '%s' does not exist",
                progressionTrackerScope)
              return
            end

            local keySets = {
              progressionTracker.goals,
              progressionTracker.progressionKeys,
            }

            for i, keys in ipairs(keySets) do
              for _, keyInfo in ipairs(keys) do
                local keyWithType = ("%s (%s)"):format(keyInfo.key, keyInfo.type)
                progressionTrackerKeyControl:AddChoice(
                  keyWithType,
                  keyInfo.key,
                  progressionTrackerKeyControl.desiredValue == keyInfo.key
                )
              end

              if (i < #keySets) then
                progressionTrackerKeyControl:AddSpacer()
              end
            end
          end

          -- Also insert code-defined progressions
          for uniqueID, progression in pairs(Schema.progression.trackersByID) do
            control:AddChoice(progression.name, uniqueID)
          end

          control:AddSpacer()

          for _, progression in pairs(progressions) do
            control:AddChoice(progression.name, progression.uniqueID)
          end

          if (control.desiredValue) then
            local optionIndex = control:FindOptionByData(control.desiredValue)

            if (optionIndex) then
              control:ChooseOptionID(optionIndex)
            end

            control.desiredValue = nil
          end
        end

        if (Schema.npc.editorPanel.progressions) then
          control.fill(Schema.npc.editorPanel.progressions)
          return
        end

        -- Load dynamic progressions loaded from server
        control:Clear()
        control:SetEnabled(false)
        control:SetText("Loading...")

        requestProgressions(control.fill)
      end,
      setupExtraButtons = function(entry, parent, npcEntity)
        local addProgressionButton = vgui.Create("DImageButton", parent)
        addProgressionButton:SetImage("icon16/add.png")
        addProgressionButton:SetSize(16, 16)
        addProgressionButton:SetKeepAspect(true)
        addProgressionButton:SetStretchToFit(true)
        addProgressionButton:Dock(LEFT)

        local editProgressionButton = vgui.Create("DImageButton", parent)
        editProgressionButton:SetImage("icon16/pencil.png")
        editProgressionButton:SetSize(16, 16)
        editProgressionButton:SetKeepAspect(true)
        editProgressionButton:SetStretchToFit(true)
        editProgressionButton:Dock(LEFT)
        editProgressionButton:DockMargin(5, 0, 0, 0)

        local function openEditProgressionDialog(tracker)
          local dialog = vgui.Create("expProgressionEditorSingle")
          dialog:SetAlwaysOnTop()
          dialog:SetSize(ScrW() * .5, ScrH() * .5)
          dialog:Center()
          dialog:MakePopup()
          dialog:SetToRemoveOnceInvalid(entry)

          if (tracker) then
            dialog:LoadProgression(tracker)
          end

          dialog.OnSave = function(dialog, uniqueID, scope, name, completedKey, isInProgressInfo,
                                   progressionKeys, goals)
            local progression = {
              uniqueID = uniqueID,
              scope = scope,
              name = name,
              completedKey = completedKey,
              isInProgressInfo = isInProgressInfo,
              progressionKeys = progressionKeys,
              goals = goals,
            }

            Schema.chunkedNetwork.Send("ProgressionsEdit", progression)

            entry.desiredValue = uniqueID

            -- Force a refresh
            entry:SetEnabled(false)
            entry:SetText("Loading...")
            requestProgressions(entry.fill)
          end
        end

        addProgressionButton.DoClick = function(addProgressionButton)
          openEditProgressionDialog()
        end

        editProgressionButton.DoClick = function(editProgressionButton)
          local _, uniqueID = entry:GetSelected()
          local tracker = Schema.npc.editorPanel.progressions[uniqueID]
              or Schema.progression.GetTracker(uniqueID)

          if (not tracker) then
            Schema.player.NotifyLocal("No valid progression tracker selected!")
            return
          end

          openEditProgressionDialog(tracker)
        end
      end,
    },
    progressionTrackerKey = {
      controlType = "DComboBox",
      findKey = "progressionTrackerKey",
      setupControl = function(control, value, npcEntity)
        control:SetSortItems(false)
      end,
    }
  })

  hook.Run("NpcEditorConstantTypesAdd", types)
  hook.Run("NpcEditorConstantTypesDestroy", types)
  hook.Run("NpcEditorConstantTypesSetup", types)

  return types
end

Schema.npcCondition.Register({
  uniqueID = "hasItem",
  name = "Player Has Item",
  selectorName = "Item",
  selectorType = {
    controlType = "expParameters",
    setupControl = function(control, values, npcEntity)
      control:SetupParameters({
        { selectorType = "item",   name = "itemID" },
        { selectorType = "number", name = "count", default = 1 },
      }, values, npcEntity)
    end,
  },
  serverCheck = function(player, npcEntity, parameters)
    return player:CountItem(parameters.itemID) >= parameters.count
  end,
})

Schema.npcCondition.Register({
  uniqueID = "progressionCheck",
  name = "Player Progression Check",
  selectorName = "Progression",
  selectorType = {
    controlType = "expParameters",
    setupControl = function(control, values, npcEntity)
      control:SetupParameters({
        { selectorType = "progressionTrackerScope", name = "scope" },
        { selectorType = "progressionTrackerKey",   name = "key" },
        { selectorType = "string",                  name = "valueToCompareTo" }
      }, values, npcEntity)
    end,
  },
  serverCheck = function(player, npcEntity, parameters)
    local valueToCompareTo = parameters.valueToCompareTo
    local converter = Schema.progression.GetTypeConverter(parameters.scope, parameters.key)
    valueToCompareTo = converter(valueToCompareTo)

    return Schema.progression.Check(player, parameters.scope, parameters.key, valueToCompareTo)
  end
})

Schema.npcCondition.Register({
  uniqueID = "luaCheckTrue",
  name = "Lua Evaluates to True",
  selectorName = "Lua Expression",
  selectorType = "lua",
  serverCheck = function(player, npcEntity, luaExpression)
    local results, resultCount = Schema.RunString(luaExpression)

    return unpack(results, 1, resultCount)
  end,
})

--- Get the conditions that have been registered for NPCs.
--- @return NpcCondition[]
--- @realm shared
function Schema.npcCondition.GetAll()
  return Schema.npcCondition.stored
end

--- Gets a condition by its unique identifier.
--- @param uniqueID string
--- @return NpcCondition?
--- @realm shared
function Schema.npcCondition.Get(uniqueID)
  return Schema.npcCondition.stored[uniqueID]
end

--- Checks if the given conditions pass for the player and npc.
--- @param conditions NpcCondition[]
--- @param player Player
--- @param npcEntity Entity
--- @return boolean
--- @realm shared
function Schema.npcCondition.CheckPass(conditions, player, npcEntity)
  if (not conditions) then
    return true
  end

  local npc = npcEntity:GetNpcData()

  for _, conditionInfo in ipairs(conditions) do
    local condition = Schema.npcCondition.Get(conditionInfo.uniqueID)

    if (not condition) then
      error("Condition " .. conditionInfo.uniqueID .. " does not exist")
    end

    -- Sort the parameters in the order that the condition expects them
    local parameters = {}

    if (#condition.parameters <= 1) then
      parameters = { conditionInfo.parameters }
    else
      for _, parameterInfo in ipairs(condition.parameters) do
        local parameter = conditionInfo.parameters[parameterInfo.name]

        if (not parameter and not parameterInfo.default) then
          error("Parameter " ..
            parameterInfo.name .. " does not exist for condition " .. conditionInfo.uniqueID)
        end

        table.insert(parameters, parameter or parameterInfo.default)
      end
    end

    if (not condition.serverCheck(player, npcEntity, unpack(parameters))) then
      return false
    end
  end

  return true
end
