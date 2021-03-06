function fancynum(num)
	num,neg=tostring(num):gsub("[^%d%.]",""),tostring(num):match("^%-") or ""
	return neg..num:gsub("%..+",""):reverse():gsub("...","%1,"):reverse():gsub("^,","")..(num:match("%..+") or "")
end

hook.new({"command_forums","command_f"},function(user,chan,txt)
	return "http://oc.cil.li/"
end,{
	desc="links to the forums",
	group="help",
})

hook.new({"command_git","command_github"},function(user,chan,txt)
	return "https://github.com/MightyPirates/OpenComputers/"..txt
end,{
	desc="links to the oc github",
	group="help",
})

hook.new({"command_rules"},function(user,chan,txt)
	return "http://oc.cil.li/index.php?/topic/171-oc-channel-rules/"
end,{
	desc="links to the channel rules",
	group="help",
})

hook.new({"command_opencomponents","command_openc"},function(user,chan,txt)
	return "http://ci.cil.li/job/OpenComponents/"..txt
end,{
	desc="links to the opencomponents jenkins",
	group="help",
})

jenkins={
	[{"http://ci.cil.li/job/OpenComputers-1.3-MC1.6.4/api/json?depth=1","OpenComputers"}]={"","oc","opencomputers","16","164","oc16","oc164"},
	[{"http://ci.cil.li/job/OpenComputers-1.3-MC1.7.2/api/json?depth=1","OpenComputers 1.7"}]={"opencomputers17","17","172","oc17","oc172"},
	[{"http://ci.cil.li/job/OpenComputers-dev-MC1.7.10/api/json?depth=1","OpenComputers 1.7.10"}]={"opencomputers1710","1710","oc1710","oc1710"},
	[{"http://ci.cil.li/job/OpenComponents-MC1.6.4/api/json?depth=1","OpenComponents"}]={"c","c16","components","opencomponents","ocomponents"},
	[{"http://ci.cil.li/job/OpenComponents-MC1.7/api/json?depth=1","OpenComponents 1.7"}]={"c17","components17","opencomponents17","ocomponents17"},
	[{"http://lanteacraft.com/jenkins/job/OpenPrinter/api/json?depth=1","OpenPrinters"}]={"op","op16","printer","printer16","openprinter","openprinters","openprinter16"},
	[{"http://lanteacraft.com/jenkins/job/OpenPrinter1.7/api/json?depth=1","OpenPrinters 1.7"}]={"op17","printer17","openprinter17","openprinters16"},
}
for k,v in tpairs(jenkins) do
	for n,l in pairs(v) do
		jenkins[l]=k
	end
	jenkins[k]=nil
end
hook.new({"command_j","command_build","command_beta"},function(user,chan,txt)
	txt=txt:lower():gsub("[%s%.]","")
	if jenkins[txt] then
		local dat,err=ahttp.get(jenkins[txt][1])
		if not dat then
			if err then
				return "Error grabbing "..jenkins[txt][1].." ("..err..")"
			else
				return "Error grabbing "..jenkins[txt][1]
			end
		end
		local dat=json.decode(dat)
		if not dat then
			return "Error parsing page."
		end
		dat=dat.lastSuccessfulBuild
		local miliseconds=(socket.gettime()*1000)-dat.timestamp
		local seconds=math.floor(miliseconds/1000)
		local minutes=math.floor(seconds/60)
		local hours=math.floor(minutes/60)
		local days=math.floor(hours/24)
		miliseconds=miliseconds~=0 and ((miliseconds%1000).." milliseconds ") or ""
		seconds=seconds~=0 and ((seconds%60).." second"..(seconds~=1 and "s " or " ")) or ""
		minutes=minutes~=0 and ((minutes%60).." minute"..(minutes~=1 and "s " or " ")) or ""
		hours=hours~=0 and ((hours%24).." hour"..(hours%24==1 and " " or "s ")) or ""
		days=days~=0 and (days.." day"..(days~=1 and "s " or " ")) or ""
		local url
		for k,v in pairs(dat.artifacts) do
			if v.relativePath:match("%-universal.jar$") then
				url=v.relativePath
			end
		end
		url=url or dat.artifacts[1].relativePath
		return "Build #"..dat.number.." for "..jenkins[txt][2]..": "..shorturl(dat.url.."artifact/"..url).." "..days..hours..minutes.."ago"
	end
end,{
	desc="links downloads for jenkins",
	group="help",
})

hook.new({"command_r","command_release","command_releases"},function(user,chan,txt)
	local dat,err=https.request("https://api.github.com/repos/MightyPirates/OpenComputers/releases")
	if not dat then
		if err then
			return "Error grabbing page. ("..err..")"
		else
			return "Error grabbing page."
		end
	end
	local dat=json.decode(dat)
	if not dat or not dat[1] or not dat[1].assets then
		error("Error parsing. "..serialize(dat))
	end
	dat=dat[1]
	local burl="https://github.com/MightyPirates/OpenComputers/releases/download/"..dat.tag_name.."/"
	local o=""
	for k,v in pairs(dat.assets) do
		o=o.." "..v.name:match("MC([^%-]+)").." "..shorturl(burl..v.name)
	end
	return "Latest release: "..dat.name.." Download:"..o
end,{
	desc="links downloads for releases",
	group="help",
})

hook.new({"command_dlstats","command_downloads"},function(user,chan,txt)
	local dat,err=https.request("https://api.github.com/repos/MightyPirates/OpenComputers/releases")
	if not dat then
		if err then
			return "Error grabbing page. ("..err..")"
		else
			return "Error grabbing page."
		end
	end
	local dat=json.decode(dat)
	if not dat then
		return "Error parsing."
	end
	local total=0
	local v16=0
	local v17=0
	local cnt
	local mx=0
	for k,v in pairs(dat) do
		local cn=0
		if v.assets[1] then
			local c=v.assets[1].download_count
			total=total+c
			v16=v16+c
			cn=cn+c
		end
		if v.assets[2] then
			local c=v.assets[1].download_count
			total=total+c
			v17=v17+c
			cn=cn+c
		end
		if cn>mx then
			cnt=v.name
			mx=cn
		end
	end
	return "Total: "..fancynum(total).." 1.6: "..math.round((v16/total)*100,2).."% 1.7: "..math.round((v17/total)*100,2).."% Most popular: "..cnt.." with "..fancynum(mx).." downloads"
end,{
	desc="oc github download statistics",
	group="help",
})

local help={
	"component.doc(address:string, method:string):string Returns the documentation string for the method with the specified name of the component with the specified address, if any.",
	"component.invoke(address:string, method:string[, ...]):... Calls the method with the specified name on the component with the specified address, passing the remaining arguments as arguments to that method.",
	"component.list([filter:string]):function Returns an iterator over all components currently attached to the computer, providing tuples of address and component type.",
	"component.proxy(address:string):table Gets a 'proxy' object for a component that provides all methods the component provides as fields, so they can be called more directly (instead of via invoke).",
	"component.type(address:string):string Get the component type of the component with the specified address.",
	"component.get(address: string[, componentType: string]):string | (nil, string) Tries to resolve an abbreviated address to a full address. Returns the full address on success, or nil and an error message otherwise.",
	"component.isAvailable(componentType: string):boolean Checks if there is a primary component of the specified component type.",
	"component.getPrimary(componentType: string):table Gets the proxy for the primary component of the specified type. Throws an error if there is no primary component of the specified type.",
	"component.setPrimary(componentType: string, address: string) Sets a new primary component for the specified component type. The address may be abbreviated, but must be valid if it is not nil.",
	"component.list([filter: string]):function Returns an iterator which returns pairs of address, type for each component connected to the computer. It optionally takes a filter - if specified this will only return those components for which the filter is a substring of the component type.",
	"computer.address():string The component address of this computer.",
	"computer.romAddress():string The component address of the computer's ROM file system, used for mounting it on startup.",
	"computer.tmpAddress():string The component address of the computer's temporary file system (if any), used for mounting it on startup.",
	"computer.freeMemory():number The amount of memory currently unused, in bytes. If this gets close to zero your computer will probably soon crash with an out of memory error.",
	"computer.totalMemory():number The total amount of memory installed in this computer, in bytes.",
	"computer.energy():number The amount of energy currently available in the network the computer is in. For a robot this is the robot's own energy / fuel level.",
	"computer.maxEnergy():number The maximum amount of energy that can be stored in the network the computer is in. For a robot this is the size of the robot's internal buffer (what you see in the robot's GUI).",
	"computer.isRobot():boolean This method is deprecated, it will be removed soon. Use component.isAvailable(\"robot\") instead.",
	"computer.uptime():number The time in real world seconds this computer has been running, measured based on the world time that passed since it was started - meaning this will not increase while the game is paused, for example.",
	"computer.shutdown([reboot: boolean]) Shuts down the computer. Optionally reboots the computer, if reboot is true, i.e. shuts down, then starts it again automatically.",
	"computer.users():string,... A list of all users registered on this computer, as a tuple. See .help users",
	"computer.addUser(name: string):boolean or nil, string Registers a new user with this computer. See .help users",
	"computer.removeUser(name: string):boolean Unregisters a user from this computer. Returns true if the user was removed. See .help users",
	"computer.pushSignal(name: string[, ...]) Pushes a new signal into the queue. Signals are processed in a FIFO order. The signal has to at least have a name. Arguments to pass along with it are optional.",
	"computer.pullSignal([timeout: number]):name,... Tries to pull a signal from the queue, waiting up to the specified amount of time before failing and returning nil. Use event.pull instead.",
	"event.listen(name: string, callback: function):boolean Register a new event listener that should be called for events with the specified name.",
	"event.ignore(name: string, callback: function):boolean Unregister a previously registered event listener. Returns true if the event listener was removed, false if the listener was not registered.",
	"event.timer(interval: number, callback:function[, times: number]):number Starts a new timer that will be called after the time specified in interval. Per default, timers only fire once. Pass times with a value larger than one to have it fire as often as that number specifies.",
	"event.cancel(timerId: function):boolean Cancels a timer previously created with event.timer. Returns true if the timer was stopped, false if there was no timer with the specified ID.",
	"event.pull([timeout: number], [name: string], ...):string,... This, besides os.sleep() should be the primary way for programs to \"yield\". This function can be used to await signals from the queue, while having unrelated signals dispatched as events.",
	"event.shouldInterrupt():boolean This function is called by event.pull after each signal was processed, to check whether it should abort early. If this returns true, event.pull will throw an interrupted error.",
	"event.onError(message: any) Global event callback error handler. If an event listener throws an error, we handle it in this function to avoid it bubbling into unrelated code (that only triggered the execution by calling event.pull).",
	"filesystem.isAutorunEnabled():boolean Returns whether autorun is currently enabled. If this is true, newly mounted file systems will be checked for a file named autorun[.lua] in their root directory.",
	"filesystem.setAutorunEnabled(value: boolean) Sets whether autorun files should be ran on startup.",
	"filesystem.canonical(path: string): string Returns the canonical form of the specified path, i.e. a path containing no \"indirections\" such as . or ...",
	"filesystem.concat(pathA: string, pathB: string[, ...]):string Concatenates two or more paths. Note that all paths other than the first are treated as relative paths, even if they begin with a slash.",
	"filesystem.path(path: string):string Returns the path component of a path to a file, i.e. everything before the last slash in the canonical form of the specified path.",
	"filesystem.name(path: string):string Returns the file name component of a path to a file, i.e. everything after the last slash in the canonical form of the specified path.",
	"filesystem.proxy(filter: string):table | nil, string This is similar to component.proxy, except that the specified string may also be a file system component's label. We check for the label first, if no file system has the specified label we fall back to component.proxy",
	"filesystem.mount(fs: table or string, path: string): boolean | nil, string Mounts a file system at the specified path. The first parameter can be either a file system component's proxy, its address or its label.",
	"filesystem.mounts():function -> table, string Returns an iterator function over all currently mounted file system component's proxies and the paths at which they are mounted.",
	"filesystem.umount(fsOrPath: table or string):boolean Unmounts a file system. The parameter can either be a file system component's proxy or (abbreviated) address.",
	"filesystem.get(path: string):table, string or nil, string Gets the file system component's proxy that contains the specified path.",
	"filesystem.exists(path: string):boolean Checks whether a file or folder exist at the specified path.",
	"filesystem.size(path: string):number Gets the file size of the file at the specified location. Returns 0 if the path points to anything other than a file.",
	"filesystem.isDirectory(path: string):boolean Gets whether the path points to a directory. Returns false if not, either because the path points to a file, or file.exists(path) is false.",
	"filesystem.lastModified(path: string):number Returns the real world unicode timestamp of the last time the file at the specified path was modified. For directories this is usually the time of their creation.",
	"filesystem.list(path: string):function -> string or nil, string Returns an iterator over all elements in the directory at the specified path. Returns nil and an error messages if the path is invalid or some other error occurred.",
	"filesystem.makeDirectory(path: string):boolean or nil, string Creates a new directory at the specified path. Creates any parent directories that do not extist yet, if necessary.",
	"filesystem.remove(path: string):boolean or nil, string Deletes a file or folder. If the path specifies a folder, deletes all files and subdirectories in the folder, recursively.",
	"filesystem.rename(oldPath: string, newPath: string):boolean or nil, string Renames a file or folder. If the paths point to different file system components this will only work for files, because it actually perform a copy operation, followed by a deletion if the copy succeeds.",
	"filesystem.copy(fromPath: string, toPath: string):boolean or nil, string Copies a file to the specified location. The target path has to contain the target file name. Does not support folders.",
	"filesystem.open(path: string[, mode: string]):table or nil, string Opens a file at the specified path for reading or writing. If mode is not specified it defaults to \"r\".",
	"internet.isHttpEnabled():boolean Returns whether HTTP requests are allowed on the server (config setting).",
	"internet.request(url: string[, data: string or table]):function Sends an HTTP request to the specified URL, with the specified POST data, if any. If no data is specified, a GET request will be made.",
	"internet.isTcpEnabled():boolean Returns whether TCP sockets are allowed on the server (config setting).",
	"keyboard.isAltDown():boolean Checks if one of the Alt keys is currently being held by some user.",
	"keyboard.isControl(char: number):boolean Checks if the specified character (from a keyboard event for example) is a control character as defined by Java's Character class. Control characters are usually not printable.",
	"keyboard.isControl(char: number):boolean Checks if the specified character (from a keyboard event for example) is a control character as defined by Java's Character class. Control characters are usually not printable.",
	"keyboard.isKeyDown(charOrCode: any):boolean Checks if a specific key is currently being by some user. If a number is specified it is assumed it's a key code.",
	"keyboard.isShiftDown():boolean Checks if one of the Shift keys is currently being held by some user.",
	"process.load(path:string[, env:table[, init:function[, name:string]]]):coroutine Loads a Lua script from the specified absolute path and sets it up as a process. It will be loaded with a custom environment, to avoid cluttering the callers/global environment.",
	"process.running([level: number]):string, table, string Returns the path to the currently running program (i.e. the last process created via process.load). The level can optionally be provided to get parent processes.",
	"robot.level():number Gets the current level of the robot, with the fractional part being the percentual progress towards the next level.",
	"robot.detect():boolean, string Tests if there is something in front of the robot. Returns true if there is something that would block the robot's movement, false otherwise. The second value can be: entity, solid, replaceable, liquid and air.",
	"robot.detectUp():boolean, string Like robot.detect, but for the block above the robot.",
	"robot.detectDown():boolean, string Like robot.detect, but for the block below the robot.",
	"robot.select([slot: number]):number Selects the inventory slot with the specified index, which is an integer in the interval [1, 16].",
	"robot.count([slot: number]):number Gets the number of item in the specified inventory slot. If no slot is specified returns the number of items in the selected slot.",
	"robot.space([slot: number]):number Gets how many more items can be put into the specified slot, which depends on the item already in the slot (for example, buckets only stack up to 16, so if there are 2 buckets in the slot this will return 14).",
	"robot.compareTo(slot: number):boolean Compares the item in the currently selected slot to the item in the specified slot. Returns true if the items are equal (i.e. the stack size does not matter), false otherwise.",
	"robot.transferTo(slot: number[, count: number]):boolean Moves items from the selected slot into the specified slot. If count is specified only moves up to this number of items.",
	"robot.compare():boolean Compares the item in the currently selected inventory slot to the block in front of the robot. Returns true if the block is equivalent to the item at the selected slot, false otherwise.",
	"robot.compareUp():boolean Like robot.compare, but for the block above the robot.",
	"robot.compareDown():boolean Like robot.compare, but for the block below the robot.",
	"robot.drop([count: number]):boolean Drops items from the selected inventory slot. If count is specified only drops up to that number of items. If the robot faces a block with an inventory, such as a chest, it will try to insert the items into that inventory.",
	"robot.dropUp([count: number]):boolean Like robot.drop, but drops into inventories or the block above the robot.",
	"robot.dropDown([count: number]):boolean Like robot.drop, but drops into inventories or the block below the robot.",
	"robot.place([side: number[, sneaky: boolean]]):boolean Places a block from the selected inventory slot in front of the robot. Returns true on success, false otherwise. The side parameter determines the \"surface\" on which to try to place the block. If it is omitted the robot will try all surfaces.",
	"robot.placeUp([side: number[, sneaky: boolean]]):boolean Like robot.place, but for placing blocks above the robot.",
	"robot.placeDown([side: number[, sneaky: boolean]]):boolean Like robot.place, but for placing blocks below the robot.",
	"robot.suck([count: number]):boolean Sucks at maximum one stack into the selected slot, or the first free slot after the selected slot. Returns true if one or more items were picked up, false otherwise.",
	"robot.suckUp([count: number]):boolean Like robot.suck, but for inventories or items lying above the robot.",
	"robot.suckDown([count: number]):boolean Like robot.suck, but for inventories or items lying below the robot.",
	"robot.durability():number or nil, string If the robot has a tool equipped, this can be used to check the remaining durability of that tool. Returns the remaining durability, if the tool has durability, nil and a reason otherwise.",
	"robot.swing([side: number]):boolean[, string] Makes the robot perform a \"left click\", using the currently equipped tool, if any. The result of this action depends on what is in front of the robot.",
	"robot.swingUp([side: number]):boolean[, string] Like robot.swing, but towards the area above the robot.",
	"robot.swingDown([side: number]):boolean[, string] Like robot.swing, but towards the area below the robot.",
	"robot.use([side: number[, sneaky:boolean[, duration: number]]]):boolean[, string] Makes the robot perform a \"right click\", using the currently equipped tool, if any. The result on this action depends on what is in front of the robot. Returns true if something happened, false otherwise.",
	"robot.useUp([side: number[, sneaky:boolean[, duration: number]]]):boolean[, string] Like robot.use, but towards the area above the robot.",
	"robot.useDown([side: number[, sneaky:boolean[, duration: number]]]):boolean[, string] Like robot.use, but towards the area below the robot.",
	"robot.forward():boolean[, string] Makes the robot try to move into the block in front of it. Returns true if the robot moved successfully, nil and a reason otherwise. The reason string will be one of the blocking results from the robot.detect function.",
	"robot.back():boolean[, string] Like robot.forward, but makes the robot try to move into the block behind it.",
	"robot.up():boolean[, string] Like robot.forward, but makes the robot try to move into the block above it.",
	"robot.down():boolean[, string] Like robot.forward, but makes the robot try to move into the block below it.",
	"robot.turnLeft() Makes the robot turn by 90 degrees to its left.",
	"robot.turnRight() Makes the robot turn by 90 degrees to its right.",
	"robot.turnAround() Makes the robot turn around by 180 degrees.",
	"serialization.serialize(value: any except functions[, pretty:boolean]):string Generates a string from an object that can be parsed again using serialization.unserialize. The generated output is Lua code.",
	"serialization.unserialize(value: string):... Restores an object previously saved with serialization.serialize.",
	"shell.getAlias(alias: string):string Gets the value of a specified alias, if any. If there is no such alias returns nil.",
	"shell.setAlias(alias: string, value: string or nil) Defines a new alias or updates an existing one. Pass nil as the value to remove an alias. Note that aliases are not limited to program names, you can include parameters as well. For example, view is a default alias for edit -r.",
	"shell.aliases():function Returns an iterator over all known aliases.",
	"shell.getWorkingDirectory(): string Gets the path to the current working directory. This is an alias for os.getenv(\"PWD\").",
	"shell.setWorkingDirectory(dir: string) Sets the current working directory. This is a checked version of os.setenv(\"PWD\", dir).",
	"shell.getPath():string Gets the search path used by shell.resolve. This can contain multiple paths, separated by colons (:). This is an alias for os.getenv(\"PATH\").",
	"shell.setPath(value: string) Sets the search path. Note that this will replace the previous search paths. To add a new path to the search paths, do this: shell.setPath(shell.getPath() .. \":/some/path\")",
	"shell.resolve(path: string[, ext: string]):string Tries to \"resolve\" a path, optionally also checking for files with the specified extension, in which case path would only contain the name.",
	"shell.execute(command: string, env: table[, ...]):boolean ... Runs the specified command. This runs the default shell (see os.getenv(\"SHELL\")) and passes the command to it. env is the environment table to use for the shell.",
	"shell.parse(...):table, table Utility methods intended for programs to parse their arguments. Will return two tables, the first one containing any \"normal\" parameters, the second containing \"options\".",
	"shell.running([level: number]):string Deprecated, use \"process.running\".",
	"term.isAvailable():boolean Returns whether the term API is available for use, i.e. whether a primary GPU an screen are present. In other words, whether term.read and term.write will actually do something.",
	"term.getCursor():number, number Gets the current position of the cursor.",
	"term.setCursor(col: number, row: number) Sets the cursor position to the specified coordinates.",
	"term.getCursorBlink():boolean Gets whether the cursor blink is currently enabled, i.e whether the cursor alternates between the actual \"pixel\" displayed at the cursor position and a fully white block every half second.",
	"term.setCursorBlink(enabled: boolean) Sets whether cursor blink should be enabled or not.",
	"term.clear() Clears the complete screen and resets the cursor position to (1, 1).",
	"term.clearLine() Clears the line the cursor is currently on and resets the cursor's horizontal position to 1.",
	"term.read([history: table]):string Read some text from the terminal, i.e. allow the user to input some text. For example, this is used by the shell and Lua interpreter to read user input.",
	"term.write(value: string[, wrap: boolean]) Allows writing optionally wrapped text to the terminal starting at the current cursor position, updating the cursor accordingly.",
	"text.detab(value: string, tabWidth: number):string Converts tabs in a string to spaces, while aligning the tags at the specified tab width. This is used for formatting text in term.write, for example.",
	"text.padRight(value: string, length: number):string Pads a string with whitespace on the right up to the specified length.",
	"text.padLeft(value: string, length: number):string Pads a string with whitespace on the left up to the specified length.",
	"text.trim(value: string):string Removes whitespace characters from the start and end of a string.",
	"text.serialize(value: any except functions):string Deprecated, use \"serialization.serialize\".",
	"text.unserialize(value: string):... Deprecated, use \"serialization.unserialize\".",
	"unicode.char(value: number, ...):string UTF-8 aware version of string.char. The values may be in the full UTF-8 range, not just ASCII.",
	"unicode.len(value: string):number UTF-8 aware version of string.len. For example, for Ümläüt it'll return 6, where string.len would return 9.",
	"unicode.lower(value: string):string UTF-8 aware version of string.lower.",
	"unicode.reverse(value: string):string UTF-8 aware version of string.reverse. For example, for Ümläüt it'll return tüälmÜ, where string.reverse would return tälm.",
	"unicode.sub(value: string, i:number[, j:number]):string UTF-8 aware version of string.sub.",
	"unicode.upper(value: string):string UTF-8 aware version of string.upper.",
	"command_block.getValue():string Gets the currently set command.",
	"command_block.setValue(value: string):boolean Sets a new command for the command block. Returns true on success.",
	"command_block.run():number Tries to execute the command set in the command block. May use a custom (fake) username for executing commands as set in the config. Returns the numeric result from running the command, usually larger than one for success, zero for failure.",
	"computer.start():boolean Tries to start the computer. Returns true on success, false otherwise. Note that this will also return false if the computer was already running.",
	"computer.stop():boolean Tries to stop the computer. Returns true on success, false otherwise. Also returns false if the computer is already stopped.",
	"computer.isRunning():boolean Returns whether the computer is currently running.",
	"crafting.craft([count: number]):boolean Tries to craft something from the items in the top left 3x3 area of the robot's inventory. If count is specified will only craft up that number of items. If count is lower than the number of items created in one crafting operation, nothing will be crafted (e.g. trying to craft one stick).",
	"generator.count():number The current number of fuel items still in the generator.",
	"generator.insert([count: number]):boolean[,string] Inserts up to the specified number of fuel items from the currently selected inventory slot into the generator's inventory. Returns true if at least one item was moved to the generator's inventory. Returns false and an error message otherwise.",
	"generator.remove([count: number]):boolean Removes up to the specified number of fuel items from the generator and places them into the currently selected slot or the first free slot after it.",
	"gpu.bind(address: string):boolean[,string] Tries to bind the GPU to a screen with the specified address. Returns true on success, false and an error message on failure.",
	"gpu.getBackground():number Gets the current background color. This background color is applied to all \"pixels\" that get changed by other operations.",
	"gpu.setBackground(color: number):number Sets the background color to apply to \"pixels\" modified by other operations from now on. The returned value is the old background color, not the actual value it was set to.",
	"gpu.getForeground():number Like getBackground, but for the foreground color.",
	"gpu.setForeground(color: number):number Like setBackground, but for the foreground color.",
	"gpu.maxDepth():number Gets the maximum supported color depth supported by the GPU and the screen it is bound to (minimum of the two).",
	"gpu.getDepth():number The currently set color depth of the GPU/screen, in bits. Can be 1, 4 or 8.",
	"gpu.setDepth(bit: number):boolean Sets the color depth to use. Can be up to the maximum supported color depth. If a larger or invalid value is provided it will throw an error.",
	"gpu.maxResolution():number,number Gets the maximum resolution supported by the GPU and the screen it is bound to (minimum of the two).",
	"gpu.getResolution():number,number Gets the currently set resolution.",
	"gpu.setResolution(width: number, height: number):boolean Sets the specified resolution. Can be up to the maximum supported resolution. If a larger or invalid resolution is provided it will throw an error.",
	"gpu.getSize():number,number Gets the size in blocks of the screen the graphics card is bound to. For simple screens and robots this will be one by one.",
	"gpu.get(x: number, y: number):string Gets the character currently being displayed at the specified coordinates.",
	"gpu.set(x: number, y: number, value: string):boolean Writes a string to the screen, starting at the specified coordinates. The string will be copied to the screen's buffer directly, in a single row. This means even if the specified string contains line breaks, these will just be printed as special characters, the string will not be displayed over multiple lines.",
	"gpu.copy(x: number, y: number, width: number, height: number, tx: number, ty: number):boolean Copies a portion of the screens buffer to another location. The source rectangle is specified by the x, y, width and height parameters. The target rectangle is defined by x + tx, y + ty, width and height. Returns true on success, false otherwise.",
	"gpu.fill(x: number, y: number, width: number, height: number, char: string):boolean Fills a rectangle in the screen buffer with the specified character. The target rectangle is specified by the x and y coordinates and the rectangle's width and height. The fill character char must be a string of length one, i.e. a single character.",
	"hologram.clear() Clears the hologram.",
	"hologram.get(x:number,z:number):number Returns the bit mask representing the specified column.",
	"hologram.set(x:number, z:number, value:number) Set the bit mask for the specified column.",
	"hologram.fill(x:number, z:number, height:number) Fills a column to the specified height. All voxels below and including the specified height will be set, all voxels above will be unset.",
	"hologram.getScale():number Returns the current render scale of the hologram.",
	"hologram.setScale(value:number) Set the render scale. A larger scale consumes more energy. The minimum scale is 0.33, where the hologram will fit in a single block space, the maximum scale is 3, where the hologram will take up a 9x6x9 block space.",
	"internet.isHttpEnabled():boolean Returns whether HTTP requests are allowed on the server (config setting).",
	"internet.isTcpEnabled():boolean Returns whether TCP sockets are allowed on the server (config setting).",
	"internet.request(url:string[, postData:string]):boolean Begins an HTTP request to the specified URL with the specified POST data (if any). Responses will be enqueued as http_response signals. Consider using the iterator wrapper in the Internet API instead.",
	"internet.connect(address:string[, port:number]):number Opens a new TCP connection. Returns the handle of the connection. The returned handle can be used to interact with the opened socket using the other callbacks. This can error if TCP sockets are not enabled, there are too many open connections or some other I/O error occurs.",
	"internet.read(handle:number, n:number):string Tries to read data from the socket stream. Returns the read byte array. Takes the handle returned from internet.connect.",
	"internet.write(handle:number, data:string):number Tries to write data to the socket stream. Returns the number of bytes written. Takes the handle returned by internet.connect.",
	"internet.close(handle:number) Closes the socket with the specified handle (obtained from internet.connect).",
	"modem.isWireless():boolean Returns whether this modem is capable of sending wireless messages.",
	"modem.maxPacketSize(): number Returns the maximum packet size for sending messages via network cards. Defaults to 8192. You can change this in the OpenComputer configuration file.",
	"modem.isOpen(port: number):boolean Returns whether the specified \"port\" is currently being listened on. Messages only trigger signals when they arrive on a port that is open.",
	"modem.open(port: number):boolean Opens the specified port number for listening. Returns true if the port was opened, false if it was already open.",
	"modem.close([port: number]):boolean Closes the specified port (default: all ports). Returns true if ports were closed.",
	"modem.send(address: string, port: number[, ...]):boolean Sends a network message to the specified address. Returns true if the message was sent. This does not mean the message was received, only that it was sent. No port-sniffing for you.",
	"modem.broadcast(port: number, ...):boolean Sends a broadcast message. This message is delivered to all reachable network cards. Returns true if the message was sent. Note that broadcast messages are not delivered to the modem that sent the message.",
	"modem.getStrength():number The current signal strength to apply when sending messages. Wireless network cards only.",
	"modem.setStrength(value: number):number Sets the signal strength. If this is set to a value larger than zero, sending a message will also generate a wireless message.",
	"navigation.getPosition():number,number,(number|nil),string Gets the current relative position of the robot. This is the position relative to the center of the map item that was used to craft the upgrade. Note that the upgrade can be re-crafted with another map to change it's point of reference.",
	"navigation.getFacing():number Gets the current facing of the robot, as one of the sides constants.",
	"navigation.getRange():number Gets the effective range of the upgrade. If the absolute value of the relative X or Z coordinate becomes larger than this, getPosition() will fail.",
	"note_block.getPitch():number Gets the current pitch set on the note block. This will always be a number in the interval [1, 25].",
	"note_block.setPitch(value: number):boolean Sets the pitch for the note block. Must be a number in the interval [1, 25] or this will throw an error. Will return true on success.",
	"note_block.trigger([pitch: number]):boolean Plays a note on the note block. If specified, sets the given pitch first, which must be in the interval [1, 25]. Returns true if a note was played, i.e. the block above the note block is an air block.",
	"redstone.getInput(side: number):number Gets the current ingoing redstone signal from the specified side. Note that the side is relative to the computer's orientation, i.e.",
	"redstone.getOutput(side: number):number Gets the currently set output on the specified side.",
	"redstone.setOutput(side: number, value: number):number Sets the strength of the redstone signal to emit on the specified side. Returns the new value. This can be an arbitrarily large number for mods that support this.",
	"redstone.getBundledInput(side: number, color: number):number Like getInput, but for bundled input, reading the value for the channel with the specified color.",
	"redstone.getBundledOutput(side: number, color: number):number Like getInput, but for bundled input, reading the value for the channel with the specified color.",
	"redstone.getBundledOutput(side: number, color: number):number Like getOutput, but for bundled output, getting the value for the channel with the specified color.",
	"redstone.setBundledOutput(side: number, color: number, value: number):number Like setOutput, but for bundled output, setting the value for the channel with the specified color.",
	"carriage.getAnchored():boolean Gets whether the controller should remain where it is when moving a carriage.",
	"carriage.setAnchored(value: boolean):boolean Sets whether the controller should remain where it is when moving a carriage. Returns the new value.",
	"carriage.move(direction: (string|number)[, simulate: boolean]):boolean Tells the controller to try to move a carriage. The direction can either be a string indicating a direction or one of the [[sides|API/Sides]] constants. You can optionally specify whether to only simulate a move, which defaults to false.",
	"carriage.simulate(direction: string or number):boolean Like move(direction, true).",
	"sign.getValue():(string|nil),string Gets the text currently displayed on the sign in front of the robot, or nil and an error message if there is no sign in front of the robot.",
	"sign.setValue(value: string):(string|nil),string Sets the text of the sign in front of the robot. Returns the new text on the sign (which may be a truncated version of the passed argument) or nil and an error message if there is no sign in front of the robot.",
}

local o={}
local alias={
	["filesystem"]={"allurhddz","fs"},
	["redstone"]={"brainhurt","wires","rs"},
	["navigation"]={"sense_of_direction","gps"},
	["robot"]={"beepboop","turtle"},
	["modem"]={"allurrfz","rednot","rednet"},
	["command_block"]={"commandblock"},
	["computer"]={"infected","comp"},
	[".+"]={"%1%(%)"}
}
for k,v in pairs(help) do
	local func=v:match("^[^%(]+"):lower()
	o[func]=v
	for n,l in pairs(alias) do
		if func:match("^"..n.."%.") then
			for m,s in pairs(l) do
				o[func:gsub(n,s)]=v
			end
		end
	end
end
help=o

local owikinames
do
	local wikinames={
		["api:colors"]={"color","colors","color api","colors api"},
		["api:component"]={"component api","components api","component"},
		["api:computer"]={"computer","computer api"},
		["api:event"]={"event","events","event api","events api"},
		["api:filesystem"]={"fs","filesystem","fs api","filesystem api"},
		["api:internet"]={"internet","internet api","tcp","socket","sockets","http","http api"},
		["api:keyboard"]={"keyboard","keys","keyboard api","keys api"},
		["api:robot"]={"robot","robots","robot api","robots api","turtle","turtle api"},
		["api:serialization"]={"serialize","serialization","serial","serializer"},
		["api:shell"]={"shell api","shell"},
		["api:sides"]={"sides","sides api"},
		["api:term"]={"term","term api"},
		["api:text"]={"text","text api"},
		["api:unicode"]={"unicode","unicode api"},
		["api"]={"apis","api","api list","apis list"},
		["start?idx=block"]={"blocks","block list","blocks list"},
		["component:abstract-bus"]={"abstract bus"},
		["component:access_point"]={"access point","relay"},
		["component:chunkloader"]={"chunkloader","chunk loader","anchor"},
		["component:commandblock"]={"command block","commandblock","command block component"},
		["component:computer"]={"computer component","component computer"},
		["component:crafting"]={"crafting","crafter","crafting component","crafter component","craft api","crafting api","crafter api"},
		["component:generator"]={"generator","generator component","generator api"},
		["component:gpu"]={"gpu","gpu api","gpu component"},
		["component:modem"]={"modem","modem api","modem component","rednet","wireless","wireless api","rednet api"},
		["component:navigation"]={"navigation","navigation api","gps","gps api"},
		["component:noteblock"]={"noteblock","noteblock api","noteblock component"},
		["component:tractor_beam"]={"tractor beam","tractorbeam"},
		["component:tunnel"]={"tunnel component","tunnel","linked","linked card"},
		["component:inventory_controller"]={"inventory","inv","inv component","inventory controller"},
		["component:redstone"]={"redstone","rs","redstone api","rs api","redstone component","rs component"},
		["component:redstoneinmotion"]={"redstone in motion","rim","redstone in motion api","rim api","redstone in motion component","rim component"},
		["component:sign"]={"sign","sign api","sign component"},
		["component:filesystem"]={"filesystem component","fs component"},
		["component:hologram"]={"holo","hologram","hologram component"},
		["componentaccess"]={"component access"},
		["component"]={"components","component list","components list"},
		["computercraft"]={"computercraft","cc"},
		["computer_users"]={"users","perms","uac"},
		["items"]={"items","item list","items list"},
		["api:non-standard-lua-libs"]={"non standard lua libs","non standard","nonstandard","sandbox"},
		["component:signals"]={"signal","signals"},
		["tutorial:oc1_basic_computer"]={"tutorial1","tutorial basic","tutorial basic computer","tutorial computer"},
		["tutorial:oc3_hard_drives"]={"tutorial hardrives","tutorial2","tutorial hdd","tutorial hdds","tutorial filesystem","tutorial fs"},
		["tutorial:oc2_writing_code"]={"tutorial3","tutorial code","tutorial coding"},
		["tutorials"]={"tutorials","help","tutorial"},
		["tutorial:program:oppm"]={"oppm","oppm tutorial"},
		["OneThree"]={"onethree","1.3","13"},
		[":http://www.lua.org/manual/5.2/manual.html#6.8"]={"io","io api"},
		[":http://www.lua.org/manual/5.2/manual.html#6.7"]={"bit32","bit32 api","bit","bit api"},
		[":http://www.lua.org/manual/5.2/manual.html#6.6"]={"math","math api"},
		[":http://www.lua.org/manual/5.2/manual.html#6.5"]={"table","table api","tables","tables api"},
		[":http://www.lua.org/manual/5.2/manual.html#6.4"]={"string","string api","strings","strings api"},
		[":http://www.lua.org/manual/5.2/manual.html#6.2"]={"coroutine","coroutine api","coroutines","coroutine api"},
		[":http://www.lua.org/manual/5.1/manual.html#5.4.1"]={"patterns","pattern","regex"},
		[":http://en.wikipedia.org/wiki/Sod's_law"]={"joshtheender","ender","josh"},
		[":http://en.wikipedia.org/wiki/Ping_of_death"]={"ping","pong","v^","^v","pixeltoast"},
		[":http://en.wikipedia.org/wiki/Hydrofluoric_acid"]={"bizzycola","cola","bizzy"},
		[":http://en.wikipedia.org/wiki/OS_X"]={"asie","asiekierka","kierka"},
		[":http://en.wikipedia.org/wiki/Stoner_(drug_user)"]={"kenny"},
		[":http://en.wikipedia.org/wiki/Methylcyclopentadienyl_Manganese_Tricarbonyl"]={"vexatos"},
		[":http://en.wikipedia.org/wiki/Insomnia"]={"kodos"},
		[":http://en.wikipedia.org/wiki/Dustbin"]={"dusty","spiriteddusty","dustbin"},
		[":http://en.wikipedia.org/wiki/Wii_U"]={"ds","ds84182"},
		[":http://ci.cil.li/"]={"jenkins","build","builds","beta"},
	}
	local words={}
	for k,v in pairs(wikinames) do
		for n,w in pairs(v) do
			words[w]=w
			for word in w:gmatch("%S+") do
				words[word]=w
			end
		end
	end
	words["component"]=nil
	words["api"]=nil
	words["list"]=nil
	owikinames=wikinames
	do
		local o={}
		for k,v in pairs(wikinames) do
			for n,l in pairs(v) do
				o[l]=k
			end
		end
		wikinames=o
	end
	local twikinames={}
	for k,v in pairs(wikinames) do
		twikinames[v]=true
	end
	hook.new({"command_wiki","command_w","command_help","command_h"},function(user,chan,txt)
		if chan=="#ccjam" then
			return "http://ccjam.ml/"
		end
		txt=txt:lower()
		local b="http://ocd.cil.li/"
		if txt=="" then
			return b
		end
		if twikinames[txt] then
			return b..txt
		elseif wikinames[txt] then
			local t=wikinames[txt]
			if t:sub(1,1)==":" then
				return t:sub(2)
			else
				return b..t
			end
		elseif help[txt] then
			return help[txt]
		else
			local f={}
			for k,v in pairs(words) do
				table.insert(f,{v,strdist(k,txt)})
			end
			table.sort(f,function(a,b)
				return a[2]<b[2]
			end)
			return "Not found. did you want \""..f[1][1].."\"?"
		end
	end,{
		desc="lists help for functions/wiki pages",
		group="help",
	})
end

do
	local req={}
	for k,v in pairs(owikinames) do
		if k:match("^api%-") then
			local n=k:match("^api%-(.+)")
			local str="local "..n.."=require(\""..n.."\")"
			for n,l in pairs(v) do
				req[l]=str
			end
		elseif k:match("^component%-") then
			local n=k:match("^component%-(.+)")
			local str="local component=require(\"component\") local "..n.."=component."..n
			for n,l in pairs(v) do
				req[l]=str
			end
		end
	end
	for k,v in pairs(owikinames["component:redstoneinmotion"]) do
		req[v]="local component=require(\"component\") local carriage=component.carriage"
	end
	hook.new({"command_req","command_require"},function(user,chan,txt)
		return req[txt:lower()] or "Not found."
	end,{
		desc="generates code to require a component or api",
		group="help",
	})
end

do
	local man={
		["https://github.com/MightyPirates/OpenComputers/wiki/"]={"","oc"},
		["http://www.lua.org/manual/5.2/"]={"lua","5.3"},
	}
	for k,v in tpairs(man) do
		for n,l in pairs(v) do
			man[l]=k
		end
		man[k]=nil
	end
	hook.new({"command_rtfm","command_man"},function(user,chan,txt)
		return man[txt:lower()] or "Not found."
	end)
end

hook.new("init",function()
	local alias={}
	local funcs={}
	local unlisted={}
	for k,v in pairs(hook.hooks) do
		local cmd=k:match("^command_(.*)")
		if cmd then
			local meta=hook.meta[k]
			if meta then
				alias[v[1]]=alias[v[1]] or {}
				table.insert(alias[v[1]],"."..cmd)
				funcs[v[1]]=meta
			else
				table.insert(unlisted,"."..cmd)
			end
		end
	end
	local groups={}
	for k,v in pairs(alias) do
		local meta=funcs[k]
		groups[meta.group]=groups[meta.group] or {}
		v.desc=meta.desc
		table.insert(groups[meta.group],v)
	end
	local file=io.open("www/help.html","w")
	local bfile=io.open("www/help.bbcode","w")
	bfile:write("[size=3]")
	for k,v in pairs(groups) do
		bfile:write("[b][font='lucida sans unicode', 'lucida grande', sans-serif][size=6]"..k..":[/size][/font][/b]\n")
		file:write("<h2>"..k.."</h2>")
		for n,l in pairs(v) do
			bfile:write(table.concat(l," ").." : "..l.desc.."\n")
			file:write(table.concat(l," ").." : "..l.desc.."<br>")
		end
	end
	bfile:close()
	file:write("<br>Unlisted (probably broken): "..table.concat(unlisted," "))
	file:close()
end)

hook.new({"command_forge","command_froge"},function(user,chan,txt)
	local res,err=http.request("http://files.minecraftforge.net")
	if not res then
		return "Error: "..err
	end
	local u16=res:match('<a href="(http://files%.minecraftforge%.net/maven/net/minecraftforge/forge/1%.6[^"]+universal%.jar)">')
	local i16=res:match('<a href="(http://files%.minecraftforge%.net/maven/net/minecraftforge/forge/1%.6[^"]+installer%.jar)">')
	local u17=res:match('<a href="(http://files%.minecraftforge%.net/maven/net/minecraftforge/forge/1%.7[^"]+universal%.jar)">')
	local i17=res:match('<a href="(http://files%.minecraftforge%.net/maven/net/minecraftforge/forge/1%.7[^"]+installer%.jar)">')
	return "1.6: installer "..shorturl(i16).." | univeral "..shorturl(u16).." 1.7: installer "..shorturl(i17).." | univeral "..shorturl(u17)
end)
