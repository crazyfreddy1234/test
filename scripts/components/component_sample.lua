local function SampleFunction(inst)

end

local Sample_Component = Class(function(self, inst)
	self.inst = inst
	self.value = nil
end)

function Sample_Component:SetValue(val)
	self.value = val
end

function Sample_Component:GetValue()
	return self.value or nil
end

function Sample_Component:OnUpdate(dt)
	SampleFunction(self.inst)
end



function Sample_Component:Start()
	
end

function Sample_Component:Stop()
	
end

--Sample_Component.OnRemoveEntity = Sample_Component.Stop
--Sample_Component.OnRemoveFromEntity = Sample_Component.Stop

return Sample_Component
