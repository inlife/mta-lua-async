mta-lua-async
=============
Description:
=============
MTA:SA Async library. 
If you have some heavy cyclic operations, that are dropping "Infinite/too long execution", or operations that "freeze" your server for couple seconds, you can use this library. It supports multiple running threads at a time.

Installation:
=============
* Download latest version of **[async.lua](https://github.com/Inlife/mta-lua-async/blob/master/async.lua)**
* Download latest version of **[slither.lua](https://github.com/Inlife/mta-lua-async/blob/master/slither.lua)** (Dependency, slightly modified version of [bartbes/slither](https://bitbucket.org/bartbes/slither))
* Update your **meta.xml**

```xml
<script src="path/to/lib/slither.lua" type="shared" />
<script src="path/to/lib/async.lua" type="shared" />
```

**That's all, You are ready to go! :)**

Usage:
=============
Create instance

```lua
local async = Async();
```
Enable debug, if you need to (it will print some useful information in server console)

```lua
async:setDebug(true);
```

Iterate on interval from 1 to 50,000,000 while calculating some data on every iteration
>(if you run standart "for" cycle, mta server will "freeze" for several seconds)

```lua
async:iterate(1, 50000000, function(i)
    local x = (i + 2) * i; -- heavy opreation
    outputServerLog(x);
end);
```

Iterate over big array of data

```lua
async:foreach(vehicles, function(vehicle)
    vehicle:setHealth(1000);
end);
```

There also an options for changing speed of your async caclulations:

```lua
async:setPriority("low");    -- better fps
async:setPriority("normal"); -- medium
async:setPriority("high");   -- better perfomance

-- or, more advanced
async:setPriority(500, 100);
-- 500ms is "sleeping" time, 
-- 100ms is "working" time, for every current async thread
```
Example:
=============
Load all vehicles from database, and create them in the game world (without lags)

```lua
local _connection; -- initialized database connection
local async = Async();
local vehicles = {};

async:setDebug(true);
async:setPriority("low");

dbQuery(function(qh)
    local data = dbPoll(qh, 0); 
    
    async:foreach(data, function(vehicle)
        
        local _vehicle = createVehicle( vehicle.model, vehicle.x, vehicle.y, vehicle.z );
        -- other stuff
        -- ...
        table.insert(vehicles, _vehicle);
        
    end);
    
    -- and run dummy cycle at the same time (just for fun :p)
    async:iterate(0, 500000, function(num)
        outputServerLog(num);
    end);
    
end, _connection, "SELECT * FROM vehicles");
```
