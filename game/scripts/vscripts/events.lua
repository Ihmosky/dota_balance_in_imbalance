require('events/imba_events')

-- This file contains all barebones-registered events and has already set up the passed-in parameters for your use.
if CDOTA_PlayerResource.IMBA_PLAYER_DEATH_STREAK == nil then
	CDOTA_PlayerResource.IMBA_PLAYER_DEATH_STREAK = {}
end
if CDOTA_PlayerResource.IMBA_PLAYER_HERO == nil then
	CDOTA_PlayerResource.IMBA_PLAYER_HERO = {}
end
if CDOTA_PlayerResource.IMBA_PLAYER_KILL_STREAK == nil then
	CDOTA_PlayerResource.IMBA_PLAYER_KILL_STREAK = {}
end

-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
	DebugPrint('[BAREBONES] Player Disconnected ' .. tostring(keys.userid))
	DebugPrintTable(keys)

	local name = keys.name
	local networkid = keys.networkid
	local reason = keys.reason
	local userid = keys.userid

end

local selectedHero = {}

local tick = 0
local waitTick = 20
if GameRules:IsCheatMode() then
	waitTick = 3
end

-- The overall game state has changed
function GameMode:OnGameRulesStateChange(keys)
	DebugPrint("[BAREBONES] GameRules State Changed")
	DebugPrintTable(keys)

	local newState = GameRules:State_Get()

	print("Game State:",newState)

	if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		Timers:CreateTimer(1.0, function()
			PauseGame(false)
			if GameRules:State_Get() > DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
				return nil
			end
			return 1.0
		end
		)
	end

	if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		Timers:CreateTimer(5, function()
			Notifications:BottomToAll({text="#DOTA_IMBA_WAIT_WARN", duration = 5})
			return nil
		end
		)
	end

	if newState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
		for i=0, 19 do -- force that noob random
			if PlayerResource:IsValidPlayer(i) and not PlayerResource:HasSelectedHero(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
				PlayerResource:GetPlayer(i):MakeRandomHeroSelection()
				PlayerResource:SetCanRepick(i, false)
			end
			CDOTA_PlayerResource.IMBA_PLAYER_DEATH_STREAK[i + 1] = 0
			CDOTA_PlayerResource.IMBA_PLAYER_KILL_STREAK[i + 1] = 0
		end
	end

	if newState == DOTA_GAMERULES_STATE_PRE_GAME then--and not GameRules:IsCheatMode() then
		IMBA:StartGameAPI()
		--[[Timers:CreateTimer(0, function()
			local thinkers = Entities:FindAllByName("npc_dota_thinker")
			for _, thinker in pairs(thinkers) do
				local buffs = thinker:FindAllModifiers()
				for _, buff in pairs(buffs) do
					if buff:GetDuration() < 0.0 or buff:GetElapsedTime() >= 20.0 then
						DebugDrawCircle(thinker:GetAbsOrigin(), Vector(255,0,0), 255, 60, false, 30)
						DebugDrawText(thinker:GetAbsOrigin(), buff:GetName(), false, 30)
					end
				end
			end
			return 30.0
		end
		)]]
		if USE_CUSTOM_TEAM_COLORS_FOR_PLAYERS then
			for i=0, 23 do
				PlayerResource:SetCustomPlayerColor(i, PLAYER_COLORS[i][1], PLAYER_COLORS[i][2], PLAYER_COLORS[i][3])
			end
		end
		local announce = false
		Timers:CreateTimer({useGameTime = false,
			callback = function()
				if tick == 0 then
					local towers = FindUnitsInRadius(0, Vector(0,0,0), nil, 50000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
					for _, tower in pairs(towers) do
						if string.find(tower:GetUnitName(), "_tower1_") then --T1 Tower set
							local ability = tower:AddAbility(RandomFromTable(IMBA_TOWER_ABILITY_1))
							ability:SetLevel(1)
						end
						if string.find(tower:GetUnitName(), "_tower2_") then --T2 Tower set
							SetCreatureHealth(tower, tower:GetHealth() + 800, true)
							for i=1, 2 do
								local abilityName = RandomFromTable(IMBA_TOWER_ABILITY_2)
								while true do
									if not tower:HasAbility(abilityName) then
										local ability = tower:AddAbility(abilityName)
										ability:SetLevel(2)
										break
									else
										abilityName = RandomFromTable(IMBA_TOWER_ABILITY_2)
									end
								end
							end
						end
						if string.find(tower:GetUnitName(), "_tower3_") then --T3 Tower set
							SetCreatureHealth(tower, tower:GetHealth() + 1300, true)
							for i=1, 3 do
								local abilityName = RandomFromTable(IMBA_TOWER_ABILITY_3)
								while true do
									if not tower:HasAbility(abilityName) then
										local ability = tower:AddAbility(abilityName)
										ability:SetLevel(2)
										break
									else
										abilityName = RandomFromTable(IMBA_TOWER_ABILITY_3)
									end
								end
							end
							local abi = tower:AddAbility("imba_tower_healer_protect")
							abi:SetLevel(1)
						end
						if string.find(tower:GetUnitName(), "_tower4") then --T4 Tower set
							SetCreatureHealth(tower, tower:GetHealth() + 2200, true)
							for i=1, 3 do
								local abilityName = RandomFromTable(IMBA_TOWER_ABILITY_4)
								while true do
									if not tower:HasAbility(abilityName) then
										local ability = tower:AddAbility(abilityName)
										ability:SetLevel(3)
										break
									else
										abilityName = RandomFromTable(IMBA_TOWER_ABILITY_4)
									end
								end
							end
							local abi = tower:AddAbility("imba_tower_the_last_line")
							abi:SetLevel(1)
						end
						if string.find(tower:GetUnitName(), "_melee_rax_") then
							SetCreatureHealth(tower, 4000, true)
						end
						if string.find(tower:GetUnitName(), "_range_rax_") then
							SetCreatureHealth(tower, 3200, true)
						end
					end
				end
				if tick >= 2 and not announce then
					announce = true
					Notifications:BottomToAll({text="#DOTA_IMBA_WAIT_20_SCES", duration = waitTick - 2})
				end
				PauseGame(true)
				tick = tick + 0.1
				if tick < waitTick then
					return 0.1
				else
					PauseGame(false)
					GameMode:ResetCameraForAll()
					return nil
				end
			end
		})

		Timers:CreateTimer(5, function()
			Notifications:BottomToAll({text="#imba_introduction_line_01", duration = 2.9})
			return nil
		end
		)
		Timers:CreateTimer(8, function()
			Notifications:BottomToAll({text="#imba_introduction_line_02", duration = 2.9})
			return nil
		end
		)
		Timers:CreateTimer(11, function()
			Notifications:BottomToAll({text="#imba_introduction_line_03", duration = 2.9})
			return nil
		end
		)
		Timers:CreateTimer(14, function()
			Notifications:BottomToAll({text="#imba_introduction_line_04", duration = 3, style={["font-size"] = "24px"}})
			return nil
		end
		)
	end

	if newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then -- IMBA Tower Ability set
		SetPlayerInfo()
	end
end

function GameMode:ResetCameraForAll()
	for i=0, 19 do -- force that noob random
		if PlayerResource:IsValidPlayer(i) and PlayerResource:HasSelectedHero(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
			Timers:CreateTimer({useGameTime = false, endTime = 10.0,
			callback = function()
					local hero = PlayerResource:GetPlayer(i):GetAssignedHero()
					local cameraDis = 1134
					PlayerResource:SetCameraTarget(i, hero)
					--GameRules:GetGameModeEntity():SetCameraDistanceOverride(cameraDis)
					PlayerResource:SetCameraTarget(i, nil)
					return nil
				end
			})
		end
	end
end

roshan_spawn = false
roshan_pos = Vector(-2464.244629, 2016.373291, 232.000000)
roshan_kill = 0

local monkeyKingFound = false

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:OnNPCSpawned(keys)
	DebugPrint("[BAREBONES] NPC Spawned")
	DebugPrintTable(keys)

	local npc = EntIndexToHScript(keys.entindex)

	--Game Start Hero Set
	if npc:IsRealHero() and not npc:IsTempestDouble() and not npc:IsClone() and npc:GetPlayerID() and npc:GetPlayerID() and npc:GetPlayerID() + 1 > 0 and CDOTA_PlayerResource.IMBA_PLAYER_HERO[npc:GetPlayerID() + 1] == nil then
		
		Timers:CreateTimer({useGameTime = false, endTime = 1.0,
			callback = function()
				if CDOTA_PlayerResource.IMBA_PLAYER_HERO[npc:GetPlayerID() + 1] == nil then
					CDOTA_PlayerResource.IMBA_PLAYER_HERO[npc:GetPlayerID() + 1] = npc
				end

				npc:AddExperience(1, 0, false, false)
				npc:AddExperience(-1, 0, false, false)
				return nil
			end
		})


		npc:AddNewModifier(npc, nil, "modifier_imba_talent_modifier_adder", {})

		local chicken = npc:AddItemByName("item_courier")
		npc:CastAbilityNoTarget(chicken, npc:GetPlayerID())
		PlayerResource:SetGold(npc:GetPlayerID(), IMBA_STARTING_GOLD, true)

		if PlayerResource:HasRandomed(npc:GetPlayerID()) then
			npc:AddItemByName("item_faerie_fire")
			npc:AddItemByName("item_imba_mango")
		end
		
		Timers:CreateTimer(0, function()
			-- a fresh Tp
			for i=0, 8 do
				local item = npc:GetItemInSlot(i)
				if item and item:GetName() == "item_tpscroll" then
					item:EndCooldown()
					return nil
				end
			end
			return 0.2
		end
		)
	end

	--Roshan Setup
	if npc:GetName() == "npc_dota_roshan" and not roshan_spawn then
		roshan_spawn = true
		npc:AddNewModifier(npc, nil, "modifier_imba_storm_bolt_caster", {})
		npc:SetAbsOrigin(Vector(40000,40000,-40000))
		Timers:CreateTimer(2.0, function()
			IMBA:SpawnRoshan()
			return nil
		end
		)
	end

	--Courier Setuo
	if npc:IsCourier() and npc:HasAbility("imba_courier_speed") then
		npc:FindAbilityByName("imba_courier_speed"):SetLevel(1)
	end

	--modifier_imba_unlimited_level_powerup
	if npc:IsHero() and not npc.firstSpawn then
		npc:AddNewModifier(npc, nil, "modifier_imba_unlimited_level_powerup", {})
	end

	-- Set Talent Ability
	if not npc.firstSpawn then
		for i = 0, 23 do
			local ability = npc:GetAbilityByIndex(i)
			if ability and ability.IsTalentAbility and ability:IsTalentAbility() then
				ability:SetLevel(1)
			end
		end
	end

	if not npc.firstSpawn then
		npc.firstSpawn = true
		npc.splitattack = true
	end

end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function GameMode:OnEntityHurt(keys)
	--DebugPrint("[BAREBONES] Entity Hurt")
	--DebugPrintTable(keys)

	local damagebits = keys.damagebits -- This might always be 0 and therefore useless
	if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
		local attacker = EntIndexToHScript(keys.entindex_attacker)
		local target = EntIndexToHScript(keys.entindex_killed)

		-- The ability/item used to damage, or nil if not damaged by an item/ability
		local ability = nil

		if keys.entindex_inflictor ~= nil then
			ability = EntIndexToHScript( keys.entindex_inflictor )
		end
	end
end

-- An item was picked up off the ground
function GameMode:OnItemPickedUp(keys)
	DebugPrint( '[BAREBONES] OnItemPickedUp' )
	DebugPrintTable(keys)

	local unitEntity = nil
	if keys.UnitEntitIndex then
		unitEntity = EntIndexToHScript(keys.UnitEntitIndex)
	elseif keys.HeroEntityIndex then
		unitEntity = EntIndexToHScript(keys.HeroEntityIndex)
	end

	local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function GameMode:OnPlayerReconnect(keys)
	DebugPrint( '[BAREBONES] OnPlayerReconnect' )
	DebugPrintTable(keys) 
	local new_state = GameRules:State_Get()
	--[[if new_state > DOTA_GAMERULES_STATE_HERO_SELECTION then
		local playerID = keys.PlayerID

		if PlayerResource:HasSelectedHero(playerID) or PlayerResource:HasRandomed(playerID) then
			-- This playerID already had a hero before disconnect
		else
			Timers:CreateTimer(5, function()
				if PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
					while true do
						local heroname = RandomFromTable(HeroList)[1]
						if not PlayerResource:IsHeroSelected(heroname) then
							local hero = CreateHeroForPlayer(PlayerResource:GetSelectedHeroName(playerID), PlayerResource:GetPlayer(playerID))
							hero:SetControllableByPlayer(playerID, false)
							if PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
								FindClearSpaceForUnit(hero, Vector(-6811, -6686, 512), true)
							else
								FindClearSpaceForUnit(hero, Vector(6985, 6326, 512), true)
							end
							break
						end
					end
					DebugPrint("[BAREBONES] Randomed a hero for a player number "..playerID.." that reconnected.")
					return nil
				end
				if PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_DISCONNECTED then
					return nil
				end
				return 1.0
			end
			)
		end
	end]]
end

-- An item was purchased by a player
function GameMode:OnItemPurchased( keys )
	DebugPrint( '[BAREBONES] OnItemPurchased' )
	DebugPrintTable(keys)

	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end

	-- The name of the item purchased
	local itemName = keys.itemname 
	
	-- The cost of the item purchased
	local itemcost = keys.itemcost
	
end

-- An ability was used by a player
function GameMode:OnAbilityUsed(keys)
	DebugPrint('[BAREBONES] AbilityUsed')
	DebugPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local abilityname = keys.abilityname
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function GameMode:OnNonPlayerUsedAbility(keys)
	DebugPrint('[BAREBONES] OnNonPlayerUsedAbility')
	DebugPrintTable(keys)

	local abilityname=  keys.abilityname
end

-- A player changed their name
function GameMode:OnPlayerChangedName(keys)
	DebugPrint('[BAREBONES] OnPlayerChangedName')
	DebugPrintTable(keys)

	local newName = keys.newname
	local oldName = keys.oldName
end

-- A player leveled up an ability
function GameMode:OnPlayerLearnedAbility( keys)
	DebugPrint('[BAREBONES] OnPlayerLearnedAbility')
	DebugPrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname

end

-- A channelled ability finished by either completing or being interrupted
function GameMode:OnAbilityChannelFinished(keys)
	DebugPrint('[BAREBONES] OnAbilityChannelFinished')
	DebugPrintTable(keys)

	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

-- A player leveled up
function GameMode:OnPlayerLevelUp(keys)
	DebugPrint('[BAREBONES] OnPlayerLevelUp')
	DebugPrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local level = keys.level
	local hero = player:GetAssignedHero()
	local hero_level = hero:GetLevel()

	hero:SetCustomDeathXP(HERO_XP_BOUNTY_PER_LEVEL[hero_level])
end

-- A player last hit a creep, a tower, or a hero
function GameMode:OnLastHit(keys)
	DebugPrint('[BAREBONES] OnLastHit')
	DebugPrintTable(keys)

	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local killedEnt = EntIndexToHScript(keys.EntKilled)
end

-- A tree was cut down by tango, quelling blade, etc
function GameMode:OnTreeCut(keys)
	DebugPrint('[BAREBONES] OnTreeCut')
	DebugPrintTable(keys)

	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A rune was activated by a player
function GameMode:OnRuneActivated (keys)
	DebugPrint('[BAREBONES] OnRuneActivated')
	DebugPrintTable(keys)
	--PrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local rune = keys.rune

	if rune == DOTA_RUNE_ILLUSION then
		IMBA:PlayerPickUpIllusionRune(player)
	end


	--[[ Rune Can be one of the following types
	DOTA_RUNE_DOUBLEDAMAGE
	DOTA_RUNE_HASTE
	DOTA_RUNE_HAUNTED
	DOTA_RUNE_ILLUSION
	DOTA_RUNE_INVISIBILITY
	DOTA_RUNE_BOUNTY
	DOTA_RUNE_MYSTERY
	DOTA_RUNE_RAPIER
	DOTA_RUNE_REGENERATION
	DOTA_RUNE_SPOOKY
	DOTA_RUNE_TURBO
	]]
end

-- A player took damage from a tower
function GameMode:OnPlayerTakeTowerDamage(keys)
	DebugPrint('[BAREBONES] OnPlayerTakeTowerDamage')
	DebugPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked a hero
function GameMode:OnPlayerPickHero(keys)
	DebugPrint('[BAREBONES] OnPlayerPickHero')
	DebugPrintTable(keys)

	local heroClass = keys.hero
	local heroEntity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit(keys)
	DebugPrint('[BAREBONES] OnTeamKillCredit')
	DebugPrintTable(keys)
	--PrintTable(keys)

	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
	local numKills = keys.herokills
	local killerTeamNumber = keys.teamnumber
end

-- An entity died
function GameMode:OnEntityKilled( keys )
	DebugPrint( '[BAREBONES] OnEntityKilled Called' )
	DebugPrintTable( keys )
	

	-- The Unit that was Killed
	local killed_unit = EntIndexToHScript( keys.entindex_killed )

	-- The Killing entity
	local killer = nil

	if keys.entindex_attacker ~= nil then
		killer = EntIndexToHScript( keys.entindex_attacker )
	end

	-- The ability/item used to kill, or nil if not killed by an item/ability
	local ability = nil

	if keys.entindex_inflictor ~= nil then
		ability = EntIndexToHScript( keys.entindex_inflictor )
	end

	local damagebits = keys.damagebits -- This might always be 0 and therefore useless

	--GameMode:_OnEntityKilled( keys )

	-------------------------------------------------------------------------------------------------
	-- IMBA: True Hero Death Setup (bb, respawn timer, death streak, lose gold)
	-------------------------------------------------------------------------------------------------

	local victim_respawn = killed_unit
	if killed_unit:IsClone() then
		victim_respawn = killed_unit:GetCloneSource()
	end
	
	if victim_respawn:IsRealHero() and not victim_respawn:IsReincarnating() then

		local player_id = victim_respawn:GetPlayerID()
		local game_time = GameRules:GetDOTATime(false, false)

		local respawn_timer = victim_respawn:GetIMBARespawnTime()

		if game_time > 1800 then
			respawn_timer = respawn_timer + math.floor((game_time - 1800) / 60)
			GameRules:SetSafeToLeave(true)
		end

		-- Set up the respawn timer
		victim_respawn:SetTimeUntilRespawn(respawn_timer)

		local buy_back_cost = 0

		buy_back_cost = BUYBACK_BASE_COST + PlayerResource:GetGoldSpentOnBuybacks(victim_respawn:GetPlayerID()) / 20 + math.min(victim_respawn:GetLevel(), 25) * BUYBACK_COST_PER_LEVEL + math.max(victim_respawn:GetLevel() - 25, 0) * BUYBACK_COST_PER_LEVEL_AFTER_25 + game_time * BUYBACK_COST_PER_SECOND

		if GameRules:IsCheatMode() then
			--buy_back_cost = 0
		end

		PlayerResource:SetCustomBuybackCost(victim_respawn:GetPlayerID(), buy_back_cost)

		-- Setup buyback cooldown
		local buyback_cooldown = 0
		if BUYBACK_COOLDOWN_ENABLED and game_time > BUYBACK_COOLDOWN_START_POINT then
			buyback_cooldown = math.min(BUYBACK_COOLDOWN_GROW_FACTOR * (game_time - BUYBACK_COOLDOWN_START_POINT), BUYBACK_COOLDOWN_MAXIMUM)
		end

		PlayerResource:SetCustomBuybackCooldown(player_id, buyback_cooldown)
		--PlayerResource:SetBuybackCooldownTime(player_id, buyback_cooldown)
		--victim_respawn:SetBuybackCooldownTime(buyback_cooldown)

		--death streak
		if killer and killer:IsRealHero() and IsEnemy(killer, victim_respawn) then
			local line_duration = 7

			local death_player = victim_respawn:GetPlayerID()
			local kill_player = killer:GetPlayerID()

			CDOTA_PlayerResource.IMBA_PLAYER_DEATH_STREAK[death_player + 1] = math.min(CDOTA_PlayerResource.IMBA_PLAYER_DEATH_STREAK[death_player + 1] + 1, 10)
			CDOTA_PlayerResource.IMBA_PLAYER_DEATH_STREAK[kill_player + 1] = 0
			CDOTA_PlayerResource.IMBA_PLAYER_KILL_STREAK[death_player + 1] = 0
			CDOTA_PlayerResource.IMBA_PLAYER_KILL_STREAK[kill_player + 1] = CDOTA_PlayerResource.IMBA_PLAYER_KILL_STREAK[kill_player + 1] + 1

			if CDOTA_PlayerResource.IMBA_PLAYER_DEATH_STREAK[death_player + 1] >= 3 then
				Notifications:BottomToAll({hero = victim_respawn:GetName(), duration = line_duration})
				Notifications:BottomToAll({text = PlayerResource:GetPlayerName(death_player).." ", duration = line_duration, continue = true})
				Notifications:BottomToAll({text = "#imba_deathstreak_"..CDOTA_PlayerResource.IMBA_PLAYER_DEATH_STREAK[death_player + 1], duration = line_duration, continue = true})
			end
		end

		--Lose Gold
		local maxLoseGold = PlayerResource:GetUnreliableGold(victim_respawn:GetPlayerID())
		local netWorth = PlayerResource:GetGoldSpentOnItems(victim_respawn:GetPlayerID())
		PlayerResource:ModifyGold(victim_respawn:GetPlayerID(), 0 - math.min(maxLoseGold, 50 + netWorth / 40), false, DOTA_ModifyGold_Death)

		print(victim_respawn:GetName(), "respawn time:", victim_respawn:GetIMBARespawnTime(), "bb cd:", buyback_cooldown, "bb cost:", buy_back_cost, "lose gold:", math.min(maxLoseGold, 50 + netWorth / 40))
	end

	-------------------------------------------------------------------------------------------------
	-- IMBA: Roshan
	-------------------------------------------------------------------------------------------------

	if killed_unit:GetName() == "npc_dota_roshan" then
		for i=2, roshan_kill do
			local drop_cheese = CreateItem("item_imba_cheese", nil, nil)
			if drop_cheese then
				CreateItemOnPositionSync(killed_unit:GetAbsOrigin(), drop_cheese)
				drop_cheese:LaunchLoot(false, 100, 0.5, killed_unit:GetAbsOrigin() + RandomVector(100))
			end
		end
		if roshan_kill >= 15 then
			local drop_cheese = CreateItem("item_aegis", nil, nil)
			if drop_cheese then
				CreateItemOnPositionSync(killed_unit:GetAbsOrigin(), drop_cheese)
				drop_cheese:LaunchLoot(false, 100, 0.5, killed_unit:GetAbsOrigin() + RandomVector(100))
			end
		end
		Timers:CreateTimer(CUSTOM_ROSHAN_RESPAWN, function()
			IMBA:SpawnRoshan()
			return nil
		end
		)
	end

	-------------------------------------------------------------------------------------------------
	-- IMBA: Lion ult refresh
	-------------------------------------------------------------------------------------------------

	if ability and ability:GetName() == "imba_lion_finger_of_death" and ability.KillCredit then
		ability:KillCredit(killed_unit)
	end

	-------------------------------------------------------------------------------------------------
	-- IMBA: Necrolyte Reapers Scythe Permanent Debuff
	-------------------------------------------------------------------------------------------------

	if ability and ability:GetName() == "imba_necrolyte_reapers_scythe" and killed_unit:IsRealHero() then
		killed_unit:AddNewModifierWhenPossible(ability:GetCaster(), ability, "modifier_imba_reapers_scythe_permanent", {})
		if ability:GetCaster():HasScepter() and ability:GetCaster():HasAbility("imba_necrolyte_sadist") and ability:GetCaster():FindAbilityByName("imba_necrolyte_sadist"):GetLevel() > 0 then
			local allies = FindUnitsInRadius(ability:GetCaster():GetTeamNumber(), killed_unit:GetAbsOrigin(), nil, ability:GetSpecialValueFor("sadist_aoe_scepter"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			local sadist = ability:GetCaster():FindAbilityByName("imba_necrolyte_sadist")
			for _, ally in pairs(allies) do
				if ally ~= ability:GetCaster() then
					for i=1, ability:GetSpecialValueFor("stacks_scepter") do
						local buff = ally:AddNewModifier(ability:GetCaster(), sadist, "modifier_imba_sadist_effect", {duration = sadist:GetSpecialValueFor("regen_duration")})
						buff:SetStackCount(buff:GetStackCount() + 1)
					end
					ally:AddNewModifier(ability:GetCaster(), sadist, "modifier_imba_sadist_stack", {})
				end
			end
		end
	end

	-------------------------------------------------------------------------------------------------
	-- IMBA: Ancient destruction detection
	-------------------------------------------------------------------------------------------------

	if killed_unit:GetUnitName() == "npc_dota_badguys_fort" then
		GAME_WINNER_TEAM = DOTA_TEAM_GOODGUYS
		GameRules:MakeTeamLose(DOTA_TEAM_BADGUYS)
		GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
		IMBA:EndGameAPI()
		UpDatePlayerInfo()
	elseif killed_unit:GetUnitName() == "npc_dota_goodguys_fort" then
		GAME_WINNER_TEAM = DOTA_TEAM_BADGUYS
		GameRules:MakeTeamLose(DOTA_TEAM_GOODGUYS)
		GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
		IMBA:EndGameAPI()
		UpDatePlayerInfo()
	end

end



-- This function is called 1 to 2 times as the player connects initially but before they 
-- have completely connected
function GameMode:PlayerConnect(keys)
	DebugPrint('[BAREBONES] PlayerConnect')
	DebugPrintTable(keys)
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
	DebugPrint('[BAREBONES] OnConnectFull')
	DebugPrintTable(keys)
	
	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)
	
	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
function GameMode:OnIllusionsCreated(keys)
	DebugPrint('[BAREBONES] OnIllusionsCreated')
	DebugPrintTable(keys)

	local originalEntity = EntIndexToHScript(keys.original_entindex)
end

-- This function is called whenever an item is combined to create a new item
function GameMode:OnItemCombined(keys)
	DebugPrint('[BAREBONES] OnItemCombined')
	DebugPrintTable(keys)

	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end
	local player = PlayerResource:GetPlayer(plyID)

	-- The name of the item purchased
	local itemName = keys.itemname 
	
	-- The cost of the item purchased
	local itemcost = keys.itemcost
end

-- This function is called whenever an ability begins its PhaseStart phase (but before it is actually cast)
function GameMode:OnAbilityCastBegins(keys)
	DebugPrint('[BAREBONES] OnAbilityCastBegins')
	DebugPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local abilityName = keys.abilityname
end

-- This function is called whenever a tower is killed
function GameMode:OnTowerKill(keys)
	DebugPrint('[BAREBONES] OnTowerKill')
	DebugPrintTable(keys)

	local gold = keys.gold
	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local team = keys.teamnumber
end

-- This function is called whenever a player changes there custom team selection during Game Setup 
function GameMode:OnPlayerSelectedCustomTeam(keys)
	DebugPrint('[BAREBONES] OnPlayerSelectedCustomTeam')
	DebugPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.player_id)
	local success = (keys.success == 1)
	local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target
function GameMode:OnNPCGoalReached(keys)
	DebugPrint('[BAREBONES] OnNPCGoalReached')
	DebugPrintTable(keys)

	local goalEntity = EntIndexToHScript(keys.goal_entindex)
	local nextGoalEntity = EntIndexToHScript(keys.next_goal_entindex)
	local npc = EntIndexToHScript(keys.npc_entindex)
end

-- This function is called whenever any player sends a chat message to team or All
function GameMode:OnPlayerChat(keys)
	local teamonly = keys.teamonly
	local userID = keys.userid
	--local playerID = self.vUserIds[userID]:GetPlayerID()

	local text = keys.text

	if not (string.byte(text) == 45) then
		return nil
	end

	for str in string.gmatch(text, "%S+") do
		if str == "-json" then
			IMBA:EndGameAPI()
		end
	end

end