-- Variables
local Proxy = require(script.Parent.Proxy)
local Constructor, TaskManager, SynchronousTask, RunningTask = {}, {}, {}, {}
local Run

-- Types
export type Constructor = {
	new: () -> TaskManager,
}

export type TaskManager = {
	[any]: any,
	Enabled: boolean,
	Tasks: number,
	Running: SynchronousTask?,
	InsertFront: (self: TaskManager, func: (RunningTask, ...any) -> (), ...any) -> SynchronousTask,
	InsertBack: (self: TaskManager, func: (RunningTask, ...any) -> (), ...any) -> SynchronousTask,
	FindFirst: (self: TaskManager, func: (RunningTask, ...any) -> ()) -> (SynchronousTask?, number?),
	FindLast: (self: TaskManager, func: (RunningTask, ...any) -> ()) -> (SynchronousTask?, number?),
	CancelAll: (self: TaskManager, func: (RunningTask, ...any) -> ()?) -> (),
}

export type SynchronousTask = {
	[any]: any,
	TaskManager: TaskManager?,
	Running: boolean,
	Wait: (self: SynchronousTask, ...any) -> ...any,
	Cancel: (self: SynchronousTask) -> (),
}

export type RunningTask = {
	Next: (self: RunningTask) -> (thread, ...any),
	Iterate: (self: RunningTask) -> ((self: RunningTask) -> (thread, ...any), RunningTask),
	End: (self: RunningTask) -> (),
}

-- Constructor
Constructor.new = function()
	local proxy, taskManager = Proxy.new(TaskManager, { Enabled = true, Tasks = 0 })
	taskManager.Active = false
	return proxy
end

-- TaskManager
TaskManager.__tostring = function()
	return "Task Manager"
end

TaskManager.__shared = {
	InsertFront = function(proxy, func, ...)
		local taskManager = getmetatable(proxy)
		if type(taskManager) ~= "table" or taskManager.__shared ~= TaskManager.__shared then
			error("Attempt to InsertFront failed: Passed value is not a Task Manager", 3)
		end
		if type(func) ~= "function" then
			error("Attempt to InsertFront failed: Passed value is not a function", 3)
		end
		taskManager.__public.Tasks += 1
		local _proxy, synchronousTask = Proxy.new(SynchronousTask, { TaskManager = proxy, Running = false })
		synchronousTask.Active = true
		synchronousTask.Function = func
		synchronousTask.Parameters = if ... == nil then nil else { ... }
		if taskManager.First == nil then
			taskManager.First, taskManager.Last = proxy, proxy
		else
			synchronousTask.Next, getmetatable(taskManager.First).Previous, taskManager.First =
				taskManager.First, proxy, proxy
		end
		if taskManager.Active == false and taskManager.__public.Enabled == true then
			taskManager.Active = true
			task.defer(Run, taskManager)
		end
		return proxy
	end,
	InsertBack = function(proxy, func, ...)
		local taskManager = getmetatable(proxy)
		if type(taskManager) ~= "table" or taskManager.__shared ~= TaskManager.__shared then
			error("Attempt to InsertBack failed: Passed value is not a Task Manager", 3)
		end
		if type(func) ~= "function" then
			error("Attempt to InsertBack failed: Passed value is not a function", 3)
		end
		taskManager.__public.Tasks += 1
		local _proxy, synchronousTask = Proxy.new(SynchronousTask, { TaskManager = proxy, Running = false })
		synchronousTask.Active = true
		synchronousTask.Function = func
		synchronousTask.Parameters = if ... == nil then nil else { ... }
		if taskManager.Last == nil then
			taskManager.First, taskManager.Last = proxy, proxy
		else
			synchronousTask.Previous, getmetatable(taskManager.Last).Next, taskManager.Last =
				taskManager.Last, proxy, proxy
		end
		if taskManager.Active == false and taskManager.__public.Enabled == true then
			taskManager.Active = true
			task.defer(Run, taskManager)
		end
		return proxy
	end,
	FindFirst = function(proxy, func)
		local taskManager = getmetatable(proxy)
		if type(taskManager) ~= "table" or taskManager.__shared ~= TaskManager.__shared then
			error("Attempt to FindFirst failed: Passed value is not a Task Manager", 3)
		end
		if type(func) ~= "function" then
			error("Attempt to FindFirst failed: Passed value is not a function", 3)
		end
		proxy = taskManager.__public.Running
		if proxy ~= nil then
			local synchronousTask = getmetatable(proxy)
			if synchronousTask.Active == true and synchronousTask.Function == func then
				return proxy, 0
			end
		end
		local index = 1
		proxy = taskManager.First
		while proxy ~= nil do
			local synchronousTask = getmetatable(proxy)
			if synchronousTask.Function == func then
				return proxy, index
			end
			proxy = synchronousTask.Next
			index += 1
		end

		return nil
	end,
	FindLast = function(proxy, func)
		local taskManager = getmetatable(proxy)
		if type(taskManager) ~= "table" or taskManager.__shared ~= TaskManager.__shared then
			error("Attempt to FindLast failed: Passed value is not a Task Manager", 3)
		end
		if type(func) ~= "function" then
			error("Attempt to FindFirst failed: Passed value is not a function", 3)
		end
		local index = if taskManager.__public.Running == nil
			then taskManager.__public.Tasks
			else taskManager.__public.Tasks - 1
		proxy = taskManager.Last
		while proxy ~= nil do
			local synchronousTask = getmetatable(proxy)
			if synchronousTask.Function == func then
				return proxy, index
			end
			proxy = synchronousTask.Previous
			index -= 1
		end
		proxy = taskManager.__public.Running
		if proxy ~= nil then
			local synchronousTask = getmetatable(proxy)
			if synchronousTask.Active == true and synchronousTask.Function == func then
				return proxy, 0
			end
		end

		return nil
	end,
	CancelAll = function(proxy, func)
		local taskManager = getmetatable(proxy)
		if type(taskManager) ~= "table" or taskManager.__shared ~= TaskManager.__shared then
			error("Attempt to FindLast failed: Passed value is not a Task Manager", 3)
		end
		if func == nil then
			local _proxy = taskManager.First
			taskManager.First = nil
			taskManager.Last = nil
			if taskManager.__public.Running == nil then
				taskManager.__public.Tasks = 0
			else
				taskManager.__public.Tasks = 1
			end
			while proxy ~= nil do
				local synchronousTask = getmetatable(proxy)
				proxy, synchronousTask.Active, synchronousTask.__public.TaskManager, synchronousTask.Previous, synchronousTask.Next =
					synchronousTask.Next, false, nil, nil, nil
			end
		else
			if type(func) ~= "function" then
				error("Attempt to CancelAll failed: Passed value is not nil or function", 3)
			end
			local _proxy = taskManager.First
			while proxy ~= nil do
				local synchronousTask = getmetatable(proxy)
				if synchronousTask.Function == func then
					taskManager.__public.Tasks -= 1
					if taskManager.First == proxy then
						taskManager.First = synchronousTask.Next
					end
					if taskManager.Last == proxy then
						taskManager.Last = synchronousTask.Previous
					end
					if synchronousTask.Previous ~= nil then
						getmetatable(synchronousTask.Previous).Next = synchronousTask.Next
					end
					if synchronousTask.Next ~= nil then
						getmetatable(synchronousTask.Next).Previous = synchronousTask.Previous
					end
					proxy, synchronousTask.Active, synchronousTask.__public.TaskManager, synchronousTask.Previous, synchronousTask.Next =
						synchronousTask.Next, false, nil, nil, nil
				else
					proxy = synchronousTask.Next
				end
			end
		end
	end,
}

TaskManager.__set = {
	Enabled = function(_proxy, taskManager, value)
		if type(value) ~= "boolean" then
			error("Attempt to set Enabled failed: Passed value is not a boolean", 3)
		end
		taskManager.__public.Enabled = value
		if value == false or taskManager.First == nil or taskManager.Active == true then
			return
		end
		taskManager.Active = true
		task.defer(Run, taskManager)
	end,
	Tasks = false,
	Running = false,
}

-- SynchronousTask
SynchronousTask.__tostring = function(_proxy)
	return "Synchronous Task"
end

SynchronousTask.__shared = {
	Wait = function(proxy, ...)
		local synchronousTask = getmetatable(proxy)
		if type(synchronousTask) ~= "table" or synchronousTask.__shared ~= SynchronousTask.__shared then
			error("Attempt to Wait failed: Passed value is not a Synchronous Task", 3)
		end
		if synchronousTask.Active == false then
			return
		end
		local waiter = { coroutine.running(), ... }
		if synchronousTask.Last == nil then
			synchronousTask.First, synchronousTask.Last = waiter, waiter
		else
			synchronousTask.Last.Next, synchronousTask.Last = waiter, waiter
		end
		return coroutine.yield()
	end,
	Cancel = function(proxy)
		local synchronousTask = getmetatable(proxy)
		if type(synchronousTask) ~= "table" or synchronousTask.__shared ~= SynchronousTask.__shared then
			error("Attempt to Cancel failed: Passed value is not a Synchronous Task", 3)
		end
		if synchronousTask.__public.Running == true then
			return false
		end
		local taskManager = synchronousTask.__public.TaskManager
		if taskManager == nil then
			return false
		end
		taskManager = getmetatable(taskManager)
		taskManager.__public.Tasks -= 1
		if taskManager.First == proxy then
			taskManager.First = synchronousTask.Next
		end
		if taskManager.Last == proxy then
			taskManager.Last = synchronousTask.Previous
		end
		if synchronousTask.Previous ~= nil then
			getmetatable(synchronousTask.Previous).Next = synchronousTask.Next
		end
		if synchronousTask.Next ~= nil then
			getmetatable(synchronousTask.Next).Previous = synchronousTask.Previous
		end
		synchronousTask.Active, synchronousTask.__public.TaskManager, synchronousTask.Previous, synchronousTask.Next =
			false, nil, nil, nil
		return true
	end,
}

SynchronousTask.__set = {
	TaskManager = false,
	Running = false,
}

-- RunningTask
RunningTask.__tostring = function(_proxy)
	return "Running Task"
end

RunningTask.__shared = {
	Next = function(proxy)
		local runningTask = getmetatable(proxy)
		if type(runningTask) ~= "table" or runningTask.__shared ~= RunningTask.__shared then
			error("Attempt to Next failed: Passed value is not a Running Task", 3)
		end
		local synchronousTask = runningTask.SynchronousTask
		local waiter = synchronousTask.First
		if waiter == nil then
			return
		end
		synchronousTask.First = waiter.Next
		if synchronousTask.Last == waiter then
			synchronousTask.Last = nil
		end
		return table.unpack(waiter)
	end,
	Iterate = function(proxy)
		local runningTask = getmetatable(proxy)
		if type(runningTask) ~= "table" or runningTask.__shared ~= RunningTask.__shared then
			error("Attempt to Iterate failed: Passed value is not a Running Task", 3)
		end
		return runningTask.__shared.Next, proxy
	end,
	End = function(proxy)
		local runningTask = getmetatable(proxy)
		if type(runningTask) ~= "table" or runningTask.__shared ~= RunningTask.__shared then
			error("Attempt to End failed: Passed value is not a Running Task", 3)
		end
		runningTask.SynchronousTask.Active = false
	end,
}

RunningTask.__set = {}

-- Functions
Run = function(taskManager)
	if taskManager.__public.Enabled == false then
		taskManager.Active = false
		return
	end
	local proxy = taskManager.First
	if proxy == nil then
		taskManager.Active = false
		return
	end
	local synchronousTask = getmetatable(proxy)
	taskManager.__public.Running = proxy
	taskManager.First = synchronousTask.Next
	synchronousTask.__public.Running = true
	if synchronousTask.Next == nil then
		taskManager.Last = nil
	else
		getmetatable(synchronousTask.Next).Previous = nil
		synchronousTask.Next = nil
	end
	local _proxy, runningTask = Proxy.new(RunningTask)
	runningTask.SynchronousTask = synchronousTask
	if synchronousTask.Parameters == nil then
		synchronousTask.Function(proxy)
	else
		synchronousTask.Function(proxy, table.unpack(synchronousTask.Parameters))
	end
	taskManager.__public.Tasks -= 1
	taskManager.__public.Running = nil
	synchronousTask.Active = false
	synchronousTask.__public.TaskManager = nil
	synchronousTask.__public.Running = false
	if taskManager.__public.Enabled == false or taskManager.First == nil then
		taskManager.Active = false
	else
		task.defer(Run, taskManager)
	end
end

return table.freeze(Constructor) :: Constructor
