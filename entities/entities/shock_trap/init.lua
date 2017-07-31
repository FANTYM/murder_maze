
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

--[[---------------------------------------------------------
	Name: Initialize
	Desc: First function called. Use to set up your entity
-----------------------------------------------------------]]
function ENT:Initialize()

	self:SetModel("models/mm/shock_trap.mdl")
	--self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysicsInitStatic(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	
	--self.attachments = self:GetAttachments()
	
	--print("------------------- Attachments ---------------------")
	--PrintTable(self.attachments)
	
	self.emitterPos = self:GetAttachment(self:LookupAttachment("emitter")).Pos
		
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
	
	self:SetPos(traceRes.HitPos) -- + (selfSize * Vector(0,0,0.5)))
	

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
	
	
	if !self.lastThink then self.lastThink = CurTime() end
	
	self.thinkDelta = CurTime() - self.lastThink
	self.lastThink = CurTime()
		
	
		
	if GAMEMODE.roundEnt:GetCurrentTitle() != "in" then return end
	
	local shockables = ents.FindInSphere(self:GetPos() + self.emitterPos, 256)
	
	--print("shock_trap - emitter: " .. tostring(self.emitterPos))
	
	--PrintTable(shockables)
	
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