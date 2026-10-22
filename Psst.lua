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

local REPLIES = {
    "Psst, you said the magic word! Grab water, we're going in.",
    "Correct password. Your invitation is non-transferable and non-refundable.",
    "Welcome! Please ignore anything on fire.",
    "You've been added to the group. Please keep your arms and legs inside the raid at all times.",
    "Invitation accepted. Free loot rules: it's all mine.",
    "Secret word confirmed. We regret to inform you the bosses were not notified.",
    "That's the word! Bring your own resurrection stone.",
    "You're in! Wipe insurance NOT included.",
    "Password accepted. The raid is now your problem too.",
    "Welcome aboard. Do you have any prior experience surviving?",
    "Invited! Please form an orderly line behind the healers.",
    "The council has reviewed your application. Approved. Barely.",
    "You're in! Tip your healer, they take cookies.",
    "Word verified. Your repair bill is on you.",
    "Invitation sent. The guild bank thanks you in advance.",
    "Correct! Your prize: an invite. Your punishment: the same invite.",
    "You're in. Please don't stand in things. That's the whole guide.",
    "Granted entry. May your drops be purple and your wipes be rare.",
    "Welcome! We have buffs, blizzards, and mild disappointment.",
    "Invite coming. You may panic in 3... 2... 1...",
    "Word accepted. Loyalty card stamped -- 9 more invites till a free one.",
    "You're in! The last guy said that too. We don't talk about the last guy.",
    "Confirmed. Bring candles, we lean ritualistic.",
    "Invited! If you die, you never knew us.",
    "Password checks out. Welcome to the machine.",
    "You made it! The druids will see you now.",
    "Invitation on its way. Side effects may include loot and responsibility.",
    "Secret word honored. We ride at dawn. Or now. Mostly now.",
    "You're in! Please sign this imaginary waiver.",
    "Enter freely, go safely, and leave something of yourself... like your dignity.",
    "Correct! Welcome to the queue. The queue is one person. It's you.",
    "Invited. Remember: aggro is a lifestyle choice.",
    "You're in! We were just talking about you. None of it was good.",
    "Word accepted. Your seat is the one with the best view of the floor.",
    "Welcome! Our motto: wipe first, ask questions later.",
    "Invite sent. Please do not feed the tanks.",
    "You're in! Loot council meets Tuesdays. Bring snacks.",
    "Granted. Your heroism has been noted and will be exploited.",
    "Password confirmed! Please collect your complimentary epic attitude.",
    "Invited! We accept bribes at the door. You may leave.",
    "You're in! Please don't ask for the secret word again, it's embarrassing.",
    "Word matched. Initiation begins immediately.",
    "Welcome, traveler. The portal was closed. Kidding -- invite incoming.",
    "Invitation delivered. Please remain seated until the raid fully stops.",
    "Correct word! The mages have been informed. They're thrilled.",
    "You're in! First rule: nobody reads the chat. Second rule: see rule one.",
    "Verified. Your invite is oven-fresh and slightly warm.",
    "Welcome! Abandon hope, all ye who roll need on off-spec gear.",
    "Invite incoming! Please have your corpse coordinates ready.",
    "The word is correct. The adventure is questionable.",
    "You're in! DPS check begins now. Just kidding. Or am I?",
    "Confirmed. This invitation does not expire, unlike your buffs.",
    "Welcome! We're a group of professionals. It says so on our banner.",
    "Invited! Please don't pet the core hounds.",
    "Word accepted. You got invited faster than my mage gets water.",
    "You're in! The healers have been warned. They're pretending to be thrilled.",
    "Entry granted. Please wipe responsibly.",
    "Correct! Your invite was lovingly hand-crafted by an addon.",
    "Welcome aboard! Complimentary resurrections for the first five casualties.",
    "Invited! Please remain behind the tank. The tank bites.",
    "You're in! We run a tight ship. The ship is on fire, but it's tight.",
    "Word confirmed. Prepare for glory. Or a night of repairs.",
    "Verified! Please state your corpse for the record.",
    "Welcome, brave soul. Your healers have accepted the challenge.",
    "Invited! We value safety. That's why we're inviting strangers from Trade chat.",
    "The password works! Amazing. Nobody ever guesses it on the first try. Wait--",
    "You're in! We were one member short of a full raid. Now we're not.",
    "Entry approved. Loot rules: need if it glows.",
    "Correct word! Please proceed to the nearest summoning stone.",
    "Invite sent! Please don't tell the others how easy that was.",
    "You're in! Our previous group disintegrated. You're the replacement. Congratulations?",
    "Word verified. The bouncer is satisfied. The bouncer is a paladin.",
    "Welcome! Tonight's forecast: 90% chance of heroism, 10% chance of regrets.",
    "Invited! Be nice in chat or the ninjas win.",
    "Confirmed! Your invite is compliments of the secret word you just used.",
    "You're in! Welcome to the team. The team is mostly me.",
    "Entry granted. Thank you for choosing Psst! Please rate your invite 5 stars.",
    "Correct! We now pause for a brief word from our sponsor: loot.",
    "You're in! This invite has been brought to you by the word itself.",
    "Welcome! Please keep the secret word secret. That's the entire system.",
    "Invited! Please remember: the floor lava is NOT decorative.",
    "Word accepted. Your seat has been heated. It's the fire. Sorry.",
    "You're in! Welcome to the elite. Membership fee: one repair bill.",
    "Confirmed! Please don't make me use the word 'wipe' in a sentence tonight.",
    "The password is correct. You may now enter the danger zone.",
    "Invited! Bring gear, bring food, bring emotional support.",
    "Welcome! We apologize in advance for our DPS. All of it. Yes.",
    "You're in! Please act natural. Nobody here knows what natural is.",
    "Correct! The door is open. The door is also imaginary. Use the invite.",
    "Entry verified! Remember: bosses don't take prisoners. We don't take attendance.",
    "You're in! The last group photo is in the guild bank. Don't ask.",
    "Word accepted! You're officially the most qualified person here. Alarming.",
    "Invited! Please don't ask about the smell. It's the warlocks.",
    "Welcome! We have a strict no-ninja policy. Ninjas get looted last.",
    "Correct! Your invite doubles as a gym membership. The gym is running from bosses.",
    "You're in! Congratulations on the fastest background check in Azeroth.",
    "Confirmed! We laugh in the face of danger. Then we run. You'll see.",
    "Entry granted! Please don't stand in the cleave. This concludes the orientation.",
    "Word verified! The invite is free, the repairs are not.",
    "Welcome! You're now part of something bigger. It's not better. Just bigger.",
}

local function WhisperFunny(name)
    SendChatMessage(REPLIES[math.random(#REPLIES)], "WHISPER", nil, name)
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
        WhisperFunny(name)
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
        WhisperFunny(name)
        Print("Invited " .. name .. " to the party.")
        return
    end

    -- Solo
    InviteUnit(name)
    WhisperFunny(name)
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
                WhisperFunny(name)
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
