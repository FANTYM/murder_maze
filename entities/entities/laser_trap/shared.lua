ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH


function ENT:SetupDataTables()

	self:NetworkVar( "Float", 0, "ShootAngle" )
	self:NetworkVar( "Entity", 1, "Block" )
	
	
	if SERVER then
		self:SetShootAngle(math.ceil(math.random() * 360))
	end
	
end

function ENT:IsTrap() 

	return true
	
end
