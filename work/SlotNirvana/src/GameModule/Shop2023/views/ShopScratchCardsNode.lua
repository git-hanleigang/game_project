--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-05-12 15:43:33
    describe:商城刮刮卡节点
]]
local ShopScratchCardsNode = class("ShopScratchCardsNode", util_require("base.BaseView"))

function ShopScratchCardsNode:initUI(data)
    self.m_shopClass = data
    self:createCsbNode("ScratchCards_logo/ScratchCards_logo.csb")
    self:runCsbAction("idle", true)
    self:showDownTimer()
end

function ShopScratchCardsNode:initCsbNodes()
    self.m_leftTimeLb = self:findChild("txt_desc")
    self.m_spRedPoint = self:findChild("Sprite_1")
    self.m_redNum = self:findChild("txt_redNum")
    self.m_touchPanel = self:findChild("click_area")
    self:addClick(self.m_touchPanel)
end

function ShopScratchCardsNode:onEnter()
    ShopScratchCardsNode.super.onEnter(self)
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.ScratchCards then
                self:removeFromParent()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function ShopScratchCardsNode:clickFunc(sender)
    local name = sender:getName()
    if name == "click_area" then
        if self.m_shopClass and self.m_shopClass.closeUI2 then
            local callBack = function()
                G_GetMgr(ACTIVITY_REF.ScratchCards):showMainLayer({source = "shop"})
            end
            self.m_shopClass:closeUI2(callBack)
        else
            G_GetMgr(ACTIVITY_REF.ScratchCards):showMainLayer({source = "shop"})
        end
    end
end

--显示倒计时
function ShopScratchCardsNode:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function ShopScratchCardsNode:updateLeftTime()
    local data = G_GetMgr(ACTIVITY_REF.ScratchCards):getRunningData()
    if data then
        self:showCounts()
        local strLeftTime, isOver = util_daysdemaining(data:getExpireAt(), true)
        self.m_leftTimeLb:setString(strLeftTime)
        if isOver then
            self:stopTimerAction()
            self:removeFromParent()
        end
    else
        self:stopTimerAction()
    end
end

function ShopScratchCardsNode:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

-- 显示红点
function ShopScratchCardsNode:showCounts()
    if not self.m_spRedPoint or not self.m_redNum then
        return
    end

    local data = G_GetMgr(ACTIVITY_REF.ScratchCards):getRunningData()
    if not data then
        self.m_spRedPoint:setVisible(false)
        return
    end

    local counts = data:isFree() and 1 or 0
    local lastCard = data:getUserLastCards()
    counts = counts + lastCard
    if counts <= 0 then
        self.m_spRedPoint:setVisible(false)
        return
    end

    self.m_spRedPoint:setVisible(true)
    self.m_redNum:setString("" .. counts)
    util_scaleCoinLabGameLayerFromBgWidth(self.m_redNum, 26)
end

function ShopScratchCardsNode:onExit()
    self:stopTimerAction()
    ShopScratchCardsNode.super.onExit(self)
end

return ShopScratchCardsNode
