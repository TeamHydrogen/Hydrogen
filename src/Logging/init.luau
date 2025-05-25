--[=[
	@class Log

	Created by railworks2, used with written permission.
]=]
local RunService = game:GetService("RunService")
local Promise = require(script.Parent.Packages.Promise)
local Log = {}

--[=[
	@type LogLevel "INFO" | "DEBUG" | "WARN" | "ERROR" | "FATAL"
	@within Log
]=]
type LogLevel = "INFO" | "DEBUG" | "WARN" | "ERROR" | "FATAL"

--[=[
	@interface Log.Config
	@within Log
	.LogLevel { Enabled: boolean, Command: function, Traceback?: boolean }

	| Log Level | Enabled | Traceback | Command |
	|---|---|---|---|
	| **DEBUG** | [RunMode](https://create.roblox.com/docs/reference/engine/classes/RunService#IsRunMode) only | Yes | print |
	| **INFO** | Yes | No | print |
	| **WARN** | Yes | Yes | warn |
	| **ERROR** | Yes | Yes | warn |
	| **FATAL** | Yes | Yes | **error** |

	_Be aware that __FATAL__ will terminate code execution and should only be used for errors that are unrecoverable._
]=]
Log.Config = {
	["DEBUG"] = {
		Enabled = RunService:IsRunMode(),
		Command = print,
		Traceback = true,
	},
	["INFO"] = {
		Enabled = true,
		Command = print,
	},
	["WARN"] = {
		Enabled = true,
		Command = warn,
		Traceback = true,
	},
	["ERROR"] = {
		Enabled = true,
		Command = warn,
		Traceback = true,
	},
	["FATAL"] = {
		Enabled = true,
		Command = error,
		Traceback = false,
	},
}

--[=[
	@within Log
	@param scriptLine string
	@return string -- scriptLine
	@private

	Removes ReplicatedStorage and ServerStorage from the provided scriptLine - Part output of debug.info(2, "sl")
]=]
local function cleanupScriptLine(scriptLine)
	for _, removeService in { "ReplicatedStorage.", "ServerStorage." } do
		scriptLine = string.gsub(scriptLine, removeService, "")
	end
	return scriptLine
end

--[=[
	@within Log
	@return nil | string
	@param debugTraceback string -- Multi line string outputn of debug.traceback()
	@private

	Takes the results from the provided debug.traceback() and more neatly formats it into a single multiline string.

	Removing results from areas that are from core scripts (This module, ModuleLoader, Root loading scripts)

	**Note:** Return can be nil if there is no traceback
]=]
local function cleanupTraceback(debugTraceback: string)
	local tracebackArray = {}
	local doNotShowLogsFromHere = { ".Log:", ".ClientCore:", ".ServerCore:", ".promise:" }

	for _, trackbackDetails in string.split(debugTraceback, "\n") do
		local acceptableItem = true

		if string.len(trackbackDetails) == 0 then
			acceptableItem = false
		else
			for _, item in doNotShowLogsFromHere do
				if string.find(trackbackDetails, item) then
					acceptableItem = false
					break
				end
			end
		end

		if acceptableItem then
			table.insert(tracebackArray, cleanupScriptLine(trackbackDetails) .. "\t")
		end
	end

	if tracebackArray == nil or #tracebackArray >= 0 then
		return
	end

	tracebackArray[#tracebackArray] = string.gsub(tracebackArray[#tracebackArray], "\n", "")
	return table.unpack(tracebackArray)
end

--[=[
	@within Log

	Creates a message to be logged. Everything uses this function.

	Example 1: 
	> [INFO][LOG] This is an example logging message - Shared.Log:111 - Client

	Example 2:
	
	> [ERROR][LOAD][ID: NotActive] Failed to start module TestModule due to the Active flag not being enabled - Shared.Log:111 - Server  
	> &nbsp;Data: {"testData"}   
	> &nbsp;Traceback: Shared.UILoad:62   
	> &nbsp;Server.Load:152
	
]=]
function Log.Message(
	config: {
		Level: LogLevel,
		LogCat: string,
		Message: string,
		LogRef: string?,
		ForceTraceback: boolean?,
	},
	...: any?
)
	local debugTraceback = debug.traceback()
	local scriptName, scriptLine = debug.info(2, "sl")
	local data = if ... then { ... } else nil

	Promise.new(function()
		if Log.Config[config.Level] and Log.Config[config.Level].Enabled == true then
			local startOfMessage = `[{config.Level}][{string.upper(config.LogCat) or "NOCAT"}]`
			if config.LogRef ~= nil then
				startOfMessage ..= `[ID: {config.LogRef}]`
			end

			local endOfMessage = `- {cleanupScriptLine(scriptName)}:{scriptLine} - {if RunService:IsServer()
				then "Server"
				else "Client"}`
			if data ~= nil then
				print(data)
				endOfMessage ..= "\n\t\tData: " .. data
			end

			if
				(Log.Config[config.Level].Traceback == true or config.ForceTraceback == true)
				and cleanupTraceback(debugTraceback) ~= nil
			then
				endOfMessage ..= "\n\t\tTraceback: " .. cleanupTraceback(debugTraceback)
			end

			Log.Config[config.Level].Command(`{startOfMessage} {config.Message} {endOfMessage}`)
		end
	end)
end

--[=[
	@within Log
	@return value | false
	Throws an error if the provided value is false or nil. If the assertion passes, it returns all values passed to it. See [#Message](#Message) for guidance.
]=]
function Log.assert(
	value: any,
	config: {
		Level: LogLevel,
		LogCat: string,
		LogRef: string?,
		Message: string,
		ForceTraceback: boolean?,
	}
)
	if not value then
		Log.Message({
			Level = "ERROR",
			LogCat = config.LogCat,
			Message = config.Message,
			LogRef = config.LogRef,
			ForceTraceback = config.ForceTraceback,
		})
		return false
	end
	return value
end

return Log
