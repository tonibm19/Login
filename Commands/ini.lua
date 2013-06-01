function HandleRegisterCommand( Split, Player )	
	if CheckIfAccExist( Player ) == true then
		Player:SendMessage( cChatColor.LightGreen .. "You already have an account" )
	else
		if Split[2] ~= nil then
			PassIni:SetValue( "Passwords", Player:GetName(), md5(Split[2]) )
			PassIni:WriteFile()
			Player:SendMessage( cChatColor.LightGreen .. "You registered" )
		else
			Player:SendMessage( cChatColor.Rose .. "usage: /register [Password]" )
		end
	end
	return true
end

function HandleLoginCommand( Split, Player )
	if CheckIfAuthenticated( Player ) == false then
		Player:SendMessage( cChatColor.LightGreen .. "You are already logged in" )
	else
		if Split[2] ~= nil then
			CheckPassword( Player, Split )
		else
			Player:SendMessage( cChatColor.Rose .. "Usage: /login [Password]" )
		end
	end
	return true
end

function HandleChangePasswordCommand( Split, Player )
	if PasswordType == "Chat" then
		if Split[2] or Split[3] == nil then
			Player:SendMessage( cChatColor.Rose .. "Usage: /changepass [Old password] [New password]" )
		else
			local Password = PassIni:GetValue( "Passwords", Player:GetName() )
			if Password == md5( Split[2] ) then
				PassIni:DeleteValue( "Passwords", Player:GetName() )
				PassIni:SetValue( "Passwords", Player:GetName(), md5(Split[3]) )
				PassIni:WriteFile()
				Player:SendMessage( cChatColor.LightGreen .. "The password is changed" )
				return true
			else
				Player:SendMessage( cChatColor.Rose .. "You entered the wrong password" )
				return true
			end
		end
	elseif PasswordType == "Pattern" then
		ChangePattern( Player )
	end
	return true
end