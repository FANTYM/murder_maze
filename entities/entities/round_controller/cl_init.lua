
include( "shared.lua" )


--[[---------------------------------------------------------
	Name: Initialize
	Desc: First function called. Use to set up your entity
-----------------------------------------------------------]]
function ENT:Initialize()
	
	self:SetRenderBounds( self:OBBMins() * 0, self:OBBMaxs() * 0 )
	
end


--[[---------------------------------------------------------
	Name: OnRestore
	Desc: Called immediately after a "load"
-----------------------------------------------------------]]
function ENT:OnRestore()

end

function ENT:DrawTranslucent()


end


function ENT:Think()

	if !GAMEMODE.roundEnt then
		GAMEMODE.roundEnt = self
		
		self:NextThink(CurTime() + 0.25)
	else
	
		self:NextThink(CurTime() + 1)
		
	end
	
end

function ENT:Draw()
	
	
end