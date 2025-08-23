do
	--- @class expNpcInteraction : EditablePanel
	local PANEL = {}

	local CSS_INTERACTION_DEFAULT = [[
@font-face {
	font-family: "LightsOut";
	src: url(http://fastdl.experiment.games/resource/fonts/lightout.woff)
}

@font-face {
	font-family: "RomanAntique";
	src: url(http://fastdl.experiment.games/resource/fonts/RomanAntique.woff);
}

* {
	box-sizing: border-box;
}

::-webkit-scrollbar {
  width: 10px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background: #A33426;
}

::-webkit-scrollbar-thumb:hover {
  background: #C34A3B;
}

html, body {
    margin: 0;
    padding: 0;
    height: 100%;
    overflow: hidden; /* Prevent double scrollbar */
	color: white;
	font-size: 24px;
	font-family: "RomanAntique";
}

h1,
h2,
h3,
h4,
h5,
h6 {
	color: #A33426;
	font-family: "LightsOut";
	margin: 0;
}

.container {
    display: flex;
    flex-direction: column;
    height: 100%;
    height: 100vh;
	padding: 16px;
}

.header {
	padding-bottom: 0.5em;
}

.content {
    flex: 1;
    overflow-y: auto;
    min-height: 0; /* for flexbox in older Chromium versions */
	word-wrap: break-word;
}

.highlight {
	background-color: #A33426;
	color: white;
	padding: 4px 8px;
	border-radius: 4px;
}

button {
	box-sizing: border-box;
	display: block;
	width: 100%;
	font-size: 20px;
	padding: 16px 8px;
	background-color: #A33426;
	color: white;
	border: none;
	border-radius: 4px;
	cursor: pointer;
	margin-top: 0.5em;
	transition: transform 0.2s;
}

button:hover {
	background-color: #C34A3B;
	transform: scale(1.02);
}

button:disabled {
	background-color: #555;
	cursor: not-allowed;
	transform: scale(1);
}

.answer-container {
	display: flex;
	flex-direction: row;
}

.rewards ul, .rewards ul li {
	margin: 0;
	padding: 0;
}

.rewards h3 {
	opacity: 0.7;
}

.rewards div {
	margin-top: 12px;
}
]]

	function PANEL:Init()
		if (IsValid(Schema.npc.panel)) then
			Schema.npc.panel:Remove()
		end

		self.html = self:Add("DHTML")
		self.html:Dock(FILL)
		self.html:DockMargin(8, 8, 8, 8)

		-- For saving changes when an admin is editing the NPC interaction
		self.html:AddFunction("interop", "editNpc", function(npcName, text, ...)
			if (not Schema.npc.isInlineEditing) then
				return
			end

			local answers = { ... }

			Schema.chunkedNetwork.Send(
				"NpcInteractEdit",
				{ self.npc.uniqueID, npcName, text, answers }
			)
		end)

		-- Called when the player chooses an answer
		self.html:AddFunction("interop", "chooseAnswer", function(answerIndex)
			local interaction = self:GetInteraction()
			local response = interaction:GetResponses()[answerIndex]

			self:OnAnswer(response, response:GetAnswer(LocalPlayer(), self.npcEntity))
		end)

		Schema.npc.panel = self
	end

	--- @param answer InteractionResponse
	--- @param answerText string The text that was generated/chosen when creating the button
	function PANEL:OnAnswer(answer, answerText)
		-- Prevent accidental double-clicking and make the player be intentional by waiting a bit before skipping
		self.choosingSkipAfter = CurTime() + 0.15

		self:ShowChosenAnswer(answerText, function()
			net.Start("expNpcInteractResponse")
			net.WriteUInt(answer:GetIndex(), 6)
			net.SendToServer()

			if (IsValid(self)) then
				self.choosingSkipAfter = nil
			end

			if (answer:GetNextInteraction() == nil) then
				if (IsValid(Schema.entityPanel)) then
					Schema.entityPanel:Remove()
					self:SetAlpha(0) -- Ensure the fade out of the entity panel shows nicely
				elseif (IsValid(self)) then
					self:Remove()
				end

				return
			end
		end)
	end

	function PANEL:ReplaceNewLines(text)
		return text:gsub("\n", "<br>")
	end

	function PANEL:SetText(text)
		text = self:ReplaceNewLines(text)

		local info = {
			css = CSS_INTERACTION_DEFAULT,
			text = text,
			npcName = self.npc.name or "???",
			html = nil, -- Set this to completely replace the HTML
			answersHtml = nil,
		}

		if (self.interaction) then
			local responses = self.interaction:GetResponses()
			local answers = {}
			local answerIndex = 1

			for i, response in ipairs(responses) do
				local answer = response:GetAnswer(LocalPlayer(), self.npcEntity)

				if (not answer) then
					continue
				end

				answers[answerIndex] = {
					index = i,
					text = answer,
					editable = response:CheckCanChoose(LocalPlayer(), self.npcEntity)
				}

				answerIndex = answerIndex + 1
			end

			-- We use innerText to prevent injection of unknown HTML
			local answersJson = util.TableToJSON(answers)
			info.answersHtml = [[
			<script>
				var answers = ]] .. answersJson .. [[;

				function disableAnswerButtons() {
					var buttons = document.getElementById("answers").getElementsByTagName("button");
					for (var i = 0; i < buttons.length; i++) {
						buttons[i].disabled = true;
					}
				}

				for (var i = 0; i < answers.length; i++) {
					(function(i) {
						var buttonContainer = document.createElement("div");
						buttonContainer.className = "answer-container";
						var button = document.createElement("button");
						button.className = "editable";
						button.innerText = answers[i].text;
						button.disabled = !answers[i].editable;
						button.onclick = function() {
							disableAnswerButtons();
							interop.chooseAnswer(answers[i].index);
						};

						buttonContainer.appendChild(button);
						document.getElementById("answers").appendChild(buttonContainer);
					})(i);
				}
			</script>
		]]
		end

		hook.Run("AdjustNpcInteractionInfo", info)

		local editableMarkup = ""

		-- Make the content editable for admins
		if (Schema.npc.isInlineEditing and self.isDynamic) then
			editableMarkup = [[
			<style>
				#edit-buttons {
					top: 0;
					right: 8px;
					position: fixed;
				}

				#edit-buttons button {
					display: inline-block;
					width: auto;
					margin-top: 0;
				}

				.enabled {
					background-color: #79C99E;
					color: black;
				}

				.is-answer-editor {
					background-color: #E3B505;
					color: black;
				}

				.remove {
					margin-left: 0.5em;
					width: auto;
				}
			</style>
		]]

			-- editableMarkup = editableMarkup .. [[
			-- 	<script>
			-- 		document.getElementById("npcName").setAttribute("contenteditable", "true")
			-- 		document.getElementById("text").setAttribute("contenteditable", "true")
			-- 	</script>
			-- ]]

			-- Add a save button to save the changes
			editableMarkup = editableMarkup .. [[
			<div id="edit-buttons">
				<button id="edit-toggle" onclick="toggleEditMode()">Enable Edit</button>
				<button onclick="saveChanges()">Save</button>
			</div>
			<script>
				var editToggleButton = document.getElementById("edit-toggle");
				var answersContainer = document.getElementById("answers");
				var isEditable = false;

				function addAnswerEditors() {
					// Adds a button to add another answer
					var button = document.createElement("button");
					button.className = "is-answer-editor";
					button.innerText = "Add Another Answer";
					button.onclick = function() {
						var buttonContainer = document.createElement("div");
						buttonContainer.className = "answer-container";
						var newButton = document.createElement("button");
						newButton.className = "editable";
						newButton.contentEditable = isEditable;
						newButton.innerText = "<New Answer>";
						buttonContainer.appendChild(newButton);
						answersContainer.insertBefore(buttonContainer, button);
					};
					answersContainer.appendChild(button);

					// Adds a remove button after each answer
					var buttons = document.getElementById("answers")
						.getElementsByTagName("button");

					for (var i = 0; i < buttons.length; i++) {
						var button = buttons[i];

						if (button.className.indexOf("is-answer-editor") === -1) {
							var removeButton = document.createElement("button");
							removeButton.className = "is-answer-editor remove";
							removeButton.innerText = "Remove";
							removeButton.addEventListener("click", function(event) {
								event.target.parentElement.remove();
							});
							button.parentElement.appendChild(removeButton);
						}
					}
				}

				function setCaret(el) {
					var range = document.createRange();
					var sel = window.getSelection();

					range.setStart(el, 0);
					range.collapse(true);

					sel.removeAllRanges();
					sel.addRange(range);
    				el.focus();
				}

				function toggleEditMode() {
					isEditable = !isEditable;

					var elements = document.getElementsByClassName("editable");

					if (isEditable) {
						editToggleButton.className = 'enabled';
						editToggleButton.innerText = 'Disable Edit';

						addAnswerEditors();
					} else {
						editToggleButton.className = '';
						editToggleButton.innerText = 'Enable Edit';

						var buttons = document.getElementsByClassName("is-answer-editor");

						while (buttons.length > 0) {
							buttons[0].remove();
						}
					}

					// Disable answer buttons temporarily so clicking on them to
					// edit the text doesn't trigger the answer
					for (var i = 0; i < elements.length; i++) {
						var element = elements[i];
						element.contentEditable = isEditable;

						// element.disabled = isEditable also stops it being editable, so lets just rename the onclick attribute
						if (!isEditable) {
							var onclick = element.getAttribute("disabledonclick");
							element.setAttribute("onclick", onclick);
						} else {
							var onclick = element.getAttribute("onclick");
							element.setAttribute("disabledonclick", onclick);

							// When the element is clicked, select the text so editing is easier, especially
							// when no content is in the element
							element.setAttribute("onclick", "setCaret(this);");

						}
					}
				}

				function saveChanges() {
					var npcData = [
						document.getElementById("npcName").innerText,
						document.getElementById("text").innerText,
					];

					var buttons = document.getElementById("answers")
						.getElementsByTagName("button");

					for (var i = 0; i < buttons.length; i++) {
						var button = buttons[i];
						if (button.className.indexOf("is-answer-editor") === -1) {
							npcData.push(button.innerText);
						}
					}

					interop.editNpc.apply(null, npcData);
				}
			</script>
		]]
		end

		local html = info.html or ([[
		<html>
			<head>
				<style>
					]] .. info.css .. [[
				</style>
			</head>
			<body>
				<div class="container">
					<div class="header">
						<h1 id="npcName" class="editable">]] .. info.npcName .. [[</h1>
					</div>
					<div class="content">
						<div id="text" class="editable">]] .. info.text .. [[</div>
					</div>
					<div class="footer">
						<div id="answers">]] .. (info.answersHtml or "") .. [[</div>
					</div>
				</div>
				]] .. editableMarkup .. [[
			</body>
		</html>
	]])

		self.html:SetHTML(html)
	end

	function PANEL:SetInteraction(interaction, npc, npcEntity, isDynamic)
		local text = interaction:GetText(LocalPlayer(), npcEntity)

		self.isDynamic = isDynamic or false
		self.npcEntity = npcEntity
		self.npc = npc
		self.interaction = interaction

		self:SetText(text)
	end

	function PANEL:GetInteraction()
		return self.interaction
	end

	function PANEL:ShowChosenAnswer(text, callbackOnFinishGrace)
		local gracePeriod = ix.config.Get("npcAnswerGracePeriod")

		self.chosenAnswer = text
		self.chosenAnswerTime = CurTime() + gracePeriod
		self.callbackOnFinishGrace = callbackOnFinishGrace
	end

	function PANEL:ForceEarlyGraceFinish()
		self.chosenAnswerTime = 0
	end

	function PANEL:PaintOver(width, height)
		if (not self.chosenAnswerTime) then
			return
		end

		if (CurTime() > self.chosenAnswerTime) then
			local callback = self.callbackOnFinishGrace

			self.chosenAnswerTime = nil
			self.callbackOnFinishGrace = nil

			if (callback) then
				callback()
			end

			return
		end

		local gracePeriod = ix.config.Get("npcAnswerGracePeriod")
		local fraction = 1 - ((self.chosenAnswerTime - CurTime()) / gracePeriod)
		local maxAlpha = 150

		surface.SetDrawColor(0, 0, 0, maxAlpha * fraction)
		surface.DrawRect(0, 0, width, height)

		local text = self.chosenAnswer
		local smallTextFont = "DermaDefault"

		local textWidth, textHeight = Schema.GetCachedTextSize(smallTextFont, text)

		local x = width * 0.5
		local targetY = height * 0.5 - textHeight * 0.5
		local y = Lerp(fraction, height, targetY)

		draw.SimpleText(text, smallTextFont, x, y, Color(255, 255, 255, 255 - (255 * fraction)), TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER)
	end

	--- Called when the player uses the close button in the entity menu
	function PANEL:OnCloseButtonPressed()
		local interaction = self:GetInteraction()

		if (not interaction) then
			return
		end

		interaction:CallClientOnClosed(LocalPlayer(), self.npcEntity)
	end

	function PANEL:OnRemove()
		Schema.npc.panel = nil
	end

	vgui.Register("expNpcInteraction", PANEL, "EditablePanel")
end
