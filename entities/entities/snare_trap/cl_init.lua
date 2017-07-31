include( "shared.lua" )

function ENT:Initialize()
	
	self:SetRenderBounds( self:OBBMins() * 20, self:OBBMaxs() * 20 )
	
	self.shockMat = Material("effects/tool_tracer")
	
	language.Add("snare_trap", "Snare Trap")
	--killicon.Add( "snare_trap", "mm/shock_trap_killicon", Color(255,255,0,196) )
	
	
		
	
end

function ENT:Draw()
	
	
	if !self.parentBlock then
		
		self.parentBlock = self:GetBlock()
		
		if !self.parentBlock then return end
	end
	
	render.SuppressEngineLighting(true)
	
	render.SetLightingOrigin(self.parentBlock.lightPos)
	
	render.ResetModelLighting( 0.0, 0.0, 0.0 )
	
	lightInfo = {}
	lightInfo.type = MATERIAL_LIGHT_POINT
	lightInfo.color = self.parentBlock:colorToVector(self.parentBlock:GetColor())
	lightInfo.pos = self.parentBlock.lightPos

	lightInfo.fiftyPercentDistance = 13.5
	lightInfo.zeroPercentDistance = 27
	lightInfo.quadraticFalloff = 1
	lightInfo.linearFalloff = 1
	lightInfo.constantFalloff = 0
	
	render.SetLocalModelLights({lightInfo})
	
	self:DrawModel()
	
	render.SuppressEngineLighting(false)
	
end