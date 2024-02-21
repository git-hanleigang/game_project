--jiaohua
local BaseActivityData = require "baseActivity.BaseActivityData"
local Activity_DiySaleData = class("Activity_DiySaleData", BaseActivityData)
local DiyFeatureSaleData = util_require("activities.Activity_DiyFeature.model.DiyFeatureSaleData")

-- function Activity_DiySaleData:ctor(_data)
--     Activity_DiySaleData.super.ctor(self,_data)
-- end

function Activity_DiySaleData:parseData(_data)
    Activity_DiySaleData.super.parseData(self, _data)
    self:parseSaleBuff(_data)
end

--高级促销
function Activity_DiySaleData:parseSaleBuff(_data)
    local sale = DiyFeatureSaleData:create()
    if _data then
        sale:parseData(_data)
        self.m_BuffD = sale
    end
end

function Activity_DiySaleData:getBuffD()
    return self.m_BuffD
end

-- function Activity_DiySaleData:getEx()
--     local ex = false
--     if self.m_BuffD then
--         local ext = self.m_BuffD:getExpire()
--         local sp = globalData.userRunData.p_serverTime
--         if tonumber(ext) > tonumber(sp) then
--             ex = true
--         end
--     end
--     return ex
-- end

function Activity_DiySaleData:getExpireAt()
    return self:getBuffExpireAt()
end

function Activity_DiySaleData:getBuffExpireAt()
    local ext = 0
    if self.m_BuffD then
        ext = self.m_BuffD:getExpire()
    end
    return ext
end

function Activity_DiySaleData:IsAll()
    local ex = false
    if self.m_BuffD then
        local ext = self.m_BuffD:isAllP()
        if ext == 1 then
            ex = true
        end
    end
    return ex
end

return Activity_DiySaleData