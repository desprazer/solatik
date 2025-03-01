# solatik
minimal, type-safe instance proxy wrapper for roblox that provides a clean, chainable api.

## why use this?
most traditional roblox instance manipulation often results in verbose, hard-to-read code.
eg.
```lua

local screenGui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
if screenGui then
    local frame = screenGui:FindFirstChild("MainFrame")
    if frame then
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        frame.BorderSizePixel = 0
        
        local button = Instance.new("TextButton")
        button.Position = UDim2.new(0.5, 0, 0.5, 0)
        button.AnchorPoint = Vector2.new(0.5, 0.5)
        button.Size = UDim2.new(0, 200, 0, 50)
        button.Text = "Click Me!"
        button.Parent = frame
        
        local connection = button.MouseButton1Click:Connect(function()
            print("Button clicked!")
        end)
        
        -- have to manually track connections for cleanup! :(
    end
end
```

solatik solves these problems.

```lua
local button = solatik.from(playerGui)
    :child("screenGui")
    :child("mainFrame")
    :set({
        backgroundcolor3 = Color3.fromRGB(40, 40, 40),
        bordersizepixel = 0
    })
    :create("textbutton", {
        position = UDim2.new(0.5, 0, 0.5, 0),
        anchorpoint = Vector2.new(0.5, 0.5),
        size = UDim2.new(0, 200, 0, 50),
        text = "Click Me!"
    })
-- yay!!!! so clean!!!!!
```

```lua
-- no more bad if-checks or pcalls for missing instances!!!!!!!!!!!!!!!!!!! hooray
local maybeButton = solatik.from(workspace):find("button-that-might-not-exist")
if maybeButton then
    -- this only runs if button exists!!!!!!!!!!!! no more thing!!!!!!!!!
    maybeButton:set({transparency = 0.5})
end
```

```lua
local connection = button:connect("mousebutton1click", function()
    print("Button clicked!") -- YAYYYYYYYYYYYYY
end)

-- later, when done:
connection:disconnect()
```
instead of
```lua
part.Size = Vector3.new(2, 2, 2)
part.Position = Vector3.new(0, 10, 0)
part.Anchored = true
part.CanCollide = false
```
do this!!:
```lua
solatik.from(part):set({
    size = Vector3.new(2, 2, 2),
    position = Vector3.new(0, 10, 0),
    anchored = true,
    cancollide = false
})
```

instead of this:
```lua
local folder = Instance.new("Folder")
folder.Name = "Items"
folder.Parent = workspace -- stupid ugly parenting anmd creating it sucks so bad
```
do this!!!! (better): 
```lua
local folder = solatik.from(workspace):create("folder", {name = "items"}) -- now isn't that amazing
```

```lua
-- if you wanted to oh i don't know find all the parts in a workspace then do this
local allparts = solatik.from(workspace):findall("part")

-- or maybe get all the textbuttons in a ui...?
local allbuttons = solatik.from(screenGui):findall("textbutton") -- Yu did it!!!!!!!!!!!!
```

## installation:
- copy code from solatik.luau and paste into a modulescript in roblox studio
- require() to import it

## basic usage:


```lua
local solatik = require(path.to.that.module.right.there.above.this.text)

-- you can create a proxy from an existing instance
local playerGui = solatik.from(game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))

-- if you like chain methods this is the library for you
local frame = playerGui
    :child("screenGui")
    :child("mainFrame")
    :set({
        backgroundcolor3 = Color3.fromRGB(40, 40, 40),
        bordersizepixel = 0
    })

-- you can create a new insatnce!!!! !! ! ! ! 
local button = frame:create("textbutton", {
    position = UDim2.new(0.5, 0, 0.5, 0),
    anchorpoint = Vector2.new(0.5, 0.5),
    size = UDim2.new(0, 200, 0, 50),
    text = "click me!!!!!!",
    textcolor3 = Color3.fromRGB(255, 255, 255)
})

-- connect to events!! wowie
local connection = button:connect("mousebutton1click", function()
    print("Button clicked!")
end)

-- find instances!!! amazbealls
local alltextlabels = frame:findall("textlabel")
for _, label in alltextlabels do
    label:set({textsize = 18})
end

-- you can also access the raw instance when needed
local rawbutton = button:get()

-- then you can even disconnect the events when done!!! isn't that amazing
connection:disconnect()
```

## api reference:

### modules:

- `from(instance: Instance): instanceproxy` - creates a new proxy wrapper for an instance

### proxy methods:

- `get(): Instance` - returns the raw roblox instance
- `child(name: string): instanceproxy?` - gets a direct child by name
- `find(name: string): instanceproxy?` - finds a descendant by name (recursive)
- `findall(classname: string?): {instanceproxy}` - gets all descendants, optionally filtered by class
- `destroy(): nil` - destroys the instance
- `clone(): instanceproxy` - clones the instance and returns a proxy for the clone
- `parent(): instanceproxy?` - gets the parent instance
- `children(): {instanceproxy}` - gets all direct children as proxies
- `connect(signal: string, callback: (...any) -> any): {disconnect: () -> nil}` - connects to an event
- `wait(property: string?, timeout: number?): any` - waits for a property change
- `set(properties: {[string]: any}): instanceproxy` - sets multiple properties at once
- `apply(func: (instance: Instance) -> any): instanceproxy` - applies a custom function to the instance
- `create(classname: string, properties: {[string]: any}?): instanceproxy` - creates a new instance as a child


# final notes

i hope you enjoy using this library, i enjoyed making it. if you think you can add something cool ro do something amazing make a pr, if something doesn't work quite right, feel free to make an issue! you can also contact me if there's a problem. cheers
