
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

--[[---------------------------------------------------------
	Name: Initialize
	Desc: First function called. Use to set up your entity
-----------------------------------------------------------]]
function ENT:Initialize()

	self:SetModel("models/mm/laser_trap.mdl")
	--self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysicsInitStatic(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	
	self.attachments = self:GetAttachments()
	
	--print("------------------- Attachments ---------------------")
	--PrintTable(self.attachments)
	
	--for k, attach in pairs(attachments) do
		
	self.shootAng = math.floor(math.random() * 360)
	self.laserRate = 7.5 + math.ceil(math.random() * 37.5)
	self.lastThink = CurTime()
	self.thinkDelta = 0
	
end


--[[---------------------------------------------------------
	Name: KeyValue
	Desc: Called when a keyvalue is added to us
-----------------------------------------------------------]]
function ENT:KeyValue( key, value )
	self[key] = value
end

--[[---------------------------------------------------------
	Name: OnRestore
	Desc: The game has just been reloaded. This is usually the right place
		to call the GetNW* functions to restore the script's values.
-----------------------------------------------------------]]
function ENT:OnRestore()
end

--[[---------------------------------------------------------
	Name: AcceptInput
	Desc: Accepts input, return true to override/accept input
-----------------------------------------------------------]]
function ENT:AcceptInput( name, activator, caller, data )
	

	
end


function ENT:Deploy(depSpot) 

	
	local traceData = {}
		  traceData.start = depSpot
		  traceData.endpos = traceData.start + Vector(0,0,blockSizes.z)
		  traceData.filter = {self}
		  
	local traceRes = util.TraceLine(traceData)
	
	--print("deploySpot: " .. tostring(depSpot))
	
	local selfSize = (self:OBBMins() - self:OBBMaxs())
	
	--print("selfSize: " .. tostring(selfSize))
	
	self:SetPos(traceRes.HitPos + (selfSize * Vector(0,0,0.5)))
	

end

function ENT:StartTouch( ent )

	
end
--[[---------------------------------------------------------
	Name: UpdateTransmitState
	Desc: Set the transmit state
-----------------------------------------------------------]]
function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end


function ENT:PhysicsSimulate( phys, deltatime )

	
	return 0, 0, SIM_NOTHING

end

function ENT:Think()
	
	

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
	
		--self:SetBeamEnd(traceRes.HitPos)
		
		if IsValid(traceRes.Entity) then
			if traceRes.Entity:IsPlayer() then
				traceRes.Entity:TakeDamage( 50, self , self )
			end
		end
		
	end
	
	self:NextThink(CurTime())
end