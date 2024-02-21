---
--xcyy
--2018年5月23日
--SpookySnacksShopItem.lua
local PublicConfig = require "SpookySnacksPublicConfig"
local SpookySnacksShopItem = class("SpookySnacksShopItem",util_require("Levels.BaseLevelDialog"))

function SpookySnacksShopItem:initUI(params)
    self.m_parentView = params.parent
    self.m_index = params.index
    self:createCsbNode("SpookySnacks_shop_shangpin.csb")

    --价格
    self.m_priceNode = util_createAnimation("SpookySnacks_shop_shangpin_jine.csb")
    self:findChild("Node_jine"):addChild(self.m_priceNode)

    self.buyGoodTips = util_createAnimation("SpookySnacks_shop_shangpin_good.csb")      --未解锁
    self.m_priceNode:findChild("Node_buygood"):addChild(self.buyGoodTips)
    self.buyGoodTips:setVisible(false)

    self.donotBuyTips = util_createAnimation("SpookySnacks_shop_shangpin_moresign_0.csb")      --金币不足
    self.m_priceNode:findChild("Node_buygood"):addChild(self.donotBuyTips)
    self.donotBuyTips:setVisible(false)

    --价格（折扣）
    local zheKouMes = util_createAnimation("SpookySnacks_shop_shangpin_zhekou.csb")
    self.m_priceNode:findChild("Node_zhekou"):addChild(zheKouMes)
    zheKouMes:setVisible(false)
    self.m_priceNode.zheKouMes = zheKouMes

    --价格（折扣前）
    local zheKouBefore = util_createAnimation("SpookySnacks_shop_shangpin_zhekouqian.csb")
    self.m_priceNode:findChild("Node_zhekou_qianshu"):addChild(zheKouBefore)
    zheKouBefore:setVisible(false)
    self.m_priceNode.zheKouBefore = zheKouBefore

    self.shangpiiSpine1 = util_spineCreate("SpookySnacks_shop_shangpin1", true, true)
    self:findChild("Node_spine1"):addChild(self.shangpiiSpine1)
    util_spinePlay(self.shangpiiSpine1, "idle",true)
    self.shangpiiSpine1.m_actName = "idle"
    self.shangpiiSpine2 = util_spineCreate("SpookySnacks_shop_shangpin2", true, true)
    self:findChild("Node_spine2"):addChild(self.shangpiiSpine2)
    util_spinePlay(self.shangpiiSpine2, "idle",true)
    self.shangpiiSpine2.m_actName = "idle"
    self.shangpiiSpine3 = util_spineCreate("SpookySnacks_shop_shangpin3", true, true)
    self:findChild("Node_spine3"):addChild(self.shangpiiSpine3)
    util_spinePlay(self.shangpiiSpine3, "idle",true)
    self.shangpiiSpine3.m_actName = "idle"

    -- 赢钱
    self.m_winCoinsNode = util_createAnimation("SpookySnacks_shop_shangpin_jiangli.csb")
    self:findChild("Node_number"):addChild(self.m_winCoinsNode)

    self.lockAct = util_createAnimation("SpookySnacks_shop_shangpin_suoding.csb")
    self:findChild("Node_suoding"):addChild(self.lockAct)

    --创建点击区域
    self:addClick(self:findChild("Panel_2"))

    -- self:playItemIdle()
    print("index =" ..self.m_index)
    local row = self:getItemRowForIndex(self.m_index)
    self:findChild("Node_3"):setVisible(row == 2)
    self:findChild("Node_2"):setVisible(row == 3)
    self:findChild("Node_1"):setVisible(row == 1)
end

function SpookySnacksShopItem:getItemRowForIndex()
    if self.m_index >= 1 and self.m_index <= 3 then
        return 1
    elseif self.m_index >= 4 and self.m_index <= 6 then
        return 2
    else
        return 3
    end
end

--[[
    物品是否播放idle
]]
function SpookySnacksShopItem:playItemIdle()
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
function SpookySnacksShopItem:setLockStatus(_isLock, _isSelected)

    if _isLock then
        self.lockAct:runCsbAction("idle")
    else
        if _isSelected then
            self.lockAct:runCsbAction("unLockIdle")
        else
            self.lockAct:runCsbAction("unLockIdle")
        end
        
    end
    
end

--[[
    设置金币不足状态
]]
function SpookySnacksShopItem:setCoinEnoughStatus(_isCoinEnough)
    if  not _isCoinEnough then
        if self.shangpiiSpine1.m_actName == "idle" then
            util_spinePlay(self.shangpiiSpine1, "dark",false)
            util_spineEndCallFunc(self.shangpiiSpine1, "dark", function ()
                util_spinePlay(self.shangpiiSpine1, "idle2",true)
                self.shangpiiSpine1.m_actName = "idle2"
            end)
        end
        if self.shangpiiSpine2.m_actName == "idle" then
            util_spinePlay(self.shangpiiSpine2, "dark",false)
            util_spineEndCallFunc(self.shangpiiSpine2, "dark", function ()
                util_spinePlay(self.shangpiiSpine2, "idle2",true)
                self.shangpiiSpine2.m_actName = "idle2"
            end)
        end
        
        
        if self.shangpiiSpine3.m_actName == "idle" then
            util_spinePlay(self.shangpiiSpine3, "dark",false)
            util_spineEndCallFunc(self.shangpiiSpine3, "dark", function ()
                util_spinePlay(self.shangpiiSpine3, "idle2",true)
                self.shangpiiSpine3.m_actName = "idle2"
            end)
        end
        
        
    else
        if self.shangpiiSpine1.m_actName == "idle2" then
            util_spinePlay(self.shangpiiSpine1, "idle",true)
            self.shangpiiSpine1.m_actName = "idle"
        end
        if self.shangpiiSpine2.m_actName == "idle2" then
            util_spinePlay(self.shangpiiSpine2, "idle",true)
            self.shangpiiSpine2.m_actName = "idle"
        end
        if self.shangpiiSpine3.m_actName == "idle2" then
            util_spinePlay(self.shangpiiSpine3, "idle",true)
            self.shangpiiSpine3.m_actName = "idle"
        end

    end
    
    -- -- if _isCoinEnough then
    --     self.m_priceNode:findChild("zhezhao"):setVisible(false)
    --     self.m_priceNode:findChild("zhezhao1"):setVisible(false)
    -- -- else
    -- --     self.m_priceNode:findChild("zhezhao"):setVisible(true)
    -- --     self.m_priceNode:findChild("zhezhao1"):setVisible(true)
    -- -- end
    
end

--[[
    刷新商品UI
]]
function SpookySnacksShopItem:refreshUI(_data, _isSuperFreeBack, _isPlaySound)
    --价格
    local price = _data.cost[self.m_index]
    
    if self.m_parentView.m_isZheKou then
        if _data.extraPick[self.m_parentView.m_curPageIndex] and _data.extraPickPos and _data.extraPickPos[self.m_parentView.m_curPageIndex] and
        _data.extraPickPos[self.m_parentView.m_curPageIndex][1] and (self.m_parentView.m_curPageIndex == (_data.extraPickPos[self.m_parentView.m_curPageIndex][1]+1)) then
            self.m_priceNode:findChild("m_lb_coins2"):setVisible(false)
            self.m_priceNode:findChild("m_lb_coins"):setVisible(false)
        else
            self.m_priceNode:findChild("m_lb_coins2"):setVisible(true)
            self.m_priceNode:findChild("m_lb_coins"):setVisible(false)
        end
        
        -- 折扣价
        self.m_priceNode:findChild("Node_2_zhekou"):setVisible(true)
        self.m_priceNode:findChild("Node_1"):setVisible(false)
        self.m_priceNode:findChild("m_lb_coins2"):setString(util_formatCoins(price*0.7, 8))
        self:updateLabelSize({label=self.m_priceNode:findChild("m_lb_coins2"),sx=0.65,sy=0.65},135)

        -- 原件
        
        self.m_priceNode:findChild("m_lb_coins"):setString(util_formatCoins(price,8))
        self:updateLabelSize({label=self.m_priceNode:findChild("m_lb_coins"),sx=0.5,sy=0.5},135)
        
    else
        if _data.extraPick[self.m_parentView.m_curPageIndex] and _data.extraPickPos and _data.extraPickPos[self.m_parentView.m_curPageIndex] and
        _data.extraPickPos[self.m_parentView.m_curPageIndex][1] and (self.m_parentView.m_curPageIndex == (_data.extraPickPos[self.m_parentView.m_curPageIndex][1]+1)) then
            self.m_priceNode:findChild("m_lb_coins2"):setVisible(false)
            self.m_priceNode:findChild("m_lb_coins"):setVisible(false)
        else
            self.m_priceNode:findChild("m_lb_coins2"):setVisible(false)
            self.m_priceNode:findChild("m_lb_coins"):setVisible(true)
        end
        
        self.m_priceNode:findChild("Node_2_zhekou"):setVisible(false)
        self.m_priceNode:findChild("Node_1"):setVisible(true)
        self.m_priceNode:findChild("m_lb_coins"):setString(util_formatCoins(price,8))
        self:updateLabelSize({label=self.m_priceNode:findChild("m_lb_coins"),sx=0.65,sy=0.65},135)
    end
    
    --金币是否充足
    self.m_isCoinEnough = _data.coins >= price
    if self.m_parentView.m_isZheKou then
        self.m_isCoinEnough = _data.coins >= (price*0.7)
    end
    if _data.extraPick[self.m_parentView.m_curPageIndex] and _data.extraPickPos and _data.extraPickPos[self.m_parentView.m_curPageIndex] and
    _data.extraPickPos[self.m_parentView.m_curPageIndex][1] and (self.m_parentView.m_curPageIndex == (_data.extraPickPos[self.m_parentView.m_curPageIndex][1]+1)) then
        self.m_isCoinEnough = true
    end

    self.m_isLocked = _data.isLocked
    if _isSuperFreeBack then
        self.m_isLocked = false
    end
    self.m_isSelected = _data.shop[self.m_index] ~= 0
    

    
    
    if _isSuperFreeBack then
        self.m_winCoinsNode:setVisible(false)
        performWithDelay(self.lockAct,function ()
            self.lockAct:runCsbAction("unlock",false,function ()
                self.m_isLocked = _data.isLocked
                self.lockAct:runCsbAction("unLockIdle",true)
            end)
        end,0.5)
        if self.m_parentView.m_isZheKou then
            self.m_priceNode:runCsbAction("idle",true) 
        else
            self.m_priceNode:runCsbAction("idle",true) 
            -- self.m_winCoinsNode:setVisible(false)
        end
    else
        self:setLockStatus(_data.isLocked,self.m_isSelected)
        if not _data.isLocked then      --没锁定

            if self.m_isSelected then
                self:updateReward(_data.shopCoins[self.m_index],nil,nil,nil,_data)
            else
                if not self.m_isCoinEnough then
                    self:setCoinEnoughStatus(self.m_isCoinEnough)
                    self:showWinCoinsAndPrice(_data)
                else
                    self:showWinCoinsAndPrice(_data)
                end
            end
        else
            self:showWinCoinsAndPrice(_data)
        end
    end
end

-- 显示购买之后的 赢钱 和 价格
function SpookySnacksShopItem:showWinCoinsAndPrice(_data)
    self.m_winCoinsNode:setVisible(false)
    self:runCsbAction("idle1",false)
    -- 免费 不管有没有折扣 都显示成 free
    -- if _data.extraPick[self.m_parentView.m_curPageIndex] and _data.extraPickPos and _data.extraPickPos[self.m_parentView.m_curPageIndex] and
    -- _data.extraPickPos[self.m_parentView.m_curPageIndex][1] and (self.m_parentView.m_curPageIndex == (_data.extraPickPos[self.m_parentView.m_curPageIndex][1]+1)) then
    --     -- self.m_priceNode:runCsbAction("idle1",true) 
    --     -- self.m_priceNode:findChild("Node_free"):setVisible(false)
    -- else
        if self.m_parentView.m_isZheKou then
            self.m_priceNode:runCsbAction("idle",true) 
        else
            self.m_priceNode:runCsbAction("idle",true) 
        end
    -- end
end

--[[
    刷新价格UI
]]
function SpookySnacksShopItem:refreshUIPrice(_data, _isComeIn)

    --价格
    local price = _data.cost[self.m_index]
    --金币是否充足
    self.m_isCoinEnough = _data.coins >= price
    if self.m_parentView.m_isZheKou then
        self.m_isCoinEnough = _data.coins >= (price*0.7)
    end
    
    if _data.extraPick[self.m_parentView.m_curPageIndex] and _data.extraPickPos and _data.extraPickPos[self.m_parentView.m_curPageIndex] and
    _data.extraPickPos[self.m_parentView.m_curPageIndex][1] and (self.m_parentView.m_curPageIndex == (_data.extraPickPos[self.m_parentView.m_curPageIndex][1]+1)) then
        self.m_isCoinEnough = true
    end

    self.m_isSelected = _data.shop[self.m_index] ~= 0
    
    
    self:setCoinEnoughStatus(self.m_isCoinEnough)
    
    --当前购买 免费
    if _data.extraPick[self.m_parentView.m_curPageIndex] and _data.extraPickPos and _data.extraPickPos[self.m_parentView.m_curPageIndex] and
    _data.extraPickPos[self.m_parentView.m_curPageIndex][1] and (self.m_parentView.m_curPageIndex == (_data.extraPickPos[self.m_parentView.m_curPageIndex][1]+1)) then
        if self.m_isSelected then
            if self.m_priceNode:findChild("Node_free"):isVisible() then
                self:runCsbAction("over",false,function ()
                    self.m_priceNode:findChild("Node_free"):setVisible(false)
                end)
            else
                self.m_priceNode:findChild("Node_free"):setVisible(false)
            end
            
            self.m_priceNode:runCsbAction("idle2",false)
            if not self.m_priceNode.zheKouMes:isVisible() then
                self.m_priceNode.zheKouMes:setVisible(true)
                self.m_priceNode.zheKouMes:runCsbAction("start",false,function ()
                    self.m_priceNode.zheKouMes:runCsbAction("idle")
                end)
            end
            if not self.m_priceNode.zheKouBefore:isVisible() then
                self.m_priceNode.zheKouBefore:setVisible(true)
                self.m_priceNode.zheKouBefore:runCsbAction("start",false,function ()
                    self.m_priceNode.zheKouBefore:runCsbAction("idle")
                end)
            end
            
        else
            self.m_priceNode:runCsbAction("idle",true) 
            if not self.m_priceNode:findChild("Node_free"):isVisible() then
                self:runCsbAction("start",false,function ()
                    self.m_priceNode:findChild("Node_free"):setVisible(true)
                    self:runCsbAction("idle3")
                end)
            else
                self.m_priceNode:findChild("Node_free"):setVisible(true)
            end
            
            self.m_priceNode:findChild("m_lb_coins2"):setVisible(false)
            self.m_priceNode:findChild("m_lb_coins"):setVisible(false)
            if self.m_priceNode.zheKouMes:isVisible() then
                self.m_priceNode.zheKouMes:runCsbAction("over",false,function ()
                    self.m_priceNode.zheKouMes:setVisible(false)
                end)
            end
            if self.m_priceNode.zheKouBefore:isVisible() then
                self.m_priceNode.zheKouBefore:runCsbAction("over",false,function ()
                    self.m_priceNode.zheKouBefore:setVisible(false)
                end)
            end
            
        end 
    else
        -- 不免费
        self.m_priceNode:findChild("Node_free"):setVisible(false)
        if self.m_parentView.m_isZheKou then
            -- 折扣价
            self.m_priceNode:findChild("m_lb_coins2"):setVisible(true)
            self.m_priceNode:findChild("m_lb_coins"):setVisible(false)
            self.m_priceNode:findChild("Node_2_zhekou"):setVisible(true)
            self.m_priceNode:findChild("Node_1"):setVisible(false)
            self.m_priceNode:findChild("m_lb_coins2"):setString(util_formatCoins(price*0.7, 8))
            self:updateLabelSize({label=self.m_priceNode:findChild("m_lb_coins2"),sx=0.65,sy=0.65},135)
            if not self.m_priceNode.zheKouMes:isVisible() then
                self.m_priceNode.zheKouMes:setVisible(true)
                self.m_priceNode.zheKouMes:runCsbAction("start",false,function ()
                    self.m_priceNode.zheKouMes:runCsbAction("idle")
                end)
            end
            if not self.m_priceNode.zheKouBefore:isVisible() then
                self.m_priceNode.zheKouBefore:setVisible(true)
                self.m_priceNode.zheKouBefore:runCsbAction("start",false,function ()
                    self.m_priceNode.zheKouBefore:runCsbAction("idle")
                end)
            end
            
            self.m_priceNode.zheKouBefore:findChild("m_lb_coins"):setString(util_formatCoins(price,8))
            
            -- 原件
            self.m_priceNode:findChild("m_lb_coins"):setString(util_formatCoins(price,8))
            self:updateLabelSize({label=self.m_priceNode:findChild("m_lb_coins"),sx=0.5,sy=0.5},135)
        else
            self.m_priceNode:findChild("m_lb_coins2"):setVisible(false)
            self.m_priceNode:findChild("m_lb_coins"):setVisible(true)
            self.m_priceNode:findChild("Node_2_zhekou"):setVisible(false)
            self.m_priceNode:findChild("Node_1"):setVisible(true)
            self.m_priceNode:findChild("m_lb_coins"):setString(util_formatCoins(price,8))
            self:updateLabelSize({label=self.m_priceNode:findChild("m_lb_coins"),sx=0.65,sy=0.65},135)
            if self.m_priceNode.zheKouMes:isVisible() then
                self.m_priceNode.zheKouMes:runCsbAction("over",false,function ()
                    self.m_priceNode.zheKouMes:setVisible(false)
                end)
            end
            if self.m_priceNode.zheKouBefore:isVisible() then
                self.m_priceNode.zheKouBefore:runCsbAction("over",false,function ()
                    self.m_priceNode.zheKouBefore:setVisible(false)
                end)
            end
        end
        -- 有折扣
        if self.m_parentView.m_isZheKou then
            if not self.m_isSelected then
                self.m_priceNode:runCsbAction("idle",true) 
            else
                self.m_priceNode:runCsbAction("idle2",true) 
            end
        else
            -- 没有买过
            if not self.m_isSelected then
                self.m_priceNode:runCsbAction("idle",true) 
            end
            
        end
    end
end

--[[
    刷新点开的奖励
]]
function SpookySnacksShopItem:updateReward(_reward, _isPlayEffect, _func, _isChengBei, _data)
    if tostring(_reward) == "extraPick" then
        self.m_winCoinsNode:findChild("Node_coin"):setVisible(false)
        self.m_winCoinsNode:findChild("Node_2X"):setVisible(true)
        
    else
        self.m_winCoinsNode:findChild("m_lb_coins"):setString(util_formatCoins(_reward,3))
        self:updateLabelSize({label=self.m_winCoinsNode:findChild("m_lb_coins"),sx=1,sy=1},125)
        self.m_winCoinsNode:findChild("Node_coin"):setVisible(true)
        self.m_winCoinsNode:findChild("Node_2X"):setVisible(false)
    end

    self.m_winCoinsNode:setVisible(true)
    if _isPlayEffect then
        -- self.m_winCoinsNode:setVisible(false)
        
        self.m_isClick = true
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_shopItem_click)
        self:runCsbAction("actionframe",false)
        local aniTime = 40/60
        
        self.m_priceNode:runCsbAction("actionframe",false,function ()
            if self.m_parentView.m_isZheKou then
                if self.m_priceNode:findChild("Node_free"):isVisible() then
                    self:runCsbAction("over",false,function ()
                        self.m_priceNode:findChild("Node_free"):setVisible(false)
                    end)
                    
                end
            else
                if self.m_priceNode:findChild("Node_free"):isVisible() then
                    self:runCsbAction("over",false,function ()
                        self.m_priceNode:findChild("Node_free"):setVisible(false)
                    end)
                end
            end 
            self.m_priceNode:runCsbAction("idle2",true)
            if tostring(_reward) == "extraPick" then
                self.m_winCoinsNode:runCsbAction("idle",true)
            else
                -- self.m_winCoinsNode:runCsbAction("idle",false)
            end
        end)

        performWithDelay(self,function ()
            if _func then
                _func()
            end
        end,aniTime + 0.5)
        
    else
        --当前购买 免费
        if _data and _data.extraPick[self.m_parentView.m_curPageIndex] and _data.extraPickPos and _data.extraPickPos[self.m_parentView.m_curPageIndex] and
            _data.extraPickPos[self.m_parentView.m_curPageIndex][1] and (self.m_parentView.m_curPageIndex == (_data.extraPickPos[self.m_parentView.m_curPageIndex][1]+1)) then

            if tostring(_reward) == "extraPick" then
                self.m_winCoinsNode:runCsbAction("idle",true)
            else
                -- self.m_winCoinsNode:runCsbAction("idle",false)
            end
        else
            -- self.m_winCoinsNode:runCsbAction("idle",false)
        end
        
        self.m_priceNode:runCsbAction("idle2",false) 
        self:runCsbAction("idle",false) 

        if _func then
            _func()
        end
    end
end


--默认按钮监听回调 滑动
function SpookySnacksShopItem:clickEndFunc(sender)

    local name = sender:getName()
    local btnTag = sender:getTag()
    if self.m_parentView.m_isMoved then
        return
    end
    if name == "Panel_2" then
        if self.m_isSelected then
            --已经买过
            return
        elseif self.m_isLocked then
            --显示无法购买
            self:showTipsForNode(self.buyGoodTips) 
        elseif not self.m_isCoinEnough and not self.m_priceNode:findChild("Node_free"):isVisible() then
            --显示金币不足
            self:showTipsForNode(self.donotBuyTips)
        
        else
            
            --发送购买消息
            self.m_parentView:clickItem(self.m_index)
        end
    end
end

function SpookySnacksShopItem:showTipsForNode(tipsNode)
    if tipsNode:isVisible() then
        return
    end
    tipsNode:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_shop_coins_buzu)
    tipsNode:runCsbAction("start",false,function ()
        tipsNode:runCsbAction("idle")
    end)
    performWithDelay(tipsNode,function ()
        tipsNode:runCsbAction("over",false,function ()
            tipsNode:setVisible(false)
        end)
    end,1)
end

function SpookySnacksShopItem:hideTipsForNode()
    self.buyGoodTips:setVisible(false)
    -- if self.buyGoodTips:isVisible() then
    --     self.buyGoodTips:runCsbAction("over",false,function ()
    --         self.buyGoodTips:setVisible(false)
    --     end)
    -- else
    --     return
    -- end
end

function SpookySnacksShopItem:hideTipsForNode2()
    self.donotBuyTips:setVisible(false)
    -- if self.donotBuyTips:isVisible() then
    --     self.donotBuyTips:runCsbAction("over",false,function ()
    --         self.donotBuyTips:setVisible(false)
    --     end)
    -- else
    --     return
    -- end
end


return SpookySnacksShopItem