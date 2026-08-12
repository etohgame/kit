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
local tableUtil = require(ReplicatedStorage.Framework.Kit.Utility.Table)
local mergeTable = tableUtil.Merge

type PropertyMethods = HierarchyMethods & {
	Property: <Self>(self: Self, property: string) -> any,
	Event: <Self>(self: Self, event: string) -> RBXScriptSignal,
}

export type Evaluator = {
	Tagged: (objectTag: string) -> PropertyMethods,
	Changer: () -> PropertyMethods,
	Instance: () -> PropertyMethods,
	Character: () -> PropertyMethods,
	Toucher: () -> PropertyMethods,
	SequenceInstance: (variable: "TouchingPart" | "ActivatingPart" | string) -> PropertyMethods,

	Value: ((value: "PlayerName") -> string)
		& ((value: "PlayerDisplayName") -> string)
		& ((value: "UserId") -> number)
		& ((value: "Distance", position: Vector3) -> number)
		& ((value: "CharacterPosition") -> Vector3)
		& ((value: "CharacterCFrame") -> CFrame)
		& ((value: "PlayerHealth") -> number)
		& ((value: "CameraCFrame") -> CFrame)
		& ((value: "ViewportSize") -> Vector2)
		& ((value: "HumanoidState") -> Enum.HumanoidStateType)
		& ((value: "FormatTimer", text: string, decimalPlaces: number, timer: number) -> string)
		& ((value: "SequenceVariable", variable: string) -> any)
		& ((value: "MoveVector") -> Vector3)
		& ((value: "IsShiftLocked", checkFirstPerson: boolean?) -> boolean)
		& ((value: "IsJumping") -> boolean)
		& ((value: "IsKeyDown", key: string | Enum.KeyCode) -> boolean)
		& ((value: "PreferredInput") -> Enum.PreferredInput),
	Event: ("JumpRequest") -> RBXScriptSignal,
}

export type ChangerData = {
	id: string,
	scope: _T.Scope,
	selectedVariables: { [string]: any }?,
	selectedInstance: Instance?,
	touchingPart: BasePart?,
	changer: BasePart,
	silenced: boolean,
	instanceHashMap: {
		hashed: { [Instance]: string },
		map: { [string]: Instance? },
		destroy: { any },
	},
}

type InstanceFormat =
	{ toucher: boolean, [string]: any }
	| { changer: boolean, [string]: any }
	| { character: boolean, [string]: any }
	| { tag: string, [string]: any }
	| { variable: string, [string]: any }

export type Format = {
	[number]: {
		Instance: InstanceFormat,
		Condition: ((_E: Evaluator) -> boolean)?,
		BlockCondition: ((_E: Evaluator) -> boolean)?,
		Tween: TweenInfo?,
		[string]: ((_E: Evaluator) -> any) | any,
	},
}

export type CheckerFormat = {
	[number]: {
		Instance: InstanceFormat,
		Condition: ((_E: Evaluator) -> boolean)?,
		Event: ((_E: Evaluator) -> RBXScriptSignal)?,
		BlockCondition: ((_E: Evaluator) -> boolean)?,
		[string]: never,
	},
}

export type Cache = {
	registered: { [string]: ChangerData? },
	tagged: { [string]: { Instance } },
	getTagged: (tag: string) -> { Instance },
	filter: (instance: Instance) -> boolean,
	changers: {
		[BasePart]: {
			forceAwait: boolean,
			change: (touchingPart: BasePart?, variables: { [string]: any }) -> (),
		},
	},

	resolveHierarchy: (instance: Instance?, hierarchy: { { [string]: any } }?) -> (Instance | { Instance })?,
	propertyMethods: { [string]: any },
	evaluatorMetatable: { [string]: any },
	classMethodMap: { [string]: { class: string, method: (instance: any, value: any) -> () } },
}

local function getHierarchy(self: any): { { [string]: any } }
	if not self.hierarchy then
		self.hierarchy = {}
	end
	return self.hierarchy
end
local methods = {
	FindChild = function<Self>(self: Self, name: string): Self
		table.insert(getHierarchy(self), { name = name })
		return self
	end,

	FindDescendant = function<Self>(self: Self, name: string): Self
		table.insert(getHierarchy(self), { name = name, descendant = true })
		return self
	end,

	FindChildOfClass = function<Self>(self: Self, class: string): Self
		table.insert(getHierarchy(self), { class = class })
		return self
	end,

	FindDescendantOfClass = function<Self>(self: Self, class: string): Self
		table.insert(getHierarchy(self), { class = class, descendant = true })
		return self
	end,

	FindAncestor = function<Self>(self: Self, name: string): Self
		table.insert(getHierarchy(self), { ancestor = name })
		return self
	end,

	FindAncestorOfClass = function<Self>(self: Self, class: string): Self
		table.insert(getHierarchy(self), { classAncestor = class })
		return self
	end,

	Parent = function<Self>(self: Self): Self
		table.insert(getHierarchy(self), { parent = true })
		return self
	end,

	GetChildren = function<Self>(self: Self): any
		table.insert(getHierarchy(self), { children = true })
		return self
	end,

	GetDescendants = function<Self>(self: Self): any
		table.insert(getHierarchy(self), { descendants = true })
		return self
	end,
}
--methods.__index = methods
type HierarchyMethods = typeof(methods)

return {
	Tagged = function(tag: string)
		return mergeTable({ tag = tag }, methods)
	end,
	TagFromSequenceVariable = function(variable: string)
		return mergeTable({ variable = variable }, methods)
	end,
	Toucher = function()
		return mergeTable({ toucher = true }, methods)
	end,
	Changer = function()
		return mergeTable({ changer = true }, methods)
	end,
	Character = function()
		return mergeTable({ character = true }, methods)
	end,

	Methods = methods,
}
