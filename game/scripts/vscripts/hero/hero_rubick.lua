

CreateEmptyTalents("rubick")

imba_rubick_telekinesis_land = class({})

function imba_rubick_telekinesis_land:IsHiddenWhenStolen() 		return false end
function imba_rubick_telekinesis_land:IsRefreshable() 			return true end
function imba_rubick_telekinesis_land:IsStealable() 			return false end
function imba_rubick_telekinesis_land:IsNetherWardStealable()	return false end
function imba_rubick_telekinesis_land:GetAOERadius() return self:GetSpecialValueFor("landing_stun_radius") end
function imba_rubick_telekinesis_land:OnSpellStart()
	local buff = self:GetCaster():FindModifierByName("modifier_imba_telekinesis_range")
	local max_distance = buff:GetStackCount() == 1 and self:GetSpecialValueFor("ally_land_distance") or self:GetSpecialValueFor("enemy_land_distance")
	local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_rubick")
	if talent then
		max_distance = max_distance + talent:GetSpecialValueFor("value")
	end
	local target_buff = self:GetCaster():FindAbilityByName("imba_rubick_telekinesis").buff
	local pos
	if (self:GetCursorPosition() - target_buff:GetParent():GetAbsOrigin()):Length2D() > max_distance then
		pos = target_buff:GetParent():GetAbsOrigin() + (self:GetCursorPosition() - target_buff:GetParent():GetAbsOrigin()):Normalized() * max_distance
	else
		pos = self:GetCursorPosition()
	end
	target_buff.pos = GetGroundPosition(pos, nil)
	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
		self.pfx = nil
	end
	self.pfx = ParticleManager:CreateParticleForTeam("particles/econ/items/rubick/rubick_force_ambient/rubick_telekinesis_marker_force.vpcf", PATTACH_CUSTOMORIGIN, nil, self:GetCaster():GetTeamNumber())
	ParticleManager:SetParticleControl(self.pfx, 0, target_buff.pos)
	ParticleManager:SetParticleControl(self.pfx, 1, Vector(target_buff:GetRemainingTime() + 0.5, 0, 0))
	ParticleManager:SetParticleControl(self.pfx, 2, target_buff:GetParent():GetAbsOrigin())
end

imba_rubick_telekinesis = class({})

LinkLuaModifier("modifier_imba_telekinesis_range", "hero/hero_rubick", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_telekinesis_ally_lift", "hero/hero_rubick", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_telekinesis_enemy_lift", "hero/hero_rubick", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_telekinesis_start_motion", "hero/hero_rubick", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_telekinesis_end_motion", "hero/hero_rubick", LUA_MODIFIER_MOTION_NONE)

function imba_rubick_telekinesis:IsHiddenWhenStolen() 		return false end
function imba_rubick_telekinesis:IsRefreshable() 			return true end
function imba_rubick_telekinesis:IsStealable() 				return false end
function imba_rubick_telekinesis:IsNetherWardStealable()	return true end
function imba_rubick_telekinesis:GetIntrinsicModifierName() return "modifier_imba_telekinesis_range" end
function imba_rubick_telekinesis:GetCooldown(i) return self:GetCaster():GetModifierStackCount("modifier_imba_telekinesis_range", self:GetCaster()) == 1 and self:GetSpecialValueFor("ally_cooldown") or self:GetSpecialValueFor("enemy_cooldown") end

function imba_rubick_telekinesis:OnAbilityPhaseStart()
	if IsEnemy(self:GetCaster(), self:GetCursorTarget()) then
		self:GetCaster():FindModifierByName("modifier_imba_telekinesis_range"):SetStackCount(0)
	else
		self:GetCaster():FindModifierByName("modifier_imba_telekinesis_range"):SetStackCount(1)
	end
	return true
end

function imba_rubick_telekinesis:OnUpgrade()
	local ability = self:GetCaster():FindAbilityByName("imba_rubick_telekinesis_land")
	if ability then
		ability:SetLevel(1)
	end
end

function imba_rubick_telekinesis:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if IsEnemy(caster, target) and (target:TriggerSpellAbsorb(self) or target:TriggerSpellReflect(self)) then
		return
	end
	caster:EmitSound("Hero_Rubick.Telekinesis.Cast")
	target:EmitSound("Hero_Rubick.Telekinesis.Target")
	local buff_name = IsEnemy(caster, target) and "modifier_imba_telekinesis_enemy_lift" or "modifier_imba_telekinesis_ally_lift"
	local duration = IsEnemy(caster, target) and self:GetSpecialValueFor("enemy_lift_time") or self:GetSpecialValueFor("ally_lift_time")
	self.buff = target:AddNewModifier(caster, self, buff_name, {duration = duration})
end

modifier_imba_telekinesis_range = class({}) --stack 1 is ally 0 is enemy

function modifier_imba_telekinesis_range:IsDebuff()				return false end
function modifier_imba_telekinesis_range:IsHidden() 			return true end
function modifier_imba_telekinesis_range:IsPurgable() 			return false end
function modifier_imba_telekinesis_range:IsPurgeException() 	return false end

modifier_imba_telekinesis_start_motion = class({})

function modifier_imba_telekinesis_start_motion:IsMotionController()return true end
function modifier_imba_telekinesis_start_motion:IsDebuff()			return false end
function modifier_imba_telekinesis_start_motion:IsHidden() 			return true end
function modifier_imba_telekinesis_start_motion:IsPurgable() 		return false end
function modifier_imba_telekinesis_start_motion:IsPurgeException() 	return false end
function modifier_imba_telekinesis_start_motion:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end
function modifier_imba_telekinesis_start_motion:DeclareFunctions() return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION} end
function modifier_imba_telekinesis_start_motion:GetOverrideAnimation() return ACT_DOTA_FLAIL end
function modifier_imba_telekinesis_start_motion:OnCreated()
	if IsServer() then
		self:CheckMotionControllers()
		self:StartIntervalThink(FrameTime())
	end
end

function modifier_imba_telekinesis_start_motion:OnIntervalThink()
	local height = 256
	local motion_progress = math.min(self:GetElapsedTime() / self:GetDuration(), 1.0) / 2
	local next_pos = GetGroundPosition(self:GetParent():GetAbsOrigin(), nil)
	next_pos.z = next_pos.z - 4 * height * motion_progress ^ 2 + 4 * height * motion_progress
	self:GetParent():SetAbsOrigin(next_pos)
end

modifier_imba_telekinesis_end_motion = class({})

function modifier_imba_telekinesis_end_motion:IsMotionController()	return true end
function modifier_imba_telekinesis_end_motion:IsDebuff()			return false end
function modifier_imba_telekinesis_end_motion:IsHidden() 			return true end
function modifier_imba_telekinesis_end_motion:IsPurgable() 			return false end
function modifier_imba_telekinesis_end_motion:IsPurgeException() 	return false end
function modifier_imba_telekinesis_end_motion:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end
function modifier_imba_telekinesis_end_motion:DeclareFunctions() return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION} end
function modifier_imba_telekinesis_end_motion:GetOverrideAnimation() return ACT_DOTA_FLAIL end
function modifier_imba_telekinesis_end_motion:OnCreated(keys)
	if IsServer() then
		self:CheckMotionControllers()
		self.startpos = self:GetParent():GetAbsOrigin()
		self.pos = Vector(keys.pos_x, keys.pos_y, keys.pos_z)
		self:OnIntervalThink()
		self:StartIntervalThink(FrameTime())
	end
end

function modifier_imba_telekinesis_end_motion:OnIntervalThink()
	local height = 256
	local distance = (self.startpos - self.pos):Length2D()
	local direction = (self.pos - self:GetParent():GetAbsOrigin()):Normalized()
	local speed = distance / self:GetDuration()
	local len = speed / (1.0 / FrameTime())
	local motion_progress = math.min(self:GetElapsedTime() / self:GetDuration(), 1.0) / 2 + 0.5
	local next_pos = GetGroundPosition(self:GetParent():GetAbsOrigin() + direction * len, nil)
	next_pos.z = next_pos.z - 4 * height * motion_progress ^ 2 + 4 * height * motion_progress
	self:GetParent():SetAbsOrigin(next_pos)
end

function modifier_imba_telekinesis_end_motion:OnDestroy()
	if IsServer() then
		self:GetParent():EmitSound("Hero_Rubick.Telekinesis.Target.Land")
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_rubick/rubick_telekinesis_land.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, self.pos)
		ParticleManager:ReleaseParticleIndex(pfx)
		local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self.pos, nil, self:GetAbility():GetSpecialValueFor("landing_stun_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(enemies) do
			if enemy ~= self:GetParent() then
				local damageTable = {
									victim = enemy,
									attacker = self:GetCaster(),
									damage = self:GetAbility():GetSpecialValueFor("landing_damage"),
									damage_type = self:GetAbility():GetAbilityDamageType(),
									damage_flags = DOTA_DAMAGE_FLAG_NONE, --Optional.
									ability = self:GetAbility(), --Optional.
									}
				ApplyDamage(damageTable)
				enemy:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_stunned", {duration = self:GetAbility():GetSpecialValueFor("landing_stun_duration")})
			end
		end
		FindClearSpaceForUnit(self:GetParent(), self.pos, true)
		GridNav:DestroyTreesAroundPoint(self.pos, self:GetAbility():GetSpecialValueFor("landing_stun_radius"), false)
		self.pos = nil
		self.startpos = nil
	end
end

modifier_imba_telekinesis_ally_lift = class({})

function modifier_imba_telekinesis_ally_lift:IsDebuff()				return false end
function modifier_imba_telekinesis_ally_lift:IsHidden() 			return false end
function modifier_imba_telekinesis_ally_lift:IsPurgable() 			return false end
function modifier_imba_telekinesis_ally_lift:IsPurgeException() 	return false end
function modifier_imba_telekinesis_ally_lift:DeclareFunctions() return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION} end
function modifier_imba_telekinesis_ally_lift:GetOverrideAnimation() return ACT_DOTA_FLAIL end
function modifier_imba_telekinesis_ally_lift:CheckState() return {[MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true} end

function modifier_imba_telekinesis_ally_lift:OnCreated()
	if IsServer() then
		self.pos = GetGroundPosition(self:GetParent():GetAbsOrigin(), nil)
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_telekinesis_start_motion", {duration = 0.2})
		self:GetCaster():SwapAbilities("imba_rubick_telekinesis", "imba_rubick_telekinesis_land", false, true)
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_rubick/rubick_telekinesis.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self:AddParticle(pfx, false, false, 15, false, false)
	end
end

function modifier_imba_telekinesis_ally_lift:OnDestroy()
	if IsServer() then
		self:GetParent():StopSound("Hero_Rubick.Telekinesis.Target")
		self:GetCaster():SwapAbilities("imba_rubick_telekinesis", "imba_rubick_telekinesis_land", true, false)
		local ability = self:GetCaster():FindAbilityByName("imba_rubick_telekinesis_land")
		if ability.pfx then
			ParticleManager:DestroyParticle(ability.pfx, false)
			ParticleManager:ReleaseParticleIndex(ability.pfx)
			ability.pfx = nil
		end
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_telekinesis_end_motion", {duration = 0.2, pos_x = self.pos.x, pos_y = self.pos.y, pos_z = self.pos.z})
		self.pos = nil
	end
end

modifier_imba_telekinesis_enemy_lift = class({})

function modifier_imba_telekinesis_enemy_lift:IsDebuff()			return false end
function modifier_imba_telekinesis_enemy_lift:IsHidden() 			return false end
function modifier_imba_telekinesis_enemy_lift:IsPurgable() 			return false end
function modifier_imba_telekinesis_enemy_lift:IsPurgeException() 	return false end
function modifier_imba_telekinesis_enemy_lift:DeclareFunctions() return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION} end
function modifier_imba_telekinesis_enemy_lift:GetOverrideAnimation() return ACT_DOTA_FLAIL end
function modifier_imba_telekinesis_enemy_lift:CheckState() return {[MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true} end

function modifier_imba_telekinesis_enemy_lift:OnCreated()
	if IsServer() then
		self.pos = GetGroundPosition(self:GetParent():GetAbsOrigin(), nil)
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_telekinesis_start_motion", {duration = 0.2})
		self:GetCaster():SwapAbilities("imba_rubick_telekinesis", "imba_rubick_telekinesis_land", false, true)
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_rubick/rubick_telekinesis.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		self:AddParticle(pfx, false, false, 15, false, false)
	end
end

function modifier_imba_telekinesis_enemy_lift:OnDestroy()
	if IsServer() then
		self:GetParent():StopSound("Hero_Rubick.Telekinesis.Target")
		self:GetCaster():SwapAbilities("imba_rubick_telekinesis", "imba_rubick_telekinesis_land", true, false)
		local ability = self:GetCaster():FindAbilityByName("imba_rubick_telekinesis_land")
		if ability.pfx then
			ParticleManager:DestroyParticle(ability.pfx, false)
			ParticleManager:ReleaseParticleIndex(ability.pfx)
			ability.pfx = nil
		end
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_telekinesis_end_motion", {duration = 0.2, pos_x = self.pos.x, pos_y = self.pos.y, pos_z = self.pos.z})
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_stunned", {duration = 0.2})
		self.pos = nil
	end
end



imba_rubick_spell_steal_buff = class({})

LinkLuaModifier("modifier_imba_spell_steal_buff", "hero/hero_rubick", LUA_MODIFIER_MOTION_NONE)

function imba_rubick_spell_steal_buff:IsTalentAbility() return true end
function imba_rubick_spell_steal_buff:GetIntrinsicModifierName() return "modifier_imba_spell_steal_buff" end

modifier_imba_spell_steal_buff = class({})

function modifier_imba_spell_steal_buff:IsDebuff()			return false end
function modifier_imba_spell_steal_buff:IsHidden() 			return true end
function modifier_imba_spell_steal_buff:IsPurgable() 		return false end
function modifier_imba_spell_steal_buff:IsPurgeException() 	return false end
function modifier_imba_spell_steal_buff:DeclareFunctions() return {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST} end
function modifier_imba_spell_steal_buff:OnAbilityFullyCast(keys)
	if not IsServer() or self:GetParent():IsIllusion() then
		return
	end
	if not self.talents then
		self.talents = {}
	end
	if keys.ability:GetAbilityName() == "rubick_spell_steal" then
		local target = keys.target
		local rubick = self:GetParent()
		for _, talent in pairs(self.talents) do
			rubick:RemoveAbility(talent:GetAbilityName())
		end
		for i=0, 23 do
			local talent = target:GetAbilityByIndex(i)
			if talent and (string.find(talent:GetAbilityName(), "special_bonus_imba") or string.find(talent:GetAbilityName(), "special_bonus_unique_")) and talent:GetLevel() > 0 then
				local ability = rubick:AddAbility(talent:GetAbilityName())
				ability:SetLevel(1)
				table.insert(self.talents, ability)
			end
		end
	end
end
		
