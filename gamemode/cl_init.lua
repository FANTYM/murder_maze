include( 'shared.lua' )
DEFINE_BASECLASS( "gamemode_base")

in_render = false
draw_player = true
mazeZero = Vector(0,0,0)
--mapIsOpen = false  -- moved to mini_map ent
inMaze = false

hudQueue = {}
mapSize = Vector(0,0,0)
compassAngle = makeValueSmoother(0, 0, 0.25)

aspectH = (ScrW() / ScrH())
aspectV = (ScrH() / ScrW())
if aspectH > aspectV then 
	aspectH = 1
else 
	aspectV = 1
end

lastHD = CurTime()
exitCamPos = nil
exitEnt = nil

lastPlyMapPos = Vector(0,0,0)

drawBoxes = {}


camTex = GetRenderTargetEx("exit_texture",
        ScrW(),
        ScrH(),
        RT_SIZE_FULL_FRAME_BUFFER,
        MATERIAL_RT_DEPTH_SEPARATE,
        8800,
        CREATERENDERTARGETFLAGS_UNFILTERABLE_OK,
		IMAGE_FORMAT_RGB888
	)
	
exitMat = CreateMaterial("exit_material", "UnlitGeneric", {
		["$selfillum"] = 1,
		["$basetexture"] = "exit_texture"
})

compassBack = Material("/mm/compass_back.vmt")
compassPointer = Material("/mm/compass_pointer.vmt")

hudRTSize = 512
hudRTName = "mini_map_hud_texture" .. tostring(CurTime())
miniMapHudTexture = GetRenderTargetEx( hudRTName,
										hudRTSize,
										hudRTSize,
										RT_SIZE_OFFSCREEN,
										MATERIAL_RT_DEPTH_NONE,
										0,
										CREATERENDERTARGETFLAGS_UNFILTERABLE_OK,
										IMAGE_FORMAT_RGBA8888
									 )

miniMapMat = CreateMaterial("mmmm_hud_material", "UnlitGeneric", 
							{ 
								["$selfillum"] = 1,
								["$basetexture"] = hudRTName,
								["$translucent"] = 1
							})

miniMapHudParts = {}
miniMapHudParts.bg 		= Material("/mm/hud_map_basic.vmt")
miniMapHudParts.ud  	= Material("/mm/hud_map_stairs.vmt")
miniMapHudParts.n  		= Material("/mm/hud_map_door_n.vmt")
miniMapHudParts.s  		= Material("/mm/hud_map_door_s.vmt")
miniMapHudParts.e  		= Material("/mm/hud_map_door_e.vmt")
miniMapHudParts.w  		= Material("/mm/hud_map_door_w.vmt")
miniMapHudParts.ply  	= Material("/mm/hud_map_player.vmt")

updateMiniMap = true

function GM:RenderMapToRT(level)
	
	--print("RenderMapToRT( " .. tostring(level) .. " )")
	local ply = LocalPlayer()
	
	local dirs = {"n", "w", "u", "d", "e", "s"}
	
	local z = 0
	local x = 0
	local y = 0
	
	local plyPos = GetPlayerMapPos(ply)
	
	if level == "b" then
		z = 1
	end
	
	local blockSizeX = math.floor(miniMapHudTexture:Width() / curX)
	local blockSizeY = math.floor(miniMapHudTexture:Height() / curY)
	
	if blockSizeX > blockSizeY then
		blockSizeX = blockSizeY 
	else
		blockSizeY = blockSizeX 
	end
		
	local render_target = render.GetRenderTarget()

	render.SetRenderTarget(miniMapHudTexture)
	render.OverrideAlphaWriteEnable(true, true)
	
	cam.Start2D()
	
		render.ClearRenderTarget(miniMapHudTexture, Color(0,0,0,0))
		
		render.SetViewPort(0,0, hudRTSize, hudRTSize)
		
		for y = 0, curY - 1 do
			
			for x = 0, curX - 1 do
				
				if !self.curMaze then
					self.curMaze = {}
				end
				
				if !self.curMaze[z] then
					self.curMaze[z] = {}
				end
				
				if !self.curMaze[z][x]  then
					self.curMaze[z][x] = {}
				end
				
				if !self.curMaze[z][x][y]  then
					self.curMaze[z][x][y] = newMazeCell()
				end
				
				local curBlock = self.curMaze[z][x][y]
				
				if curBlock.visited then
					
					surface.SetDrawColor(0,0,0,128)
		
					surface.SetMaterial(miniMapHudParts.bg)
					
					surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					
					if curBlock.u || curBlock.d then
						surface.SetMaterial(miniMapHudParts.ud)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					end
					
					if !curBlock.n then
						surface.SetMaterial(miniMapHudParts.n)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					end
					
					if !curBlock.s then
						surface.SetMaterial(miniMapHudParts.s)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					end
					
					if !curBlock.e then
						surface.SetMaterial(miniMapHudParts.e)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					end
					
					if !curBlock.w then
						surface.SetMaterial(miniMapHudParts.w)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					end
					
					if (plyPos.x == x) && (plyPos.y == y) then
						local plyColor = LocalPlayer():GetPlayerColor()
						
						surface.SetDrawColor(255 * plyColor.r, 255 * plyColor.g, 255 * plyColor.b,32)	
						surface.SetMaterial(miniMapHudParts.ply)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
						
					end
					
					--surface.SetMaterial()
				end
				
			end
			
		end
	cam.End2D()
	render.SetRenderTarget(render_target)
	render.SetViewPort(0,0,ScrW(), ScrH())
	render.OverrideAlphaWriteEnable(false)
	miniMapMat:SetTexture("$basetexture", miniMapHudTexture)
	
	--miniMapMat:Recompute()
	
	--return actualSize --* mAspect
	
end

function GM:Initialize()

	BaseClass.Initialize(self)
	
	CleanUpMaze()
	
end

function GM:HUDPaint()
	
	
	BaseClass.HUDPaint(self)
	
	local hDelta = CurTime() - lastHD
	lastHD = CurTime()
	
	surface.SetDrawColor(0,0,0,255)
	
	draw.DrawText( "Time: " .. self.roundEnt:GetFormattedTime(), "DermaLarge", ScrW() * 0.5, 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	if credits then
		draw.DrawText( "Credits: " .. tostring(math.ceil(credits:GetValue())), "DermaLarge", ScrW(), 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT )
	end
	
	surface.SetDrawColor(0,0,0,32)	
	
	surface.SetMaterial(miniMapMat)
	surface.DrawTexturedRect(8, 144, hudRTSize * aspectH, hudRTSize * aspectV)
	
	surface.SetDrawColor(0,0,0,255)	
		
	if #hudQueue > 0 then
		
		if !hudQueue[1].ttd then
			hudQueue[1].ttd = CurTime() + hudQueue[1].ttl 
			--PrintTable(hudQueue[1])
			--print("CurTime(): " .. tostring(CurTime()))
			--print("setting ttd: " .. tostring(hudQueue[1].ttd))
		end
		
		draw.DrawText( hudQueue[1].message, "DermaLarge", ScrW() * 0.5, ScrH() * 0.2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
		
		if CurTime() > hudQueue[1].ttd then
			
			table.remove(hudQueue, 1)
		
		end
		
	end	
	
	surface.SetMaterial(compassBack)
	surface.DrawTexturedRect(8, 8, 128,128)
	
	surface.SetMaterial(compassPointer)
	surface.DrawTexturedRectRotated(72, 72, 128,128, compassAngle:GetValue())
	
	return true 
	
end

function CleanUpMaze()
	
	if GAMEMODE.roundEnt then
		
		if !inMaze && (GAMEMODE.roundEnt:GetCurrentTitle() != "pre" && 
					   GAMEMODE.roundEnt:GetCurrentTitle() != "in" && 
					   GAMEMODE.roundEnt:GetCurrentTitle() != "ending") then
		
			local csEnts = ents.FindByClass("class C_BaseFlex")
			--print("Found " .. tostring(#csEnts) .. " ... Removing")
			
			for k,csEnt in pairs(csEnts) do
				
				if !csEnt.noDelete then
					csEnt:Remove()
				end
			
			end
			
			curX = 0
			curY = 0
			
			GAMEMODE.curMaze = {}
			
			updateMiniMap = true
			
		end
	end
	
	timer.Simple(3, CleanUpMaze)
	
end



net.Receive( "rec_room_from_server", function(len, ply)
									
									local roomPos = net.ReadVector()
									
									--print("Receiving info for room: " .. tostring(roomPos))
									
									local recCell = newMazeCell()
									
									recCell.u = net.ReadBool()
									recCell.d = net.ReadBool()
									recCell.n = net.ReadBool()
									recCell.s = net.ReadBool()
									recCell.e = net.ReadBool()
									recCell.w = net.ReadBool()
									recCell.visited = true
									
									--PrintTable(GAMEMODE.curMaze)
									if !GAMEMODE.curMaze then
										GAMEMODE.curMaze = {}
									end
									
									if !GAMEMODE.curMaze[roomPos.z] then
										GAMEMODE.curMaze[roomPos.z] = {}
									end
									
									if !GAMEMODE.curMaze[roomPos.z][roomPos.x]  then
										GAMEMODE.curMaze[roomPos.z][roomPos.x] = {}
									end
									
									GAMEMODE.curMaze[roomPos.z][roomPos.x][roomPos.y] = recCell
									
									updateMiniMap = true
									
								end )
								
net.Receive( "add_draw_box", function(len, ply)
									
									local newBox = {}
									
									newBox.pos = net.ReadVector()
									
									newBox.min = net.ReadVector()
									newBox.max = net.ReadVector()
									
									newBox.ttl = net.ReadFloat()
									
									table.insert(drawBoxes, newBox)
										
								end )
								
net.Receive( "destroy_maze", function(len, ply)
									
									--CleanUpMaze()
										
								end )

net.Receive( "play_sound", function(len, ply)
									
									surface.PlaySound(net.ReadString())
										
								end )
								
net.Receive( "hud_message", function(len, ply)
									--print("recieved hud message")
									
									local message = net.ReadString()
									local ttl = net.ReadFloat()
									
									--print("message: " .. tostring(message))
									--print("ttl: " .. tostring(ttl))
									
									local msg = {}
										  msg.message = message
										  msg.ttl = ttl
										  
									table.insert(hudQueue, msg)
										
								end )
								
net.Receive( "update_maze_size", function(len, ply)
									
									curX = net.ReadInt(32)
									curY = net.ReadInt(32)
									
									--print("Got maze size update: " .. tostring(curX) .. ", " .. tostring(curY))
									
								end )
								
net.Receive( "world_size", function(len, ply)
									
									mapSize = net.ReadVector()
									--print("Got map size: " .. tostring(mapSize))
								end )
								
net.Receive( "maze_zero", function(len, ply)
									--print("Got maze zero.")
									mazeZero = net.ReadVector()
									
								end )
								
net.Receive( "in_maze", function(len, ply)
									--print("inMaze update")
									inMaze = net.ReadBool()
									if !inMaze then
										--print("Player is not in the maze...")
									else 
										--print("Player is in the maze...")
									end
								end )
								
net.Receive( "get_exit_cam", function(len, ply)
									--print("Got Exit Cam Position")
									exitCamPos = net.ReadVector()
									--print("exitCamPos: " .. tostring(exitCamPos))
								end )
								
net.Receive( "credit_info", function(len, ply)
									--print("Got credit update")
									local newCredits = net.ReadInt(32)
									--print("newCredits: " .. tostring(newCredits))
									
									
									if credits == nil then
										credits = makeValueSmoother(0, newCredits, 1.25) 
									else
										credits = makeValueSmoother(credits:GetValue(), newCredits, 1.25) 
										--credits.sVal = credits:GetValue()
										--credits.eVal = newCredits
										--credits.startTime = CurTime()
									end
									--print("credits: " .. tostring(credits:GetValue()))
								end )
								
							
local canNextSound = CurTime()
local lastNum = -1

function GM:Think()
	
	BaseClass.Think(self)
	
	local playerYaw = LocalPlayer():GetAngles().y - 90
	local angleDelta = compassAngle.eVal - playerYaw
	
	if self.roundEnt:GetTimeLeft() < 10 && (self.roundEnt:GetCurrentTitle() == "in" || self.roundEnt:GetCurrentTitle() == "ending") then
		
		local curNum = math.ceil(self.roundEnt:GetTimeLeft() - 0.5)
		
		if (CurTime() > canNextSound) && curNum != lastNum then
			
			surface.PlaySound(countDownSounds[curNum])
			
			canNextSound = CurTime() + SoundDuration(countDownSounds[curNum])
			
			lastNum = curNum
			
			--if curNum == 10 then surface.PlaySound(net.ReadString())
		end
	
	end
	----print(" ")
	----print("compassAngle: " .. tostring(compassAngle:GetValue()))
	----print("playerYaw: " .. tostring(playerYaw))
	----print("angleDelta: " .. tostring(angleDelta))
	
	if angleDelta < -359 then
		----print("bigDelta: " .. tostring(angleDelta) .. " <-------------------------------------------")
		compassAngle.sVal = playerYaw
		compassAngle.eVal = -compassAngle:GetValue()
		
	elseif angleDelta > 359 then
		----print("bigDelta: " .. tostring(angleDelta) .. " <-------------------------------------------")
		compassAngle.sVal = playerYaw
		compassAngle.eVal = -compassAngle:GetValue()
	else
		compassAngle.sVal = compassAngle:GetValue()
		compassAngle.eVal = playerYaw
	end
	
	compassAngle.aTime = (1 / math.abs(compassAngle.sVal - compassAngle.eVal)) * 2
	
	compassAngle.startTime = CurTime() --makeValueSmoother(compassAngle:GetValue(), LocalPlayer():GetAngles().y, 0.1)
	----PrintTable(compassAngle)
	if !credits then
		net.Start("request_credit_info")
		net.SendToServer()
	end
	
	if mapSize == Vector(0,0,0) then
	
		net.Start("req_world_size")
		net.SendToServer()
		
	end
	
	if mazeZero == Vector(0,0,0) then
		
		net.Start("req_maze_zero")
		net.SendToServer()
	
	end
	
	if curX == 0 || curY == 0 then
		
		net.Start("req_maze_size")
		net.SendToServer()
		
	end
	
	local curPlyMapPos = GetPlayerMapPos(LocalPlayer())
	
	if  curPlyMapPos != lastPlyMapPos then
		net.Start("req_room_from_server")
			net.WriteVector(curPlyMapPos)
		net.SendToServer()
		lastPlyMapPos = curPlyMapPos
		
	end
end
		

hook.Add( "RenderScene", "renderScene_m", function( ViewOrigin, ViewAngles, ViewFOV )
	
	
	renderScene( ViewOrigin, ViewAngles )
	
	
	if updateMiniMap then
		local plyMapPos = GetPlayerMapPos(LocalPlayer())
		local levelChar = "t"
		
		if plyMapPos.z == 1 then
			levelChar = "b"
		end
		
		GAMEMODE.miniMapSize = GAMEMODE:RenderMapToRT(levelChar)
		updateMiniMap = false
		--print("miniMapSize: " .. tostring(GAMEMODE.miniMapSize))
	end 


end )

function renderScene(origin, angles)
	
	if in_render then return end
	
	if (!exitCamPos || !exitEnt) ||
	   (!IsValid(exitEnt)) then 
	
	   if !exitCamPos then
			net.Start("request_exit_cam")
			net.SendToServer()
	   end
	   
	   return
	end
	
	in_render = true
	local doorNormal = -exitEnt:GetForward()

	local doorDist = doorNormal:Dot(exitCamPos)

	local exitNormal = exitCamPos:Angle():Forward()

	local exitDist = exitNormal:Dot(exitEnt:GetPos())
			
	local fwd = angles:Forward()

	local up = angles:Up()

	local dot = origin:DotProduct( doorNormal ) - doorDist
	origin = origin + ( -2 * dot ) * doorNormal

	local dot = fwd:DotProduct( doorNormal)
	fwd = fwd + (-2 * dot) * doorNormal

	local dot = up:DotProduct( doorNormal)
	up = up + (-2 * dot) * doorNormal

	angles = math.VectorAngles( fwd, up)

	local lOrigin = exitEnt:WorldToLocal(origin)
	local lAngles = exitEnt:WorldToLocalAngles( angles)

	lOrigin.y = -lOrigin.y
	lAngles.y = -lAngles.y
	lAngles.r = -lAngles.r

	local view = {}

	view.x = 0
	view.y = 0
	view.w = ScrW()
	view.h = ScrH()

	view.origin = exitCamPos + Vector(0,0,0)
	--view.angles = Angle(0,180,0)
	--view.origin = everythingServesTheBeam:LocalToWorld(lOrigin) --exitCam:GetPos() --+ ((exitCam - LocalPlayer():GetPos()) * 0.01)
	view.angles = everythingServesTheBeam:LocalToWorldAngles(lAngles) --Angle(0,-180,0) + Angle(LocalPlayer():GetAngles().p , 0, 0)

	view.fov = 106

	local render_target = render.GetRenderTarget()

	render.SetRenderTarget(camTex)

			--render.Clear(0, 0, 0, 255)
			--render.ClearDepth()
			--render.ClearStencil()
			
			--render.SetViewPort(0, 0,  80, 80)
			--render.SetViewPort(0,0,ScrW(), ScrH())
			
				exitEnt:SetNoDraw(true)
				cam.Start2D()
					
					render.RenderView(view)
					
				cam.End2D()
				exitEnt:SetNoDraw(false)
			
			--render.SetViewPort(0,0,ScrW(), ScrH())
			
			
	render.SetRenderTarget(render_target)

	
	exitMat:SetTexture("$basetexture", camTex)
	
	in_render = false
	
end
--[[
function GM:PreDrawViewModel( viewModel, ply, weapon )
	
	viewModel = LocalPlayer():GetViewModel()
	ply = LocalPlayer()
	weapon = ply:GetActiveWeapon()
	----print(self, viewModel, ply, weapon)
	BaseClass.PreDrawViewModel(self, viewModel, ply, weapon)
	----print(self, viewModel, ply, weapon)
	render.SuppressEngineLighting(true)	
	render.ResetModelLighting( 1.0, 1.0, 1.0 )
	render.SetAmbientLight( 1.0, 1.0, 1.0 )
	
	
	----print("PreDrawViewModel")
	--viewModel:SetNoDraw(false)
	
end
--]]

local matColor = Material("color")

function GM:PreDrawOpaqueRenderables()
	
	if drawBoxes then
		if #drawBoxes > 0 then
			
			for i = 1, #drawBoxes do
				
				
				local curBox = drawBoxes[i]
				
				if curBox == nil then continue end
				
				----PrintTable(curBox)
				
				if curBox.dieTime == nil then
					curBox.dieTime = CurTime() + curBox.ttl 
				end
				
				render.SetColorMaterial()
				
				--render.DrawBox( curBox.pos, Angle(0,0,0), curBox.min, curBox.max, Color(255,255,0,196), true )
				render.DrawWireframeBox( curBox.pos, Angle(0,0,0), curBox.min, curBox.max, Color(255,255,0,196), false )
			
				
				
				if CurTime() >= curBox.dieTime then
					table.remove(drawBoxes, i)
				end
				
			end
		end
	end
	
end

function GM:PostDrawViewModel( viewModel, ply, weapon )
	
	viewModel = LocalPlayer():GetViewModel()
	ply = LocalPlayer()
	weapon = ply:GetActiveWeapon()
	
	BaseClass.PostDrawViewModel(self, vm, ply, weapon)
	
	if ( weapon.Use || !weapon:IsScripted() ) then

		local hands = LocalPlayer():GetHands()
		
		local plyBlock = self:GetPlayerBlock()
		
		if inMaze && IsValid(plyBlock) then
			
			render.SuppressEngineLighting(true)
			
			render.SetLightingOrigin(plyBlock.lightPos)
			
			render.ResetModelLighting( 0.0, 0.0, 0.0 )
			
			lightInfo = {}
			lightInfo.type = MATERIAL_LIGHT_POINT
			lightInfo.color = plyBlock:colorToVector(plyBlock:GetColor()) --doorBlock.lightColor * 0.25
			lightInfo.pos = plyBlock.lightPos

			lightInfo.fiftyPercentDistance = 13.5
			lightInfo.zeroPercentDistance = 27
			lightInfo.quadraticFalloff = 1
			lightInfo.linearFalloff = 1
			lightInfo.constantFalloff = 0
			
			render.SetLocalModelLights({lightInfo})
		    
			if ( IsValid( hands ) ) then 
				hands:DrawModel() 
			end		
			
			render.SuppressEngineLighting(false)
		else 
			
			if ( IsValid( hands ) ) then 
				hands:DrawModel() 
			end
			
		end 
		
	end

end

function GM:GetPlayerBlock()
	
	local ply = LocalPlayer()
	----print(ply)
	
	local plyMapPos = GetPlayerMapPos(ply)
	----print(plyMapPos)
	
	local blockPos = GetBlockWorldPos(plyMapPos) * Vector(1,1,1)
	----print(blockPos)
	
	local blockList = ents.FindInBox( blockPos - (blockSizes * 0.5), blockPos + (blockSizes * 0.5) ) --ents.FindInSphere(blockPos, 128)
	
	local blockEnt = nil
	local cDist = 640000
	
	for k, ent in pairs(blockList) do
		
		if ent:GetClass() == "maze_block" then
			
			local bDist = (LocalPlayer():GetPos() - ent:GetPos()):Length()
			
			if bDist < cDist then
				blockEnt = ent
				cDist = bDist
			end
			--break
		end
		
	end
	
	----print("Player Block List: ")
	----PrintTable(blockList)
	----print("---------------------------")
	----print("blockEnt: " .. tostring(blockEnt))
	
	return blockEnt
	
end

/*------------------------------------
        VectorAngles()
------------------------------------*/
function math.VectorAngles( forward, up )

        local angles = Angle( 0, 0, 0 )

        local left = up:Cross( forward )
        left:Normalize()
       
        local xydist = math.sqrt( forward.x * forward.x + forward.y * forward.y )
       
        // enough here to get angles?
        if( xydist > 0.001 ) then
       
                angles.y = math.deg( math.atan2( forward.y, forward.x ) )
                angles.p = math.deg( math.atan2( -forward.z, xydist ) )
                angles.r = math.deg( math.atan2( left.z, ( left.y * forward.x ) - ( left.x * forward.y ) ) )

        else
       
                angles.y = math.deg( math.atan2( -left.x, left.y ) )
                angles.p = math.deg( math.atan2( -forward.z, xydist ) )
                angles.r = 0
       
        end
 

        return angles
       
end

function GM:InitPostEntity() 
	
	BaseClass.InitPostEntity(self)
	
	--print ("InitPostEntity() : " .. tostring(CurTime()))
	
	everythingServesTheBeam = ents.FindByClass( "beam" )[1]

	--print("everythingServesTheBeam: " .. tostring(everythingServesTheBeam:GetPos()))

end

local storeMenu
storeIsOpen = false

function openStore(len, ply)
	
	--print("opening store menu...")
	
	if storeIsOpen then
		--print("store already open")
		storeMenu:Remove()
		return
	end
	
	gui.EnableScreenClicker( true )
	
	storeIsOpen = true
	
	storeMenu = vgui.Create('DFrame')
	storeMenu:SetSize(ScrW() * 0.5, ScrH() * 0.5)
	storeMenu:Center()
	storeMenu:SetTitle('Murder Maze - Store')
	storeMenu:SetDeleteOnClose(true)

	storeMenu.OnRemove = function(self) 
							storeIsOpen = false
							gui.EnableScreenClicker(false) 
						end

	-- Store Icons
	local titleOffset = 24
	local maxCols = 4
	local rowPad = 8
	local rowCount = 0
	local colPad = 8
	local colCount = 0
	
	local spawnIconWidth = (storeMenu:GetWide() / maxCols) - rowPad
	local spawnIconHeight = spawnIconWidth
	
	local lblTemp = vgui.Create("DLabel")
		  lblTemp:SetFont("DermaDefaultBold")
		  lblTemp:SetText("W")
	
	local lblHeight = lblTemp:GetTall()
	
	lblTemp:Remove()
	
	local longest = 0
	local widest = 0
	
	for itemNumber, item in pairs(items) do
		
		if item.class == "internal" then continue end
		
		if string.len(item.title) > longest then
			longest = string.len(item.title)
		end
		
		local toolTip = item.title .. " \n " .. "Cost: " .. tostring(item.cost) .. " Quantity: " .. tostring(item.quantity)
		
		local spiBack = vgui.Create("DPanel")
			  spiBack:SetParent(storeMenu)
			  spiBack:SetPos( colPad + (colPad + spawnIconWidth) * colCount,
							  rowPad + titleOffset + ((rowPad + spawnIconHeight) * rowCount ))
			  spiBack:SetSize(spawnIconWidth, spawnIconWidth)
			  spiBack:SetBackgroundColor(Color(63,63,63,32))
		
		local spawnIcon = vgui.Create("SpawnIcon")
			  spawnIcon:SetModel(item.model)
			  spawnIcon:SetParent(spiBack)		
			  spawnIcon:SetSize(spawnIconWidth * 0.70, spawnIconHeight * 0.70)
			  spawnIcon:SetPos( (spiBack:GetWide() * 0.5) - (spawnIcon:GetWide() * 0.5), (spiBack:GetTall() * 0.5) - (spawnIcon:GetTall() * 0.5))
			
			
			  spawnIcon:SetToolTip( toolTip )
			  spawnIcon.OnMousePressed = function() 
										net.Start("req_purchase") 
											net.WriteInt(itemNumber, 32)
										net.SendToServer()
									end
									
		lblTemp = vgui.Create("DLabel")
		lblTemp:SetFont("DermaDefaultBold")
		lblTemp:SetText(item.title)	
		lblTemp:SetParent(spiBack)
		lblTemp:SizeToContents()	
		lblTemp:SetPos((spawnIconWidth * 0.5) - (lblTemp:GetWide() * 0.5), lblTemp:GetTall() * 0.5)
		
		
		lblTemp = vgui.Create("DLabel")
		lblTemp:SetFont("DermaDefaultBold")
		lblTemp:SetText("x" .. item.quantity)	
		lblTemp:SetParent(spawnIcon)
		lblTemp:SizeToContents()	
		lblTemp:SetPos(spawnIcon:GetWide() - (lblTemp:GetWide() ) ,spawnIcon:GetTall() - lblTemp:GetTall() )
		
		lblTemp = vgui.Create("DLabel")
		lblTemp:SetFont("DermaDefaultBold")
		lblTemp:SetText("Cost: " .. item.cost)	
		lblTemp:SetParent(spiBack)
		lblTemp:SizeToContents()	
		lblTemp:SetPos(colPad , spiBack:GetTall() - (lblTemp:GetTall() * 1.5 ) - rowPad)
		
		
		--spawnIcon.OnMouseReleased = function() RememberCursorPosition( ) storeMenu:Close() end
		
		colCount = colCount + 1
		if colCount == maxCols then
			colCount = 0
			rowCount = rowCount +1
		end
		
	end	
	

	storeMenu:SizeToChildren(true,true)
	storeMenu:InvalidateLayout(false)
	
	storeMenu:SetSize(storeMenu:GetWide() + (colPad * 0.5), storeMenu:GetTall() + (rowPad * 0.5))
	
	storeMenu:SetVerticalScrollbarEnabled(true)
	
end

net.Receive("open_store", openStore)

function openHelp(len, ply)
	
	--print("opening help menu...")


end

net.Receive("open_help", openHelp)

local playerMenu
playerIsOpen = false 

function openPlayer(len, ply)
	
	--print("opening player menu...")
	
	if playerIsOpen then
		--print("store already open")
		playerMenu:Remove()
		return
	end
	
	local plyPanel
	local totalHorizontalOffset = 0
	local titleOffset = 24
	local maxCols = 3
	local rowPad = 8
	local rowCount = 0
	local colPad = 8
	local colCount = 0
	
	gui.EnableScreenClicker( true )
	
	playerIsOpen = true
	
	playerMenu = vgui.Create("DFrame")
	playerMenu:SetSize(ScrW() * 0.5, ScrH() * 0.5)
	playerMenu:Center()
	playerMenu:SetTitle("Murder Maze - Player Options/Info")
	playerMenu:SetDeleteOnClose(true)
	local pmPos = {}
	--pmPos.x, pmPos.y = playerMenu:GetPos()
	--playerMenu:SetPos((ScrW() - playerMenu:GetWide()) - colPad * 2, pmPos.y)

	playerMenu.OnRemove = function(self) 
							playerIsOpen = false
							gui.EnableScreenClicker(false) 
						end
	
	
	
	local lblPlyClr = vgui.Create("DLabel")
		  lblPlyClr:SetPos(colPad * 1.5, titleOffset + 2)
		  lblPlyClr:SetText("Player Color")
		  lblPlyClr:SetParent(playerMenu)
	
	
	totalHorizontalOffset = totalHorizontalOffset +  lblPlyClr:GetWide()
	
	local clrPick = vgui.Create("DRGBPicker")
		  clrPick:SetParent(playerMenu)
		  clrPick:SetSize((lblPlyClr:GetWide() * 0.9),128)
		  clrPick:SetPos(colPad + (lblPlyClr:GetWide() * 0.5) - (clrPick:GetWide() * 0.5), titleOffset + lblPlyClr:GetTall())
		  clrPick.OnChange = function ( self, color )
								net.Start("set_player_color")
									net.WriteVector( Vector(color.r / 255, color.g / 255, color.b / 255) )
								net.SendToServer()
								end
								
	--totalHorizontalOffset = totalHorizontalOffset --+ clrPick:GetWide()
	
	local lblPlyMdl = vgui.Create("DLabel")
		  lblPlyMdl:SetPos((colPad * 2) + lblPlyClr:GetWide(), titleOffset + 2)
		  lblPlyMdl:SetText("Player Model")
		  lblPlyMdl:SetParent(playerMenu)

	--totalHorizontalOffset = lblPlyMdl:GetPos() --totalHorizontalOffset + colPad
	
	local spawnIconWidth = (((playerMenu:GetWide() - totalHorizontalOffset) * 0.5) / maxCols) - rowPad
	local spawnIconHeight = spawnIconWidth
	
	for k, plyModel in pairs(males) do
			
		local toolTip = "Male"
		
		local spiBack = vgui.Create("DPanel")
			  spiBack:SetParent(playerMenu)
			  spiBack:SetPos( lblPlyMdl:GetPos() + (colPad + spawnIconWidth) * colCount,
							  rowPad + titleOffset + ((rowPad + spawnIconHeight) * rowCount ) + lblPlyMdl:GetTall())
			  spiBack:SetSize(spawnIconWidth, spawnIconWidth)
			  spiBack:SetBackgroundColor(Color(63,63,63,32))
		
		local spawnIcon = vgui.Create("SpawnIcon")
			  spawnIcon:SetModel(plyModel)
			  spawnIcon:SetParent(spiBack)		
			  spawnIcon:SetSize(spawnIconWidth * 0.70, spawnIconHeight * 0.70)
			  spawnIcon:SetColor(LocalPlayer():GetPlayerColor())
			  spawnIcon:SetPos( (spiBack:GetWide() * 0.5) - (spawnIcon:GetWide() * 0.5), (spiBack:GetTall() * 0.5) - (spawnIcon:GetTall() * 0.5))
			
			
			  spawnIcon:SetToolTip( toolTip )
			  spawnIcon.OnMousePressed = function() 
										net.Start("set_player_model")
											net.WriteString( plyModel )
										net.SendToServer()
										timer.Simple(0.1, function()
											plyPanel:SetModel(LocalPlayer():GetModel())
											function plyPanel.Entity:GetPlayerColor() return LocalPlayer():GetPlayerColor() end
										end)
									end
									
		colCount = colCount + 1
		if colCount == maxCols then
			colCount = 0
			rowCount = rowCount +1
		end
		
	end
	
	totalHorizontalOffset = totalHorizontalOffset + (colPad * 2) + ((colPad + spawnIconWidth) * maxCols)
	
	colCount = 0
	rowCount = 0
	
	for k, plyModel in pairs(females) do
			
		local toolTip = "Female"
		
		local spiBack = vgui.Create("DPanel")
			  spiBack:SetParent(playerMenu)
			  spiBack:SetPos( totalHorizontalOffset + (colPad + spawnIconWidth) * colCount,
							  rowPad + titleOffset + ((rowPad + spawnIconHeight) * rowCount ) + lblPlyMdl:GetTall())
			  spiBack:SetSize(spawnIconWidth, spawnIconWidth)
			  spiBack:SetBackgroundColor(Color(63,63,63,32))
		
		local spawnIcon = vgui.Create("SpawnIcon")
			  spawnIcon:SetModel(plyModel)
			  spawnIcon:SetParent(spiBack)		
			  spawnIcon:SetSize(spawnIconWidth * 0.70, spawnIconHeight * 0.70)
			  spawnIcon:SetColor(LocalPlayer():GetPlayerColor())
			  spawnIcon:SetPos( (spiBack:GetWide() * 0.5) - (spawnIcon:GetWide() * 0.5), (spiBack:GetTall() * 0.5) - (spawnIcon:GetTall() * 0.5))
			
			
			  spawnIcon:SetToolTip( toolTip )
			  spawnIcon.OnMousePressed = function() 
										net.Start("set_player_model")
											net.WriteString( plyModel )
										net.SendToServer()
										timer.Simple(0.1, function()
											plyPanel:SetModel(LocalPlayer():GetModel())
											function plyPanel.Entity:GetPlayerColor() return LocalPlayer():GetPlayerColor() end
										end)
									end
									
		colCount = colCount + 1
		if colCount == maxCols then
			colCount = 0
			rowCount = rowCount +1
		end
		
	end
	
	totalHorizontalOffset = totalHorizontalOffset + (colPad * 2) + ((colPad + spawnIconWidth) * maxCols)
	
	plyPanel = vgui.Create("DModelPanel")
	plyPanel:SetPos( totalHorizontalOffset, titleOffset + 2)
	plyPanel:SetSize(ScrW() / 10, ScrH() * 0.4)
	plyPanel:SetParent(playerMenu)
	plyPanel:SetModel(LocalPlayer():GetModel())
	function plyPanel:LayoutEntity( ent ) ent:SetAngles(Angle(0,45,0)) return end
	function plyPanel.Entity:GetPlayerColor() return LocalPlayer():GetPlayerColor() end
	plyPanel:SetCamPos(Vector(15, 25, 64))
	plyPanel:SetLookAt(Vector(0, 0, 48) )
	plyPanel:SetFOV(45)
	plyPanel.Entity.noDelete = true
				
			
	playerMenu:SizeToChildren(true,true)
	playerMenu:SetSize(playerMenu:GetWide() + colPad, playerMenu:GetTall() + rowPad)
	
end

net.Receive("open_player", openPlayer)

function showWelcome(len, ply)

	local welcomeMenu = vgui.Create('DFrame')
		  welcomeMenu:SetSize(ScrW(), ScrH() - (ScrH() * 0.25))
		  welcomeMenu:Center()
		  welcomeMenu:SetTitle('Welcome To Murder Maze')
		  welcomeMenu:SetSizable(false)
		  welcomeMenu:SetDeleteOnClose(true)
		  welcomeMenu:SetBackgroundBlur(true)
		  welcomeMenu:MakePopup()

	local htmlPanel = vgui.Create('HTML')
		  htmlPanel:SetParent(welcomeMenu)
		  htmlPanel:SetPos(5, 24)
		  htmlPanel:SetSize(welcomeMenu:GetWide() - 5, welcomeMenu:GetTall() - (welcomeMenu:GetTall() * 0.1))
		  --htmlPanel:OpenURL("https://sites.google.com/site/murdermazeintro/welcome/murder_maze_intro.html?attredirects=0&d=1")
		  htmlPanel:OpenURL("https://sites.google.com/site/fantym420/")
		  
		  htmlPanel:Refresh(true)
	
	local playButton = vgui.Create('DButton')
		  playButton:SetParent(welcomeMenu)
		  playButton:SetSize(welcomeMenu:GetWide() - 20, 25)
		  playButton:SetPos(5, welcomeMenu:GetTall() - 35)
	  	  playButton:SetText('Play!')
		  playButton.DoClick = function() welcomeMenu:Close() end
	
end

net.Receive("show_welcome", showWelcome)

function GM:PrePlayerDraw( ply )

	BaseClass.PrePlayerDraw(self, ply)
	
	if !IsValid(ply) then return end
	
	local plyDist = (LocalPlayer():GetPos() - ply:GetPos()):Length()
	
	if plyDist > 1056 then return end
	
	render.SuppressEngineLighting(true)
	
end

function GM:PostPlayerDraw( ply )
	
	BaseClass.PostPlayerDraw(self, ply)
	
	if !IsValid(ply) then return end
	
	local plyDist = (LocalPlayer():GetPos() - ply:GetPos()):Length()
	
	if plyDist > 1056 then return end
	
	render.SuppressEngineLighting(false)
	
	local plyHeadBone = ply:LookupBone( "ValveBiped.Bip01_Head1" )
	local plyHeadPos, plyHeadAngle = ply:GetBonePosition(plyHeadBone)
	
	local nameOffset = ((plyHeadPos - ply:GetPos()) * Vector(1,1,0)) + Vector(0,0,73)
	local namePos = ply:GetPos() + nameOffset + plyHeadAngle:Up()
	local plyColor = ply:GetPlayerColor()

	plyHeadAngle:RotateAroundAxis( plyHeadAngle:Right(), 90 )	

	cam.Start3D2D( namePos, Angle(0,plyHeadAngle.y, 90)  , 0.25)
		draw.DrawText( ply:GetName(), "DermaLarge", 0,0, Color( 255 * plyColor.r, 255 * plyColor.g, 255 * plyColor.b, 196), TEXT_ALIGN_CENTER)
	cam.End3D2D()
	
end


function GM:CalcView(ply, origin, angles, fov, znear, zfar )
	
	local view = {}
	
	local plyHead = ply:GetPos() + (ply:GetAngles():Up() * 72)
	
	if (playerIsOpen) then
		
		view.origin = plyHead + (ply:GetForward() * Vector(100,100,0)) -- + ( angles:Forward() * 180 ) + Vector(0,0,100) --+ (angles:Right() * 150)
		view.angles = ((plyHead + ply:GetRight() * -50) - view.origin):Angle() --angles
		view.fov = fov
		view.drawviewer = true

		--return view
		
	end
			
end
