local PLUGIN = PLUGIN
local PANEL = {}

local OPEN_URL_PREFIX = "OPEN_URL:"

function PANEL:Init()
	self.html = self:Add("DHTML")
	self.html:Dock(FILL)

	local html = Schema.util.GetHtml("terms-of-service.html")

	html = html:Replace("{{privacy_email}}", ix.config.Get("privacyEmail"))
	html = html:Replace("{{support_email}}", ix.config.Get("supportEmail"))
	html = html:Replace("{{github_url}}", ix.config.Get("githubUrl"))

	self.html:SetHTML(html)

	self.html.ConsoleMessage = function(html, message, file, line)
		if (not isstring(message)) then
			message = "*js variable*"
		end

		if (message == "TERMS_AGREED") then
			self:Close()

			net.Start("expAcceptTermsOfService")
			net.SendToServer()
		elseif (message == "TERMS_DISAGREED") then
			net.Start("expDisagreeTermsOfService")
			net.SendToServer()
		elseif (message:StartsWith(OPEN_URL_PREFIX)) then
			self:Close()
			gui.OpenURL(message:sub(OPEN_URL_PREFIX:len() + 1))
		end
	end

	self.html.OnDocumentReady = function()
		self.targetAlpha = 0
	end

	self.currentAlpha = 255
end

-- Draws a black overlay that fades out when the document loads, preventing the character creation behind this panel to flash visible shortly on join
function PANEL:PaintOver(width, height)
	self.currentAlpha = math.Approach(self.currentAlpha, self.targetAlpha or self.currentAlpha, FrameTime() * 200)

	surface.SetDrawColor(0, 0, 0, self.currentAlpha)
	surface.DrawRect(0, 0, width, height)
end

vgui.Register("expTermsOfService", PANEL, "EditablePanel")
