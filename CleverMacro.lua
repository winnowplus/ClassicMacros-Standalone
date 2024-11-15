--------------------------------------------------------------------------------
-- CleverMacro v1.3.1 by _brain    VERSION = 1.7                              --
--------------------------------------------------------------------------------

local lastUpdate = 0    
local currentAction
local mouseOverUnit

local actions = {}    
local macros = {}    
local sequences = {}
local currentSequence

local actionEventHandlers = {}
local mouseOverResolvers = {}

local items = {}

local CM_ScanTip

--检查是否有对应的BUFF材质
local function HasBuff(texture)
    for i = 1, 32 do
		local buff = UnitBuff("player", i)
		if buff and buff == [[Interface\Icons\]] .. texture then
			return true
		end
    end
    return false
end

--连击点
local function GetCP(cp)
	if cp == GetComboPoints("target") then
		return true
	end
	return false
end

local function Trim(s)
    if s == nil then return nil end
    local _, b = string.find(s, "^%s*")
    local e = string.find(s, "%s*$", b + 1)
    return string.sub(s, b + 1, e - 1)
end

local function Seq(_, i)
    return (i or 0) + 1
end

local function Split(s, p, trim)
    local r, o = {}, 1
    repeat
        local b, e = string.find(s, p, o)
        if b == nil then
            local sub = string.sub(s, o)
            table.insert(r, trim and Trim(sub) or sub)
            return r
        end
        if b > 1 then
            local sub = string.sub(s, o, b - 1)
            table.insert(r, trim and Trim(sub) or sub)
        else
            table.insert(r, "")
        end
        o = e + 1
    until false
end

--比较HP
local function Compare_UnitHp(v, unit)
	for hp in v do
		local HPPercent = 100 / UnitHealthMax(unit) * UnitHealth(unit)
		if string.find(hp, ">") then
			local biggerhp = Split(hp, ">")
			return HPPercent > tonumber(biggerhp[2])
		elseif string.find(hp, "<") then
			local lesshp = Split(hp, "<")
			return HPPercent < tonumber(lesshp[2])
		end
	end
end

--比较MP
local function Compare_UnitMp(v, unit)
	for mp in v do
		local MPPercent = 100 / UnitManaMax(unit) * UnitMana(unit)
		if string.find(mp, ">") then
			local biggermp = Split(mp, ">")
			return MPPercent > tonumber(biggermp[2])
		elseif string.find(mp, "<") then
			local lessmp = Split(mp, "<")
			return MPPercent < tonumber(lessmp[2])
		end
	end
end

--获取技能CD
local function GetSpellCooldownByName(spellName)
    local checkFor = function(bookType)
        local i = 1
        while true do
            local name, spellRank = GetSpellName(i, bookType)
            
            if not name then
                break
            end
            
            if name == spellName then
                local _, duration = GetSpellCooldown(i, bookType)
                return duration
            end
            
            i = i + 1
        end
        return nil
    end

    local cd = checkFor(BOOKTYPE_PET)
    if not cd then cd = checkFor(BOOKTYPE_SPELL) end
    
    return cd
end

--获取装备栏物品CD
local function GetInventoryCooldownByName(itemName)
    CM_ScanTip:SetOwner(UIParent, "ANCHOR_NONE")
    for i=0, 19 do
        CM_ScanTip:ClearLines()
        hasItem = CM_ScanTip:SetInventoryItem("player", i)
        
        if hasItem then
            local lines = CM_ScanTip:NumLines()
            
            local label = getglobal("CM_ScanTipTextLeft1")
            
            if label:GetText() == itemName then
                local _, duration, _ = GetInventoryItemCooldown("player", i)
                return duration
            end
        end
    end
    
    return nil
end

--获取背包物品CD
local function GetContainerItemCooldownByName(itemName)
    CM_ScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    
    for i = 0, 4 do
        for j = 1, GetContainerNumSlots(i) do
            CM_ScanTip:ClearLines()
            CM_ScanTip:SetBagItem(i, j)
            if CM_ScanTipTextLeft1:GetText() == itemName then
                local _, duration, _ = GetContainerItemCooldown(i, j)
                return duration
            end
        end
    end
    
    return nil
end

--返回CD
function Get_CD(name)
	local cd = GetSpellCooldownByName(name)
	if not cd then cd = GetInventoryCooldownByName(name) end
	if not cd then cd = GetContainerItemCooldownByName(name) end
	if cd then return cd > 1.5 end
end

function MyBuff(aura)
	if (not aura) then
		return false
	end

	CM_ScanTip:SetOwner(UIParent, "ANCHOR_NONE")
	
	aura = string.gsub(aura, "_", " ")
	
	if string.lower("player") == "mainhand" then
		CM_ScanTip:ClearLines()
		CM_ScanTip:SetInventoryItem("player",GetInventorySlotInfo("MainHandSlot"))
		for i = 1, CM_ScanTip:NumLines() do
			if string.find((_G["CM_ScanTipTextLeft"..i]:GetText() or ""), aura) then
				return true
			end
		end
	end

	if string.lower("player") == "offhand" then
		CM_ScanTip:ClearLines()
		CM_ScanTip:SetInventoryItem("player", GetInventorySlotInfo("SecondaryHandSlot"))
		for i=1, CM_ScanTip:NumLines() do
			if string.find((_G["CM_ScanTipTextLeft"..i]:GetText() or ""), aura) then
				return true
			end
		end
	end

	local i = 1
	while UnitBuff("player", i) do 
		CM_ScanTip:ClearLines()
		CM_ScanTip:SetUnitBuff("player", i)
		if string.find(CM_ScanTipTextLeft1:GetText(), aura) then
			return true
		end
		i = i + 1
	end
	
	return false
end

function MyDebuff(aura)
	if (not aura) then
		return false
	end
	
	CM_ScanTip:SetOwner(UIParent, "ANCHOR_NONE")
	
	aura = string.gsub(aura, "_", " ")
	
	local i = 1
	while UnitDebuff("player", i) do 
		CM_ScanTip:ClearLines()
		CM_ScanTip:SetUnitDebuff("player", i)
		if string.find(CM_ScanTipTextLeft1:GetText(), aura) then
			return true
		end
		i = i + 1
	end
	
	return false
end

function TarBuff(aura)
	if (not aura) then
		return false
	end
	
	CM_ScanTip:SetOwner(UIParent, "ANCHOR_NONE")

	aura = string.gsub(aura, "_", " ")
	
	local i = 1
	while UnitBuff("target", i) do 
		CM_ScanTip:ClearLines()
		CM_ScanTip:SetUnitBuff("target", i)
		if string.find(CM_ScanTipTextLeft1:GetText(), aura) then
			return true
		end
		i = i + 1
	end
	
	return false
end

function TarDebuff(aura)
	if (not aura) then
		return false
	end
	
	CM_ScanTip:SetOwner(UIParent, "ANCHOR_NONE")

	aura = string.gsub(aura, "_", " ")
	
	local i = 1
	while UnitDebuff("target", i) do 
		CM_ScanTip:ClearLines()
		CM_ScanTip:SetUnitDebuff("target", i)
		if string.find(CM_ScanTipTextLeft1:GetText(), aura) then
			return true
		end
		i = i + 1
	end	
	
	return false
end

local function GetSpellInfo(spellSlot)
    CM_ScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    CM_ScanTip:SetSpell(spellSlot, "spell")
    local _, _, cost = string.find(CM_ScanTipTextLeft2 and CM_ScanTipTextLeft2:GetText() or "", "^(%d+)")
    return tonumber(cost)
end

local function GetSpellSlotByName(name)
    name = string.lower(name)
    local b, _, rank = string.find(name, "%(%s*"..LEVEL.."%s+(%d+)%s*%)");
    if b then name = (b > 1) and Trim(string.sub(name, 1, b - 1)) or "" end

    for tabIndex = GetNumSpellTabs(), 1, -1 do
        local _, _, offset, count = GetSpellTabInfo(tabIndex)
        for index = offset + count, offset + 1, -1 do
            local spell, subSpell = GetSpellName(index, "spell")
            spell = string.lower(spell) 
            if name == spell and (not rank or subSpell == LEVEL.." "..rank) then
                return index
            end
        end
    end
end

local function GetCurrentShapeshiftForm()
    for index = 1, GetNumShapeshiftForms() do 
        local _, _, active = GetShapeshiftFormInfo(index)
        if active then return index end
    end
end    
    
local function CancelShapeshiftForm(index)
    local index =GetCurrentShapeshiftForm(index)
    if index ~= nil then CastShapeshiftForm(index) end
end

local UNITS = {
    "(mouseover)", "(player)", "(pet)", "(party)(%d)", "(partypet)(%d)",
    "(raid)(%d+)", "(raidpet)(%d+)", "(target)", "(targettarget)"
}

local function IsUnitValid(unit)
    local offset = 1
    repeat
        local b, e, name, n
        for _, p in ipairs(UNITS) do
            b, e, name, n = string.find(unit, "^" .. p, offset)
           if e then break end
        end
        if not e then return false end
        if offset > 1 and name ~= "target" then return false end
        if n and tonumber(n) == 0 then return false end

        if (name == "raid" or name == "raidpet") and tonumber(n) > 40 then
            return false
        end

        if (name == "partypet" or name == "party") and tonumber(n) > 4 then
            return false
        end
        
        offset = e + 1
    until offset > string.len(unit)
    return offset > 1
end

local function GetMouseOverUnit()
    local frame = GetMouseFocus()
    if not frame then return end

    if frame.unit then return frame.unit end

    for _, fn in ipairs(mouseOverResolvers) do
        local unit = fn(frame)
        if unit then return unit end
    end
end

local function TestConditions(conditions, target)
    local result = true

    for k, v in pairs(conditions) do
        local _, no = string.find(k, "^no")
        local mod = no and string.sub(k, no + 1) or k

        if mod == "help" then 
            result = UnitCanAssist("player", target) 
        elseif mod == "exists" then
            result = UnitExists(target)
        elseif mod == "harm" then
            result = UnitCanAttack("player", target)
        elseif mod == "dead" then
            result = UnitIsDead(target) or UnitIsGhost(target)
        elseif mod == "combat" then
            result = UnitAffectingCombat("player")
        elseif mod == "stealth" then
            result = HasBuff("Ability_Ambush") or HasBuff("Ability_Stealth")
        elseif mod == "isnpc" then
            result = not UnitIsPlayer(target)
        elseif mod == "mod" or mod == "modifier" then
            if v == true then
                result = IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown()
            else
                result = IsAltKeyDown() and v.alt
                result = result or IsControlKeyDown() and v.ctrl
                result = result or IsShiftKeyDown() and v.shift
            end
        elseif mod == "form" or mod == "stance" then
            if v == true then
                result = GetCurrentShapeshiftForm() ~= nil
            else
                result = v[GetCurrentShapeshiftForm() or 0] 
            end

        elseif mod == "cp" then
            if v then
				for cp in v do
					result = GetCP(cp)
				end
            end
        elseif mod == "cd" then
            if v then
				for cd in v do
					result = Get_CD(cd)
				end
            end
        elseif mod == "mybuff" then
            if v then
				for s in v do
					result = MyBuff(s)
				end
            end
        elseif mod == "mydebuff" then
            if v then
				for s in v do
					result = MyDebuff(s)
				end
            end
        elseif mod == "tarbuff" then
            if v then
				for s in v do
					result = TarBuff(s)
				end
            end
        elseif mod == "tardebuff" then
            if v then
				for s in v do
					result = TarDebuff(s)
				end
            end
        elseif mod == "myhp" then
			if v then
				result = Compare_UnitHp(v, "player")
			end
        elseif mod == "mymp" then		
			if v then
				result = Compare_UnitMp(v, "player")
			end
        elseif mod == "tarhp" then
			if v then
				result = Compare_UnitHp(v, "target")
			end
        elseif mod == "tarmp" then
			if v then
				result = Compare_UnitMp(v, "target")
			end
			
        -- Conditions that are NOT a part of the official implementation.
        elseif mod == "shift" then
             result = IsShiftKeyDown()
        elseif mod == "alt" then
            result = IsAltKeyDown()
        elseif mod == "ctrl" then
            result = IsControlKeyDown()
        elseif mod == "alive" then
             result = not (UnitIsDead(target) or UnitIsGhost())
             
        else
            return false
        end
        
        if no then result = not result end
        
        if not result then return false end
    end
    
    return true
end

local function GetArg(args)
    for _, arg in ipairs(args) do
        for _, conditionGroup in ipairs(arg.conditionGroups) do
            local target = conditionGroup.target

            local _, _, subTarget = string.find(target, "^mouseover(.*)")
			
            if not subTarget then
                _, _, subTarget = string.find(target, "^mo(.*)")
            end
			
            if subTarget then
                target = (GetMouseOverUnit() or "mouseover") .. subTarget
            end
            
            if not IsUnitValid(target) then
                target = "target"
            end
			
            local result = TestConditions(conditionGroup.conditions, target)
            if result then return arg, target end
        end
    end
end

local function ParseArguments(s)
    local args = {}
    
    for _, sarg in ipairs(Split(s, ";")) do
        local arg = { 
            conditionGroups = {}
        }
        table.insert(args, arg)
        
        local offset = 1
        repeat
            local _, e, sconds = string.find(sarg, "%s*%[([^]]*)]%s*", offset)
            if not sconds then break end

            local conditionGroup = {
                target = "target",
                conditions = {}
            }
            table.insert(arg.conditionGroups, conditionGroup)
            
            for _, scond in ipairs(Split(sconds, ",")) do
                local _, _, a, k, q, b, l, v = string.find(scond, "^%s*(@?)(%w+)(:?)(>?)(<?)([^%s]*)%s*$"); 
				
                if a then
                    if a == "@" and q == "" and v == "" then
                        conditionGroup.target = k
                    elseif a == "" then
                        if q == ":" then
                            local conds = {}
                            for _, smod in ipairs(Split(v, "/")) do
                                if smod ~= "" then 
                                    conds[tonumber(smod) or string.lower(smod)] = true
                                end
                            end
                            conditionGroup.conditions[string.lower(k)] = conds
                        else
                            conditionGroup.conditions[string.lower(k)] = true
                        end
						if b == ">" then
                            local conds = {}
                            for _, smod in ipairs(Split(v, ">")) do
                                if smod ~= "" then 
                                    conds[tonumber(b..smod) or string.lower(b..smod)] = true
                                end
                            end
							conditionGroup.conditions[string.lower(k)] = conds
						elseif l == "<" then
                            local conds = {}
                            for _, smod in ipairs(Split(v, "<")) do
                                if smod ~= "" then 
                                    conds[tonumber(l..smod) or string.lower(l..smod)] = true
                                end
                            end
							conditionGroup.conditions[string.lower(k)] = conds
						end						
                    end
                end
            end

            offset = e + 1
        until false
        
        arg.text = Trim(string.sub(sarg, offset))

        if table.getn(arg.conditionGroups) == 0 then
            local conditionGroup = {
                target = "target",
                conditions = {}
            }
            table.insert(arg.conditionGroups, conditionGroup)
        end
    end
    
    
    return args
end



local COMMANDS = {
    ["/cast"] =  function(args) 
        for _, arg in ipairs(args) do
            arg.spellSlot = GetSpellSlotByName(arg.text)
        end
    end,
    
    ["/castsequence"] = function(args)
        sequence = args[1]
        if not sequence then return end
        
        sequence.index = 1
        sequence.reset = {}
        sequence.spells = {}
        sequence.status = 0
    
        local _, e, reset = string.find(sequence.text, "^%s*reset=([%w/]+)%s*")
        s = e and string.sub(sequence.text, e + 1) or sequence.text

        if reset then
            for _, rule in ipairs(Split(reset, "/")) do
                local secs = tonumber(rule)
                if secs and secs > 0 then
                    if not sequence.reset.secs or secs < sequence.reset.secs then
                        sequence.reset.secs = secs
                    end
                else
                    sequence.reset[rule] = true
                end
            end
        end
    
        for _, name in ipairs(Split(s, ",")) do
            local spellSlot = GetSpellSlotByName(Trim(name))
			if name and GetSpellSlotByName(Trim(name)) then
				table.insert(sequence.spells, GetSpellSlotByName(Trim(name)))
			end
        end
    end,

    ["/use"] = function(args)
        for itemID, item in pairs(items) do
            for _, arg in ipairs(args) do
                if arg and ( string.lower(arg.text) == string.lower(item.name) or string.lower(arg.text) == item.id ) then
                    arg.itemID = itemID
                end
            end
        end
    end,
    
    ["/target"] = true,
    
    ["/stopmacro"] = true
}

local function ParseMacro(name)
    local macroIndex = GetMacroIndexByName(name)
    if macroIndex == 0 then return nil end

    local name, iconTexture, body = GetMacroInfo(macroIndex)
    if not name then return nil end

    local macro = {
        name = name,
        iconTexture = iconTexture,
        commands = {}
    }

    for i, line in ipairs(Split(body, "\n", true)) do
        if i == 1 then
            local _, _, s = string.find(line, "^%s*#showtooltip(.*)$")
            if s and not string.find(s, "^%w") then
                macro.tooltips = {}
                for _, arg in ipairs(ParseArguments(s)) do
                    local tooltip = {
                        conditionGroups = arg.conditionGroups,
                        spellSlot = GetSpellSlotByName(Trim(arg.text))
                    }
                    table.insert(macro.tooltips, tooltip)
                end
            end
        end
        
        if i > 1 or not macro.tooltips then
            local _, e, name = string.find(line, "^(/%w+)%s*")
            if name then
                local command = {
                    name = name,
                    text = string.sub(line, e + 1)
                }
                
                table.insert(macro.commands, command)

                local cmd = COMMANDS[name]
                if cmd then
                    command.args = ParseArguments(command.text)
                    if type(cmd) == "function" then
                        cmd(command.args)
                    end
                    if name == "/castsequence" then
                        table.insert(sequences, command.args[1])
                    end
                end
                
                -- Search for a corresponding slash command.
                for cmd, fn in pairs(SlashCmdList) do
                    for i in Seq do
                        local cmdt = _G["SLASH_" .. cmd .. i]
                        if not cmdt then break end
                        if cmdt == name then
                            command.fn = fn
                            break
                        end
                    end
                    if command.fn then break end
                end
            elseif line ~= "" then
                table.insert(macro.commands, { text = line })
            end
        end
    end
    
    return macro
end

local function GetMacroInfo(macro)
    if macro.tooltips then
        local arg = GetArg(macro.tooltips)
        if arg and arg.spellSlot then 
            return "spell", arg.spellSlot, 
                GetSpellTexture(arg.spellSlot, "spell")
        end
    end
    
    for _, command in ipairs(macro.commands) do
        if command.name == "/cast" then
            local arg = GetArg(command.args)
            if arg and arg.spellSlot then
                return "spell", arg.spellSlot,
                    GetSpellTexture(arg.spellSlot, "spell")
            end
        elseif command.name == "/castsequence" then
            local arg = GetArg(command.args)
            if arg then
                local reset = false
                reset = arg.reset.shift and IsShiftKeyDown() 
                reset = reset or (arg.reset.alt and IsAltKeyDown())
                reset = reset or (arg.reset.ctrl and IsControlKeyDown())
                    
                local spellSlot = arg.spells[reset and 1 or arg.index]
                
                if spellSlot then
                    return "spell", spellSlot,
                        GetSpellTexture(spellSlot, "spell")
                end
            end
        elseif command.name == "/stopmacro" then
            if GetArg(command.args) then break end
        elseif command.name == "/use" then
            local arg = GetArg(command.args)
            if arg and arg.itemID and items[arg.itemID]  then
                return "item", arg.itemID, items[arg.itemID].texture
            end
        end
    end
end

local function GetMacro(name)
    local macro = macros[name]
    if macro then return macro end
    macros[name] = ParseMacro(name)
    return macros[name]
end

local function RunMacro(macro)
    for _, command in ipairs(macro.commands) do
        if command.fn then 
            local r = command.fn(command.text, command)
            if r ~= nil and r == false then break end
        else
			if command.name then
				ChatFrameEditBox:SetText(command.name.." "..command.text);
				ChatEdit_SendText(ChatFrameEditBox);
			else
				ChatFrameEditBox:SetText(command.text);
				ChatEdit_SendText(ChatFrameEditBox);				
			end
        end
    end
end

local function RefreshAction(action)
    local spellSlot, itemID = action.spellSlot, action.itemID
    local type, value, texture = GetMacroInfo(action.macro)
    
    action.texture = texture

    if type == "spell" then
        action.cost = GetSpellInfo(value)
        action.usable = (not action.cost) or (UnitMana("player") >= action.cost)
        action.itemID = nil
        action.spellSlot = value
    elseif type == "item" then
        action.cost = 0
        action.usable = true
        action.itemID = value
        action.spellSlot = nil
    else
        action.cost = 0
        action.usable = true
        action.itemID = nil
        action.spellSlot = nil
    end
    
    return usable ~= action.usable or spellSlot ~= action.spellSlot or itemID ~= action.itemID
end

local function GetAction(slot)
    local action = actions[slot]
    if action then return action end

    local text = GetActionText(slot)
    
    if text then
        local macro = GetMacro(text)
        if macro then
            action = {
                text = text,
                macro = macro,
                slot = slot
            }

            RefreshAction(action)
            actions[slot] = action 
            return action
        end
    end
end

local function SendEventForAction(slot, event, ...)
    local _this = this

    arg1, arg2, arg3, arg4, arg5, arg6, arg7 = unpack(arg)

    local page = floor((slot - 1) / NUM_ACTIONBAR_BUTTONS) + 1
    local pageSlot = slot - (page - 1) * NUM_ACTIONBAR_BUTTONS
    
    -- Classic support.
    
    if slot >= 73 then
        this = _G["BonusActionButton" .. pageSlot]
        if this then ActionButton_OnEvent(event) end
    else
        if slot >= 61 then
            this = _G["MultiBarBottomLeftButton" .. pageSlot]
        elseif slot >= 49 then
            this = _G["MultiBarBottomRightButton" .. pageSlot]
        elseif slot >= 37 then
            this = _G["MultiBarLeftButton" .. pageSlot]
        elseif slot >= 25 then
            this = _G["MultiBarRightButton" .. pageSlot]
        else
            this = nil
        end

        if this then ActionButton_OnEvent(event) end
        
        if page == CURRENT_ACTIONBAR_PAGE then
            this = _G["ActionButton" .. pageSlot]
            if this then ActionButton_OnEvent(event) end
        end
    end

    this = _this
    
    for _, fn in ipairs(actionEventHandlers) do
        fn(slot, event, unpack(arg))
    end
end

local function IndexItems()
    items = {}
    for bagID = 0, NUM_BAG_SLOTS do
        for slot = GetContainerNumSlots(bagID), 1, -1 do
            local link = GetContainerItemLink(bagID, slot)
            if link then
                local _, _, itemID = string.find(link, "item:(%d+)")
                if itemID and not items[itemID] then
                    local name, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
                    local item = {
                        bagID = bagID,
                        slot = slot,
                        id = itemID,
                        name = name,
                        texture = texture
                    }
                    _, _, item.link = string.find(link, "|H([^|]+)|h")
                    items[itemID] = item
                end
            end
        end
    end
    
    for inventoryID = 0, 19 do
        local link = GetInventoryItemLink("player", inventoryID)
        if link then
            local _, _, itemID = string.find(link, "item:(%d+)")
            if itemID and not items[itemID] then
                local name, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
                local item = {
                    inventoryID = inventoryID,
                    id = itemID,
                    name = name,
                    texture = texture
                }
                _, _, item.link = string.find(link, "|H([^|]+)|h")
                items[itemID] = item
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Overrides                                                                   -
--------------------------------------------------------------------------------

local base = {}

base.UseAction = UseAction
function UseAction(slot, checkCursor, onSelf)
    local action = GetAction(slot)
    if action and action.macro then
        RunMacro(action.macro)
    else
        base.UseAction(slot, checkCursor, onSelf)
    end
end

base.GameTooltip = {}

base.GameTooltip.SetAction = GameTooltip.SetAction
function GameTooltip.SetAction(self, slot)
    local action = GetAction(slot)
    if action then
        if action.spellSlot then
            GameTooltip:SetSpell(action.spellSlot, "spell")
            local _, rank = GetSpellName(action.spellSlot, "spell")
            GameTooltipTextRight1:SetText("|cff808080" .. rank .."|r");
            GameTooltipTextRight1:Show();
            GameTooltip:Show()
        elseif action.itemLink then
            GameTooltip:SetHyperlink(action.itemLink)
            GameTooltip:Show()
        end
    else
        base.GameTooltip.SetAction(self, slot)
    end
end

base.IsActionInRange = IsActionInRange
function IsActionInRange(slot, unit)
	if slot then
		local action = GetAction(slot)
	end
    if action and action.macro and action.macro.tooltips then
        return action.spellSlot and true 
    else
        return base.IsActionInRange(slot, unit)
    end
end

base.IsUsableAction = IsUsableAction
function IsUsableAction(slot, unit)
    local action = GetAction(slot)
    if action and action.macro and action.macro.tooltips then 
        if action.usable then
            return true, false
        else
            return false, true
        end
    else
        return base.IsUsableAction(slot, unit)
    end
end

base.GetActionTexture = GetActionTexture
function GetActionTexture(slot)
    local action = GetAction(slot)
    if action and action.macro and action.macro.tooltips then
        return action.texture or "Interface\\Icons\\INV_Misc_QuestionMark"
    else
        return base.GetActionTexture(slot)
    end
end

base.GetActionCooldown = GetActionCooldown
function GetActionCooldown(slot)
    local action = GetAction(slot)
    if action and action.macro then
        if action.spellSlot then
            return GetSpellCooldown(action.spellSlot, "spell")
        elseif action.itemID then
            local item = items[action.itemID]
            if item then
                if item.bagID and item.slot then
                    return GetContainerItemCooldown(item.bagID, item.slot)
                elseif item.inventoryID then
                    return GetInventoryItemCooldown("player", item.inventoryID)
                end
            end
        end
        return 0, 0, 0
    else
        return base.GetActionCooldown(slot)
    end
end

base.SlashCmdList = {}

base.SlashCmdList.TARGET = SlashCmdList["TARGET"]
SlashCmdList["TARGET"] = function(msg)
    local arg, target = GetArg(command and command.args or ParseArguments(msg))
    if arg then
        if target ~= "target" then
            TargetUnit(target)
        else
            base.SlashCmdList.TARGET(arg.text)
        end
    end
end

--------------------------------------------------------------------------------
-- UI                                                                          -
--------------------------------------------------------------------------------

local function OnUpdate(self)
    local time = GetTime()

    -- Slow down a bit.
    if (time - lastUpdate) < 0.1 then return end
    lastUpdate = time

    if currentSequence and currentSequence.status >= 2 and 
            (time - currentSequence.lastUpdate) >= 0.2 then
        if currentSequence.status == 2 then
            if currentSequence.index >= table.getn(currentSequence.spells) then
                currentSequence.index = 1
            else
                currentSequence.index = currentSequence.index + 1
            end
        end

        for slot, action in pairs(actions) do
            for _, command in ipairs(action.macro.commands) do
                if command.name == "/castsequence" and command.args[1] == currentSequence then
                    SendEventForAction(slot, "ACTIONBAR_SLOT_CHANGED", slot)
                end
            end
        end

        currentSequence = nil
    end

    for _, sequence in ipairs(sequences) do
        if sequence.index > 1 and sequence.reset.secs and (time - sequence.lastUpdate) >= sequence.reset.secs then
            sequence.index = 1
            
            for slot, action in pairs(actions) do
                for _, command in ipairs(action.macro.commands) do
                    if command.name == "/castsequence" and command.args[1] == sequence then
                        SendEventForAction(slot, "ACTIONBAR_SLOT_CHANGED", slot)
                    end
                end
            end
        end
    end
    
    for slot, action in pairs(actions) do
        if RefreshAction(action) then
            SendEventForAction(slot, "ACTIONBAR_SLOT_CHANGED", slot)
        end
    end
end

local function OnEvent()
    if event == "UPDATE_MACROS" or event == "SPELLS_CHANGED" then
        currentSequence = nil
        macros = {}
        actions = {}
        sequences = {}
        IndexItems()
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        actions[arg1] = nil
        SendEventForAction(arg1, "ACTIONBAR_SLOT_CHANGED", arg1)
    elseif event == "BAG_UPDATE" then
        macros = {}
        actions = {}
        IndexItems()
    elseif event == "PLAYER_LEAVE_COMBAT" then
        for _, sequence in pairs(sequences) do
            if currentSequence ~= sequence and sequence.index > 1 and sequence.reset.combat then
                sequence.index = 1
            end
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        for _, sequence in pairs(sequences) do
            if currentSequence ~= sequence and sequence.index > 1 and sequence.reset.target then
                sequence.index = 1
            end
        end
    elseif currentSequence then
        if event == "SPELLCAST_START" then
            currentSequence.status = 1
        elseif event == "SPELLCAST_STOP" then
            currentSequence.status = 2
            currentSequence.lastUpdate = GetTime()
        elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
            currentSequence.status = 3
        end
    end
   
end

CM_ScanTip = CreateFrame("GameTooltip", "CM_ScanTip", nil, "GameTooltipTemplate")
CM_ScanTip:SetScript("OnUpdate", OnUpdate)
CM_ScanTip:SetScript("OnEvent", OnEvent)

CM_ScanTip:RegisterEvent("UPDATE_MACROS")
CM_ScanTip:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
CM_ScanTip:RegisterEvent("SPELLCAST_START")
CM_ScanTip:RegisterEvent("SPELLCAST_STOP")
CM_ScanTip:RegisterEvent("SPELLCAST_FAILED")
CM_ScanTip:RegisterEvent("SPELLCAST_INTERRUPTED")
CM_ScanTip:RegisterEvent("PLAYER_LEAVE_COMBAT")
CM_ScanTip:RegisterEvent("PLAYER_TARGET_CHANGED")
CM_ScanTip:RegisterEvent("SPELLS_CHANGED")
CM_ScanTip:RegisterEvent("BAG_UPDATE")
--------------------------------------------------------------------------------
-- Slash Commands                                                              -
--------------------------------------------------------------------------------
SlashCmdList["CAST"] = function(msg, command)
    local args = command and command.args
    if not args then
        args = ParseArguments(msg)
        COMMANDS["/cast"](args)
    end

	--arg
	--target 返回实际的单位
    local arg, target = GetArg(args)
			
	--选择目标
    if target and not UnitIsUnit(target, "target") then
        TargetUnit(target)
    end            

	--获取实际的命令的单词
	local turecmd = nil
    for _, true_CMD in ipairs(args) do
        for _, conditionGroup in ipairs(true_CMD.conditionGroups) do
			turecmd = conditionGroup.target
		end
	end

	--焦点目标施放技能
	if turecmd == "focus" then
		if arg and arg.spellSlot then
			local spellName, spellRank = GetSpellName(arg.spellSlot, "spell")
			SlashCmdList.FCAST(spellName.."("..spellRank..")")
		end
	end
	
	--一般施放技能
	if arg and arg.spellSlot then
		local spellName, spellRank = GetSpellName(arg.spellSlot, "spell")
		CastSpellByName(spellName.."("..spellRank..")")
	else
		if msg ~= "" then
			CastSpellByName(msg)
		end
	end

	--是否返回上一个目标
	if (turecmd == "mouseover" or turecmd == "mo") and target ~= "target" then
		TargetLastTarget()
	elseif target == "targettarget" then
		TargetLastTarget()
	end

	--print(turecmd.." / "..target)
end

SlashCmdList["USE"] = function(msg, command)
    local args = command and command.args
    if not args then
        args = ParseArguments(msg)
        COMMANDS["/use"](args)
    end

    local arg, target = GetArg(args)
    if not arg or not arg.itemID then return end

    local item = items[arg.itemID]
    if not item then return end

    if target and not UnitIsUnit(target, "target") then
        TargetUnit(target)
    end             

	--获取实际的命令的单词
	local turecmd = nil
    for _, true_CMD in ipairs(args) do
        for _, conditionGroup in ipairs(true_CMD.conditionGroups) do
			turecmd = conditionGroup.target
		end
	end

	--焦点目标施放技能
	if turecmd == "focus" then
		if item and item.name then
			SlashCmdList.FITEM(item.name)
		end
	end

    if item.bagID and item.slot then
        UseContainerItem(item.bagID, item.slot)
    elseif item.inventoryID then
        UseInventoryItem(item.inventoryID)
    end

	--是否返回上一个目标
	if (turecmd == "mouseover" or turecmd == "mo") and target ~= "target" then
		TargetLastTarget()
	elseif target == "targettarget" then
		TargetLastTarget()
	end
end

SlashCmdList["CASTSEQUENCE"] = function(msg, command)
    local args = command and command.args

    if currentSequence then return end

    if not args then
        args = ParseArguments(msg)
        COMMANDS["/castsequence"](args)
    end

    local arg, target = GetArg(args)
    if not arg then return end

    if arg and arg.index > 1 then
        local reset = false
        reset = arg.reset.shift and IsShiftKeyDown() 
        reset = reset or (arg.reset.alt and IsAltKeyDown())
        reset = reset or (arg.reset.ctrl and IsControlKeyDown())
        if reset then arg.index = 1 end
    end

    local spellSlot = arg.spells[arg.index]
    
    if spellSlot then
        arg.status = 0
        arg.lastUpdate = GetTime()

        currentSequence = arg
        
		if target and not UnitIsUnit(target, "target") then
			TargetUnit(target)
		end

		--获取实际的命令的单词
		local turecmd = nil
		for _, true_CMD in ipairs(args) do
			for _, conditionGroup in ipairs(true_CMD.conditionGroups) do
				turecmd = conditionGroup.target
			end
		end

		--焦点目标施放技能
		if turecmd == "focus" then
			if spellSlot then
				local spellName, spellRank = GetSpellName(spellSlot, "spell")
				SlashCmdList.FCAST(spellName.."("..spellRank..")")
			end
		end

		local spellName, spellRank = GetSpellName(spellSlot, "spell")
		CastSpellByName(spellName.."("..spellRank..")")

		--是否返回上一个目标
		if (turecmd == "mouseover" or turecmd == "mo") and target ~= "target" then
			TargetLastTarget()
		elseif target == "targettarget" then
			TargetLastTarget()
		end

    end
end

SlashCmdList["STOPMACRO"] = function(msg, command)
    if command and GetArg(command.args) then 
        return false
    end
end

SlashCmdList["CANCELFORM"] = function(msg)
    local arg = GetArg(command and command.args or ParseArguments(msg))
    if arg then CancelShapeshiftForm() end
end

SLASH_CANCELFORM1 = "/cancelform"
SLASH_CASTSEQUENCE1 = "/castsequence"
SLASH_STOPMACRO1 = "/stopmacro"
SLASH_USE1 = "/use"
SLASH_USE2 = "/equip"

-- Exports

CleverMacro = {}

CleverMacro.RegisterActionEventHandler = function(fn)
    if type(fn) == "function" then
        table.insert(actionEventHandlers, fn)
    end
end

CleverMacro.RegisterMouseOverResolver = function(fn)
    if type(fn) == "function" then
        table.insert(mouseOverResolvers, fn)
    end
end