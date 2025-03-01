--!native
--!optimize 2
--!strict
--[[

   __                                                                 __   
  / /   ______   ______   ______   ______   ______   ______   ______  \ \  
 / /   /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/   \ \ 
 \ \   /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/   / / 
  \_\                                                                 /_/  
                                                                           
              _________      .__          __  .__ __                       
             /   _____/ ____ |  | _____ _/  |_|__|  | __                   
             \_____  \ /  _ \|  | \__  \\   __\  |  |/ /                   
             /        (  <_> )  |__/ __ \|  | |  |    <                    
            /_______  /\____/|____(____  /__| |__|__|_ \                   
                    \/                 \/             \/                   
   __                                                                 __   
  / /   ______   ______   ______   ______   ______   ______   ______  \ \  
 / /   /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/   \ \ 
 \ \   /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/   / / 
  \_\                                                                 /_/  
                                                                           
--]]
-- solatik
-- a minimal, type-safe instance proxy wrapper for roblox

export type instanceproxy = {
	get: () -> Instance,
	child: (name: string) -> instanceproxy?,
	find: (name: string) -> instanceproxy?,
	findall: (classname: string?) -> {instanceproxy},
	destroy: () -> nil,
	clone: () -> instanceproxy,
	parent: () -> instanceproxy?,
	children: () -> {instanceproxy},
	connect: (signal: string, callback: (...any) -> any) -> {disconnect: () -> nil},
	wait: (property: string?, timeout: number?) -> any,
	set: (properties: {[string]: any}) -> instanceproxy,
	apply: (func: (instance: Instance) -> any) -> instanceproxy,
	create: (classname: string, properties: {[string]: any}?) -> instanceproxy
}

local function wrap(instance: Instance?): instanceproxy?
	if not instance then
		return nil
	end
	
	local proxy = {} :: instanceproxy
	
	local function get()
		return instance
	end
	
	local function child(name: string): instanceproxy?
		return wrap(instance:FindFirstChild(name))
	end
	
	local function find(name: string): instanceproxy?
		return wrap(instance:FindFirstChild(name, true))
	end
	
	local function findall(classname: string?): {instanceproxy}
		local results = {}
		local instances = classname and instance:GetDescendants():Where(function(i)
			return i.ClassName == classname
		end) or instance:GetDescendants()
		
		for _, inst in instances do
			table.insert(results, wrap(inst))
		end
		
		return results
	end
	
	local function destroy(): nil
		instance:Destroy()
		return nil
	end
	
	local function clone(): instanceproxy
		return wrap(instance:Clone())
	end
	
	local function parent(): instanceproxy?
		return wrap(instance.Parent)
	end
	
	local function children(): {instanceproxy}
		local results = {}
		for _, child in instance:GetChildren() do
			table.insert(results, wrap(child))
		end
		return results
	end
	--@signal
	local function connect(signal: string, callback: (...any) -> any)
		local connection = instance[signal]:Connect(callback)
		return {
			disconnect = function()
				connection:Disconnect()
			end
		}
	end
	
	local function wait(property: string?, timeout: number?): any
		if property then
			return instance:GetPropertyChangedSignal(property):Wait(timeout)
		else
			return instance.Changed:Wait(timeout)
		end
	end
	
	local function set(properties: {[string]: any}): instanceproxy
		for prop, value in properties do
			instance[prop] = value
		end
		return proxy
	end
	
	local function apply(func: (instance: Instance) -> any): instanceproxy
		func(instance)
		return proxy
	end
	
	local function create(classname: string, properties: {[string]: any}?): instanceproxy
		local newinstance = Instance.new(classname)
		newinstance.Parent = instance
		
		if properties then
			for prop, value in properties do
				newinstance[prop] = value
			end
		end
		
		return wrap(newinstance)
	end
	
	proxy.get = get
	proxy.child = child
	proxy.find = find
	proxy.findall = findall
	proxy.destroy = destroy
	proxy.clone = clone
	proxy.parent = parent
	proxy.children = children
	proxy.connect = connect
	proxy.wait = wait
	proxy.set = set
	proxy.apply = apply
	proxy.create = create
	
	return proxy
end

local solatik = {}

function solatik.from(instance: Instance): instanceproxy
	return wrap(instance)
end

return solatik
