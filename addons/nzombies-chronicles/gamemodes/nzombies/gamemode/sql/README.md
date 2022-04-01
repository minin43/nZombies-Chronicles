# You can change where everything is saved/loaded
Refer to the [wiki](https://github.com/Ethorbit/nZombies-Chronicles/wiki/Saving-NZC-data-to-a-MySQL-database)
if you want everything to save/load from a remote database instead of the SQLite sv.db file.


TLDR: you can override query getter/setters from the sql .lua files in your own thirdparty server addon and then the gamemode will use that.


## Q/A
***
**Q:** Why not add hooks for us instead so we don't have to override functions?
**A:** Hooks are redundant if the only purpose they serve is to allow people to override functions.

**Q:** Can I just copy the queries from the NZ classes to my function overrides?
**A:** Some SQLite queries are different than whatever you might be using, so just double check it would actually work before adding.
***
