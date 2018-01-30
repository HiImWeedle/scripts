	--[[
		WeedleWalk.lua 
		Version 0.2 
   		Authors: Weedle
		.isVisible and .boundingRadius broken atm
		.canMoveWhileChanneling also broken atm 
	--]]

	if _G.WeedleWalk_Loaded then 
		return
	end

	_G.WeedleWalk_Loaded = true

	local function class()
   		local cls = {}
   		cls.__index = cls
   		return setmetatable(cls, {__call = function (c, ...)
   		    local instance = setmetatable({}, cls)
   		    if cls.__init then
   		        cls.__init(instance, ...)
   		    end
   		    return instance
   		end})
	end

	local version = 0.2 
	local char_name = myHero.charName 
	local summoner_name = myHero.name 

	local myId = myHero.networkId
	local myBoundingRadius = myHero.boundingRadius 
	local myRange = myHero.characterIntermediate.attackRange + myBoundingRadius * 0.5 
	local attackDelay = myHero.attackDelay
	local attackCastDelay = myHero.attackCastDelay 

	local extraWindup = 0.09 -- Menu Slider 
	local holdRadius = 150 -- Menu Slider 

	local spacebar = 0x20
	local c = 0x43
	local v = 0x56
	local x = 0x58	

	local huge = math.huge
	local pi = math.pi
	local floor = math.floor 
	local sqrt = math.sqrt 
	local max = math.max 
	local min = math.min 		

	local abs = math.abs 
	local deg = math.deg 
	local acos = math.acos 
	local atan = math.atan 

	local format = string.format 
	local find = string.find 
	local lower = string.lower 
	local insert = table.insert 
	local remove = table.remove 

	local TEAM_JUNGLE = 300 
	local TEAM_ALLY = myHero.team 
	local TEAM_ENEMY = TEAM_JUNGLE - TEAM_ALLY

	local _HERO = GameObjectType.AIHeroClient
	local _MISSILE = GameObjectType.MissileClient 

	local _INTERNAL = 0
	local _AURA = 1 
	local _ENHANCER = 2 
	local _DEHANCER = 3 
	local _SPELLSHIELD = 4 
	local _STUN = 5
	local _INVIS = 6
	local _SILENCE = 7
	local _TAUNT = 8
	local _POLYMORPH = 9	
	local _SLOW = 10	
	local _SNARE = 11
	local _DMG = 12 
	local _HEAL = 13 
	local _HASTE = 14
	local _SPELLIMM = 15
	local _PHYSIMM = 16
	local _INVULNERABLE = 17 
	local _SLEEP = 18 
	local _NEARSIGHT = 19 
	local _FRENZY = 20 
	local _FEAR = 21	
	local _CHARM = 22
	local _POISON = 23
	local _SUPRESS = 24		
	local _BLIND = 25
	local _COUNTER = 26 
	local _SHRED = 27
	local _FLEE = 28
	local _KNOCKUP = 29
	local _KNOCKBACK = 30	
	local _DISARM = 31

	local lastAA = -1000 
	local lastMC = -1000
	local isLaunched = true
	local orbTarget = nil 
	local orbMode = 0 

	local time = RiotClock.time 
	local hudManager = pwHud.hudManager 

	local AttackResets = {
        "dariusnoxiantacticsonh", "fiorae", "garenq", "gravesmove",
        "hecarimrapidslash", "jaxempowertwo", "jaycehypercharge",
        "leonashieldofdaybreak", "luciane", "monkeykingdoubleattack",
        "mordekaisermaceofspades", "nasusq", "nautiluspiercinggaze",
        "netherblade", "gangplankqwrapper", "powerfist",
        "renektonpreexecute", "rengarq", "shyvanadoubleattack",
        "sivirw", "takedown", "talonnoxiandiplomacy",
        "trundletrollsmash", "vaynetumble", "vie", "volibearq",
        "xenzhaocombotarget", "yorickspectral", "reksaiq",
        "itemtitanichydracleave", "masochism", "illaoiw",
        "elisespiderw", "fiorae", "meditate", "sejuaninorthernwinds",
        "asheq", "camilleq", "camilleq2"
        }

    local Attacks = {
        "caitlynheadshotmissile", "frostarrow", "garenslash2",
        "kennenmegaproc", "masteryidoublestrike", "quinnwenhanced",
        "renektonexecute", "renektonsuperexecute",
        "rengarnewpassivebuffdash", "trundleq", "xenzhaothrust",
        "xenzhaothrust2", "xenzhaothrust3", "viktorqbuff",
        "lucianpassiveshot"}

    local NoAttacks = {
   		 "volleyattack", "volleyattackwithsound",
         "jarvanivcataclysmattack", "monkeykingdoubleattack",
         "shyvanadoubleattack", "shyvanadoubleattackdragon",
         "zyragraspingplantattack", "zyragraspingplantattack2",
         "zyragraspingplantattackfire", "zyragraspingplantattack2fire",
         "viktorpowertransfer", "sivirwattackbounce", "asheqattacknoonhit",
         "elisespiderlingbasicattack", "heimertyellowbasicattack",
         "heimertyellowbasicattack2", "heimertbluebasicattack",
         "annietibbersbasicattack", "annietibbersbasicattack2",
         "yorickdecayedghoulbasicattack", "yorickravenousghoulbasicattack",
         "yorickspectralghoulbasicattack", "malzaharvoidlingbasicattack",
         "malzaharvoidlingbasicattack2", "malzaharvoidlingbasicattack3",
         "kindredwolfbasicattack", "gravesautoattackrecoil"}

	--x--

	local function contains(table, element)
		for _, value in pairs(table) do 
			if value == element then 
				return true 
			end
		end
		return false 
	end

	local function Hex(a,r,g,b)
		return format("0x%.2X%.2X%.2X%.2X",a,r,g,b)
	end	

	local function GetDistanceSqr(p1, p2)
	  	p2 = p2 or myHero
	  	p1 = p1.position or p1
	  	p2 = p2.position or p2
	  	
	  	local dx = p1.x - p2.x
	  	local dz = p1.z - p2.z
	  	return dx*dx + dz*dz
	end
	
	local function GetDistance(p1, p2)
	 	return sqrt(GetDistanceSqr(p1, p2))
	end	

	local function GetMode()
		if IsKeyDown(spacebar) then return 1 end 
		if IsKeyDown(c) then return 2 end 
		if IsKeyDown(v) then return 3 end 
		if IsKeyDown(x) then return 4 end 
		return 0
	end

	
	local function GetLatency()
	    return NetClient.ping
	end	

	local function GetTime()
		return RiotClock.time 
	end

	local function CalcPhysicalDamage(source, target, dmg)
	    if target.isInvulnerable then return 0 end
	    
		local result = 0
		local baseArmor = target.characterIntermediate.armor
		local Lethality = source.characterIntermediate.physicalLethality * (0.6 + 0.4 * source.experience.level / 18)
		baseArmor = baseArmor - Lethality
	
		if baseArmor < 0 then baseArmor = 0 end
		if (baseArmor >= 0 ) then
			local armorPenetration = source.characterIntermediate.percentArmorPenetration
			local armor = baseArmor - ((armorPenetration*baseArmor) / 100)
			result = dmg * (100 / (100 + armor))
		end
	
		return result
	end

	local function CalcMagicalDamage(source, target, dmg)
	    if target.isInvulnerable then return 0 end
	    
	    local result = 0
	
		local baseArmor = target.characterIntermediate.spellBlock
		local Lethality = source.characterIntermediate.flatMagicPenetration
	    baseArmor = baseArmor - Lethality
	
		if baseArmor < 0 then baseArmor = 0 end
		if (baseArmor >= 0 ) then
			local armorPenetration = source.characterIntermediate.percentMagicPenetration
			local armor = baseArmor - ((armorPenetration*baseArmor) / 100)
			result = dmg * (100 / (100 + armor))
		end
	
		return result
	end		

	local function GetTarget(range)
		local potential = {} 
		local ad = myHero.characterIntermediate.flatPhysicalDamageMod 
		local ap = myHero.characterIntermediate.flatMagicDamageMod
		local adc = true
		if ap > ad then 
			adc = false 
		end
		for i,v in pairs(ObjectManager:GetEnemyHeroes()) do 
			if v.team == TEAM_ENEMY and v.isValid and v.isDead == false --[[and v.isVisble]] and (v.isInvulnerable == false or v.charName == "Anivia" or v.charName == "Zac") then 
				if GetDistance(v) < range --[[+ v.boundingRadius * 0.5]] then 
					if adc then 
						potential[CalcPhysicalDamage(myHero, v, 100)/v.health] = v 
					else
						potential[CalcMagicalDamage(myHero, v, 100)/v.health] = v 
					end
				end
			end
		end
		local bT = 0
	    for d,v in pairs(potential) do
	      	if d > bT then
	        	bT = d
	      	end
	    end
	    if bT ~= 0 then return potential[bT] end	
	end


	local function ResetLastAA()
		lastAA = 0 
	end

	local function CanAttack()
		if myHero.canAttack then 
			if myHero.buffManager:HasBuffOfType(_BLIND) and char_name ~= "Kalista" then 
				return false 
			end
	
			if char_name == "Graves" then 
				attackDelay = 1.0740296828 * myHero.attackDelay - 716.2381256175
				if time + latency * 0.0005 + 0.025 >= lastAA + attackDelay and myHero.buffManager:HasBuff("GravesBasicAttackAmmo1") then 
					return true 
				else 
					return false 
				end
			end
	
			if char_name == "Jhin" then 
				if myHero.buffManager:HasBuff("JhinPassiveReload") then 
					return false 
				end
			end
			return time + latency * 0.0005 + 0.025 >= lastAA + attackDelay 
		end
		return false
	end

	local function CanMove()
		if myHero.isRanged and isLaunched then 
			if time + latency * 0.0005 > lastAA + attackCastDelay + extraWindup then
				return true 
			else
				return false
			end
		end
		return char_name == "Kalista" and true or time + latency * 0.0005 > lastAA + attackCastDelay + extraWindup 
	end

	local function GetAttackRange()
		local result = myHero.characterIntermediate.attackRange + myBoundingRadius 

		if char_name == "Caitlyn" then 
			if myHero.buffManager:HasBuff("caitlynheadshotrangecheck") then 
				result = result + 650 
			end 
		end 
		return result 
	end	

	--x--

	Orbwalker = class()

	function Orbwalker:_init()
		AddEvent(Events.OnTick, function() self:OnTick() end)
		AddEvent(Events.OnBasicAttack, function(...) self:OnBasicAttack(...) end)
		AddEvent(Events.OnCreateObject, function(...) self:OnCreateObject(...) end)
		AddEvent(Events.OnProcessSpell, function(...) self:OnProcessSpell(...) end)
		print("WeedleWalk v"..version.." Loaded")
		PrintChat("<b><font color=\"#FF1C6F\"><b>WeedleWalk  v"..version.."</font><font color=\"#FFFFFF\"> Loaded!</font></b>")
	end

	modes = {
	function() Orbwalker:Combo() end,
	function() Orbwalker:Mixed() end,
	function() Orbwalker:Clear() end,
	function() Orbwalker:LastHit() end}

	function Orbwalker:OnTick()
		time = GetTime()
		latency = GetLatency()
		orbMode = GetMode()
		myBoundingRadius = 55 --myHero.boundingRadius * 0.5
		myRange = GetAttackRange()

		if myHero.isDead == false and MenuGUI.isChatOpen == false and orbMode > 0 then 
			orbTarget = GetTarget(myRange)
			modes[orbMode]()
		else
			orbTarget = nil 
		end
	end

	function Orbwalker:OnBasicAttack(source, spell)
		if source.isValid and source.networkId == myId then 
			lastAA = time 
			isLaunched = false 

			attackDelay = myHero.attackDelay 
			attackCastDelay = myHero.attackCastDelay 
		end
	end

	function Orbwalker:OnCreateObject(obj)
		if obj.type == _MISSILE and obj.asMissile.spellCaster.networkId == myId then 
			local name = lower(obj.asMissile.missileData.spellData.name)
			if (find(name, "attack") and not contains(NoAttacks, name)) or contains(Attacks, name) then 
				isLaunched = true 
			end
		end
	end

	function Orbwalker:OnProcessSpell(source, spell)
		if source.isValid and source.networkId == myId then 
			local name = lower(spell.spellData.name)
			if contains(AttackResets, name) then 
				ResetLastAA() 
			end
		end
	end	

	function Orbwalker:Combo()
		if orbTarget and CanAttack() then 
			myHero:IssueOrder(GameObjectOrder.AttackUnit, orbTarget)
		elseif CanMove() then 
			myHero:IssueOrder(GameObjectOrder.MoveTo, hudManager.activeVirtualCursorPos)
			lastMC = time 
		end
	end

	function Orbwalker:Mixed()

	end

	function Orbwalker:Clear()

	end

	function Orbwalker:LastHit()

	end

	--x--

	function OnLoad()
		Orbwalker:_init()
	end




