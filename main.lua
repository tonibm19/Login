function Initialize( Plugin )
	PLUGIN = Plugin
	Plugin:SetVersion(0)
	Plugin:SetName( "Login" )
	
	PluginManager = cRoot:Get():GetPluginManager()
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_EXECUTE_COMMAND)
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_CHAT)
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_DISCONNECT)
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_TAKE_DAMAGE)
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_PLAYER_PLACING_BLOCK)
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_PLAYER_BREAKING_BLOCK)
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_PLAYER_SPAWNED)
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_PLAYER_MOVING)
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_PLAYER_TOSSING_ITEM)
	
	LoadSettings()
	CreateTables()
	LoadSettings()
	LoadPasswords()
	LoadPlayers()
	if string.upper(Storage) == "SQLITE" then
		dofile( PLUGIN:GetLocalDirectory() .. "/Commands/sqlite.lua" )
	elseif string.upper(Storage) == "INI" then
		dofile( PLUGIN:GetLocalDirectory() .. "/Commands/ini.lua" )
	else
		LOGWARN( "The given storage scheme is invaild" )
	end
	dofile( PLUGIN:GetLocalDirectory() .. "/Commands/global.lua" )
	if PasswordType == "Chat" then
		PluginManager:BindCommand("/login",       "login.login",         HandleLoginCommand,         "" )
		PluginManager:BindCommand("/register",    "login.register",      HandleRegisterCommand,      "" )
	end
	PluginManager:BindCommand("/changepass",      "login.changepass",    HandleChangePasswordCommand,      "" )
	PluginManager:BindCommand("/logout",          "login.logout",        HandleLogoutCommand,            "" )
	
	LOG( "Initializing " .. Plugin:GetName() .. " v" .. Plugin:GetVersion() )
	return true
end

function OnDisable()
	local LoopPlayers = function( Player )
		if CheckIfAuthenticated( Player ) == true then
			Client = Player:GetClientHandle()
			Client:Kick( "Server reload" )
		end
	end
	cRoot:Get():ForEachPlayer( LoopPlayers )
	PwdDB:close()
end