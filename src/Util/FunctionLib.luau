--!strict

local FunctionLib = {}
local suffixes = { "K", "M", "B", "T", "Qd", "Qn", "Se", "Sp", "Oc", "No", "Dc", "Udc", "Ddc", "Tdc" }

function FunctionLib:ToSuffixString(n)
	if n == 0 then
		return "0"
	end

	for i = #suffixes, 1, -1 do
		if i == 1 then
			continue
		end

		local v = math.pow(10, i * 3)

		if n >= v then
			return ("%.0f"):format(n / v) .. suffixes[i]
		end
	end
	return tostring(n)
end

function FunctionLib:FindPossibleStringsInString(String: string, Values: { string }): string?
	for _, Value in Values do
		if string.find(String, Value) then
			return Value
		end
	end

	return
end

function FunctionLib:FindStringsInTable(Strings: { string }, Values: { string }): boolean
	for _, String in Strings do
		if not table.find(Values, String) then
			return false
		end
	end

	return true
end

function FunctionLib:SecsToMins(Secs: number, FormatAsString: boolean?): { Mins: number, Secs: number } | string
	local TimeTable = {} :: { Mins: number, Secs: number }

	TimeTable.Mins = math.floor(Secs / 60)
	TimeTable.Secs = Secs % 60

	if not FormatAsString then
		return TimeTable
	end

	local ReturnString = `{TimeTable.Mins}:{TimeTable.Secs}`

	if TimeTable.Mins == 0 then
		ReturnString = `{TimeTable.Secs}s`
	end

	return ReturnString
end

function FunctionLib:FindFirstDescendant(Object: Instance, Name: string)
	local ChildToReturn

	for _, Child in Object:GetDescendants() do
		if Child.Name == Name then
			ChildToReturn = Child
		end
	end

	return ChildToReturn
end

function FunctionLib:ToScientificNotation(N: number): string
	local b = math.floor(math.log(N, 10))
	local a = N / (10 ^ b)

	local notation = `{a}e{b}`

	return notation
end

function FunctionLib:ToRegularNumber(N: string): number
	local Split = string.split(N, "e") :: { string }

	local Num1 = tonumber(Split[1]) :: number
	local Num2 = tonumber(Split[2]) :: number

	if string.sub(Split[2], 1, 1) == "+" then
		Num2 = tonumber(string.sub(Split[2], 2, string.len(Split[2]))) :: number
	end

	return Num1 * (10 ^ Num2)
end

function FunctionLib:CheckIfPartIsPlayer(Hit: BasePart): boolean
	local Parent = Hit.Parent :: BasePart

	if not Parent then
		return false
	end

	if not Parent:FindFirstChildOfClass("Humanoid") then
		return false
	end

	return true
end

return FunctionLib
