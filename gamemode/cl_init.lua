include( 'shared.lua' )

DEFINE_BASECLASS( "gamemode_base")

mm_cl_globals = {}
mm_cl_globals.inMaze = false
mm_cl_globals.in_render = false
mm_cl_globals.storeIsOpen = false
mm_cl_globals.playerIsOpen = false 
mm_cl_globals.updateMiniMap = true

mm_cl_globals.mapSize = Vector(0,0,0)
mm_cl_globals.mazeZero = Vector(0,0,0)
mm_cl_globals.lastPlyMapPos = Vector(0,0,0)
mm_cl_globals.compassAngle = makeValueSmoother(0, 0, 0.25)

mm_cl_globals.lastHD = CurTime()

mm_cl_globals.exitCamPos = nil
mm_cl_globals.exitEnt = nil

mm_cl_globals.hudRTSize = 512
mm_cl_globals.hudRTName = "mini_map_hud_texture" .. tostring(CurTime())

mm_cl_globals.canNextSound = CurTime()
mm_cl_globals.lastNum = -1
mm_cl_globals.storeMenu = nil
mm_cl_globals.playerMenu = nil
mm_cl_globals.scoreMenu = nil

mm_cl_globals.hudQueue = {}
mm_cl_globals.drawBoxes = {}
mm_cl_globals.scores = {}

mm_cl_globals.compassBack = Material("/mm/compass_back.vmt")
mm_cl_globals.compassPointer = Material("/mm/compass_pointer.vmt")
mm_cl_globals.miniMapHudParts = {}
mm_cl_globals.miniMapHudParts.bg 		= Material("/mm/hud_map_basic.vmt")
mm_cl_globals.miniMapHudParts.ud  	= Material("/mm/hud_map_stairs.vmt")
mm_cl_globals.miniMapHudParts.n  		= Material("/mm/hud_map_door_n.vmt")
mm_cl_globals.miniMapHudParts.s  		= Material("/mm/hud_map_door_s.vmt")
mm_cl_globals.miniMapHudParts.e  		= Material("/mm/hud_map_door_e.vmt")
mm_cl_globals.miniMapHudParts.w  		= Material("/mm/hud_map_door_w.vmt")
mm_cl_globals.miniMapHudParts.ply  	= Material("/mm/hud_map_player.vmt")

mm_cl_globals.aspectH = (ScrW() / ScrH())
mm_cl_globals.aspectV = (ScrH() / ScrW())
if mm_cl_globals.aspectH > mm_cl_globals.aspectV then 
	mm_cl_globals.aspectH = 1
else 
	mm_cl_globals.aspectV = 1
end

mm_cl_globals.camTex = GetRenderTargetEx( "exit_texture",
										  ScrW(),
										  ScrH(),
										  RT_SIZE_FULL_FRAME_BUFFER,
										  MATERIAL_RT_DEPTH_SEPARATE,
										  8800,
										  CREATERENDERTARGETFLAGS_UNFILTERABLE_OK,
										  IMAGE_FORMAT_RGB888)
	
mm_cl_globals.exitMat = CreateMaterial("exit_material", "UnlitGeneric", {
																			["$selfillum"] = 1,
																			["$basetexture"] = "exit_texture"
																		})

mm_cl_globals.miniMapHudTexture = GetRenderTargetEx( mm_cl_globals.hudRTName,
													 mm_cl_globals.hudRTSize,
													 mm_cl_globals.hudRTSize,
													 RT_SIZE_OFFSCREEN,
													 MATERIAL_RT_DEPTH_NONE,
													 0,
													 CREATERENDERTARGETFLAGS_UNFILTERABLE_OK,
													 IMAGE_FORMAT_RGBA8888)

mm_cl_globals.miniMapMat = CreateMaterial("mmmm_hud_material", "UnlitGeneric", { 
																					["$selfillum"] = 1,
																					["$basetexture"] = mm_cl_globals.hudRTName,
																					["$translucent"] = 1
																			   })



net.Receive("rec_scores", function (len, ply) 
	
	local plyCount = net.ReadInt(32)
		
	for i = 1, plyCount do
		local newScore = {}		
			  newScore.nick = net.ReadString()
			  newScore.mazeStats = net.ReadVector()  
			  newScore.credits = net.ReadInt(32)
		table.insert(mm_cl_globals.scores, newScore)
	end
	
end)

net.Receive( "rec_room_from_server", function(len, ply)
									
									local roomPos = net.ReadVector()
																		
									local recCell = newMazeCell()
									
									recCell.u = net.ReadBool()
									recCell.d = net.ReadBool()
									recCell.n = net.ReadBool()
									recCell.s = net.ReadBool()
									recCell.e = net.ReadBool()
									recCell.w = net.ReadBool()
									recCell.visited = true
									
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
									
									mm_cl_globals.updateMiniMap = true
									
								end )
								
net.Receive( "add_draw_box", function(len, ply)
									
									local newBox = {}
									
									newBox.pos = net.ReadVector()
									
									newBox.min = net.ReadVector()
									newBox.max = net.ReadVector()
									
									newBox.ttl = net.ReadFloat()
									
									table.insert(mm_cl_globals.drawBoxes, newBox)
										
								end )
								
net.Receive( "play_sound", function(len, ply)
									
									surface.PlaySound(net.ReadString())
										
								end )
								
net.Receive( "hud_message", function(len, ply)
									local message = net.ReadString()
									local ttl = net.ReadFloat()
									
									local msg = {}
										  msg.message = message
										  msg.ttl = ttl
										  
									table.insert(mm_cl_globals.hudQueue, msg)
										
								end )
								
net.Receive( "update_maze_size", function(len, ply)
									
									mm_sh_globals.curX = net.ReadInt(32)
									mm_sh_globals.curY = net.ReadInt(32)
																		
								end )
								
net.Receive( "world_size", function(len, ply)
									
									mm_cl_globals.mapSize = net.ReadVector()
									
								end )
								
net.Receive( "maze_zero", function(len, ply)

									mm_cl_globals.mazeZero = net.ReadVector()
									
								end )
								
net.Receive( "in_maze", function(len, ply)

									mm_cl_globals.inMaze = net.ReadBool()
									
								end )
								
net.Receive( "get_exit_cam", function(len, ply)
									mm_cl_globals.exitCamPos = net.ReadVector()
								end )
								
net.Receive( "credit_info", function(len, ply)
									local newCredits = net.ReadInt(32)
									
									if credits == nil then
										credits = makeValueSmoother(0, newCredits, 1.25) 
									else
										credits = makeValueSmoother(credits:GetValue(), newCredits, 1.25) 
									end
									
								end )

								
function GM:RenderMapToRT(level)
	
	local ply = LocalPlayer()
	
	local dirs = {"n", "w", "u", "d", "e", "s"}
	
	local z = 0
	local x = 0
	local y = 0
	
	local plyPos = GetPlayerMapPos(ply)
	
	if level == "b" then
		z = 1
	end
	
	local blockSizeX = math.floor(mm_cl_globals.miniMapHudTexture:Width() / mm_sh_globals.curX)
	local blockSizeY = math.floor(mm_cl_globals.miniMapHudTexture:Height() / mm_sh_globals.curY)
	
	if blockSizeX > blockSizeY then
		blockSizeX = blockSizeY 
	else
		blockSizeY = blockSizeX 
	end
		
	local render_target = render.GetRenderTarget()

	render.SetRenderTarget(mm_cl_globals.miniMapHudTexture)
	render.OverrideAlphaWriteEnable(true, true)
	
	cam.Start2D()
	
		render.ClearRenderTarget(mm_cl_globals.miniMapHudTexture, Color(0,0,0,0))
		
		render.SetViewPort(0,0, mm_cl_globals.hudRTSize, mm_cl_globals.hudRTSize)
		
		for y = 0, mm_sh_globals.curY - 1 do
			
			for x = 0, mm_sh_globals.curX - 1 do
				
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
		
					surface.SetMaterial(mm_cl_globals.miniMapHudParts.bg)
					
					surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					
					if curBlock.u || curBlock.d then
						surface.SetMaterial(mm_cl_globals.miniMapHudParts.ud)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					end
					
					if !curBlock.n then
						surface.SetMaterial(mm_cl_globals.miniMapHudParts.n)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					end
					
					if !curBlock.s then
						surface.SetMaterial(mm_cl_globals.miniMapHudParts.s)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					end
					
					if !curBlock.e then
						surface.SetMaterial(mm_cl_globals.miniMapHudParts.e)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					end
					
					if !curBlock.w then
						surface.SetMaterial(mm_cl_globals.miniMapHudParts.w)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
					end
					
					if (plyPos.x == x) && (plyPos.y == y) then
						local plyColor = LocalPlayer():GetPlayerColor()
						
						surface.SetDrawColor(255 * plyColor.r, 255 * plyColor.g, 255 * plyColor.b,32)	
						surface.SetMaterial(mm_cl_globals.miniMapHudParts.ply)
						surface.DrawTexturedRect( x * blockSizeX, y * blockSizeY, blockSizeX , blockSizeY )
						
					end
					
				end
				
			end
			
		end
	cam.End2D()
	render.SetRenderTarget(render_target)
	render.SetViewPort(0,0,ScrW(), ScrH())
	render.OverrideAlphaWriteEnable(false)
	mm_cl_globals.miniMapMat:SetTexture("$basetexture", mm_cl_globals.miniMapHudTexture)
		
end

function GM:Initialize()

	BaseClass.Initialize(self)
	
	CleanUpMaze()
	
end

function GM:HUDPaint()
	
	
	BaseClass.HUDPaint(self)
	
	local hDelta = CurTime() - mm_cl_globals.lastHD
	mm_cl_globals.lastHD = CurTime()
	
	surface.SetDrawColor(0,0,0,255)
	
	draw.DrawText( "Time: " .. self.roundEnt:GetFormattedTime(), "DermaLarge", ScrW() * 0.5, 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	if credits then
		draw.DrawText( "Credits: " .. tostring(math.ceil(credits:GetValue())), "DermaLarge", ScrW(), 0, Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT )
	end
	
	surface.SetDrawColor(0,0,0,32)	
	
	surface.SetMaterial(mm_cl_globals.miniMapMat)
	surface.DrawTexturedRect(8, 144, mm_cl_globals.hudRTSize * mm_cl_globals.aspectH, mm_cl_globals.hudRTSize * mm_cl_globals.aspectV)
	
	surface.SetDrawColor(0,0,0,255)	
		
	if #mm_cl_globals.hudQueue > 0 then
		
		if !mm_cl_globals.hudQueue[1].ttd then
			mm_cl_globals.hudQueue[1].ttd = CurTime() + mm_cl_globals.hudQueue[1].ttl 
		end
		
		draw.DrawText( mm_cl_globals.hudQueue[1].message, "DermaLarge", ScrW() * 0.5, ScrH() * 0.2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
		
		if CurTime() > mm_cl_globals.hudQueue[1].ttd ||
		   #mm_cl_globals.hudQueue > 1 then
			
			table.remove(mm_cl_globals.hudQueue, 1)
		
		end
		
	end	
	
	surface.SetMaterial(mm_cl_globals.compassBack)
	surface.DrawTexturedRect(8, 8, 128,128)
	
	surface.SetMaterial(mm_cl_globals.compassPointer)
	surface.DrawTexturedRectRotated(72, 72, 128,128, mm_cl_globals.compassAngle:GetValue())
	
	return true 
	
end

function CleanUpMaze()
	
	if GAMEMODE.roundEnt then
		
		if !mm_cl_globals.inMaze && (GAMEMODE.roundEnt:GetCurrentTitle() != "pre" && 
					   GAMEMODE.roundEnt:GetCurrentTitle() != "in" && 
					   GAMEMODE.roundEnt:GetCurrentTitle() != "ending") then
		
			local csEnts = ents.FindByClass("class C_BaseFlex")
			
			for k,csEnt in pairs(csEnts) do
				
				if !csEnt.noDelete then
					csEnt:Remove()
				end
			
			end
			
			mm_sh_globals.curX = 0
			mm_sh_globals.curY = 0
			
			GAMEMODE.curMaze = {}
			
			mm_cl_globals.updateMiniMap = true
			
		end
	end
	
	timer.Simple(3, CleanUpMaze)
	
end
								
function GM:Think()
	
	BaseClass.Think(self)
	
	local playerYaw = LocalPlayer():GetAngles().y - 90
	local angleDelta = mm_cl_globals.compassAngle.eVal - playerYaw
	
	if self.roundEnt:GetTimeLeft() < 10 && (self.roundEnt:GetCurrentTitle() == "in" || self.roundEnt:GetCurrentTitle() == "ending") then
		
		local curNum = math.ceil(self.roundEnt:GetTimeLeft() - 0.5)
		
		if (CurTime() > mm_cl_globals.canNextSound) && curNum != mm_cl_globals.lastNum then
			
			surface.PlaySound(mm_sh_globals.countDownSounds[curNum])
			
			mm_cl_globals.canNextSound = CurTime() + SoundDuration(mm_sh_globals.countDownSounds[curNum])
			
			mm_cl_globals.lastNum = curNum
			
		end
	
	end
	
	if angleDelta < -359 then
		mm_cl_globals.compassAngle.sVal = playerYaw
		mm_cl_globals.compassAngle.eVal = -mm_cl_globals.compassAngle:GetValue()
		
	elseif angleDelta > 359 then
		mm_cl_globals.compassAngle.sVal = playerYaw
		mm_cl_globals.compassAngle.eVal = -mm_cl_globals.compassAngle:GetValue()
	else
		mm_cl_globals.compassAngle.sVal = mm_cl_globals.compassAngle:GetValue()
		mm_cl_globals.compassAngle.eVal = playerYaw
	end
	
	mm_cl_globals.compassAngle.aTime = (1 / math.abs(mm_cl_globals.compassAngle.sVal - mm_cl_globals.compassAngle.eVal)) * 2
	
	mm_cl_globals.compassAngle.startTime = CurTime() 
	if !credits then
		net.Start("request_credit_info")
		net.SendToServer()
	end
	
	if mm_cl_globals.mapSize == Vector(0,0,0) then
	
		net.Start("req_world_size")
		net.SendToServer()
		
	end
	
	if mm_cl_globals.mazeZero == Vector(0,0,0) then
		
		net.Start("req_maze_zero")
		net.SendToServer()
	
	end
	
	if mm_sh_globals.curX == 0 || mm_sh_globals.curY == 0 then
		
		net.Start("req_maze_size")
		net.SendToServer()
		
	end
	
	local curPlyMapPos = GetPlayerMapPos(LocalPlayer())
	
	if curPlyMapPos != mm_cl_globals.lastPlyMapPos then
		net.Start("req_room_from_server")
			net.WriteVector(curPlyMapPos)
		net.SendToServer()
		mm_cl_globals.lastPlyMapPos = curPlyMapPos
		
	end
end
		

hook.Add( "RenderScene", "renderScene_m", function( ViewOrigin, ViewAngles, ViewFOV )
	
	renderScene( ViewOrigin, ViewAngles )
	
	if mm_cl_globals.updateMiniMap then
		local plyMapPos = GetPlayerMapPos(LocalPlayer())
		local levelChar = "t"
		
		if plyMapPos.z == 1 then
			levelChar = "b"
		end
		
		GAMEMODE.miniMapSize = GAMEMODE:RenderMapToRT(levelChar)
		mm_cl_globals.updateMiniMap = false
		
	end 


end )

function renderScene(origin, angles)
	
	if mm_cl_globals.in_render then return end
	
	if (!mm_cl_globals.exitCamPos || !mm_cl_globals.exitEnt) ||
	   (!IsValid(mm_cl_globals.exitEnt)) then 
	
	   if !mm_cl_globals.exitCamPos then
			net.Start("request_exit_cam")
			net.SendToServer()
	   end
	   
	   return
	end
	
	mm_cl_globals.in_render = true
	local doorNormal = -mm_cl_globals.exitEnt:GetForward()

	local doorDist = doorNormal:Dot(mm_cl_globals.exitCamPos)

	local exitNormal = mm_cl_globals.exitCamPos:Angle():Forward()

	local exitDist = exitNormal:Dot(mm_cl_globals.exitEnt:GetPos())
			
	local fwd = angles:Forward()

	local up = angles:Up()

	local dot = origin:DotProduct( doorNormal ) - doorDist
	origin = origin + ( -2 * dot ) * doorNormal

	local dot = fwd:DotProduct( doorNormal)
	fwd = fwd + (-2 * dot) * doorNormal

	local dot = up:DotProduct( doorNormal)
	up = up + (-2 * dot) * doorNormal

	angles = up:Cross( fwd ):Angle() + Angle(0,-90,0)

	local lOrigin = mm_cl_globals.exitEnt:WorldToLocal(origin)
	local lAngles = mm_cl_globals.exitEnt:WorldToLocalAngles( angles )

	lOrigin.y = -lOrigin.y
	lAngles.y = -lAngles.y
	lAngles.r = -lAngles.r

	local view = {}

	view.x = 0
	view.y = 0
	view.w = ScrW()
	view.h = ScrH()

	view.origin = mm_cl_globals.exitCamPos + Vector(0,0,0)
	view.angles = everythingServesTheBeam:LocalToWorldAngles(lAngles) 
	
	view.fov = 106

	local render_target = render.GetRenderTarget()

	render.SetRenderTarget(mm_cl_globals.camTex)

				mm_cl_globals.exitEnt:SetNoDraw(true)
				cam.Start2D()
					
					render.RenderView(view)
					
				cam.End2D()
				mm_cl_globals.exitEnt:SetNoDraw(false)
						
	render.SetRenderTarget(render_target)

	mm_cl_globals.exitMat:SetTexture("$basetexture", mm_cl_globals.camTex)
	
	mm_cl_globals.in_render = false
	
end

local matColor = Material("color")

function GM:PreDrawOpaqueRenderables()
	
	if mm_cl_globals.drawBoxes then
		if #mm_cl_globals.drawBoxes > 0 then
			
			for i = 1, #mm_cl_globals.drawBoxes do
				
				
				local curBox = mm_cl_globals.drawBoxes[i]
				
				if curBox == nil then continue end
				
				if curBox.dieTime == nil then
					curBox.dieTime = CurTime() + curBox.ttl 
				end
				
				render.SetColorMaterial()
				
				render.DrawWireframeBox( curBox.pos, Angle(0,0,0), curBox.min, curBox.max, Color(255,255,0,196), false )
			
				
				
				if CurTime() >= curBox.dieTime then
					table.remove(mm_cl_globals.drawBoxes, i)
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
		
		if mm_cl_globals.inMaze && IsValid(plyBlock) then
			
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
	
	local plyMapPos = GetPlayerMapPos(ply)
	
	local blockPos = GetBlockWorldPos(plyMapPos) * Vector(1,1,1)
	
	local blockList = ents.FindInBox( blockPos - (mm_sh_globals.blockSizes * 0.5), blockPos + (mm_sh_globals.blockSizes * 0.5) ) 
	local blockEnt = nil
	local cDist = 640000
	
	for k, ent in pairs(blockList) do
		
		if ent:GetClass() == "maze_block" then
			
			local bDist = (LocalPlayer():GetPos() - ent:GetPos()):Length()
			
			if bDist < cDist then
				blockEnt = ent
				cDist = bDist
			end
			
		end
		
	end
		
	return blockEnt
	
end

function GM:InitPostEntity() 
	
	BaseClass.InitPostEntity(self)
	
	everythingServesTheBeam = ents.FindByClass( "beam" )[1]

end

function openStore(len, ply)
	
	if mm_cl_globals.storeIsOpen then
		mm_cl_globals.storeMenu:Remove()
		return
	end
	
	gui.EnableScreenClicker( true )
	
	mm_cl_globals.storeIsOpen = true
	
	mm_cl_globals.storeMenu = vgui.Create('DFrame')
	mm_cl_globals.storeMenu:SetSize(ScrW() * 0.5, ScrH() * 0.5)
	mm_cl_globals.storeMenu:Center()
	mm_cl_globals.storeMenu:SetTitle('Murder Maze - Store')
	mm_cl_globals.storeMenu:SetDeleteOnClose(true)

	mm_cl_globals.storeMenu.OnRemove = function(self) 
							mm_cl_globals.storeIsOpen = false
							gui.EnableScreenClicker(false) 
						end

	-- Store Icons
	local titleOffset = 24
	local maxCols = 4
	local rowPad = 8
	local rowCount = 0
	local colPad = 8
	local colCount = 0
	
	local spawnIconWidth = (mm_cl_globals.storeMenu:GetWide() / maxCols) - rowPad
	local spawnIconHeight = spawnIconWidth
	
	local lblTemp = vgui.Create("DLabel")
		  lblTemp:SetFont("DermaDefaultBold")
		  lblTemp:SetText("W")
	
	local lblHeight = lblTemp:GetTall()
	
	lblTemp:Remove()
	
	local longest = 0
	local widest = 0
	
	for itemNumber, item in pairs(mm_sh_globals.items) do
		
		if item.class == "internal" then continue end
		
		if string.len(item.title) > longest then
			longest = string.len(item.title)
		end
		
		local toolTip = item.title .. " \n " .. "Cost: " .. tostring(item.cost) .. " Quantity: " .. tostring(item.quantity)
		
		local spiBack = vgui.Create("DPanel")
			  spiBack:SetParent(mm_cl_globals.storeMenu)
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
		
		colCount = colCount + 1
		if colCount == maxCols then
			colCount = 0
			rowCount = rowCount +1
		end
		
	end	
	

	mm_cl_globals.storeMenu:SizeToChildren(true,true)
	mm_cl_globals.storeMenu:InvalidateLayout(false)
	
	mm_cl_globals.storeMenu:SetSize(mm_cl_globals.storeMenu:GetWide() + (colPad * 0.5), mm_cl_globals.storeMenu:GetTall() + (rowPad * 0.5))
	
	mm_cl_globals.storeMenu:SetVerticalScrollbarEnabled(true)
	
end
net.Receive("open_store", openStore)

function openHelp(len, ply)
	
end
net.Receive("open_help", openHelp)




function openPlayer(len, ply)
	
	if mm_cl_globals.playerIsOpen then
		mm_cl_globals.playerMenu:Remove()
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
	
	mm_cl_globals.playerIsOpen = true
	
	mm_cl_globals.playerMenu = vgui.Create("DFrame")
	mm_cl_globals.playerMenu:SetSize(ScrW() * 0.5, ScrH() * 0.5)
	mm_cl_globals.playerMenu:Center()
	mm_cl_globals.playerMenu:SetTitle("Murder Maze - Player Options/Info")
	mm_cl_globals.playerMenu:SetDeleteOnClose(true)
	local pmPos = {}

	mm_cl_globals.playerMenu.OnRemove = function(self) 
							mm_cl_globals.playerIsOpen = false
							gui.EnableScreenClicker(false) 
						end
	
	
	
	local lblPlyClr = vgui.Create("DLabel")
		  lblPlyClr:SetPos(colPad * 1.5, titleOffset + 2)
		  lblPlyClr:SetText("Player Color")
		  lblPlyClr:SetParent(mm_cl_globals.playerMenu)
	
	
	totalHorizontalOffset = totalHorizontalOffset +  lblPlyClr:GetWide()
	
	local clrPick = vgui.Create("DRGBPicker")
		  clrPick:SetParent(mm_cl_globals.playerMenu)
		  clrPick:SetSize((lblPlyClr:GetWide() * 0.9),128)
		  clrPick:SetPos(colPad + (lblPlyClr:GetWide() * 0.5) - (clrPick:GetWide() * 0.5), titleOffset + lblPlyClr:GetTall())
		  clrPick.OnChange = function ( self, color )
								net.Start("set_player_color")
									net.WriteVector( Vector(color.r / 255, color.g / 255, color.b / 255) )
								net.SendToServer()
								end
								
	
	local lblPlyMdl = vgui.Create("DLabel")
		  lblPlyMdl:SetPos((colPad * 2) + lblPlyClr:GetWide(), titleOffset + 2)
		  lblPlyMdl:SetText("Player Model")
		  lblPlyMdl:SetParent(mm_cl_globals.playerMenu)

	
	local spawnIconWidth = (((mm_cl_globals.playerMenu:GetWide() - totalHorizontalOffset) * 0.5) / maxCols) - rowPad
	local spawnIconHeight = spawnIconWidth
	
	for k, plyModel in pairs(mm_sh_globals.males) do
			
		local toolTip = "Male"
		
		local spiBack = vgui.Create("DPanel")
			  spiBack:SetParent(mm_cl_globals.playerMenu)
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
	
	for k, plyModel in pairs(mm_sh_globals.females) do
			
		local toolTip = "Female"
		
		local spiBack = vgui.Create("DPanel")
			  spiBack:SetParent(mm_cl_globals.playerMenu)
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
	plyPanel:SetParent(mm_cl_globals.playerMenu)
	plyPanel:SetModel(LocalPlayer():GetModel())
	function plyPanel:LayoutEntity( ent ) ent:SetAngles(Angle(0,45,0)) return end
	function plyPanel.Entity:GetPlayerColor() return LocalPlayer():GetPlayerColor() end
	plyPanel:SetCamPos(Vector(15, 25, 64))
	plyPanel:SetLookAt(Vector(0, 0, 48) )
	plyPanel:SetFOV(45)
	plyPanel.Entity.noDelete = true
				
			
	mm_cl_globals.playerMenu:SizeToChildren(true,true)
	mm_cl_globals.playerMenu:SetSize(mm_cl_globals.playerMenu:GetWide() + colPad, mm_cl_globals.playerMenu:GetTall() + rowPad)
	
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
	
	if (mm_cl_globals.playerIsOpen) then
		
		view.origin = plyHead + (ply:GetForward() * Vector(100,100,0)) 
		view.angles = ((plyHead + ply:GetRight() * -50) - view.origin):Angle()
		view.fov = fov
		view.drawviewer = true

	end
			
end

function GM:ScoreboardShow()
	
	net.Start("req_scores")
	net.SendToServer()
	
	mm_cl_globals.scores = {}
	
	timer.Simple(0.1, doScoreboard)
	--return false	

end

function doScoreboard()
		
	if LocalPlayer():KeyDown(IN_SCORE) && #mm_cl_globals.scores > 0 then
		
		if !mm_cl_globals.scoreMenu then
		
			mm_cl_globals.scoreMenu = vgui.Create("DPanel")
			mm_cl_globals.scoreMenu:SetSize(ScrW() * 0.5, ScrH() * 0.666)
		
			function mm_cl_globals.scoreMenu:Paint()
				
				draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), Color(64,64,64,128))
			
			end
			
			local ySpace = 24
			local yPad = 8
			local xPad = 40
			
			local x = xPad
			local y = yPad + 16
			
			local nickCol = 256
			local runCol = 160
			local compCol = 160
			local incompCol = 160
			local creditCol = 160
			
			local scoresFont = "Trebuchet24"
			
			local plyNick = vgui.Create("DLabel")
				  plyNick:SetParent(mm_cl_globals.scoreMenu)
				  plyNick:SetFont(scoresFont)
				  plyNick:SetSize(nickCol, ySpace * 2)
				  plyNick:SetPos(x,y)
				  plyNick:SetText(makeLen("\nPlayer", 30, " ", false))
				  plyNick:SetTextColor(Color(255,255,255,255))
				  
				  
			local lX,lY = plyNick:GetPos()
			
			x = x + plyNick:GetWide() + xPad
			
			local plyRan = vgui.Create("DLabel")
				  plyRan:SetParent(mm_cl_globals.scoreMenu)
				  plyRan:SetFont(scoresFont)
				  plyRan:SetSize(runCol, ySpace * 2)
				  plyRan:SetPos(x,y)
				  plyRan:SetText(makeLen("Total\nRuns", 5, " ", false))
				  plyRan:SetTextColor(Color(255,255,255,255))
				  lX,lY = plyRan:GetPos()
				  
			x = x + plyRan:GetWide() + xPad
				  
			local plyComp = vgui.Create("DLabel")
				  plyComp:SetParent(mm_cl_globals.scoreMenu)
				  plyComp:SetFont(scoresFont)
				  plyComp:SetSize(compCol, ySpace * 2)
				  plyComp:SetPos(x,y)
				  plyComp:SetText(makeLen("Completed\nRuns", 5, " ", false))
				  plyComp:SetTextColor(Color(0,255,0,255))
				  lX,lY = plyComp:GetPos()

			x = x + plyComp:GetWide() + xPad
			
			local plyIncomp = vgui.Create("DLabel")
				  plyIncomp:SetParent(mm_cl_globals.scoreMenu)
				  plyIncomp:SetFont(scoresFont)
				  plyIncomp:SetSize(incompCol, ySpace * 2)
				  plyIncomp:SetPos(x,y)
				  plyIncomp:SetText(makeLen("Incomplete\nRuns", 5, " ", false))
				  plyIncomp:SetTextColor(Color(255,0,0,255))
				  lX,lY = plyIncomp:GetPos()
			
			x = x + plyIncomp:GetWide() + xPad
			
			local plyCredit = vgui.Create("DLabel")
				  plyCredit:SetParent(mm_cl_globals.scoreMenu)
				  plyCredit:SetFont(scoresFont)
				  plyCredit:SetSize(creditCol, ySpace * 2)
				  plyCredit:SetPos(x,y)
				  plyCredit:SetText(makeLen("Credits", 5, " ", false))
				  plyCredit:SetTextColor(Color(255,255,0,255))
				  
				  lX,lY = plyNick:GetPos()
				  
			y = y + yPad + (ySpace * 2)
			x = xPad
			
			local divider = vgui.Create("DShape")
				  divider:SetType("Rect")
				  divider:SetParent(mm_cl_globals.scoreMenu)
				  divider:SetPos(x,y)
				  divider:SetColor(Color(160,160,160,196))
			
			y = y + (yPad * 2)
			
			for k, score in pairs(mm_cl_globals.scores) do
				plyNick = vgui.Create("DLabel")
				plyNick:SetParent(mm_cl_globals.scoreMenu)
				plyNick:SetFont(scoresFont)
				plyNick:SetSize(nickCol, ySpace)
				plyNick:SetPos(x,y)
				plyNick:SetText(makeLen(score.nick, 30, " ", false))
				plyNick:SetTextColor(Color(255,255,255,224))
					  
				lX,lY = plyNick:GetPos()
				
				x = x + plyNick:GetWide() + xPad
				
				plyRan = vgui.Create("DLabel")
				plyRan:SetParent(mm_cl_globals.scoreMenu)
				plyRan:SetFont(scoresFont)
				plyRan:SetSize(runCol, ySpace)
				plyRan:SetPos(x,y)
				plyRan:SetText(makeLen(score.mazeStats.x, 5, " ", false))
				plyRan:SetTextColor(Color(255,255,255,224))
				lX,lY = plyRan:GetPos()
					  
				x = x + plyRan:GetWide() + xPad
					  
				plyComp = vgui.Create("DLabel")
				plyComp:SetParent(mm_cl_globals.scoreMenu)
				plyComp:SetFont(scoresFont)
				plyComp:SetSize(compCol, ySpace)
				plyComp:SetPos(x,y)
				plyComp:SetText(makeLen(score.mazeStats.y, 5, " ", false))
				plyComp:SetTextColor(Color(0,255,0,224))
				lX,lY = plyComp:GetPos()

				x = x + plyComp:GetWide() + xPad
				
				plyIncomp = vgui.Create("DLabel")
				plyIncomp:SetParent(mm_cl_globals.scoreMenu)
				plyIncomp:SetFont(scoresFont)
				plyIncomp:SetSize(incompCol, ySpace)
				plyIncomp:SetPos(x,y)
				plyIncomp:SetText(makeLen(score.mazeStats.z, 5, " ", false))
				plyIncomp:SetTextColor(Color(255,0,0,224))
				lX,lY = plyIncomp:GetPos()
				
				x = x + plyIncomp:GetWide() + xPad
				
				plyCredit = vgui.Create("DLabel")
				plyCredit:SetParent(mm_cl_globals.scoreMenu)
				plyCredit:SetFont(scoresFont)
				plyCredit:SetSize(creditCol, ySpace)
				plyCredit:SetPos(x,y)
				plyCredit:SetText(makeLen(score.credits, 5, " ", false))
				plyCredit:SetTextColor(Color(255,255,0,224))
				lX,lY = plyNick:GetPos()
					  
				y = y + yPad + ySpace
				x = xPad
			end
			
			mm_cl_globals.scoreMenu:SizeToChildren(true,true)
			
			mm_cl_globals.scoreMenu:SetSize(mm_cl_globals.scoreMenu:GetWide() + xPad, mm_cl_globals.scoreMenu:GetTall() + yPad)
			
			mm_cl_globals.scoreMenu:SetPos(ScrW() * 0.5 - (mm_cl_globals.scoreMenu:GetWide() * 0.5),
										   ScrH() * 0.5 - (mm_cl_globals.scoreMenu:GetTall() * 0.5))
			
			--scoreMenu:SetPaintBackground(false)
			divider:SetSize(mm_cl_globals.scoreMenu:GetWide() - (xPad * 2), yPad * 0.5)
			
		end
		
	else
		
		if mm_cl_globals.scoreMenu then
			if mm_cl_globals.scoreMenu.Close then
				mm_cl_globals.scoreMenu:Close()
			elseif mm_cl_globals.scoreMenu.Remove then
				mm_cl_globals.scoreMenu:Remove()
			end
			mm_cl_globals.scoreMenu = nil
			return
		end
		
	end

	timer.Simple(0.1, doScoreboard)
	
end