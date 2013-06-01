function HandleLogoutCommand( Split, Player )
	Logout( Player )
	Player:TeleportTo( Player:GetWorld():GetSpawnX(), Player:GetWorld():GetSpawnY(), Player:GetWorld():GetSpawnZ() )
	Player:SendMessage( cChatColor.LightGreen .. "You logged out" )
	if PasswordType == "Pattern" then
		SendSqlLoginPattern( Player )
	end
	return true
end