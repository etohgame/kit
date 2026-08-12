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

export type Key = {
	instance: Model?,
	originalCFrame: CFrame,
	hitbox: BasePart,
	timerBillboard: typeof(script.Parent.KeyTimer),
	timerLabel: TextLabel,
	config: {
		ViewportOffset: CFrame,
		SpinSpeed: number,
		Timer: number,
		TimerText: string,
		TimerDecimalPlaces: number,
	},

	__private: {
		id: string,
		groupID: string,
		group: KeyGroup,
		isViewportDisplayed: boolean,
		targetCFrame: CFrame?,
		parent: Instance,
		active: boolean,
		cooldown: boolean,
		used: boolean,
		startTimer: number?,
		collectKey: (self: Key) -> (),
		returnKey: (self: Key) -> (),
		viewport: typeof(script.KeyViewport),
	}?,
}
export type KeyDoor = {
	instance: Model,
	hitbox: BasePart,
	doorParts: { [BasePart]: string? },
	doorSigns: { [TextLabel]: string },
	config: {
		RequiredKeys: number,
	},

	__private: {
		id: string,
		groupID: string,
		group: KeyGroup,
		unlocked: boolean,
		usedKeys: { string },
		unlockDoor: (self: KeyDoor) -> (),
		updateSigns: (self: KeyDoor) -> (),
		useKey: (self: KeyDoor, keyID: string) -> (),
	}?,
}
export type KeyGroup = {
	scope: any,
	id: string,
	keys: { [string]: Key },
	doors: { [string]: KeyDoor },
	addKey: (self: KeyGroup, Key) -> Key?,
	addDoor: (self: KeyGroup, KeyDoor) -> KeyDoor?,
}
export type Cache = {
	groups: { [string]: KeyGroup? },
	keys: { [string]: Key? },
	doors: { [string]: KeyDoor? },
	activeKeys: { string? },
	newGroup: (any) -> KeyGroup,
	id: string,
}

return nil
