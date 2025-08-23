local PLUGIN = PLUGIN
local PANEL = {}

-- Violence inducing advertisements
function PANEL:Init()
  self:Dock(FILL)
  self:SetPos(0, 0)

  self.ads = {
    "Violence is the answer!",
    "Kill them all!",
    "Do it! End them!",
    "Obey the screens!",
    "Violence is the only way!",
    "Your purpose is to kill!",
    "Ask no questions, just kill!",
  }
  self.currentAd = 0

  self:NextAd()
end

function PANEL:NextAd()
  self:Clear()

  self.currentAd = self.currentAd + 1

  if (self.currentAd > #self.ads) then
    self.currentAd = 1
  end

  local ad = self.ads[self.currentAd]

  self:CreateAd(ad)
end

function PANEL:CreateAd(text)
  local duration = math.random(2, 5)
  self.adText = text
  self.adColor = Color(255, math.random(0, 255), math.random(0, 255))
  self.randomRotation = math.random() < 0.5 and math.random(30, 70) or math.random(-80, -34)
  self.randomScale = math.Rand(1, 2)

  timer.Simple(duration, function()
    if (not IsValid(self)) then
      return
    end
    self:NextAd()
  end)
end

function PANEL:Paint(width, height)
  -- Draw the text at an angle, glitched out
  surface.SetFont("expMonitorLarge")

  local textWidth, textHeight = surface.GetTextSize(self.adText)
  local textX, textY = width * .5 - textWidth * .5, height * .5 - textHeight * .5

  -- Draw glitching text in the background that is a lot bigger and rotated
  surface.SetTextColor(Color(self.adColor.r, self.adColor.g, self.adColor.b, 10))

  if (self.nextRandomShake == nil or CurTime() > self.nextRandomShake) then
    -- Go long periods without shaking
    self.nextRandomShake = CurTime() + (
      math.random() < .2 and math.Rand(0.5, 1) or math.Rand(2, 5)
    )
    self.randomShake = math.Rand(0.5, 1.5)
  end

  for i = 1, math.floor(3 * self.randomShake), 1 do
    local matrix = Matrix()
    matrix:Translate(Vector(width * .5, height * .5))
    matrix:Rotate(Angle(0, self.randomRotation * (self.randomShake * i), 0))
    matrix:Scale(Vector(self.randomScale * .9, self.randomScale * .9, self.randomScale * .9))
    matrix:Translate(-Vector(width * .5, height * .5))

    cam.PushModelMatrix(matrix)
    surface.SetTextPos(textX, textY)
    surface.DrawText(self.adText)
    cam.PopModelMatrix()
  end

  local scale = self.randomShake * .5

  matrix = Matrix()
  matrix:Translate(Vector(width * .5, height * .5))
  matrix:Rotate(Angle(0, self.randomRotation, 0))
  matrix:Scale(Vector(self.randomScale * scale, self.randomScale * scale, self.randomScale * scale))
  matrix:Translate(-Vector(width * .5, height * .5))

  surface.SetTextColor(self.adColor)

  cam.PushModelMatrix(matrix)
  surface.SetTextPos(textX, textY)
  surface.DrawText(self.adText)
  cam.PopModelMatrix()
end

vgui.Register("expMonitorViolenceAds", PANEL, "Panel")
