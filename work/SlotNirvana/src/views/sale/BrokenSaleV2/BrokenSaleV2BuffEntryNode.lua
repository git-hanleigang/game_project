-- 破产促销 buff右边条节点
local BrokenSaleV2BuffEntryNode = class("BrokenSaleV2BuffEntryNode", util_require("base.BaseView"))

function BrokenSaleV2BuffEntryNode:initUI()
    BrokenSaleV2BuffEntryNode.super.initUI(self)
    self:initView()
end

function BrokenSaleV2BuffEntryNode:initDatas()
    self.m_data = G_GetMgr(G_REF.BrokenSaleV2):getData()
    self.m_buffData = self.m_data:getActiveBuff()
end

function BrokenSaleV2BuffEntryNode:getCsbName()
    return "BrokenSaleV2/csd/BrokenSale_entry.csb"
end

function BrokenSaleV2BuffEntryNode:initCsbNodes()
    self.m_sp_icon = self:findChild("sp_icon")
    self.m_lb_num = self:findChild("lb_shuzi")
end

function BrokenSaleV2BuffEntryNode:initView()
    self:initLeftNum()
end

function BrokenSaleV2BuffEntryNode:initLeftNum()
    local buffData = self.m_data:getActiveBuff()
    if self.m_buffData and buffData then
        local curCoins = buffData:getBuffCoins()
        local perCoins = self.m_buffData:getBuffCoins()
        if perCoins >= curCoins then
            self.m_buffData = clone(buffData)
            self:checkBuffIsNotSpinNum()
        end
        local num = buffData:getCount()
        self.m_lb_num:setString("" .. num)
    end
end

function BrokenSaleV2BuffEntryNode:checkBuffIsNotSpinNum()
    if self.m_buffData:isNotSpinNum() then -- 检测spin次数为0 buff结束
        G_GetMgr(G_REF.BrokenSaleV2):requestBuffCoinsReward(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_BROKENSALE_BUFF)
            end
        )
    end
end

function BrokenSaleV2BuffEntryNode:onEnter()
    BrokenSaleV2BuffEntryNode.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:initLeftNum()
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    -- 大赢结束事件
    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            self:flyCoins()
        end,
        ViewEventType.NOTIFY_PLAY_OVER_BIGWIN_EFFECT
    )

    -- 购买促销成功
    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            self:initLeftNum()
        end,
        ViewEventType.NOTIFY_BROKENSALE_BUY_SUCCESS
    )
end

function BrokenSaleV2BuffEntryNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_click" then
        G_GetMgr(G_REF.BrokenSaleV2):showBuffLayer(self.m_buffData)
    end
end

function BrokenSaleV2BuffEntryNode:getRightFrameSize()
    return {widht = 100, height = 100}
end

function BrokenSaleV2BuffEntryNode:flyCoins()
    local buffData = self.m_data:getActiveBuff()
    if not self.m_buffData or not buffData then
        return
    end
    if buffData:isCanCollect() then -- 能够收集需要弹出弹板领奖 不需要播放收集特效
        self.m_buffData = clone(buffData)
        return
    end
    local curCoins = buffData:getBuffCoins()
    local perCoins = self.m_buffData:getBuffCoins()
    if curCoins > perCoins then
        local flyList = {}
        local startPos = globalData.winFlyNodePos
        local endPos = self.m_sp_icon:getParent():convertToWorldSpace(cc.p(self.m_sp_icon:getPosition()))
        table.insert(flyList, {cuyType = FlyType.Coin, addValue = 0, startPos = startPos, endPos = endPos})
        G_GetMgr(G_REF.Currency):playFlyCurrency(
            flyList,
            function()
                self.m_buffData = clone(buffData)
            end
        )
    else
        self.m_buffData = clone(buffData)
    end
end

return BrokenSaleV2BuffEntryNode