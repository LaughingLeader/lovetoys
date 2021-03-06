local middleclass = {
    _VERSION     = 'middleclass v3.0.1',
    _DESCRIPTION = 'Object Orientation for Lua',
    _URL         = 'https://github.com/kikito/middleclass',
    _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2011 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]
}

local function _setClassDictionariesMetatables(aClass)
    local dict = aClass.__instanceDict
    dict.__index = dict

    local super = aClass.super
    if super then
        local superStatic = super.static
        setmetatable(dict, super.__instanceDict)
        setmetatable(aClass.static, { __index = function(_,k) return dict[k] or superStatic[k] end })
    else
        setmetatable(aClass.static, { __index = function(_,k) return dict[k] end })
    end
end

local function _setClassMetatable(aClass)
    setmetatable(aClass, {
        __tostring = function() return "class " .. aClass.name end,
        __index    = aClass.static,
        __newindex = aClass.__instanceDict,
        __call     = function(self, ...) return self:New(...) end
    })
end

---@class class
---@field name string
---@field super class
---@field static staticMethods
---@field subclasses class[]

---@class staticMethods
---@field allocate fun():class
---@field new fun(params:varargs):class
---@field subclass fun(name:string):void
---@field isSubclassOf fun(other:class):boolean
---@field include fun():class
---@field includes fun(mixin:class):boolean
---@field isInstanceOf fun(other:class):boolean

---@return class
local function _createClass(name, super)
    local aClass = { name = name, super = super, static = {}, __mixins = {}, __instanceDict={} }
    aClass.subclasses = setmetatable({}, {__mode = "k"})
    --print(string.format("_createClass(%s, %s)", name, super))
    _setClassDictionariesMetatables(aClass)
    _setClassMetatable(aClass)

    return aClass
end

local function _createLookupMetamethod(aClass, name)
    return function(...)
        local method = aClass.super[name]
        assert( type(method)=='function', tostring(aClass) .. " doesn't implement metamethod '" .. name .. "'" )
        return method(...)
    end
end

local function _setClassMetamethods(aClass)
    for _,m in ipairs(aClass.__metamethods) do
        aClass[m]= _createLookupMetamethod(aClass, m)
    end
end

local function _setDefaultInitializeMethod(aClass, super)
    aClass.Initialize = function(instance, ...)
        return super.Initialize(instance, ...)
    end
end

local function _includeMixin(aClass, mixin)
    assert(type(mixin)=='table', "mixin must be a table")
    for name,method in pairs(mixin) do
        if name ~= "included" and name ~= "static" then aClass[name] = method end
    end
    if mixin.static then
        for name,method in pairs(mixin.static) do
            aClass.static[name] = method
        end
    end
    if type(mixin.included)=="function" then mixin:Included(aClass) end
    aClass.__mixins[mixin] = true
end

---@class Object:class
local Object = _createClass("Object", nil)

Object.static.__metamethods = { '__add', '__call', '__concat', '__div', '__ipairs', '__le',
'__len', '__lt', '__mod', '__mul', '__pairs', '__pow', '__sub',
'__tostring', '__unm'}

function Object.static:Allocate()
    assert(type(self) == 'table', "Make sure that you are using 'Class:Allocate' instead of 'Class.allocate'")
    return setmetatable({ class = self }, self.__instanceDict)
end

function Object.static:New(...)
    local instance = self:Allocate()
    instance:Initialize(...)
    --print(string.format("Object.static:New(%s) | self.class = (%s)", instance.name, instance.class))
    return instance
end

function Object.static:SubClass(name)
    assert(type(self) == 'table', "Make sure that you are using 'Class:SubClass' instead of 'Class.subclass'")
    assert(type(name) == "string", "You must provide a name(string) for your class")

    --print(string.format("subclass(%s)", name))

    local subclass = _createClass(name, self)
    _setClassMetamethods(subclass)
    _setDefaultInitializeMethod(subclass, self)
    self.subclasses[subclass] = true
    self:SubClassed(subclass)

    return subclass
end

function Object.static:SubClassed(other) end

function Object.static:IsSubclassOf(other)
    return type(other)                   == 'table' and
    type(self)                    == 'table' and
    type(self.super)              == 'table' and
    ( self.super == other or
    type(self.super.isSubclassOf) == 'function' and
    self.super:IsSubclassOf(other)
    )
end

function Object.static:Include( ... )
    assert(type(self) == 'table', "Make sure you that you are using 'Class:Include' instead of 'Class.include'")
    for _,mixin in ipairs({...}) do _includeMixin(self, mixin) end
    return self
end

function Object.static:Includes(mixin)
    return type(mixin)          == 'table' and
    type(self)           == 'table' and
    type(self.__mixins)  == 'table' and
    ( self.__mixins[mixin] or
    type(self.super)           == 'table' and
    type(self.super.includes)  == 'function' and
    self.super:Includes(mixin)
    )
end

function Object:Initialize() end

function Object:__tostring() return "instance of " .. tostring(self.class) end

function Object:IsInstanceOf(aClass)
    return type(self)                == 'table' and
    type(self.class)          == 'table' and
    type(aClass)              == 'table' and
    ( aClass == self.class or
    type(aClass.isSubclassOf) == 'function' and
    self.class:IsSubclassOf(aClass)
    )
end

function middleclass.Class(name, super, ...)
    super = super or Object
    return super:SubClass(name, ...)
end

middleclass.Object = Object

setmetatable(middleclass, { __call = function(_, ...) return middleclass.Class(...) end })

return middleclass
