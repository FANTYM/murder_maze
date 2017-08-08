include( "shared.lua" )

function ENT:Initialize()
	
	self:SetRenderBounds( self:OBBMins() * 0, self:OBBMaxs() * 0 )
	
end

function ENT:Think()

	if !mmGlobals.roundEntity then
		mmGlobals.roundEntity = self
		
		self:NextThink(CurTime() + 0.25)
	else
	
		self:NextThink(CurTime() + 1)
		
	end
	
end
