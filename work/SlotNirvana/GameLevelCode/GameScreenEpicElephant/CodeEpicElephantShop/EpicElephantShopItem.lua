---
--xcyy
--2018年5月23日
--EpicElephantShopItem.lua

local EpicElephantShopItem = class("EpicElephantShopItem",util_require("Levels.BaseLevelDialog"))


function EpicElephantShopItem:initUI(params)
    self.m_parentView = params.parent
    self.m_index = params.index
    self:createCsbNode("EpicElephant_shop_stuff.csb")

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(170,170))
    layout:setTouchEnabled(true)
    self:addClick(layout)

    self:runCsbAction("idle",true)
end

--[[
    设置锁定状态
]]
function EpicElephantShopItem:setLockStatus(isLock)

    if isLock then
        self:runCsbAction("sidle",true)
    else
        self:runCsbAction("idle",true)
    end
    
end

--[[
    刷新UI
]]
function EpicElephantShopItem:refreshUI(data, isSuperFreeBack, isPlaySound)
    --价格
    local price = data.cost[self.m_index]
    self:findChild("m_lb_coins_price"):setString(util_formatCoins(price,8))
    
    --金币是否充足
    self.m_isCoinEnough = data.coins >= price
    self.m_isLocked = data.isLocked
    self.m_isSelected = data.shop[self.m_index] ~= 0
    self:setLockStatus(data.isLocked)
    
    if isSuperFreeBack then
        self.m_isLocked = true
        self:runCsbAction("sidle",true)
        -- 延迟45帧在播放解锁 是为了等待商店界面的start时间线播放完
        self.m_parentView.m_machine:delayCallBack(45/60,function()
            if isPlaySound then
                gLobalSoundManager:playSound(self.m_parentView.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_shop_jieSuo)
            end

            self:runCsbAction("jiesuo",false,function()
                self.m_isLocked = data.isLocked

                if not self.m_isCoinEnough then
                    self:runCsbAction("anidle",true)
                end
            end)
        end)
    else
        if not data.isLocked then

            if self.m_isSelected then
                self:updateReward(data.shopCoins[self.m_index])
            else
                if not self.m_isCoinEnough then
                    self:runCsbAction("anidle",true)
                end
            end
            
        end
    end
end

--[[
    刷新UI
]]
function EpicElephantShopItem:refreshUIPrice(data)

    --价格
    local price = data.cost[self.m_index]
    --金币是否充足
    self.m_isCoinEnough = data.coins >= price

    self.m_isSelected = data.shop[self.m_index] ~= 0
    
    if not data.isLocked then

        if self.m_isSelected then
            
        else
            if not self.m_isCoinEnough then
                if data.features and data.features == 0 then
                    if not data.extraPick[self.m_parentView.m_curPageIndex] then
                        self:runCsbAction("anidle",true)
                    end
                end
            end
        end
        
    end
    --当前购买 免费
    if data.extraPick[self.m_parentView.m_curPageIndex] and data.extraPickPos and data.extraPickPos[self.m_parentView.m_curPageIndex] and
    data.extraPickPos[self.m_parentView.m_curPageIndex][1] and (self.m_parentView.m_curPageIndex == (data.extraPickPos[self.m_parentView.m_curPageIndex][1]+1)) then
        self:findChild("m_lb_coins_price"):setVisible(false)
        self:findChild("free"):setVisible(true)
    else
        self:findChild("m_lb_coins_price"):setVisible(true)
        self:findChild("free"):setVisible(false)
    end
end

--[[
    刷新奖励
]]
function EpicElephantShopItem:updateReward(reward, isPlayEffect, func, isChengBei)
    
    if tostring(reward) == "extraPick" then
        self:findChild("bought_1"):setVisible(true)
        self:findChild("bought_money"):setVisible(false)
    else
        if not isChengBei then
            self:findChild("bought_1"):setVisible(false)
            self:findChild("bought_money"):setVisible(true)
            self:findChild("m_lb_coins"):setString(util_formatCoins(reward,3))
            self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=1,sy=1},135)
        end
    end

    if isPlayEffect then
        self:runCsbAction("actionframe",false,function()
            if tostring(reward) == "extraPick" then
                self:runCsbAction("idle2",true)
            else
                self:runCsbAction("idle1",true)
            end
            if func then
                func()
            end
        end)
    else
        if isChengBei then
            self:runCsbAction("fankui",false,function()
                self:runCsbAction("idle1",true)
                if func then
                    func()
                end
            end)
            self.m_parentView.m_machine:delayCallBack(9/60,function()
                self:findChild("bought_1"):setVisible(false)
                self:findChild("bought_money"):setVisible(true)
                self:findChild("m_lb_coins"):setString(util_formatCoins(reward,3))
                self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=1,sy=1},135)
            end)
        else
            self:runCsbAction("idle1",true)
        end
    end
end

--默认按钮监听回调
function EpicElephantShopItem:clickFunc(sender)
    if self.m_isSelected then
        return
    end
    if self.m_isLocked then
        self.m_parentView:showCoinNotEnough(self.m_index,false,true)
        return
    end
    --金币不足
    if not self.m_isCoinEnough and not self:findChild("free"):isVisible() then
        self.m_parentView:showCoinNotEnough(self.m_index,false,false)
        return
    end
    self.m_parentView:clickItem(self.m_index)
end


return EpicElephantShopItem