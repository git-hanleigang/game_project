local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local LinkFishBnousGameLayer = class("LinkFishBnousGameLayer", BaseGame)
-- 构造函数
LinkFishBnousGameLayer.m_currClickItem = nil
LinkFishBnousGameLayer.m_currClickRow = nil
LinkFishBnousGameLayer.m_bsWinCoins = nil
LinkFishBnousGameLayer.m_bClickFlag = nil
LinkFishBnousGameLayer.m_extraGame = nil
LinkFishBnousGameLayer.m_bHaveNext = nil
function LinkFishBnousGameLayer:initUI(data)
    local resourceFilename = "LinkFish/BonusGame.csb"
    self:createCsbNode(resourceFilename)
    self.m_isBonusCollect=true
    self.m_vecItem = {}
    local itemTag = 1
    for i = 1, 3, 1 do
        local index = 1
        while true do
            local node = self:findChild("Node_" .. i .."_" .. index )
            if node ~= nil then
                local info = {}
                info.row = i
                info.levelID = data
                local item = util_createView("CodeLinkFishSrc.LinkFishBnousGameItem", info)
                if self.m_vecItem[i] == nil then
                    self.m_vecItem[i] = {}
                end
                self.m_vecItem[i][index] = item
                item:setTag(itemTag)
                local func = function ()
                    self:clickItemCallFunc(i,item:getTag())
                end
                item:setClickFunc(func)
                item:setClickFlag(false)
                node:addChild(item)
                itemTag = itemTag + 1
            else
                break
            end
            index = index + 1
        end
    end
    self.m_currClickRow = 1
    self.m_bClickFlag = false
    self:runCsbAction("star", false, function()
        self.m_bClickFlag = true
    end)
    self.m_levelID = data
end

function LinkFishBnousGameLayer:clickItemCallFunc(index , pos)
    if self.m_bClickFlag == false then
        return 
    end
    self.m_pickTip:setVisible(false)
    local vecItem = self.m_vecItem[index]
    for i = 1, #vecItem, 1 do
        local item = vecItem[i]
        if item:getTag() ~= pos then
            item:setClickFlag(false)
        else
            self.m_currClickItem = item
            self:sendData(pos)
        end
    end
end

function LinkFishBnousGameLayer:initViewData(callBackFun,mainClass)
    self.m_mainClass = mainClass
    self.m_callFunc=callBackFun
    self:initItemStatus()
end

function LinkFishBnousGameLayer:resetView(featureData,callBackFun, mainClass)
    self.m_mainClass = mainClass
    self.m_callFunc=callBackFun

    local choose = featureData.p_chose
    for i = 1, #choose, 1 do
        local index = choose[i]
        local vecItem = self.m_vecItem[i]
        local rewardID = 1
        local otherReward = featureData.p_extra.otherOption[i]
        for j = 1, #vecItem, 1 do
            local item = vecItem[j]
            item:setClickFlag(false)
            if item:getTag() == index then
                if featureData.p_contents[i] == "game" then
                    item:showSelected(0)
                    self.m_extraGame = true
                else
                    item:showSelected(featureData.p_contents[i])
                end
                
            else
                if otherReward ~= nil then
                    item:unselected(otherReward[rewardID])
                    rewardID = rewardID + 1
                end
            end
        end
    end
    if choose and #choose > 0 then
        self.m_currClickRow = #choose + 1
    end
    if self.m_currClickRow > 3 then
        self.m_currClickRow = 3
    end
    self:initItemStatus()
end

function LinkFishBnousGameLayer:initItemStatus()
    local vecItem = self.m_vecItem[self.m_currClickRow]
    for i = 1, #vecItem, 1 do
        local item = vecItem[i]
        item:setClickFlag(true)
        item:idle()
    end
    for i = self.m_currClickRow + 1, 3, 1 do
        local vecItem = self.m_vecItem[i]
        for j = 1, #vecItem, 1 do
            local item = vecItem[j]
            item:setClickFlag(false)
            item:canNotClick()
        end
    end
    self:addPickTip()
end

function LinkFishBnousGameLayer:addPickTip()
    local node = self:findChild("click_tip_"..self.m_currClickRow)
    if self.m_pickTip == nil then
        local pick, act = util_csbCreate("LinkFish_game_pickone.csb")
        util_csbPlayForKey(act, "actionframe", true)
        self.m_pickTip = pick
        node:getParent():addChild(self.m_pickTip)
    end
    self.m_pickTip:setVisible(true)
    self.m_pickTip:setPosition(node:getPositionX(), node:getPositionY())
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
    self.m_currClickItem:click(self.m_serverWinCoins, function()
        self:clickCallBack()
    end, func)
    
end

function LinkFishBnousGameLayer:unclickItem(row)
    local vecItem = self.m_vecItem[row]
    local index = 1
    local otherReward = self.m_featureData.p_extra.otherOption[row]
    for i = 1, #vecItem, 1 do
        local item = vecItem[i]
        if item:getTag() ~= self.m_currClickItem:getTag() and item:getIsSelected() ~= true then
            item:unclick(otherReward[index])
            index = index + 1
        end
    end
end

function LinkFishBnousGameLayer:clickCallBack()
    self.m_currClickRow = self.m_currClickRow + 1
    if self.m_currClickRow > 3 then
        self.m_currClickRow = 3
        if self.m_bHaveNext == true then
            self.m_bHaveNext = false
            self:addPickTip()
            local vecItem = self.m_vecItem[3]
            for i = 1, #vecItem, 1 do
                local item = vecItem[i]
                if item:getTag() ~= self.m_currClickItem:getTag() then
                    item:setClickFlag(true)
                end
            end
        else
            self:unclickItem(self.m_currClickRow)
        end
    else
        self:unclickItem(self.m_currClickRow - 1)
        performWithDelay(self, function()
            self:initItemStatus()
        end, 0.8)
        
    end
end

function LinkFishBnousGameLayer:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end

    if featureData.p_data.respin and featureData.p_data.respin.extra then
        self.m_mainClass.m_runSpinResultData.p_rsExtraData = featureData.p_data.respin.extra
    end
    
    self.p_chose = featureData.p_chose
    self.p_status = featureData.p_status

    
    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_bsWinCoins, GameEffect.EFFECT_BONUS})

        self:clickItem(function()
            if self.m_callFunc ~= nil then
                self.m_callFunc(self.m_bsWinCoins, self.m_extraGame)
            end
        end)
    else
        self:clickItem()
        if self.m_currClickRow == 3 then
            self.m_bHaveNext = true
        end
        
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
            self.m_bsWinCoins = data.bonus.bsWinCoins
            if self.m_featureData.p_contents[#self.m_featureData.p_contents] == "game" then
                self.m_mainClass:updateMapData(data.bonus.extra.map)
                self.m_extraGame = true
            end
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