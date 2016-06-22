mta-lua-async
=============
Description:
=============
MTA:SA Async library.
If you have some heavy cyclic operations, that are dropping "Infinite/too long execution", or operations that "freeze" your server for couple seconds, you can use this library. It supports multiple running threads at a time.

Installation:
=============
* Download latest version of **[async.lua](https://github.com/Inlife/mta-lua-async/blob/master/async.lua)**
* Put it inside your resource folder
* Update resource **meta.xml** file:

```xml
...
<script src="path/to/lib/async.lua" type="shared" />
...
```

**That's all, You are ready to go! :)**

Usage:
=============
Enable debug, if you need to (it will print some useful information in server console)

```lua
Async:setDebug(true);
```

Iterate on interval from 1 to 50,000,000 while calculating some data on every iteration
>(if you run standart "for" cycle, mta server will "freeze" for several seconds)

```lua
Async:iterate(1, 50000000, function(i)
    local x = (i + 2) * i; -- heavy opreation
    outputServerLog(x);
end);
```

Iterate over big array of data

```lua
Async:foreach(vehicles, function(vehicle)
    vehicle:setHealth(1000);
end);
```

There also an options for changing speed of your async caclulations:

```lua
Async:setPriority("low");    -- better fps
Async:setPriority("normal"); -- medium
Async:setPriority("high");   -- better perfomance

-- or, more advanced
Async:setPriority(500, 100);
-- 500ms is "sleeping" time, 
-- 100ms is "working" time, for every current async thread
```
Example:
=============
Load all vehicles from database, and create them in the game world (without lags)

```lua
local _connection; -- initialized database connection
local vehicles = {};

Async:setDebug(true);
Async:setPriority("low");

dbQuery(function(qh)
    local data = dbPoll(qh, 0); 
    
    Async:foreach(data, function(vehicle)
        
        local _vehicle = createVehicle( vehicle.model, vehicle.x, vehicle.y, vehicle.z );
        -- other stuff
        -- ...
        table.insert(vehicles, _vehicle);
        
    end);
    
    -- and run dummy cycle at the same time (just for fun :p)
    Async:iterate(0, 500000, function(num)
        outputServerLog(num);
    end);
    
end, _connection, "SELECT * FROM vehicles");
```

#Upgrading:
If you've used library before "Singleton" update:

```lua
-- warning! old example
local async = Async();
async:iterate(function(i)
	outputDebugString(i);
end);
```

You can easily simulate it, just by adding "_" before Async class name:

```lua
-- warning! updated old example (localized scope, not recommended)
local async = _Async();
async:iterate(function(i)
	outputDebugString(i);
end);
```

But, still: it's not recommended! :P

#Under the hood:
If you want to create independent/scope-isolated instance of Async manager, you can do it that way:

```lua
local isolatedAsync = _Async();
```

You can find kinda well documented code inside async.lua file. If you need some help, you can always create an issue.

#Other:
Library uses [bartbes/slither](https://bitbucket.com/bartbes/slither) class library. Check it out. @Bartbes, thank you so much! :)