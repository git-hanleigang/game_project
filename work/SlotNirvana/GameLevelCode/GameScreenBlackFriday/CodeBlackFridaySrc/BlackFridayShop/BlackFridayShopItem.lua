---
--xcyy
--2018年5月23日
--BlackFridayShopItem.lua

local BlackFridayShopItem = class("BlackFridayShopItem",util_require("Levels.BaseLevelDialog"))

function BlackFridayShopItem:initUI(params)
    self.m_parentView = params.parent
    self.m_index = params.index
    self:createCsbNode("BlackFriday_shop_shangpin.csb")

    --价格
    self.m_priceNode = util_createAnimation("BlackFriday_shop_jiage.csb")
    self:findChild("Node_jiage"):addChild(self.m_priceNode)

    -- 赢钱
    self.m_winCoinsNode = util_createAnimation("BlackFriday_shop_qian.csb")
    if self.m_index%2 == 1 then
        self:findChild("Node_wanzi_xianglian"):addChild(self.m_winCoinsNode)
    else
        self:findChild("Node_wanzi_erhuan"):addChild(self.m_winCoinsNode)
    end

    --创建点击区域
    self:addClick(self:findChild("Panel_2"))

    self:playItemIdle()

    self:findChild("Node_xianglian"):setVisible(self.m_index%2 == 1)
    self:findChild("Node_erhuan"):setVisible(self.m_index%2 == 0)
end

--[[
    物品是否播放idle
]]
function BlackFridayShopItem:playItemIdle()
    if self.m_isClick or self.m_isLocked or self.m_isSelected then
        self.m_parentView.m_machine:waitWithDelay(4,function()
            self:playItemIdle()
        end)

        return
    end

    local random = math.random(1,100)
    if random <= 50 then
        self:runCsbAction("idleframe",false,function()
            self:playItemIdle()
        end)
    else
        self:runCsbAction("idle1",false,function()
           
            self.m_parentView.m_machine:waitWithDelay(4,function()
                self:playItemIdle()
            end)
            
        end)
    end
end

--[[
    设置锁定状态
]]
function BlackFridayShopItem:setLockStatus(_isLock, _isSelected)

    if _isLock then
        self:findChild("xianglian_zhezhao"):setVisible(true)
        self:findChild("xianglian_jie"):setVisible(true)
        self:findChild("erhuan_zhezhao"):setVisible(true)
        self:findChild("erhuan_jie"):setVisible(true)
        self:findChild("Node_1"):setVisible(false)
        self:findChild("Node_2"):setVisible(false)
    else
        self:findChild("xianglian_zhezhao"):setVisible(false)
        self:findChild("erhuan_zhezhao"):setVisible(false)
        self:findChild("xianglian_jie"):setVisible(false)
        self:findChild("erhuan_jie"):setVisible(false)
        self:findChild("Node_1"):setVisible(true)
        self:findChild("Node_2"):setVisible(true)
    end
    
end

--[[
    设置金币不足状态
]]
function BlackFridayShopItem:setCoinEnoughStatus(_isCoinEnough)

    -- if _isCoinEnough then
        self.m_priceNode:findChild("zhezhao"):setVisible(false)
        self.m_priceNode:findChild("zhezhao1"):setVisible(false)
    -- else
    --     self.m_priceNode:findChild("zhezhao"):setVisible(true)
    --     self.m_priceNode:findChild("zhezhao1"):setVisible(true)
    -- end
    
end

--[[
    刷新UI
]]
function BlackFridayShopItem:refreshUI(_data, _isSuperFreeBack, _isPlaySound)
    --价格
    local price = _data.cost[self.m_index]
    
    if self.m_parentView.m_isZheKou then
        -- 折扣价
        self.m_priceNode:findChild("m_lb_coins_0"):setString(util_formatCoins(price*0.7, 8))
        self:updateLabelSize({label=self.m_priceNode:findChild("m_lb_coins_0"),sx=0.65,sy=0.65},135)

        -- 原件
        self.m_priceNode:findChild("m_lb_coins_1"):setString(util_formatCoins(price,8))
        self:updateLabelSize({label=self.m_priceNode:findChild("m_lb_coins_1"),sx=0.5,sy=0.5},135)
    else
        self.m_priceNode:findChild("m_lb_coins"):setString(util_formatCoins(price,8))
        self:updateLabelSize({label=self.m_priceNode:findChild("m_lb_coins"),sx=0.65,sy=0.65},135)
    end
    
    --金币是否充足
    self.m_isCoinEnough = _data.coins >= price
    if self.m_parentView.m_isZheKou then
        self.m_isCoinEnough = _data.coins >= (price*0.7)
    end

    self.m_isLocked = _data.isLocked
    self.m_isSelected = _data.shop[self.m_index] ~= 0
    self:setLockStatus(_data.isLocked)
    
    if _isSuperFreeBack then
        self.m_winCoinsNode:runCsbAction("idle1",false)
        if self.m_parentView.m_isZheKou then
            self.m_priceNode:runCsbAction("idle2",true) 
        else
            self.m_priceNode:runCsbAction("idle1",true) 
        end

        -- 挂一个 丝带spine 然后 播放解锁动画
        local sidaiSpine = util_spineCreate("BlackFriday_sidai",true,true)
        self:findChild("Node_sidai"):addChild(sidaiSpine)
        -- 延迟45帧在播放解锁 是为了等待商店界面的start时间线播放完
        self.m_parentView.m_machine:waitWithDelay(30/60,function()
            util_spinePlay(sidaiSpine, "jiesuo", false)
            util_spineEndCallFunc(sidaiSpine, "jiesuo", function()
                if not self.m_isCoinEnough then
                    self:setCoinEnoughStatus(self.m_isCoinEnough)
                end
            end)
        end)
    else
        if not _data.isLocked then

            if self.m_isSelected then
                self:updateReward(_data.shopCoins[self.m_index],nil,nil,nil,_data)
            else
                if not self.m_isCoinEnough then
                    self:setCoinEnoughStatus(self.m_isCoinEnough)
                    self:showWinCoinsAndPrice()
                else
                    self:showWinCoinsAndPrice()
                end
            end
        else
            self:showWinCoinsAndPrice()
        end
    end
end

-- 显示购买之后的 赢钱 和 价格
function BlackFridayShopItem:showWinCoinsAndPrice( )
    self.m_winCoinsNode:runCsbAction("idle1",false)
    self:runCsbAction("idle1",false)
    -- 免费 不管有没有折扣 都显示成 free
    if  self.m_priceNode:findChild("free"):isVisible() then
        self.m_priceNode:runCsbAction("idle1",true) 
    else
        if self.m_parentView.m_isZheKou then
            self.m_priceNode:runCsbAction("idle2",true) 
        else
            self.m_priceNode:runCsbAction("idle1",true) 
        end
    end
end

--[[
    刷新UI
]]
function BlackFridayShopItem:refreshUIPrice(_data, _isComeIn)

    --价格
    local price = _data.cost[self.m_index]
    --金币是否充足
    self.m_isCoinEnough = _data.coins >= price
    if self.m_parentView.m_isZheKou then
        self.m_isCoinEnough = _data.coins >= (price*0.7)
    end

    self.m_isSelected = _data.shop[self.m_index] ~= 0
    
    self:setCoinEnoughStatus(self.m_isCoinEnough)
    
    --当前购买 免费
    if _data.extraPick[self.m_parentView.m_curPageIndex] and _data.extraPickPos and _data.extraPickPos[self.m_parentView.m_curPageIndex] and
    _data.extraPickPos[self.m_parentView.m_curPageIndex][1] and (self.m_parentView.m_curPageIndex == (_data.extraPickPos[self.m_parentView.m_curPageIndex][1]+1)) then
        if self.m_isSelected then
            self.m_priceNode:runCsbAction("idle",false)
        else
            self.m_priceNode:runCsbAction("idle1",true) 
            self.m_priceNode:findChild("m_lb_coins"):setVisible(false)
            self.m_priceNode:findChild("free"):setVisible(true)
        end 
    else
        -- 不免费
        self.m_priceNode:findChild("free"):setVisible(false)
        -- 有折扣
        if self.m_parentView.m_isZheKou then
            if not self.m_isSelected then
                self.m_priceNode:runCsbAction("idle2",true) 
            end
        else
            -- 没有买过
            if not self.m_isSelected then
                self.m_priceNode:runCsbAction("idle1",true) 
            end
            self.m_priceNode:findChild("m_lb_coins"):setVisible(true)
        end
    end
end

--[[
    刷新奖励
]]
function BlackFridayShopItem:updateReward(_reward, _isPlayEffect, _func, _isChengBei, _data)
    if tostring(_reward) == "extraPick" then
        self.m_winCoinsNode:findChild("m_lb_num"):setVisible(false)
        self.m_winCoinsNode:findChild("zi"):setVisible(true)
    else
        self.m_winCoinsNode:findChild("m_lb_num"):setString(util_formatCoins(_reward,3))
        self:updateLabelSize({label=self.m_winCoinsNode:findChild("m_lb_num"),sx=1,sy=1},125)
        self.m_winCoinsNode:findChild("m_lb_num"):setVisible(true)
        self.m_winCoinsNode:findChild("zi"):setVisible(false)
    end

    if _isPlayEffect then
        self.m_winCoinsNode:setVisible(false)
        self.m_isClick = true
        self:runCsbAction("actionframe",false)
        if self.m_parentView.m_isZheKou then
            if self.m_priceNode:findChild("free"):isVisible() then
                self.m_priceNode:runCsbAction("fanzhuan",false) 
            else
                self.m_priceNode:runCsbAction("fanzhuan1",false)
            end
        else
            self.m_priceNode:runCsbAction("fanzhuan",false) 
        end 

        -- 5帧的时候 播放
        self.m_parentView.m_machine:waitWithDelay(5/60,function()
            self.m_winCoinsNode:setVisible(true)
            local startActionFrane = "idle"
            if tostring(_reward) == "extraPick" then
                startActionFrane = "start"
                gLobalSoundManager:playSound(self.m_parentView.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_shop_chegbei)
            end
            self.m_winCoinsNode:runCsbAction(startActionFrane,false,function()
                if tostring(_reward) == "extraPick" then
                    self.m_winCoinsNode:runCsbAction("idle2",true)
                end

                if _func then
                    _func()
                end
            end)
        end)
        
    else
        --当前购买 免费
        if _data and _data.extraPick[self.m_parentView.m_curPageIndex] and _data.extraPickPos and _data.extraPickPos[self.m_parentView.m_curPageIndex] and
            _data.extraPickPos[self.m_parentView.m_curPageIndex][1] and (self.m_parentView.m_curPageIndex == (_data.extraPickPos[self.m_parentView.m_curPageIndex][1]+1)) then

            if tostring(_reward) == "extraPick" then
                self.m_winCoinsNode:runCsbAction("idle2",true)
            else
                self.m_winCoinsNode:runCsbAction("idle",false)
            end
        else
            self.m_winCoinsNode:runCsbAction("idle",false)
        end
        
        self.m_priceNode:runCsbAction("idle",false) 
        self:runCsbAction("idle",false) 

        if _func then
            _func()
        end
    end
end

--默认按钮监听回调
function BlackFridayShopItem:clickFunc(sender)
    if self.m_parentView.m_isMoved then
        return
    end

    if self.m_isSelected then
        return
    end
    if self.m_isLocked then
        self.m_parentView:showCoinNotEnough(self.m_index,false,true)
        return
    end
    --金币不足
    if not self.m_isCoinEnough and not self.m_priceNode:findChild("free"):isVisible() then
        self.m_parentView:showCoinNotEnough(self.m_index,false,false)
        return
    end

    self.m_parentView:clickItem(self.m_index)
end

--默认按钮监听回调 滑动
function BlackFridayShopItem:clickEndFunc(sender)

    local name = sender:getName()
    local btnTag = sender:getTag()

    if name == "Panel_2" then
        self.m_parentView:onMoveClickCallBack(sender)
    end
end

return BlackFridayShopItem