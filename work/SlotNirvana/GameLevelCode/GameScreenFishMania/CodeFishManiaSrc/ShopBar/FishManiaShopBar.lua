---
--xcyy
--2018年5月23日
--FishManiaShopBar.lua

local FishManiaShopBar = class("FishManiaShopBar",util_require("base.BaseView"))

FishManiaShopBar.m_pickScore = 0
FishManiaShopBar.m_jumpPickScore = 0
FishManiaShopBar.m_buyState = 0          -- 0:无法购买 1:可以购买
FishManiaShopBar.m_maxPickScore = 99999  -- 展示的上限积分


function FishManiaShopBar:initUI()

    self:createCsbNode("FishMania_progress.csb")

    self.m_ShopBtnCallBackList = {}   --按钮点击回调列表

    self:addClick(self:findChild("clickShowTip")) 
    self:addClick(self:findChild("clickShowShop")) 
   

    self.m_coins = self:findChild("m_lb_coins")
    
    self.m_logo = util_createAnimation("FishMania_progress_chuizi.csb")
    self:findChild("Node_logo"):addChild(self.m_logo)
    self.m_logo:runCsbAction("idleframe1", true)

    self.m_tip = util_createAnimation("FishMania_progree_tip.csb")
    self:findChild("tip"):addChild(self.m_tip)
    util_setCascadeOpacityEnabledRescursion(self.m_tip, true)
    self.m_tip:setVisible(false)
    self:changeTipShow()

    self.m_fingertip = util_createAnimation("FishMania_shangdian_shou.csb")
    self:findChild("shouzhiNode"):addChild(self.m_fingertip)
    self.m_fingertip:setVisible(false)

    self.m_isCanTouch = true
    --
    self:runCsbAction("idleframe", true)
    self:updateCoins(self.m_pickScore)
    
end

function FishManiaShopBar:onExit()
    gLobalNoticManager:removeAllObservers(self)
    if self.m_jumpCoinHandlerID then
        scheduler.unscheduleGlobal(self.m_jumpCoinHandlerID)
        self.m_jumpCoinHandlerID = nil
    end
    FishManiaShopBar.super.onExit(self)
end

--设置界面按钮是否可点击
function FishManiaShopBar:setIsCanTouch(isCan)
    self.m_isCanTouch = isCan
end

--默认按钮监听回调
function FishManiaShopBar:clickFunc(sender)
    if not self.m_isCanTouch then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "clickShowTip" then
        self:changeTipShow()
    elseif name == "clickShowShop" then
        self:onShopBtnClick()
    end
end

function FishManiaShopBar:onShopBtnClick()
    gLobalSoundManager:playSound("FishManiaSounds/FishMania_shop_click.mp3")

    --freeSpin
    local currSpinMode = globalData.slotRunData.currSpinMode
    if currSpinMode == FREE_SPIN_MODE then
        return
    end
    --不在引导状态下的autoSpin点击
    if currSpinMode == AUTO_SPIN_MODE then     
        local p_shopData = globalMachineController.p_fishManiaShopData
        local isGuide = p_shopData:getGuideState()
        if not isGuide then
            return
        end
    end


    

    -- 修改为商店引导，由外部关闭
    -- if self.m_fingertip:isVisible() then
    --     self.m_fingertip:setVisible(false)
    -- end
    if self.m_tip:isVisible() then
        self:changeTipShow()
    end
    self:stopJumpCoins()
    gLobalNoticManager:postNotification(globalMachineController.p_fishManiaPlayConfig.EventName.SHOPLISTVIEW_SHOW_HIDE)
    self:triggerShopBtnCallBack()
end

function FishManiaShopBar:registerShopBtnClickCallBack(_fun)
    local registerId = -1
    if "function" ~= type(_fun)  then
        return registerId
    end

    registerId = 0
    while nil ~= self.m_ShopBtnCallBackList[registerId] do
        registerId = registerId + 1
    end
    
    self.m_ShopBtnCallBackList[registerId] = _fun

    return registerId
end
function FishManiaShopBar:unRegisterShopBtnClickCallBack(_registerId)
    if nil ~= self.m_ShopBtnCallBackList[_registerId] then
        self.m_ShopBtnCallBackList[_registerId] = nil
    end
end

function FishManiaShopBar:triggerShopBtnCallBack()
    for _registerId,_callback in pairs(self.m_ShopBtnCallBackList) do
        _callback(_registerId)
    end
end

-- 刷新商店的购买状态
function FishManiaShopBar:upDateShopBuyState()
    local p_shopData = globalMachineController.p_fishManiaShopData
    local bCanBuy = p_shopData:getShopIsCanBuy()

    local oldState = self.m_buyState
    local newState = bCanBuy and 1 or 0

    if oldState ~= newState then
        -- 切换为 可购买状态
        if 1 == newState then
            gLobalSoundManager:playSound("FishManiaSounds/FishMania_shopBar_canBuy.mp3")

            self.m_logo:runCsbAction("actionframe1", false, function()
                self.m_logo:runCsbAction("idleframe", true)
            end)
        -- 切换为 不可购买状态
        else
            self.m_logo:runCsbAction("actionframe", false, function()
                self.m_logo:runCsbAction("idleframe1", true)
            end)
        end

        self.m_buyState = newState
    end
end
-- 展示手指指引
function FishManiaShopBar:playFingerTipAnim()
    self.m_fingertip:setVisible(true)
    self.m_fingertip:runCsbAction("actionframe", true)
end
function FishManiaShopBar:playCollectAnim()
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idleframe", true)
    end)
    
    local particle = self:findChild("Particle_1")
    if particle then
        particle:setVisible(true)
        particle:stopSystem()
        particle:resetSystem()
    end

    local particle_2 = self:findChild("Particle_2")
    if particle_2 then
        particle_2:setVisible(true)
        particle_2:stopSystem()
        particle_2:resetSystem()
    end
end
--[[
    商店提示
]]
function FishManiaShopBar:changeTipShow()
    if self.m_runTipAct then
        return
    end
    self.m_runTipAct = true

    local isVis = self.m_tip:isVisible()
    
    if not isVis then
        self.m_tip:setVisible(true)
    end

    local actName = isVis and "over" or "start"
    
    self.m_tip:runCsbAction(actName, false, function()
        self.m_runTipAct = false
        if not isVis then
            --打开后2.5s后再次关闭
            local actTable = {}
            local act_delay = cc.DelayTime:create(2.5)
            table.insert(actTable, act_delay)
            local act_callfun = cc.CallFunc:create(function()
                if self.m_tip:isVisible() and not self.m_runTipAct then
                    self:changeTipShow()
                end
            end)
            table.insert(actTable, act_callfun)
            self.m_tip:runAction(cc.Sequence:create(actTable))
        else
            self.m_tip:setVisible(false)
        end
    end)
end

--[[
    商店代币相关
]]
--直接刷新
function FishManiaShopBar:updateCoins( _score)
    self.m_pickScore = math.min(self.m_maxPickScore, _score) 
    self.m_coins:setString(util_formatCoins(self.m_pickScore, 50))
    self:updateLabelSize({label=self.m_coins,sx=1,sy=1},96)
end
--停止跳动
function FishManiaShopBar:stopJumpCoins()
    if self.m_jumpCoinHandlerID then
        scheduler.unscheduleGlobal(self.m_jumpCoinHandlerID)
        self.m_jumpCoinHandlerID = nil

        self:updateCoins(self.m_jumpPickScore)
    end
end
--跳动刷新
function FishManiaShopBar:jumpConis(_score)
    self.m_jumpPickScore = math.min(self.m_maxPickScore, _score) 
    if self.m_jumpCoinHandlerID then
        return
    end

    self.m_jumpCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        if self.m_pickScore ~= self.m_jumpPickScore then
            local offset = self.m_jumpPickScore - self.m_pickScore
            local interval = offset / (1 * 60)
            local str = string.gsub(tostring(interval),"0",math.random( 1, 5 ))
            interval = math.ceil(tonumber(str) )  

            self.m_pickScore = self.m_pickScore + interval
            --是否结束跳动
            if (offset > 0 and  self.m_pickScore > self.m_jumpPickScore) or 
                (offset <= 0 and  self.m_pickScore < self.m_jumpPickScore)  then

                self.m_pickScore = self.m_jumpPickScore
                self:updateCoins(self.m_pickScore)
            --继续下一次跳动
            else
                self:updateCoins(self.m_pickScore)
                return
            end
        end

        if self.m_jumpCoinHandlerID then
            scheduler.unscheduleGlobal(self.m_jumpCoinHandlerID)
            self.m_jumpCoinHandlerID = nil
        end
        
    end)
end

function FishManiaShopBar:getShopLogoWorldPos()
    local endNode = self:findChild("Node_logo")
    local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    return worldPos
end

return FishManiaShopBar