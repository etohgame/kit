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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

export type Button<Config> = {
	Button: BasePart,
	Configuration: Config,
	Color: Color3,
	ID: string,
	Pressed: BoolValue,
	TotalPresses: number,
	TimerFinished: BindableEvent,
}
export type ButtonCache<Tags, Config> = {
	ButtonActivatedPlatforms: { [BasePart]: Tags? },
	Buttons: { [Instance]: Button<Config>? },
}

return nil
