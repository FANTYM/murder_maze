AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()
	
	self.doors = {}
	
	self.doors.t = {}
	
	self.doors.b = {}
	
end

function ENT:SetType(newType)
	
	if newType == "b" then
		self:SetModel("models/mm/maze_block.mdl")
	else 
		self:SetModel("models/mm/maze_block_ud.mdl")
	end
	
	self:SetBlockType(newType)
	
	self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysicsInitShadow(false, false)
	self:SetCollisionGroup( COLLISION_GROUP_NONE )
	self:SetCustomCollisionCheck(true)
	
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end

function ENT:PhysicsSimulate( phys, deltatime )

	
	return 0, 0, SIM_NOTHING

end

function ENT:CloseAllDoors()

	local levels = {"t", "b"}
	local dirs = {"n", "s", "e", "w"}
	
	for kL, l in pairs(levels) do
		
		for kD, d in pairs(dirs) do
			
			self:SetDoor(l,d,true)
			
		end
		
	end

end

function ENT:OpenAllDoors()

	local levels = {"t", "b"}
	local dirs = {"n", "s", "e", "w"}
	
	for kL, l in pairs(levels) do
		
		for kD, d in pairs(dirs) do
			
			self:SetDoor(l,d,false)
			
		end
		
	end

end

function ENT:SetDoor(doorLevel, doorDir, hasDoor)

	local curDoor = self.doors[doorLevel][doorDir]
	
	local dirAngles = {}
		  dirAngles.n = Angle(   0,   90,   0)
		  dirAngles.e = Angle(   0,    0,   0)
		  dirAngles.s = Angle(   0,  270,   0)
		  dirAngles.w = Angle(   0,  180,   0)
		  
	
	if curDoor && hasDoor then 
		return 
	end
	
	if !curDoor && !hasDoor then
		return 
	end
	
	if curDoor && !hasDoor then
		
		curDoor:Remove()
		self.doors[doorLevel][doorDir] = nil
		return
		
	end
	
	if !curDoor && hasDoor then
		
		local newDoor = ents.Create("maze_door")
		
		newDoor:Spawn()
		
		if doorLevel == "t" then
			newDoor:SetPos(self:GetPos())
		else
			newDoor:SetPos(self:GetPos() + Vector(0,0,-104))
		end
		
		newDoor:SetAngles(dirAngles[doorDir])
		
		
		newDoor:SetBlock(self)
		newDoor.level = doorLevel
		newDoor.dir = doorDir
		newDoor:SetLevel(doorLevel)
		newDoor:SetDirection(doorDir)
		
		self.doors[doorLevel][doorDir] = newDoor
	
	end
		

end

