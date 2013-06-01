function HandleRegisterCommand( Split, Player )
	if Split[2] ~= nil then
		local UserName = Player:GetName()
		local PasswordGiven = Split[2];
		local function ProcessRow(UserData, NumCols, Values, Names)
			for i = 1, NumCols do
				if (Names[i] == "Password") then  -- "Password" is the column name
					PlayerExist = true
				end
			end
		end
		local Res = PwdDB:exec('SELECT * FROM Passwords WHERE Name="'.. UserName ..'"', ProcessRow, nil);
		if Res ~= sqlite3.OK then
			 LOG("TestDB:exec() failed: " .. Res .. " (" .. PwdDB:errmsg() .. ")");
		end
		if PlayerExist == true then
			Player:SendMessage( cChatColor.LightGreen .. "You already have an account" )
		else
			local Res = PwdDB:exec('INSERT INTO Passwords VALUES("' .. UserName .. '", "' .. PasswordGiven .. '");'  )
			if Res ~= sqlite3.OK then
				 LOG("PwdDB:exec() failed: " .. Res .. " (" .. PwdDB:errmsg() .. ")");
			end
			Login( Player )
			Player:SendMessage( cChatColor.LightGreen .. "You registered" )
		end
	else
		Player:SendMessage( cChatColor.Rose .. "usage: /register [Password]" )
	end
	return true
end

function HandleLoginCommand( Split, Player )
	if Split[2] ~= nil then
		local UserName = Player:GetName()
		local PasswordGiven = Split[2];
		local ShouldAllowLogin = false;
		local PlayerFound = false
		local function ProcessRow(UserData, NumCols, Values, Names)
			PlayerFound = true
			for i = 1, NumCols do
				if (Names[i] == "Password") then  -- "Password" is the column name
					ShouldAllowLogin = (Values[i] == PasswordGiven);
				end
			end
			return 0;
		end
		local Res = PwdDB:exec("SELECT * FROM Passwords WHERE Name=\"" .. UserName .."\"", ProcessRow, nil);
		if (Res ~= sqlite3.OK) then
			LOG("SQL query failed: " .. Res .. " (" .. PwdDB:errmsg() .. ")");
		end;
		if PlayerFound == false then
			Player:SendMessage( cChatColor.Rose .. "You don't have an account yet" )
			return true
		end
		if ShouldAllowLogin then
			Login( Player )
			Player:SendMessage( cChatColor.LightGreen .. "You logged in" )
		else
			Player:SendMessage( cChatColor.Rose .. "Wrong Password" )
		end
	else
		Player:SendMessage( cChatColor.Rose .. "Usage: /login [Password]" )
	end		
	return true
end
	
function HandleChangePasswordCommand( Split, Player )
	if PasswordType == "Chat" then
		if Split[2] == nil or Split[3] == nil then
			Player:SendMessage( cChatColor.Rose .. "Usage: /changepass [Old password] [New password]" )
		else
			local UserName = Player:GetName()
			local PasswordGiven = Split[2]
			local ToChangePass = Split[3]
			local function ProcessRow(UserData, NumCols, Values, Names)
				for i = 1, NumCols do
					if (Names[i] == "Password") then  -- "Password" is the column name
						ShouldAllowLogin = (Values[i] == PasswordGiven);
					end
				end
				return 0;
			end
			local Res = PwdDB:exec("SELECT * FROM Passwords WHERE Name=\"" .. UserName .."\"", ProcessRow, nil);
			if (Res ~= sqlite3.OK) then
				LOG("SQL query failed: " .. Res .. " (" .. PwdDB:errmsg() .. ")");
			end;	
			if ShouldAllowLogin == true then
				local SQL = [[UPDATE Passwords SET Password=']] .. ToChangePass .. [[' WHERE Name=']] .. UserName .. [[';]]
				PwdDB:exec( SQL )
				Player:SendMessage( cChatColor.LightGreen .. "The password is changed" )
			else
				Player:SendMessage( cChatColor.Rose .. "You entered the wrong password" )
			end
		end
	elseif PasswordType == "Pattern" then
		ChangeSqlitePattern( Player )
	end
	return true
end