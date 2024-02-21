local LuaList=class("LuaList")
--队列 先进先出
--startPos 队列起始下标 默认为1 errorCode弹出空队列错误码 默认为nil
function LuaList:ctor(startPos,errorCode)
    self.startPos=startPos
    self.errorCode=errorCode
    self:init()
end

function LuaList:init()
    self.cur_pos=self.startPos or 1
    self.end_pos=self.cur_pos-1
    self.list={}
end
--加入队列
function LuaList:push(value)
    self.end_pos = self.end_pos + 1
    self.list[self.end_pos] = value
end
--弹出队列 如果存在retain 只返回元素不弹出队列
function LuaList:pop(retain)
    if self.cur_pos > self.end_pos then
        return self.errorCode
    end
    local value = self.list[self.cur_pos]
    if not retain then
        self.list[self.cur_pos] = nil
        self.cur_pos = self.cur_pos + 1
    end
    return value
end

--是否为空
function LuaList:empty() 
    if self:getListCount()<=0 then
        return true
    end
end

--获得当前队列数量
function LuaList:getListCount()
    return self.end_pos-self.cur_pos+1
end

--获得当前队列
function LuaList:getList()
    return self.list,self.cur_pos,self.end_pos
end

--清空队列
function LuaList:clear()
    self:init()
end

return LuaList
--endregion
