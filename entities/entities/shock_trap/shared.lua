
ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH


function ENT:SetupDataTables()

	self:NetworkVar( "Vector", 0, "ShockSpot" )
	self:NetworkVar( "Bool", 1, "IsShocking")
	--self:NetworkVar( "Vector", 1, "BeamEnd" )
	--self:NetworkVar( "Int", 15, "BottomDoorsState" )
	
	
	if SERVER then
		self:SetShockSpot(Vector(0,0,0))
		self:SetIsShocking(false)
		--self:SetBeamEnd(self:GetPos())
	end
end

function ENT:IsTrap() 

	return true
	
end
