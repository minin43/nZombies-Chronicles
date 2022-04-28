-- Admin Settings menu created by Ethorbit,
-- based on my Chronicles server's "nZombies Settings Menu"

if CLIENT then
    nzChatCommand.Add("/adminsettings", function(ply, text)
        print("Test", ply)
    end, false, "Opens the Admin Settings panel.")
end
