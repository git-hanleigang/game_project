--
-- 袋鼠商店中的页面
--
local SUPER_FREESPIN_DELAY_CLOSEUI = 1.7
local FortuneCatsShopData = util_require("CodeFortuneCatsShopSrc.FortuneCatsShopData")
local FortuneCatsShopPage = class("FortuneCatsShopPage", util_require("base.BaseView"))

function FortuneCatsShopPage:initUI(params)
    local resourceFilename = "FortuneCats_shop_Page.csb"
    self:createCsbNode(resourceFilename, isAutoScale)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
    self.m_rootView = params.rootView

    self:initData(params.pageIndex)
    self.m_WinCoins = 0
end

function FortuneCatsShopPage:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function FortuneCatsShopPage:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
end

-- 数据处理
function FortuneCatsShopPage:initData(pageIndex)
    self.m_pageIndex = pageIndex
end

-- 触发freespin时只播放兑换动作，不刷新UI， 等待freespin开始界面弹出来
function FortuneCatsShopPage:playPageUIAction(noPlayStart, callFunc)
    -- 播放动作
    local pageCellIndex = FortuneCatsShopData:getRequestPageCellIndex()
    local isFreeSpin = FortuneCatsShopData:getFreeSpinState()
    -- 如果是触发freespin界面的话
    if isFreeSpin == true then
        -- 只刷新点击的，全部金币
        self:updatePageCell(
            pageCellIndex,
            noPlayStart,
            function()
                FortuneCatsShopData:setExchangeEffectState(false)
                self:flyCoins(pageCellIndex)
            end
        )
        performWithDelay(
            self,
            function()
                gLobalNoticManager:postNotification("NOTIFY_OPEN_SHOP_CAT")
            end,
            SUPER_FREESPIN_DELAY_CLOSEUI
        )
    else
        self:updatePageCell(
            pageCellIndex,
            noPlayStart,
            function()
                FortuneCatsShopData:setExchangeEffectState(false)
                self:flyCoins(pageCellIndex)
                if callFunc then
                    callFunc()
                end
            end
        )
    end
end

function FortuneCatsShopPage:updateUI(noPlayStart, firstOpen)
    for i = 1, 9 do
        self:updatePageCell(i, noPlayStart, nil, firstOpen)
    end
end

function FortuneCatsShopPage:updatePageCell(cellIndex, noPlayStart, callBack, firstOpen)
    local pageCellStatus = FortuneCatsShopData:getPageCellState(self.m_pageIndex, cellIndex)
    local isTriggerPick = FortuneCatsShopData:getShopIsTriggerPick()
    local node = self:findChild("kuang" .. cellIndex)
    local child = node:getChildByName(pageCellStatus)
    if child then
        child:updateUI(noPlayStart, callBack, firstOpen,isTriggerPick)
    else
        -- 新界面播放动作
        local newUI = function(scaleAction)
            local view
            if pageCellStatus == "PageStatus_free" then
                view = util_createView("CodeFortuneCatsShopSrc.FortuneCatsShopPageItem", self.m_pageIndex, cellIndex,self.m_rootView)
            elseif pageCellStatus == "PageStatus_opened" then
                view = util_createView("CodeFortuneCatsShopSrc.FortuneCatsShopPageCoin", self.m_pageIndex, cellIndex,self.m_rootView)
            elseif pageCellStatus == "PageStatus_unopen" then
                view = util_createView("CodeFortuneCatsShopSrc.FortuneCatsShopPageItem", self.m_pageIndex, cellIndex,self.m_rootView)
            elseif pageCellStatus == "PageStatus_unlock" then
                view = util_createView("CodeFortuneCatsShopSrc.FortuneCatsShopPageItem", self.m_pageIndex, cellIndex,self.m_rootView)
            end
            view:setName(pageCellStatus)
            if scaleAction then
                noPlayStart = false
            end
            view:updateUI(noPlayStart, callBack, firstOpen,isTriggerPick)
            node:removeAllChildren()
            node:addChild(view)
        end
        child = node:getChildByName("PageStatus_unopen")
        if child then
            -- 旧界面播放动作
            child:playSuccessBuyAction(
                function()
                    gLobalNoticManager:postNotification("NOTIFY_SHOP_PAGE_BUY_SUCCESS")
                    newUI(true)
                end
            )
        else
            newUI()
        end
    end
end

function FortuneCatsShopPage:flyCoins(pageCellIndex)
    local pageCellStatus = FortuneCatsShopData:getPageCellState(self.m_pageIndex, pageCellIndex)
    if pageCellStatus == "PageStatus_free" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        return
    end

    local info = FortuneCatsShopData:getShopPageInfo()
    local _winCoins = info[self.m_pageIndex][pageCellIndex][2]
    local totalWinCoins =  self.m_WinCoins + _winCoins
    
    if  self.m_WinCoins ~= 0 then
        globalData.slotRunData.lastWinCoin =  totalWinCoins
    end
    if _winCoins > 0 then
        gLobalNoticManager:postNotification("SHOP_PLAY_WIN_EFFECT")
        self.m_WinCoins = totalWinCoins
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {_winCoins, true, true})
        globalData.slotRunData.lastWinCoin = self.m_WinCoins
    end
end

return FortuneCatsShopPage
