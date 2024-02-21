local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local LinkFishBnousGameLayer = class("LinkFishBnousGameLayer", BaseGame)
-- 构造函数
LinkFishBnousGameLayer.m_currClickItem = nil
LinkFishBnousGameLayer.m_bsWinCoins = nil
LinkFishBnousGameLayer.m_bClickFlag = nil
LinkFishBnousGameLayer.m_jackpotID = nil
LinkFishBnousGameLayer.m_currItemID = nil
LinkFishBnousGameLayer.m_jackpotName = nil
LinkFishBnousGameLayer.m_vecChooseItems = nil
LinkFishBnousGameLayer.m_vecJpID = 
{
    Mini = 1,
    Minor = 2,
    Major = 3,
    Grand = 4
}

function LinkFishBnousGameLayer:initUI(data)
    local resourceFilename = "FortuneTree/BonusGame.csb"
    self:createCsbNode(resourceFilename)
    self.m_isBonusCollect = true
    self.m_vecItem = {}
    local itemTag = 1
    
    local index = 1
    while true do
        local node = self:findChild("Node_" .. index )
        if node ~= nil then
            local item = util_createView("CodeFortuneTreeSrc.FortuneTreeBnousGameItem", index)
            self.m_vecItem[index] = item
            item:setTag(itemTag)
            local func = function ()
                self:clickItemCallFunc(item)
            end
            item:setClickFunc(func)
            node:addChild(item)
            itemTag = itemTag + 1
        else
            break
        end
        index = index + 1
    end
    
    self.m_bClickFlag = false
    
    self.m_jackpotPos = data

    self.m_vecChooseItems = {}

    self:runCsbAction("idle")
end

function LinkFishBnousGameLayer:clickItemCallFunc(item)
    if self.m_bClickFlag == false then
        return 
    end
    gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_click_coin.mp3")
    self.m_bClickFlag = false
    self.m_currClickItem = item
    self.m_currItemID = item:getTag()
    self:sendData(self.m_currItemID)
end

function LinkFishBnousGameLayer:initViewData(callBackFun,mainClass)
    self.m_mainClass = mainClass
    self.m_callFunc=callBackFun

    local jackpotBar = util_createView("CodeFortuneTreeSrc.FortuneTreeJackpotBar")
    jackpotBar:initMachine(self.m_mainClass)
    self:findChild("Node_Jackpot_bonus"):addChild(jackpotBar)
    jackpotBar:setPositionY(jackpotBar:getPositionY() + self.m_jackpotPos)

    self:initItemStatus()
end

function LinkFishBnousGameLayer:resetView(featureData,callBackFun, mainClass)
    self.m_mainClass = mainClass
    self.m_callFunc=callBackFun
   
    local jackpotBar = util_createView("CodeFortuneTreeSrc.FortuneTreeJackpotBar")
    jackpotBar:initMachine(self.m_mainClass)
    self:findChild("Node_Jackpot_bonus"):addChild(jackpotBar)
    jackpotBar:setPositionY(jackpotBar:getPositionY() + self.m_jackpotPos)

    local vecCard = featureData.p_data.selfData.cards
    for i = 1, #vecCard, 1 do
        local card = vecCard[i]
        local item = self.m_vecItem[i]
        if card ~= "-1" then
            item:chooseIdle(self.m_vecJpID[card])
            if self.m_vecChooseItems[card] == nil then
                self.m_vecChooseItems[card] = {}
            end
            self.m_vecChooseItems[card][#self.m_vecChooseItems[card] + 1] = item
        else
            item:idle()
        end
        
    end
    
    self:initItemStatus()
    self:showTwice()
    self.m_bClickFlag = true
end

function LinkFishBnousGameLayer:appearAnimation()
    for i = 1, #self.m_vecItem do
        local item = self.m_vecItem[i]
        if i == #self.m_vecItem then
            item:appear(function()
                self.m_bClickFlag = true
            end)
        else
            item:appear()
        end
    end
    
end

function LinkFishBnousGameLayer:initItemStatus()
    self:findChild("root"):setScale(self.m_mainClass.m_machineRootScale)
end

function LinkFishBnousGameLayer:addPickTip()
    
end

--数据发送
function LinkFishBnousGameLayer:sendData(pos)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        
        messageData={msg = MessageDataType.MSG_BONUS_SELECT , data = pos } -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,true)
    
end

--默认按钮监听回调
function LinkFishBnousGameLayer:clickItem(func)
    self.m_currClickItem:click(self.m_jackpotID, function()
        self:clickCallBack()
    end, func)
    
end

function LinkFishBnousGameLayer:unclickItem(row)
    
end

function LinkFishBnousGameLayer:clickCallBack()
    if self.m_bGameOver ~= true then
        self.m_bClickFlag = true
    end
    self:showTwice()
end

function LinkFishBnousGameLayer:showTwice()
    local jackpot = nil
    for k, v in pairs(self.m_vecChooseItems) do
        if #v == 2 then
            jackpot = k
            for i = 1, #v, 1 do
                local item = v[i]
                -- performWithDelay(self, function()
                    item:twiceItem(self.m_vecJpID[k])
                -- end, 0.5)
            end
        end
    end
end

function LinkFishBnousGameLayer:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end
    
    self.p_chose = featureData.p_chose
    self.p_status = featureData.p_status

    
    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_totleWimnCoins, GameEffect.EFFECT_BONUS})

        local jackpot = nil
        for k, v in pairs(self.m_vecChooseItems) do
            if #v == 2 then
                jackpot = k
                for i = 1, #v, 1 do
                    local item = v[i]
                    performWithDelay(self, function()
                        item:chooseIdle(self.m_vecJpID[k])
                    end, 2)
                end
            end
        end
        for k, v in pairs(self.m_vecChooseItems) do
            if #v == 3 then
                jackpot = k
                for i = 1, #v, 1 do
                    local item = v[i]
                    performWithDelay(self, function()
                        item:getParent():setLocalZOrder(100)
                        item:overIdle(self.m_vecJpID[k])
                    end, 2)
                end
                break
            end
        end

        self:clickItem(function()
            self:runCsbAction("animation0", false, function()
                for i = 1, #self.m_vecItem do
                    local item = self.m_vecItem[i]
                    if item.m_bSelected ~= true then
                        local currJackpot = self.m_featureData.p_data.selfData.cards[i]
                        local index = self.m_vecJpID[currJackpot]
                        item:unclick(index)
                    end
                end
            end)
            performWithDelay(self, function()
                if self.m_callFunc ~= nil then
                    self.m_callFunc(self.m_totleWimnCoins, jackpot)
                end
            end, 3)
        end)
        self.m_bGameOver = true
    else
        self:clickItem()
    end
    
end

function LinkFishBnousGameLayer:sortNetData( data)
    -- 服务器非得用这种结构 只能本地转换一下结构
    local localdata = {}
    if data.bonus then
        if data.bonus then
            data.choose = data.bonus.choose
            data.content = data.bonus.content
            data.extra = data.bonus.extra
            data.status = data.bonus.status

        end
    end 


    localdata = data

    return localdata
end

function LinkFishBnousGameLayer:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            local data = self:sortNetData(spinData.result)
            self.m_featureData:parseFeatureData(data)    
            local currJackpot = self.m_featureData.p_data.selfData.cards[self.m_currItemID]
            self.m_jackpotID = self.m_vecJpID[currJackpot]
            if self.m_vecChooseItems[currJackpot] == nil then
                self.m_vecChooseItems[currJackpot] = {}
            end
            self.m_vecChooseItems[currJackpot][#self.m_vecChooseItems[currJackpot] + 1] = self.m_currClickItem
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

function LinkFishBnousGameLayer:onEnter()
    BaseGame.onEnter(self)
end

function LinkFishBnousGameLayer:onExit()
    scheduler.unschedulesByTargetName("LinkFish_BonusGame")
    BaseGame.onExit(self)
end

return LinkFishBnousGameLayer