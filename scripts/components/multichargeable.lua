local Multichargeable = Class(function(self, inst)
    self.inst = inst
    self.max_charges = 3
    self.current_charges = 3
    self.charge_time = 10
    self.cooldownrate = 1
    self.recharge_tasks = {}
    self.is_recharging = false

    self.onchargeused = nil
    self.onfullcharged = nil
    self.onpartialcharged = nil

    self._onEquipped = function(inst, data) self:OnEquipped(data) end
    self._onUnequipped = function(inst, data) self:OnUnequipped(data) end

    inst:ListenForEvent("equipped", self._onEquipped)
    inst:ListenForEvent("unequipped", self._onUnequipped)
end)

function Multichargeable:OnEquipped(data)
    self.owner = data.owner
    self:RecalculateRate()
    self:UpdateHUD()
end

function Multichargeable:OnUnequipped(data)
    self:CancelAllRechargeTasks()
    self.cooldownrate = 1
    self.owner = nil
end

function Multichargeable:SetMaxCharges(n)
    self.max_charges = n
    self.current_charges = math.min(self.current_charges, n)
end

function Multichargeable:SetChargeTime(t)
    self.charge_time = t
end

function Multichargeable:RecalculateRate()
    if self.owner ~= nil then
        self.cooldownrate = self.owner.components.buffable and self.owner.components.buffable:ApplyStatBuffs({"cooldown"}, 1) or 1
    end
end

function Multichargeable:UseCharge()
    if self.current_charges <= 0 then return false end

    self.current_charges = self.current_charges - 1
    self:StartRecharge()

    if self.onchargeused then
        self.onchargeused(self.inst, self.current_charges)
    end

    self:UpdateHUD()
    return true
end

function Multichargeable:StartRecharge()
    if self.current_charges >= self.max_charges then return end

    local actual_time = self.charge_time * self.cooldownrate
    self.is_recharging = true

    local start_time = GetTime()

    local task = self.inst:DoPeriodicTask(FRAMES, function()
        local elapsed = GetTime() - start_time
        local percent = math.min(elapsed / actual_time, 1)

        -- 클라이언트에 HUD 업데이트
        if self.inst.replica and self.inst.replica.inventoryitem then
            self.inst.replica.inventoryitem:SetChargeTime(actual_time * (1 - percent))
        end

        -- rechargechange 이벤트
        self.inst:PushEvent("rechargechange", { percent = percent, overtime = true })

        if percent >= 1 then
            self:FinishRecharge(task)
        end
    end)

    table.insert(self.recharge_tasks, task)
end

function Multichargeable:FinishRecharge(task)
    if task then
        task:Cancel()
    end

    self.current_charges = math.min(self.current_charges + 1, self.max_charges)
    self.is_recharging = false

    self:UpdateHUD()

    if self.current_charges == self.max_charges then
        if self.onfullcharged then
            self.onfullcharged(self.inst)
        end
    elseif self.onpartialcharged then
        self.onpartialcharged(self.inst, self.current_charges)
    end
end

function Multichargeable:UpdateHUD()
    if self.inst.replica and self.inst.replica.inventoryitem then
        local percent = self.current_charges / self.max_charges
        self.inst.replica.inventoryitem:SetChargeTime(self:GetRemainingRechargeTime())
        self.inst:PushEvent("rechargechange", { percent = percent, overtime = false })
    end
end

function Multichargeable:GetRemainingRechargeTime()
    return self.is_recharging and (self.charge_time * self.cooldownrate) or 0
end

function Multichargeable:CancelAllRechargeTasks()
    for _, task in ipairs(self.recharge_tasks) do
        if task then task:Cancel() end
    end
    self.recharge_tasks = {}
end

function Multichargeable:IsFullyCharged()
    return self.current_charges >= self.max_charges
end

function Multichargeable:GetCurrentCharges()
    return self.current_charges
end

function Multichargeable:GetMaxCharges()
    return self.max_charges
end

function Multichargeable:SetOnChargeUsedFn(fn)
    self.onchargeused = fn
end

function Multichargeable:SetOnFullChargedFn(fn)
    self.onfullcharged = fn
end

function Multichargeable:SetOnPartialChargedFn(fn)
    self.onpartialcharged = fn
end

function Multichargeable:GetDebugString()
    return string.format("charges: %d/%d, recharge time: %.2f", self.current_charges, self.max_charges, self:GetRemainingRechargeTime())
end

return Multichargeable
