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

CreateFont("HL2MPBig", {
    font = "HL2MP",
    extended = false,
    size = ScrW() * 0.1,
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

local AddShouldDraw, RemoveHUD = nil, nil
local ScaleVec = Vector(-1, 1, 1)
local x, y = ScrW() * 0.8, ScrH() * 0.97 -- make this dynamic later
local TranslateVec = Vector(x, y, 0)
local color_grey = Color(200, 200, 200)
local function AddMOHHud()
    AddShouldDraw()
    local Weapons = {
        ["weapon_357"] = ".",
        ["weapon_ar2"] = "2",
        ["weapon_crossbow"] = "1",
        ["weapon_pistol"] = "-",
        ["weapon_shotgun"] = "0",
        ["weapon_smg1"] = "/",
        ["weapon_grav"] = "",
    }

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
        local text = Weapons[weap:GetClass()]
        if not text then return end
        -- from https://wiki.facepunch.com/gmod/VMatrix:IsZero#example
        local vm = ply:GetViewModel()
        if not IsValid(vm) then return false end
        local seq = vm:GetSequence()
        local act = vm:GetSequenceActivity(seq)
        local IsReloading = false
        if act == ACT_VM_RELOAD then IsReloading = true end
        -- 
        --local SeqDuration = vm:SequenceDuration(seq)
        local SeqProgress = 1
        if IsReloading == true then --
            SeqProgress = vm:GetCycle()
        end

        surface.SetFont("HL2MPBig")
        local w, h = surface.GetTextSize(text)
        --
        render.PushFilterMag(TEXFILTER.ANISOTROPIC)
        render.PushFilterMin(TEXFILTER.ANISOTROPIC)
        local m = Matrix()
        m:Translate(TranslateVec)
        m:Scale(ScaleVec)
        m:Translate(Vector(-w / 2, -h / 2, 0))
        cam.PushModelMatrix(m, true)
        render.CullMode(MATERIAL_CULLMODE_CW)
        local col = (IsReloading == false and color_white) or color_grey
        draw.SimpleText(text, "HL2MPBig", 0, 0, col)
        if IsReloading == true then
            --surface.SetDrawColor(color_grey)
            local FontHeightOffset = ScrH() * 0.085
            local FillHeight = h * SeqProgress
            render.SetScissorRect(0, y + (h - FillHeight) - FontHeightOffset, x + w, y + (h - FontHeightOffset), true)
            draw.SimpleText(text, "HL2MPBig", 0, 0, color_white)
            render.SetScissorRect(0, 0, 0, 0, false)
        end

        render.CullMode(MATERIAL_CULLMODE_CCW)
        cam.PopModelMatrix()
        render.PopFilterMag()
        render.PopFilterMin()
    end)
end

RemoveHUD = function()
    hook.Remove("HUDShouldDraw", "rv_hud")
    hook.Remove("HUDPaint", "rv_hud")
end

local HUDType = 1 -- determined from convar later 
local HUDTypes = {
    ["0"] = {
        ["AddFunction"] = RemoveHUD
    },
    ["1"] = {
        ["ElementsToHide"] = {
            ["CHudBattery"] = true,
            ["CHudHealth"] = true,
            ["CHudAmmo"] = true,
            ["CHudSecondaryAmmo"] = true,
        },
        ["AddFunction"] = AddMOHHud,
    }
}

local function BadHUDElements(HUDtype, HUDElement)
    if not HUDTypes[HUDtype]["ElementsToHide"] then return end
    if HUDTypes[HUDtype]["ElementsToHide"][HUDElement] then --
        return false
    end
end

AddShouldDraw = function() hook.Add("HUDShouldDraw", "rv_hud", function(name) return BadHUDElements(HUDType, name) end) end
local rv_hud = CreateClientConVar("rv_hud", "0", true, false, "Set hud type, 1 = ETHUD", 0)
cvars.AddChangeCallback("rv_hud", function(convar, old, new)
    HUDType = new
    if not HUDTypes[HUDType] then return end
    HUDTypes[HUDType]["AddFunction"]()
end, "rv_hud")

RemoveHUD()
HUDType = rv_hud:GetString()
HUDTypes[HUDType]["AddFunction"]()
