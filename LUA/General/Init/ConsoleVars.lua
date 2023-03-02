if CV_FindVar("botcycling") then
	return
end

CV_RegisterVar{
	name = "botcycling",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}--RAI_cyclingBots