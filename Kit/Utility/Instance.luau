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

local POINTER_TAG = "OBJ_POINTER"

--[=[
@class Instance
@client
A table of utility functions for working with Instances that can be used to speed up the process of writing repository scripts for client objects.

]=]
local InstanceUtil = { POINTER_TAG = POINTER_TAG }

--[=[
    @within Instance
    
    Returns whether the `object` is a module pointer. Module pointers are used
    for things such as module-based object configurations to help reduce
    memory usage when requiring them.
]=]
function InstanceUtil.isPointer(object: Instance?)
	return typeof(object) == "Instance" and object:HasTag(POINTER_TAG) and object:IsA("ObjectValue")
end

--[=[
    @within Instance
    
    If the given `object` is a pointer, this function will return it's value.
    Otherwise, it will just return the object that was passed in.
]=]
function InstanceUtil.getPointer(object: Instance?): Instance?
	if object and InstanceUtil.isPointer(object) and object:IsA("ObjectValue") then
		return object.Value
	end

	return object
end

return table.freeze(InstanceUtil)
