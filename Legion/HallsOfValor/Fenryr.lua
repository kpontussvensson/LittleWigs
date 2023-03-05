--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Fenryr", 1477, 1487)
if not mod then return end
mod:RegisterEnableMob(95674, 99868) -- Phase 1 Fenryr, Phase 2 Fenryr
mod:SetEncounterID(1807)
mod:SetRespawnTime(30)
mod:SetStage(1)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		196543, -- Unnerving Howl
		{197556, "SAY", "PROXIMITY"}, -- Ravenous Leap
		196512, -- Claw Frenzy
		{196838, "SAY", "ICON"}, -- Scent of Blood
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Stealth", 196567)
	self:Log("SPELL_CAST_START", "UnnervingHowl", 196543)
	self:Log("SPELL_CAST_START", "RavenousLeap", 197558)
	self:Log("SPELL_AURA_APPLIED", "RavenousLeapApplied", 197556)
	self:Log("SPELL_AURA_REMOVED", "RavenousLeapRemoved", 197556)
	self:Log("SPELL_CAST_SUCCESS", "ClawFrenzy", 196512)
	self:Log("SPELL_CAST_START", "ScentOfBlood", 196838)
	self:Log("SPELL_AURA_REMOVED", "ScentOfBloodRemoved", 196838)
end

function mod:OnEngage()
	--self:CDBar(196543, 4.5) -- Unnerving Howl
	--self:CDBar(197556, 9.5) -- Ravenous Leap
	--self:CDBar(196838, 20) -- Scent of Blood
	if self:GetBossId(95674) then -- Stage 1 Fenryr
		self:RegisterEvent("ENCOUNTER_END")
		self:SetStage(1)
	elseif self:GetBossId(99868) then -- Stage 2 Fenryr
		self:SetStage(2)
	else
		-- sometimes boss frames are slow
		self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:INSTANCE_ENCOUNTER_ENGAGE_UNIT(event)
	if self:GetBossId(95674) then -- Stage 1 Fenryr
		self:RegisterEvent("ENCOUNTER_END")
		self:SetStage(1)
	elseif self:GetBossId(99868) then -- Stage 2 Fenryr
		self:SetStage(2)
	end
	-- restore listener
	self:RegisterEvent(event, "CheckBossStatus")
end

do
	local stealthed = false

	function mod:ENCOUNTER_END(_, engageId, _, _, _, status)
		if engageId == self.engageId then
			stealthed = false
			if status == 0 then
				-- wait some seconds to see if Fenryr stealths
				self:ScheduleTimer("CheckForStealth", 2)
			else
				self:Win()
			end
		end
	end

	function mod:Stealth()
		stealthed = true
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:Reboot()
	end

	function mod:CheckForStealth()
		if not stealthed then
			self:Wipe()
			-- force a respawn timer
			self:SendMessage("BigWigs_EncounterEnd", self, self.engageId, self.displayName, self:Difficulty(), 5, 0)
		end
	end
end

function mod:UnnervingHowl(args)
	self:Message(args.spellId, "orange", CL.casting:format(args.spellName))
	self:PlaySound(args.spellId, "alert")
	self:CDBar(args.spellId, 28)
	if self:MobId(args.sourceGUID) == 95674 then -- Stage 1
		self:CDBar(196512, {4.9, 9.7}) -- Claw Frenzy
	end
end

do
	local playerList = {}

	function mod:RavenousLeap(args)
		playerList = {}
		self:CDBar(197556, 31.7)
	end

	function mod:RavenousLeapApplied(args)
		playerList[#playerList + 1] = args.destName
		self:TargetsMessage(args.spellId, "yellow", playerList, 4)
		self:PlaySound(args.spellId, "alert", nil, playerList)
		if self:Me(args.destGUID) then
			self:OpenProximity(args.spellId, 10)
			self:Say(args.spellId)
		end
	end

	function mod:RavenousLeapRemoved(args)
		if self:Me(args.destGUID) then
			self:CloseProximity(args.spellId)
		end
	end
end

function mod:ClawFrenzy(args)
	self:Message(args.spellId, "red")
	if self:MobId(args.sourceGUID) == 95674 then -- Stage 1
		self:CDBar(args.spellId, 9.7)
	end
end

do
	local function printTarget(self, name, guid)
		self:PrimaryIcon(196838, name)
		self:TargetMessage(196838, "orange", name)
		if self:Me(guid) then
			self:Say(196838)
			self:PlaySound(196838, "warning")
		end
	end

	function mod:ScentOfBlood(args)
		self:GetBossTarget(printTarget, 0.4, args.sourceGUID)
		self:CDBar(args.spellId, 34)
	end

	function mod:ScentOfBloodRemoved(args)
		self:PrimaryIcon(args.spellId)
	end
end
