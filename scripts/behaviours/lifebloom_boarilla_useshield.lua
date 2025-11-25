--[[
Copyright (C) 2018 Forged Forge

This file is part of Forged Forge.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]
--[[
TODO
brain is turned off when sleeping and resets all the variables, need to save important trackers to mob itself so that bunker can occur on wake if triggered prior.
--]]
LifeBloom_Boarilla_UseShield = Class(BehaviourNode, function(self, inst, damage_for_shield, shield_time, cooldown_time, hide_from_heals, hide_from_projectiles, hide_when_scared)
    BehaviourNode._ctor(self, "LifeBloom_Boarilla_UseShield")
    self.inst = inst
	self.is_first_phase_started = false
	self.is_second_phase_started = false
	self.first_phase_hide_health_percent = 0.5  
	self.second_phase_hide_health_percent = 0.1
end)

function LifeBloom_Boarilla_UseShield:CheckHealth()
    local hp = self.inst.components.health:GetPercent()

    if not self.is_first_phase_started
        and hp <= self.first_phase_hide_health_percent then
        return 1
    end

    if not self.is_second_phase_started
        and hp <= self.second_phase_hide_health_percent then
        return 2
    end

    return false
end

function LifeBloom_Boarilla_UseShield:ShouldShield() -- TODO might want to separate into 2 shield methods to bypass cooldown? If scared should cooldown be ignored? same with the other shield req here except damage of course?
    return not self.inst.components.health:IsDead() and not self.inst.sg:HasStateTag("busy") and self:CheckHealth()
end

function LifeBloom_Boarilla_UseShield:Visit()
    if self.status == READY then
        if self:ShouldShield() then 
            local phase = nil
			if self:CheckHealth() == 1 then -- 50%
				self.is_first_phase_started = true
                phase = 1
			elseif self:CheckHealth() == 2 then -- 10%
				self.is_second_phase_started = true
                phase = 2
			end -- each phase runs only once

			self.inst:PushEvent("enter_shield_phase",{phase = phase}) -- just jump to center
			self.status = RUNNING
        else 
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
		if TheWorld.components.lavaarenaevent.victory == false then
			self.inst:PushEvent("exitshield") -- this is not my phase.this is original boarilla exit shield status.
			self.status = SUCCESS
		end
    end
end
