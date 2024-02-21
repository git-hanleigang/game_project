--[[
]]
local ShopBuckTopNode = class("ShopBuckTopNode", BaseView)

function ShopBuckTopNode:getCsbName()
    return "ShopBuck/csb/top/ShopBuckTopNode.csb"
end

function ShopBuckTopNode:initDatas()
    self.m_cur = 0
end

function ShopBuckTopNode:initCsbNodes()
    self.m_nodeBuck = self:findChild("node_buck")
    self.m_lbBuck = self:findChild("lb_bucks")
end

function ShopBuckTopNode:getUpNode()
    return self.m_nodeBuck
end

function ShopBuckTopNode:initUI()
    ShopBuckTopNode.super.initUI(self)
    self:initBuck()
end

function ShopBuckTopNode:initBuck()
    local buckNum = G_GetMgr(G_REF.ShopBuck):getBuckNum()
    self:updateBuck(buckNum)
end

function ShopBuckTopNode:updateBuck(buckNum)
    buckNum = math.max(0, buckNum or 0)
    self.m_cur = buckNum
    self:__updateValue(self.m_cur)
end

function ShopBuckTopNode:__updateValue(buckNum)
    self.m_lbBuck:setString(util_cutCoins(buckNum, true, 2))
    self:updateLabelSize({label = self.m_lbBuck, sx = 0.5, sy = 0.5}, 267)
    self:__setFinalValue(buckNum)
end

function ShopBuckTopNode:__setFinalValue(nValue)
    G_GetMgr(G_REF.Currency):setBucks(nValue)
end

function ShopBuckTopNode:refreshBuck(_perAdd, _target, _addTime)
    if not _target then
        _target = self.m_cur + (tonumber(_perAdd or 0) * (_addTime or 0))
    else
        _target = _target
    end
    self:__refreshValue(_perAdd, _target)
end

function ShopBuckTopNode:__refreshValue(_perAdd, _tar, _over)
    local perAdd = tonumber(_perAdd or 0)
    local cur = tonumber(self.m_cur or 0)
    local tar = tonumber(_tar or 0)
    if perAdd == 0 or tar == cur then
        if _over then
            _over()
        end
        return
    end

    local frameInterval = 1/60
    if self.m_buckSche then
        self:stopAction(self.m_buckSche)
        self.m_buckSche = nil
    end
    
    -- 取个整，防止来回跳
    perAdd = math.max(1, math.floor(perAdd))

    local now = cur
    self.m_buckSche = util_schedule(self, function()
        now = now + perAdd
        if (perAdd > 0 and now >= tar) or (perAdd < 0 and now <= tar) then
            self.m_cur = tar
            self:__updateValue(tar)
            if self.m_buckSche then
                self:stopAction(self.m_buckSche)
                self.m_buckSche = nil
            end
            if _over then
                _over()
            end
        else
            self.m_cur = now
            self:__updateValue(now)
        end
    end, frameInterval)
end

function ShopBuckTopNode:onEnter()
    ShopBuckTopNode.super.onEnter(self)

    -- -- 购买代币
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         local buckNum = G_GetMgr(G_REF.ShopBuck):getBuckNum()
    --         self:updateBuck(buckNum)
    --     end,
    --     ViewEventType.NOTIFY_PURCHASE_BUCK_SUCCESS
    -- )
    -- 花费代币
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.isConsumeBuck then
                local buckNum = G_GetMgr(G_REF.ShopBuck):getBuckNum()
                self:updateBuck(buckNum)
            end
        end,
        ViewEventType.NOTIFY_PURCHASE_SUCCESS
    )
end

function ShopBuckTopNode:onExit()
    ShopBuckTopNode.super.onExit(self)
    if self.m_buckSche then
        self:stopAction(self.m_buckSche)
        self.m_buckSche = nil
    end    
end

return ShopBuckTopNode