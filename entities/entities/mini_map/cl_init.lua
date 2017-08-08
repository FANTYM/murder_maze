include( "shared.lua" )

function ENT:Initialize()
	
	-- Angles for compass directions, used for drawing doors
	self.dirAngles = {}
	self.dirAngles.n = Angle(   0,   90,   0)
	self.dirAngles.e = Angle(   0,    0,   0)
	self.dirAngles.s = Angle(   0,  270,   0)
	self.dirAngles.w = Angle(   0,  180,   0)
	
	-- Map Materials 
	self.plyMat = Material("particle/particle_glow_04") -- Sprite for players
	self.mapMat = Material("mm/mini_map") -- Map material
	self.mapMatWire = Material("models/wireframe") -- Wireframe Map material
	self.mapMatBeam = Material("cable/blue_elec") -- Map "render" beams 

	self:SetRenderBounds( Vector(-10240, -10240, -10240), Vector(10240, 10240, 10240))
	
	-- Entities to render and the render offset
	self.renderEnts = {}
	self.drawOffset = Vector(0,0,0)
	
	-- Map's current scale, and map's full scale
	self.mapScale = 0
	self.mapFullScale = 0.0625
	
	-- Map drawing variables
	self.beamSectionStart = 0
	self.beamSectionEnd = 1
	self.beamWidth = 8
	self.mapMin = Vector(0,0,0)
	self.mapMax = Vector(0,0,0)
	self.corners = {}
	for i = 0, 7 do
		self.corners[i] = Vector(0,0,0)
	end
	self.scanDir = -1
	self.scanPerc = 1
	self.invPerc = 0
	
	-- Timing Variables
	self.deployTime = 2
	self.closeTime = 2
	self.lastThink = CurTime()
	self.timeMarker = CurTime()
	self.thinkDelta = 0
	
	-- Open/Close tracking variable
	self.mapIsOpen = false
	
end

-- It's a holographics(kinda) map, so draw translucent
function ENT:DrawTranslucent()

	-- Draw origin sphere
	render.SetMaterial(self.mapMat)
	render.DrawSphere( self:GetPos(), 1.5, 9, 9, Vector(255,255,255, 255) )
	render.DrawWireframeSphere( self:GetPos(), 1.6, 8, 8, Vector(255, 0,0, 128), true )
	
	-- Check if we are close enough to see this
	local entDist = (LocalPlayer():GetPos() - self:GetPos()):Length()
	if ( entDist > 1584) then return end
	
	-- If the maze is open and local player is not in the maze, draw the map
	if !mmGlobals.inMaze && self.mapIsOpen then
		
		-- Reset map min/max, this is for the beams
		self.mapMin = Vector(0,0,0)
		self.mapMax = Vector(0,0,0)
		
		-- Suppress lighting, we don't want lights to hit the holographics
		render.SuppressEngineLighting(true)

		-- itterate over render table
		for k,rEnt in pairs(self.renderEnts) do
			
			-- if the ent is valid render it
			if rEnt && IsValid(rEnt) then
					
				-- calculate offset and position to render
				local rendOffset = (rEnt:GetPos() - self.drawOffset)
				local rendPos = self:GetPos() + (rendOffset * self.mapScale)
				
				-- Track min / max
				if rendPos.x < self.mapMin.x then self.mapMin.x = rendPos.x end
				if rendPos.y < self.mapMin.y then self.mapMin.y = rendPos.y end
				if rendPos.x < self.mapMin.z then self.mapMin.z = rendPos.z end
				
				if rendPos.x > self.mapMax.x then self.mapMax.x = rendPos.x end
				if rendPos.y > self.mapMax.y then self.mapMax.y = rendPos.y end
				if rendPos.x > self.mapMax.z then self.mapMax.z = rendPos.z end
				
				-- If we have a model of this entity then draw it
				if rEnt.csModel && IsValid(rEnt.csModel) then
					
					local cM = rEnt.csModel
					
					-- Setup matrix to move/scale the model
					local mat = Matrix()
						  mat:Scale( Vector( self.mapScale, self.mapScale, self.mapScale ) )
						  mat:SetTranslation(rendPos)
					
					-- Color the exit door green
					if rEnt:GetClass() == "maze_door" then
						mat:Rotate(self.dirAngles[rEnt:GetDirection()])
						if rEnt:GetIsExit() then
							render.SetColorModulation(0,1,0)
						end
					end
					
					-- Calculate clip plane info
					local sideOne = self.corners[6] - self.corners[5]
					local sideTwo = self.corners[5] - self.corners[4]
					local plane = sideOne:Cross(sideTwo) + (Vector(0,0,1) * self.corners[4])
					
					local clipNormal = -plane:GetNormal()
					
					-- This is to fix a weird error where cM goes nil right before the draw
					if !cM || !IsValid(cM) then end
					
					-- Draw entity using the mapMat, the matrix and the clip plane
					cM:EnableMatrix("RenderMultiply", mat)
					
					local oldClip = render.EnableClipping(true)
					
						render.PushCustomClipPlane(clipNormal, clipNormal:Dot(Vector(0,0,0) + self:GetPos() + (Vector(0,0, 1) * (self.corners[4] - self:GetPos()))))
							
							render.MaterialOverride(self.mapMat)
								cM:DrawModel()
							render.MaterialOverride()
							
						render.PopCustomClipPlane()
						
					render.EnableClipping(oldClip)
					
					-- Calculate second clip plane, opposite of the first and offset a bit
					plane = sideOne:Cross(sideTwo) + (Vector(0,0,-1) * self.corners[4]) -- was 0 not 4
					
					clipNormal = -plane:GetNormal()
					
					-- Draw entity again with mapMatWire, the same matrix, the new clip plane
					oldClip = render.EnableClipping(true)
						
						render.PushCustomClipPlane(clipNormal, clipNormal:Dot(Vector(0,0,2) + self:GetPos() + (Vector(0,0, 1) * (self.corners[4] - self:GetPos()))))
							
							render.MaterialOverride(self.mapMatWire)
								cM:DrawModel()
							render.MaterialOverride()
							
						render.PopCustomClipPlane()
						
					render.EnableClipping(oldClip)
					
					cM:DisableMatrix("RenderMultiply")
					
				else
					rEnt:makeCSModel()
				end
				
				-- reset color modulation, in case we drew the door
				render.SetColorModulation(1,1,1)
				
			end
		
		end
		
		-- Draw beams
		-- Origin to bottom set of corners
		render.SetMaterial(self.mapMatBeam)
		render.DrawBeam(self:GetPos(), 
						self.corners[0],
						self.beamWidth, self.beamSectionStart * 2.5, self.beamSectionEnd * 2.5, Color(0,0,128,128))					
		render.DrawBeam(self:GetPos(), 
						self.corners[1],
						self.beamWidth, self.beamSectionStart * 2.5, self.beamSectionEnd * 2.5, Color(0,0,128,128))						
		render.DrawBeam(self:GetPos(), 
						self.corners[2],
						self.beamWidth, self.beamSectionStart * 2.5, self.beamSectionEnd * 2.5, Color(0,0,128,128))						
		render.DrawBeam(self:GetPos(), 
						self.corners[3],
						self.beamWidth, self.beamSectionStart * 2.5, self.beamSectionEnd * 2.5, Color(0,0,128,128))
		
		-- Draw the bottom square
		render.DrawBeam(self.corners[0], 
						self.corners[1],
						self.beamWidth, self.beamSectionStart * 2, self.beamSectionEnd * 2, Color(0,0,128,128))					
		render.DrawBeam(self.corners[1], 
						self.corners[2],
						self.beamWidth, self.beamSectionStart * 2, self.beamSectionEnd * 2, Color(0,0,128,128))						
		render.DrawBeam(self.corners[2], 
						self.corners[3],
						self.beamWidth, self.beamSectionStart * 2, self.beamSectionEnd * 2, Color(0,0,128,128))						
		render.DrawBeam(self.corners[3], 
						self.corners[0],
						self.beamWidth, self.beamSectionStart * 2, self.beamSectionEnd * 2, Color(0,0,128,128))
	
		-- Draw connection to the top
		render.DrawBeam(self.corners[0], 
						self.corners[4],
						self.beamWidth, self.beamSectionStart,self.beamSectionEnd, Color(0,0,128,128))					
		render.DrawBeam(self.corners[1], 
						self.corners[5],
						self.beamWidth, self.beamSectionStart,self.beamSectionEnd, Color(0,0,128,128))						
		render.DrawBeam(self.corners[2], 
						self.corners[6],
						self.beamWidth, self.beamSectionStart,self.beamSectionEnd, Color(0,0,128,128))						
		render.DrawBeam(self.corners[3], 
						self.corners[7],
						self.beamWidth, self.beamSectionStart,self.beamSectionEnd, Color(0,0,128,128))
						
		-- Draw the top square
		render.DrawBeam(self.corners[4], 
						self.corners[5],
						self.beamWidth, self.beamSectionStart * 2, self.beamSectionEnd * 2, Color(0,0,128,128))					
		render.DrawBeam(self.corners[5], 
						self.corners[6],
						self.beamWidth, self.beamSectionStart * 2, self.beamSectionEnd * 2, Color(0,0,128,128))						
		render.DrawBeam(self.corners[6], 
						self.corners[7],
						self.beamWidth, self.beamSectionStart * 2, self.beamSectionEnd * 2, Color(0,0,128,128))						
		render.DrawBeam(self.corners[7], 
						self.corners[4],
						self.beamWidth, self.beamSectionStart * 2, self.beamSectionEnd * 2, Color(0,0,128,128))

		-- Draw plyMat (sprite) for each player in the map, in their color
		render.SetMaterial(self.plyMat)
		for k, ply in pairs(player.GetAll()) do
			if IsInMaze(getMapPos(ply:GetPos() + Vector(0,0,64))) then
				
				local plyClr = ply:GetPlayerColor()
				render.DrawSprite( self:GetPos() + (((ply:GetPos() - self.drawOffset ) + Vector(0,0,48)) * self.mapScale), 120 * self.mapScale, 120 * self.mapScale, Color(plyClr.r * 255, plyClr.g * 255, plyClr.b * 255, 255) )
				
			end
		end
		
		render.SuppressEngineLighting(false)
		
	end

end

-- Entity think, gather information to use in the DrawTranslucent function
function ENT:Think()
	
	--Assign self to GAMEMODE table for global access to the miniMap entity
	GAMEMODE.mapEnt = self
	
	-- Fixes a bug where even though I set self.lastThink in initalize it goes nil
	if !self.lastThink then
		self.lastThink = CurTime() - math.random()
	end
	
	-- Calculate think delta
	self.thinkDelta = CurTime() - self.lastThink
	self.lastThink = CurTime()
	
	-- If round entity isn't know then exit, we'll try again later
	if !mmGlobals.roundEntity then return end
	
	-- if local player is not in the maze and we are in round "in" or "ending", continue gather maze info
	if !mmGlobals.inMaze && ((mmGlobals.roundEntity:GetCurrentTitle() == "in") || (mmGlobals.roundEntity:GetCurrentTitle() == "ending")) then
			
		-- Gather maze_block and maze_door entities, assign them as render ents
		local tempEnts = ents.FindByClass("maze_block")
		table.Add(tempEnts, ents.FindByClass("maze_door"))
		self.renderEnts = tempEnts
		
		-- Open and Close map depending on round time and if map is open or close
		if self.mapIsOpen && (mmGlobals.roundEntity:GetTimeLeft()) <= (self.closeTime * 1.25) then
			--print("Closing map...")
				self.scanDir = 1
				self.timeMarker = CurTime()
				self.mapIsOpen = false
			--print("time's almost up, closing map...")
		end
		
		if !self.mapIsOpen && (mmGlobals.roundEntity:GetTimeLeft()) > (self.closeTime * 1.25) then
			
			--print("Opening map...")
			self.scanDir = -1
			self.timeMarker = CurTime()
			self.scanPerc = 1
			self.mapIsOpen = true
			
		end
		
		-- Calculate open/close percentage if delta is > 0
		local sPercDelta = (CurTime() - self.timeMarker)
		if sPercDelta != 0 then
		
			if self.mapIsOpen then
			
				self.scanPerc = 1 - ( sPercDelta / self.deployTime)
				
			else
			
				self.scanPerc = ( sPercDelta / self.closeTime)
				
			end
			
			self.scanPerc = math.max(0, math.min(self.scanPerc, 1))		
			self.invPerc = 1 - self.scanPerc
			self.mapScale = self.mapFullScale * self.invPerc
			
		end
		
		-- Calculate square corners from min/max
		-- Bottom
		self.corners[0] = Vector(0,0,0.5) + self.mapMin + (Vector(mmGlobals.blockSizes.x * -0.5, mmGlobals.blockSizes.y * 0.5, mmGlobals.blockSizes.z * (-1 * self.scanPerc) ) * self.mapScale)
		self.corners[1] = Vector(self.mapMin.x, self.mapMax.y, self.mapMin.z + 0.5) + (Vector(mmGlobals.blockSizes.x * -0.5, mmGlobals.blockSizes.y * -0.5, mmGlobals.blockSizes.z * (-1 * self.scanPerc) ) * self.mapScale)
		self.corners[2] = Vector(self.mapMax.x, self.mapMax.y, self.mapMin.z + 0.5) + (Vector(mmGlobals.blockSizes.x * 0.5, mmGlobals.blockSizes.y * -0.5, mmGlobals.blockSizes.z * (-1 * self.scanPerc)  ) * self.mapScale)
		self.corners[3] = Vector(self.mapMax.x, self.mapMin.y, self.mapMin.z + 0.5) + (Vector(mmGlobals.blockSizes.x * 0.5, mmGlobals.blockSizes.y * 0.5, mmGlobals.blockSizes.z * (-1 * self.scanPerc)  ) * self.mapScale)
		
		--Top
		self.corners[4] = self.mapMin + (Vector(mmGlobals.blockSizes.x * -0.5, mmGlobals.blockSizes.y * 0.5, (mmGlobals.blockSizes.z * self.invPerc) + mmGlobals.blockSizes.z * (-1 * self.scanPerc) ) * self.mapScale)
		self.corners[5] = Vector(self.mapMin.x, self.mapMax.y, self.mapMin.z) + (Vector(mmGlobals.blockSizes.x * -0.5, mmGlobals.blockSizes.y * -0.5, (mmGlobals.blockSizes.z * self.invPerc) + mmGlobals.blockSizes.z * (-1 * self.scanPerc) ) * self.mapScale)
		self.corners[6] = Vector(self.mapMax.x, self.mapMax.y, self.mapMin.z) + (Vector(mmGlobals.blockSizes.x * 0.5, mmGlobals.blockSizes.y * -0.5, (mmGlobals.blockSizes.z * self.invPerc) + mmGlobals.blockSizes.z * (-1 * self.scanPerc)  ) * self.mapScale)
		self.corners[7] = Vector(self.mapMax.x, self.mapMin.y, self.mapMin.z) + (Vector(mmGlobals.blockSizes.x * 0.5, mmGlobals.blockSizes.y * 0.5, (mmGlobals.blockSizes.z * self.invPerc) + mmGlobals.blockSizes.z * (-1 * self.scanPerc)  ) * self.mapScale)
		
		-- Calculate offset from maze that is relative to final offset of miniMap
		self.drawOffset = mmGlobals.mazeZero + (Vector( ((mmGlobals.mazeCurSize.x - 1) * mmGlobals.blockSizes.x) * 0.5, 
											  ((mmGlobals.mazeCurSize.y - 1) * mmGlobals.blockSizes.y) * 0.5,
											    mmGlobals.blockSizes.z * -1.89 ))
		
		-- Run beam section vairiables to animate the beams
		self.beamSectionStart = self.beamSectionStart - ((2 * self.invPerc) * self.thinkDelta)
		self.beamSectionEnd = self.beamSectionEnd - ((2 * self.invPerc) * self.thinkDelta)
		
		if self.beamSectionStart < -1 then
		
			self.beamSectionStart = 1
			
		end
		
		if self.beamSectionEnd < 0 then
		
			self.beamSectionEnd = 2
			
		end
	
	end
	
end