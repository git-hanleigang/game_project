local ShopRecommendedTimeNode=class("ShopRecommendedTimeNode",util_require("base.BaseView"))

function ShopRecommendedTimeNode:initDatas(data)
    self.m_cellData = data
end

function ShopRecommendedTimeNode:initUI()
    self:createCsbNode(SHOP_RES_PATH.RecommendedTimeNode)

    self.m_labBuyTimes = self:findChild("lb_count")
    self.m_labTime = self:findChild("lb_time")
    
    self.m_lineIndex = 1

    self:updatePayTimes()
    self:checkActionTimer()
end

function ShopRecommendedTimeNode:updatePayTimes(data)
    if data then
        self.m_cellData = data
    end
    local leftBuyTimes = self.m_cellData:getMaxPayTimes() - self.m_cellData:getPayTimes()
    self.m_labBuyTimes:setString( leftBuyTimes .. "/" .. self.m_cellData:getMaxPayTimes())
    -- if leftBuyTimes == 0 then
    --     self.m_labBuyTimes:setVisible(false)
    -- end
end


function ShopRecommendedTimeNode:checkActionTimer(_showStorePrice)
    -- idle1:倒计时  -> 剩余次数
    -- idle2:剩余次数 -> 倒计时
    -- stop1:只显示 剩余次数
    -- stop2:只显示 倒计时
    -- 如果当前已经没有推荐位了，直接播放 idle2
    if self.m_checkTimerLineAction ~= nil then
        self:stopAction(self.m_checkTimerLineAction)
        self.m_checkTimerLineAction = nil
    end
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
        self.activityAction = nil
    end
    if not _showStorePrice then
        self.m_lineIndex = 1
        self:updateTimerLine()
    end
    self:checkTimer()
end


function ShopRecommendedTimeNode:updateTimerLine()
    if self.m_checkTimerLineAction ~= nil then
        self:stopAction(self.m_checkTimerLineAction)
        self.m_checkTimerLineAction = nil
    end
    local lineName1 = "idle" .. self.m_lineIndex
    local lineName2 = "stop" .. self.m_lineIndex
    self:runCsbAction(
        lineName1,
        false,
        function()
            self:runCsbAction(
                lineName2,
                false,
                function()
                    self.m_checkTimerLineAction =
                        util_performWithDelay(
                        self,
                        function()
                            self:updateTimerLine()
                        end,
                        2
                    )
                end,
                60
            )
            self.m_lineIndex = self.m_lineIndex + 1
            if self.m_lineIndex > 2 then
                self.m_lineIndex = 1
            end
        end,
        60
    )
end

function ShopRecommendedTimeNode:checkTimer()
    self.activityAction =
        util_schedule(
        self,
        function()
            self:updateLeftTime()
        end,
        1
    )
    self:updateLeftTime()
end

-- 更新剩余时间
function ShopRecommendedTimeNode:updateLeftTime()
    local dataleftTime =   self.m_cellData:getLeftTime()
    local leftTime = util_count_down_str(dataleftTime)
    if dataleftTime <= 0 then
        if self.activityAction ~= nil then
            self:stopAction(self.activityAction)
            self.activityAction = nil
        end
    else
        self.m_labTime:setString(leftTime)
    end
end

return ShopRecommendedTimeNode