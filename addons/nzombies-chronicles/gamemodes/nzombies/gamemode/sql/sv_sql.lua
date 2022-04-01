-- SQL support added to nZombies by: Ethorbit.

-- This is because Chronicles adds many things that are
-- better suited in databases rather than text files.

-- Check the README.MD for more information.

nzSQL = nzSQL or {}

function nzSQL:ShowError(message)
    ServerLog(string.format("[nZombies] %s (%s)\n", message, sql.LastError()))
    PrintMessage(HUD_PRINTTALK, "Critical nZombies error, check the host console for details.")
end
