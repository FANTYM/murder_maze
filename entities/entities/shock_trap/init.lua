AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()

	self:SetModel("models/mm/shock_trap.mdl")
	--self:PhysicsInitStatic(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysicsInitShadow(false, false)
	self:SetMoveType(MOVETYPE_NONE)
	
	self.emitterPos = self:GetAttachment(self:LookupAttachment("emitter")).Pos
		
	self.lastThink = CurTime()
	self.thinkDelta = 0
	
end

function ENT:Deploy(depSpot) 

	
	local traceData = {}
		  traceData.start = depSpot
		  traceData.endpos = traceData.start + Vector(0,0,mmGlobals.blockSizes.z)
		  traceData.filter = {self}
		  
	local traceRes = util.TraceLine(traceData)
	
	local selfSize = (self:OBBMins() - self:OBBMaxs())
	
	self:SetPos(traceRes.HitPos)
	
end

function ENT:StartTouch( ent )

	
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
		
	if mmGlobals.roundEntity && mmGlobals.roundEntity:GetCurrentTitle() != "in" then return end
	
	local shockables = ents.FindInSphere(self:GetPos() + self.emitterPos, 256)
	
	for k, ent in pairs(shockables) do
		
		if IsValid(ent) && ent:IsPlayer() then
			
			local traceData = {}
				  traceData.start = self:GetPos() + self.emitterPos
				  traceData.endpos = ent:LocalToWorld(ent:OBBCenter())
				  
				  traceData.filter = {self}
				  
			local traceRes = util.TraceLine(traceData)
			
			if traceRes.Entity == ent then
			
				self:SetShockSpot(ent:LocalToWorld(ent:OBBCenter()))
				self:SetIsShocking(true)
				ent:TakeDamage( 5, self , self )
				timer.Simple(0.1, function()
				
									self:SetIsShocking(false)
									ent:TakeDamage( 2.5, self , self )
									
								end)
			end
		
		end
	
	end
	
	self:NextThink(CurTime() + 0.75)
end