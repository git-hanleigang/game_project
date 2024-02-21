local LuaQueue = class("LuaQueue")
--双向队列

function LuaQueue:ctor()
    self.errorCode = -1
    self:init()
end

function LuaQueue:init()
    self.first = 1
    self.last = 0
    self.list={}
end

--加入队列
function LuaQueue:pushFront(value)
    local first = self.first - 1
    self.first = first
    self.list[first] = value
end

function LuaQueue:pushBack(value)
    local last = self.last + 1
    self.last = last
    self.list[last] = value
end

function LuaQueue:popFront(retain)
    local first = self.first
    if first > self.last then 
        return self.errorCode
    end

    local value = self.list[first]
    if not retain then
        self.list[first] = nil
        self.first = first + 1
    end
    return value
end

function LuaQueue:popBack(retain)
    local last = self.last
    if self.first > last then 
        return self.errorCode
    end

    local value = self.list[last]
    if not retain then
        self.list[last] = nil
        self.last = last-1
    end

    return value
end

--某元素序号
function LuaQueue:indexOf(value)
    for k,v in pairs(self.list) do
        if v == value then
            return k
        end
    end

    return -1
end

--是否为空
function LuaQueue:empty() 
    if self:getListCount()<=0 then
        return true
    end
end

--获得当前队列数量
function LuaQueue:getListCount()
    return self.last-self.first+1
end

--获得当前队列
function LuaQueue:getList()
    return self.list,self.first,self.last
end

--清空队列
function LuaQueue:clear()
    self:init()
end

return LuaQueue

