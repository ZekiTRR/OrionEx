--!strict
-- sUNC executor API definitions (https://docs.sunc.io/)
-- Loaded via `luau-lsp lsp --definitions=globalTypes.d.luau --definitions=sunc.d.luau`.
-- Must be loaded AFTER globalTypes.d.luau: the `debug` declaration below
-- re-states the standard Luau/Roblox debug members plus the sUNC additions.

--------------------------------------------------------------------------------
-- Shared types
--------------------------------------------------------------------------------

declare extern type sUNCConnection with
    Connected: boolean
    function Disconnect(self): ()
end

declare extern type sUNCClosure with end

-- Drawing library object (canvas 2D render object)
declare extern type Drawing with
    Visible: boolean
    Color: Color3
    Transparency: number
    Thickness: number
    Size: Vector2
    Position: Vector2
    Text: string
    TextBounds: Vector2
    Font: number
    Center: boolean
    Outline: boolean
    OutlineColor: Color3
    Filled: boolean
    ZIndex: number
    NumSides: number
    Radius: number
    Rotation: number
    From: Vector2
    To: Vector2
    ThicknessEnd: number
    Point: Vector2
    function Remove(self): ()
    function Destroy(self): ()
end

-- GC filter options for filtergc
declare extern type sUNCGCFilter with
    Type: ("Function" | "Table")?
    Name: string?
    Options: { any }?
    Keys: { any }?
    Values: { any }?
    Function: ((any) -> boolean)?
    IncludeTables: boolean?
    IncludeFunctions: boolean?
    IncludeUserdata: boolean?
    IgnoreNoGetName: boolean?
    PreventDuplicates: boolean?
    MatchTableContents: boolean?
    MatchFunctionProperties: boolean?
end

--------------------------------------------------------------------------------
-- Closures (https://docs.sunc.io/closures/)
--------------------------------------------------------------------------------

--- Returns true if the calling thread originates from the executor.
declare function checkcaller(): boolean

--- Returns true if func is a C closure (registered function).
declare function iscclosure(func: any): boolean

--- Returns true if func is a Lua closure.
declare function islclosure(func: any): boolean

--- Returns true if func originated from the executor.
declare function isexecutorclosure(func: any): boolean

--- Returns a cloned copy of func.
declare function clonefunction(func: (...any) -> ...any): (...any) -> ...any

--- Wraps func in a new C closure.
declare function newcclosure(func: (...any) -> ...any): (...any) -> ...any

--- Replaces func with hook; returns the original function.
declare function hookfunction(func: (...any) -> ...any, hook: (...any) -> ...any): ((...any) -> ...any)

--- Restores func to its original implementation (undo hookfunction).
declare function restorefunction(func: (...any) -> ...any): ()

--- Replaces the metamethod __name on obj with hook; returns the original.
declare function hookmetamethod(obj: any, __name: string, hook: (...any) -> ...any): (...any) -> ...any

--- Returns the bytecode hash of func.
declare function getfunctionhash(func: (...any) -> ...any): string

--- Compiles source and returns the resulting function, or nil + error.
declare function loadstring(source: string, chunkName: string?): ((...any) -> ...any?, string?)

--------------------------------------------------------------------------------
-- Debug extensions (https://docs.sunc.io/debug/)
--- Standard Luau/Roblox debug members plus sUNC additions.
--------------------------------------------------------------------------------

declare debug: {
    info: (<R...>(thread, number, string) -> R...) & (<R...>(number, string) -> R...) & (<A..., R1..., R2...>((A...) -> R1..., string) -> R2...),
    traceback: ((string?, number?) -> string) & ((thread, string?, number?) -> string),
    profilebegin: (label: string) -> (),
    profileend: () -> (),
    getmemorycategory: () -> string,
    setmemorycategory: (tag: string) -> (),
    resetmemorycategory: () -> (),

    --- Returns the constant at index idx of func.
    getconstant: (func: (...any) -> ...any, idx: number) -> any,
    --- Returns all constants of func as a table.
    getconstants: (func: (...any) -> ...any) -> { any },
    --- Replaces the constant at idx of func with value.
    setconstant: (func: (...any) -> ...any, idx: number, value: any) -> (),
    --- Returns the proto-function at index idx of func.
    getproto: (func: (...any) -> ...any, idx: number, activated: boolean?) -> ((...any) -> ...any),
    --- Returns all protos of func as a table.
    getprotos: (func: (...any) -> ...any, activated: boolean?) -> { (...any) -> ...any },
    --- Returns a value from func's debug stack at level/idx.
    getstack: ((thread, number, number) -> any) & ((number, number) -> any),
    --- Sets a value in func's debug stack at level/idx.
    setstack: ((thread, number, number, any) -> ()) & ((number, number, any) -> ()),
    --- Returns the upvalue at index idx of func.
    getupvalue: (func: (...any) -> ...any, idx: number) -> any,
    --- Returns all upvalues of func as a table.
    getupvalues: (func: (...any) -> ...any) -> { any },
    --- Replaces the upvalue at index idx of func with value.
    setupvalue: (func: (...any) -> ...any, idx: number, value: any) -> (),
}

--------------------------------------------------------------------------------
-- Drawing (https://docs.sunc.io/drawing/)
--------------------------------------------------------------------------------

--- Creates a new Drawing render object of the given class ("Line", "Text", "Square", "Circle", "Triangle", "Image").
declare Drawing: {
    new: (className: string) -> Drawing,
}
--- Destroys all Drawing objects created by this script.
declare function cleardrawcache(): ()
--- Returns true if obj is a Drawing render object.
declare function isrenderobj(obj: any): boolean
--- Reads a render property of a Drawing object.
declare function getrenderproperty(obj: Drawing, property: string): any
--- Writes a render property of a Drawing object.
declare function setrenderproperty(obj: Drawing, property: string, value: any): ()

--------------------------------------------------------------------------------
-- Encoding (https://docs.sunc.io/encoding/)
--------------------------------------------------------------------------------

--- Encodes str as Base64.
declare function base64encode(str: string): string
--- Decodes a Base64 string.
declare function base64decode(str: string): string
--- LZ4-compress data.
declare function lz4compress(data: string): string
--- LZ4-decompress data.
declare function lz4decompress(data: string): string

--------------------------------------------------------------------------------
-- Environment (https://docs.sunc.io/environment/)
--------------------------------------------------------------------------------

--- Returns the executor's global environment table.
declare function getgenv(): { any }
--- Returns the Lua registry table.
declare function getreg(): { any }
--- Returns the Roblox environment table.
declare function getrenv(): { any }
--- Returns all objects currently tracked by Lua's garbage collector.
declare function getgc(includeTables: boolean?): { any }
--- Returns a filtered list of objects tracked by the garbage collector.
declare function filtergc(filter: sUNCGCFilter): { any }

--------------------------------------------------------------------------------
-- Filesystem (https://docs.sunc.io/filesystem/)
--------------------------------------------------------------------------------

--- Reads the contents of path.
declare function readfile(path: string): string
--- Writes content to path (overwrites existing file).
declare function writefile(path: string, content: string): ()
--- Appends content to path.
declare function appendfile(path: string, content: string): ()
--- Compiles the file at path and returns its chunk function.
declare function loadfile(path: string): ((...any) -> ...any?, string?)
--- Deletes the file at path.
declare function delfile(path: string): ()
--- Deletes the folder at path.
declare function delfolder(path: string): ()
--- Creates the folder at path.
declare function makefolder(path: string): ()
--- Returns true if path is a file.
declare function isfile(path: string): boolean
--- Returns true if path is a folder.
declare function isfolder(path: string): boolean
--- Returns a table of file names under path.
declare function listfiles(path: string): { string }
--- Returns an rbxasset:// string for the custom asset at path.
declare function getcustomasset(path: string): string

--------------------------------------------------------------------------------
-- Instances (https://docs.sunc.io/instances/)
--------------------------------------------------------------------------------

--- Returns a fresh Lua-side reference to obj.
declare function cloneref(obj: any): any
--- Returns true if a and b refer to the same Roblox Instance.
declare function compareinstances(a: any, b: any): boolean
--- Returns the executor's hidden GUI container instance.
declare function gethui(): Instance
--- Returns all Instances currently in memory.
declare function getinstances(): { Instance }
--- Returns Instances whose Lua reference is nil.
declare function getnilinstances(): { Instance }
--- Returns the function backing a Roblox signal/callback of instance.
declare function getcallbackvalue(instance: Instance, property: string): (...any) -> ...any
--- Programmatically fires a ClickDetector.
declare function fireclickdetector(detector: Instance, distance: number?, ...: any): ()
--- Programmatically triggers a ProximityPrompt.
declare function fireproximityprompt(prompt: Instance, holdDuration: number?, ...: any): ()
--- Simulates a Touched event on part with toggle state.
declare function firetouchinterest(part: Instance, toPart: Instance, toggle: boolean): ()

--------------------------------------------------------------------------------
-- Metatable (https://docs.sunc.io/metatable/)
--------------------------------------------------------------------------------

--- Returns the current namecall method inside a hooked __namecall.
declare function getnamecallmethod(): (...any) -> ...any
--- Returns the raw metatable of obj.
declare function getrawmetatable(obj: any): { any }
--- Replaces the raw metatable of obj.
declare function setrawmetatable(obj: any, mt: { any }): boolean
--- Returns true if the table is locked from writes.
declare function isreadonly(table: { any }): boolean
--- Toggles a table's write lock.
declare function setreadonly(table: { any }, value: boolean): ()

--------------------------------------------------------------------------------
-- Miscellaneous (https://docs.sunc.io/miscellaneous/)
--------------------------------------------------------------------------------

--- Returns info about the current executor.
declare function identifyexecutor(): (string, string?)
--- Performs a generic HTTP request with an options table.
declare function request(options: {
    Url: string,
    Method: string?,
    Headers: { [string]: string }?,
    Body: string?,
    Cookies: { [string]: string }?,
    Callback: ((number, string) -> ())?,
}): {
    Success: boolean,
    StatusCode: number,
    Headers: { [string]: string },
    Body: string,
}

--------------------------------------------------------------------------------
-- Reflection (https://docs.sunc.io/reflection/)
--------------------------------------------------------------------------------

--- Reads a hidden (non-scriptable) property of obj.
declare function gethiddenproperty(obj: Instance, property: string): (any, boolean)
--- Writes a hidden property of obj.
declare function sethiddenproperty(obj: Instance, property: string, value: any): boolean
--- Returns true if the property of obj is currently scriptable.
declare function isscriptable(obj: Instance, property: string): boolean
--- Toggles a property's scriptable flag.
declare function setscriptable(obj: Instance, property: string, value: boolean): boolean
--- Returns the current thread Identity level.
declare function getthreadidentity(): number
--- Changes the current thread Identity level.
declare function setthreadidentity(level: number): ()

--------------------------------------------------------------------------------
-- Scripts (https://docs.sunc.io/scripts/)
--------------------------------------------------------------------------------

--- Returns the script that called the current function.
declare function getcallingscript(): Instance
--- Returns all Scripts and LocalScripts currently running.
declare function getscripts(): { Instance }
--- Returns all ModuleScripts currently loaded.
declare function getloadedmodules(): { Instance }
--- Returns running Script/LocalScript/ModuleScript instances.
declare function getrunningscripts(): { Instance }
--- Returns the Lua closure that backs script.
declare function getscriptclosure(script: Instance): ((...any) -> ...any)
--- Returns the bytecode of script.
declare function getscriptbytecode(script: Instance): string
--- Returns the script associated with a Lua thread.
declare function getscriptfromthread(thread: thread): Instance
--- Returns the bytecode hash of script.
declare function getscripthash(script: Instance): string
--- Returns script's environment table.
declare function getsenv(script: Instance): { any }

--------------------------------------------------------------------------------
-- Signals (https://docs.sunc.io/signals/)
--------------------------------------------------------------------------------

--- Programmatically fires any signal with arguments.
declare function firesignal(signal: any, ...: any): ()
--- Returns all connections to a signal.
declare function getconnections(signal: any): { sUNCConnection }
--- Replicates a RemoteEvent/Function signal across the server boundary.
declare function replicatesignal(signal: any, ...: any): boolean

--------------------------------------------------------------------------------
-- WebSocket (https://docs.sunc.io/websocket/)
--------------------------------------------------------------------------------

declare extern type sUNCWebSocket with
    --- Connection URL.
    Url: string
    --- Connection ready state (0 connecting, 1 open, 2 closing, 3 closed).
    ReadyState: number
    --- Fired with (message: string) when a message arrives.
    OnMessage: { any }
    --- Fired when the connection closes.
    OnClose: { any }
    --- Sends data through the socket.
    function Send(self, data: string): ()
    --- Closes the socket.
    function Close(self): ()
end

--- Opens a WebSocket connection to the given ws:// or wss:// URL.
declare websocket: {
    --- Opens a WebSocket connection to the given ws:// or wss:// URL.
    connect: (url: string) -> sUNCWebSocket,
}
