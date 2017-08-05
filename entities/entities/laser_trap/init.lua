AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()

	self:SetModel("models/mm/laser_trap.mdl")
	self:PhysicsInitStatic(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	
	self.shootAng = math.floor(math.random() * 360)
	self.laserRate = 7.5 + math.ceil(math.random() * 37.5)
	self.lastThink = CurTime()
	self.thinkDelta = 0
	
end

function ENT:KeyValue( key, value )
	self[key] = value
end

function ENT:Deploy(depSpot) 

	
	local traceData = {}
		  traceData.start = depSpot
		  traceData.endpos = traceData.start + Vector(0,0,blockSizes.z)
		  traceData.filter = {self}
		  
	local traceRes = util.TraceLine(traceData)
	
	local selfSize = (self:OBBMins() - self:OBBMaxs())
	
	self:SetPos(traceRes.HitPos + (selfSize * Vector(0,0,0.5)))
	

end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end


function ENT:PhysicsSimulate( phys, deltatime )

	return 0, 0, SIM_NOTHING

end

function ENT:Think()

	if !self.lastThink then self.lastThink = CurTime() end
	
	self.thinkDelta = CurTime() - self.lastThink
	self.lastThink = CurTime()
		
		
	if GAMEMODE.roundEnt:GetCurrentTitle() != "in" then return end
	
	self.shootAng = Lerp(self.thinkDelta, self.shootAng, self.shootAng + self.laserRate) --((self.shootAng + (self.laserRate * self.thinkDelta)) % 360)
	
	self:SetShootAngle(self.shootAng)
	
	local traceData = {}
		  traceData.start = self:GetPos()
		  traceData.endpos = traceData.start + Vector( math.sin(math.rad(self.shootAng)) * (blockSizes.x) * 2, 
													   math.cos(math.rad(self.shootAng)) * (blockSizes.y) * 2,
													   math.sin(math.rad(self.shootAng)) * 15 )
		  traceData.filter = {self}
		  
	local traceRes = util.TraceLine(traceData)
	
	if traceRes.Hit then
	
		if IsValid(traceRes.Entity) then
			if traceRes.Entity:IsPlayer() then
				traceRes.Entity:TakeDamage( 50, self , self )
			end
		end
		
	end
	
	self:NextThink(CurTime())
end