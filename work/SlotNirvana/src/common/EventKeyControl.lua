local  EventKeyControl =class("EventKeyControl")
function  EventKeyControl:ctor()
    self.KeyBacks={}
    self.m_isEnabled = true
end

function EventKeyControl:setEnabled(isEnabled)
    self.m_isEnabled = isEnabled
end

function EventKeyControl:getKeyBack(isRemove)
    local count=#self.KeyBacks
    if  count<=0 then
        return
    end
    if isRemove then
        return table.remove(self.KeyBacks)
    else
        return self.KeyBacks[count]
    end
end

function EventKeyControl:onKeyBack()
    if not self.m_isEnabled then
        return
    end

    local item=self:getKeyBack()
    if item then
        if item.onKeyBack then
           item:onKeyBack()
        else
           self:removeKeyBack()
           self:onKeyBack()
        end
    end
end

function EventKeyControl:addKeyBack(item)
    self:removeKeyBack(item)
    table.insert(self.KeyBacks, item)
end

function EventKeyControl:removeKeyBack(item)
    if #self.KeyBacks == 0 then
        return
    end

    if item then
        return table.removebyvalue(self.KeyBacks, item)
    else
        return table.remove(self.KeyBacks)
    end
end

function EventKeyControl:clearKeyBack()
    self.KeyBacks={}
end
return EventKeyControl