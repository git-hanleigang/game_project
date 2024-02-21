-- 等级里程碑 促销界面
local LevelRoadSaleLayer = class("LevelRoadSaleLayer", BaseLayer)

function LevelRoadSaleLayer:ctor()
    LevelRoadSaleLayer.super.ctor(self)

    self:setLandscapeCsbName("LevelRoad/csd/LevelRoad_LevelSale.csb")
    self:setPortraitCsbName("LevelRoad/csd/Main_Portrait/LevelRoad_LevelSale_Portrait.csb")
    self:setPauseSlotsEnabled(true)
    self:setExtendData("LevelRoadSaleLayer")
end

function LevelRoadSaleLayer:initDatas(_params)
    self.m_data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    self.m_slaeData = self.m_data:getSaleData()
    self.m_params = _params
    self.m_isTouch = false
end

function LevelRoadSaleLayer:initCsbNodes()
    self.m_lb_title_num = self:findChild("lb_title_num")
    self.m_sp_boost_X = self:findChild("sp_boost_X")
    self.m_lb_boost_num_new = self:findChild("lb_boost_num_new")
    self.m_sp_coin_icon = self:findChild("sp_coin_icon")
    self.m_lb_coins = self:findChild("lb_coins")
    self.m_lb_time = self:findChild("lb_time")
end

function LevelRoadSaleLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    LevelRoadSaleLayer.super.playShowAction(self, "start")
end

function LevelRoadSaleLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
    self:showDownTimer()
end

function LevelRoadSaleLayer:initView()
    self:initBtnLabel()
    self:initBoost()
    self:initCoins()
    self:initTitleLevel()
    self:initTime()
end

function LevelRoadSaleLayer:initBtnLabel()
    local price = self.m_slaeData.price or 0
    self:setButtonLabelContent("btn_pay", "$" .. price)
end

function LevelRoadSaleLayer:initBoost()
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        local expansion = data:getCurrentExpansion() or 1
        self.m_lb_boost_num_new:setString("" .. expansion)
        local uiList = {
            {node = self.m_sp_boost_X},
            {node = self.m_lb_boost_num_new, alignX = 5, alignY = 17}
        }
        util_alignCenter(uiList, nil, 170)
    end
end

function LevelRoadSaleLayer:initCoins()
    local coins = self.m_slaeData.coins or 0
    self.m_lb_coins:setString(util_formatMoneyStr(coins))
    local uiList = {
        {node = self.m_sp_coin_icon, scale = 1},
        {node = self.m_lb_coins, alignX = 10, scale = 0.85}
    }
    util_alignCenter(uiList, nil, 905)
end

function LevelRoadSaleLayer:initTitleLevel()
    local level = self.m_slaeData.level or 0
    self.m_lb_title_num:setString("" .. level)
    self:updateLabelSize({label = self.m_lb_title_num}, 119)
end

function LevelRoadSaleLayer:initTime()
    if self.m_data then
        local leftTime = self.m_data:getSaleExpireAt()
        local timeStr, isOver = util_daysdemaining(leftTime)
        if isOver then
            timeStr = "00:00:00"
        end
        if self.m_lb_time then
            self.m_lb_time:setString(timeStr)
        end
    end
end

function LevelRoadSaleLayer:onEnter()
    LevelRoadSaleLayer.super.onEnter(self)
    -- 请求领取奖励
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.isSuc then
                self:rewardCollect()
            else
                self.m_isTouch = false
            end
        end,
        ViewEventType.NOTIFY_LEVELROAD_BUY_SALE
    )
end

function LevelRoadSaleLayer:rewardCollect()
    local btnCollect = self.m_sp_coin_icon
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local cuyMgr = G_GetMgr(G_REF.Currency)
    if cuyMgr then
        local flyList = {}
        local coins = self.m_slaeData.coins or 0
        if coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = coins, startPos = startPos})
        end
        if #flyList > 0 then
            cuyMgr:playFlyCurrency(flyList, function()
                if not tolua.isnull(self) then
                    self:closeUI()
                end
            end)
        else
            self:closeUI()
        end
    else
        self:closeUI()
    end
end

function LevelRoadSaleLayer:clickFunc(sender)
    if self.m_isTouch then
        return
    end
    local name = sender:getName()
    if name == "btn_pay" then
        self:buySale()
    elseif name == "btn_close" then
        self:closeUI()
    end
end

function LevelRoadSaleLayer:buySale()
    self.m_isTouch = true
    G_GetMgr(G_REF.LevelRoad):requestBuySale({saleData = self.m_slaeData})
end

--显示倒计时
function LevelRoadSaleLayer:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function LevelRoadSaleLayer:updateLeftTime()
    if self.m_data then
        local leftTime = self.m_data:getSaleExpireAt()
        local timeStr, isOver = util_daysdemaining(leftTime)
        if isOver then
            self:stopTimerAction()
            self:closeUI()
        end
        if self.m_lb_time then
            self.m_lb_time:setString(timeStr)
        end
    else
        self:stopTimerAction()
        self:closeUI()
    end
end

function LevelRoadSaleLayer:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

return LevelRoadSaleLayer
