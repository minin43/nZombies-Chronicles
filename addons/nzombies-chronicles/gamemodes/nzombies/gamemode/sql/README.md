# You can change where everything is saved/loaded
Refer to the [wiki](https://github.com/Ethorbit/nZombies-Chronicles/wiki/Saving-NZC-data-to-different-database)
if you want everything to save/load from a remote database instead of the SQLite sv.db file.


TLDR: you can override functions from the sql/sv_sql.lua or instead sql/subclasses/ .lua files' getter/setters in your own thirdparty server addon and then the gamemode will use that.


## Q/A
**Q:** Why did you create functions for returning query strings in sv_sql instead of just.. you know.. using them directly?

**A:** I wanted to make this as mod friendly as possible as database syntax differs between database types. Also, it cuts down on the gamemode's own code.
<br></br>
**Q:** Why does the nzSQL class use the syntax that it does?

**A:** No particular reason, it's just easier for me as the developer to manage.
<br></br>
**Q:** Why not add hooks for us instead so we don't have to override functions?

**A:** Hooks are redundant if the only purpose they serve is to allow people to override functions.
