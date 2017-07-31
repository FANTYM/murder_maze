
include( "shared.lua" )


--[[---------------------------------------------------------
	Name: Initialize
	Desc: First function called. Use to set up your entity
-----------------------------------------------------------]]
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

--[[---------------------------------------------------------
	Name: OnRestore
	Desc: Called immediately after a "load"
-----------------------------------------------------------]]
function ENT:OnRestore()

end

function ENT:OnRemove()

	if self.csModel then
		self.csModel:Remove()
	end

	
end

function ENT:Think()

	if (self:GetIsExit()) then 
		
		
		exitEnt = self
		
		if !self.didExitDoorInit then
			
			self.drawPos = self:GetAttachment(self:LookupAttachment("portal_pos")).Pos
			
			self.didExitDoorInit = true
		end
		
		----print(tostring(self) .. " is the exit!!")
		--[[
		self.effectPos = self:GetAttachment(self:LookupAttachment("portal_pos")).Pos
		
		if !self.emitter then
		
			self.emitter = ParticleEmitter( self.effectPos, false)
			self.emitter:SetNoDraw(true)
			
		end
		
		if self.emitter then
			
			self.emitter:SetPos(self.effectPos)
			local newPart = self.emitter:Add("particle/particle_glow_03", self.effectPos)
			
			--newPart:SetVelocity(self:GetForward() * - 200)
			newPart:SetGravity(Vector(0,0,0))
			newPart:SetVelocity(Vector(-120 + (math.random() * 240), -120 + (math.random() * 240), -120 + (math.random() * 240) ))
			newPart:SetAngleVelocity( Angle(-24 + (math.random() * 12), -24 + (math.random() * 12), -24 + (math.random() * 12) ) )
			newPart:SetDieTime(1)
			newPart:SetColor(125, 10, 255)
			newPart:SetEndAlpha(32)
			newPart:SetStartAlpha(255)
			newPart:SetStartSize(16)
			newPart:SetEndSize(2)
			
			
			
			----print("emitter: " .. tostring(self.emitter))
			----print("newPart: " .. tostring(newPart))
			
		end
		]]
	end
	
	self:NextThink(CurTime() + 1)
end

function ENT:Draw()
	
	--self:DisableMatrix("RenderMultiply")
	local entDist = (LocalPlayer():GetPos() - self:GetPos()):Length()
	----print(entDist)
	if ( entDist > 1584) then return end
	
	local doorBlock = self:GetBlock()
	 
	if !doorBlock then return end
	
	----print(tostring(self) .. " dist to player: " .. tostring(entDist) .. " - Drawing...")

	--local entDist = (LocalPlayer():GetPos() - self:GetPos()):Length()
	
	--if ( entDist > 1056) then return end

	if (self:GetIsExit()) && self.didExitDoorInit then 
		
		self:RemoveAllDecals()
		--exitEnt = self
		----print(tostring(self) .. " is the exit!!")
		--hook.Add("RenderScene", "mfrs", myRS)
		
		
		--renderScene()
		
		--render.SetMaterial( exitMat )
		
		render.MaterialOverride( exitMat)
		
		self:DrawModel()
		
		render.DrawQuadEasy(self.drawPos, -self:GetForward(), 80 * aspectH, 80 , Color(255,255,255,255), 180)
	  
		render.MaterialOverride()
		
		
		
		
	else
		render.SuppressEngineLighting(true)
		
		render.SetLightingOrigin(doorBlock.lightPos)
		
		render.ResetModelLighting( 0.0, 0.0, 0.0 )
		
		lightInfo = {}
		lightInfo.type = MATERIAL_LIGHT_POINT
		lightInfo.color = doorBlock:colorToVector(doorBlock:GetColor()) --doorBlock.lightColor * 0.25
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