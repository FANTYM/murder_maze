AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()

	self:SetModel("models/mm/snare_trap.mdl")
	self:PhysicsInitStatic(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	
	self.lastThink = CurTime()
	self.thinkDelta = 0
	
	self.snareList = {}
	
end

function ENT:Deploy(depSpot) 

	
	local traceData = {}
		  traceData.start = depSpot
		  traceData.endpos = traceData.start + Vector(0,0,-blockSizes.z)
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
		
	if GAMEMODE.roundEnt:GetCurrentTitle() != "in" then return end
	
	local snareables = ents.FindInSphere(self:GetPos(), 196)
	--PrintTable(snareables)
	for k, ent in pairs(snareables) do
		
		if IsValid(ent) && ent:IsPlayer() then
			
			local traceData = {}
				  traceData.start = self:GetPos()
				  traceData.endpos = ent:LocalToWorld(ent:OBBCenter())
				  
				  traceData.filter = {self}
				  
			local traceRes = util.TraceLine(traceData)
			
			if traceRes.Entity == ent then
			
				if !ent.snared then
					
					local plyIndex = -1
					
					for meh, ply in pairs(self.snareList) do
						if ply == ent then
							plyIndex = meh
						end
					end
					
					if plyIndex < 0 then
						
						ent:SetVelocity((self:GetPos() - traceData.endpos) * 3)
						
						ent.snared = true
						
						timer.Simple(1, function() if IsValid(ent) then 
														ent.snared = false
													end 
										end)
						timer.Simple(2, function() if self.snareList then self.snareList[plyIndex] = nil end end)
					
					end
				
				end
				
			end
		
		end
	
	end
	
	self:NextThink(CurTime() + 0.25)
end