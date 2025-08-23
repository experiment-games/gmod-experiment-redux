local PLUGIN = PLUGIN

local arrowMaterial = Material("experiment-redux/arrow.png")
local arrowForwardMaterial = Material("experiment-redux/arrow_forward.png") -- From the perspective of the player
local arrowBackwardMaterial = Material("experiment-redux/arrow_backward.png")

local PANEL = {}

function PANEL:Init()
  self:Dock(FILL)
  self:SetPos(0, 0)
end

function PANEL:SetMonitor(monitor)
  self.monitor = monitor
end

function PANEL:DrawDistanceText(distance, width, height)
  local font = "expMonitorLarge"
  local scale = self.monitor:GetMonitorScale()

  if (scale < 0.1) then
    font = "expMonitorSmall"
  end

  local distanceCentimeters = Schema.util.UnitToCentimeters(distance)
  local distanceRounded = math.Round(distanceCentimeters / 100)
  local text = distanceRounded == 0 and "Right here!" or
      (distanceRounded .. (distanceRounded == 1 and " meter" or " meters"))
  local textWidth, textHeight = Schema.GetCachedTextSize(font, text)

  surface.SetTextColor(255, 255, 255, 90)
  surface.SetFont(font)
  surface.SetTextPos((width * .5) - (textWidth * .5), height * .15)
  surface.DrawText(text)
end

function PANEL:DrawDirectionArrow(direction, width, height)
  local rotation
  local correctedDirection = direction
  local monitorAngles = self.monitor:GetAngles()

  correctedDirection:Rotate(Angle(0, monitorAngles.y * -1, 0))
  local x, y, z = math.Round(correctedDirection.x), math.Round(correctedDirection.y), math.Round(correctedDirection.z)

  if (y == 0 and z == 1) then
    rotation = 90
  elseif (y == 1 and z == 1) then
    rotation = 45
  elseif (y == 1 and z == 0) then
    rotation = 0
  elseif (y == 1 and z == -1) then
    rotation = -45
  elseif (y == 0 and z == -1) then
    rotation = -90
  elseif (y == -1 and z == -1) then
    rotation = -135
  elseif (y == -1 and z == 0) then
    rotation = 180
  elseif (y == -1 and z == 1) then
    rotation = 135
  end

  surface.SetDrawColor(255, 255, 255, 90)
  if (rotation) then
    surface.SetMaterial(arrowMaterial)
    surface.DrawTexturedRectRotated(width * .5, height * .5, width * .8, height * .8, rotation)
  else
    if (x == 1) then
      surface.SetMaterial(arrowBackwardMaterial)
    elseif (x == -1) then
      surface.SetMaterial(arrowForwardMaterial)
    else
      drawCircle(width * .5, height * .5, width * .8, 18)
    end

    surface.DrawTexturedRect(0, 0, width, height)
  end
end

function PANEL:Paint(width, height)
  local monitor = self.monitor
  if (not monitor) then return end

  local direction, distance = PLUGIN:GetDirectionToTarget(monitor)
  if (not direction) then return end

  -- Cheat a bit so the player doesnt have to be dead center of the moniotor
  if (distance < 512) then
    distance = 0
  end

  self:DrawDirectionArrow(direction, width, height)
  self:DrawDistanceText(distance, width, height)
end

vgui.Register("expMonitorTarget", PANEL, "Panel")
