
ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH


function ENT:SetupDataTables()

	self:NetworkVar( "Entity", 0, "Block" )
	self:NetworkVar( "Entity", 1, "Snared")
	
end

function ENT:IsTrap() 

	return true
	
end
