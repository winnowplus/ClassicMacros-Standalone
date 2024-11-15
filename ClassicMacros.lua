SLASH_CASTRANDOM1 = "/castrandom"
SLASH_STOPCASTING1 = "/stopcasting"

SLASH_CANCELAURA1 = "/cancelaura"

SLASH_STARTATTACK1 = "/startattack"
SLASH_STOPATTACK1 = "/stopattack"

SLASH_AUTOSHOOTATTACK1 = "/shootattack"

SLASH_PETAGGRESSIVE1 = "/petaggressive"
SLASH_PETPASSIVE1 = "/petpassive"
SLASH_PETDEFENSIVE1 = "/petdefensive"
SLASH_PETATTACK1 = "/petattack"
SLASH_PETFOLLOW1 = "/petfollow"
SLASH_PETSTAY1 = "/petstay"

SLASH_CLEARTARGET1 = "/cleartarget"
SLASH_LASTTARGET1 = "/lasttarget"

SLASH_EQUIPOFF1 = "/equipoff"
SLASH_IN1 = "/in"

local scantip = CreateFrame("GameTooltip", "scantip", nil, "GameTooltipTemplate")

--检查24#动作条是否有攻击按钮
local function Check24SoltSpell(SoltId)
	scantip:SetOwner(WorldFrame, "ANCHOR_NONE")
	scantip:SetAction(SoltId)
	local SoltSpellName = scantipTextLeft1:GetText()
	if GetActionText(SoltId) or SoltSpellName ~= ATTACK then
		return true
	else
		return false
	end
end

function StartAttack(SoltId)
	if not SoltId then SoltId = 24 end
	local noattacktexture = Check24SoltSpell(SoltId)
	local id = GetSpellIndex(ATTACK)

	if not UnitExists("target") then
		TargetNearestEnemy()
	else
		if UnitIsDeadOrGhost("target") == 1 then
			ClearTarget()
		end
	end
	if noattacktexture then
		PickupSpell(id, BOOKTYPE_SPELL)
		PlaceAction(SoltId)
		ClearCursor()
	else
		if IsCurrentAction(SoltId) == nil then
			UseAction(SoltId)
		end
	end
end

function StopAttack(SoltId)
	if not SoltId then SoltId = 24 end
	local noattacktexture = Check24SoltSpell(SoltId)
	local id = GetSpellIndex(ATTACK)
	
	if noattacktexture then
		PickupSpell(id, BOOKTYPE_SPELL)
		PlaceAction(SoltId)
		ClearCursor()
	else
		if IsCurrentAction(SoltId) == 1 then
			AttackTarget()
		end
	end
end

--检查23#动作条是否有自动射击按钮
local function Check23SoltSpell(SoltId)
	scantip:SetOwner(WorldFrame, "ANCHOR_NONE")
	scantip:SetAction(SoltId)
	local SoltSpellName = scantipTextLeft1:GetText()
	if GetActionText(SoltId) or SoltSpellName ~= "自动射击" then
		return true
	else
		return false
	end
end

function AutoShootAttack(SoltId)
	if not SoltId then SoltId = 23 end
	local noshoottexture = Check23SoltSpell(SoltId)
	local id = GetSpellIndex("自动射击")
	
	if noshoottexture then
		PickupSpell(id, BOOKTYPE_SPELL)
		PlaceAction(SoltId)
		ClearCursor()
	else
		if IsActionInRange(SoltId) == 1 then
			if IsAutoRepeatAction(SoltId) == nil then
				UseAction(SoltId)
			end
		else
			SlashCmdList.STARTATTACK(msg, editbox)
		end
	end
end

local function strsplit(pString, pPattern)
	local Table = {}
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = strfind(pString, fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(Table,cap)
		end
		last_end = e+1
		s, e, cap = strfind(pString, fpat, last_end)
	end
	if last_end <= strlen(pString) then
		cap = strsub(pString, last_end)
		table.insert(Table, cap)
	end
	return Table
end

function TrimSpaces(str)
	if ( str ) then
		return gsub(str,"^%s*(.-)%s*$","%1");
	end
end

function SlashCmdList.CASTRANDOM(msg, editbox)
	if msg == "" then
		return
	end
	local tbl = strsplit(msg, ",")
	local spell = tbl[math.random(1,getn(tbl))]
	while strsub(spell,1,1) == " " do
		spell = strsub(spell,2)
	end
	while strsub(spell,strlen(spell)) == " " do
		spell = strsub(spell, 1, (strlen(spell)-1))
	end
	CastSpellByName(spell)
end

function SlashCmdList.STOPCASTING(msg, editbox)
	SpellStopCasting()
end

function SlashCmdList.CANCELAURA(msg, editbox)
   	local buff = strlower(msg)
   	for i=0, 32 do
   		scantip:SetOwner(UIParent, "ANCHOR_NONE")
   		scantip:SetPlayerBuff(i)
   		local name = scantipTextLeft1:GetText()
   		if not name then break end
   		if strfind(strlower(name), buff) then
   			CancelPlayerBuff(i)
   		end
   		scantip:Hide()
   	end
end

function SlashCmdList.STARTATTACK(msg, editbox)
	StartAttack(24)
end

function SlashCmdList.STOPATTACK(msg, editbox)
	StopAttack(24)
end

function SlashCmdList.AUTOSHOOTATTACK(msg, editbox)
	AutoShootAttack(23)
end

function SlashCmdList.PETAGGRESSIVE(msg, editbox)
	PetAggressiveMode()
end

function SlashCmdList.PETPASSIVE(msg, editbox)
	PetPassiveMode()
end

function SlashCmdList.PETDEFENSIVE(msg, editbox)
	PetDefensiveMode()
end

function SlashCmdList.PETATTACK(msg, editbox)
	PetAttack()
end

function SlashCmdList.PETFOLLOW(msg, editbox)
	PetFollow()
end

function SlashCmdList.PETSTAY(msg, editbox)
	PetWait()
end

function SlashCmdList.CLEARTARGET(msg, editbox)
	ClearTarget()
end

function SlashCmdList.LASTTARGET(msg, editbox)
	TargetLastTarget()
end

function SlashCmdList.EQUIPOFF(msg)
	local bag, slot = FindItemInfo(TrimSpaces(msg))
	if bag and slot then
		PickupContainerItem(bag, slot)
		PickupInventoryItem(17)
	end
end

--移植超级宏的/in命令
local f = CreateFrame("Frame")
f.events = {}
f.events.n = 0
CM_Alias = {}
CM_Alias.low = 0
CM_Alias.high = 0
CM_Alias[0] = function (body) return body end

function InEnter(sec, cmd, rep)
	if ( not sec or not cmd ) then return end
	local t = f.events
	local seconds = sec
	if strfind(seconds, '[hms]') then
		seconds = gsub(seconds, '^(%d+)(h?)(%d*)(m?)(%d*)(s?)$', function(hd, h, md, m, sd, s)
			local a = 0
			if ( h == "h" ) then a = a + hd * 3600
			else md = hd..md end
			if ( m == "m" ) then a = a + md * 60
			else sd = md..sd end
			if ( sd ~= "" ) then a = a + sd end
			return a
		end)
	end
	s = GetTime() + seconds
	t[s] = {}
	t[s].cmd = cmd
	t[s].sec = seconds
	t[s].rep = rep and rep or ""
	t.n = t.n + 1
	f:Show()
end

function INFRAME_OnUpdate()
	local t = this.events
	if ( getn(t) == 0 ) then
		f:Hide()
	end
	for k,v in t do
		if (k ~= 'n' and k <= GetTime()) then
			RunBody(v.cmd)
			if (v.rep ~= "") then
				local s = GetTime() + v.sec
				t[s] = {}
				t[s].cmd = v.cmd
				t[s].sec = v.sec
				t[s].rep = v.rep
				t[k] = nil
			else
				t[k] = nil
				t.n = t.n-1
			end
		end
	end
end

function RunBody(text)
	local body = text
	local length = strlen(body)
	for w in string.gfind(body, "[^\n]+") do
		RunLine(w)
	end
end

function RunLine(...)
	for k = 1,arg.n do
		local text = arg[k]
		text = ReplaceAlias(text, -1)
		
		if ( string.find(text, "^/cast") ) then
			local i, book = SM_FindSpell(gsub(text, "^%s*/cast%s*(%w.*[%w%)])%s*$","%1"))
			if (i) then
				CastSpell(i,book)
			end
		else
			if string.find(text, "^/script ") then
				RunScript(gsub(text, "^/script ",""))
			else
				text = gsub( text, "\n", "")
				ChatFrameEditBox:SetText(text)
				ChatEdit_SendText(ChatFrameEditBox)
			end
		end
	end
end
	
function ReplaceAlias(body, after)
	local size, step
	if ( after == -1 ) then
		size, step = CM_Alias.low, -1
	else
		size, step = CM_Alias.high, 1
	end
	for i = step, size, step do
		body = CM_Alias[i](body)
	end
	return body
end

f:SetScript("OnUpdate",function() INFRAME_OnUpdate() end)

function SlashCmdList.IN(msg)
	local _, _, s, r, c = strfind(msg, "(%d+h?%d*m?%d*s?)(%+?)%s+(.*)")
	if ( not c or TrimSpaces(c) == "" ) then return end
	c = gsub(c,"\\n","\n")
	InEnter(s, c, r)
end