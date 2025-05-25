-- Variables
local Proxy = require(script.Parent.Proxy)
local Constructor, Signal, Connection = {}, {}, {}
local Thread, Call
local threads = {}

-- Types
export type Constructor = {
	new: () -> Signal,
}

export type Signal = {
	[any]: any,
	Connections: number,
	Connected: (connected: boolean, signal: Signal) -> ()?,
	Connect: (self: Signal, func: (...any) -> (), ...any) -> Connection,
	Once: (self: Signal, func: (...any) -> (), ...any) -> Connection,
	Wait: (self: Signal, ...any) -> ...any,
	Fire: (self: Signal, ...any) -> (),
	FastFire: (self: Signal, ...any) -> (),
	DisconnectAll: (self: Signal) -> (),
}

export type Connection = {
	[any]: any,
	Signal: Signal?,
	Disconnect: (self: Connection) -> (),
}

-- Constructor
Constructor.new = function()
	local proxy, _signal = Proxy.new(Signal, { Connections = 0 })
	return proxy
end

-- Signal
Signal.__tostring = function()
	return "Signal"
end

Signal.__shared = {
	Connect = function(proxy, func, ...)
		local signal = getmetatable(proxy)
		if type(signal) ~= "table" or signal.__shared ~= Signal.__shared then
			error("Attempt to Connect failed: Passed value is not a Signal", 3)
		end
		if type(func) ~= "function" then
			error("Attempt to Connect failed: Passed value is not a function", 3)
		end
		signal.__public.Connections += 1
		local connectionProxy, connection = Proxy.new(Connection, { Signal = proxy })
		connection.FunctionOrThread = func
		connection.Parameters = if ... == nil then nil else { ... }
		if signal.Last == nil then
			signal.First, signal.Last = connection, connection
		else
			connection.Previous, signal.Last.Next, signal.Last = signal.Last, connection, connection
		end
		if signal.__public.Connections == 1 and signal.__public.Connected ~= nil then
			task.defer(signal.__public.Connected, true, proxy)
		end
		return connectionProxy
	end,
	Once = function(proxy, func, ...)
		local signal = getmetatable(proxy)
		if type(signal) ~= "table" or signal.__shared ~= Signal.__shared then
			error("Attempt to Connect failed: Passed value is not a Signal", 3)
		end
		if type(func) ~= "function" then
			error("Attempt to Connect failed: Passed value is not a function", 3)
		end
		signal.__public.Connections += 1
		local connectionProxy, connection = Proxy.new(Connection, { Signal = proxy })
		connection.FunctionOrThread = func
		connection.Once = true
		connection.Parameters = if ... == nil then nil else { ... }
		if signal.Last == nil then
			signal.First, signal.Last = connection, connection
		else
			connection.Previous, signal.Last.Next, signal.Last = signal.Last, connection, connection
		end
		if signal.__public.Connections == 1 and signal.__public.Connected ~= nil then
			task.defer(signal.__public.Connected, true, proxy)
		end
		return connectionProxy
	end,
	Wait = function(proxy, ...)
		local signal = getmetatable(proxy)
		if type(signal) ~= "table" or signal.__shared ~= Signal.__shared then
			error("Attempt to Connect failed: Passed value is not a Signal", 3)
		end
		signal.__public.Connections += 1
		local _connectionProxy, connection = Proxy.new(Connection, { Signal = proxy })
		connection.FunctionOrThread = coroutine.running()
		connection.Once = true
		connection.Parameters = if ... == nil then nil else { ... }
		if signal.Last == nil then
			signal.First, signal.Last = connection, connection
		else
			connection.Previous, signal.Last.Next, signal.Last = signal.Last, connection, connection
		end
		if signal.__public.Connections == 1 and signal.__public.Connected ~= nil then
			task.defer(signal.__public.Connected, true, proxy)
		end
		return coroutine.yield()
	end,
	Fire = function(proxy, ...)
		local signal = getmetatable(proxy)
		if type(signal) ~= "table" or signal.__shared ~= Signal.__shared then
			error("Attempt to connect failed: Passed value is not a Signal", 3)
		end
		local connection = signal.First
		while connection ~= nil do
			if connection.Once == true then
				signal.__public.Connections -= 1
				connection.__public.Signal = nil
				if signal.First == connection then
					signal.First = connection.Next
				end
				if signal.Last == connection then
					signal.Last = connection.Previous
				end
				if connection.Previous ~= nil then
					connection.Previous.Next = connection.Next
				end
				if connection.Next ~= nil then
					connection.Next.Previous = connection.Previous
				end
				if signal.__public.Connections == 0 and signal.__public.Connected ~= nil then
					task.defer(signal.__public.Connected, false, proxy)
				end
			end
			if type(connection.FunctionOrThread) == "thread" then
				if connection.Parameters == nil then
					task.spawn(connection.FunctionOrThread, ...)
				else
					local parameters = { ... }
					task.spawn(
						connection.FunctionOrThread,
						table.unpack(
							table.move(connection.Parameters, 1, #connection.Parameters, #parameters + 1, parameters)
						)
					)
				end
			else
				local thread = table.remove(threads)
				if thread == nil then
					thread = coroutine.create(Thread)
					coroutine.resume(thread)
				end
				if connection.Parameters == nil then
					task.spawn(thread, thread, connection.FunctionOrThread, ...)
				else
					local parameters = { ... }
					task.spawn(
						thread,
						thread,
						connection.FunctionOrThread,
						table.unpack(
							table.move(connection.Parameters, 1, #connection.Parameters, #parameters + 1, parameters)
						)
					)
				end
			end
			connection = connection.Next
		end
	end,
	FastFire = function(proxy, ...)
		local signal = getmetatable(proxy)
		if type(signal) ~= "table" or signal.__shared ~= Signal.__shared then
			error("Attempt to connect failed: Passed value is not a Signal", 3)
		end
		local connection = signal.First
		while connection ~= nil do
			if connection.Once == true then
				signal.__public.Connections -= 1
				connection.__public.Signal = nil
				if signal.First == connection then
					signal.First = connection.Next
				end
				if signal.Last == connection then
					signal.Last = connection.Previous
				end
				if connection.Previous ~= nil then
					connection.Previous.Next = connection.Next
				end
				if connection.Next ~= nil then
					connection.Next.Previous = connection.Previous
				end
				if signal.__public.Connections == 0 and signal.__public.Connected ~= nil then
					task.defer(signal.__public.Connected, false, proxy)
				end
			end
			if type(connection.FunctionOrThread) == "thread" then
				if connection.Parameters == nil then
					coroutine.resume(connection.FunctionOrThread, ...)
				else
					local parameters = { ... }
					coroutine.resume(
						connection.FunctionOrThread,
						table.unpack(
							table.move(connection.Parameters, 1, #connection.Parameters, #parameters + 1, parameters)
						)
					)
				end
			else
				if connection.Parameters == nil then
					connection.FunctionOrThread(...)
				else
					local parameters = { ... }
					connection.FunctionOrThread(
						table.unpack(
							table.move(connection.Parameters, 1, #connection.Parameters, #parameters + 1, parameters)
						)
					)
				end
			end
			connection = connection.Next
		end
	end,
	DisconnectAll = function(proxy)
		local signal = getmetatable(proxy)
		if type(signal) ~= "table" or signal.__shared ~= Signal.__shared then
			error("Attempt to Connect failed: Passed value is not a Signal", 3)
		end
		local connection = signal.First
		if connection == nil then
			return
		end
		while connection ~= nil do
			connection.__public.Signal = nil
			if type(connection.FunctionOrThread) == "thread" then
				task.cancel(connection.FunctionOrThread)
			end
			connection = connection.Next
		end
		if signal.__public.Connected ~= nil then
			task.defer(signal.__public.Connected, false, proxy)
		end
		signal.__public.Connections, signal.First, signal.Last = 0, nil, nil
	end,
}

Signal.__set = {
	Connections = false,
}

-- Connection
Connection.__tostring = function()
	return "Connection"
end

Connection.__shared = {
	Disconnect = function(proxy)
		local connection = getmetatable(proxy)
		if type(connection) ~= "table" or connection.__shared ~= Connection.__shared then
			error("Attempt to Disconnect failed: Passed value is not a Connection", 3)
		end
		local signal = getmetatable(connection.__public.Signal)
		if signal == nil then
			return
		end
		signal.__public.Connections -= 1
		connection.__public.Signal = nil
		if signal.First == connection then
			signal.First = connection.Next
		end
		if signal.Last == connection then
			signal.Last = connection.Previous
		end
		if connection.Previous ~= nil then
			connection.Previous.Next = connection.Next
		end
		if connection.Next ~= nil then
			connection.Next.Previous = connection.Previous
		end
		if type(connection.FunctionOrThread) == "thread" then
			task.cancel(connection.FunctionOrThread)
		end
		if signal.__public.Connections == 0 and signal.__public.Connected ~= nil then
			task.defer(signal.__public.Connected, false, proxy)
		end
	end,
}

Connection.__set = {
	Signal = false,
}

-- Functions
Thread = function()
	while true do
		Call(coroutine.yield())
	end
end

Call = function(thread, func, ...)
	func(...)
	if #threads >= 16 then
		return
	end
	table.insert(threads, thread)
end

return table.freeze(Constructor) :: Constructor
