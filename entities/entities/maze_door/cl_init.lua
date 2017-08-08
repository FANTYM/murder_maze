include( "shared.lua" )

function ENT:Initialize()
	
	self:SetRenderBounds( self:OBBMins() * 10, self:OBBMaxs() * 10 )
	self.didExitDoorInit = false
	
	self:makeCSModel()
	
	
end

function ENT:KillCSModelOnRemove(csModel)
	
	if !IsValid(self) then
		if csModel then
			if csModel.Remove then
				csModel:Remove()
				return
			end
		end
	end
	
	timer.Simple(1, function() self:KillCSModelOnRemove(self.csModel) end)

end

function ENT:makeCSModel()

	self.csModel = ClientsideModel(self:GetModel())
	self.csModel.owner = self
	self.csModel:SetNoDraw(true)

	
end

function ENT:OnRemove()

	if self.csModel then
		self.csModel:Remove()
	end

	
end

function ENT:Think()

	if (self:GetIsExit()) then 
		
		
		mmGlobals.exitDoorEntity = self
		
		if !self.didExitDoorInit then
			
			self.drawPos = self:GetAttachment(self:LookupAttachment("portal_pos")).Pos
			
			self.didExitDoorInit = true
		end
		
	end
	
	self:NextThink(CurTime() + 1)
end

function ENT:Draw()
	
	local entDist = (LocalPlayer():GetPos() - self:GetPos()):Length()
	
	if ( entDist > 1584) then return end
	
	local doorBlock = self:GetBlock()
	 
	if !doorBlock then return end
	
	if (self:GetIsExit()) && self.didExitDoorInit then 
		
		self:RemoveAllDecals()
		
		render.MaterialOverride( mmGlobals.exitMat)
		
		self:DrawModel()
		
		render.DrawQuadEasy(self.drawPos, -self:GetForward(), 80 * mmGlobals.aspectH, 80 , Color(255,255,255,255), 180)
	  
		render.MaterialOverride()
	
	else
	
		render.SuppressEngineLighting(true)
		
		render.SetLightingOrigin(doorBlock.lightPos)
		
		render.ResetModelLighting( 0.0, 0.0, 0.0 )
		
		lightInfo = {}
		lightInfo.type = MATERIAL_LIGHT_POINT
		lightInfo.color = doorBlock:colorToVector(doorBlock:GetColor())
		lightInfo.pos = doorBlock.lightPos

		lightInfo.fiftyPercentDistance = 13.5
		lightInfo.zeroPercentDistance = 27
		lightInfo.quadraticFalloff = 1
		lightInfo.linearFalloff = 1
		lightInfo.constantFalloff = 0
		
		render.SetLocalModelLights({lightInfo})
		
		self:DrawModel()
		
		render.SuppressEngineLighting(false)
		
	end

end