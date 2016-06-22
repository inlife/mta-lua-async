local _LICENSE = -- zlib / libpng
[[
Copyright (c) 2011-2014 Bart van Strien

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
  claim that you wrote the original software. If you use this software
  in a product, an acknowledgment in the product documentation would be
  appreciated but is not required.

  2. Altered source versions must be plainly marked as such, and must not be
  misrepresented as being the original software.

  3. This notice may not be removed or altered from any source
  distribution.
]]

class =
{
    _VERSION = "Slither 20140904",
    -- I have no better versioning scheme, deal with it
    _DESCRIPTION = "Slither is a pythonic class library for lua",
    _URL = "http://bitbucket.org/bartbes/slither",
    _LICENSE = _LICENSE,
}

local function stringtotable(path)
    local t = _G
    local name

    for part in path:gmatch("[^%.]+") do
        t = name and t[name] or t
        name = part
    end

    return t, name
end

local function class_generator(name, b, t)
    local parents = {}
    for _, v in ipairs(b) do
        parents[v] = true
        for _, v in ipairs(v.__parents__) do
            parents[v] = true
        end
    end

    local temp = { __parents__ = {} }
    for i, v in pairs(parents) do
        table.insert(temp.__parents__, i)
    end

    local class = setmetatable(temp, {
        __index = function(self, key)
            if key == "__class__" then return temp end
            if key == "__name__" then return name end
            if t[key] ~= nil then return t[key] end
            for i, v in ipairs(b) do
                if v[key] ~= nil then return v[key] end
            end
            if tostring(key):match("^__.+__$") then return end
            if self.__getattr__ then
                return self:__getattr__(key)
            end
        end,

        __newindex = function(self, key, value)
            t[key] = value
        end,

        allocate = function(instance)
            local smt = getmetatable(temp)
            local mt = {__index = smt.__index}

            function mt:__newindex(key, value)
                if self.__setattr__ then
                    return self:__setattr__(key, value)
                else
                    return rawset(self, key, value)
                end
            end

            if temp.__cmp__ then
                if not smt.eq or not smt.lt then
                    function smt.eq(a, b)
                        return a.__cmp__(a, b) == 0
                    end
                    function smt.lt(a, b)
                        return a.__cmp__(a, b) < 0
                    end
                end
                mt.__eq = smt.eq
                mt.__lt = smt.lt
            end

            for i, v in pairs{
                __call__ = "__call", __len__ = "__len",
                __add__ = "__add", __sub__ = "__sub",
                __mul__ = "__mul", __div__ = "__div",
                __mod__ = "__mod", __pow__ = "__pow",
                __neg__ = "__unm", __concat__ = "__concat",
                __str__ = "__tostring",
                } do
                if temp[i] then mt[v] = temp[i] end
            end

            return setmetatable(instance or {}, mt)
        end,

        __call = function(self, ...)
            local instance = getmetatable(self).allocate()
            if instance.__init__ then instance:__init__(...) end
            return instance
        end
        })

    for i, v in ipairs(t.__attributes__ or {}) do
        class = v(class) or class
    end

    return class
end

local function inheritance_handler(set, name, ...)
    local args = {...}

    for i = 1, select("#", ...) do
        if args[i] == nil then
            error("nil passed to class, check the parents")
        end
    end

    local t = nil
    if #args == 1 and type(args[1]) == "table" and not args[1].__class__ then
        t = args[1]
        args = {}
    end

    for i, v in ipairs(args) do
        if type(v) == "string" then
            local t, name = stringtotable(v)
            args[i] = t[name]
        end
    end

    local func = function(t)
        local class = class_generator(name, args, t)
        if set then
            local root_table, name = stringtotable(name)
            root_table[name] = class
        end
        return class
    end

    if t then
        return func(t)
    else
        return func
    end
end

function class.private(name)
    return function(...)
        return inheritance_handler(false, name, ...)
    end
end

class = setmetatable(class, {
    __call = function(self, name)
        return function(...)
            return inheritance_handler(true, name, ...)
        end
    end,
})


function class.issubclass(class, parents)
    if parents.__class__ then parents = {parents} end
    for i, v in ipairs(parents) do
        local found = true
        if v ~= class then
            found = false
            for _, p in ipairs(class.__parents__) do
                if v == p then
                    found = true
                    break
                end
            end
        end
        if not found then return false end
    end
    return true
end

function class.isinstance(obj, parents)
    return type(obj) == "table" and obj.__class__ and class.issubclass(obj.__class__, parents)
end

-- Export a Class Commons interface
-- to allow interoperability between
-- class libraries.
-- See https://github.com/bartbes/Class-Commons
--
-- NOTE: Implicitly global, as per specification, unfortunately there's no nice
-- way to both provide this extra interface, and use locals.
if common_class ~= false then
    common = {}
    function common.class(name, prototype, superclass)
        prototype.__init__ = prototype.init
        return class_generator(name, {superclass}, prototype)
    end

    function common.instance(class, ...)
        return class(...)
    end
end

--return class;