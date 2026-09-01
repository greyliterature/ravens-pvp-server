--[[
MsgC([[
    API VERSION: https://translate.googleapis.com/ (API_3) | TRANSLATOR RESULTS MAY NOT BE ACCURATE AS https://translate.googleapis.com
    google translator for garry's mod
    developed by lenn with the help of the world wide web
    what it does: it's a realtime translator for garry's mod that translates most chat messages as well as your own messages using the console
    what it also does: it uses known endpoints from google to translate any type of text into something readable in english
    notes: it is not 100% flawless or accurate or anyway, captchas/blocked requests are bound to happen at anytime, there are anti-spam measures to prevent this from happening too quickly
    notes: enter find google in console to get started
]\]
)
--]]
local function urlencode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w%-_%.~])", function(c) return string.format("%%%02X", string.byte(c)) end)
        str = string.gsub(str, "[！。.!]", ",")
        str = string.gsub(str, " ", "+")
    end
    return str
end

local TranslateTable = {
    -- so you dont have to manually type in the ISO 639 names 
    -- this table is chatgpt, it seems accurate enough
    ["abkhaz"] = "ab",
    ["acehnese"] = "ace",
    ["acholi"] = "ach",
    ["afar"] = "ay",
    ["afrikaans"] = "af",
    ["albanian"] = "sq",
    ["alur"] = "alz",
    ["amharic"] = "am",
    ["arabic"] = "ar",
    ["armenian"] = "hy",
    ["assamese"] = "as",
    ["awadhi"] = "awa",
    ["aymara"] = "ay",
    ["azerbaijani"] = "az",
    ["balinese"] = "ban",
    ["baluchi"] = "bal",
    ["bambara"] = "bm",
    ["bashkir"] = "ba",
    ["basque"] = "eu",
    ["batakkaro"] = "btx",
    ["bataksimalungun"] = "bts",
    ["batak toba"] = "bbc",
    ["belarusian"] = "be",
    ["bemba"] = "bem",
    ["bengali"] = "bn",
    ["betawi"] = "bew",
    ["bhojpuri"] = "bho",
    ["bikol"] = "bik",
    ["bosnian"] = "bs",
    ["breton"] = "br",
    ["bulgarian"] = "bg",
    ["buryat"] = "bua",
    ["cantonese"] = "yue",
    ["catalan"] = "ca",
    ["cebuano"] = "ceb",
    ["chinesesimplified"] = "zh-CN",
    ["chinesetraditional"] = "zh-TW",
    ["chuvash"] = "cv",
    ["corsican"] = "co",
    ["crimean tatar"] = "crh",
    ["croatian"] = "hr",
    ["czech"] = "cs",
    ["danish"] = "da",
    ["dinka"] = "din",
    ["dhivehi"] = "dv",
    ["dogri"] = "doi",
    ["dombe"] = "dov",
    ["dutch"] = "nl",
    ["dzongkha"] = "dz",
    ["english"] = "en",
    ["esperanto"] = "eo",
    ["estonian"] = "et",
    ["ewe"] = "ee",
    ["fijian"] = "fj",
    ["filipino"] = "fil",
    ["finnish"] = "fi",
    ["french"] = "fr",
    ["frenchcanadian"] = "fr-CA",
    ["frisian"] = "fy",
    ["fulfulde"] = "ff",
    ["ga"] = "gaa",
    ["galician"] = "gl",
    ["ganda"] = "lg",
    ["georgian"] = "ka",
    ["german"] = "de",
    ["greek"] = "el",
    ["guarani"] = "gn",
    ["gujarati"] = "gu",
    ["haitian creole"] = "ht",
    ["hakha chin"] = "cnh",
    ["hausa"] = "ha",
    ["hawaiian"] = "haw",
    ["hebrew"] = "he",
    ["hebrew (iw)"] = "iw", -- legacy code
    ["hiligaynon"] = "hil",
    ["hindi"] = "hi",
    ["hmong"] = "hmn",
    ["hungarian"] = "hu",
    ["icelandic"] = "is",
    ["igbo"] = "ig",
    ["ilocano"] = "ilo",
    ["indonesian"] = "id",
    ["irish"] = "ga",
    ["italian"] = "it",
    ["japanese"] = "ja",
    ["javanese"] = "jv",
    ["kannada"] = "kn",
    ["kazakh"] = "kk",
    ["khmer"] = "km",
    ["kinyarwanda"] = "rw",
    ["konkani"] = "gom", -- Meiteilon / Manipuri alias
    ["korean"] = "ko",
    ["krio"] = "kri",
    ["kurdish"] = "ku",
    ["kurdish (sorani)"] = "ckb",
    ["kyrgyz"] = "ky",
    ["lao"] = "lo",
    ["latin"] = "la",
    ["latgalian"] = "ltg",
    ["latvian"] = "lv",
    ["lingala"] = "ln",
    ["lithuanian"] = "lt",
    ["luganda"] = "lg",
    ["luxembourgish"] = "lb",
    ["macedonian"] = "mk",
    ["maithili"] = "mai",
    ["malagasy"] = "mg",
    ["malay"] = "ms",
    ["malayalam"] = "ml",
    ["maltese"] = "mt",
    ["maori"] = "mi",
    ["marathi"] = "mr",
    ["meiteilon (manipuri)"] = "mni-Mtei",
    ["minang"] = "min",
    ["mizo"] = "lus",
    ["mongolian"] = "mn",
    ["myanmar (burmese)"] = "my",
    ["na'vi"] = "nv", -- (not official but example; adjust if needed)
    ["nepali"] = "ne",
    ["norwegian"] = "no",
    ["nyanja"] = "ny",
    ["odia"] = "or",
    ["oromo"] = "om",
    ["pashto"] = "ps",
    ["persian"] = "fa",
    ["polish"] = "pl",
    ["portuguese"] = "pt",
    ["portuguese (brazil)"] = "pt-BR",
    ["portuguese (portugal)"] = "pt-PT",
    ["punjabi"] = "pa",
    ["punjabi (shahmukhi)"] = "pa-Arab",
    ["quechua"] = "qu",
    ["romani"] = "rom",
    ["romanian"] = "ro",
    ["rundi"] = "rn",
    ["russian"] = "ru",
    ["samoan"] = "sm",
    ["sango"] = "sg",
    ["sanskrit"] = "sa",
    ["scots gaelic"] = "gd",
    ["serbian"] = "sr",
    ["sesotho"] = "st",
    ["seychellois creole"] = "crs",
    ["shn"] = "shn",
    ["shona"] = "sn",
    ["sicilian"] = "scn",
    ["silesian"] = "szl",
    ["sindhi"] = "sd",
    ["sinhala"] = "si",
    ["slovak"] = "sk",
    ["slovenian"] = "sl",
    ["somali"] = "so",
    ["spanish"] = "es",
    ["sundanese"] = "su",
    ["swahili"] = "sw",
    ["swati"] = "ss",
    ["swedish"] = "sv",
    ["tajik"] = "tg",
    ["tamil"] = "ta",
    ["tatar"] = "tt",
    ["telugu"] = "te",
    ["tetum"] = "tet",
    ["thai"] = "th",
    ["tigrinya"] = "ti",
    ["tsonga"] = "ts",
    ["tswana"] = "tn",
    ["twi (akan)"] = "ak",
    ["ukrainian"] = "uk",
    ["urdu"] = "ur",
    ["uyghur"] = "ug",
    ["uzbek"] = "uz",
    ["vietnamese"] = "vi",
    ["welsh"] = "cy",
    ["xhosa"] = "xh",
    ["yiddish"] = "yi",
    ["yoruba"] = "yo",
    ["yucatec maya"] = "yua",
    ["zulu"] = "zu",
}

local function translate(TargetLanguage, SourceLanguage, Message, callback)
    if TargetLanguage == "" or TargetLanguage == " " then
        callback(nil, nil, nil, "(NOTL)")
        return
    end

    if not Message or Message == "" then
        callback(nil, nil, nil, "(NOMSG)")
        return
    end

    MakeQueue(function()
        TargetLanguage = string.lower(TargetLanguage)
        SourceLanguage = string.lower(SourceLanguage)
        local TargetLanguageISO = TranslateTable[TargetLanguage] or TargetLanguage
        --if SourceLanguage then
        SourceLanguageISO = TranslateTable[SourceLanguage] or SourceLanguage
        --else
        --    SourcelanguageISO = "auto"
        --end
        local q = "" .. Message .. ""
        local argument = Message
        local v_encoded = urlencode("" .. argument .. "")
        local data = {
            client = "gtx",
            dt = "t",
            sl = SourceLanguageISO,
            tl = TargetLanguageISO,
            q = q
        }

        local headers = {
            [":authority"] = "translate.googleapis.com",
            [":method"] = "GET",
            [":path"] = string.format("/translate_a/single?client=gtx&dt=t&sl=%s&tl=%s&q=", SourceLanguageISO, TargetLanguageISO) .. argument .. "",
            [":scheme"] = "https",
            Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            ["Accept-Language"] = "en-US,en;q=0.9",
            ["Upgrade-Insecure-Requests"] = "1"
        }

        local format = nil
        local request_body_json = util.TableToJSON(data)
        HTTP({
            url = string.format("https://translate.googleapis.com/translate_a/single?client=gtx&dt=t&sl=%s&tl=%s&q=", SourceLanguageISO, TargetLanguageISO) .. v_encoded .. "",
            method = "POST",
            headers = headers,
            type = "application/json",
            success = function(code, body, _)
                format = util.JSONToTable(body)
                if code ~= 200 then
                    callback(nil, TargetLanguageISO, SourceLanguageISO, code)
                    return
                end

                callback(format[1][1][1] .. "", TargetLanguageISO, format[3])
            end,
            body = request_body_json
        })
    end, 3, "TranslatorQueuedFunction")
end

local ChatCommands = {
    ["!t"] = function(ply, text, ...)
        local args = {...}
        translate(args[1], "AUTO", table.concat(args, " ", 2), function(translated, TL, SL, error)
            if error or table.concat(args, " ", 2) == translated then
                chat.AddText("[Fail translate code " .. (error or "(tr=te)") .. "] ", team.GetColor(ply:Team()), ply:Nick(), color_white, ": ", text)
            else
                chat.AddText("[" .. (string.upper(SL) or "N/A") .. " -> " .. (string.upper(TL) or "N/A") .. "] ", team.GetColor(ply:Team()), ply:Nick(), color_white, ": ", translated)
            end
        end)
    end,
}

CreateClientConVar("rv_translator", 1, true, false, "Whether or not to translate messages prefixed with !t.", 0, 1)
-- this is copy pasted from my haven code lazily
hook.Add("OnPlayerChat", "TranslateChatCommand", function(sender, text, teamChat, isDead)
    if GetConVar("rv_translator"):GetBool() == false then return end
    text = string.lower(text)
    local exploded = string.Explode(" ", text)
    if not exploded[2] then return end
    local command = exploded[1]
    local args = exploded
    table.remove(args, 1)
    local func = ChatCommands[command]
    if func then
        func(sender, text, unpack(args))
        return true
    end
end)