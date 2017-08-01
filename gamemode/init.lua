AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "items.lua" )

DEFINE_BASECLASS( "gamemode_base")

resource.AddFile( "materials/mm/com_shield003a.vmt" )
resource.AddFile( "materials/mm/compass_back.vmt" )
resource.AddFile( "materials/mm/compass_pointer.vmt" )
resource.AddFile( "materials/mm/concretefloor008a.vmt" )
resource.AddFile( "materials/mm/concretewall013a.vmt" )
resource.AddFile( "materials/mm/dev_concretefloor004a.vmt" )
resource.AddFile( "materials/mm/dev_concretefloor006a.vmt" )
resource.AddFile( "materials/mm/dev_measuregeneric01b.vmt" )
resource.AddFile( "materials/mm/fluorescentwhite001a.vmt" )
resource.AddFile( "materials/mm/glass.vmt" )
resource.AddFile( "materials/mm/glasswindow018a_cracked.vmt" )
resource.AddFile( "materials/mm/hud_map_basic.vmt" )
resource.AddFile( "materials/mm/hud_map_door_e.vmt" )
resource.AddFile( "materials/mm/hud_map_door_n.vmt" )
resource.AddFile( "materials/mm/hud_map_door_s.vmt" )
resource.AddFile( "materials/mm/hud_map_door_w.vmt" )
resource.AddFile( "materials/mm/hud_map_player.vmt" )
resource.AddFile( "materials/mm/hud_map_stairs.vmt" )
resource.AddFile( "materials/mm/metaldoor032b.vmt" )
resource.AddFile( "materials/mm/metalduct001a.vmt" )
resource.AddFile( "materials/mm/metalstainless01.vmt" )
resource.AddFile( "materials/mm/mini_map.vmt" )
resource.AddFile( "materials/mm/tvscreen005a.vmt" )

resource.AddFile( "materials/mm/laser_trap_killicon.vmt")
resource.AddFile( "materials/mm/shock_trap_killicon.vmt")

resource.AddFile( "models/mm/laser_trap.mdl" )
resource.AddFile( "models/mm/maze_block.mdl" )
resource.AddFile( "models/mm/maze_block_ud.mdl" )
resource.AddFile( "models/mm/maze_door.mdl" )
resource.AddFile( "models/mm/shock_trap.mdl" )
resource.AddFile( "models/mm/snare_trap.mdl" )

include( "shared.lua" )

mm_sv_globals = {}

mm_sv_globals.traps = { "laser_trap", "shock_trap" , "snare_trap" }
	
mm_sv_globals.blocks = {}

mm_sv_globals.roundEntity = ""

mm_sv_globals.prizePool = 0

mm_sv_globals.playersOnServer = 0

mm_sv_globals.playersInRound = {}

mm_sv_globals.finishedPlayers = {}

mm_sv_globals.miniMapPos = Vector(0,0,0)

mm_sv_globals.hasMaze = false

mm_sv_globals.miniEnt = ""

mm_sv_globals.generatingMaze = false

for x = 0, 29 do
	mm_sv_globals.blocks[x] = {}
	for y = 0, 29 do
		mm_sv_globals.blocks[x][y] = nil
	end
end

function GM:Initialize()
	
	util.AddNetworkString("update_maze_size")
	util.AddNetworkString("in_maze")
	util.AddNetworkString("get_exit_cam")
	util.AddNetworkString("request_exit_cam")
	util.AddNetworkString("credit_info")
	util.AddNetworkString("request_credit_info")
	util.AddNetworkString("mini_map_pos")
	util.AddNetworkString("maze_zero")
	util.AddNetworkString("world_size")
	util.AddNetworkString("req_world_size")
	util.AddNetworkString("req_maze_zero")
	util.AddNetworkString("req_maze_size")
	util.AddNetworkString("open_help") -- F1
	util.AddNetworkString("open_store") -- F2
	util.AddNetworkString("req_purchase")
	util.AddNetworkString("open_player") --F3	
	util.AddNetworkString("show_scores") --TAB	
	util.AddNetworkString("hud_message")
	util.AddNetworkString("play_sound")
	util.AddNetworkString("set_player_color")
	util.AddNetworkString("show_welcome")
	util.AddNetworkString("req_maze_dimensions")
	util.AddNetworkString("add_draw_box")
	util.AddNetworkString("set_player_model")
	util.AddNetworkString("req_room_from_server")
	util.AddNetworkString("rec_room_from_server")
	util.AddNetworkString("create_ragdoll")
	util.AddNetworkString("req_scores")
	util.AddNetworkString("rec_scores")
	
	for k, m in pairs(males) do
		util.PrecacheModel(m)
	end
	
	for k, f in pairs(females) do
		util.PrecacheModel(f)
	end
	
	healThePlayers()
	
end

function GM:PlayGUISound(ply, sound)
	
	net.Start("play_sound")
		net.WriteString(sound)
	net.Send(ply)
	
end

function GM:SendHudMessage(ply, msg, ttl)

	if type(ply) == "string" then
		
		net.Start("hud_message")
			net.WriteString(ply or "-._.-= Blank Message =-._.-")
			net.WriteFloat(msg)
		net.Broadcast()
	else
		
		if IsValid(ply) && ply:IsPlayer() then
		
			net.Start("hud_message")
				net.WriteString(msg or "-._.-= Blank Message =-._.-")
				net.WriteFloat(ttl)
			net.Send(ply)
		end
		
	end
	
end


net.Receive("req_scores", function (len, ply) 
	
	local playas = player.GetAll()
	local plyCount = #playas
	
	net.Start("rec_scores")
		net.WriteInt(plyCount, 32)
		
		for k, oPly in pairs(playas) do
			net.WriteString(oPly:Nick())
			net.WriteVector(Vector(oPly.mazesRan, oPly.mazesCompleted, oPly.mazesIncomplete))
			net.WriteInt(oPly.credits, 32)
		end
	
	net.Send(ply)
	
end)

net.Receive("set_player_model", function (len, ply) 
	
	local newModel = net.ReadString()
	
	ply:SetModel(newModel)
	ply.curPosMC = ply:GetPos()
	ply.curAngMC = ply:GetAngles()
	ply.mdlChange = true
	
	ply:Spawn()
	
end)


net.Receive("req_room_from_server", function (len, ply) 
	
	local roomPos = net.ReadVector()
	
	if GAMEMODE.curMaze then
	
		if GAMEMODE.curMaze[roomPos.z] then
			
			if GAMEMODE.curMaze[roomPos.z][roomPos.x] then
			
				if GAMEMODE.curMaze[roomPos.z][roomPos.x][roomPos.y] then
					
					local sendRoom = GAMEMODE.curMaze[roomPos.z][roomPos.x][roomPos.y]
					
					net.Start("rec_room_from_server")
						net.WriteVector(roomPos)
						net.WriteBool(sendRoom.u)
						net.WriteBool(sendRoom.d)
						net.WriteBool(sendRoom.n)
						net.WriteBool(sendRoom.s)
						net.WriteBool(sendRoom.e)
						net.WriteBool(sendRoom.w)
					net.Send(ply)
					
				end
		
			end

		end

	end
	
end)

net.Receive("req_maze_size", function (len, ply) 
	
	if curX == 0 || curY == 0 then return end 
	
	net.Start("update_maze_size")
		net.WriteInt(curX, 32)
		net.WriteInt(curY, 32)
	net.Broadcast()
	
end)

net.Receive("set_player_color", function (len, ply) 
	
	local newColor = net.ReadVector()
	
	if !newColor then return end 
	
	ply:SetPlayerColor(newColor)
	
	ply:SetPData("mm_ply_color", newColor)
	
end)

net.Receive("req_purchase", function (len, ply) 
	
	local itemNum = net.ReadInt(32)
	local thisItem = items[itemNum]
	
	if !thisItem then return end
	
	local canBuy, errorMessage = thisItem:canBuy( ply )
	
	if canBuy then 
	
		GAMEMODE:ModifyPlayerCredit(ply, -thisItem.cost)
		thisItem.buyFunc(thisItem.class, thisItem.quantity, ply)
		GAMEMODE:PlayGUISound(ply, "buttons/blip1.wav")
		
	else
	
		GAMEMODE:SendHudMessage(ply, errorMessage, 0.25)
		GAMEMODE:PlayGUISound(ply, "buttons/combine_button_locked.wav")
		
	end
	
end)

net.Receive("req_maze_zero", function (len, ply) 
	
	net.Start("maze_zero")
		net.WriteVector(mazeZero:GetPos())
	net.Send(ply)
	
	
end)

net.Receive("req_world_size", function (len, ply) 
	
	local theWorld = game.GetWorld()
	local theWorldTable = theWorld:GetSaveTable()
	
	local worldMin = Vector(theWorldTable["m_WorldMins"])
	local worldMax = Vector(theWorldTable["m_WorldMaxs"])
	local worldSize = (worldMax - worldMin)
	
	net.Start("world_size")
		net.WriteVector(worldSize)
	net.Send(ply)
	
	
end)

net.Receive("request_credit_info", function (len, ply) 
	
	net.Start("credit_info")
		net.WriteInt(ply.credits,32)
	net.Broadcast()

end)

net.Receive("request_exit_cam", function (len, ply) 
	
	net.Start("get_exit_cam")
		net.WriteVector(exitCam:GetPos())
	net.Broadcast()

end)

--
-- Prize Structure
--
-- Round numbers up
--
-- each player in maze increases pool by 1000
-- 1st gets 1/2 pool
-- 2nd gets 1/2 remaining pool
-- 3rd gets 1/2 remaining pool
-- 4th on gets 1/x (x = num remaining players) remaining pool
-- DNF = 10% of 4th on prize

function GM:AwardPrizes()
	
	local curPrize = 0
	local dnfPrize = mm_sv_globals.prizePool * 0.05
	local totalPlayers = (#mm_sv_globals.finishedPlayers + #mm_sv_globals.playersInRound)
	
	for i = 1, #mm_sv_globals.finishedPlayers do
		
		local ply = mm_sv_globals.finishedPlayers[i]
		
		if IsValid(ply) then
			
			if i <= 3 then
				curPrize = mm_sv_globals.prizePool / 2
			else
				curPrize = mm_sv_globals.prizePool / (#mm_sv_globals.finishedPlayers - 3)
				dnfPrize = curPrize * 0.1
			end
			
			mm_sv_globals.prizePool = mm_sv_globals.prizePool - curPrize
			
			ply:ChatPrint("You placed " .. self:FormatPlace( i ) .. " !! You get " .. tostring(curPrize) .. " credits.")
			self:ModifyPlayerCredit(ply, curPrize)
		end
		
	end
		
	for k, ply in pairs(mm_sv_globals.playersInRound) do
		
		if IsValid(ply) then
			ply:ChatPrint("You didn't finish, but you still get " .. tostring(dnfPrize) .. " credits for trying.")
			self:ModifyPlayerCredit(ply, dnfPrize)
			ply.mazesIncomplete = ply.mazesIncomplete + 1
		end
		
	end

	self:ResetPlayerRegister()
	
end

function GM:RegisterPlayerFinished( ply )

	if ply && IsValid(ply) && ply:IsPlayer() then
		
		print("Registering " .. tostring(ply) .. " finished the maze")
		ply.mazesCompleted = ply.mazesCompleted + 1
		mm_sv_globals.playersInRound[ply.rIndex] = nil
		
		return table.insert(mm_sv_globals.finishedPlayers, ply)
	
	end

end

function GM:RegisterPlayerForRound( ply )
	
	if IsValid(ply) && ply:IsPlayer() then
		
		print("Registering " .. tostring(ply) .. " for this round")
		
		mm_sv_globals.prizePool = mm_sv_globals.prizePool + 1000
		ply.rIndex = table.insert(mm_sv_globals.playersInRound, ply)
		ply.mazesRan = ply.mazesRan + 1
	
	end

end

function GM:ResetPlayerRegister()
	
	mm_sv_globals.playersInRound = {}
	mm_sv_globals.finishedPlayers = {}
	mm_sv_globals.prizePool = 0
	
end

				
function GM:PlayerDisconnected( ply )
	
	
	if !ply.isResetting then
		self:SavePlayerInfo(ply)
		self:SavePlayerWeapons(ply)
	end
	
	mm_sv_globals.playersOnServer = mm_sv_globals.playersOnServer - 1
	
end

function GM:SaveAllPlayers()

	for k, ply in pairs(player.GetAll()) do
		self:SavePlayerInfo(ply)
		self:SavePlayerWeapons(ply)
	end

end

function GM:SavePlayerInfo(ply)
	
	ply:SetPData("mm_ply_model", ply:GetModel())
	
	ply:SetPData("mm_ply_credits", ply.credits)
	
	ply:SetPData("mm_ply_color", ply:GetPlayerColor())
	
	ply:SetPData("mm_ply_max_health", ply:GetMaxHealth())
	
	ply:SetPData("mm_ply_mazes_ran", ply.mazesRan)
	ply:SetPData("mm_ply_mazes_completed", ply.mazesCompleted)
	ply:SetPData("mm_ply_mazes_incomplete", ply.mazesIncomplete)
	

end

function GM:LoadPlayerInfo(ply)

	local modelString = ply:GetPData("mm_ply_model")
	
	local plyCredits = ply:GetPData("mm_ply_credits")
	
	local plyColor = ply:GetPData("mm_ply_color")
	
	local plyMaxHealth = ply:GetPData("mm_ply_max_health")
	
	local plyHasModel = (modelString != nil)
		
	if !plyHasModel then
		if (math.random() > 0.5) then
			
			modelString = females[math.ceil(math.random() * #females)]
			
		else
		
			modelString = males[math.ceil(math.random() * #males)]
		
		end
		
		ply:SetPData("mm_ply_model", modelString)
		
	end
	
	
	ply:SetModel( modelString )
	
	if plyCredits then
		
		ply.credits = tonumber(plyCredits)
			
	else
		
		ply.credits = 0
		self:ModifyPlayerCredit(ply, 1000)
		
	end
	
	if plyColor then
		
		ply:SetPlayerColor(Vector(plyColor))
		
	else
	
		ply:SetPlayerColor(Vector(math.random(), math.random(), math.random()))
	
	end
	
	if plyMaxHealth then
	
		ply:SetMaxHealth(plyMaxHealth)
		
	end
	
	ply.mazesRan = tonumber(ply:GetPData("mm_ply_mazes_ran", 0)) or 0
	ply.mazesCompleted = tonumber(ply:GetPData("mm_ply_mazes_completed", 0)) or 0
	ply.mazesIncomplete = tonumber(ply:GetPData("mm_ply_mazes_incomplete", 0)) or 0
	
	--PrintTable(ply:GetTable())
	
	
end

function GM:PlayerInitialSpawn( ply )

	mm_sv_globals.playersOnServer = mm_sv_globals.playersOnServer + 1
	
	ply:AllowFlashlight(false)
	
	self:LoadPlayerInfo(ply)
	
	net.Start("show_welcome")
	net.Send(ply)
	
end

					
function GM:PlayerSpawn( ply )

	ply:SetCustomCollisionCheck(true)
	
	ply:SetMaxHealth(ply:GetPData("mm_ply_max_health", 100))
		
	ply:SetHealth(ply:GetMaxHealth())
	
	ply.inMaze = ply.inMaze or false
	
	net.Start("in_maze")
		net.WriteBool(ply.inMaze)
	net.Send(ply)

	net.Start("get_exit_cam")
		net.WriteVector(exitCam:GetPos())
	net.Broadcast()
	
	self:LoadPlayerWeapons(ply)
	
	ply:Give("weapon_fists")
	
	if !ply.inMaze then
		timer.Simple(0.1, function()
								ply:SelectWeapon("weapon_fists")
						  end)
	else
		
		ply:SetEyeAngles(ply:EyeAngles() + Angle(0,math.floor(-180 + math.random() * 360), 0))
		
	end
	
	-- Hands Code from wiki
	local oldhands = ply:GetHands()
	
	if ( IsValid( oldhands ) ) then oldhands:Remove() end

	local hands = ents.Create( "gmod_hands" )
	if ( IsValid( hands ) ) then
		ply:SetHands( hands )
		hands:SetOwner( ply )

		local mdlNameParts = string.Explode("/", ply:GetModel(), false)
		
		local rawModelName = mdlNameParts[#mdlNameParts]
		
		local mdlName = rawModelName:sub(1, string.len(rawModelName) - 4)
				
		local cl_playermodel = mdlName 
		local info = player_manager.TranslatePlayerHands( cl_playermodel )
		if ( info ) then
			hands:SetModel( info.model )
			hands:SetSkin( info.skin )
			hands:SetBodyGroups( info.body )
		end

		local vm = ply:GetViewModel( 0 )
		hands:AttachToViewmodel( vm )

		vm:DeleteOnRemove( hands )
		ply:DeleteOnRemove( hands )

		hands:Spawn()
	end
	
end

function GM:PlayerSwitchWeapon(ply, oWeapon, nWeapon)
	
	if !IsValid(oWeapon) then
	
		oWeapon = {}
		function oWeapon:GetClass()
		
			return "none"
			
		end
		
	end
	
	if (!ply.inMaze && (nWeapon:GetClass() == "weapon_fists")) then 
	
		return false
		
	end
	
	return !ply.inMaze 

end

function GM:TestSpawn(ply)
	
	local spawnEnt = self:PlayerSelectSpawn(ply)
	
	ply:SetPos(spawnEnt:GetPos())

end

function GM:PlayerSelectSpawn(ply)
	
	local spawn = BaseClass.PlayerSelectSpawn(self, ply)
		
	if ply.mdlChange then
		
		ply:SetPos(ply.curPosMC)
		ply:SetAngles(ply.curAngMC) 
		ply.mdlChange = false
		
		return ply
		
	end
	
	if ply.inMaze then
	
		if mm_sv_globals.hasMaze then
		
			local pHull = {}
				  pHull.min, pHull.max = ply:GetHull()
			
			local traceRes = {}
			
			local spawnPos = Vector(0,0,0)
			local rndAngle = (math.random() * 360)
			
			local angleSweep = 0
			local angleStep = 15
			
			local spawnMapPos = Vector( math.floor(math.random() * ((curX) * 0.5)), 
									    math.floor(math.random() * ((curY) * 0.5)), 
									    math.floor(math.random() * 2)     )
			
			local rawWorldBlockPos = GetBlockWorldPos(spawnMapPos)
			local worldBlockPos = ( Vector(0,0,-315) * spawnMapPos.z ) + rawWorldBlockPos 
						
			local spawnRadius = 196
			
			local badTime = SysTime()
			
			traceRes.Hit = true
			
			local loopCount = 0
			
			local spawnBlocked = true
			
			while spawnBlocked do
				
				if SysTime() - badTime > 3 then
					break
				end
				
				if (angleSweep >= 360) then
				
					angleSweep = 0
					rndAngle = (math.random() * 360)
					spawnMapPos = Vector( math.floor(math.random() * ((curX - 1) * 0.5)), 
										  math.floor(math.random() * ((curY - 1) * 0.5)), 
										  math.floor(math.random() * 2)     )  
												
					
					rawWorldBlockPos = GetBlockWorldPos(spawnMapPos)
					
					worldBlockPos = ( Vector(0,0,-315) * spawnMapPos.z ) + rawWorldBlockPos 
					
					
				end
			
				spawnPos = Vector( math.sin(math.rad((rndAngle + angleSweep) % 360)) * spawnRadius, 
								   math.cos(math.rad((rndAngle + angleSweep) % 360)) * spawnRadius,
								   0 ) + worldBlockPos + ((blockSizes * 0.5) * Vector(1,1,0)) + Vector(0,0,6)
		
				
				local entsAtSpawn = ents.FindInBox(pHull.min + spawnPos, pHull.max + spawnPos)
				
				spawnBlocked = false
				
				for k,ent in pairs(entsAtSpawn) do
					
					if IsValid(ent) then
					
						if ent:IsPlayer() || (ent.IsTrap && ent:IsTrap()) then
							spawnBlocked = true
							break
						end
					
					end
				
				end
								
				angleSweep = angleSweep + angleStep
				loopCount = loopCount + 1
				
			end
			
			-- Debug box for spawn
			--[[
			net.Start("add_draw_box")
				net.WriteVector(spawnPos) -- Pos
				net.WriteVector(pHull.min) -- Min
				net.WriteVector(pHull.max) -- Max
				net.WriteFloat(30) -- TTL
			net.Send(ply)
			--]]
			local spawnEnt = ents.Create("info_player_start")
				  spawnEnt:SetPos( spawnPos  )
				  spawnEnt:Spawn()
			
			spawn = spawnEnt
			
		end
		
	end
	
	return spawn
	
end

function GM:SavePlayerWeapons( ply )
	
	local plyWeapons = ply:GetWeapons()
	
	for k,item in pairs(items) do
	
		if item.class == "internal" then continue end
		
		local ammoType = items.weaponsAmmo[item.class]
		
		local plyWeapon = ply:GetWeapon(item.class)
		
		local hasItem = IsValid(plyWeapon) 
		
		local ammoCount =  0 
		local clip1Count = 0
		local clip2Count = 0 
		
		if hasItem then
		
			ammoCount =  ply:GetAmmoCount(ammoType)
			clip1Count = plyWeapon:Clip1()
			clip2Count = plyWeapon:Clip2()
		
		end
		
		ply:SetPData("mm_items_" .. item.class, hasItem)
		ply:SetPData("mm_items_" .. item.class .. "_ammo_count", ammoCount)
		ply:SetPData("mm_items_" .. item.class .. "_clip_one", clip1Count)
		ply:SetPData("mm_items_" .. item.class .. "_clip_two", clip2Count)
		
	end

end

function GM:ResetPlayerData( ply )
	
	ply:StripWeapons()
	ply:StripAmmo()
	ply:Give("weapon_hands")
	ply:RemovePData("mm_ply_color")
	ply:RemovePData("mm_ply_model")
	ply:RemovePData("mm_ply_credits")
	ply:RemovePData("mm_ply_max_health")
	
	for k, item in pairs(items) do
		ply:RemovePData("mm_items_" .. item.class)
		ply:RemovePData("mm_items_" .. item.class .. "_ammo_count")
		ply:RemovePData("mm_items_" .. item.class .. "_clip_one")
		ply:RemovePData("mm_items_" .. item.class .. "_clip_two")
	end
	
	ply.isResetting = true
	ply:Kick("Resetting Data.... please re-join")
	
end

function GM:LoadPlayerWeapons( ply )
	
	ply:StripWeapons()
	ply:StripAmmo()
	
	for k, item in pairs(items) do
		
		if item.class == "internal" then continue end
		
		local ammoType = items.weaponsAmmo[item.class]
		local hasItem = tobool(ply:GetPData("mm_items_" .. item.class, false))
		local ammoCount = tonumber(ply:GetPData("mm_items_" .. item.class .. "_ammo_count", 0))
		local clip1Count = tonumber(ply:GetPData("mm_items_" .. item.class .. "_clip_one", 0))
		local clip2Count = tonumber(ply:GetPData("mm_items_" .. item.class .. "_clip_two", 0))
		
		if hasItem then
			
			if item.class:sub(1,6) == "weapon" then
			
				local newItem = ply:Give(item.class)
					
				ply:SetAmmo( 0, items.weaponsAmmo[item.class] )
				newItem:SetClip1(0)
				newItem:SetClip2(0)
				
				if ammoCount > 0 then
					ply:SetAmmo(ammoCount, items.weaponsAmmo[item.class] )
				end
				
				if clip1Count > 0 then
					newItem:SetClip1(clip1Count)
				end
				
				if clip2Count > 0 then
					newItem:SetClip1(clip2Count)
				end
			end
		end		
	end

end



function GM:InitPostEntity() 
		
	local physTable = {}
		  physTable.LookAheadTimeObjectsVsObject = 0.25 -- default: 0.5
		  --physTable.LookAheadTimeObjectsVsWorld =  1 -- default: 1
		  physTable.MaxCollisionChecksPerTimestep = 10000 -- default: 50000
		  physTable.MaxCollisionsPerObjectPerTimestep = 2 -- default: 10
		  
	physenv.SetPerformanceSettings( physTable )
	
	mazeZero = ents.FindByName( "grid_origin" )[1]
	
	exitCam = ents.FindByName( "exit_cam" )[1]
	
	mm_sv_globals.miniMapPos = ents.FindByName( "spec_map" )[1]:GetPos()
	
	mm_sv_globals.miniEnt = ents.Create("mini_map")
	
	mm_sv_globals.miniEnt:SetPos(mm_sv_globals.miniMapPos)
	
	mm_sv_globals.miniEnt:Spawn()
	
	for k,ent in pairs(ents.GetAll()) do
			
		if ent:GetName():sub(1, 6) == "enter_" then
			if ent:GetName():sub(7) == "sound" then
				self.soundOn = false
				self.soundEnt = ent
				
				function self:toggleSound(setVal) 
				
					if !(setVal == nil) then
						if setVal == self.soundOn then return end
						self.soundOn = setVal
					else
						self.soundOn = !self.soundOn
					end
					
					if self.soundOn then
						self.soundEnt:Fire("Volume", 10)
						self.soundEnt:Fire("PlaySound", 1)
					else
						self.soundEnt:Fire("Volume", 00)
						self.soundEnt:Fire("ToggleSound", 0)
						
					end
					self.soundEnt:Activate()
				end
			end
			
			if ent:GetName():sub(7) == "tesla" then
				self.teslaOn = false
				self.teslaEnt = ent
				function self:toggleTesla(setVal) 
				
					if !(setVal == nil) then
						if setVal == self.teslaOn then return end
						self.teslaOn = setVal
					else
						self.teslaOn = !self.teslaOn
					end
					
					if self.teslaOn then
						self.teslaEnt:Fire("TurnOn")
					else
						self.teslaEnt:Fire("TurnOff")
					end
					self.teslaEnt:Activate()
				end
			end
			
			if ent:GetName():sub(7) == "core" then
				self.coreOn = false
				self.coreEnt = ent
				function self:toggleCore(setVal) 
					
					if !(setVal == nil) then
						if setVal == self.coreOn then return end
						self.coreOn = setVal
					else
						self.coreOn = !self.coreOn
					end
					
					if self.coreOn then
						self.coreEnt:Fire("StartCharge", 2)
						timer.Simple(1, function()
							self.coreEnt:Fire("StartDischarge", 30)
							end)
						
					else
						self.coreEnt:Fire("Stop")
					end
					self.coreEnt:Activate()
				end
			end
			
			if ent:GetName():sub(7) == "glow" then
				self.glowOn = false
				self.glowEnt = ent
				function self:toggleGlow(setVal) 
					
					if !(setVal == nil) then
						if setVal == self.glowOn then return end
						self.glowOn = setVal
					else
						self.glowOn = !self.glowOn
					end
					
					if self.glowOn then
						self.glowEnt:Fire("Color", "125 10 255")
						
						
					else
						self.glowEnt:Fire("Color", "0 0 0")
					end
					self.glowEnt:Activate()
				end
			end
			
			if ent:GetName():sub(7) == "trigger" then
				self.triggerOn = false
				self.triggerEnt = ent
				function self:toggleTrigger(setVal) 
					
					if !(setVal == nil) then
						if setVal == self.triggerOn then return end
						self.triggerOn = setVal
					else
						self.triggerOn = !self.triggerOn
					end
					
					if self.triggerOn then
						self.triggerEnt:Fire("Enable")
						
						
					else
						self.triggerEnt:Fire("Disable")
					end
					self.triggerEnt:Activate()
				end
			end
			
			if ent:GetName():sub(7) == "push" then
				self.pushOn = false
				self.pushEnt = ent
				function self:togglePush(setVal) 
					
					if !(setVal == nil) then
						if setVal == self.pushOn then return end
						self.pushOn = setVal
					else
						self.pushOn = !self.pushOn
					end
					
					if self.pushOn then
						self.pushEnt:Fire("Enable")
						
						
					else
						self.pushEnt:Fire("Disable")
					end
					self.pushEnt:Activate()
				end
				
				function self:setPushDirection(setVal) 
					
						self.pushEnt:SetKeyValue("pushdir", tostring(setVal.x) .. " " .. tostring(setVal.y) .. " " .. tostring(setVal.z))
						self.pushEnt:Activate()
						
				end
				
				function self:setPushForce(setVal) 
					
						self.pushEnt:SetKeyValue("speed", setVal)
						self.pushEnt:Activate()
						
				end
				
			end
			
		end
		
	end
	
	net.Start("get_exit_cam")
		net.WriteVector(exitCam:GetPos())
	net.Broadcast()
	
	net.Start("maze_zero")
		net.WriteVector(mazeZero:GetPos())
	net.Broadcast()
	
	mm_sv_globals.roundEntity = ents.Create("round_controller")
	mm_sv_globals.roundEntity:Spawn()
	
end

function GM:OpenEntrance()
	
	self:toggleSound(true)
	self:toggleGlow(true)
	self:toggleTesla(true)
	self:toggleCore(true)
	self:toggleTrigger(true)
	self:setPushDirection(Vector(0,1,0))
	
end

function GM:CloseEntrance()

	self:toggleSound(false)
	self:toggleGlow(false)
	self:toggleTesla(false)
	self:toggleCore(false)
	self:toggleTrigger(false)
	self:setPushDirection(Vector(0,-1,0))
	--self:togglePush(false)

end



function GM:SpawnMazeBlock(x, y, isUD)
	
	local newBlock = ents.Create("maze_block")
	
	if isUD then
		newBlock:SetType("u")
	else 
		newBlock:SetType("b")
	end
		
	newBlock:SetPos(mazeZero:GetPos() + (Vector(x * blockSizes.x, y * blockSizes.y, 0)))
	
	newBlock:Spawn()
	
	mm_sv_globals.blocks[x][y] = newBlock
	
	return newBlock
	

end

function GM:EnterMaze( ply )

	if !IsValid(ply) || !ply:IsPlayer() || ply.inMaze then return end 
	
	if mm_sv_globals.hasMaze then
		
		if !ply.inMaze then
			
			ply.inMaze = true
			
			net.Start("in_maze")
				net.WriteBool(ply.inMaze)
			net.Send(ply)
			
			self:RegisterPlayerForRound( ply )
			
			
			--- Pick Random Spawn, not occupied
			local spawnEnt = self:PlayerSelectSpawn(ply)
			local spawnPos = spawnEnt:GetPos()
			gSetPos(ply, spawnPos)
			ply:SetVelocity(ply:GetVelocity() * -1)			
			timer.Simple(0.5, function() spawnEnt:Remove() end)
						
		end
	
	end

end

-- F1
function GM:ShowHelp( ply )
	net.Start("show_welcome")
	net.Send(ply)
end

-- F2 
function GM:ShowTeam( ply )

	if ply.inMaze then return end
	
	net.Start("open_store")
	net.Send(ply)
	
	net.Start("credit_info")
		net.WriteInt(ply.credits,32)
	net.Broadcast()
	
end

-- F3
function GM:ShowSpare1(  ply )

	if ply.inMaze then return end
	
	net.Start("open_player")
	net.Send(ply)
end

-- F4
function GM:ShowSpare2(  ply )
	
	
	
end

function GM:StartChat(TeamSay)
	
	allowMenu = false
	
end


function GM:FinishChat(TeamSay)
	
	allowMenu = true
	
end


function GM:FormatPlace( place )
	
	local placeString = tostring(place)
	local suffix = "th"
	
	if placeString:sub(-1) == "1" then suffix = "st" end
	if placeString:sub(-1) == "2" then suffix = "nd" end
	if placeString:sub(-1) == "3" then suffix = "rd" end
	
	return placeString .. suffix
	
end

function GM:ModifyPlayerCredit(ply, amount)
	
	if ply && IsValid(ply) && ply:IsPlayer() then
		
		if !ply.credits then ply.credits = 0 end
		
		ply.credits = ply.credits + amount
		
	else
		return
	end
	
	net.Start("credit_info")
		net.WriteInt(ply.credits, 32)
	net.Send(ply)
	
	
end


function GM:TeleportToExit( ply )
	
	if !ply || !IsValid(ply) || !ply:IsPlayer() then 
		return 
	end 
	
	self:SavePlayerInfo(ply)
	self:SavePlayerWeapons(ply)
	ply:SelectWeapon("weapon_fists")
	
	local traceData = {}
	
	local pHull = {}
	pHull.min, pHull.max = ply:GetHull()
	
	local plyHeight = pHull.max - pHull.min
	
	local spawnPos = exitCam:GetPos() + Vector(0,0, plyHeight.z * -0.5)
	
	traceRes = {}
	local entsAtExit = ents.FindInBox(pHull.min + spawnPos, pHull.max + spawnPos)
	local exitBlocked = false
	
	for k,ent in pairs(entsAtExit) do
		
		if IsValid(ent) then
		
			if ent:IsPlayer() then
				exitBlocked = true
			end
		
		end
	
	end
	
	if exitBlocked then
		
		timer.Simple(0.5, function()
			self:TeleportToExit(ply) 
		end)
		
	else
	
		ply.inMaze = false
		
		net.Start("in_maze")
			net.WriteBool(ply.inMaze)
		net.Send(ply)
		
		ply:SetEyeAngles(Angle(0,180,0))
		
		gSetPos(ply, spawnPos)
		ply:ScreenFade( SCREENFADE.IN, Color( 125, 10, 255, 128 ), 0.5, 0 )
		
	end
	
	
end


function GM:DestroyMaze()
	
	if !mm_sv_globals.hasMaze then return end
	
	self.curMaze = {}
	mm_sv_globals.hasMaze = false
	blocks = {}
	
	local plList = player.GetAll()
	
	for k,v in pairs(plList) do
		
		if v.inMaze then
			
			self:TeleportToExit(v)
		
		end
	
	end
	
	for k, v in pairs(ents.FindByClass("maze_door")) do
	
		v:Remove()
		
	end
	
	for k, v in pairs(ents.FindByClass("maze_block")) do
	
		v:Remove()
		
	end
	
	for ti, trapName in pairs(mm_sv_globals.traps) do
		for k, v in pairs(ents.FindByClass(trapName)) do
		
			v:Remove()
			
		end
	end

end

function countOpenDirections(mazeCell)
	
	local dirs = {"u", "d", "n", "s", "e", "w"}
	local openDirs = 0
	
	for k, dir in pairs(dirs) do
		
		if mazeCell[dir] then
			openDirs = openDirs + 1
		end
		
	end
	
	return openDirs

end

liveStepTime = 0.05

function GM:GenerateMazeLive(mazeData, runNum)

	if runNum == nil then 
		runNum = 0 
		mm_sv_globals.generatingMaze = true
	end
	
	runNum = runNum + 1
	
	--print( "-= @#@#@#@#@#@#@#@#@#@#@#@# Generating Maze Live #@#@#@#@#@#@#@#@#@#@#@#@#@#@ =-")
	--print("runNum: " .. tostring(runNum))
	local dirs = {"u", "d", "n", "s", "e", "w"}
	
	local wordVommit = false 
	
	if mazeData == nil then
		local plyCountBoost = 2 * (mm_sv_globals.playersOnServer / game.MaxPlayers())
		local addX = math.floor( (math.random() * (maxX - minX)) )
		local addY = math.floor( (math.random() * (maxY - minY)) )
		
		curX = math.Truncate(minX + plyCountBoost, 0) + addX
		curY = math.Truncate(minY + plyCountBoost, 0) + addY
		
		mazeData = {}
		
		for z = 0, 1 do
			mazeData[z] = {}
			for x = 0, curX - 1 do
				mazeData[z][x] = {}
				for y = 0, curY - 1 do
				
					mazeData[z][x][y] = newMazeCell()
					
				end
			end
		end
		
		mazeData.nextCell = Vector( math.floor(math.random() * curX), 
								    math.floor(math.random() * curY), 
								    math.floor(math.random() * 2) )
		mazeData.mazeComplete = false
		mazeData.toRevisit = {}
		
	end

	if wordVommit then print( ".-= ################################################ =-.") end
	local curCell = mazeData.nextCell
	mazeData[curCell.z][curCell.x][curCell.y].numVisits = mazeData[curCell.z][curCell.x][curCell.y].numVisits + 1
	if wordVommit then print("cumazeData.rCell: " .. tostring(curCell)) end
			
	local possibleDirs = {}
	
	for k, dir in pairs(dirs) do
		
		local dirCell = getNextCell(curCell, dir)
		local isInMaze = IsInMaze(dirCell)
		
		if wordVommit then print("direction: " .. dir .. ", isInMaze: " .. tostring(isInMaze)) end
		
		if isInMaze then
			local openDoorCount = countOpenDirections(mazeData[dirCell.z][dirCell.x][dirCell.y])
			if wordVommit then print("has " .. tostring(openDoorCount) .. " open doors.") end
			if openDoorCount < 2 && !(mazeData[dirCell.z][dirCell.x][dirCell.y].numVisits > 2) then
				if wordVommit then print("adding to possible directions to go.") end
				table.insert(possibleDirs, {["dir"] = dir, ["dirCell"] = dirCell})
			end
		end
		
	end
	
	if wordVommit then  print("possibleDirs: ") end
	if wordVommit then PrintTable(possibleDirs) end
	
	if #possibleDirs > 0 then
		
		if wordVommit then print("we have possible directions") end
		
		local rndNum = math.ceil(math.random() * #possibleDirs)
		local rndDir = possibleDirs[rndNum]
		
		if wordVommit then print("we go " .. tostring(rndDir.dir) .. " to cell " .. tostring(rndDir.dirCell)) end
		
		mazeData.nextCell = rndDir.dirCell

		mazeData[curCell.z][curCell.x][curCell.y][rndDir.dir] = true
		mazeData[mazeData.nextCell.z][mazeData.nextCell.x][mazeData.nextCell.y][dirPairs[rndDir.dir]] = true
		
		if wordVommit then print(" and remove it from possible directions.") end
		table.remove(possibleDirs, rndNum)		
		
		if wordVommit then print("add remaining directions to revisit list") end
		for k, remDir in pairs(possibleDirs) do
			
			--local indexStr = tostring(remDir.dirCell.z) .. "." .. tostring(remDir.dirCell.x) .. "." .. tostring(remDir.dirCell.y)
			if wordVommit then print("adding " .. tostring(remDir.dir) .. " : " .. tostring(remDir.dirCell)) end
			table.insert(mazeData.toRevisit, remDir.dirCell)
			
		end
		
		table.insert(mazeData.toRevisit, curCell)
		
	else
	
		if wordVommit then print("found no possible directions") end
		
		if #mazeData.toRevisit > 0 then
			
			if wordVommit then print("there are cells to revisit") end
			
			local rndRevCellNum = math.ceil(math.random() * #mazeData.toRevisit)
			mazeData.nextCell = mazeData.toRevisit[rndRevCellNum]
			
			if wordVommit then print("we are going to cell: " .. tostring(mazeData.nextCell) .. " removing from revisit list.") end 
			
			table.remove(mazeData.toRevisit, rndRevCellNum)
							
		else
			
			if wordVommit then print("nothing to revisit, maze is complete") end
			mazeData.mazeComplete = true
			
		end
		
	end
	
	if wordVommit then 
		print("Top Level")
		print("----------------------------------")
		print(" ")
		print(self:drawMapToString("t", nil, mazeData))
		print(" ")
		print("----------------------------------")
		print(" ")
		print("Bottom Level")
		print("----------------------------------")
		print(self:drawMapToString("b", nil, mazeData))
		print(" ")
		print("----------------------------------")
	end
	
	if wordVommit then print( "^-= ################################################ =-^") end

	if mazeData.mazeComplete then
		
		mm_sv_globals.generatingMaze = false
		self:CreateMaze(mazeData)
		
	else
	
		timer.Simple(liveStepTime, function() self:GenerateMazeLive(mazeData, runNum) end)
		
	end

end

function GM:CreateMaze(mazeData)

	for x = 0, 29 do
		mm_sv_globals.blocks[x] = {}
		for y = 0, 29 do
			mm_sv_globals.blocks[x][y] = nil
		end
	end
	
	dirs = {"n", "s", "e", "w"}
	
	local placedExit = false
	local exitPos = Vector(0,0,0)
	local exitDir = ""
	
	for z = 0, 1 do
		local levelLetter = "t"
		
		if z == 1 then
			levelLetter = "b"
		end
		
		for x = 0, curX - 1 do
			for y = 0, curY - 1 do
				
				local curSpot = mazeData[z][x][y]
				
				local curBlock = mm_sv_globals.blocks[x][y]
				
				if curBlock == nil then
					
					if curSpot.u || curSpot.d then
						curBlock = self:SpawnMazeBlock(x,y, true)
					else
						curBlock = self:SpawnMazeBlock(x,y, false)
					end
					
				end
				
				local curDirs = {}
				
				for k,v in pairs(dirs) do
					curBlock:SetDoor(levelLetter, v, !curSpot[v])
					if (!curSpot[v]) then
						table.insert(curDirs, v)
					end
				end
				
				if math.random() > 0.75 then
					
					local blockAttach = curBlock:GetAttachments()
					
					local useableTraps = {}
					
					for k, attach in pairs(blockAttach) do
						
						if attach.name:sub(1,4) == "trap" then
							
							if attach.name:sub(6,6) == levelLetter then
								
								if !curBlock[attach.name] then
									
									table.insert(useableTraps, attach)
																	
								end
								
							end
							
						end
						
					end
					
					local numTraps = math.ceil(math.random() * 2)
					for i = 1, numTraps do
						if #useableTraps <= 0 then break end
						local rndTrapSpotNum = math.ceil(math.random() * #useableTraps)
						local rndTrapSpot = curBlock:GetAttachment(useableTraps[rndTrapSpotNum].id)
						table.remove(useableTraps, rndTrapSpotNum)
						
						local newTrapPos = rndTrapSpot.Pos
						
						local newTrap = ents.Create(mm_sv_globals.traps[math.ceil(math.random() * #mm_sv_globals.traps)])
						
						newTrap:Spawn()
						
						newTrap:Deploy(newTrapPos)
						
						newTrap:SetBlock(curBlock)
						
					end
					
					
					
				end
				
				if !placedExit then
					if ( x == ( curX - 1 ) ) ||
					   ( y == ( curY - 1 ) ) then
						
						if ((curX - 1) == x) && ((curY - 1) == y) && (levelLetter == "b") then
							
							local rndDoorDir = curDirs[math.ceil(math.random() * #curDirs)]
							local rndDoor = curBlock.doors[levelLetter][rndDoorDir]
							
							exitDir = rndDoorDir
							exitPos = Vector(x,y,z)
							mm_cl_globals.exitEnt = rndDoor
							placedExit = true
							rndDoor:SetIsExit(true)
							
							curBlock:SetHasExit(true)
							curBlock:SetExitDoor(rndDoor)
							curBlock:SetColor(Color(255,255,255,255))
							
						else
							
							if  ( x >= ( curX * 0.25 ) ) &&
								( y >= ( curY * 0.25 ) ) then
								
								if (math.ceil(math.random() * 100) >= 50) then
									local rndDoorDir = curDirs[math.ceil(math.random() * #curDirs)]
									local rndDoor = curBlock.doors[levelLetter][rndDoorDir]
									
									exitDir = rndDoorDir
									exitPos = Vector(x,y,z)
									exitEnt = rndDoor
									placedExit = true
									rndDoor:SetIsExit(true)
									curBlock:SetHasExit(true)
									curBlock:SetExitDoor(rndDoor)
									curBlock:SetColor(Color(255,255,255,255))
								end
							end
							
							
						end
					   
					end
				end
				
			end
		end
	end
	
	self.curMaze = mazeData
	
	self.roundEnt:SetRoundTimeByName("in", ((curX * curY * 2) * 4) + (mm_sv_globals.playersOnServer * 2))
	
	mm_sv_globals.hasMaze = true
	
	self:OpenEntrance()
	
	--[[
	print("Top Level")
	print("----------------------------------")
	print(" ")
	print(self:drawMapToString("t"))
	print(" ")
	print("----------------------------------")
	print(" ")
	print("Bottom Level")
	print("----------------------------------")
	print(self:drawMapToString("b"))
	print(" ")
	print("----------------------------------")
	--]]
	
	net.Start("update_maze_size")
		net.WriteInt(curX, 32)
		net.WriteInt(curY, 32)
	net.Broadcast()
	
end

function GM:Think()

	for k, ply in pairs(player.GetAll()) do
	
		if ply.inMaze && self.roundEnt:GetCurrentTitle() == "pre" then
			ply:Freeze(true)
		else
			ply:Freeze(False)
		end
	
	end
	
end

function GM:SetupPlayerVisibility( ply )
	
	AddOriginToPVS(exitCam:GetPos())
	
	AddOriginToPVS(mazeZero:GetPos())
	
	for k, p in pairs(player.GetAll()) do
		
		AddOriginToPVS(p:GetPos())
	
	end
	
end

function getNextCell(pos, dir)
	
	local dirs = {}
	
		  dirs["u"] = Vector(  0,  0, -1 )
		  dirs["d"] = Vector(  0,  0,  1 )
		  
		  dirs["s"] = Vector(  0,  1,  0 )
		  dirs["n"] = Vector(  0, -1,  0 )
		  
		  
		  dirs["e"] = Vector(  1,  0,  0 )
		  dirs["w"] = Vector( -1,  0,  0 )
		  
	return pos + dirs[dir]
		  

end

function GM:PlayerSilentDeath( ply )

	ply:Spawn()

end

function GM:DoPlayerDeath( ply, attacker, dmgInfo)
	
	self:SavePlayerWeapons(ply)

	timer.Simple(0.2, function() if IsValid(ply) then ply:Spawn() end end )

end

function GM:ShouldCollide(ent1, ent2)

	if IsValid(ent1) && IsValid(ent2) then
		
		if (ent1:IsPlayer() && ent2:IsPlayer()) && (!ent1.inMaze && !ent2.inMaze) then
			return false
		end
		
		if (ent1:GetClass() == "maze_block" || ent1:GetClass() == "maze_door") &&
		   (ent2:GetClass() == "maze_block" || ent2:GetClass() == "maze_door") then
		   
			return false
		end

	end
	
	return true
	
end

-- SetPos doesn't always work, this funciton tries it a few times to get it to work
function gSetPos(ent, pos, tries)

	if !IsValid(ent) then return end
	
	if tries == nil then
		tries = 0
	end
	
	if IsValid(ent) then
	
		local curDist = (ent:GetPos() - pos):Length()
	
		if ent:GetPos() == pos ||
		   curDist < 150 then
		
			return 
			
		end
		
		ent:SetPos(pos)
		
	end
	
	if tries < 3 then
		timer.Simple(0.2, function() gSetPos(ent,pos, tries) end)
	end
	
	tries = tries + 1
	
end

function GM:PlayerShouldTakeDamage(ply, attacker)

	if IsValid(ply) && IsValid(attacker) then
	
		if ply:IsPlayer() && attacker:IsPlayer() then
		
			if !ply.inMaze && !attacker.inMaze then
			
				return false
				
			end
		end
	end
	
	return true


end

function kickAllBots()

	
	for k, bot in pairs(player.GetBots()) do
		
		bot:Kick()
		
	end

end

function healThePlayers()

	
	for k,ply in pairs(player.GetAll()) do
		
		if IsValid(ply) then
			ply:SetHealth(math.min(ply:Health() + (ply:GetMaxHealth() * 0.06), ply:GetMaxHealth()))
		end
	
	end
	
	timer.Simple(1.1, healThePlayers)
	
end

