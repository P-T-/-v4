#include "lua.h"
#include "lauxlib.h"
#include "ljitauxlib.h"

extern int lib_udataptr(lua_State* L) {
	luaL_pushpointer(L,lua_touserdata(L,1));
	return 1;
}

extern int lib_dump(lua_State* L) {
	size_t size;
	void* data=luaL_checklcdata(L,1,&size);
	lua_pushlstring(L,(const char*)data,size);
	return 1;
}

extern int lib_udump(lua_State* L) {
	const char* tp=luaL_checkstring(L,1);
	size_t size;
	const char* data=luaL_checklstring(L,2,&size);
	luaL_pushcdata(L,(void*)data,size,tp);
	return 1;
}
