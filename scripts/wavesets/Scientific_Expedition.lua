local _W = _G.UTIL.WAVESET
local RPX=TUNING.modfns["workshop-2038128735"]
local tuningvalue = _G.TUNING.FORGE
local weaponname = _G.STRINGS.NAMES
local HasTag=function(t,tag) return type(t)=="table" and t.tags and t.tags[tag] or false end
local boarrior_sg = deepcopy(require "stategraphs/SGpitpig_hards")
local GetReforgedData=function(k,v) local t=REFORGED_DATA and REFORGED_DATA[k] or {} return v and t[v] or t or {} end
local GetReforgedSettings=function(k,v) local t=REFORGED_SETTINGS and REFORGED_SETTINGS[k] or {} return v and t[v] or t or {} end
local sp={waveset="wavesets",difficulty="difficulties",gametype="gametypes",mode="modes",mutator="mutators",map="maps"}
local GameplayHasTag=function(data,tag)
    local v=GetReforgedSettings("gameplay",data)
    return HasTag(GetReforgedData(sp[data],v),tag)
end
local ishard = GameplayHasTag("difficulty","hard")
local AddReforgedPrefab=RPX.AddReforgedPrefab

math.randomseed(os.time())

local AddCrocommander=function(inst)

end

local AddHardCrocommander=function(inst)
	if not GameplayHasTag("difficulty","hard") then return inst end
	inst.reinforcements.min_followers=-1
end

AddReforgedPrefab("crocommander",AddCrocommander,AddHardCrocommander)

local hueindex={}
 local SetHue=function(inst,hue)
 	if inst.AnimState then 
 		if not hue then 
 			hue=hueindex[inst.prefab] or 0
 			hue=hue-0.08+(0.08>hue and 1.02 or 0)
 			hueindex[inst.prefab]=hue
 		end
 		if type(hue)=="table" then 
 			for k,v in pairs(hue) do 
                inst.AnimState:SetSymbolHue(k,v)
            end
 		else 
 			inst.AnimState:SetHue(hue)
 		end
 	end
 end

 local symbolsets,huepresets,huepresetsindex={
 	boarilla={{"helmet","armour","shell","belt"},{"head","eyes","mouth","body","arm","hand","leg","foot"}},
 	boarrior={{"head","chest","shoulder","hand","pelvis"},{"eyes","nose","arm","mouth"}},
 	rhinocebro={{"ears","head","eyes","mouth","shoulder","arm","body","leg","foot"}},
 	swineclops={{"head","shoulder","shell"}}
 },{},{}
 symbolsets.rhinocebro2=symbolsets.rhinocebro
 huepresets.boarilla={
 	purple={0.69,0.95},
 	green={0.31,0.09},
 	blue={0.54,0.97},
 	grey={0.14,0.07},
 	copper={0.08,0.1},
 	olive={0.27,0.64},
 	teal={0.44,0.3},
 	lilac={0.66,0.45},
 	violet={0.74,0.17},
 	cherry={0.9,0.87}
 }
 huepresets.boarrior={
    black={0.19},
 	purple={0.71,0.94},
 	green={0.33,0.96},
 	blue={0.57,0.13},
 	grey={0.19,0.97},
 	olive={0.28,0.58},
 	emerald={0.39,0.89},
 	teal={0.49,0.04},
 	lilac={0.69,0.43},
 	violet={0.75,0.17},
 	cherry={0.91,0.88}
 }
 huepresets.rhinocebro={
 	lilac={0.69},
 	blue={0.56},
 	grey={0.18},
 	olive={0.24},
 	teal={0.46}
 }
 huepresets.rhinocebro2=huepresets.rhinocebro
 huepresets.rhinocebro_hard={
 	lilac=0.69,
 	blue=0.58,
 	grey=0.22,
 	olive=0.32,
 	teal=0.5
 }
 huepresets.rhinocebro2_hard=huepresets.rhinocebro_hard
 huepresets.swineclops={
    black={0.19},
 	red={0.66},
 	blue={0.24},
 	brown={0.82},
 	purple={0.39},
 	violet={0.33}
 }
 huepresets.swineclops_hard={
 	red=0.91,
 	blue=0.53,
 	brown=0.1,
 	purple=0.66,
 	violet=0.62
 }
 local SetPresetHue=function(inst,opt)
 	if inst.AnimState then 
 		local name=inst.prefab
 		local ishardbuild=inst.AnimState:GetBuild() and inst.AnimState:GetBuild():find("_hardmode")
 		if ishardbuild and name and huepresets[name.."_hard"] then name=name.."_hard" end
 		local opts=huepresets[name]
 		if opts then 
 			if opt==nil then 
 				opt=GetRandomKey(opts)
 			elseif opt==true or opt==false then 
 				local k=opt==false and huepresetsindex[name] or next(opts,huepresetsindex[name])
 				opt=k
 				huepresetsindex[name]=k
 			end
 			local preset=type(opt)=="table" and opt or opts[opt]
 			if preset then 
 				if type(preset)=="table" then 
 					local symbolset=symbolsets[name]
 					if symbolset then 
 						for i,v in ipairs(preset) do 
 							local symbols=symbolset[i]
 							if symbols then 
                                for _,v1 in ipairs(symbols) do 
                                    inst.AnimState:SetSymbolHue(v1,v) 
                                    if name == "boarrior" then
                                        inst.AnimState:SetSymbolMultColour(v1,0.3,0.3,0.3,1)
                                    end
                                end 
                            end
 						end
 					else 
 						inst.AnimState:SetHue(preset[1])
 					end
 				else 
 					inst.AnimState:SetHue(preset)
 				end		
 			end
 		end
 	end
 end
 
smallmob_weight = {
    {pitpig=1},
    {snortoise=2},
    {scorpeon=3},
    {crocommander=4}
} 

midmob_weight = {
    {boarilla=20},
    {rhinocebro=20}
}

boss_weight = {
    {boarrior=50},
    {swineclops=50},
}

wave_weight = {
    [1] = {weight = math.random(10,15)},            -- small mob                                                        --cant midmob              active smallmob
    [2] = {weight = math.random(25,30)},            -- 1mid,small or 2small                                             --cant 2midmob             active smallmob
    [3] = {weight = math.random(45,50)},            -- 1boss,1mid or 2mid,small       or 1mid,small                     --cant 1boss,small         active midmob                   
    [4] = {weight = math.random(10,15)},            -- 1boss 2mid or 1boss,1mid,small or 2boss                          --cant 2mid,small          active boss
    [5] = {weight = math.random(5,5)},             -- 1mid,small or 2small           or 2midmob                        --
    [6] = {weight = math.random(5,5)},
    [7] = {weight = math.random(44,44)},
}

local function MakeSpawnTable(round)
    math.randomseed(os.time())
    local max_round = 4
    local wave_weight_round = wave_weight[round].weight
    local count_bossmob = 0
    local count_midmob = 0
    local count_smallmob = {}
    local count_smallmob_loop = 1

    local count_mob = {
        {pitpig=0},
        {snortoise=0},
        {scorpeon=0},
        {crocommander=0},
        {crocommander_rapidfire=0},
        {boarilla=0},
        {rhinocebro=0},
        {boarrior=0},
        {swineclops=0}
    }

    if(round == 1) then
        count_midmob = 0
    end
    if(round == 2) then
        count_midmob = 1
    elseif(round == 3) then
        count_midmob = 2
    elseif(round == 4) then
        count_midmob = 0
    elseif(round == 5) then 
        count_mob[8]["boarrior"] = count_mob[8]["boarrior"] + 1
    elseif(round == 6) then
        count_mob[9]["swineclops"] = count_mob[9]["swineclops"] + 1
    elseif(round == 7) then
        count_midmob = 2
    end




    --[[
    for count2=1,count_bossmob do
        wave_weight_round = wave_weight_round -50
        for i,j in pairs(boss_weight[math.random(1,#boss_weight)]) do
            for count=1,#count_mob do
                for k,l in pairs(count_mob[count]) do
                    if tostring(i)==tostring(k) then                    
                        count_mob[count][k] = count_mob[count][k] + 1       
                    end      
                end
            end
        end
    end
    --]]

    for count2=1,count_midmob do 
        wave_weight_round = wave_weight_round - 20
        for i,j in pairs(midmob_weight[math.random(1,#midmob_weight)]) do
            for count=1,#count_mob do
                for k,l in pairs(count_mob[count]) do
                    if tostring(i)==tostring(k) then                    
                        count_mob[count][k] = count_mob[count][k] + 1       
                    end      
                end
            end
        end
    end 


    while(wave_weight_round > 0) do
        if(wave_weight_round < 4) then
            count_smallmob[count_smallmob_loop] = math.random(1,wave_weight_round)
        else 
            count_smallmob[count_smallmob_loop] = math.random(1,4)
        end
        wave_weight_round = wave_weight_round - count_smallmob[count_smallmob_loop]

        count_smallmob_loop = count_smallmob_loop + 1
    end
    for count2=1,count_smallmob_loop do
        if smallmob_weight[count_smallmob[count2]] == nil then
            break
        end
        for i,j in pairs(smallmob_weight[count_smallmob[count2]]) do
            for count=1,#count_mob do
                for k,l in pairs(count_mob[count]) do
                    if tostring(i)==tostring(k) then                    
                        count_mob[count][k] = count_mob[count][k] + 1       
                    end      
                end
            end
        end
    end

    return count_mob
end

local function MakeSpawner(round)
    math.randomseed(os.time())
    local SetSpawner = {
        {pitpig=0, snortoise=0, scorpeon=0, crocommander=0, crocommander_rapidfire=0, boarilla=0, rhinocebro=0, boarrior=0, rhinocebros=0, swineclops=0,},
        {pitpig=0, snortoise=0, scorpeon=0, crocommander=0, crocommander_rapidfire=0, boarilla=0, rhinocebro=0, boarrior=0, rhinocebros=0, swineclops=0,},
        {pitpig=0, snortoise=0, scorpeon=0, crocommander=0, crocommander_rapidfire=0, boarilla=0, rhinocebro=0, boarrior=0, rhinocebros=0, swineclops=0,}
    }

    for i,j in pairs(MakeSpawnTable(round)) do   
        for k,l in pairs(j) do  
            if(l>0) then                    
                for n=1,l do   
                    local randomnumber = math.random(1,3)
                    SetSpawner[randomnumber][k] = SetSpawner[randomnumber][k] + 1
                end
            end
        end
    end
    
    return SetSpawner
end

LastSpawner = {}
LastSpawner[1] = MakeSpawner(1)
LastSpawner[2] = MakeSpawner(2)
LastSpawner[3] = MakeSpawner(3)
LastSpawner[4] = MakeSpawner(4)
LastSpawner[5] = MakeSpawner(5)
LastSpawner[6] = MakeSpawner(6)
LastSpawner[7] = MakeSpawner(7)


local function CreateRepeatMob(spawner,round)
    local spawnermoblist = {}
    for i,j in pairs(LastSpawner[round]) do
        if(spawner==i) then
            for k,l in pairs(j) do
                if l>0 then
                    table.insert(spawnermoblist, _W.RepeatMob(k,l))
                end
            end
        end
    end

    return unpack(spawnermoblist)
end

local function CreateCreateMobList(spawner,round)
    return _W.CreateMobList(CreateRepeatMob(spawner,round))
end

local function CreateCreateSpawn(spawner,round)
    return {_W.CreateSpawn(_W.CreateMobSpawnFromPreset("random", CreateCreateMobList(spawner,round))),{spawner}}
end

local function MakeSetSpawn(round)
    return _W.SetSpawn(CreateCreateSpawn(1,round),CreateCreateSpawn(2,round),CreateCreateSpawn(3,round))
end

local function ChangeWeaponStat()
    
    local pos = Vector3(0,0,0)
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, 999, {"_inventoryitem"})
    
    for _,ent in pairs(ents) do
        --MELEE--
        if ent.prefab == "blacksmithsedge" then
            local randomHP = math.random(50,75)
            ent._HP:set(randomHP)

            local function OnParrySuccesss(inst, caster)
                caster.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/hide_hit")
                for _,player in pairs(AllPlayers) do
                    if player.components.health and not (player.components.health:IsDead() or player.components.health:IsInvincible() or player:HasTag("playerghost")) and
                    player.entity:IsVisible() then
                        player.components.health:DoDelta(2.5, nil, "parry_heal")
                    end
                end
            end
            ent.components.parryweapon:SetOnParrySuccessFn(OnParrySuccesss)

            for _,player in pairs(AllPlayers) do
                if(player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == ent) then
                    player.components.health:AddHealthBuff(ent.prefab, randomHP, "flat")
                end
            end
            ent:ListenForEvent("unequipped", function(inst, data)
                if data.owner then
                    data.owner.components.health:RemoveHealthBuff(inst.prefab, "flat")
                end
            end)
            ent:ListenForEvent("equipped", function(inst, data)
                if data.owner then
                    data.owner.components.health:AddHealthBuff(inst.prefab, randomHP, "flat")
                end
            end)
            
        end

        if ent.prefab == "forginghammer" then
            local electricattack = 1
            local hit_count = 0
            local equidplayer 

            ent._electricattack:set(electricattack)

            local function electricAblity(inst,data)
                if hit_count<13 then 
                    ent.components.weapon.overridestimulifn = function() return "" end
                    hit_count=hit_count+1 
                elseif(hit_count == 13) then
                    ent.components.weapon.overridestimulifn = function() return "electric" end
                    ent.components.weapon:SetDamage(TUNING.FORGE.FORGINGHAMMER.DAMAGE * 5)
                    hit_count=hit_count+1 
                else
                    ent.components.weapon.overridestimulifn = function() return "" end
                    ent.components.weapon:SetDamage(TUNING.FORGE.FORGINGHAMMER.DAMAGE)
                    COMMON_FNS.CreateFX("forginghammer_crackle_fx",data.target)
                    COMMON_FNS.CreateFX("forge_electrocute_fx", data.target) 
                    hit_count=0 
                end
            end

            for _,player in pairs(AllPlayers) do
                if(player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == ent) then

                    local hit_count=0 
                    if player then 
                        player:ListenForEvent("onhitother",electricAblity)
                    end 
                end
            end

            ent:ListenForEvent("equipped",function(inst,data) 
                hit_count=0 
                local owner=data and data.owner 

                if owner then 
                    data.owner:ListenForEvent("onhitother",electricAblity)
                end 
            end)
            ent:ListenForEvent("unequipped", function(inst, data)
                hit_count=0 
                if data.owner then
                
                    data.owner:RemoveEventCallback("onhitother",electricAblity)
                end                 
            end)
        end

        if ent.prefab == "teleport_staff" then
            local randomdamage = math.random(10,13) 
            local healrate = 1

            ent._damage:set(randomdamage)
            ent._healrate:set(healrate)

            ent.HealOwner = function(inst, owner)
				inst.heal_task = inst:DoTaskInTime(1, function(inst)
					if inst.components.equippable:IsEquipped() and not owner.components.health:IsDead() then
                        if owner.components.health:GetPercent() <= 1 then
                            if not inst:HasTag("regen2") then
                                inst:AddTag("regen2")
                                owner.components.health:AddRegen("blossomedwreath_regen2", 1)                               
                            end

                            if owner.components.health.currenthealth < owner.components.health.maxhealth then
                                owner.components.health:DoDelta(1, true, "regen2", true)
                            end

                            inst:HealOwner(owner)
                        else
                            owner.components.health:RemoveRegen("blossomedwreath_regen2")
							inst:RemoveTag("regen2")
                        end
					else
						inst:RemoveTag("regen2")
					end
				end)
			end

            for _,player in pairs(AllPlayers) do
                if(player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == ent) then
                    ent:HealOwner(player)
                    ent._deathfunction = function(owner)
                        if ent.heal_task then
                            ent.heal_task:Cancel()
                            ent.heal_task = nil
                        end
                        ent:RemoveTag("regen2")
                        owner.components.health:Kill()
                    end
                    ent._revivefunction = function(owner)
                        ent:HealOwner(owner)
                    end
                    player:ListenForEvent("ms_respawnedfromghost", ent._revivefunction)
                    player:ListenForEvent("death", ent._deathfunction)
                end
            end

            ent:ListenForEvent("equipped", function(inst, data)
                inst:HealOwner(data.owner)
                inst._deathfunction = function(owner)
                    if inst.heal_task then
                        inst.heal_task:Cancel()
                        inst.heal_task = nil
                    end
                    inst:RemoveTag("regen2")
                    owner.components.health:Kill()
                end
                inst._revivefunction = function(owner)
                    inst:HealOwner(owner)
                end
                data.owner:ListenForEvent("ms_respawnedfromghost", inst._revivefunction)
                data.owner:ListenForEvent("death", inst._deathfunction)
            end)
            ent:ListenForEvent("unequipped", function(inst, data)
            	local owner = data.owner
                if inst.heal_task then
                    inst.heal_task:Cancel()
                    inst.heal_task = nil
                end
                inst:RemoveTag("regen2")
                owner.components.health:RemoveRegen("blossomedwreath_regen2")
                owner:RemoveEventCallback("ms_respawnedfromghost", inst._revivefunction)
                inst._revivefunction = nil
                owner:RemoveEventCallback("death", inst._deathfunction)
                inst._deathfunction = nil
            end)

            ent.components.weapon:SetDamage(TUNING.FORGE.TELEPORT_STAFF.DAMAGE + randomdamage)
        end

        if ent.prefab == "riledlucy" then
            local randomspeed = 1   
            local upspeed = 5        
            ent._speed:set(randomspeed)
            ent._upspeed:set(upspeed)

            ent.components.equippable.walkspeedmult = tonumber(string.format("1.%d",randomspeed ))

            ent:ListenForEvent("aoe_casted", function(inst, data)
                data.caster.components.locomotor.runspeed = 9
                ent:DoTaskInTime(2, function()
                    data.caster.components.locomotor.runspeed = 6
                end)
            end)
        end

        if ent.prefab == "pithpike" then
            local randomdamage = math.random(10,13) 
            local defensebuff = 1
            ent._damage:set(randomdamage)
            ent._defensebuff:set(defensebuff)

            ent.components.weapon:SetDamage(TUNING.FORGE.PITHPIKE.DAMAGE + randomdamage)
            ent.components.weapon:SetAltAttack(TUNING.FORGE.PITHPIKE.ALT_DAMAGE + randomdamage)

            local function PlayerMighty(inst, data)
                inst:AddTag("dontremoveheavybody")
            end


            ent:ListenForEvent("aoe_casted", function(inst, data)


                for _,player in pairs(AllPlayers) do
                    player.components.combat:AddDamageBuff("pithpike_def", 0.8, true)

                    if not player:HasTag("heavybody") then
                        player:AddTag("heavybody")
                    else
                        player:AddTag("dontremoveheavybody")
                    end

                    player:ListenForEvent("powerup",PlayerMighty)
                end
                ent:DoTaskInTime(3, function()
                    for _,player in pairs(AllPlayers) do
                        player.components.combat:RemoveDamageBuff("pithpike_def", true)
                        player:RemoveEventCallback("powerup",PlayerMighty)
                        
                        if not player:HasTag("dontremoveheavybody") and player:HasTag("heavybody") then
                            player:RemoveTag("heavybody")
                        elseif player:HasTag("dontremoveheavybody") then
                            player:RemoveTag("dontremoveheavybody")
                        end

                    end
                end)
            end)
            
	    end

        --DART--

        if ent.prefab == "forgedarts" then
            local randomdamage = math.random(5,8) 
            local infirange = {60,120,180,200}
            local hit_count = 0
            local equidplayer

            ent._damage:set(randomdamage)
            ent._infirange:set(1)

            local function electricAblity(inst,data)
                if hit_count<19 then 
                    hit_count=hit_count+1 
                else
                    data.target.components.debuffable:AddDebuff("scorpeon_dot", "scorpeon_dot")
                    hit_count=0
                end
            end

            for _,player in pairs(AllPlayers) do
                if(player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == ent) then
                    hit_count=0 
                    if player then 
                        player:ListenForEvent("onhitother",electricAblity)
                    end 
                end
            end

            ent:ListenForEvent("equipped",function(inst,data) 
                hit_count=0 
                 
                local owner=data and data.owner 
                if owner then 
                    data.owner:ListenForEvent("onhitother",electricAblity)
                end 
            end)
            ent:ListenForEvent("unequipped", function(inst, data)
                hit_count=0 
                if data.owner then
                
                    data.owner:RemoveEventCallback("onhitother",electricAblity)
                end                 
            end)

            ent.components.weapon:SetDamage(TUNING.FORGE.FORGEDARTS.DAMAGE + randomdamage)
            ent.components.weapon:SetAltAttack(TUNING.FORGE.FORGEDARTS.ALT_DAMAGE + randomdamage)
        end

        if ent.prefab == "moltendarts" then
            local randomdamage = math.random(10,13) 
            local infirange = {60,120,180,200}
            local hit_count = 0
            ent._damage:set(randomdamage)
            ent._infirange:set(1)

            local function electricAblity(inst,data)
                if hit_count<19 then 
                    hit_count=hit_count+1 
                else
                    SpawnAt("scorpeon_projectile", data.target).components.complexprojectile:Launch(data.target:GetPosition(), inst)
                    hit_count=0
                end
            end

            for _,player in pairs(AllPlayers) do
                if(player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == ent) then
                    hit_count=0 
                    if player then 
                        player:ListenForEvent("onhitother",electricAblity)
                    end 
                end
            end

            ent:ListenForEvent("equipped",function(inst,data) 
                hit_count=0 
                 
                local owner=data and data.owner 
                if owner then 
                    data.owner:ListenForEvent("onhitother",electricAblity)
                end 
            end)
            ent:ListenForEvent("unequipped", function(inst, data)
                hit_count=0 
                if data.owner then
                
                    data.owner:RemoveEventCallback("onhitother",electricAblity)
                end                 
            end)

            ent.components.weapon:SetDamage(TUNING.FORGE.MOLTENDARTS.DAMAGE + randomdamage)
            ent.components.weapon:SetAltAttack(TUNING.FORGE.MOLTENDARTS.ALT_DAMAGE + randomdamage)
        end

        if ent.prefab == "firebomb" then
            local randomdamage = 10
            local anotherbomb = 1
            ent._damage:set(randomdamage)
            ent._anotherbomb:set(anotherbomb)

            ent:ListenForEvent("aoe_casted", function(inst, data)
                local cast_player = data.caster
                local pos_firebomb = data.pos

                local return_firebomb = SpawnPrefab("firebomb_projectile")
                return_firebomb.Transform:SetPosition(pos_firebomb:Get())
                return_firebomb.owner = cast_player
                return_firebomb.components.complexprojectile:Launch(cast_player:GetPosition(), cast_player, ent, cast_player.components.combat:CalcDamage(nil, ent, nil, true, nil, TUNING.FORGE.FIREBOMB.ALT_STIMULT), true)
                return_firebomb:AttackArea(cast_player, ent, pos_firebomb)
            end)

            ent.components.weapon:SetDamage(TUNING.FORGE.MOLTENDARTS.DAMAGE + randomdamage)
            ent.components.weapon:SetAltAttack(TUNING.FORGE.MOLTENDARTS.ALT_DAMAGE + randomdamage)
	    end


        --STAFF--

        if ent.prefab == "livingstaff" then
            local randomhealrate = 2
            local target_heal = 1
            local checkheal = 1

            ent._healrate:set(randomhealrate)
            ent._target_heal:set(target_heal)
            ent._checkheal:set(checkheal)


            local pos = Vector3(0,0,0)
            local ents = TheSim:FindEntities(pos.x, 0, pos.z, 999, {"_inventoryitem"})
            local livingstaff_prefab 

            for _,ent in pairs(ents) do
                if ent.prefab == "livingstaff" then
                    livingstaff_prefab = ent
                end
            end



            local function HealTeamMate(inst, data)     
                ent._checkheal:set(0)
                
                if data.target and data.target:HasTag("upgrade_healer_ishere") then

                    local player_bloom_position = data.target:GetPosition()
                    local bloom = COMMON_FNS.CreateFX("healingcircle_bloom")
                    bloom.Transform:SetPosition(player_bloom_position:Get())

                    bloom:DoTaskInTime(1, function(inst)
                        inst.AnimState:PushAnimation("out_"..inst.variation, false)
                        inst:ListenForEvent("animover", function()
                            if inst.AnimState:AnimDone() then
                                inst:Remove()
                            end
                        end)
                    end)

                    if not data.target.components.health:IsDead() then
                        data.target.components.health:DoDelta(0.5, true, "livingstaff_heal", true)
                    end
                end

            end

            for _,player in pairs(AllPlayers) do
                player:AddTag("upgrade_healer_ishere")
                player:RemoveTag("NOCLICK")
                if(player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == livingstaff_prefab) then

                    player:AddTag("upgrade_healer")
                    
                    player:ListenForEvent("onmissother",HealTeamMate)
                end
            end
            
            ent:ListenForEvent("unequipped", function(inst, data)
                for _,player in pairs(AllPlayers) do
                    player:AddTag("upgrade_healer_ishere")
                    player:RemoveTag("NOCLICK")
                end

                if data.owner then
                    data.owner:RemoveTag("upgrade_healer")
                    data.owner:RemoveEventCallback("onmissother",HealTeamMate)
                end
            end)
            ent:ListenForEvent("equipped", function(inst, data)
                for _,player in pairs(AllPlayers) do
                    player:AddTag("upgrade_healer_ishere")
                    player:RemoveTag("NOCLICK")
                end

                if data.owner then
                    data.owner:AddTag("upgrade_healer")
                    data.owner:ListenForEvent("onmissother",HealTeamMate)
                end
            end)



            ent.heal_rate = TUNING.FORGE.LIVINGSTAFF.HEAL_RATE + randomhealrate

            
        end

        if ent.prefab == "infernalstaff" then
            local randomdamage = math.random(5,10)
            local moremeteor = 1

            ent._damage:set(randomdamage)
            ent._moremeteor:set(moremeteor)
            

            ent.components.weapon:SetDamage(TUNING.FORGE.INFERNALSTAFF.DAMAGE + randomdamage)
            ent.components.weapon:SetAltAttack(TUNING.FORGE.INFERNALSTAFF.ALT_DAMAGE + randomdamage)

            ent:ListenForEvent("aoe_casted", function(inst, data)
                for i=1,2 do
                    ent:DoTaskInTime(i-i*0.7, function()
                        for _,player in pairs(AllPlayers) do
                            if(player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == ent) then
                                local pos = player:GetPosition()
                                pos.x = pos.x + math.random(0,4) - 2
                                pos.z = pos.z + math.random(0,4) - 2

                                SpawnPrefab("infernalstaff_meteor"):AttackArea(player, ent, pos, nil, COMMON_FNS.GetPlayerExcludeTags(player))
                            end
                        end
                    end)
                end
            end)
        end


        --BOOK--
        if ent.prefab == "petrifyingtome" then
            local randomspeed = math.random(1,2)
            local petagain = 1

            ent._speed:set(randomspeed)
            ent._petagain:set(petagain)

            
            ent:ListenForEvent("aoe_casted", function(inst, data)
                ent:DoTaskInTime(3, function()
                    inst.components.fossilizer:Fossilize(data.pos, data.caster)
                end)
            end)
            ent.components.equippable.walkspeedmult = tonumber(string.format("1.%d", randomspeed))
        end

        if ent.prefab == "bacontome" then

            local cutegolemappear = 1
            ent._golemappear:set(cutegolemappear)
            local randomspeed = math.random(1,2)
            ent._speed:set(randomspeed)

            ent.components.equippable.walkspeedmult = tonumber(string.format("1.%d", randomspeed))
            local golemprefab

            local function FollowLeader(golem, player)
                golem.entity:SetParent(player.entity)
                golem.entity:AddFollower()
                golem.Follower:FollowSymbol(player.GUID, player.components.debuffable.followsymbol, 0, -200, 0)
            end

            local function SpawnCuteGolem(player)
                local cutegolem = SpawnPrefab("golem")
                
                cutegolem.components.health:SetMaxHealth(500)
                cutegolem.acidimmune = true
                cutegolem.components.combat:SetRange(25)
                local function UpdateProjectileRange(weapon, caster, target, projectile)
                    projectile.components.projectile:SetRange(25)
                    projectile.components.projectile:SetSpeed(50)
                end
                cutegolem.weapon.components.weapon:SetOnProjectileLaunched(UpdateProjectileRange)
                cutegolem.weapon.components.weapon:SetProjectile("forge_fireball_projectile_big")
                cutegolem:DoTaskInTime(2*_G.FRAMES, function()
                    _G.RemoveTask(cutegolem, "death_timer")
                end)
                cutegolem.components.buffable:AddBuff("golem_size", {{name = "scaler", type = "mult", val = 0.5}})
                cutegolem.components.scaler:ApplyScale()

                golemprefab = cutegolem
                FollowLeader(cutegolem, player)
            end

            local function KillGolem(golem)
                if not golem.components.health:IsDead() then
                    golem.components.health:Kill()
                end
            end

            for _,player in pairs(AllPlayers) do
                if(player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == ent) then                
                    SpawnCuteGolem(player)
                end
            end
            ent:ListenForEvent("unequipped", function(inst, data)
                if data.owner then
                    KillGolem(golemprefab)
                end
            end)
            ent:ListenForEvent("equipped", function(inst, data)
                if data.owner then
                    SpawnCuteGolem(data.owner)
                end
            end)
        end
    end

end

local function ChangeSmallWeaponStat()
    local pos = Vector3(0,0,0)
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, 999, {"_inventoryitem"})

    for _,ent in pairs(ents) do

        --MELEE--
        if ent.prefab == "forginghammer" then
            local randomHP = math.random(50,75)
            ent._HP:set(randomHP)


            for _,player in pairs(AllPlayers) do
                if(player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == ent) then
                    player.components.health:AddHealthBuff(ent.prefab, randomHP, "flat")
                end
            end

            ent:ListenForEvent("unequipped", function(inst, data)
                if data.owner then
                    data.owner.components.health:RemoveHealthBuff(inst.prefab, "flat")
                end
            end)
            ent:ListenForEvent("equipped", function(inst, data)
                if data.owner then
                    data.owner.components.health:AddHealthBuff(inst.prefab, randomHP, "flat")
                end
            end)
            
        end

        if ent.prefab == "teleport_staff" then
            local randomdamage = math.random(5,10) 
            ent._damage:set(randomdamage)

            ent.components.weapon:SetDamage(TUNING.FORGE.TELEPORT_STAFF.DAMAGE + randomdamage)
	    end

        if ent.prefab == "riledlucy" then
            local randomspeed = 1
            ent._speed:set(randomspeed)

            ent.components.equippable.walkspeedmult = tonumber(string.format("1.%d",randomspeed ))
	    end

        if ent.prefab == "pithpike" then
            local randomdamage = math.random(5,10) 
            ent._damage:set(randomdamage)

            ent.components.weapon:SetDamage(TUNING.FORGE.MOLTENDARTS.DAMAGE + randomdamage)
            ent.components.weapon:SetAltAttack(TUNING.FORGE.MOLTENDARTS.ALT_DAMAGE + randomdamage)
	    end


        --DART--

        if ent.prefab == "forgedarts" then
            local randomdamage = math.random(5,10) 
            ent._damage:set(randomdamage)

            ent.components.weapon:SetDamage(TUNING.FORGE.FORGEDARTS.DAMAGE + randomdamage)
            ent.components.weapon:SetAltAttack(TUNING.FORGE.FORGEDARTS.ALT_DAMAGE + randomdamage)
        end

        if ent.prefab == "moltendarts" then
            local randomdamage = math.random(5,10) 
            ent._damage:set(randomdamage)

            ent.components.weapon:SetDamage(TUNING.FORGE.MOLTENDARTS.DAMAGE + randomdamage)
            ent.components.weapon:SetAltAttack(TUNING.FORGE.MOLTENDARTS.ALT_DAMAGE + randomdamage)
        end

        if ent.prefab == "firebomb" then
            local randomdamage = math.random(5,10) 
            ent._damage:set(randomdamage)

            ent.components.weapon:SetDamage(TUNING.FORGE.MOLTENDARTS.DAMAGE + randomdamage)
            ent.components.weapon:SetAltAttack(TUNING.FORGE.MOLTENDARTS.ALT_DAMAGE + randomdamage)
	    end

        if ent.prefab == "lavaarena_seeddarts" then
            local randomdamage = math.random(5,10) 
            ent._damage:set(randomdamage)

            ent.components.weapon:SetDamage(TUNING.FORGE.MOLTENDARTS.DAMAGE + randomdamage)
            ent.components.weapon:SetAltAttack(TUNING.FORGE.MOLTENDARTS.ALT_DAMAGE + randomdamage)
	    end


        --STAFF--

        if ent.prefab == "livingstaff" then
            local randomhealrate = math.random(1,2) 
            ent._healrate:set(randomhealrate)

            ent.heal_rate = TUNING.FORGE.LIVINGSTAFF.HEAL_RATE + randomhealrate
        end


        --BOOK--

        if ent.prefab == "bacontome" then
            local randomspeed = 1
            ent._speed:set(randomspeed)

            ent.components.equippable.walkspeedmult = tonumber(string.format("1.%d",randomspeed ))
        end

        if ent.prefab == "petrifyingtome" then
            local randomspeed = 1
            ent._speed:set(randomspeed)

            ent.components.equippable.walkspeedmult = tonumber(string.format("1.%d",randomspeed ))
        end
    end
end

----------------
-- ITEM DROPS --
----------------

local item_drops = {
    [1] = {
        [1] = {
            final_mob = {"barbedhelm","crystaltiara","jaggedarmor","silkenarmor","featheredwreath","splintmail","flowerheadband","wovengarland"}
        },
    },
    [2] = {
        [1] = {
            final_mob = {"noxhelm","steadfastarmor","jaggedgrandarmor","silkengrandarmor","whisperinggrandarmor","infernalstaff","blacksmithsedge"}
        },
    },
    [3] = {
        [1] = {
            final_mob = {"resplendentnoxhelm", "blossomedwreath","clairvoyantcrown","jaggedgrandarmor","silkengrandarmor","steadfastgrandarmor"},
        },
    },
}

local character_tier_opts = {
    [1] = {round = 1},
    [2] = {round = 2},
    [3] = {round = 3, force_items = {"moltendarts"}},

}
local heal_opts = {
    dupe_rate = 0.2,
    drops = {
        heal = {round = 1, wave = 1, type = "final_mob", force_items = {"livingstaff"}}
    },
}



------------------
-- WAVESET DATA --
------------------
local function GenerateWavesetData(waveset_data)
    waveset_data[1].waves[1]=MakeSetSpawn(1)
    waveset_data[2].waves[1]=MakeSetSpawn(2)
    waveset_data[3].waves[1]=MakeSetSpawn(3)
    waveset_data[3].waves[2]=MakeSetSpawn(4)
    waveset_data[4].waves[1]=MakeSetSpawn(5)
    waveset_data[5].waves[1]=MakeSetSpawn(6)
    waveset_data[5].waves[2]=MakeSetSpawn(7)
end

--WAVESET DATA--

local waveset_data={
    endgame_speech={victory={speech="REFORGED.DIALOGUE.Random.BOARLORD_PLAYER_VICTORY"},defeat={speech="REFORGED.DIALOGUE.Random.BOARLORD_PLAYERS_DEFEATED_BATTLECRY"}}
}



waveset_data[1]={
    waves={},
    wavemanager={
        dialogue={
            [1] = {speech = function(lavaarenaevent)
                local forge_lord = lavaarenaevent:GetForgeLord()
				local throne_pos = forge_lord:GetThronePosition()
				local portal_pos = TheWorld.multiplayerportal and TheWorld.multiplayerportal:GetPosition() or _G.Vector3(0,0,0)
                local time = 0    
                
                --[[
                TheWorld:ListenForEvent("answer_yes",function(world, data)
                    print("yes")w
                end)

                TheWorld:ListenForEvent("answer_no",function(world, data)
                    print("no")
                end)
                
                local this_user = _G.TheNet:GetClientTableForUser(_G.TheNet:GetUserID())
                local UserCommands = require "usercommands"
                print(this_user)
                UserCommands.RunUserCommand("lobbyvotestart", {command = "the_choice", force_success = "false"}, this_user)
                ]]--
                
                forge_lord.Transform:SetPosition(portal_pos:Get())
                lavaarenaevent:DoSpeech("REFORGED.DIALOGUE.Random.BOARLORD_ROUND1_START_1", nil, nil, nil, nil, nil, function()
                    COMMON_FNS.DropItem(forge_lord:GetPosition(), "moltendarts")
                    COMMON_FNS.DropItem(forge_lord:GetPosition(), "firebomb")
                    COMMON_FNS.DropItem(forge_lord:GetPosition(), "bacontome")
                    COMMON_FNS.DropItem(forge_lord:GetPosition(), "forginghammer")
                    TheWorld:DoTaskInTime(1, function()
                        lavaarenaevent:DoSpeech("REFORGED.DIALOGUE.Random.BOARLORD_ROUND1_START_2")
                    end)
                end,true)

            end},
        },
        onspawningfinished={},
    }
}

waveset_data[1].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)

    

    TheWorld:DoTaskInTime(0.1, function()
        for _,player in pairs(AllPlayers) do
                player:RemoveTag("NOCLICK")
        end
        
    end)
end

waveset_data[2]={
    waves={},
    wavemanager={
        dialogue={
            [1] = {speech = function(lavaarenaevent)
                local forge_lord = lavaarenaevent:GetForgeLord()

                lavaarenaevent:DoSpeech("REFORGED.DIALOGUE.Random.BOARLORD_ROUND2_START_1", nil, nil, nil, nil, nil, function()
                    forge_lord:Work()

                    TheWorld:DoTaskInTime(3, function()
                        ChangeSmallWeaponStat()
                        lavaarenaevent:DoSpeech("REFORGED.DIALOGUE.Random.BOARLORD_ROUND2_START_2")
                    end)

                end,true)

            end},
        },
        onspawningfinished={},
    }
}

waveset_data[2].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)

    TheWorld:DoTaskInTime(0.1, function()
        for _,player in pairs(AllPlayers) do
            player:RemoveTag("NOCLICK")
        end
        
    end)
end

waveset_data[3]={
    waves={},
    wavemanager={
        dialogue={
            [1] = {speech = function(lavaarenaevent)
                local forge_lord = lavaarenaevent:GetForgeLord()

                lavaarenaevent:DoSpeech("REFORGED.DIALOGUE.Random.BOARLORD_ROUND3_START_1", nil, nil, nil, nil, nil, function()
                    forge_lord:Work()
                    TheWorld:DoTaskInTime(3, function()
                        ChangeWeaponStat()
                        lavaarenaevent:DoSpeech("REFORGED.DIALOGUE.Random.BOARLORD_ROUND3_START_2")
                    end)
                end,true)
            end},
            [2] = {speech = function(lavaarenaevent)
                local forge_lord = lavaarenaevent:GetForgeLord()

                lavaarenaevent:DoSpeech("REFORGED.DIALOGUE.Random.BOARLORD_ROUND3_START_REINFORCE")

            end},
        },
        onspawningfinished={},
    }
}

waveset_data[3].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)
    self.timers.queue_next_wave = self.inst:DoTaskInTime(15, function()
		self:QueueWave(2)
	end)


    TheWorld:DoTaskInTime(0.1, function()

        for _,player in pairs(AllPlayers) do
            player:RemoveTag("NOCLICK")
        end
        
    end)
end

waveset_data[4]={
    waves={},
    wavemanager={
        dialogue={
            [1] = {speech = function(lavaarenaevent)
                local forge_lord = lavaarenaevent:GetForgeLord()

                lavaarenaevent:DoSpeech("REFORGED.DIALOGUE.Random.BOARLORD_ROUND4_START")

            end},
        },
        onspawningfinished={},
    }
}

waveset_data[4].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)

    TheWorld:DoTaskInTime(0.1, function()
        for _,player in pairs(AllPlayers) do
            player:RemoveTag("NOCLICK")
        end
        
    end)

    for i,moblist in pairs(spawnedmobs) do 
        for mob in pairs(moblist) do 

            if mob.prefab=="boarrior" then 
                mob.components.locomotor.walkspeed = mob.components.locomotor.walkspeed * 2
                mob:AddTag("nosleep")
                SetPresetHue(mob,"black")
                if ishard then
                    mob:SetStateGraph("SGrandomboarrior_hard")
                else                   
                    mob:SetStateGraph("SGpitpig_hards")
                end

            end

        end
    end
end

waveset_data[5]={
    waves={},
    wavemanager={
        dialogue={
            [1] = {speech = function(lavaarenaevent)
                local forge_lord = lavaarenaevent:GetForgeLord()

                lavaarenaevent:DoSpeech("REFORGED.DIALOGUE.Random.BOARLORD_ROUND5_START_1")

            end},
            [2] = {speech = function(lavaarenaevent)
                local forge_lord = lavaarenaevent:GetForgeLord()

                lavaarenaevent:DoSpeech("REFORGED.DIALOGUE.Random.BOARLORD_ROUND5_START_MIDBOSS")

            end},
        },
        onspawningfinished={},
    }
}

waveset_data[5].wavemanager.onspawningfinished[1]=function(self,spawnedmobs)

    TheWorld:DoTaskInTime(0.1, function()

        for _,player in pairs(AllPlayers) do
            player:RemoveTag("NOCLICK")
        end
        
    end)

    for i,moblist in pairs(spawnedmobs) do 
        for mob in pairs(moblist) do 

            if mob.prefab == "swineclops" then
                mob.components.locomotor.walkspeed = mob.components.locomotor.walkspeed * 2.5
                mob.components.locomotor.runspeed = mob.components.locomotor.runspeed * 1.5

                SetPresetHue(mob,"red")
                mob:SetStateGraph("SGrandom_swineclops")

                local function SpawnAllTurtle()
                    mob.sg.mem.wants_to_spawnAlltrutle = true
                end

                local swine = _W.OrganizeAllMobs(spawnedmobs).swineclops
                local sw=#swine
                self.health_triggers.swine = {
                    [1]={total_percent=sw*0.75,fn=function()
                        SpawnAllTurtle()
                    end},
                    [2]={total_percent=sw*0.5,fn=function()
                        self:QueueWave(2)
                    end},
                    [3]={total_percent=sw*0.25,fn=function()
                        SpawnAllTurtle()
                    end},
                }
                _W.AddHealthTriggers(self.health_triggers.swine, unpack(swine))

                local function SpawnTrutle()
                    mob.sg.mem.wants_to_spawntrutle = true
                    mob:DoTaskInTime(50, function()
                        SpawnTrutle()
                    end)
                end

                mob:DoTaskInTime(5, function()
                    SpawnTrutle()
                end)
            end

        end
    end
end

waveset_data.item_drops=item_drops
    waveset_data.item_drop_options={
        character_tier_opts=character_tier_opts,
        heal_opts=heal_opts,
        generate_item_drop_list_fn=_W.GenerateItemDropList
    }

GenerateWavesetData(waveset_data)

return waveset_data

