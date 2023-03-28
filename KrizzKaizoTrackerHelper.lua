local function KrizzKaizoTrackerHelper()
	local self = {}

	-- Define descriptive attributes of the custom extension that are displayed on the Tracker settings
	self.name = "Krizz's Kaizo Tracker Helper"
	self.author = "Krizz"
	self.description = "This extension helps the tracker work with Krizz's Kaizo IronMon Randomizer ROM. Must be enabled before talking to Mom. Set favorites in the streaming section of tracker."
	self.version = "0.2"
	self.url = "https://github.com/tehkrizz/IronMon-Tracker-Extension-KKTH"

	--Hard coded version check specific to Krizz's custom ROM
	self.verLoc = 0x08C99200 --RomCustom
	self.verCheck = 1263683930 --4B52495A

	--Abilities location
	self.abiLoc = 0x0203f468

	--Favorites location
	self.favLoc = self.abiLoc + 1648 --gFavorites C99254

	--If either of these values is nil, the extension will update the abilities table.
	self.updated = nil
	self.curTrainer = nil

	--If this and curTrainer are nil, the extension will update the favorites.
	self.updatedf = nil

	--Updates the tracker's ability table to use the randomized abilities
	local function updateAbilities()
		local memloc = self.abiLoc

		for i=1, PokemonData.totalPokemon, 1 do
			local ability2 = Utils.getbits(Memory.readword(memloc + (i * 4)), 0, 8)
			local ability1 = Utils.getbits(Memory.readword(memloc + (i * 4)), 8, 8)
			PokemonData.Pokemon[i].abilities[1] = ability1
			PokemonData.Pokemon[i].abilities[2] = ability2
		end
		print("Ability table updated.")
		
		self.updated = 1
	end

	--Uses the tracker's favorites to set the player's three favorites for initial mon selection
	local function updateFavorites()
		--favorites in memory
		local fav1 = Memory.readword(self.favLoc)
		local fav2 = Memory.readword(self.favLoc+2)
		local fav3 = Memory.readword(self.favLoc+4)

		--Get favorites from settings
		local optionfavs = Options["Startup favorites"]
		local newfav1, newfav2, newfav3 = string.match(optionfavs, "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
		newfav1 = tonumber(newfav1)
		newfav2 = tonumber(newfav2)
		newfav3 = tonumber(newfav3)

		--Update Memory
		Memory.writeword(self.favLoc,newfav1)
		local fav1 = Memory.readword(self.favLoc)
		Memory.writeword((self.favLoc+2),newfav2)
		local fav2 = Memory.readword(self.favLoc+2)
		Memory.writeword((self.favLoc+4),newfav3)
		local fav3 = Memory.readword(self.favLoc+4)

		print("Favorites applied.")
		self.updatedf = 1
	end

	-- Executed only once: When the extension is enabled by the user, and/or when the Tracker first starts up, after it loads all other required files and code
	function self.startup()
		if Memory.readdword(self.verLoc) ~= self.verCheck then
			print("KKTH - This is only compatible with Krizz's Kaizo FireRed ROM.")
			CustomCode.disableExtension("KrizzKaizoTrackerHelper")
			return
		else 
			print("KKTH - ROM is compatible.")
		end		
	end

	-- Executed only once: When the extension is disabled by the user, necessary to undo any customizations, if able
	function self.unload()
		--Makes sure the checkbox reflects disabled if disabled by compatibility check.
		SingleExtensionScreen.refreshButtons()
	end

	-- Executed once every 30 frames, after most data from game memory is read in
	function self.afterProgramDataUpdate()
		--Only work when in game.
		if not Program.isValidMapLocation() then
			return
		end
		--Trainer ID is tracked to allow it to run for a new game without a hard reset
		if self.curTrainer == nil or self.curTrainer ~= Tracker.Data.trainerID then
			self.updated = nil
			self.curTrainer = Tracker.Data.trainerID
		end
		--Proceed with extension once in game
		if self.updated == nil then
			updateAbilities()
			updateFavorites()
		end
	end

	return self
end
return KrizzKaizoTrackerHelper