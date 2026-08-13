SoundSystem = (
function()
    local this = {}

    this.enabled = false
    this.lastSound = nil
    this.disabledGroups = {}

    function this:init()
        Config.defaultValues[configDatabankMap.soundEnabled] = this.enabled
        Config.defaultValues[configDatabankMap.mutedSoundGroups] = {}
        EventSystem:register('ConfigDBChanged', this.applyConfig, this)
        this:applyConfig()
    end

    function this:applyConfig()
        this.enabled = Config:getValue(configDatabankMap.soundEnabled)
        -- Load muted from db
        this.disabledGroups = {}
        local muted = Config:getValue(configDatabankMap.mutedSoundGroups)
        for i,mutedGroup in pairs(muted) do
            this.disabledGroups[mutedGroup] = true
        end
    end

    function this:playSound(soundFile, override)
        if not this.enabled then return end
        if soundFile.group ~= nil and this.disabledGroups[soundFile.group] then return end
        if soundFile.file == nil then print('Invalid sound file') return end
        if system.isPlayingSound() == 0 then
            system.playSound(soundFile.file)
            this.lastSound = soundFile
        elseif override or (this.lastSound ~= nil and this.lastSound.priority <= soundFile.priority) then
            system.playSound(soundFile.file)
            this.lastSound = soundFile
        end
    end

    function this:toggleGroup(group, state)
        if state == nil then state = this.disabledGroups[group] == true end
        this.disabledGroups[group] = ternary(state, nil, true)
        Config:setValue(configDatabankMap.mutedSoundGroups, table.keys(this.disabledGroups))
    end

    return this
end
)()

SoundGroup = {
    menuSelect = 'ms',
    menuBack = 'mb',
    menuUpdown = 'ud',
    autopilotEnabled = 'ae',
    autopilotDisabled = 'ad',
    startup = 'st',
    destinationReached = 'dr',
    waypointReached = 'wr',
}

SoundFiles = {
    menuSelect = { file = 'SagaHUD/UI_Select.mp3', priority = 0, group = SoundGroup.menuSelect },
    menuBack = { file = 'SagaHUD/UI_Back.mp3', priority = 0, group = SoundGroup.menuBack },
    menuUpdown = { file = 'SagaHUD/UI_Switch.mp3', priority = 0, group = SoundGroup.menuUpdown },
    autopilotEnabled = { file = 'SagaHUD/AutopilotEnabled.mp3', priority = 1 },
    autopilotDisabled = { file = 'SagaHUD/AutopilotDisabled.mp3', priority = 1 },
    startup = { file = 'SagaHUD/Startup.mp3', priority = 1 },
    destinationReached = { file = 'SagaHUD/DestinationReached.mp3', priority = 2 },
    waypointReached = { file = 'SagaHUD/WaypointReached.mp3', priority = 1 },
}