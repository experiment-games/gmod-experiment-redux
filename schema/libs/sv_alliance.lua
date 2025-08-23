util.AddNetworkString("AllianceRequestInviteMember")
util.AddNetworkString("AllianceMemberInvitation")
util.AddNetworkString("AllianceRequestInviteAccept")
util.AddNetworkString("AllianceRequestInviteDecline")
util.AddNetworkString("AllianceInviteDeclined")
util.AddNetworkString("AllianceRequestUpdateMembers")
util.AddNetworkString("AllianceRequestUpdateMembersDeclined")
util.AddNetworkString("AllianceForceUpdate")
util.AddNetworkString("AllianceUpdateMembers")

Schema.alliance = ix.util.GetOrCreateLibrary("alliance")

function Schema.alliance.LoadTables()
  local query

  query = mysql:Create("exp_alliances")
  query:Create("alliance_id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
  query:Create("name", "VARCHAR(32) NOT NULL")
  query:Create("members", "TEXT NOT NULL")
  query:Create("created", "INT(11) UNSIGNED NOT NULL")
  query:PrimaryKey("alliance_id")
  query:Execute()
end

hook.Add("DatabaseConnected", "expDatabaseConnected_AllianceLoadTables", function()
  Schema.alliance.LoadTables()
end)

function Schema.alliance.WipeTables()
  local query

  query = mysql:Drop("exp_alliances")
  query:Execute()
end

hook.Add("OnWipeTables", "expWipeTables_AllianceWipeTables", function()
  Schema.alliance.WipeTables()
end)

function Schema.alliance.Create(client, allianceName, callback)
  local character = client:GetCharacter()
  local ownerId = character:GetID()
  local rank = RANK_GENERAL
  local query

  local members = {
    {
      id = ownerId,
      rank = rank,
      name = character:GetName(),
    }
  }

  query = mysql:Insert("exp_alliances")
  query:Insert("name", allianceName)
  query:Insert("members", util.TableToJSON(members))
  query:Insert("created", os.time())
  query:Callback(function(result, status, lastID)
    if (not IsValid(client)) then
      return
    end

    if (status == false) then
      ix.log.Add(client, "schemaDebug", "CreateAlliance",
        "Failed to create alliance with result " .. tostring(result) .. " and lastID " .. tostring(lastID) .. ".")
      return
    end

    character:SetData("rank", rank)
    callback(lastID, members)
  end)
  query:Execute()
end

function Schema.alliance.GetOnlineMembers(allianceId)
  local members = {}

  for _, v in ipairs(player.GetAll()) do
    local alliance = v:GetAlliance()

    if (not alliance or alliance.id ~= allianceId) then
      continue
    end

    table.insert(members, v)
  end

  return members
end

--- Attempts to add an alliance member to the given alliance.
--- @param allianceId number The ID of the alliance to add the member to.
--- @param memberId number The ID of the character to add as a member.
--- @param memberName string The name of the member to add.
--- @param memberRank number The rank of the member to add.
--- @param callback fun(success: boolean, reason: string?, alliance: table?) When the alliance is valid it will be passed as the third argument.
function Schema.alliance.AddMember(allianceId, memberId, memberName, memberRank, callback)
  return Schema.util.RunSingleWithinScope("AllianceModifyMembers", function(release)
    local query

    query = mysql:Select("exp_alliances")
    query:Select("name")
    query:Select("members")
    query:Where("alliance_id", allianceId)
    query:Callback(function(result)
      if (not result or #result < 1) then
        release()
        callback(false, "Alliance does not exist.")
        return
      end

      local alliance = result[1]
      local members = util.JSONToTable(alliance.members) or {}

      table.insert(members, {
        id = memberId,
        rank = memberRank,
        name = memberName,
      })

      query = mysql:Update("exp_alliances")
      query:Update("members", util.TableToJSON(members))
      query:Where("alliance_id", allianceId)
      query:Callback(function(result, status)
        if (status == false) then
          release()
          callback(false, "Failed to add member.", alliance)
          return
        end

        release()
        callback(true, nil, alliance)
      end)
      query:Execute()
    end)
    query:Execute()
  end)
end

function Schema.alliance.RemoveMember(allianceId, memberId, callback)
  return Schema.util.RunSingleWithinScope("AllianceModifyMembers", function(release)
    local query

    query = mysql:Select("exp_alliances")
    query:Select("members")
    query:Where("alliance_id", allianceId)
    query:Callback(function(result)
      if (not result or #result < 1) then
        release()
        callback(false, "Alliance does not exist.")
        return
      end

      local members = util.JSONToTable(result[1].members) or {}
      local found = false

      for k, v in ipairs(members) do
        if (v.id == memberId) then
          table.remove(members, k)
          found = true
          break
        end
      end

      if (not found) then
        release()
        callback(false, "Member does not exist.")
        return
      end

      if (#members == 0) then
        query = mysql:Delete("exp_alliances")
        query:Where("alliance_id", allianceId)
        query:Callback(function(result, status)
          if (status == false) then
            release()
            callback(false, "Failed to remove alliance.")
            return
          end

          release()
          callback(true)
        end)
        query:Execute()

        return
      else
        query = mysql:Update("exp_alliances")
        query:Update("members", util.TableToJSON(members))
        query:Where("alliance_id", allianceId)
        query:Callback(function(result, status)
          if (status == false) then
            release()
            callback(false, "Failed to remove member.")
            return
          end

          release()
          callback(true)
        end)
        query:Execute()
      end
    end)
    query:Execute()
  end)
end

function Schema.alliance.SetMemberRank(allianceId, memberId, memberRank, callback)
  return Schema.util.RunSingleWithinScope("AllianceModifyMembers", function(release)
    local query

    query = mysql:Select("exp_alliances")
    query:Select("members")
    query:Where("alliance_id", allianceId)
    query:Callback(function(result)
      if (not result or #result < 1) then
        release()
        callback(false, "Alliance does not exist.")
        return
      end

      local members = util.JSONToTable(result[1].members) or {}
      local found = false

      for k, v in ipairs(members) do
        if (v.id == memberId) then
          v.rank = memberRank
          found = true
          break
        end
      end

      if (not found) then
        release()
        callback(false, "Member does not exist.")
        return
      end

      query = mysql:Update("exp_alliances")
      query:Update("members", util.TableToJSON(members))
      query:Where("alliance_id", allianceId)
      query:Callback(function(result, status)
        if (status == false) then
          release()
          callback(false, "Failed to set member rank.")
          return
        end

        release()
        callback(true)
      end)
      query:Execute()
    end)
    query:Execute()
  end)
end

function Schema.alliance.RequestCreate(client, allianceName)
  if (Schema.util.Throttle("RequestCreate", 10, client)) then
    client:Notify("Please wait before trying to create an alliance again.")

    return
  end

  local canRun = Schema.util.RunSingleWithinScope("RequestCreate", function(release)
    if (type(allianceName) ~= "string" or allianceName:len() < 1) then
      client:Notify("You entered an invalid alliance name!")

      release()
      return
    end

    local allianceCost = ix.config.Get("allianceCost")
    local character = client:GetCharacter()

    if (not character:HasMoney(allianceCost)) then
      client:Notify("You need another " ..
        ix.currency.Get(allianceCost - character:GetMoney(), nil, true) .. "!")

      release()
      return
    end

    local query

    query = mysql:Select("exp_alliances")
    query:Select("alliance_id")
    query:Where("name", allianceName)
    query:Callback(function(result)
      if (not IsValid(client)) then
        release()
        return
      end

      if (client:GetCharacter() ~= character) then
        client:Notify("You switched characters before the alliance creation process could finish.")
        release()
        return
      end

      if (result and #result > 0) then
        client:Notify("An alliance with the name '" .. allianceName .. "' already exists!")
        release()
        return
      end

      Schema.alliance.Create(client, allianceName, function(allianceId, members)
        if (not IsValid(client)) then
          release()
          return
        end

        if (client:GetCharacter() ~= character) then
          client:Notify("You switched characters before the alliance creation process could finish.")
          release()
          return
        end

        client:SetAlliance({
          id = allianceId,
          name = allianceName,
        })
        character:TakeMoney(allianceCost, "creating an alliance")

        client:Notify("You have created the '" .. allianceName .. "' alliance.")
        ix.log.Add(client, "allianceCreated", allianceName)

        net.Start("AllianceForceUpdate")
        net.Send(client)

        release()
      end)
    end)
    query:Execute()
  end)

  if (not canRun) then
    client:Notify("You are already creating an alliance!")

    return
  end
end

function Schema.alliance.RequestKick(client, member)
  if (Schema.util.Throttle("RequestKick", 5, client)) then
    client:Notify("Please wait before trying to kick a member again.")

    return
  end

  if (not client:GetAllianceCanManageRoster()) then
    client:Notify("You are not allowed to kick members from the alliance!")
    return
  end

  if (member:GetAllianceRank() == client:GetAllianceRank()) then
    client:Notify("You cannot kick this member as they have the same rank as you.")
    return
  end

  if (member:GetAllianceRank() > client:GetAllianceRank()) then
    client:Notify("You cannot kick this member as they have a higher rank than you.")
    return
  end

  local alliance = client:GetAlliance()
  local memberAlliance = member:GetAlliance()

  if (not memberAlliance or memberAlliance.id ~= alliance.id) then
    client:Notify(member:Name() .. " is not in your alliance!")
    return
  end

  local memberCharacter = member:GetCharacter()

  if (not memberCharacter) then
    client:Notify("This player is not valid!")
    return
  end

  local canRun = Schema.alliance.RemoveMember(alliance.id, memberCharacter:GetID(), function(success, reason)
    if (not IsValid(client)) then
      return
    end

    if (not success) then
      client:Notify("Failed to kick member: " .. reason)
      return
    end

    if (not IsValid(member)) then
      client:Notify("The member you tried to kick is no longer valid.")
      return
    end

    client:Notify("You have kicked " .. member:Name() .. " from the '" .. alliance.name .. "' alliance.")
    member:Notify("You have been kicked from the '" .. alliance.name .. "' alliance.")
    ix.log.Add(client, "allianceKicked", member, alliance.name)

    member:SetAlliance(nil)
    Schema.alliance.RequestSendMembersToAlliance(alliance.id)
  end)

  if (not canRun) then
    client:Notify("Somebody is already modifying the alliance members. Please wait a moment and try again.")
  end
end

function Schema.alliance.RequestSetRank(client, member, rank)
  if (Schema.util.Throttle("RequestSetRank", 5, client)) then
    client:Notify("Please wait before trying to change a member's rank.")

    return
  end

  local alliance = client:GetAlliance()
  local memberAlliance = member:GetAlliance()

  if (not memberAlliance or memberAlliance.id ~= alliance.id) then
    client:Notify(member:Name() .. " is not in your alliance!")
    return
  end

  if (not rank or rank < RANK_RECRUIT or rank > RANK_GENERAL) then
    client:Notify("You entered an invalid rank!")
    return
  end

  local clientRank = client:GetAllianceRank()
  local rankIsLower = rank < member:GetAllianceRank()
  local canSetRank = (clientRank >= RANK_LIEUTENANT and rankIsLower) or (clientRank == RANK_GENERAL)

  if (not canSetRank) then
    client:Notify("You cannot set this rank!")
    return
  end

  -- If the leader tries to demote themselves, reject it
  if (clientRank == RANK_GENERAL and member == client) then
    client:Notify("You cannot demote yourself!")
    return
  end

  local canRun = Schema.alliance.SetMemberRank(alliance.id, member:GetCharacter():GetID(), rank,
    function(success, reason)
      if (not IsValid(client)) then
        return
      end

      if (not success) then
        client:Notify("Failed to change member rank: " .. reason)
        return
      end

      if (not IsValid(member)) then
        client:Notify("The member you tried to modify is no longer valid.")
        return
      end

      client:Notify("You have set " ..
        member:Name() .. " to the rank of " .. RANKS[rank] .. " in the '" .. alliance.name .. "' alliance.")
      member:Notify("You have been set to the rank of " ..
        RANKS[rank] .. " in the '" .. alliance.name .. "' alliance.")
      ix.log.Add(client, "allianceRankSet", member, RANKS[rank], alliance.name)

      member:SetAllianceRank(rank)
      Schema.alliance.RequestSendMembersToAlliance(alliance.id)
    end)

  if (not canRun) then
    client:Notify("Somebody is already modifying the alliance members. Please wait a moment and try again.")
  end
end

function Schema.alliance.GetAllMembers(allianceId, callback)
  -- TODO: Cache this data in memory instead of doing a query every time
  local query

  query = mysql:Select("exp_alliances")
  query:Select("members")
  query:Where("alliance_id", allianceId)
  query:Callback(function(result)
    if (not result or #result < 1) then
      callback({})
      return
    end

    local members = util.JSONToTable(result[1].members) or {}
    callback(members)
  end)
  query:Execute()
end

function Schema.alliance.RequestSendMembers(client)
  if (Schema.util.Throttle("RequestSendMembers", 5, client)) then
    net.Start("AllianceRequestUpdateMembersDeclined")
    net.Send(client)
    return
  end

  local alliance = client:GetAlliance()

  if (not alliance) then
    -- Happens when they leave the alliance while a request is ongoing
    return
  end

  Schema.alliance.GetAllMembers(alliance.id, function(members)
    if (not IsValid(client)) then
      return
    end

    if (#members == 0) then
      client:Notify("Your alliance does not exist anymore!")
      return
    end

    net.Start("AllianceUpdateMembers")
    net.WriteUInt(alliance.id, 32)
    net.WriteTable(members)
    net.Send(client)
  end)
end

net.Receive("AllianceRequestUpdateMembers", function(len, client)
  Schema.alliance.RequestSendMembers(client)
end)

--- Inform all alliance members of the current members in the alliance.
function Schema.alliance.RequestSendMembersToAlliance(allianceId)
  Schema.alliance.GetAllMembers(allianceId, function(members)
    local onlineMembers = Schema.alliance.GetOnlineMembers(allianceId)

    if (#members == 0) then
      return
    end

    net.Start("AllianceUpdateMembers")
    net.WriteUInt(allianceId, 32)
    net.WriteTable(members)
    net.Send(onlineMembers)
  end)
end

function Schema.alliance.RequestInviteMember(client, member)
  if (Schema.util.Throttle("RequestInviteMember", 5, client)) then
    client:Notify("Please wait before trying to invite a member again.")

    return
  end

  local alliance = client:GetAlliance()

  if (not alliance) then
    client:Notify("You are not in an alliance!")
    return
  end

  if (not client:GetAllianceCanManageRoster()) then
    client:Notify("You are not allowed to invite members to the alliance!")
    return
  end

  local memberCharacter = member:GetCharacter()

  if (not memberCharacter) then
    client:Notify("This player is not valid!")
    return
  end

  local memberAlliance = member:GetAlliance()

  if (memberAlliance) then
    client:Notify(member:Name() .. " is already in an alliance!")
    return
  end

  member.expAllianceInvites = member.expAllianceInvites or {}

  -- Only have one invite per alliance active at a time
  if (member.expAllianceInvites[alliance.id]) then
    client:Notify(member:Name() .. " has already been invited to this alliance!")
    return
  end

  -- Prevent spamming invites by tracking already declined invites
  member.expAllianceInvitesDeclined = member.expAllianceInvitesDeclined or {}

  if (member.expAllianceInvitesDeclined[alliance.id]) then
    client:Notify(member:Name() .. " has already declined an invite to this alliance!")
    return
  end

  member.expAllianceInvites[alliance.id] = client

  client:Notify("You have invited " .. member:Name() .. " to the '" .. alliance.name .. "' alliance.")
  member:Notify(client:Name() ..
    " has invited you to the '" .. alliance.name .. "' alliance. Go to the alliance panel to accept.")
  ix.log.Add(client, "allianceInvited", member, alliance.name)

  net.Start("AllianceMemberInvitation")
  net.WriteUInt(alliance.id, 32)
  net.WriteString(alliance.name)
  net.Send(member)
end

net.Receive("AllianceRequestInviteMember", function(len, client)
  local member = net.ReadEntity()

  Schema.alliance.RequestInviteMember(client, member)
end)

function Schema.alliance.RequestInviteAccept(client, allianceId)
  if (Schema.util.Throttle("RequestInviteAccept", 5, client)) then
    client:Notify("Please wait before trying to accept an alliance invite again.")

    return
  end

  client.expAllianceInvites = client.expAllianceInvites or {}

  if (not client.expAllianceInvites[allianceId]) then
    client:Notify("You do not have an invite to this alliance!")
    return
  end

  local alliance = client:GetAlliance()

  if (alliance) then
    client:Notify("You are already in an alliance!")
    return
  end

  local canRun = Schema.alliance.AddMember(allianceId, client:GetCharacter():GetID(), client:GetCharacter():GetName(),
    RANK_RECRUIT,
    function(success, reason, alliance)
      if (not IsValid(client)) then
        return
      end

      if (not success) then
        client:Notify("Failed to join alliance: " .. reason)
        return
      end

      local inviter = client.expAllianceInvites[allianceId]

      if (IsValid(inviter)) then
        Schema.achievement.Progress("the_don", inviter, client:SteamID64())
        Schema.achievement.Progress("alliance_architect", inviter, client:SteamID64())
        inviter:Notify(client:Name() ..
          " has accepted your invitation to join the '" .. inviter:GetAlliance().name .. "' alliance.")
      end

      local allianceName = alliance.name
      client:SetAlliance({
        id = allianceId,
        name = alliance.name,
      })
      client:SetAllianceRank(RANK_RECRUIT)

      client:Notify("You have joined the '" .. allianceName .. "' alliance.")
      ix.log.Add(client, "allianceJoined", allianceName)
      Schema.alliance.RequestSendMembersToAlliance(allianceId)
    end)

  if (not canRun) then
    client:Notify("Somebody is already modifying the alliance members. Please wait a moment and try again.")
  end
end

net.Receive("AllianceRequestInviteAccept", function(length, client)
  local allianceId = net.ReadUInt(32)

  Schema.alliance.RequestInviteAccept(client, allianceId)
end)

function Schema.alliance.RequestInviteDecline(client, allianceId)
  if (Schema.util.Throttle("RequestInviteDecline", 5, client)) then
    client:Notify("Please wait before trying to decline an alliance invite again.")

    return
  end

  client.expAllianceInvites = client.expAllianceInvites or {}

  if (not client.expAllianceInvites[allianceId]) then
    client:Notify("You do not have an invite to this alliance!")
    return
  end

  local inviter = client.expAllianceInvites[allianceId]

  if (IsValid(inviter)) then
    inviter:Notify(client:Name() ..
      " has declined your invitation to join the '" .. inviter:GetAlliance().name .. "' alliance. "
      .. "You can invite them again after they rejoin the server."
    )
  end

  client.expAllianceInvites[allianceId] = nil

  client.expAllianceInvitesDeclined = client.expAllianceInvitesDeclined or {}
  client.expAllianceInvitesDeclined[allianceId] = true

  client:Notify("You have declined the invite to the alliance.")
  net.Start("AllianceInviteDeclined")
  net.WriteUInt(allianceId, 32)
  net.Send(client)
end

net.Receive("AllianceRequestInviteDecline", function(length, client)
  local allianceId = net.ReadUInt(32)

  Schema.alliance.RequestInviteDecline(client, allianceId)
end)

function Schema.alliance.RequestLeave(client)
  if (Schema.util.Throttle("RequestLeave", 5, client)) then
    client:Notify("Please wait before trying to leave an alliance again.")

    return
  end

  local alliance = client:GetAlliance()

  if (not alliance) then
    client:Notify("You are not in an alliance!")
    return
  end

  local canRun = Schema.alliance.RemoveMember(alliance.id, client:GetCharacter():GetID(), function(success, reason)
    if (not success) then
      client:Notify("Failed to leave alliance: " .. reason)
      return
    end

    client:SetAlliance(nil)

    client:Notify("You have left the '" .. alliance.name .. "' alliance.")
    ix.log.Add(client, "allianceLeft", alliance.name)
    Schema.alliance.RequestSendMembersToAlliance(alliance.id)
  end)

  if (not canRun) then
    client:Notify("Somebody is already modifying the alliance members. Please wait a moment and try again.")
  end
end
