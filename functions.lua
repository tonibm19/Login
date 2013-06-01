function CreateTables()
	Auth = {}
	Coords = {}
	PatternCount = {}
	PatternChange = {}
end

function LoadPlayers()
	local LoopPlayers = function( Player )
		Login( Player )
	end
	cRoot:Get():ForEachPlayer( LoopPlayers )
end

function Login( Player )
	Auth[Player:GetName()] = true
	if Coords[Player:GetName()] ~= nil then
		local Coordinates = StringSplit( Coords[Player:GetName()], "," )
		Player:TeleportTo( Coordinates[1], Coordinates[2], Coordinates[3] )
	end
end

function Logout( Player )
	Auth[Player:GetName()] = false
	Coords[Player:GetName()] = Player:GetPosX() .. "," .. Player:GetPosY() .. "," .. Player:GetPosZ()
end

function CheckIfAuthenticated( Player, Action )
	if Action ~= nil then
		if Action == 0 then
			Message = cChatColor.Rose .. "Please login before using commands"
		elseif Action == 1 then
			Message = cChatColor.Rose .. "Please login before chatting"
		elseif Action == 2 then
			Message = cChatColor.Rose .. "Please login before placing blocks"
		elseif Action == 3 then
			Message = cChatColor.Rose .. "Please login before breaking blocks"
		end
		if Auth[Player:GetName()] == false then
			Player:SendMessage( Message )
			return true
		else
			return false
		end
	else
		if Auth[Player:GetName()] == false then
			return true
		else
			return false
		end
	end
end

function LoadSettings()
	SettingsIni = cIniFile( PLUGIN:GetLocalDirectory() .. "/Config.ini" )
	SettingsIni:ReadFile()
	Tries = SettingsIni:GetValueSetI( "General", "Tries", 3 )
	Storage = SettingsIni:GetValueSet( "General", "Storage", "SQLite" )
	PasswordType = SettingsIni:GetValueSet( "General", "Password", "Chat" )
	SettingsIni:WriteFile()
end

function LoadPasswords()
	if string.upper(Storage) == "SQLITE" then
		DB = io.open( PLUGIN:GetLocalDirectory() .. "/Players.sqlite", "r" )
		PwdDB = {}
		PwdDB, ErrCode, ErrMsg = sqlite3.open(PLUGIN:GetLocalDirectory() .. "/Players.sqlite");
		if not DB then
			local CreateTable = [[
							CREATE TABLE Passwords(Name,Password);
							CREATE TABLE Pattern(Name,Pattern);
			]]
			local Res = PwdDB:exec( CreateTable )
			if Res ~= sqlite3.OK then
				LOGWARN("SQL query failed: " .. Res .. " (" .. PwdDB:errmsg() .. ")");
			end
		end
	elseif string.upper(Storage) == "INI" then
		PassIni = cIniFile( PLUGIN:GetLocalDirectory() .. "/Players.ini" )
		if PassIni:ReadFile() == false then
			PassIni:WriteFile()
		end
	end
end

function CheckPassword( Player, Split )
	local Password = PassIni:GetValue( "Passwords", Player:GetName() )
	if Password == nil then
		return false
	elseif Password == md5( Split[2] ) then
		Login( Player )
		Player:SendMessage( cChatColor.LightGreen .. "You logged in" )
		return true
	else
		Player:SendMessage( cChatColor.Rose .. "You entered the wrong password" )
		return
	end
end

function CheckIfAccExist( Player )
	if PassIni:GetValue( "Passwords", Player:GetName() ) == "" then
		return false
	else
		return true
	end
end

function SendRegistrationPattern( Player )
	local WindowType = cWindow.DropSpenser;
	local RegisterWindow = cLuaWindow(WindowType, 3, 3, "Registration. exit to complete");
	for i=0, 8 do
		RegisterWindow:SetSlot(Player, i, cItem(E_BLOCK_WATER, 1));
	end
	PatternCount[Player:GetName()] = 1
	local OnClosing = function(Window, Player)
		local Pattern = ""
		for i=0, 8 do
			Pattern = Pattern .. Window:GetSlot( Player, i ).m_ItemCount .. ","
		end
		PassIni:SetValue( "Pattern", Player:GetName(), md5(Pattern) )
		PassIni:WriteFile()
		Login( Player )
		Player:SendMessage( cChatColor.LightGreen .. "You registered" )
	end
	RegisterWindow:SetOnClosing( OnClosing )
	Player:OpenWindow(RegisterWindow);
end

function WritePatternToSQL( Pattern, Player )
	local UserName = Player:GetName()
	local Res = PwdDB:exec('INSERT INTO Pattern VALUES("' .. UserName .. '", "' .. Pattern .. '");'  )
	if Res ~= sqlite3.OK then
		 LOG("PwdDB:exec() failed: " .. Res .. " (" .. PwdDB:errmsg() .. ")");
	end
end

function SendLoginPattern( Player )
	local WindowType = cWindow.DropSpenser;
	local LoginWindow = cLuaWindow(WindowType, 3, 3, "Login. exit to complete");
	for i=0, 8 do
		LoginWindow:SetSlot(Player, i, cItem(E_BLOCK_LAVA, 1));
	end
	PatternCount[Player:GetName()] = 1
	local OnClosing = function(Window, Player)
		local Pattern = ""
		for i=0, 8 do
			Pattern = Pattern .. Window:GetSlot( Player, i ).m_ItemCount .. ","
		end
		if PassIni:GetValue( "Pattern", Player:GetName() ) == md5(Pattern) then
			Login( Player )
			Player:SendMessage( cChatColor.LightGreen .. "You logged in" )
		else
			PatternCount[Player:GetName()] = PatternCount[Player:GetName()] + 1
			if PatternCount[Player:GetName()] > Tries then
				Player:GetClientHandle():Kick( cChatColor.Rose .. "too many tries" )
			end
			return true
		end
	end
	LoginWindow:SetOnClosing( OnClosing )
	Player:OpenWindow(LoginWindow);
end

function SendSqlRegistrationPattern(  Player )
	local WindowType = cWindow.DropSpenser;
	local RegisterWindow = cLuaWindow(WindowType, 3, 3, "Registration. exit to complete");
	for i=0, 8 do
		RegisterWindow:SetSlot(Player, i, cItem(E_BLOCK_WATER, 1));
	end
	local OnClosing = function( Window, Player )
		local Pattern = ""
		for i=0, 8 do
			Pattern = Pattern .. Window:GetSlot( Player, i ).m_ItemCount .. ","
		end
		WritePatternToSQL( Pattern, Player )
		Login( Player )
	end
	RegisterWindow:SetOnClosing( OnClosing )
	Player:OpenWindow(RegisterWindow);
end

function SendSqlLoginPattern( Player )
	local WindowType = cWindow.DropSpenser;
	local LoginWindow = cLuaWindow(WindowType, 3, 3, "Login. exit to complete");
	for i=0, 8 do
		LoginWindow:SetSlot(Player, i, cItem(E_BLOCK_LAVA, 1));
	end
	PatternCount[Player:GetName()] = 1
	local OnClosing = function( Window, Player )
		local Pattern = ""
		for i=0, 8 do
			Pattern = Pattern .. Window:GetSlot( Player, i ).m_ItemCount .. ","
		end
		local function ProcessRow(UserData, NumCols, Values, Names)
			for i = 1, NumCols do
				if (Names[i] == "Pattern") then  -- "Password" is the column name
					ShouldAllowLogin = (Values[i] == Pattern);
				end
			end
		end
		local Res = PwdDB:exec( 'SELECT * FROM Pattern WHERE Name="' .. Player:GetName() .. '"', ProcessRow, nil )
		if ShouldAllowLogin == true then
			Login( Player )
			return false
		else
			PatternCount[Player:GetName()] = PatternCount[Player:GetName()] + 1
			if PatternCount[Player:GetName()] > Tries then
				Player:GetClientHandle():Kick( cChatColor.Rose .. "too many tries" )
			end
			return true
		end
	end
	LoginWindow:SetOnClosing( OnClosing )
	Player:OpenWindow( LoginWindow )
end

function ChangePattern( Player )
	local WindowType = cWindow.DropSpenser;
	local OldPattern = cLuaWindow(WindowType, 3, 3, "Change Pattern");
	for i=0, 8 do
		OldPattern:SetSlot(Player, i, cItem(E_BLOCK_WALLSIGN, 1));
	end
	local OnClosing = function(Window, Player)
		local Pattern = ""
		for i=0, 8 do
			Pattern = Pattern .. Window:GetSlot( Player, i ).m_ItemCount .. ","
		end
		if PatternChange[Player:GetName()] == true then
			PassIni:DeleteValue( "Pattern", Player:GetName() )
			PassIni:SetValue( "Pattern", Player:GetName(), md5(Pattern) )
			PassIni:WriteFile()
			PatternChange[Player:GetName()] = false
			Player:SendMessage( cChatColor.LightGreen .. "Pattern changed" )
			return false
		end
		if PassIni:GetValue( "Pattern", Player:GetName() ) == md5(Pattern) then
			for i=0, 8 do
				Window:SetSlot(Player, i, cItem(E_BLOCK_SUGARCANE, 1 ));			
				PatternChange[Player:GetName()] = true
			end
			return true
		else
			Player:SendMessage( cChatColor.Rose .. "Wrong pattern" )
		end
	end
	OldPattern:SetOnClosing( OnClosing )
	Player:OpenWindow(OldPattern);
end

function ChangeSqlitePattern( Player )
	local WindowType = cWindow.DropSpenser;
	local OldPattern = cLuaWindow(WindowType, 3, 3, "Change Pattern");
	for i=0, 8 do
		OldPattern:SetSlot(Player, i, cItem(E_BLOCK_WALLSIGN, 1));
	end
	local OnClosing = function(Window, Player)
		local Pattern = ""
		for i=0, 8 do
			Pattern = Pattern .. Window:GetSlot( Player, i ).m_ItemCount .. ","
		end
		if PatternChange[Player:GetName()] == true then
			local SQL = [[UPDATE Pattern SET Pattern=']] .. Pattern .. [[' WHERE Name=']] .. Player:GetName() .. [[';]]
			PwdDB:exec( SQL )
			return false
		end	
		local function ProcessRow(UserData, NumCols, Values, Names)
			for i = 1, NumCols do
				if (Names[i] == "Pattern") then  -- "Password" is the column name
					ShouldAllowLogin = (Values[i] == Pattern);
				end
			end
			return 0;
		end
		local Res = PwdDB:exec( "SELECT * FROM Pattern WHERE Name=\"" .. Player:GetName() .."\"", ProcessRow, nil);
		if ShouldAllowLogin == true then
			for i=0, 8 do
				Window:SetSlot(Player, i, cItem(E_BLOCK_SUGARCANE, 1 ));			
				PatternChange[Player:GetName()] = true
			end
			return true
		end
	end
	OldPattern:SetOnClosing( OnClosing )
	Player:OpenWindow( OldPattern )
end