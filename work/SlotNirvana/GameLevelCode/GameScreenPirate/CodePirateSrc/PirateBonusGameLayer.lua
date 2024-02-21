local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PirateBonusGameLayer = class("PirateBonusGameLayer", BaseGame)
-- 构造函数
PirateBonusGameLayer.m_currClickItem = nil
PirateBonusGameLayer.m_currClickRow = nil
PirateBonusGameLayer.m_bsWinCoins = nil
PirateBonusGameLayer.m_bClickFlag = nil
PirateBonusGameLayer.m_extraGame = nil
PirateBonusGameLayer.m_bHaveNext = nil
PirateBonusGameLayer.m_curFeatureData = nil

PirateBonusGameLayer.REWARD_ICON_NAME = 
{
    "Pirate_qiandai_",
    "Pirate_mutong_",
    "Pirate_baoxiang_"
}

function PirateBonusGameLayer:initUI(levelId)
    local resourceFilename = "Pirate/BonusMiniGame.csb"
    self:createCsbNode(resourceFilename)
    self.m_isBonusCollect=true
    self.m_vecItem = {}
    self.m_resultItem = {}

    self.m_currClickRow = 1
    self.m_bClickFlag = false
    self:runCsbAction("star", false, function()
        self.m_bClickFlag = true
    end)
    self.m_levelID = levelId
    self:initItem()
end

function PirateBonusGameLayer:initItem()
    local roundIndex = 1
    if self.m_curFeatureData then
        roundIndex = #self.m_curFeatureData.p_extra.otherOption + 1 --
    end

    self.m_vecItem = {}
    for i = 1, 3, 1 do
        local index = 1
        if self.m_vecItem[i] == nil then
            self.m_vecItem[i] = {}
        end
        while true do
            local node = self:findChild(self.REWARD_ICON_NAME[i] .. index )
            if node ~= nil then
                local info = {}
                info.type = i
                info.levelID = self.m_levelID
                local item = util_createView("CodePirateSrc.PirateBonusGameItem", info)
                self.m_vecItem[i][index] = item
                item:setTag(index)
                local func = function ()
                    self:clickItemCallFunc(i, item:getTag())
                end
                item:setClickFunc(func)
                item:setClickFlag(false)
                local posX, posY = node:getPosition()
                self:findChild("root"):addChild(item)
                item:setPosition(posX,posY)
            else
                break
            end
            index = index + 1
        end
    end
end

function PirateBonusGameLayer:clickItemCallFunc(index, pos)
    
    if self.m_bClickFlag == false then
        return 
    end
    local vecItem = self.m_vecItem[index]
    for i = 1, #vecItem, 1 do
        local item = vecItem[i]
        item:setClickFlag(false)
        if item:getTag() == pos then
            self.m_currClickItem = item
            self:sendData(pos)
        end
    end
    -- if index == 1 then
    --     gLobalSoundManager:playSound("PirateSounds/sound_pirate_click_money.mp3")
    -- elseif index == 2 then
        gLobalSoundManager:playSound("PirateSounds/sound_pirate_click_tong.mp3")
    -- elseif index == 3 then
    --     gLobalSoundManager:playSound("PirateSounds/sound_pirate_click_box.mp3")
    -- end
end

function PirateBonusGameLayer:initViewData(callBackFun,mainClass)
    self.m_mainClass = mainClass
    self.m_callFunc=callBackFun
    self:initItemStatus()
    -- self:addPickTip()
end

function PirateBonusGameLayer:resetView(featureData, callBackFun, mainClass)
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
                    item:unclick(otherReward[rewardID])
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
    -- self:addPickTip()
end

function PirateBonusGameLayer:initItemStatus()
    
    local vecItem = self.m_vecItem[self.m_currClickRow]
    for i = 1, #vecItem, 1 do
        local item = vecItem[i]
        if item:getIsSelected() ~= true then
            item:setClickFlag(true)
            item:idle()
        end
    end
    for i = self.m_currClickRow + 1, 3, 1 do
        local vecItem = self.m_vecItem[i]
        for j = 1, #vecItem, 1 do
            local item = vecItem[j]
            item:setClickFlag(false)
            item:canNotClick()
        end
    end
    
end

function PirateBonusGameLayer:addPickTip(func)
    local node = self:findChild("pos_"..self.m_currClickRow)
    local pos = cc.p(node:getPositionX(), node:getPositionY())
    if self.m_pickTip == nil then
        local pick, act = util_csbCreate("Pirate_wanfa_jiantou.csb")
        -- util_csbPlayForKey(act, "actionframe", true)
        self.m_pickTip = pick
        node:getParent():addChild(self.m_pickTip)
        self.m_pickTip:setPosition(pos)
    else
        local move = cc.MoveTo:create(0.5, pos)
        self.m_pickTip:runAction(cc.Sequence:create(move, cc.CallFunc:create(function()
            if func ~= nil then
                func()
            end
        end)))
    end
end

--数据发送
function PirateBonusGameLayer:sendData(pos)
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
function PirateBonusGameLayer:clickItem(func)
    self.m_currClickRow = self.m_currClickRow + 1
    self.m_currClickItem:click(self.m_serverWinCoins, function()
        self:unselectCallBack()
    end, function()
        self:clickCallBack()
    end, func)
end

function PirateBonusGameLayer:unclickItem(row)
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

function PirateBonusGameLayer:unselectCallBack()
    if self.m_currClickRow > 3 then
        if self.m_bHaveNext ~= true then
            self:unclickItem(3)
        end
    else
        self:unclickItem(self.m_currClickRow - 1)
    end
end

function PirateBonusGameLayer:clickCallBack()
    if self.m_currClickRow > 3 then
        return
    elseif self.m_bHaveNext == true then
        self.m_bHaveNext = false
        -- self:addPickTip()
        local vecItem = self.m_vecItem[3]
        for i = 1, #vecItem, 1 do
            local item = vecItem[i]
            if item:getTag() ~= self.m_currClickItem:getTag() then
                item:setClickFlag(true)
            end
        end
    else
        performWithDelay(self, function()
            -- self:addPickTip(function()
                self:initItemStatus()
            -- end)
        end, 0.8)
        
    end
end

function PirateBonusGameLayer:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end
    self.m_curFeatureData = featureData
    local sumNum = #self.m_curFeatureData.p_chose
    --结果集发生变化
    if sumNum <= 3 then
        self.m_clickList ={}
    end
    -- performWithDelay(self,function()
    --     -- self.m_resultItem[1]:showCoins(self.m_curFeatureData.p_contents)
    -- end,1.3)

    self.m_currClickRow = #self.m_curFeatureData.p_extra.otherOption
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
        if self.m_currClickRow == 3 then
            self.m_bHaveNext = true
        end
        self:clickItem()
    end

end

function PirateBonusGameLayer:sortNetData( data)
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

function PirateBonusGameLayer:featureResultCallFun(param)
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
            self.m_curFeatureData = self.m_featureData
            self.m_bsWinCoins = data.bonus.bsWinCoins
            if self.m_curFeatureData.p_contents[#self.m_curFeatureData.p_contents] == "game" then
                self.m_mainClass:updateMapData(data.bonus.extra.map)
                self.m_extraGame = true
            end
            self:recvBaseData(self.m_curFeatureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self.m_curFeatureData = self.m_featureData
            self:recvBaseData(self.m_curFeatureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
        self.m_levelID = self.m_curFeatureData.p_extra.currPosition

    else
        -- 处理消息请求错误情况
    end
end

function PirateBonusGameLayer:onEnter()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    BaseGame.onEnter(self)
end

function PirateBonusGameLayer:onExit()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    scheduler.unschedulesByTargetName("Pirate_BonusGame")
    PirateBonusGameLayer.super.onExit(self)
end

return PirateBonusGameLayer