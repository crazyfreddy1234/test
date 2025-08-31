local function SampleFunction(inst)

end

local CustomComponent = Class(function(self, inst)
	self.inst = inst
	self.value = nil
end)

function CustomComponent:SetValue(val)
	self.value = val
end

function CustomComponent:GetValue()
	return self.value or nil
end

function CustomComponent:OnUpdate(dt)
	SampleFunction(self.inst)
end



function CustomComponent:Start()
	
end

function CustomComponent:Stop()
	
end

--Sample_Component.OnRemoveEntity = Sample_Component.Stop
--Sample_Component.OnRemoveFromEntity = Sample_Component.Stop

return CustomComponent
