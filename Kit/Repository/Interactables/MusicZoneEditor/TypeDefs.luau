--!strict
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 

PLEASE, **DO NOT** make any script edits to this script.
To make a script edit, please read the following:
https://etohgame.github.io/kit/docs/misc#writingediting-repository-scripts

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

export type PropertyTable = {[string]: any} | "Default"

export type ZoneConfiguration = {
	ZoneDisabled: boolean?,
	ZonePriority: number?,
	SoundConfiguration: PropertyTable?,
	EffectConfiguration: {[string]: PropertyTable}?,
	ExtraConfiguration: {[string]: any}?,
}

return nil