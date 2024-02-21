local InboxItem_base = class("InboxItem_base", util_require("base.BaseView"))

-- 这里尽量不要重写 initDatas ， 如果有需求，将操作放在 initDatasFinish
function InboxItem_base:initDatas(_data, _removeMySelf)
    self.m_mailData = _data
    self.m_removeMySelf = _removeMySelf

    self:initDatasFinish()
end

function InboxItem_base:initDatasFinish()
end

function InboxItem_base:initUI()
    if self:isCsbExist() then 
        InboxItem_base.super.initUI(self)
        self:initView()
    end
end

function InboxItem_base:initView()
    
end

function InboxItem_base:setHeight(_height)
    self.m_height = _height
end

function InboxItem_base:getHeight()
    return self.m_height
end

return InboxItem_base
