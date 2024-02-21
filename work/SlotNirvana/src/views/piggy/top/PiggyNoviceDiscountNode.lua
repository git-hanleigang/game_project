--[[
    author:{author}
    time:2019-09-05 12:11:45
]]
local text1 = "PIGGY SALE"
local text21 = "MORE COINS"
local text22 = "MORE" -- 竖版时因为显示不开，所以少一个单词
local PiggyNoviceDiscountNode = class("PiggyNoviceDiscountNode", util_require("base.BaseView"))
function PiggyNoviceDiscountNode:initUI()
    self:createCsbNode(self:getCsbName())

    local t1 = self:findChild("text1")
    t1:setString(text1)
    self.m_discountNode = self:findChild("discount")

    self.m_discount = text22
    if globalData.slotRunData.isPortrait == true then
        self:setScale(0.55)
    else
        -- self.m_discount = text21
        self:setPositionY(8)
    end

    local play
    play = function()
        self:runCsbAction(
            "show1",
            false,
            function()
                self:runCsbAction("show2", false, play)
            end
        )
    end
    play()

    self:updateDiscount()
end

function PiggyNoviceDiscountNode:getCsbName()
    return "GameNode/PiggyNoviceBg.csb"
end

function PiggyNoviceDiscountNode:updateDiscount()
    local discount = 0
    local pigCoins = G_GetMgr(ACTIVITY_REF.PigCoins):getRunningData()
    if pigCoins then
        discount = pigCoins:getPiggyCommonSaleParam(false)
    else
        local clanSaleData = G_GetMgr(ACTIVITY_REF.PigClanSale):getRunningData() -- 公会小猪折扣
        if clanSaleData and clanSaleData:isRunning() then
            discount = clanSaleData:getDiscount()
        else
            local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
            local isInNoviceDiscount = piggyBankData and piggyBankData:checkInNoviceDiscount()
            if isInNoviceDiscount then
                discount = piggyBankData:getNoviceFirstDiscount() or 0
            end
        end
    end
    self.m_discountNode:setString(discount .. "% " .. self.m_discount)
end

function PiggyNoviceDiscountNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
            if piggyBankData and piggyBankData:checkInNoviceDiscount() then
                self:updateDiscount()
            end
        end,
        ViewEventType.UPDATE_SLIDEANDHALL_FINISH
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
            if piggyBankData and piggyBankData:checkInNoviceDiscount() then
                self:updateDiscount()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
            if piggyBankData and piggyBankData:checkInNoviceDiscount() then
                self:updateDiscount()
            end
        end,
        ViewEventType.PUSH_VIEW_FINISH
    )
end

function PiggyNoviceDiscountNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return PiggyNoviceDiscountNode
