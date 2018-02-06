	--[[
		WeedleWalk.lua (PlsWork.lua)
		Version 0.2 
	--]]

	require 'GeometryLib'

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
	local orbHeroTarget = nil 
	local orbObjTarget = nil 
	local orbMode = 0 

	local lastSpell = {isSpell = false, time = 0, spellTime = 0} -- For champs scripts

	local time = RiotClock.time 
	local hudManager = pwHud.hudManager 

	local NoWaste = {"Kalista", "Twitch"}

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

	--x--

	local function Ready(spell)
		return myHero.spellbook:CanUseSpell(spell) == 0
	end		

	local function Vec3(vec)
		return D3DXVECTOR3(vec.x, vec.y, vec.z)
	end	

	--x--
	
	local function GetLatency()
	    return NetClient.ping
	end	

	local function GetTime()
		return RiotClock.time 
	end

	local function GetCursorPos()
		return hudManager.activeVirtualCursorPos
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

	local function GetHeroTarget(range)
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
			if myHero.buffManager:HasBuffOfType(_BLIND) and not contains(NoWaste, char_name ) then 
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
		AddEvent(Events.OnDraw, function() self:OnDraw() end)
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
			orbHeroTarget = GetHeroTarget(myRange)
			modes[orbMode]()
		else
			orbHeroTarget = nil 
		end
	end

	function Orbwalker:OnBasicAttack(source, spell)
		if source.isValid and source.networkId == myId then 
			lastAA = time 
			isLaunched = false 

			attackDelay = myHero.attackDelay 
			attackCastDelay = myHero.attackCastDelay 

			lastSpell.isSpell = false 
			lastSpell.time = GetTime()
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
			lastSpell.isSpell = true 
			lastSpell.time = GetTime()
			lastSpell.spellTime = GetTime()
		end
	end	

	function Orbwalker:Combo()
		if orbHeroTarget and CanAttack() then 
			myHero:IssueOrder(GameObjectOrder.AttackUnit, orbHeroTarget)
		elseif CanMove() and GetDistance(hudManager.activeVirtualCursorPos) > 100 then 
			myHero:IssueOrder(GameObjectOrder.MoveTo, GetCursorPos())
			lastMC = time 
		end
	end

	function Orbwalker:Mixed()

	end

	function Orbwalker:Clear()

	end

	function Orbwalker:LastHit()

	end

	function Orbwalker:OnDraw()
		DrawHandler:Circle3D(myHero.position, myRange, Hex(230, 255, 0, 93))
	end		

	--x--

	local Q = 0 
	local W = 1 
	local E = 2 
	local R = 3

	Vayne = class()

	function Vayne:_init()
		AddEvent(Events.OnTick, function() self:OnTick() end)
		print("Vayne Loaded")
	end

	function Vayne:OnTick()
		if myHero.isDead == false and MenuGUI.isChatOpen == false then 
			if orbMode == 1 then
				if orbHeroTarget then
					if Ready(Q) then 
						if CanMove() and time < lastAA + attackDelay then 
							myHero.spellbook:CastSpell(Q, hudManager.activeVirtualCursorPos)
						end
					end
					if Ready(E) then 
						self:CastE(orbHeroTarget)
					end
				end
			end
		end
	end

	function Vayne:CanE(unit)
		local wallCheck = false 
	
		local myHero_pos, unit_pos = Vector(myHero.position), Vector(unit.position)
		local distance = GetDistance(unit_pos, myHero_pos)
	
		local boundingRadius = 27.5 -- boundingRadius * 0.5
		local startVec = (unit_pos - myHero_pos):normalized()	

		for i = 1, 95 do -- 475 / 5 = 95
			local checkPoint = myHero_pos + startVec * (distance + boundingRadius + 5 * i)
			local flags = NavMesh:GetCollisionFlags(Vec3(checkPoint))
			if flags == 2 or flags == 70 then -- 2 == wall, 70 == nexus building/turret
				wallCheck = true
				break
			end
		end
		return wallCheck 
	end

	function Vayne:CastE(unit)
		if self:CanE(unit) then 
			myHero.spellbook:CastSpell(E, unit.networkId)
		end
	end

	function Vayne:OnDraw()
		DrawHandler:Circle3D(myHero.position, myRange, Hex(230, 255, 0, 93))
	end

	--x--

	Pred = class()

	function Pred:_init()
		print("Pred_Class Loaded")
	end

	function Pred:GetPathIndex(unit, pathing)
	    local result = 1 
	    for i = 2, #pathing.paths do
	        local myHeroPos = Vector(myHero)
	        local iPath = Vector(pathing.paths[i])
	        local iMinusPath = Vector(pathing.paths[i-1])
	        if GetDistance(iPath,myHeroPos) < GetDistance(iMinusPath,myHeroPos) and 
	            GetDistance(iPath,iMinusPath) <= GetDistance(iMinusPath, myHeroPos) and i ~= #pathing.paths then
	            result = i 
	        end
	    end
	    return result
	end 	

	function Pred:GetPaths(unit)
   		local result = {}
   		local pathing = unit.aiManagerClient.navPath
   		if pathing and pathing.paths and #pathing.paths > 1 then        
   		    for i = self:GetPathIndex(unit, pathing), #pathing.paths do 
   		        local path = pathing.paths[i]
   		        insert(result, Vector(path))
   		    end  
   		    insert(result, 2, Vector(unit))   
   		else
   		    insert(result, Vector(unit))
   		end
   		return result
   	end	

   	function Pred:GetPred(unit, speed, delay)
   		local hPos = Vector(myHero) 
   		local tms = unit.characterIntermediate.movementSpeed
   		local paths = self:GetPaths(unit)
   		if #paths <= 2 then return paths[1] end 

   		local t = delay + GetLatency()/2000 

   		local dt = 0
   		local pPath = paths[2]

   		if speed < huge then 
   			for i = 3, #paths do 
   				local cPath = paths[i]
   				local dir = (cPath - pPath):normalized()
   				local velocity = dir*tms 
   				local a = velocity * velocity - speed * speed 
   				if a == 0 then return nil end 
   				local vecBetween = hPos - pPath 
   				local b = 2 * velocity * vecBetween 
   				local c = vecBetween * vecBetween 
	
   				local radicand = b*b - 4*a*c 
   				if radicand < 0 then return nil end 
   				local sqrtRadicand = sqrt(radicand)
   				
   				local d = 2*a 
   				local t0 = (-b + sqrtRadicand) / d 
   				local t1 = (-b - sqrtRadicand) / d 
	
   				local time
   				if t0 < t1 then 
   					if t1 < 0 then return nil end
   					if t0 >= 0 then 
   						time = t0 
   					else 
   						time = t1 
   					end
   				else 
   					if t0 < 0 then return nil end 
   					if t1 >= 0 then 
   						time = t1 
   					else
   						time = t0 
   					end 
   				end
	
   				t = t + time 
   				local dist = GetDistance(cPath, pPath)
	
   				if t - dt < dist / tms or i == #paths then 
   					return pPath + dir * (t*tms)
   				end
   				pPath = cPath 
   				dt = dt + (dist / tms)
   			end
   		end
   		return pPath + (paths[3] - pPath):normalized() * (t*tms) 
   	end

   	local function VectorPointProjectionOnLineSegment(v1, v2, v)
		local cx, cy, ax, ay, bx, by = v.x, v.z, v1.x, v1.z, v2.x, v2.z
		local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
		local pointLine = { x = ax + rL * (bx - ax), z = ay + rL * (by - ay) }
		local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
		local isOnSegment = rS == rL
		local pointSegment = isOnSegment and pointLine or {x = ax + rS * (bx - ax), z = ay + rS * (by - ay)}
		return pointSegment, pointLine, isOnSegment
	end	

	local function Mcollision(pos1, pos2, width)
		local count = 0
		for k, v in pairs(ObjectManager:GetEnemyMinions()) do 
			if v.isValid and v.isDead == false then 
				local pos3 = v.position
				local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(pos1, pos2, pos3)
				width = width + 33 --v.boundingRadius 66/67
				if isOnSegment and GetDistance(pointSegment, pos3) < width and GetDistance(pos1, pos2) > GetDistance(pos1, pos3) then
					count = count + 1
				end
			end
		end
		return count 
	end


	KogMaw = class()

	function KogMaw:_init()
		AddEvent(Events.OnTick, function() self:OnTick() end)
		print("KogMaw Loaded")	
	end

	function KogMaw:OnTick()
		if myHero.isDead == false and MenuGUI.isChatOpen == false then 
			if orbMode == 1 then
				self:Combo()
			end
		end
	end

	function KogMaw:Combo()
		if Ready(W) then 
			local target = GetHeroTarget(myRange + 110 + 20 * myHero.spellbook:Spell(W).level)
			if target then 
				myHero.spellbook:CastSpell(W, myId)
			end
		end
		local range = 900 + 300 * myHero.spellbook:Spell(R).level
		local target = orbHeroTarget or GetHeroTarget(range)
		if target and CanMove() and time < lastAA + attackDelay and (lastSpell.isSpell == false or GetDistance(target) > myRange) and time - lastSpell.spellTime > 0.5 then 
			if Ready(Q) and myHero.mana/myHero.maxMana > 0.15 then 
				local pred = Pred:GetPred(target, 1600, 0.25)
				if pred and GetDistance(pred) < 1175 then 
					if Mcollision(myHero.position, pred, 80) == 0 then 
						myHero.spellbook:CastSpell(Q, Vec3(pred))
						return
					end
				end
			end
			if Ready(E) and myHero.mana/myHero.maxMana > 0.20 then 
				local pred = Pred:GetPred(target, 1400, 0.25) 
				if pred and GetDistance(pred) < 1200 then 
					myHero.spellbook:CastSpell(E, Vec3(pred))
					return 
				end
			end
			if Ready(R) and myHero.mana/myHero.maxMana > 0.33 then 
				for i,v in pairs(ObjectManager:GetEnemyHeroes()) do 
					if v.isValid and v.isDead == false and (v.isInvulnerable == false or v.charName == "Anivia" or v.charName == "Zac") then 
						local debuff = {_STUN, _TAUNT, _SNARE, _SLEEP, _CHARM, _SUPRESS, _AIRBORNE, _SLOW}
						for i = 1, #debuff do 
							if target.buffManager:HasBuffOfType(debuff[i]) then         
            					local pred = Pred:GetPred(target, huge, 1.2)
								if pred and GetDistance(pred) < range then 
									myHero.spellbook:CastSpell(R, Vec3(pred))
									break
								end
							end
						end
					end
				end
			end
		end
	end

	function KogMaw:OnDraw()
		DrawHandler:Circle3D(myHero.position, myRange, Hex(230, 255, 0, 93))
	end		
	--x--

	function OnLoad()
		Orbwalker:_init()
		if char_name == "Vayne" then 
			Vayne:_init()
		elseif char_name == "KogMaw" then 
			Pred:_init()
			KogMaw:_init()
		end
	end




