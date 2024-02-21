local ColorfulCircusObjectPool = {}
function ColorfulCircusObjectPool.New(onCreate)
    local o = {}
    setmetatable(o, ColorfulCircusObjectPool)
    ColorfulCircusObjectPool.__index = ColorfulCircusObjectPool
    o.buffer = {}
    o.size = 0
    o.onCreate = onCreate
    return o
end

function ColorfulCircusObjectPool:Get(...)
    local e = self.buffer[self.size]
    if not e then
        return self.onCreate(...)
    end
    self.size = self.size - 1
    return e
end

function ColorfulCircusObjectPool:Put(item)
    self.size = self.size + 1
    self.buffer[self.size] = item
end

return ColorfulCircusObjectPool