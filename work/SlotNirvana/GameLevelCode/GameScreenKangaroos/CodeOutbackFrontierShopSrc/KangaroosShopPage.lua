--
-- 袋鼠商店中的页面
-- 
local SUPER_FREESPIN_DELAY_CLOSEUI = 1.7
local KangaroosShopData = util_require("CodeOutbackFrontierShopSrc.KangaroosShopData")
local KangaroosShopPage = class("KangaroosShopPage", util_require("base.BaseView"))

function KangaroosShopPage:initUI(pageIndex)
    -- local isAutoScale =true
    -- if CC_RESOLUTION_RATIO==3 then
    --     isAutoScale=false
    -- end
    local resourceFilename = "OutbackFrontierShop/OutbackFrontierShopPage.csb"
    self:createCsbNode(resourceFilename, isAutoScale)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)

    self:initData(pageIndex)
end

function KangaroosShopPage:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function KangaroosShopPage:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

end

-- 数据处理
function KangaroosShopPage:initData(pageIndex)
    self.m_pageIndex = pageIndex
end

-- free：本次点击属于免费
-- 触发freespin时只播放兑换动作，不刷新UI， 等待freespin开始界面弹出来
function KangaroosShopPage:playPageUIAction(free, noPlayStart, callFunc)
    -- 播放动作
    local pageCellIndex = KangaroosShopData:getRequestPageCellIndex()
    if free then
        local flyOverCallFunc = function()
            local isFreeSpin = KangaroosShopData:getFreeSpinState()
            -- 如果是触发freespin界面的话
            if isFreeSpin == true then
                -- 只刷新点击的，全部金币
                self:updatePageCell(pageCellIndex, noPlayStart, free, nil, function()
                    KangaroosShopData:setExchangeEffectState(false)
                    self:flyCoins(pageCellIndex,function(  )
                        performWithDelay(self, function()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_KANGAROOS_SHOP_FREE_SPIN, "start")
                        end, SUPER_FREESPIN_DELAY_CLOSEUI)
                    end)
                end)
            else
                KangaroosShopData:setExchangeEffectState(false)
                self:flyCoins(pageCellIndex,function(  )
                end)    
                if not tolua.isnull(self) and callFunc then
                    callFunc()
                end    
            end            
        end
        local callBack = function()
            self:freeFly(KangaroosShopData:getRequestPageCellIndex(), flyOverCallFunc)            
        end
        -- 只刷新点击的，一半金币
        self:updatePageCell(pageCellIndex, noPlayStart, free, true, callBack)
    else
        local isFreeSpin = KangaroosShopData:getFreeSpinState()
        -- 如果是触发freespin界面的话
        if isFreeSpin == true then
            -- 只刷新点击的，全部金币
            self:updatePageCell(pageCellIndex, noPlayStart, true, nil, function()
                KangaroosShopData:setExchangeEffectState(false)
                self:flyCoins(pageCellIndex,function(  )
                    performWithDelay(self, function()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_KANGAROOS_SHOP_FREE_SPIN, "start")
                    end, SUPER_FREESPIN_DELAY_CLOSEUI)
                end)  
            end)
      
        else
            self:updatePageCell(pageCellIndex, noPlayStart, nil, nil, function()
                KangaroosShopData:setExchangeEffectState(false)
                self:flyCoins(pageCellIndex, function(  )
                end)  
                if not tolua.isnull(self) and callFunc then
                    callFunc()
                end
            end)
        end
    end
end

function KangaroosShopPage:updateUI(noPlayStart)
    for i=1,9 do   
        self:updatePageCell(i, noPlayStart)
    end
end

function KangaroosShopPage:updatePageCell(cellIndex, noPlayStart, free, half, callBack)
    local pageCellStatus = KangaroosShopData:getPageCellState(self.m_pageIndex, cellIndex)
    
    -- 最后一页的最后一个翻页的时候，数据会全部变成-1（未翻转状态）
    -- 所以最后一页的最后一个翻转要特殊处理
    if free and KangaroosShopData:isAllUnopen() then
        pageCellStatus = "PageStatus_opened"
    end

    local node = self:findChild("Node_"..cellIndex)
    local child = node:getChildByName(pageCellStatus)
    if child then
        child:updateUI(noPlayStart, free, half, callBack)
    else
        -- 新界面播放动作
        local newUI = function(scaleAction)
            local view 
            if pageCellStatus == "PageStatus_free" then
                view = util_createView("CodeOutbackFrontierShopSrc.KangaroosShopPage2x",self.m_pageIndex, cellIndex)
            elseif pageCellStatus == "PageStatus_opened" then
                view = util_createView("CodeOutbackFrontierShopSrc.KangaroosShopPageCoin",self.m_pageIndex, cellIndex)
            elseif pageCellStatus == "PageStatus_unopen" then
                view = util_createView("CodeOutbackFrontierShopSrc.KangaroosShopPageunOpen",self.m_pageIndex, cellIndex)
            elseif pageCellStatus == "PageStatus_unlock" then
                view = util_createView("CodeOutbackFrontierShopSrc.KangaroosShopPageunOpen",self.m_pageIndex, cellIndex)            
            end
            view:setName(pageCellStatus)
            if scaleAction then
                noPlayStart = false
            end
            view:updateUI(noPlayStart, free, half, callBack)
            node:removeAllChildren()
            node:addChild(view)
        end
        child = node:getChildByName("PageStatus_unopen")
        if child then
            -- 旧界面播放动作
            child:playSuccessBuyAction(function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_KANGAROOS_SHOP_PAGE_BUY_SUCCESS)
                newUI(true)
            end)
        else
            newUI()
        end
    end
end

-- freeFlyTocellIndex: 目标点
function KangaroosShopPage:freeFly(flyTocellIndex, callFunc)
    -- local startIndex = nil
    -- for cellIndex=1,9 do
    --     local pageCellStatus = KangaroosShopData:getPageCellState(self.m_pageIndex, cellIndex)
    --     if pageCellStatus == "PageStatus_free" then
    --         startIndex = cellIndex
    --         break
    --     end
    -- end

    local frees = KangaroosShopData:getPagesFree()
    local startIndex = frees[self.m_pageIndex][2]

    if not startIndex then
        -- 理论上这个地方肯定不会调用
        if callFunc then
            callFunc()
        end
        return
    end
    if KangaroosShopData:getFlyData() == true then
        if callFunc then
            callFunc()
        end        
        return
    end
    KangaroosShopData:setFlyData(true)    
    self:flyto(startIndex, flyTocellIndex, callFunc)
end

function KangaroosShopPage:flyto(startIndex, endIndex, callFunc)
    local startNode = self:findChild("Node_"..startIndex)
    local endNode = self:findChild("Node_"..endIndex)

    local particle = cc.ParticleSystemQuad:create("Kangaroos_shoujiTrail.plist")
    startNode:getParent():addChild(particle)
    particle:setPosition(startNode:getPosition())
    
    local epos = cc.p(endNode:getPosition())
    local moveTo = cc.MoveTo:create(0.5, epos)
    local removeCallFunc = cc.CallFunc:create(function()
        if callFunc then
            callFunc()
        end
        particle:removeFromParent()
        
        KangaroosShopData:setFlyData(false)
        -- local view = self:findChild("Node_"..endIndex):getChildByName("PageStatus_opened")
        -- if view then
        --     view:changeDouble()
        -- end
    end)
    particle:runAction(cc.Sequence:create(moveTo, removeCallFunc))        
end

function KangaroosShopPage:flyCoins(pageCellIndex,callFun)
    local pageCellStatus = KangaroosShopData:getPageCellState(self.m_pageIndex, pageCellIndex)
    if pageCellStatus == "PageStatus_free" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
        return
    end
    local endPos = globalData.flyCoinsEndPos
    local pageCellIndex = KangaroosShopData:getRequestPageCellIndex()
    local startNode = self:findChild("Node_"..pageCellIndex)
    local startPos = startNode:getParent():convertToWorldSpace(cc.p(startNode:getPosition()))
    local baseCoins = globalData.topUICoinCount 
    local addCoins = globalData.userRunData.coinNum - baseCoins
    gLobalViewManager:pubPlayFlyCoin(startPos,endPos,baseCoins,addCoins,function ()
         if not tolua.isnull(self) and callFun then
            callFun()
        end
    end )
end

return KangaroosShopPage