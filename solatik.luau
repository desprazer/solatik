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

export type connection = {
	disconnect: () -> nil
}

export type attributevalue = string | boolean | number | Vector2 | Vector3 | CFrame | Color3 | BrickColor | nil

export type instanceproxy = {
	get: () -> Instance,
	child: (name: string) -> instanceproxy?,
	find: (name: string) -> instanceproxy?,
	findall: (classname: string?) -> {instanceproxy},
	destroy: () -> nil,
	clone: () -> instanceproxy,
	parent: () -> instanceproxy?,
	children: () -> {instanceproxy},
	connect: (signal: string, callback: (...any) -> any) -> connection,
	wait: (property: string?, timeout: number?) -> any,
	set: (properties: {[string]: any}) -> instanceproxy,
	apply: (func: (instance: Instance) -> any) -> instanceproxy,
	create: (classname: string, properties: {[string]: any}?) -> instanceproxy,
	descendantofclass: (classname: string) -> instanceproxy?,
	descendantsofclass: (classname: string) -> {instanceproxy},
	ancestor: (name: string) -> instanceproxy?,
	ancestors: () -> {instanceproxy},
	setattribute: (name: string, value: attributevalue) -> instanceproxy,
	getattribute: (name: string) -> attributevalue,
	attributes: () -> {[string]: attributevalue},
	removeattribute: (name: string) -> instanceproxy,
	clearattributes: () -> instanceproxy,
	batch: (func: (proxy: instanceproxy) -> nil) -> instanceproxy,
	setparent: (parent: Instance | instanceproxy?) -> instanceproxy,
	setname: (name: string) -> instanceproxy,
	rename: (pattern: string, replacement: string) -> instanceproxy,
	waitfor: (childname: string, timeout: number?) -> instanceproxy?,
	waitforclass: (classname: string, timeout: number?) -> instanceproxy?,
	findwhere: (predicate: (instance: Instance) -> boolean) -> instanceproxy?,
	findallwhere: (predicate: (instance: Instance) -> boolean) -> {instanceproxy},
	tag: (tag: string) -> instanceproxy,
	untag: (tag: string) -> instanceproxy,
	hastag: (tag: string) -> boolean,
	oncedestroying: (callback: () -> nil) -> connection,
	oncedescendantadded: (callback: (descendant: instanceproxy) -> nil) -> connection,
	observeproperty: (property: string, callback: (newValue: any, oldValue: any) -> nil) -> connection
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
	
	local function connect(signal: string, callback: (...any) -> any): connection
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
	
	local function descendantofclass(classname: string): instanceproxy?
		return wrap(instance:FindFirstChildOfClass(classname, true))
	end
	
	local function descendantsofclass(classname: string): {instanceproxy}
		local results = {}
		for _, descendant in instance:GetDescendants() do
			if descendant.ClassName == classname then
				table.insert(results, wrap(descendant))
			end
		end
		return results
	end
	
	local function ancestor(name: string): instanceproxy?
		local current = instance.Parent
		while current do
			if current.Name == name then
				return wrap(current)
			end
			current = current.Parent
		end
		return nil
	end
	
	local function ancestors(): {instanceproxy}
		local results = {}
		local current = instance.Parent
		while current do
			table.insert(results, wrap(current))
			current = current.Parent
		end
		return results
	end
	
	local function setattribute(name: string, value: attributevalue): instanceproxy
		instance:SetAttribute(name, value)
		return proxy
	end
	
	local function getattribute(name: string): attributevalue
		return instance:GetAttribute(name)
	end
	
	local function attributes(): {[string]: attributevalue}
		local attrs = {}
		for _, name in instance:GetAttributeChangedSignal():GetConnections() do
			attrs[name] = instance:GetAttribute(name)
		end
		return attrs
	end
	
	local function removeattribute(name: string): instanceproxy
		instance:SetAttribute(name, nil)
		return proxy
	end
	
	local function clearattributes(): instanceproxy
		for name, _ in attributes() do
			instance:SetAttribute(name, nil)
		end
		return proxy
	end
	
	local function batch(func: (proxy: instanceproxy) -> nil): instanceproxy
		func(proxy)
		return proxy
	end
	
	local function setparent(parent: Instance | instanceproxy?): instanceproxy
		if typeof(parent) == "table" and parent.get then
			instance.Parent = parent:get()
		else
			instance.Parent = parent
		end
		return proxy
	end
	
	local function setname(name: string): instanceproxy
		instance.Name = name
		return proxy
	end
	
	local function rename(pattern: string, replacement: string): instanceproxy
		instance.Name = string.gsub(instance.Name, pattern, replacement)
		return proxy
	end
	
	local function waitfor(childname: string, timeout: number?): instanceproxy?
		local child = instance:WaitForChild(childname, timeout)
		return wrap(child)
	end
	
	local function waitforclass(classname: string, timeout: number?): instanceproxy?
		local startTime = time()
		local timeoutRemaining = timeout
		
		while timeoutRemaining == nil or timeoutRemaining > 0 do
			local child = instance:FindFirstChildOfClass(classname)
			if child then
				return wrap(child)
			end
			
			task.wait(0.05)
			
			if timeout then
				timeoutRemaining = timeout - (time() - startTime)
			end
		end
		
		return nil
	end
	
	local function findwhere(predicate: (instance: Instance) -> boolean): instanceproxy?
		for _, descendant in instance:GetDescendants() do
			if predicate(descendant) then
				return wrap(descendant)
			end
		end
		return nil
	end
	
	local function findallwhere(predicate: (instance: Instance) -> boolean): {instanceproxy}
		local results = {}
		for _, descendant in instance:GetDescendants() do
			if predicate(descendant) then
				table.insert(results, wrap(descendant))
			end
		end
		return results
	end
	
	local function tag(tag: string): instanceproxy
		if game:GetService("CollectionService") then
			game:GetService("CollectionService"):AddTag(instance, tag)
		end
		return proxy
	end
	
	local function untag(tag: string): instanceproxy
		if game:GetService("CollectionService") then
			game:GetService("CollectionService"):RemoveTag(instance, tag)
		end
		return proxy
	end
	
	local function hastag(tag: string): boolean
		if game:GetService("CollectionService") then
			return game:GetService("CollectionService"):HasTag(instance, tag)
		end
		return false
	end
	
	local function oncedestroying(callback: () -> nil): connection
		local connection
		connection = instance.Destroying:Connect(function()
			callback()
			connection:Disconnect()
		end)
		return {
			disconnect = function()
				connection:Disconnect()
			end
		}
	end
	
	local function oncedescendantadded(callback: (descendant: instanceproxy) -> nil): connection
		local connection
		connection = instance.DescendantAdded:Connect(function(descendant)
			callback(wrap(descendant))
			connection:Disconnect()
		end)
		return {
			disconnect = function()
				connection:Disconnect()
			end
		}
	end
	
	local function observeproperty(property: string, callback: (newValue: any, oldValue: any) -> nil): connection
		local oldValue = instance[property]
		
		local connection = instance:GetPropertyChangedSignal(property):Connect(function()
			local newValue = instance[property]
			callback(newValue, oldValue)
			oldValue = newValue
		end)
		
		return {
			disconnect = function()
				connection:Disconnect()
			end
		}
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
	proxy.descendantofclass = descendantofclass
	proxy.descendantsofclass = descendantsofclass
	proxy.ancestor = ancestor
	proxy.ancestors = ancestors
	proxy.setattribute = setattribute
	proxy.getattribute = getattribute
	proxy.attributes = attributes
	proxy.removeattribute = removeattribute
	proxy.clearattributes = clearattributes
	proxy.batch = batch
	proxy.setparent = setparent
	proxy.setname = setname
	proxy.rename = rename
	proxy.waitfor = waitfor
	proxy.waitforclass = waitforclass
	proxy.findwhere = findwhere
	proxy.findallwhere = findallwhere
	proxy.tag = tag
	proxy.untag = untag
	proxy.hastag = hastag
	proxy.oncedestroying = oncedestroying
	proxy.oncedescendantadded = oncedescendantadded
	proxy.observeproperty = observeproperty
	
	return proxy
end

local solatik = {}

local function from(instance: Instance): instanceproxy
	return wrap(instance)
end

local function create(classname: string, properties: {[string]: any}?): instanceproxy
	local instance = Instance.new(classname)
	
	if properties then
		for prop, value in properties do
			instance[prop] = value
		end
	end
	
	return wrap(instance)
end

local function wrapall(instances: {Instance}): {instanceproxy}
	local proxies = {}
	for _, instance in instances do
		table.insert(proxies, wrap(instance))
	end
	return proxies
end

local function getbytag(tag: string): {instanceproxy}
	if game:GetService("CollectionService") then
		return wrapall(game:GetService("CollectionService"):GetTagged(tag))
	end
	return {}
end

local function service(name: string): instanceproxy
	return wrap(game:GetService(name))
end

solatik.from = from
solatik.create = create
solatik.wrapall = wrapall
solatik.getbytag = getbytag
solatik.service = service

return solatik
