include( "shared.lua" )

function ENT:Initialize()
	
	self:SetRenderBounds( self:OBBMins() * 20, self:OBBMaxs() * 20 )
	
	self.shockMat = Material("effects/tool_tracer")
	
	language.Add("shock_trap", "Shock Trap")
	killicon.Add( "shock_trap", "mm/shock_trap_killicon", Color(255,255,0,196) )
	
	self.emitterPos = self:GetAttachment(self:LookupAttachment("emitter")).Pos
		
	
end

function ENT:Draw()
	
	--[[
	render.SuppressEngineLighting(true)
	
	render.SetLightingOrigin(doorBlock.lightPos)
	
	render.ResetModelLighting( 0.0, 0.0, 0.0 )
	
	lightInfo = {}
	lightInfo.type = MATERIAL_LIGHT_POINT
	lightInfo.color = doorBlock.lightColor * 0.25
	lightInfo.pos = doorBlock.lightPos

	lightInfo.fiftyPercentDistance = 13.5
	lightInfo.zeroPercentDistance = 27
	lightInfo.quadraticFalloff = 1
	lightInfo.linearFalloff = 1
	lightInfo.constantFalloff = 0
	
	render.SetLocalModelLights({lightInfo})
	--]]
	
	
	self:DrawModel()
	
	if self:GetIsShocking() then
		
		render.SetMaterial(self.shockMat)
		render.DrawBeam(self.emitterPos, 
						self:GetShockSpot() , 8, (math.random() * 0.5), 0.5 + (math.random() * 0.5), Color(255,255,0,128))
	else
	
		render.SetMaterial(self.shockMat)
		render.DrawBeam(self.emitterPos, 
						self.emitterPos + Vector( (-16 + math.random() * 32), 
												  (-16 + math.random() * 32), 
												  (-16 + math.random() * 32) ) , 4, (math.random() * 0.5), 0.5 + (math.random() * 0.5), Color(255,255,0,128))
		
	end
	

	
end