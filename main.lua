local socket=require("socket")
local sv=socket.connect("localhost",1337)
local https=require("ssl.https")
local http=require("socket.http")
local lfs=require("lfs")
local bit=require("bit")
local bc=require("bc")
local lanes=require("lanes")
local json=require("dkjson")
math.randomseed(socket.gettime())
cnick="^v"
fs={
	exists=function(file)
		return lfs.attributes(file)~=nil
	end,
	isDir=function(file)
		local dat=lfs.attributes(file)
		if not dat then
			return nil
		end
		return dat.mode=="directory"
	end,
	isFile=function(file)
		local dat=lfs.attributes(file)
		if not dat then
			return nil
		end
		return dat.mode=="file"
	end,
	split=function(file)
		local t={}
		for dir in file:gmatch("[^/]+") do
			t[#t+1]=dir
		end
		return t
	end,
	combine=function(filea,fileb)
		local o={}
		for k,v in pairs(fs.split(filea)) do
			table.insert(o,v)
		end
		for k,v in pairs(fs.split(fileb)) do
			table.insert(o,v)
		end
		return filea:match("^/?")..table.concat(o,"/")..fileb:match("/?$")
	end,
	resolve=function(file)
		local b,e=file:match("^(/?).-(/?)$")
		local t=fs.split(file)
		local s=0
		for l1=#t,1,-1 do
			local c=t[l1]
			if c=="." then
				table.remove(t,l1)
			elseif c==".." then
				table.remove(t,l1)
				s=s+1
			elseif s>0 then
				table.remove(t,l1)
				s=s-1
			end
		end
		return b..table.concat(t,"/")..e
	end,
	list=function(dir)
		dir=dir or ""
		local o={}
		for fn in lfs.dir(dir) do
			if fn~="." and fn~=".." then
				table.insert(o,fn)
			end
		end
		return o
	end,
}
function tpairs(tbl)
	local s={}
	local c=1
	for k,v in pairs(tbl) do
		s[c]=k
		c=c+1
	end
	c=0
	return function()
		c=c+1
		return s[c],tbl[s[c]]
	end
end
function string.tmatch(str,...)
	local o={}
	for r in str:gmatch(...) do
		table.insert(o,r)
	end
	return o
end
getmetatable("").tmatch=string.tmatch
file=setmetatable({},{
	__index=function(s,n)
		local file=io.open(n,"r")
		return file and file:read("*a")
	end,
	__newindex=function(s,n,d)
		if not d then
			lfs.delete(n)
		else
			local file=io.open(n,"w")
			file:write(d)
			file:close()
		end
	end,
})
function math.round(num,idp)
	local mult=10^(idp or 0)
	return math.floor(num*mult+0.5)/mult
end
function table.reverse(tbl)
    local size=#tbl
    local o={}
    for k,v in ipairs(tbl) do
		o[size-k]=v
    end
	for k,v in pairs(o) do
		tbl[k+1]=v
	end
	return tbl
end
function pescape(txt)
	local o=txt:gsub("[%.%[%]%(%)%%%*%+%-%?%^%$]","%%%1"):gsub("%z","%%z")
	return o
end
local function send(txt)
	sv:send(txt.."\n")
end
local function respond(user,txt)
	if not txt:match("^\1.+\1$") then
		txt=txt:gsub("\1","")
	end
	send(
		(user.chan==cnick and "NOTICE " or "PRIVMSG ")..
		(user.chan==cnick and user.nick or user.chan)..
		" :"..txt
		:gsub("^[\r\n]+",""):gsub("[\r\n]+$",""):gsub("[\r\n]+"," | ")
		:gsub("[%z\2\4\5\6\7\8\9\10\11\12\13\14\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]","")
		:sub(1,446)
	)
end
dofile("hook.lua")
dofile("db.lua")

hook.new("raw",function(txt)
	txt:gsub("^:"..cnick.." MODE "..cnick.." :%+i",function()
		send("JOIN #oc")
		send("JOIN #ocbots")
		send("JOIN #OpenPrograms")
	end)
	txt:gsub("^PING (.+)",function(pong)
		sv:send("PONG "..pong.."\n")
	end)
end)
local plenv=setmetatable({
	socket=socket,
	sv=sv,
	https=https,
	http=http,
	lfs=lfs,
	send=send,
	respond=respond,
	hook=hook,
	bit=bit,
	sql=sql,
	bc=bc,
	json=json,
	lanes=lanes,
},{__index=_G,__newindex=_G})
plenv._G=plenv
hook.new("msg",function(user,chan,txt)
	txt=txt:gsub("%s+$","")
	if txt:sub(1,1)=="." then
		local err,res=xpcall(function()
			print(user.nick.." used "..txt)
			local cb=function(st,dat)
				if st==true then
					print("responding with "..tostring(dat))
					respond(user,tostring(dat))
				elseif st then
					print("responding with "..tostring(st))
					respond(user,user.nick..", "..tostring(st))
				end
			end
			hook.callback=cb
			hook.queue("command",user,chan,txt:sub(2))
			local cmd,param=txt:match("^%.(%S+) ?(.*)")
			if cmd then
				hook.callback=cb
				hook.queue("command_"..cmd,user,chan,param)
			end
		end,debug.traceback)
		if not err then
			print(res)
			respond(user,"Oh noes! "..paste(res))
		end
	end
end)

for fn in lfs.dir("plugins") do
	if fn:sub(-4,-1)==".lua" then
		setfenv(assert(loadfile("plugins/"..fn)),plenv)()
	end
end

send("WHOIS "..cnick)
sv:settimeout(0)
hook.newsocket(sv)
while true do
	local s,e=sv:receive()
	if s then
		hook.queue("raw",s)
	else
		if e=="closed" then
			error(e)
		end
	end
	hook.queue("select",socket.select(hook.sel,nil,math.min(10,hook.interval or 10)))
end