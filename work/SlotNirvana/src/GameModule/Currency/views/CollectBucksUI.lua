--[[
    收集代币
]]
local CollectBucksUI = class("CollectBucksUI", util_require("base.BaseView"))

function CollectBucksUI:initDatas(bRotation)
    local isPortrait = globalData.slotRunData.isPortrait
    self.m_isPortrait = isPortrait

    -- self:setCsbNodeScale(globalData.topUIScale)
end

function CollectBucksUI:getCsbName()
    return "ShopBuck/csb/top/ShopBuckTopNode.csb"
end

function CollectBucksUI:initCsbNodes()
    self.m_lbValue = self:findChild("lb_bucks")
end

function CollectBucksUI:initUI()
    CollectBucksUI.super.initUI(self)
end

function CollectBucksUI:updateUI(nValue)
    assert(nValue, "buck value is nil!!!")
    self.m_cur = nValue
    self:updateValue(self.m_cur)
end

function CollectBucksUI:refreshValue(_add, _addTime, _over)
    local function animCallBack()        
        util_performWithDelay(
            self,
            function()
                if _over then
                    _over()
                end
            end,
            0.5
        )
    end

    if not (_add and tonumber(_add or 0) > 0) then
        animCallBack()
        return
    end
    local add = tonumber(_add or 0)
    local cur = tonumber(self.m_cur or 0)
    local tar = cur + add

    local frameInterval = 0.03
    local frameAddValue = math.max(1, math.floor(add/10))
    if self.m_buckSche then
        self:stopAction(self.m_buckSche)
        self.m_buckSche = nil
    end
    local now = cur
    self.m_buckSche = util_schedule(self, function()
        now = now + frameAddValue
        if now >= tar then
            self.m_cur = tar
            self:updateValue(tar)
            self:setFinalValue(tar)
            if self.m_buckSche then
                self:stopAction(self.m_buckSche)
                self.m_buckSche = nil
            end
            animCallBack()
        else
            self:updateValue(now)
            self:setFinalValue(now)
        end
    end, frameInterval)
end

function CollectBucksUI:updateValue(nValue)
    self.m_lbValue:setString(util_cutCoins(nValue, true, 2))
    self:updateLabelSize({label = self.m_lbValue, sx = 0.5, sy = 0.5}, 267)
end

function CollectBucksUI:showAction()
    -- self:runCsbAction("idle", false)
end

function CollectBucksUI:onExit()
    CollectBucksUI.super.onExit(self)
    if self.m_buckSche then
        self:stopAction(self.m_buckSche)
        self.m_buckSche = nil
    end
end

function CollectBucksUI:setFinalValue(_now)
    local mgr = G_GetMgr(G_REF.Currency)
    if mgr then
        mgr:setBucks(_now)
    end
end

return CollectBucksUI
