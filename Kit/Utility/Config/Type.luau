--!strict

-- inspo: https://github.com/osyrisrblx/t/

local Type = {}

local function makeType(type): any
	return { type = type }
end

Type.none = makeType("none") :: never
Type.any = makeType("any") :: any?

Type.string = makeType("string") :: string?
Type.boolean = makeType("boolean") :: boolean?
Type.number = makeType("number") :: number?
Type.UDim = makeType("UDim") :: UDim?
Type.UDim2 = makeType("UDim2") :: UDim2?
Type.BrickColor = makeType("BrickColor") :: BrickColor?
Type.Color3 = makeType("Color3") :: Color3?
Type.Vector2 = makeType("Vector2") :: Vector2?
Type.Vector3 = makeType("Vector3") :: Vector3?
Type.NumberSequence = makeType("NumberSequence") :: NumberSequence?
Type.ColorSequence = makeType("ColorSequence") :: ColorSequence?
Type.NumberRange = makeType("NumberRange") :: NumberRange?
Type.Rect = makeType("Rect") :: Rect?
Type.Font = makeType("Font") :: Font?
Type.CFrame = makeType("CFrame") :: CFrame?

Type.Literal = function<V>(v: V): V?
	return { type = "literal", value = v } :: any
end

Type.Some = function(...): any?
	return { type = "some", value = table.pack(...) } :: any
end

Type.Enum = function<T>(enum: T & EnumItem): T
	return {
		type = "EnumItem",
		ignoreType = true,
		check = function(value: EnumItem): (boolean, string?)
			local valueType = typeof(value)
			local check = valueType == "EnumItem" and value.EnumType == enum.EnumType
			if not check then
				return check,
					`Enum.{enum.EnumType} expected, got {if valueType == "EnumItem"
						then `Enum.{value.EnumType}`
						else valueType}`
			end
			return check
		end,
		checkFailedProcessor = function()
			return enum
		end,
	} :: any
end

Type.integer = (
	{
		type = "number",
		check = function(value: number): (boolean, string?)
			local check = value % 1 == 0
			if not check then
				return check, `integer expected, got {value}`
			end
			return check
		end,
		checkFailedProcessor = function(value)
			return math.round(value)
		end,
	} :: any
) :: number?

Type.minNumber = function(min: number): number?
	return {
		type = "number",
		check = function(value: number): (boolean, string?)
			local check = value >= min
			if not check then
				return check, `number >= {min} expected, got {value}`
			end
			return check
		end,
		checkFailedProcessor = function(value: number)
			return math.max(min, value)
		end,
	} :: any
end

Type.maxNumber = function(max: number): number?
	return {
		type = "number",
		check = function(value: number): (boolean, string?)
			local check = value <= max
			if not check then
				return check, `number <= {max} expected, got {value}`
			end
			return check
		end,
		checkFailedProcessor = function(value: number)
			return math.min(max, value)
		end,
	} :: any
end

Type.minNumberExclusive = function(min: number): number?
	return {
		type = "number",
		check = function(value: number): (boolean, string?)
			local check = value > min
			if not check then
				return check, `number > {min} expected, got {value}`
			end
			return check
		end,
		checkFailedProcessor = function(value: number)
			return math.max(min + 1, value)
		end,
	} :: any
end

Type.maxNumberExclusive = function(max: number): number?
	return {
		type = "number",
		check = function(value: number): (boolean, string?)
			local check = value < max
			if not check then
				return check, `number < {max} expected, got {value}`
			end
			return check
		end,
		checkFailedProcessor = function(value: number)
			return math.min(max - 1, value)
		end,
	} :: any
end

Type.constrainedNumber = function(min: number, max: number): number?
	return {
		type = "number",
		check = function(value: number): (boolean, string?)
			local check = value >= min and value <= max
			if not check then
				return check, `{max} >= number >= {min} expected, got {value}`
			end
			return check
		end,
		checkFailedProcessor = function(value: number)
			return math.clamp(value, min, max)
		end,
	} :: any
end

Type.constrainedNumberExclusive = function(min: number, max: number): number?
	return {
		type = "number",
		check = function(value: number): (boolean, string?)
			local check = value > min and value < max
			if not check then
				return check, `{max} > number > {min} expected, got {value}`
			end
			return check
		end,
		checkFailedProcessor = function(value: number)
			return math.clamp(value, min + 1, max - 1)
		end,
	} :: any
end

Type.stringMatches = function(pattern: string): string?
	return {
		type = "string",
		check = function(value: string): (boolean, string?)
			local check = value:match(pattern) ~= nil
			if not check then
				return check, `"{value}" failed to match pattern "{pattern}"`
			end
			return check
		end,
		processor = function(value: string)
			return value:match(pattern)
		end,
	} :: any
end

return table.freeze(Type)
