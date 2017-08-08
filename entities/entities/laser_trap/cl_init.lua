include( "shared.lua" )

function ENT:Initialize()
	
	self:SetRenderBounds( self:OBBMins() * 20, self:OBBMaxs() * 20 )
	
	self.laserMat = Material("cable/redlaser")
	
	language.Add("laser_trap", "Laser Trap")
	killicon.Add( "laser_trap", "mm/laser_trap_killicon", Color(255,0,0,196) )
	
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
		
	local traceData = {}
		  traceData.start = self:GetPos()
		  traceData.endpos = traceData.start + Vector( math.sin(math.rad(self:GetShootAngle())) * mmGlobals.blockSizes.x, 
													   math.cos(math.rad(self:GetShootAngle())) * mmGlobals.blockSizes.y,
													   math.sin(math.rad(self:GetShootAngle())) * 15 )
		  traceData.filter = {self}
		  
	local traceRes = util.TraceLine(traceData)
		
	render.SetMaterial(self.laserMat)
	render.DrawBeam(self:GetPos(), 
					traceRes.HitPos , 8, 0, 1, Color(255,0,0,128))		
	
	render.SuppressEngineLighting(false)

	
end