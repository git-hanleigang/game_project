--商城制定档位送道具
local PurchaseGiftMgr = class("PurchaseGiftMgr", BaseActivityControl)

function PurchaseGiftMgr:ctor()
    PurchaseGiftMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PurchaseGift)
    self.m_useNewPath = {
        ["Activity_PurchaseGift_Zombie"] = true,
    }
end

function PurchaseGiftMgr:parseGiftData(_data)
    local data = self:getRunningData()
    if data then 
        data:parseGiftData(_data)
    end
end

function PurchaseGiftMgr:getPopPath(popName)
    if self.m_useNewPath[themeName] then
        return popName
    else
        return PurchaseGiftMgr.super.getPopPath(self, popName)
    end
    
end

function PurchaseGiftMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return themeName .. "/Icons/" .. hallName .. "HallNode"
    else
        return PurchaseGiftMgr.super.getHallPath(self, hallName)
    end
end

function PurchaseGiftMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return themeName .. "/Icons/" .. slideName .. "SlideNode"
    else
        return PurchaseGiftMgr.super.getSlidePath(self, slideName)
    end    
end

return PurchaseGiftMgr
