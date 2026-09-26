local FontsMade = {}
local function CreateFont(...)
    local args = {...}
    local fontname = args[1]
    if FontsMade[fontname] == true then -- already made this font dont waste mem
        return
    end

    FontsMade[fontname] = true
    surface.CreateFont(unpack(args))
end

local function AddHUD()
    local ElementsToHide = {
        ["CHudBattery"] = true,
        ["CHudHealth"] = true,
        ["CHudAmmo"] = true,
        ["CHudSecondaryAmmo"] = true,
    }

    CreateFont("Arial_Black", {
        font = "Arial Narrow Bold",
        extended = false,
        size = 45,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    })

    local function DropShadowArial(text, font, x, y, col, xalign, yalign) -- moh has a black shadow for its arial hud element
        draw.SimpleText(text, font, x + 1, y + 1, color_black, xalign, yalign)
        draw.SimpleText(text, font, x + 2, y + 2, color_black, xalign, yalign)
        draw.SimpleText(text, font, x, y, col, xalign, yalign)
    end

    local HUDType = 1
    local function MOHHUD(name)
        if ElementsToHide[name] then -- get rid of stuff were overriding
            return false
        end

        hook.Add("HUDPaint", "rv_hud", function()
            if LocalPlayer():Alive() == false then return end
            local HeightOffset = ScrH() * 0.015
            surface.SetDrawColor(color_white)
            surface.DrawRect(ScrW() * 0.5 - 1, 0, 1, ScrH())
            surface.DrawRect(ScrW() * 0.5 - 1, 0, 1, ScrH())
            local ply = LocalPlayer()
            local weap = ply:GetActiveWeapon()
            --local PrimaryAmmoType = weap:GetPrimaryAmmoType()
            --local PrimaryAmmoCount = ply:GetAmmoCount(PrimaryAmmoType)
            local clip1 = weap:Clip1()
            local maxclip1 = weap:GetMaxClip1()
            --local clip2 = weap:Clip2()
            local SecondaryAmmoType = weap:GetSecondaryAmmoType()
            local SecondaryAmmoCount = ply:GetAmmoCount(SecondaryAmmoType)
            DropShadowArial(ply:Health() .. " HP", "Arial_Black", ScrW() * 0.5, ScrH() * 0.94 - HeightOffset, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            DropShadowArial(clip1 .. "/" .. maxclip1, "Arial_Black", ScrW() * 0.5, ScrH() - HeightOffset, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            DropShadowArial(SecondaryAmmoCount .. " ALT", "Arial_Black", ScrW() * 0.43, ScrH() - HeightOffset, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            DropShadowArial(ply:Armor() .. " AP", "Arial_Black", ScrW() * 0.57, ScrH() - HeightOffset, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        end)
    end

    hook.Add("HUDShouldDraw", "rv_hud", function(name)
        local Return = nil
        if HUDType == 1 then
            Return = MOHHUD(name)
        elseif HUDType == 2 then
            --
        end
        return Return
    end)
end

local function RemoveHUD()
    hook.Remove("HUDShouldDraw", "rv_hud")
    hook.Remove("HUDPaint", "rv_hud")
end

AddHUD()
