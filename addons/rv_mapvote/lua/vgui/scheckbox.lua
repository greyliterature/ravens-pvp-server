local PANEL = {}
function PANEL:Init()
    self.ClickFunction = function() print("I am " .. ((self.bool == false and "On ") or "Off ") .. " . . .Override my function. . . ") end
    self.BoxThickness = 2
    self.BoxColor = color_white
    self.bool = false
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(self.BoxColor)
    surface.DrawOutlinedRect(0, 0, w, h, self.BoxThickness)
    if self.bool == true then
        -- manually made again, but from https://github.com/greyliterature/FSpectate/blob/0c63e3f5975e48b4f2156ecc69b0a4edabbce470/lua/fspectate/cl_init.lua#L513
        draw.NoTexture()
        surface.DrawTexturedRectRotated(w * 0.64, h * 0.5, w * 0.17, h * 0.5, -45)
        surface.DrawTexturedRectRotated(w * 0.40, h * 0.5, w * 0.17, h * 0.2, 45)
    end
end

function PANEL:SetFunction(func)
    self.ClickFunction = func
end

function PANEL:SetOn(bool)
    self.bool = bool
end

function PANEL:Toggle()
    self.bool = not self.bool
end

function PANEL:OnMousePressed(keyCode)
    if keyCode == MOUSE_LEFT then
        self:Toggle()
        self.ClickFunction(bool)
    end
end

vgui.Register("SCheckBox", PANEL, "DPanel")
