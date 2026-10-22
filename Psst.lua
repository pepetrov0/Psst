-- Psst! - whisper the secret word, get invited.
-- WoW WotLK 3.3.5 (Interface 30300)

local ADDON = "Psst!"
local COOLDOWN = 5        -- seconds between handling whispers from the same player
local CONVERT_TIMEOUT = 5 -- seconds to wait for party -> raid conversion

local defaults = { enabled = true, word = "" }

local pending = nil       -- { name = "...", expires = time } while waiting for raid conversion
local lastSeen = {}       -- [lowername] = time

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff" .. ADDON .. "|r " .. msg)
end

local function Trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Is this player already in my party/raid?
local function InMyGroup(name)
    local lname = name:lower()
    local raidCount = GetNumRaidMembers()
    if raidCount > 0 then
        for i = 1, raidCount do
            local n = UnitName("raid" .. i)
            if n and n:lower() == lname then return true end
        end
    else
        for i = 1, GetNumPartyMembers() do
            local n = UnitName("party" .. i)
            if n and n:lower() == lname then return true end
        end
    end
    return false
end

local function IsLeader()
    if GetNumRaidMembers() > 0 then
        return IsRaidLeader()
    elseif GetNumPartyMembers() > 0 then
        return IsPartyLeader()
    end
    return true -- solo: you can always invite
end

local function CanInviteInRaid()
    return IsRaidLeader() or IsRaidOfficer()
end

local function TryInvite(name)
    local raidCount = GetNumRaidMembers()
    local partyCount = GetNumPartyMembers()

    -- Already in a raid
    if raidCount > 0 then
        if not CanInviteInRaid() then
            Print("Can't invite " .. name .. ": you're not raid leader or assistant.")
            return
        end
        if raidCount >= 40 then
            Print("Can't invite " .. name .. ": raid is full (40/40).")
            return
        end
        InviteUnit(name)
        Print("Invited " .. name .. " to the raid.")
        return
    end

    -- In a party
    if partyCount > 0 then
        if not IsPartyLeader() then
            Print("Can't invite " .. name .. ": you're not the party leader.")
            return
        end
        if partyCount + 1 >= 5 then
            -- 5/5: convert to raid first, then invite once the roster updates
            pending = { name = name, expires = GetTime() + CONVERT_TIMEOUT }
            ConvertToRaid()
            Print("Party full, converting to raid for " .. name .. "...")
            return
        end
        InviteUnit(name)
        Print("Invited " .. name .. " to the party.")
        return
    end

    -- Solo
    InviteUnit(name)
    Print("Invited " .. name .. ".")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")

frame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 ~= "Psst" then return end
        PsstDB = PsstDB or {}
        for k, v in pairs(defaults) do
            if PsstDB[k] == nil then PsstDB[k] = v end
        end
        if PsstDB.word == "" then
            Print("loaded. Set your secret with |cffffff00/psst word <secret>|r")
        else
            Print("loaded. " .. (PsstDB.enabled and "Enabled." or "Disabled."))
        end

    elseif event == "CHAT_MSG_WHISPER" then
        if not PsstDB or not PsstDB.enabled or PsstDB.word == "" then return end
        local msg, sender = arg1, arg2
        if not msg or not sender then return end
        if sender == UnitName("player") then return end
        if Trim(msg):lower() ~= PsstDB.word:lower() then return end

        local key = sender:lower()
        local now = GetTime()
        if lastSeen[key] and (now - lastSeen[key]) < COOLDOWN then return end
        lastSeen[key] = now

        if InMyGroup(sender) then return end
        TryInvite(sender)

    elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
        -- Finish the invite once the party has become a raid
        if pending and GetNumRaidMembers() > 0 then
            local name = pending.name
            pending = nil
            if CanInviteInRaid() then
                InviteUnit(name)
                Print("Invited " .. name .. " to the raid.")
            end
        end
    end
end)

-- Expire a pending invite if the raid conversion never happened
frame:SetScript("OnUpdate", function(self, elapsed)
    if pending and GetTime() > pending.expires then
        Print("Raid conversion didn't go through, invite for " .. pending.name .. " cancelled.")
        pending = nil
    end
end)

SLASH_PSST1 = "/psst"
SlashCmdList["PSST"] = function(input)
    local cmd, rest = (input or ""):match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "word" then
        rest = Trim(rest)
        if rest == "" then
            Print("Usage: /psst word <secret>")
        else
            PsstDB.word = rest
            Print("Secret word set to: |cffffff00" .. rest .. "|r")
        end
    elseif cmd == "on" then
        PsstDB.enabled = true
        Print("Enabled.")
    elseif cmd == "off" then
        PsstDB.enabled = false
        Print("Disabled.")
    elseif cmd == "toggle" then
        PsstDB.enabled = not PsstDB.enabled
        Print(PsstDB.enabled and "Enabled." or "Disabled.")
    else
        Print((PsstDB.enabled and "Enabled" or "Disabled") ..
            ", secret word: " .. (PsstDB.word ~= "" and ("|cffffff00" .. PsstDB.word .. "|r") or "(not set)"))
        Print("Commands: /psst word <secret>, /psst on, /psst off, /psst toggle")
    end
end
