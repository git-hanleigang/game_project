---
--xcyy
--2018年5月23日
--RobinIsHoodShopView.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local SendDataManager = require "network.SendDataManager"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local RobinIsHoodShopView = class("RobinIsHoodShopView",util_require("Levels.BaseLevelDialog"))

RobinIsHoodShopView.m_featureData = nil --网络消息返回的数据

local BTN_TAG_CLOSE         =       9999
local BTN_TAG_LEFT          =       1001
local BTN_TAG_RIGHT         =       1002
local BTN_TAG_TIP           =       1003
local BTN_TAG_HIDE_ITEM_TIP =       1004    --隐藏道具不能购买提示

-- 构造函数
function RobinIsHoodShopView:ctor(params)
    RobinIsHoodShopView.super.ctor(self,params)
    self.m_featureData = SpinFeatureData.new()
end

function RobinIsHoodShopView:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("RobinIsHood/ShopRobinIsHood.csb")

    self.m_clickItems = {}
    --页签
    self.m_tab_items = {}
    for index = 1,5 do
        local item = util_createAnimation("RobinIsHood_shop_collect_yezi.csb")
        self:findChild("Node_collect_yezi"..index):addChild(item)
        self.m_tab_items[index] = item
    end

    --提示按钮
    self.m_tip_btn = util_createAnimation("RobinIsHood_shop_i.csb")
    self:findChild("Node_i"):addChild(self.m_tip_btn)
    self:addClick(self.m_tip_btn:findChild("Button_1"))
    self.m_tip_btn:findChild("Button_1"):setTag(BTN_TAG_TIP)

    --提示
    self.m_tip_csb = util_createAnimation("RobinIsHood_shop_i_tips.csb")
    self.m_tip_btn:findChild("Node_tips"):addChild(self.m_tip_csb)
    self.m_tip_csb:setVisible(false)

    --提示信息
    self.m_tip_message = util_createAnimation("RobinIsHood_shop_message.csb")
    self:findChild("Node_message"):addChild(self.m_tip_message)

    --金币条
    self.m_coins_bar = util_createView("CodeRobinIsHoodSrc.RobinIsHoodShop.RobinIsHoodShopCoins",{machine = self.m_machine,shopView = self})
    self:findChild("Node_pricediscount"):addChild(self.m_coins_bar)

    --左翻页按钮
    self.m_leftBtn = self:findChild("btn_Left")
    self.m_leftBtn:setTag(BTN_TAG_LEFT)
    --右翻页按钮
    self.m_rightBtn = self:findChild("btn_Right")
    self.m_rightBtn:setTag(BTN_TAG_RIGHT)
    --关闭按钮
    self.m_closeBtn = self:findChild("btn_back")
    self.m_closeBtn:setTag(BTN_TAG_CLOSE)

    --隐藏不能购买提示按钮
    self.m_panel_hide_tip = self:findChild("Panel_tip")
    self.m_panel_hide_tip:setTag(BTN_TAG_HIDE_ITEM_TIP)
    self:addClick(self.m_panel_hide_tip)
    self.m_panel_hide_tip:setVisible(false)

    --提示
    self.m_tip_cannot_buy = util_createAnimation("RobinIsHood_shop_main_message.csb")
    self.m_panel_hide_tip:addChild(self.m_tip_cannot_buy)
    self.m_tip_cannot_buy:setVisible(false)

    --内容界面
    self.m_contentNode = self:findChild("Panel_content")
    self.m_pageSize = self.m_contentNode:getContentSize()

    local pageParams = {
        machine = self.m_machine,
        shopView = self,
        pageSize = self.m_pageSize
    }
    --当前页面节点
    self.m_curPageNode = util_createView("CodeRobinIsHoodSrc.RobinIsHoodShop.RobinIsHoodShopPageView",pageParams)
    self.m_contentNode:addChild(self.m_curPageNode)
    self.m_curPageNode:setPosition(cc.p(0,0))

    --下一页面节点
    self.m_nextPageNode = util_createView("CodeRobinIsHoodSrc.RobinIsHoodShop.RobinIsHoodShopPageView",pageParams)
    self.m_contentNode:addChild(self.m_nextPageNode)
    self.m_nextPageNode:setPosition(cc.p(self.m_pageSize.width + 70,0))

    util_setCascadeOpacityEnabledRescursion(self, true)

    self.m_curPageIndex = 1

    self.m_clickEnabled = true
    self.m_clickTipEnabled = true
end

function RobinIsHoodShopView:onEnter()
    RobinIsHoodShopView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(self, params)
        self:featureResultCallFun(params)
    end,
    ViewEventType.NOTIFY_GET_SPINRESULT)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function RobinIsHoodShopView:initSpineUI()
    
end

--[[
    重置界面显示
]]
function RobinIsHoodShopView:resetPageShow(pageIndex)
    local shopData = self.m_machine.m_shopData
    local finished = shopData.finished
    if pageIndex then
        self.m_curPageIndex = pageIndex
    else
        for index = 1,#finished do
            if finished[index] then
                self.m_curPageIndex = index
            else
                break
            end
        end
    end
    

    --购买记录
    local shop = shopData.shopCoins
    --商品价格
    local cost = shopData.cost

    --是否免费
    local extraPick = shopData.extraPick
    local isFree = false
    if extraPick and extraPick[self.m_curPageIndex] then
        isFree = true
    end

    --设置页面位置
    self.m_curPageNode:setPosition(cc.p(0,0))
    self.m_nextPageNode:setPosition(cc.p(self.m_pageSize.width + 70,0))
    self.m_curPageNode:updateView(shop[self.m_curPageIndex],cost[self.m_curPageIndex],self.m_curPageIndex,finished[self.m_curPageIndex],isFree)

    self:updateTabItem()
end

--[[
    刷新当前页显示
]]
function RobinIsHoodShopView:updateCurPageView()
    local shopData = self.m_machine.m_shopData
    local finished = shopData.finished

    --购买记录
    local shop = shopData.shopCoins
    --商品价格
    local cost = shopData.cost

    --是否免费
    local extraPick = shopData.extraPick
    local isFree = false
    if extraPick and extraPick[self.m_curPageIndex] then
        isFree = true
    end
    self.m_curPageNode:updateView(shop[self.m_curPageIndex],cost[self.m_curPageIndex],self.m_curPageIndex,finished[self.m_curPageIndex],isFree)
end

--[[
    刷新页签
]]
function RobinIsHoodShopView:updateTabItem()
    for index = 1,5 do
        local item = self.m_tab_items[index]
        item:findChild("full"):setVisible(index == self.m_curPageIndex)

        local panel_click = item:findChild("panel_click")
        self:addClick(panel_click)
        panel_click:setTag(index)

        self.m_tip_message:findChild("Node_"..index):setVisible(index == self.m_curPageIndex)
        self.m_tip_csb:findChild("trigger_buju"..index):setVisible(index == self.m_curPageIndex)
    end
end

--[[
    显示界面
]]
function RobinIsHoodShopView:showView(pageIndex,func)
    self.m_machine:removeSoundHandler()
    self.m_clickEnabled = false
    self:setVisible(true)
    self:resetPageShow(pageIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_show_shop_view"])
    self:runCsbAction("start",false,function()
        self.m_clickEnabled = true
        self:runCsbAction("idle",true)
        if type(func) == "function" then
            func()
        end
        
    end)

    self.m_machine:delayCallBack(15 / 60,function()
        local Particle = self:findChild("Particle_1")
        if not tolua.isnull(Particle) then
            Particle:resetSystem()
        end
    end)
end

--[[
    隐藏界面
]]
function RobinIsHoodShopView:hideView(func)
    if self.m_tip_csb:isVisible() then
        self:clickTipBtn()
    end

    self.m_machine:reelsDownDelaySetMusicBGVolume()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_hide_shop_view)
    self.m_clickEnabled = false
    self:runCsbAction("over",false,function()
        self:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示不能购买提示
]]
function RobinIsHoodShopView:showTip(item)
    self.m_panel_hide_tip:setVisible(true)
    local pos = util_convertToNodeSpace(item.m_price_bar:findChild("Node_tip"),self.m_panel_hide_tip)
    self.m_tip_cannot_buy:setPosition(pos)
    self.m_tip_cannot_buy:findChild("dark_lock"):setVisible(item.m_isLock)
    self.m_tip_cannot_buy:findChild("only_dark"):setVisible(not item.m_isLock)
    self.m_tip_cannot_buy:setVisible(true)
    self.m_tip_cannot_buy:stopAllActions()
    self.m_tip_cannot_buy:runCsbAction("auto")
    performWithDelay(self.m_tip_cannot_buy,function()
        self.m_panel_hide_tip:setVisible(false)
        self.m_tip_cannot_buy:setVisible(false)
    end,360 / 60)
end

--[[
    隐藏不能购买提示
]]
function RobinIsHoodShopView:hideTip()
    if self.m_tip_cannot_buy:isVisible() and not self.m_tip_cannot_buy.m_isRunOver then
        self.m_tip_cannot_buy.m_isRunOver = true
        self.m_tip_cannot_buy:stopAllActions()
        self.m_tip_cannot_buy:runCsbAction("over")
        performWithDelay(self.m_tip_cannot_buy,function()
            self.m_panel_hide_tip:setVisible(false)
            self.m_tip_cannot_buy:setVisible(false)
            self.m_tip_cannot_buy.m_isRunOver = false
        end,30 / 60)
    end
end

--[[
    点击商品
]]
function RobinIsHoodShopView:clickItem(item)
    
    if item.m_isLock or not item:checkCoinsEnough() then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_click_shop_item)
        self:showTip(item)  
        return
    end

    if not self.m_clickEnabled then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_click_shop_item)
    self.m_clickEnabled = false
    item.m_isClicked = true
    self.m_clickItems[#self.m_clickItems + 1] = item
    self:sendData(item.m_itemID)
end

--默认按钮监听回调
function RobinIsHoodShopView:clickFunc(sender)
    if not self.m_clickEnabled then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_click)
    self:hideTip()
    local name = sender:getName()
    local tag = sender:getTag()
    if tag == BTN_TAG_CLOSE then
        self:hideView()
    elseif tag == BTN_TAG_LEFT then
        self:turnLeftPage()
    elseif tag == BTN_TAG_RIGHT then
        self:turnRightPage()
    elseif tag == BTN_TAG_TIP then
        self:clickTipBtn()
    elseif tag == BTN_TAG_HIDE_ITEM_TIP then
        
        
    elseif tag <= 5 then
        if self.m_curPageIndex ~= tag then
            self:turnPage(tag)
        end
    end
end

--[[
    翻页
]]
function RobinIsHoodShopView:turnPage(tarPage)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_turn_shop_page)
    --是否往左翻
    local isLeft = self.m_curPageIndex < tarPage
    if tarPage < 1 then
        tarPage = 5
        isLeft = false
    elseif tarPage > 5  then
        tarPage = 1
        
    end

    if self.m_tip_csb:isVisible() then
        self:clickTipBtn()
    end

    --屏蔽点击
    self.m_clickEnabled = false

    local shopData = self.m_machine.m_shopData
    --是否完成
    local finished = shopData.finished
    --购买记录
    local shop = shopData.shopCoins
    --商品价格
    local cost = shopData.cost

    --设置页面位置
    self.m_curPageNode:setPosition(cc.p(0,0))

    --往左翻
    if isLeft then
        self.m_nextPageNode:setPosition(cc.p(self.m_pageSize.width + 70,0))
        self.m_curPageNode:runAction(cc.MoveTo:create(0.2,cc.p(-(self.m_pageSize.width + 70),0)))
    else --往右翻

        --切换页面动作
        self.m_curPageNode:runAction(cc.MoveTo:create(0.2,cc.p(self.m_pageSize.width + 70,0)))
        self.m_nextPageNode:setPosition(cc.p(-(self.m_pageSize.width + 70),0))
    end

    
    self.m_curPageIndex  = tarPage
    
    --是否免费
    local extraPick = shopData.extraPick
    local isFree = false
    if extraPick and extraPick[self.m_curPageIndex] then
        isFree = true
    end
    
    self.m_nextPageNode:updateView(shop[self.m_curPageIndex],cost[self.m_curPageIndex],self.m_curPageIndex,finished[self.m_curPageIndex],isFree)

    
    local actionList = {
        cc.MoveTo:create(0.2,cc.p(0,0)),
        cc.CallFunc:create(function()
            --恢复可点击状态
            self.m_clickEnabled = true
            --交换指针
            local temp = self.m_curPageNode
            self.m_curPageNode = self.m_nextPageNode
            self.m_nextPageNode = temp
        end)
    }
    self.m_nextPageNode:runAction(cc.Sequence:create(actionList))

    self:updateTabItem()
end

--[[
    向左翻页
]]
function RobinIsHoodShopView:turnLeftPage()
    self:turnPage(self.m_curPageIndex - 1)
end

--[[
    向右翻页
]]
function RobinIsHoodShopView:turnRightPage()
    self:turnPage(self.m_curPageIndex + 1)
end

--[[
    点击提示按钮
]]
function RobinIsHoodShopView:clickTipBtn()
    if not self.m_clickTipEnabled then
        return
    end
    --屏蔽点击
    self.m_clickTipEnabled = false
    self.m_tip_csb:stopAllActions()

    if not self.m_tip_csb:isVisible() then
        --显示提示
        self.m_tip_csb:setVisible(true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_show_shop_tip)
        self.m_tip_csb:runCsbAction("auto",false)
        performWithDelay(self.m_tip_csb,function()
            self.m_clickTipEnabled = true
        end,30 / 60)
        performWithDelay(self.m_tip_csb,function()
            self.m_tip_csb:setVisible(false)
        end,360 / 60)
        
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_hide_shop_tip)
        self.m_tip_csb:runCsbAction("over",false)
        performWithDelay(self.m_tip_csb,function()
            self.m_tip_csb:setVisible(false)
            self.m_clickTipEnabled = true
        end,30 / 60)
    end
end


--[[
    显示解锁动画
]]
function RobinIsHoodShopView:updateLockView()
    local shopData = self.m_machine.m_shopData
    local finished = shopData.finished

    --购买记录
    local shop = shopData.shopCoins
    --商品价格
    local cost = shopData.cost

    self.m_curPageNode:updateView(shop[self.m_curPageIndex],cost[self.m_curPageIndex],self.m_curPageIndex,false,false)

end

function RobinIsHoodShopView:showUnlockAni(func)
    self.m_clickEnabled = false
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.firstRound then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_unlock_shop_item)
        self.m_curPageNode:runUnLockAni(function()
            self.m_clickEnabled = true
            if type(func) == "function" then
                func()
            end
        end)
    else
        self.m_clickEnabled = true
        if type(func) == "function" then
            func()
        end
    end
    
end

------------------------------------网络数据相关------------------------------------------------------------
--[[
    数据发送
]]
function RobinIsHoodShopView:sendData(clickPos)
    local data = {self.m_curPageIndex - 1, clickPos - 1}
    local messageData={msg=MessageDataType.MSG_BONUS_SPECIAL, choose = data,clickPos = clickPos - 1}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end


--[[
    解析返回的数据
]]
function RobinIsHoodShopView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        --防止其他类型消息传到这里
        if spinData.action == "SPECIAL" and self:isVisible() then
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            --bonus中需要带回status字段才会有最新钱数回来
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        end
    else
        gLobalViewManager:showReConnect(true)
    end
end

--[[
    网络消息返回
]]
function RobinIsHoodShopView:recvBaseData(featureData)
    local selfData = featureData.p_data.selfData
    self.m_machine:updateShopData(selfData)
    if selfData and selfData.lastBuy then
        self.m_machine.m_runSpinResultData.p_selfMakeData.lastBuy = selfData.lastBuy
    end
    
    local shopCoins = self.m_machine.m_shopData.shopCoins
    local pickResult = selfData.pickResult

    self.m_machine:updateDoublePickData(self.m_curPageIndex,pickResult)
    self.m_machine:setShopCoins(self.m_machine.m_shopData.coins)
    local isTriggerFs = self.m_machine:checkAddFsEffect(featureData.p_data)
    if isTriggerFs then
        self.m_machine.m_runSpinResultData.p_selfMakeData = selfData
        self.m_machine.m_runSpinResultData.p_fsExtraData = featureData.p_data.freespin.extra
        self.m_machine.m_runSpinResultData.p_avgBet = featureData.p_data.avgBet
    end

    if #self.m_clickItems > 0 then
        local item = self.m_clickItems[1]
        local clickPos = item.m_itemID
        local reward = shopCoins[self.m_curPageIndex][clickPos]
        local params = {
            reward = reward
        }
        item:showRewardAni(params,function()
            
            if params.reward == "extraPick" then
                self.m_curPageNode:switchToFreePrice()
            else
                self.m_curPageNode:switchToNormalPrize()
            end

            --触发了free
            if isTriggerFs then
                self.m_clickEnabled = false
                self:hideView(function()
                    self.m_machine:playGameEffect()
                end)
            else
                self.m_clickEnabled = true
            end
        end)

        if item:getCost() > self.m_machine.m_shopData.coins then
            self.m_curPageNode:showBlackAni()
        end

        table.remove(self.m_clickItems,1)
    end
    
end

------------------------------------网络数据相关  end------------------------------------------------------------


return RobinIsHoodShopView