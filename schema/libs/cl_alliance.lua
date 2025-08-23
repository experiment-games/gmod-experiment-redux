Schema.alliance = ix.util.GetOrCreateLibrary("alliance", {
  notices = {},
})

net.Receive("AllianceMemberInvitation", function()
  local allianceId = net.ReadUInt(32)
  local allianceName = net.ReadString()

  Schema.alliance.notices[#Schema.alliance.notices + 1] = {
    notice = "You have been invited to join the alliance '" .. allianceName .. "'.",
    allianceId = allianceId,
    actions = {
      {
        text = "Accept",
        callback = function(button, notice)
          net.Start("AllianceRequestInviteAccept")
          net.WriteUInt(allianceId, 32)
          net.SendToServer()
        end
      },
      {
        text = "Decline",
        callback = function()
          net.Start("AllianceRequestInviteDecline")
          net.WriteUInt(allianceId, 32)
          net.SendToServer()
        end
      }
    }
  }

  if (IsValid(ix.gui.alliance)) then
    ix.gui.alliance:Update()
  end
end)

net.Receive("AllianceInviteDeclined", function()
  local allianceId = net.ReadUInt(32)

  for k, v in ipairs(Schema.alliance.notices) do
    if (v.allianceId == allianceId) then
      table.remove(Schema.alliance.notices, k)
      break
    end
  end

  if (IsValid(ix.gui.alliance)) then
    ix.gui.alliance:Update()
  end
end)
