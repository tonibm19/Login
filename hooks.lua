function OnExecuteCommand(Player, CommandSplit)
	if Player == nil then
		return false
	end
	if CheckIfAuthenticated( Player ) == false then
		if CommandSplit[1] == "/login" or CommandSplit[1] == "/register" then
			return false
		else		
			return CheckIfAuthenticated( Player )
		end
	end
end

function OnChat( Player, Message )
	return CheckIfAuthenticated( Player, 1 )
end

function OnDisconnect(Player, Reason)
	Logout( Player )
end

function OnTakeDamage(Receiver, TDI)
	if Receiver:IsPlayer() then
		return CheckIfAuthenticated( Receiver )
	end
end

function OnPlayerPlacingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ, BlockType)
	return CheckIfAuthenticated( Player, 2 )
end

function OnPlayerBreakingBlock(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ, BlockType)
	return CheckIfAuthenticated( Player, 3 )
end

function OnPlayerSpawned( Player )
	Logout( Player )
	World = Player:GetWorld()
	if string.upper(Storage) == "INI" then
		if PasswordType == "Pattern" then
			Found, Pattern = PassIni:GetValue( "Pattern", Player:GetName() )
			if Found == "" then
				SendRegistrationPattern( Player )
			else
				SendLoginPattern( Player )
			end
		end
	elseif string.upper(Storage) == "SQLITE" then
		if PasswordType == "Pattern" then
			local function ProcessRow(UserData, NumCols, Values, Names)
				for i = 1, NumCols do
					if (Names[i] == "Pattern") then  -- "Pattern" is the column name
						PlayerExist = true
					end
				end
			end
			local Res = PwdDB:exec('SELECT * FROM Pattern WHERE Name="'.. Player:GetName() ..'"', ProcessRow, nil);
			if PlayerExist then
				SendSqlLoginPattern( Player )
			else
				SendSqlRegistrationPattern( Player )
			end
		end
	end
end

function OnPlayerMoving( Player )
	if CheckIfAuthenticated( Player ) == true then
		Player:TeleportTo( Player:GetWorld():GetSpawnX(), Player:GetWorld():GetSpawnY(), Player:GetWorld():GetSpawnZ() )
	end
end

function OnPlayerTossingItem(Player)
	if Tossing[Player:GetName()] == true then
		Tossing[Player:GetName()] = false
		return true
	end
end