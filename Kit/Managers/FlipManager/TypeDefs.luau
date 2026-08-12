--!strict
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

export type FlipManager = {
	--> BaseController
	Init: (self: FlipManager) -> FlipManager,
	__initialized: boolean,

	--> FlipManager
	TryFlip: (self: FlipManager) -> (),
	BindToFlip: (self: FlipManager, part: BasePart, callback: (rootPart: BasePart) -> ()) -> () -> (),
	__callbacks: { [BasePart]: { [any]: (rootPart: BasePart) -> () } },

	Binds: { Keyboard: Enum.KeyCode | Enum.UserInputType, Controller: Enum.KeyCode },
}

return nil
