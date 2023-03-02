for _, filename in ipairs{
    -- Global
    "General/Global/RAI_DeclareGlobal.lua",
    "General/Global/RAI_MakeRailAI.lua",
    "General/Global/RAI_DoModeConditions.lua",
    "General/Global/RAI_AimFunction",

    -- Hooks
    "General/Hooks/OnBotHit.lua",
    "General/Hooks/SamusAndAbilitylessBySpawner.lua",
    "General/Hooks/tracer.lua",
    "General/Hooks/LastHit.lua",

    -- Init

    "General/Init/ConsoleVars.lua",

    -- Main Code
    "General/maincode.lua",
} do
    dofile(filename)
end