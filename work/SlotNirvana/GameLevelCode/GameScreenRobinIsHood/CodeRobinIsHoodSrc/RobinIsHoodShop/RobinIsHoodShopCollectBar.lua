---
--xcyy
--2018年5月23日
--RobinIsHoodShopCollectBar.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local RobinIsHoodShopCollectBar = class("RobinIsHoodShopCollectBar",util_require("base.BaseView"))

local BTN_TAG_TIP   =   1001    --提示按钮
local BTN_TAG_SHOP  =   1002    --显示商店

function RobinIsHoodShopCollectBar:initUI(params)
    --当前本地时间戳
    self.m_timeStamp = 0
    self.m_discountLeftTime = 0 --折扣券剩余时间
    self.m_machine = params.machine
    self:createCsbNode("RobinIsHood_base_money.csb")

    self.m_btn_csb = util_createAnimation("RobinIsHood_base_money_i.csb")
    self:findChild("Node_base_i"):addChild(self.m_btn_csb)
    local btn = self.m_btn_csb:findChild("Button_base_i")
    btn:setTag(BTN_TAG_TIP)
    self:addClick(btn)

    self.m_btn_show_shop = self:findChild("panel_shop")
    self.m_btn_show_shop:setTag(BTN_TAG_SHOP)
    self:addClick(self.m_btn_show_shop)

    --折扣券
    self.m_message = util_createAnimation("RobinIsHood_base_zhekouquan.csb")
    self:findChild("Node_message1"):addChild(self.m_message)
    for index = 1,2 do
        local particle = self.m_message:findChild("Particle_"..index)
        if not tolua.isnull(particle) then
            particle:setVisible(false)
        end
    end
    self.m_message:setVisible(false)

    --tip
    self.m_tip = util_createAnimation("RobinIsHood_base_money_i_message.csb")
    self:findChild("Node_base_i"):addChild(self.m_tip)
    self.m_tip:setVisible(false)

    --是否可点击提示
    self.m_canClickTip = true
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function RobinIsHoodShopCollectBar:initSpineUI()
    
end

--[[
    设置金币数量
]]
function RobinIsHoodShopCollectBar:setCoins(coins)
    local label = self:findChild("m_lb_coins")
    label:setString(util_formatCoins(coins,5))

    local info = {label = label, sx = 1.5, sy = 1.5}
    self:updateLabelSize(info, 93)
end

--[[
    收集金币反馈动画
]]
function RobinIsHoodShopCollectBar:runCollectCoinsFeedBackAni()
    self:runCsbAction("actionframe")
    local particle = self:findChild("Particle_1")
    if not tolua.isnull(particle) then
        particle:resetSystem()
    end
end

--[[
    更新折扣券显示
]]
function RobinIsHoodShopCollectBar:updateDisCountShow(hour,minute,second)
    local Time_S = self.m_message:findChild("Time_S")
    local Time_M = self.m_message:findChild("Time_M")
    local Time_H = self.m_message:findChild("Time_H")
    Time_S:setString(second)
    Time_M:setString(minute)
    Time_H:setString(hour)

    self.m_machine.m_shopView.m_coins_bar:updateDisCountShow(hour,minute,second)
end

--[[
    折扣券反馈动画
]]
function RobinIsHoodShopCollectBar:runDiscountFeedBack()
    if self.m_message:isVisible() then
        self.m_machine:delayCallBack(0.5,function()
            self.m_message:runCsbAction("actionframe3")
        end)
        
        local particle = self.m_message:findChild("Particle_1")
        if not tolua.isnull(particle) then
            particle:setVisible(true)
            particle:resetSystem()
        end
        return true
    else
        self.m_message:setVisible(true)
        local particle = self.m_message:findChild("Particle_2")
        if not tolua.isnull(particle) then
            particle:setVisible(true)
            particle:setPositionType(0)
        end

        self.m_message:runCsbAction("actionframe2",false,function()
            if not tolua.isnull(particle) then
                particle:stopSystem()
            end
        end)
        return false
    end
    
end

--[[
    刷新折扣倒计时
]]
function RobinIsHoodShopCollectBar:updateDiscountTime(leftTime)
    self.m_message:stopAllActions()
    if leftTime <= 0 then
        self.m_machine.m_isDiscount = false   --是否折扣
        self.m_machine.m_shopView.m_coins_bar:idleWithOutDiscountAni()
        self.m_message:setVisible(false)
        self:updateDisCountShow(0,0,0)
        return
    end
    self.m_machine.m_isDiscount = true   --是否折扣
    self.m_machine.m_shopView.m_coins_bar:idleWithDiscountAni()
    if not self.m_message:isVisible() then
        self.m_message:setVisible(true)
        self.m_message:runCsbAction("idleframe")
    end
    
    self.m_timeStamp = os.time()
    self.m_discountLeftTime = leftTime
    local hour,minute,second = self.m_machine:getFormatTime(leftTime)
    self:updateDisCountShow(hour,minute,second)

    util_schedule(self.m_message,function()
        local curTimeStamp = os.time()
        local tempTime = curTimeStamp - self.m_timeStamp
        local leftTime = self.m_discountLeftTime - tempTime
        if leftTime <= 0 then
            leftTime = 0
            self.m_machine.m_isDiscount = false   --是否折扣
            self:updateDisCountShow(0,0,0)
            self.m_message:stopAllActions()
            self.m_message:runCsbAction("over",false,function()
                self.m_message:setVisible(false)
            end)
            self.m_machine.m_shopView.m_coins_bar:runOverAni()
            self.m_machine.m_shopView:updateCurPageView()
        else
            local hour,minute,second = self.m_machine:getFormatTime(leftTime)
            self:updateDisCountShow(hour,minute,second)
        end
    end,1)
end

--[[
    显示提示
]]
function RobinIsHoodShopCollectBar:showTipAni(func)
    self.m_tip:stopAllActions()
    self.m_canClickTip = false
    self.m_tip:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_show_base_tip)
    self.m_tip:runCsbAction("start",false,function()
        self.m_canClickTip = true
    end)
    performWithDelay(self.m_tip,function()
        self:hideTipAni()
    end,30 / 60 + 5)
end

--[[
    隐藏提示
]]
function RobinIsHoodShopCollectBar:hideTipAni(func)
    self.m_canClickTip = false
    self.m_tip:stopAllActions()
    self.m_tip:runCsbAction("over")
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_hide_base_tip)
    performWithDelay(self.m_tip,function()
        self.m_tip:setVisible(false)
        self.m_canClickTip = true
    end,30 / 60)
end

--[[
    提示是否显示
]]
function RobinIsHoodShopCollectBar:isShowTip()
    local isShow = self.m_tip:isVisible()
    return isShow
end

--默认按钮监听回调
function RobinIsHoodShopCollectBar:clickFunc(sender)
    if not self.m_machine:collectBarClickEnabled() then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()

    if tag == BTN_TAG_TIP then
        if not self.m_canClickTip then
            return
        end
        if self:isShowTip() then
            self:hideTipAni()
        else
            self:showTipAni()
        end
    elseif tag == BTN_TAG_SHOP then
        local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
        local pageIndex
        if selfData and selfData.lastBuy and not selfData.firstRound then
            pageIndex = selfData.lastBuy[1] + 1
            if pageIndex > 5 then
                pageIndex = 5
            end
        end
        
        self.m_machine.m_shopView:showView(pageIndex)
    end
end


return RobinIsHoodShopCollectBar