AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "items.lua" )

DEFINE_BASECLASS( "gamemode_base")
--resource.AddFile( "" )
--resource.AddFile( "" )

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
resource.AddFile( "materials/mm/spike_trap_killicon.vmt")

resource.AddFile( "models/mm/laser_trap.mdl" )
resource.AddFile( "models/mm/maze_block.mdl" )
resource.AddFile( "models/mm/maze_block_ud.mdl" )
resource.AddFile( "models/mm/maze_door.mdl" )
resource.AddFile( "models/mm/back_spike_pad.mdl" )
resource.AddFile( "models/mm/front_spike_pad.mdl" )
resource.AddFile( "models/mm/shock_trap.mdl" )
resource.AddFile( "models/mm/spike_trap.mdl" )




include( "shared.lua" )

traps = { "laser_trap", "shock_trap" } --, "spike_trap" }
	
blocks = {}

roundEntity = ""

prizePool = 0

playersOnServer = 0

playersInRound = {}

finishedPlayers = {}

miniMapPos = Vector(0,0,0)

hasMaze = false

for x = 0, 29 do
	blocks[x] = {}
	for y = 0, 29 do
		blocks[x][y] = nil
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
	--util.AddNetworkString("map_info")
	util.AddNetworkString("maze_zero")
	util.AddNetworkString("world_size")
	util.AddNetworkString("req_world_size")
	util.AddNetworkString("req_maze_zero")
	util.AddNetworkString("req_maze_size")
	util.AddNetworkString("open_help") -- F1
	
	util.AddNetworkString("open_store") -- F2
	util.AddNetworkString("req_purchase")
	
	util.AddNetworkString("open_player") --F3
	
	-- util.AddNetworkString("") --F3
	
	util.AddNetworkString("show_scores") --TAB
	
	-- Scores = kills - finishes - mazes - fastest time
	
	util.AddNetworkString("hud_message")
	
	util.AddNetworkString("play_sound")
	
	util.AddNetworkString("set_player_color")
	
	util.AddNetworkString("show_welcome")
	
	util.AddNetworkString("destroy_maze")
	
	util.AddNetworkString("req_maze_dimensions")
	
	util.AddNetworkString("add_draw_box")
	
	util.AddNetworkString("set_player_model")
	
	util.AddNetworkString("req_room_from_server")
	util.AddNetworkString("rec_room_from_server")
	
	util.AddNetworkString("create_ragdoll")
	
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

	--print("SendHudMessage( " .. tostring(ply) .. ", " .. tostring(msg) .. ", " .. tostring(ttl) .. " )")
	
	if type(ply) == "string" then
		
		--print("only two arguments, broadcasting")
		net.Start("hud_message")
			net.WriteString(ply or "-._.-= Blank Message =-._.-")
			net.WriteFloat(msg)
		net.Broadcast()
	else
		
		--print("all three arguments")
		if IsValid(ply) && ply:IsPlayer() then
		
			net.Start("hud_message")
				net.WriteString(msg or "-._.-= Blank Message =-._.-")
				net.WriteFloat(ttl)
			net.Send(ply)
		end
		
	end
	
end



net.Receive("set_player_model", function (len, ply) 
	
	local newModel = net.ReadString()
	
	--print(tostring(ply) .. " setting model to " .. newModel)
	
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
	
	--print("Client " .. tostring(ply) .. " is setting their color to " .. tostring(newColor))
	
	ply:SetPlayerColor(newColor)
	
	ply:SetPData("mm_ply_color", newColor)
	
end)

net.Receive("req_purchase", function (len, ply) 
	
	local itemNum = net.ReadInt(32)
	local thisItem = items[itemNum]
	
	if !thisItem then return end
	
	--print("Client " .. tostring(ply) .. " wants item #: " .. tostring(itemNum))
	
	--print(tostring(ply) .. " has " .. tostring(ply.credits))
	
	--print("item: " .. thisItem.title .. " Costs: " .. thisItem.cost)
	
	----print(type(ply.credits))
	----print(type(thisItem.cost))
	local canBuy, errorMessage = thisItem:canBuy( ply )
	
	--print("canBuy: " .. tostring(canBuy))
	--print("errorMessage: " .. tostring(errorMessage))
	
	if canBuy then --ply.credits >= thisItem.cost then
	
		GAMEMODE:ModifyPlayerCredit(ply, -thisItem.cost)
		thisItem.buyFunc(thisItem.class, thisItem.quantity, ply)
		GAMEMODE:PlayGUISound(ply, "buttons/blip1.wav")
		
	else
	
		GAMEMODE:SendHudMessage(ply, errorMessage, 0.25)
		GAMEMODE:PlayGUISound(ply, "buttons/combine_button_locked.wav")
		
	end
	
end)

net.Receive("req_maze_zero", function (len, ply) 
	
	--print("Client " .. tostring(ply) .. " requesting maze zero")
	
	
	net.Start("maze_zero")
		net.WriteVector(mazeZero:GetPos())
	net.Send(ply)
	
	
end)

net.Receive("req_world_size", function (len, ply) 
	
	--print("Client " .. tostring(ply) .. " requesting map size")
	
	local theWorld = game.GetWorld()
	local theWorldTable = theWorld:GetSaveTable()
	
	local worldMin = Vector(theWorldTable["m_WorldMins"])
	--print("worldMin: " .. tostring(worldMin))
	local worldMax = Vector(theWorldTable["m_WorldMaxs"])
	--print("worldMax: " .. tostring(worldMax))
	local worldSize = (worldMax - worldMin)
	--print("worldSize: " .. tostring(worldSize))
	
	net.Start("world_size")
		net.WriteVector(worldSize)
	net.Send(ply)
	
	
end)

net.Receive("request_credit_info", function (len, ply) 
	
	--print("Client " .. tostring(ply) .. " requesting credit info")
	net.Start("credit_info")
		net.WriteInt(ply.credits,32)
	net.Broadcast()
	--print("credits: " .. tostring(ply.credits))

end)

net.Receive("request_exit_cam", function (len, ply) 
	
	--print("Client " .. tostring(ply) .. " requesting cam pos")
	net.Start("get_exit_cam")
		net.WriteVector(exitCam:GetPos())
	net.Broadcast()
	--print("exitCamPos: " .. tostring(exitCam:GetPos()))

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
--
-- Special Case Players < 4
-- num test: 6 players = 6000 pool
-- 1st = 6000 / 2 = 3000
-- 2nd = 3000 / 2 = 1500
-- 3rd = 1500 / 2 =  750
-- 4th = 750  / 3 =  250
-- 5th = 250  / 2 =  125
-- 6th = 125  / 1 =  125
-- DNF = 10% of 4th on prize = 25
--
-- num test: 4 players = 4000 pool
-- 1st = 4000 / 2 = 2000
-- 2nd = 2000 / 2 = 1000
-- 3rd =  500 / 2 =  250
-- 4th =  250 / 1 =  250
-- DNF = 10% of 4th on prize = 25
--
-- num test: 16 players = 16000 pool
-- 1st = 16000 / 2 = 8000
-- 2nd =  8000 / 2 = 4000
-- 3rd =  4000 / 2 = 2000
-- 4th =  2000 / 13 = 154
-- 5th =  1846 / 12 = 154
-- 6th =  1692 / 11 = 154
-- 7th =  1538 / 10 = 154
-- 8th =  1384 /  9 = 154
-- 9th =  1230 /  8 = 154
-- 10th = 1076 /  7 = 154
-- 11th =  922 /  6 = 154
-- 12th =  768 /  5 = 154
-- 13th =  614 /  4 = 154
-- 14th =  460 /  3 = 154
-- 15th =  306 /  2 = 153
-- 16th =  153 /  1 = 153
-- DNF = 10% of 4th on prize = 16
--
-- num test: 2 players = 2000 pool
-- 1st = 2000  / 2 = 1000
-- 2nd = 1000  / 2 =  500
-- 3nd =  500  / 2 =  250
-- DNF = 10% of 3nd prize = 25
--
-- num test: 2 players = 2000 pool
-- 1st = 2000  / 1.5 = 1334
-- 2nd = 1334  / 1.5 =  890
-- 3nd =  890  / 1.5 =  594
-- 4th =  594  / 1.5 =  396  
-- DNF = 10% of 4nd prize = 40
--
-- Special Cases < 4
--
-- ( ( 4 - pc ) / 3 ) = x
-- ( ( 4 - 1  ) / 3 ) = 1  
-- ( ( 4 - 2  ) / 3 ) = 0.67
-- ( ( 4 - 3  ) / 3 ) = 0.34
--
-- num test: 1 players = 1000 pool
-- 1st = 1000  * 1 = 1000
-- 2nd = 1000  * 1 = 1000
-- 3nd = 1000  * 1 = 1000
-- 4th = 1000  * 1 = 1000  
-- DNF = 10% of 4nd prize = 100
--
-- num test: 2 players = 2000 pool
-- 1st = 2000  * 0.67 = 1340
-- 2nd = 1340  * 0.67 =  898
-- 3nd =  898  * 0.67 =  602
-- 4th =  602  * 0.67 =  403  
-- DNF = 10% of 4nd prize = 41
--
-- num test: 3 players = 3000 pool
-- 1st = 3000 * 0.34 = 1020
-- 2nd = 1020 * 0.34 =  347
-- 3nd = 347  * 0.34 =  118
-- 4th = 118  * 0.34 =  41  
-- DNF = 10% of 4nd prize = 5

function GM:AwardPrizes()
	
	--print("--------- Awarding Prizes --------")
	--print("prizePool: " .. tostring(prizePool))
	local curPrize = 0
	local dnfPrize = prizePool * 0.05
	--print("baseDNFPrize: " .. tostring(dnfPrize))
	local totalPlayers = (#finishedPlayers + #playersInRound)
	--print("finishedPlayers: " .. tostring(#finishedPlayers))
	--print("playersNotFinished: " .. tostring(#playersInRound))
	
	--print("totalPlayers(in round): " .. tostring(totalPlayers))
	

	for i = 1, #finishedPlayers do
		
		local ply = finishedPlayers[i]
		
		if IsValid(ply) then
			--print(tostring(ply) .. " finished in position " .. tostring(i))
			
			if i <= 3 then
				curPrize = prizePool / 2
			else
				curPrize = prizePool / (#finishedPlayers - 3)
				dnfPrize = curPrize * 0.1
			end
			
			--print("curPrize: " .. tostring(curPrize))
			
			prizePool = prizePool - curPrize
			
			--print("remaining prizePool: " .. tostring(prizePool))
			
			ply:ChatPrint("You placed " .. self:FormatPlace( i ) .. " !! You get " .. tostring(curPrize) .. " credits.")
			self:ModifyPlayerCredit(ply, curPrize)
		end
		
	end
		
	for k, ply in pairs(playersInRound) do
		
		if IsValid(ply) then
			--print(tostring(ply) .. " didn't finish, but still gets " .. tostring(dnfPrize) .. " credits.")
			ply:ChatPrint("You didn't finish, but you still get " .. tostring(dnfPrize) .. " credits for trying.")
			self:ModifyPlayerCredit(ply, dnfPrize)
		end
		
	end

	--print("remaining prizePool: " .. tostring(prizePool))
	--print("----- End Prize Awarding -----")
	--print("----- Resetting Prize System -")
	self:ResetPlayerRegister()
	
	
end

function GM:RegisterPlayerFinished( ply )

	if ply && IsValid(ply) && ply:IsPlayer() then
		
		print("Registering " .. tostring(ply) .. " finished the maze")
		playersInRound[ply.rIndex] = nil
		
		return table.insert(finishedPlayers, ply)
	
	end

end

function GM:RegisterPlayerForRound( ply )
	
	if ply && IsValid(ply) && ply:IsPlayer() then
		
		print("Registering " .. tostring(ply) .. " for this round")
		
		prizePool = prizePool + 1000
		ply.rIndex = table.insert(playersInRound, ply)
	
	end

end

function GM:ResetPlayerRegister()

	--print("Resetting player register...")
	
	playersInRound = {}
	finishedPlayers = {}
	prizePool = 0
	
end

				
function GM:PlayerDisconnected( ply )
	
	
	if !ply.isResetting then
		----print(tostring(ply) .. " disconnected, saving info.")
		self:SavePlayerInfo(ply)
		self:SavePlayerWeapons(ply)
	else
		----print(tostring(ply) .. " was kicked for a reset")
	end
	
	playersOnServer = playersOnServer - 1
	
end

function GM:SaveAllPlayers()

	for k, ply in pairs(player.GetAll()) do
		self:SavePlayerInfo(ply)
		self:SavePlayerWeapons(ply)
	end

end

function GM:SavePlayerInfo(ply)
	
	local modelString = ply:SetPData("mm_ply_model", ply:GetModel())
	
	local plyCredits = ply:SetPData("mm_ply_credits", ply.credits)
	
	local plyColor = ply:SetPData("mm_ply_color", ply:GetPlayerColor())
	
	local plyMaxHealth = ply:SetPData("mm_ply_max_health", ply:GetMaxHealth())

end

function GM:LoadPlayerInfo(ply)

	local modelString = ply:GetPData("mm_ply_model")
	
	local plyCredits = ply:GetPData("mm_ply_credits")
	
	local plyColor = ply:GetPData("mm_ply_color")
	
	local plyMaxHealth = ply:GetPData("mm_ply_max_health")
	
	local plyHasModel = (modelString != nil)
		
	if !plyHasModel then
		--print("picking a random body")
		if (math.random() > 0.5) then
			
			modelString = females[math.ceil(math.random() * #females)]
			
		else
		
			modelString = males[math.ceil(math.random() * #males)]
		
		end
		
		ply:SetPData("mm_ply_model", modelString)
		
	end
	
	----print(tostring(ply) .. " is " .. modelString)
	
	ply:SetModel( modelString )
	
	if plyCredits then
		
		ply.credits = tonumber(plyCredits)
			
	else
		
		ply.credits = 0
		self:ModifyPlayerCredit(ply, 1000)
		
	end
	
	if plyColor then
		
		----print(plyColor)
		----print(Vector(plyColor))
		
		ply:SetPlayerColor(Vector(plyColor))
		
	else
	
		ply:SetPlayerColor(Vector(math.random(), math.random(), math.random()))
	
	end
	
	if plyMaxHealth then
	
		ply:SetMaxHealth(plyMaxHealth)
		
	end
	
	
end

function GM:PlayerInitialSpawn( ply )

	--print("PlayerInitialSpawn( " .. tostring(ply) .. " ) : " .. tostring(CurTime()))
	
	playersOnServer = playersOnServer + 1
	
	ply:AllowFlashlight(false)
	
	self:LoadPlayerInfo(ply)
	
	net.Start("show_welcome")
	net.Send(ply)
	
end

					
function GM:PlayerSpawn( ply )

	--print("PlayerSpawn ( " .. tostring(ply) .. " ) : " .. tostring(CurTime()))
	--print("Player is in the maze: " .. tostring(ply.inMaze))
	--ply:Flashlight(true)
	--ply:SetPos(ply:GetPos() + Vector(-32,-32, 16))
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
	
	-- Hands Code
	local oldhands = ply:GetHands()
	
	if ( IsValid( oldhands ) ) then oldhands:Remove() end

	local hands = ents.Create( "gmod_hands" )
	if ( IsValid( hands ) ) then
		ply:SetHands( hands )
		hands:SetOwner( ply )

		-- Which hands should we use?
		local mdlNameParts = string.Explode("/", ply:GetModel(), false)
		
		--PrintTable(mdlNameParts)
		
		local rawModelName = mdlNameParts[#mdlNameParts]
		
		--print("rawModelName: " .. rawModelName)
		
		local mdlName = rawModelName:sub(1, string.len(rawModelName) - 4)
		
		--print("modelName: " .. mdlName)
		
		local cl_playermodel = mdlName --ply:GetModel() --GetInfo( "cl_playermodel" )
		local info = player_manager.TranslatePlayerHands( cl_playermodel )
		if ( info ) then
			hands:SetModel( info.model )
			hands:SetSkin( info.skin )
			hands:SetBodyGroups( info.body )
		end

		-- Attach them to the viewmodel
		local vm = ply:GetViewModel( 0 )
		hands:AttachToViewmodel( vm )

		vm:DeleteOnRemove( hands )
		ply:DeleteOnRemove( hands )

		hands:Spawn()
	end
	
	----print("exitCamPos: " .. tostring(exitCam:GetPos()))
	
	
end

function GM:PlayerSwitchWeapon(ply, oWeapon, nWeapon)
	
	----print("oldWeapon: " .. tostring(oWeapon))
	----print("newWeapon: " .. tostring(nWeapon))
	
	if !IsValid(oWeapon) then
	
		oWeapon = {}
		function oWeapon:GetClass()
		
			return "none"
			
		end
		
	end
	
	----print(tostring(ply) .. " is switching weapon from " .. oWeapon:GetClass() .. " to " .. nWeapon:GetClass())
	----print(tostring(ply) .. " in the maze?: " .. tostring( ply.inMaze))
	----print("toFists in Spawn: " .. tostring(!(!ply.inMaze && (nWeapon:GetClass() == "weapon_fists"))))
	
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
	
	--util.TimerCycle()
	--print("--------------------- PlayerSelectSpawn ---------------------")
	local spawn = BaseClass.PlayerSelectSpawn(self, ply)
	
	----print(tostring(ply) .. " selecting spawn... : " .. tostring(CurTime()))
	--print("default spawn: " .. tostring(spawn))
	
	if ply.mdlChange then
		
		ply:SetPos(ply.curPosMC) -- = ply:GetPos()
		ply:SetAngles(ply.curAngMC) -- = ply:GetAngles()
		ply.mdlChange = false
		
		return ply
		
	end
	
	if ply.inMaze then
	
		--print("player needs to spawn in the maze")
		if hasMaze then
		
			----print("maze still open, respawning in maze...")
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
			
			--print("spawnMapPos: " .. tostring(spawnMapPos))
			--print("rawWorldBlockPos: " .. tostring(rawWorldBlockPos))
			--print("worldBlockPos: " .. tostring(worldBlockPos))
			
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
				
				--PrintTable(entsAtSpawn)
				for k,ent in pairs(entsAtSpawn) do
					
					if IsValid(ent) then
					
						if ent:IsPlayer() || (ent.IsTrap && ent:IsTrap()) then
							spawnBlocked = true
							break
						end
					
					end
				
				end
				
				--print("spawnPos: " .. tostring(spawnPos))
				--local spawnClear = true
				
				--local traceData = {}
				--traceData.start = spawnPos + pHull.bottom
				--traceData.endpos = spawnPos  + pHull.top
				--traceData.filter = {ply}
				--traceRes = util.TraceLine(traceData)
				
				--traceData.start = spawnPos + pHull.bottom
				--traceData.endpos = spawnPos  + pHull.top
				--traceData.filter = {ply}
				--traceRes = util.TraceLine(traceData)
				
				--traceRes = util.TraceEntity(traceData, ply)
				
				angleSweep = angleSweep + angleStep
				loopCount = loopCount + 1
				----print(".. ")
			end
			
			net.Start("add_draw_box")
				net.WriteVector(spawnPos) -- Pos
				net.WriteVector(pHull.min) -- Min
				net.WriteVector(pHull.max) -- Max
				net.WriteFloat(30) -- TTL
			net.Send(ply)
			
			local spawnEnt = ents.Create("info_player_start")
				  spawnEnt:SetPos( spawnPos  )
				  spawnEnt:Spawn()
			
			spawn = spawnEnt
			
			----print("loopCount: " .. loopCount)
			----print("spawnEnt: " .. tostring(spawnEnt))
			
		end
		
	end
	
	----print("chosen spawn: " .. tostring(spawn))
	
	----print("spawnPos: " .. tostring(spawn:GetPos()))
	
	----print("spawnMapPos: " .. tostring(GetPlayerMapPos(spawn)))
	
	----print("PlayerSelectSpawn took : " .. tostring(util.TimerCycle() / 1000) .. " seconds to execute.")
	return spawn
	
end

function GM:SavePlayerWeapons( ply )
	
	--print("Save Player Weapons")
	----print(ply)
	
	local plyWeapons = ply:GetWeapons()
	
	
	--print("=-...............................................-=")
	----print(tostring(ply) .. " has: ")
	
	--PrintTable(plyWeapons)
	
	--print(" ")
	
	for k,item in pairs(items) do
	
		if item.class == "internal" then continue end
		
		local ammoType = items.weaponsAmmo[item.class]
		
		local plyWeapon = ply:GetWeapon(item.class)
		
		local hasItem = IsValid(plyWeapon) --!(plyWeapon == nil) && IsValid()
		
		local ammoCount =  0 -- ply:GetAmmoCount(ammoType)
		local clip1Count = 0 --weapon:Clip1()
		local clip2Count = 0 --weapon:Clip2()
		
		if hasItem then
		
			ammoCount =  ply:GetAmmoCount(ammoType)
			clip1Count = plyWeapon:Clip1()
			clip2Count = plyWeapon:Clip2()
		
		end
		
		if !hasItem then
		
		else
			----print(item.class .. " uses " .. ammoType .. ", " .. tostring(ply) .. " has ammoCount: " .. tostring(ammoCount))
			--print(" and clip1: " .. tostring(clip1Count) .. " and clip2: " .. tostring(clip2Count))
		end
		
		ply:SetPData("mm_items_" .. item.class, hasItem)
		ply:SetPData("mm_items_" .. item.class .. "_ammo_count", ammoCount)
		ply:SetPData("mm_items_" .. item.class .. "_clip_one", clip1Count)
		ply:SetPData("mm_items_" .. item.class .. "_clip_two", clip2Count)
		--print("\n.-===============================================-.")		
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
	
	--print("Load Player Weapons")
	--print(ply)
	ply:StripWeapons()
	ply:StripAmmo()
	
	for k, item in pairs(items) do
		
		if item.class == "internal" then continue end
		--print("=-...............................................-=")
		
		----PrintTable(item)
		
		--print(" ")
		local ammoType = items.weaponsAmmo[item.class]
		--print("ammoType: " .. tostring(ammoType))
		local hasItem = tobool(ply:GetPData("mm_items_" .. item.class, false))
		--print("hasItem: " .. tostring(hasItem))
		local ammoCount = tonumber(ply:GetPData("mm_items_" .. item.class .. "_ammo_count", 0))
		--print("ammoCount: " .. tostring(ammoCount))
		local clip1Count = tonumber(ply:GetPData("mm_items_" .. item.class .. "_clip_one", 0))
		--print("clip1Count: " .. tostring(clip1Count))
		local clip2Count = tonumber(ply:GetPData("mm_items_" .. item.class .. "_clip_two", 0))
		--print("clip2Count: " .. tostring(clip2Count))
		--print("prefix:  " .. item.class:sub(1,6))
		
		if hasItem then
			
			if item.class:sub(1,6) == "weapon" then
				--print(tostring(ply) .. " has a " .. item.class)
				--print("with: " )
				--print("clip1: " .. tostring(clip1Count))
				--print("clip2: " .. tostring(clip2Count))
				--print("ammoCount: " .. tostring(ammoCount))
				
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
		else
			
			--print(tostring(ply) .. " doesn't have a " .. item.class)
			
		end
		
		--print("\n.-===============================================-.")			
	end

end

miniEnt = ""

function GM:InitPostEntity() 
	
	--print ("InitPostEntity() : " .. tostring(CurTime()))
	
	local physTable = {}
		  physTable.LookAheadTimeObjectsVsObject = 0.25 -- default: 0.5
		  --physTable.LookAheadTimeObjectsVsWorld =  1 -- default: 1
		  physTable.MaxCollisionChecksPerTimestep = 10000 -- default: 50000
		  physTable.MaxCollisionsPerObjectPerTimestep = 2 -- default: 10
		  
		  
	physenv.SetPerformanceSettings( physTable )
	

	
	mazeZero = ents.FindByName( "grid_origin" )[1]
	
	exitCam = ents.FindByName( "exit_cam" )[1]
	
	miniMapPos = ents.FindByName( "spec_map" )[1]:GetPos()
	
	miniEnt = ents.Create("mini_map")
	
	miniEnt:SetPos(miniMapPos)
	
	miniEnt:Spawn()
	
	for k,ent in pairs(ents.GetAll()) do
			
		----print(ent:GetName())
		----print(ent:GetName():sub(1, 6))
		----print(ent:GetName():sub(7))
		if ent:GetName():sub(1, 6) == "enter_" then
		
			--print("found enter object: " .. tostring(ent) .. " - " .. ent:GetName())
			
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
		
		--ent:SetSaveValue("m_fActive", true)
		--ent:Fire("Use")
		--ent:Activate()
	
	end
	
	net.Start("get_exit_cam")
		net.WriteVector(exitCam:GetPos())
	net.Broadcast()
	
	net.Start("maze_zero")
		net.WriteVector(mazeZero:GetPos())
	net.Broadcast()
	
	--print("exitCamPos: " .. tostring(exitCam:GetPos()))

	roundEntity = ents.Create("round_controller")
	roundEntity:Spawn()
	
end

function GM:OpenEntrance()
	
	self:toggleSound(true)
	self:toggleGlow(true)
	self:toggleTesla(true)
	self:toggleCore(true)
	self:toggleTrigger(true)
	self:setPushDirection(Vector(0,1,0))
	--self:togglePush(true)
	
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
		----print("creating up/down block...")
	else 
		newBlock:SetType("b")
		----print("creating basic block...")
	end
		
	newBlock:SetPos(mazeZero:GetPos() + (Vector(x * blockSizes.x, y * blockSizes.y, 0)))
	
	newBlock:Spawn()
	
	blocks[x][y] = newBlock
	
	return newBlock
	

end


--[[
function GM:UnLockPlayers()
	
	for k, ply in pairs(player.GetAll()) do
		
		if ply && IsValid(ply) && ply:IsPlayer() then 
			
			ply:UnLock()
			
		end
	
	end

end
--]]

function GM:EnterMaze( ply )
	
	--print("EnterMaze: " .. tostring(ply))
	
	-- Enter Maze
	if !IsValid(ply) || !ply:IsPlayer() || ply.inMaze then return end 
	
	--print("player valid")
	
	if hasMaze then
		
		--print("hasMaze")
		
		if !ply.inMaze then
			
			--print("player not in maze yet")
			
			ply.inMaze = true
			
			net.Start("in_maze")
				net.WriteBool(ply.inMaze)
			net.Send(ply)
			
			self:RegisterPlayerForRound( ply )
			
			--- Pick Random Spawn, not occupied
			local spawnEnt = self:PlayerSelectSpawn(ply)
			local spawnPos = spawnEnt:GetPos()
			--print("spawnEnt: " .. tostring(spawnEnt))
			
			--print("spawnEntPos: " .. tostring(spawnPos))
			
			--print("spawnMapPos: " .. tostring(GetPlayerMapPos(spawnEnt)))
			
			--timer.Simple(0.01, function() ply:SetPos(spawnPos) end ) --blocks[0][0]:GetPos() + Vector(0,0,17))
			
			--ply:SetPos(spawnPos)
			
			gSetPos(ply, spawnPos)
			ply:SetVelocity(ply:GetVelocity() * -1)
			--timer.Simple(0.1, function() ply:SetPos(spawnPos) end)			
			timer.Simple(0.5, function() spawnEnt:Remove() end)
			
			--timer.Simple(0.3, function() if ply && IsValid(ply) && ply:IsPlayer() then ply:Lock() end end)
			
			
		end
	
	end

end

-- F1
function GM:ShowHelp( ply )
	
	----print(tostring(ply) .. " is requesting the help menu.")
end

-- F2 
function GM:ShowTeam( ply )

	--print(tostring(ply) .. " is requesting the store menu.")
	
	if ply.inMaze then return end
	
	net.Start("open_store")
	net.Send(ply)
	
	net.Start("credit_info")
		net.WriteInt(ply.credits,32)
	net.Broadcast()
	
end

-- F3
function GM:ShowSpare1(  ply )
	--print(tostring(ply) .. " is requesting the player menu")
	
	if ply.inMaze then return end
	
	net.Start("open_player")
	net.Send(ply)
end

-- F4
function GM:ShowSpare2(  ply )
	
	net.Start("show_welcome")
	net.Send(ply)
	
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
	
	-- 1st 2nd 3rd 4th 5th 6th 7th 8th 9th 10th 11th ...
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
		--print("Can not modify credits on " .. tostring(ply))
		return
	end
	
	--print("Modified Player Credit: " .. tostring(ply.credits))
	
	net.Start("credit_info")
	
		net.WriteInt(ply.credits, 32)
	
	net.Send(ply)
	
	--ply:SetPData("mm_ply_credits", ply.credits)
	
end


function GM:TeleportToExit( ply )
	
	--print("TeleportToExit")
	--print("ply: " .. tostring(ply))
	
	if !ply || !IsValid(ply) || !ply:IsPlayer() then 
		--print("ply not valid or something")
		return 
	end 
	--ply:Lock()
	
	--ply:Freeze(true)
	self:SavePlayerInfo(ply)
	self:SavePlayerWeapons(ply)
	ply:SelectWeapon("weapon_fists")
	
	local traceData = {}
	
	local pHull = {}
	pHull.min, pHull.max = ply:GetHull()
	
	local plyHeight = pHull.max - pHull.min
	
	local spawnPos = exitCam:GetPos() + Vector(0,0, plyHeight.z * -0.5)
	--print("spawnPos: " .. tostring(spawnPos))
	--traceData.start = spawnPos
	--traceData.endpos = spawnPos 
	
	--traceData.mins = pHull.min
	--traceData.maxs = pHull.max
	
	--local traceRes = util.TraceHull(traceData)
	traceRes = {}
	local entsAtExit = ents.FindInBox(pHull.min + spawnPos, pHull.max + spawnPos)
	local exitBlocked = false
	----PrintTable()
	for k,ent in pairs(entsAtExit) do
		
		if IsValid(ent) then
		
			if ent:IsPlayer() then
				exitBlocked = true
			end
		
		end
	
	end
	
	if exitBlocked then
		
		----PrintTable(entsAtExit)
		----print("Exit blocked, waiting...")
		
		timer.Simple(0.5, function()
			self:TeleportToExit(ply) 
		end)
		
	else
	
		--print("Exit available, teleporting...")
		ply.inMaze = false
		
		net.Start("in_maze")
			net.WriteBool(ply.inMaze)
		net.Send(ply)
		
		ply:SetEyeAngles(Angle(0,180,0))
		--print("spawnPos: " .. tostring(spawnPos))
		--ply:SetPos(spawnPos)
		
		gSetPos(ply, spawnPos)
		ply:ScreenFade( SCREENFADE.IN, Color( 125, 10, 255, 128 ), 0.5, 0 )
		
		
		
	end
	
	
end


function GM:DestroyMaze()
	
	if !hasMaze then return end
	

	self.curMaze = {}
	hasMaze = false
	blocks = {}
	
	local plList = player.GetAll()
	
	for k,v in pairs(plList) do
		
		if v.inMaze then
			
			--v.inMaze = false
			
			self:TeleportToExit(v)
		
		end
	
	end
	
	for k, v in pairs(ents.FindByClass("maze_door")) do
	
		v:Remove()
		
	end
	
	for k, v in pairs(ents.FindByClass("maze_block")) do
	
		v:Remove()
		
	end
	
	for ti, trapName in pairs(traps) do
		for k, v in pairs(ents.FindByClass(trapName)) do
		
			v:Remove()
			
		end
	end
	
	net.Start("destroy_maze")
	net.Broadcast()
	
	for k, ply in pairs(player.GetAll()) do
		
		net.Start("destroy_maze")
		net.Send(ply)
	
	end
	
	
	--self:AwardPrizes()
	
	--self.mapEnt:sendMazeInfo(true)
	
	

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

	if runNum == nil then runNum = 0 end
	
	runNum = runNum + 1
	
	print( "-= @#@#@#@#@#@#@#@#@#@#@#@# Generating Maze Live #@#@#@#@#@#@#@#@#@#@#@#@#@#@ =-")
	print("runNum: " .. tostring(runNum))
	local dirs = {"u", "d", "n", "s", "e", "w"}
	
	local wordVommit = false 
	
	if mazeData == nil then
		local plyCountBoost = 2 * (playersOnServer / game.MaxPlayers())
		
		--print("plyCountBoost: " .. tostring(plyCountBoost))
		
		--print("minX: " .. tostring(minX))
		--print("minY: " .. tostring(minY))
		
		local addX = math.floor( (math.random() * (maxX - minX)) )
		local addY = math.floor( (math.random() * (maxY - minY)) )
		
		--print("addX: " .. tostring(addX))
		--print("addY: " .. tostring(addY))
		
		curX = math.Truncate(minX + plyCountBoost, 0) + addX
		curY = math.Truncate(minY + plyCountBoost, 0) + addY
		
		--print("curX: " .. curX)
		--print("curY: " .. curY)
		
		--curX = math.floor(math.max(minX, minX + (playersOnServer * 0.25))) + math.ceil( (math.random() * (math.max(maxX, maxX + (playersOnServer * 0.25)) - minX)) )
		--curY = math.floor(math.max(minY, minY + (playersOnServer * 0.25))) + math.ceil( (math.random() * (math.max(maxY, maxY + (playersOnServer * 0.25)) - minY)) )
		
		--print("New Maze Deminsions: ")
		--print("\tx: " .. tostring(curX))
		--print("\ty: " .. tostring(curY))
		
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
	
	
	
	--while !mazeComplete do
		
		if wordVommit then print( ".-= ################################################ =-.") end
		local curCell = mazeData.nextCell
		mazeData[curCell.z][curCell.x][curCell.y].numVisits = mazeData[curCell.z][curCell.x][curCell.y].numVisits + 1
		if wordVommit then print("cumazeData.rCell: " .. tostring(curCell)) end
				
		local possibleDirs = {}
		
		for k, dir in pairs(dirs) do
			
			local dirCell = getNextCell(curCell, dir)
			local isInMaze = IsInMap(dirCell)
			
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

	--end
	
	if mazeData.mazeComplete then
		
		self:CreateMaze(mazeData)
		
	else
	
		timer.Simple(liveStepTime, function() self:GenerateMazeLive(mazeData, runNum) end)
		
	end

end

function GM:GenerateMaze()
	
	print( ".-= @#@#@#@#@#@#@#@#@#@#@#@#@#@#@# Generating Maze #@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@ =-.")
	
	local plyCountBoost = 2 * (playersOnServer / game.MaxPlayers())
	
	--print("plyCountBoost: " .. tostring(plyCountBoost))
	
	--print("minX: " .. tostring(minX))
	--print("minY: " .. tostring(minY))
	
	local addX = math.floor( (math.random() * (maxX - minX)) )
	local addY = math.floor( (math.random() * (maxY - minY)) )
	
	--print("addX: " .. tostring(addX))
	--print("addY: " .. tostring(addY))
	
	curX = math.Truncate(minX + plyCountBoost, 0) + addX
	curY = math.Truncate(minY + plyCountBoost, 0) + addY
	
	--print("curX: " .. curX)
	--print("curY: " .. curY)
	
	--curX = math.floor(math.max(minX, minX + (playersOnServer * 0.25))) + math.ceil( (math.random() * (math.max(maxX, maxX + (playersOnServer * 0.25)) - minX)) )
	--curY = math.floor(math.max(minY, minY + (playersOnServer * 0.25))) + math.ceil( (math.random() * (math.max(maxY, maxY + (playersOnServer * 0.25)) - minY)) )
	
	--print("New Maze Deminsions: ")
	--print("\tx: " .. tostring(curX))
	--print("\ty: " .. tostring(curY))
	
	local mazeData = {}
	
	for z = 0, 1 do
		mazeData[z] = {}
		for x = 0, curX - 1 do
			mazeData[z][x] = {}
			for y = 0, curY - 1 do
			
				mazeData[z][x][y] = newMazeCell()
				
			end
		end
	end
	
	
	local flip = true
	local nextCell = Vector( math.floor(math.random() * curX), 
							 math.floor(math.random() * curY), 
							 math.floor(math.random() * 2) )
							 
	local mazeComplete = false
	
	local toRevisit = {}
	local toRevisitIndex = {}
	
	local dirs = {"u", "d", "n", "s", "e", "w"}
	local isBroke = SysTime() + 10
	local wordVommit = false 
	
	while !mazeComplete || (SysTime() < isBroke) do
		
		if wordVommit then print( ".-= ################################################ =-.") end
		local curCell = nextCell
		mazeData[curCell.z][curCell.x][curCell.y].numVisits = mazeData[curCell.z][curCell.x][curCell.y].numVisits + 1
		if wordVommit then print("curCell: " .. tostring(curCell)) end
				
		local possibleDirs = {}
		
		for k, dir in pairs(dirs) do
			
			local dirCell = getNextCell(curCell, dir)
			local isInMaze = IsInMap(dirCell)
			
			if wordVommit then print("direction: " .. dir .. ", isInMaze: " .. tostring(isInMaze)) end
			
			if isInMaze then
				local openDoorCount = countOpenDirections(mazeData[dirCell.z][dirCell.x][dirCell.y])
				if wordVommit then print("has " .. tostring(openDoorCount) .. " open doors.") end
				if openDoorCount <= 1 && !(mazeData[dirCell.z][dirCell.x][dirCell.y].numVisits > 2) then
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
			
			nextCell = rndDir.dirCell

			mazeData[curCell.z][curCell.x][curCell.y][rndDir.dir] = true
			mazeData[nextCell.z][nextCell.x][nextCell.y][dirPairs[rndDir.dir]] = true
			
			if wordVommit then print(" and remove it from possible directions.") end
			table.remove(possibleDirs, rndNum)		
			
			if wordVommit then print("add remaining directions to revisit list") end
			for k, remDir in pairs(possibleDirs) do
				
				--local indexStr = tostring(remDir.dirCell.z) .. "." .. tostring(remDir.dirCell.x) .. "." .. tostring(remDir.dirCell.y)
				if wordVommit then print("adding " .. tostring(remDir.dir) .. " : " .. tostring(remDir.dirCell)) end
				table.insert(toRevisit, remDir.dirCell)
				
			end
			
			table.insert(toRevisit, curCell)
			
		else
		
			if wordVommit then print("found no possible directions") end
			
			if #toRevisit > 0 then
				
				if wordVommit then print("there are cells to revisit") end
				
				local rndRevCellNum = math.ceil(math.random() * #toRevisit)
				nextCell = toRevisit[rndRevCellNum]
				
				if wordVommit then print("we are going to cell: " .. tostring(nextCell) .. " removing from revisit list.") end 
				
				table.remove(toRevisit, rndRevCellNum)
								
			else
				
				if wordVommit then print("nothing to revisit, maze is complete") end
				mazeComplete = true
				
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

	end
	
	--print("toRevisit: " ) 
	--PrintTable(toRevisit)
	
	-- Check Maze Here
	--[[
	if !self:CanSolveMaze(mazeData) then
		--timer.Simple(0.1, function()
		--print("\n -- Can't Solve Maze -- \n -- Trying Again --\n")
		self.roundEnt:createRound( "stuck", 0, "Creating Maze...", 1, false, function() self:GenerateMaze() end, true )
		self.roundEnt:createRound( "stuck", 2, "Creating Maze...", 1, false, nil, true )
		--self.roundEnt:ChangeRound()
		
			--self:GenerateMaze()
		--end)
		return
	end
	--]]
	self:CreateMaze(mazeData)
	
end
	-- Physically make maze below
function GM:CreateMaze(mazeData)

	for x = 0, 29 do
		blocks[x] = {}
		for y = 0, 29 do
			blocks[x][y] = nil
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
				
				----print("\ncurSpot: z: " .. tostring(z) .. " x: " .. tostring(x) .. " y: " .. tostring(y))
				local curSpot = mazeData[z][x][y]
				----PrintTable(curSpot)
				
				local curBlock = blocks[x][y]
				
				----print("curBlock: " .. tostring(curBlock))
				
				if curBlock == nil then
					
					----print("no block, creating ...")
					
					if curSpot.u || curSpot.d then
						curBlock = self:SpawnMazeBlock(x,y, true)
						--curBlock:CloseAllDoors()
					else
						curBlock = self:SpawnMazeBlock(x,y, false)
						--curBlock:CloseAllDoors()
					end
					
				end
				
				local curDirs = {}
				
				for k,v in pairs(dirs) do
					curBlock:SetDoor(levelLetter, v, !curSpot[v])
					if (!curSpot[v]) then
						table.insert(curDirs, v)
					end
				end
				
				--if curSpot.checked then
					
				--	curBlock:SetColor(Color(128,255,128,255))
					
				--end
				
				if math.random() > 0.75 then
					
					--print("we should place a trap")
					
					local blockAttach = curBlock:GetAttachments()
					--PrintTable(blockAttach)
					local useableTraps = {}
					
					for k, attach in pairs(blockAttach) do
						
						if attach.name:sub(1,4) == "trap" then
							
							if attach.name:sub(6,6) == levelLetter then
								--print("found trap spot : " .. attach.name)
								
								if !curBlock[attach.name] then
									
									--print("can place the trap")
									
									table.insert(useableTraps, attach)
									
									--curBlock[attach.name] = true					
								
								end
								
							end
							
						end
						
					end
					
					local numTraps = math.ceil(math.random() * 3)
					for i = 1, numTraps do
						if #useableTraps <= 0 then break end
						local rndTrapSpotNum = math.ceil(math.random() * #useableTraps)
						local rndTrapSpot = curBlock:GetAttachment(useableTraps[rndTrapSpotNum].id)
						table.remove(useableTraps, rndTrapSpotNum)
						
						local newTrapPos = rndTrapSpot.Pos
						
						local newTrap = ents.Create(traps[math.ceil(math.random() * #traps)]) --"laser_trap")
						
						newTrap:Spawn()
						
						newTrap:Deploy(newTrapPos) -- SetPos(newTrapPos)
					end
					
					
					
				end
				
							
				----print("curBlock: " .. tostring(curBlock))
				----print("curDoors: ")
				----PrintTable(curBlock.doors[levelLetter])
				
				if !placedExit then
					if ( x == ( curX - 1 ) ) ||
					   ( y == ( curY - 1 ) ) then
						
						if ((curX - 1) == x) && ((curY - 1) == y) && (levelLetter == "b") then
							
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
	
	self.roundEnt:SetRoundTimeByName("in", ((curX * curY * 2) * 4) + (playersOnServer * 2))
	
	hasMaze = true
	
	self:OpenEntrance()
	
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

function GM:CanSolveMaze(mazeData)
	
	--print("Attempting to solve maze....")
	
	local totalCount = ((curX * curY) * 2)
	--print("totalRooms: " .. tostring(totalCount))
	local solveStart = CurTime()
	local foundRooms = 0
	
	local finishedRooms = {}
	local rooms = {}
	local recheck = {}
	local availableMoves = {}
	
	local dirs = {"u", "d", "n", "s", "e", "w"}
	
	--print("Gathering rooms and directions...")
	for z = 0, 1 do		
		for x = 0, curX - 1 do
			for y = 0, curY - 1 do
	 
				local thisRoom = Vector(x,y,z)
				local roomStr = tostring(thisRoom)
				
				rooms[roomStr] = copyMazeCell( mazeData[z][x][y] )
				rooms[roomStr].pos = thisRoom
				
				for k,dir in pairs(dirs) do
					
					if !rooms[roomStr][dir] then
						rooms[roomStr][dir] = nil
					end
					
				end
				foundRooms = foundRooms + 1
				
			end
		end
	end
	
	----PrintTable(rooms)
	
	--print("Found rooms: " .. tostring(foundRooms))
	
	
	
	
	local curPos = Vector(0,0,0)
	local checking = true
	local roomFinished = false
	local nextRoom = Vector(0,0,0)
	local curRoom = ""
	local curIndexStr = ""
	local possibleMoves = {}
	local finishedCount = 0
	
	----print("solveDelta: " .. tostring((CurTime() - solveStart)))
	
	while (checking && ((CurTime() - solveStart) < 10)) do
		
		----print("curPos: " .. tostring(curPos))
		curIndexStr = tostring(curPos)
		----print("curIndexStr: " .. curIndexStr)
		----print(rooms[curIndexStr])
		possibleMoves = {}
		
		roomFinished = false 
		
		if rooms[curIndexStr] then
			
			mazeData[curPos.z][curPos.x][curPos.y].checked = true
			
			for k,dir in pairs(dirs) do
				
				----print("Checking dir: " .. dir)
				----print("room : " .. tostring(rooms[curIndexStr]))
				----PrintTable(rooms[curIndexStr])
				if rooms[curIndexStr][dir] then
					
					----print("found possible move: " .. dir)
									
					table.insert(possibleMoves, dir)

				end
			
			end
		end
		
		----print("possibleMoves: " .. tostring(#possibleMoves))
		----PrintTable(possibleMoves)
		
		
		if #possibleMoves > 0 then
			
			----print("picking direction to move... " )
			
			local rndDirIndex = math.ceil(math.random() * #possibleMoves)
			local rndDir = possibleMoves[rndDirIndex]
			
			possibleMoves[rndDirIndex] = nil
			
			----print("dir: " .. rndDir)
			
			rooms[curIndexStr][rndDir] = nil
			----print("roomAfter: ")
			----PrintTable(rooms[curIndexStr])
			
			nextRoom = getNextCell(curPos, rndDir)
			----print("nextRoom: " .. tostring(nextRoom))
						
		else
			
			roomFinished = true
			
		end
		
		if #possibleMoves <= 0 then
		
			--roomFinished = true
		else
			
			
			recheck[curIndexStr] = rooms[curIndexStr]
									
		end
		
		if roomFinished then
		
			----print("Room finished -- All directions checked")
			
			--finishedRooms[curIndexStr] = rooms[curIndexStr]
			
			rooms[curIndexStr] = nil
			recheck[curIndexStr] = nil
			finishedCount = finishedCount + 1
			foundRooms = foundRooms - 1
			
			--if #recheck > 0 then
			--	nextRoom = recheck[1].pos
			--	table.remove(recheck, 1)
			--	continue
			--end
			
			for k, room in pairs(recheck) do
				
				nextRoom = room.pos
				continue
			
			end
			
		end
		
		--rooms[curIndexStr] = nil
		
		curPos = nextRoom
		
		if foundRooms == 0 then
			checking = false
		end
		----print(" ")
	end
	--print("visitedRooms: " .. tostring(finishedCount))
	
	return true --finishedCount == totalCount


end





function GM:SetupPlayerVisibility( ply )
	
	AddOriginToPVS(exitCam:GetPos())
	
	AddOriginToPVS(mazeZero:GetPos())
	
	for k, p in pairs(player.GetAll()) do
		
		AddOriginToPVS(p:GetPos())
	
	end
	
end

function canOpenDoor(pos, dir, mazeData) 

	--print("canOpenDoor( " .. tostring(pos) .. ", " .. tostring(dir) .. " )")
	--local dirs = {"u", "d", "n", "s", "e", "w"}
	local nCell = getNextCell(pos,dir)
	local inMap = IsInMap(nCell)
	
	if inMap then
		--print("is in map")
		local odc = countOpenDirections(mazeData[nCell.z][nCell.x][nCell.y])
		--print("open directions: " .. tostring(odc))
		if odc < 1 then
			--print("cell not opened") 
			return true
		end
	end
	
	return false
	
end


function getNextCell(pos, dir)
	
	--print("getNextCell( " .. tostring(pos) .. ", " .. tostring(dir) .. " )")
	
	local dirs = {}
	
		  dirs["u"] = Vector(  0,  0, -1 )
		  dirs["d"] = Vector(  0,  0,  1 )
		  
		  dirs["s"] = Vector(  0,  1,  0 )
		  dirs["n"] = Vector(  0, -1,  0 )
		  
		  
		  dirs["e"] = Vector(  1,  0,  0 )
		  dirs["w"] = Vector( -1,  0,  0 )
		  
	return pos + dirs[dir]
		  

end



function copyMazeCell(toCopy)
	
	if !toCopy || !toCopy.isCell then return end
	
	local theCopy = {}
	
	for k,v in pairs(toCopy) do
		
		theCopy[k] = v
	
	end
	
	return theCopy

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

function gSetPos(ent, pos, tries)

	
	if !IsValid(ent) then return end
	
	--print("gSetPos( " .. tostring(ent) .. ", " .. tostring(pos) .. ", " .. tostring(tries) .. " )")
	if tries == nil then
		tries = 0
	end
	
	if IsValid(ent) then
	
	
	
		local curDist = (ent:GetPos() - pos):Length()
		--print("curDist: " .. tostring(curDist))
	
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

