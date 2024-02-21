local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local GoldExpressBonusGameLayer = class("GoldExpressBonusGameLayer", BaseGame)
-- 构造函数
GoldExpressBonusGameLayer.m_currClickItem = nil
GoldExpressBonusGameLayer.m_currClickRow = nil
GoldExpressBonusGameLayer.m_bsWinCoins = nil
GoldExpressBonusGameLayer.m_bClickFlag = nil
GoldExpressBonusGameLayer.m_extraGame = nil
GoldExpressBonusGameLayer.m_bHaveNext = nil
GoldExpressBonusGameLayer.m_curFeatureData = nil

function GoldExpressBonusGameLayer:initUI(levelId,data)
    if data then
        self.m_curFeatureData = data
    end
    local resourceFilename = "GoldExpress/BonusGame.csb"
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
    self:initResultItem()
end
function GoldExpressBonusGameLayer:initResultItem()
    for i=1,2 do
        local node = self:findChild("Node_2_" .. i )
        if node ~= nil then
            local item = util_createView("CodeGoldExpressSrc.GoldExpressBonusResultItem",{type=i,levelID = self.m_levelID})
            self.m_resultItem[#self.m_resultItem+1] = item
            node:addChild(item)
        end
    end
end
function GoldExpressBonusGameLayer:initItem()
    local roundIndex = 1
    if self.m_curFeatureData then
        roundIndex = #self.m_curFeatureData.p_extra.otherOption + 1
    end
    local index = 1
    while true do
        local node = self:findChild("Node_1_" .. index )
        if node ~= nil then
            local info = {}
            info.type = roundIndex
            info.levelID = self.m_levelID
            local item = util_createView("CodeGoldExpressSrc.GoldExpressBonusGameItem", info)
            if self.m_vecItem == nil then
                self.m_vecItem = {}
            end
            self.m_vecItem[index] = item
            item:setTag(index)
            local func = function ()
                self:clickItemCallFunc(item:getTag())
            end
            item:setClickFunc(func)
            item:setClickFlag(true)
            node:addChild(item)
        else
            break
        end
        index = index + 1
    end
end

function GoldExpressBonusGameLayer:clickItemCallFunc(pos)
    local clickItem = self.m_vecItem[pos]
    if self.m_request then
        return
    end

    if clickItem.m_clickFlag == true then
        return
    end
    self.m_request = true
    clickItem.m_clickFlag = true
    gLobalSoundManager:playSound("GoldExpressSounds/sound_GoldExpress_bonusGameClick.mp3")

    self:sendData(pos)
    self.m_currClickItem = self.m_vecItem[pos]
end

function GoldExpressBonusGameLayer:initViewData(callBackFun,mainClass)
    self.m_mainClass = mainClass
    self.m_callFunc=callBackFun
    self:initItemStatus()
end

function GoldExpressBonusGameLayer:resetView(callBackFun, mainClass)
    self.m_mainClass = mainClass
    self.m_callFunc=callBackFun
    self:initItemStatus()
end

function GoldExpressBonusGameLayer:initItemStatus()
    if self.m_clickList == nil then
        self.m_clickList = {}
    end

    for i = 1, #self.m_vecItem, 1 do
        local item = self.m_vecItem[i]
        item:setClickFlag(false)
        item:idle()
    end
    if self.m_curFeatureData then
        local sumNum = #self.m_curFeatureData.p_chose
        --结果集发生变化
        if sumNum == 3 then
            for i = 1, #self.m_vecItem do
                local tagId = self.m_vecItem[i]:getTag()
                if tagId == self.m_curFeatureData.p_chose[sumNum] then
                    if self.m_clickList == nil then
                        self.m_clickList = {}
                    end
                    self.m_clickList[#self.m_clickList+1] = self.m_vecItem[i]:getTag()
                    self.m_vecItem[i]:showSelected(0)
                end
            end
        end
        self.m_resultItem[1]:showCoins(self.m_curFeatureData.p_contents)
        self.m_resultItem[2]:showExtra(self.m_curFeatureData.p_contents)
    end

end


--数据发送
function GoldExpressBonusGameLayer:sendData(pos)
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
function GoldExpressBonusGameLayer:clickItem(func,isShowOther)

    local index = 1
    local other = self.m_curFeatureData.p_extra.otherOption[self.m_currClickRow]
    self.m_currClickItem:click(self.m_serverWinCoins, function()
        if self.m_clickList == nil then
            self.m_clickList = {}
        end
        self.m_clickList[#self.m_clickList+1] = self.m_currClickItem:getTag()

        if self:checkNeedReset() then
            for i=1,#self.m_vecItem do
                if not self:checkClick(self.m_vecItem[i]:getTag()) then
                    self.m_vecItem[i]:unclick(other[index])
                    index = index+1
                end
            end
        end

        performWithDelay(self,function()
            if func then
                func()
            end
        end,1)
    end)
end
function GoldExpressBonusGameLayer:checkClick(id)
    for i=1,#self.m_clickList do
        if self.m_clickList[i] == id then
            return true
        end
    end
    return false
end
function GoldExpressBonusGameLayer:recvBaseData(featureData)
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
    performWithDelay(self,function()
        self.m_resultItem[1]:showCoins(self.m_curFeatureData.p_contents)
    end,1.3)

    self.m_currClickRow = #self.m_curFeatureData.p_extra.otherOption
    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)
        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_bsWinCoins, GameEffect.EFFECT_BONUS})

        self:clickItem(function()
            if self.m_callFunc ~= nil then
                self.m_resultItem[2]:showOverExtra(self.m_curFeatureData.p_contents)

                performWithDelay(self,function(  )
                    if self.m_extraGame then
                        self.m_callFunc(self.m_bsWinCoins, self.m_extraGame)
                    else
                        self.m_callFunc(self.m_bsWinCoins,nil)
                    end
                end,1.5)
            end
        end)
    else

        self:clickItem(function()
            if self:checkNeedReset() then
                self.m_request = false
                for i=1,#self.m_vecItem do
                    self.m_vecItem[i]:removeFromParent()
                end
                self.m_vecItem = {}
                self:initItem()
                self:initItemStatus()
            else
                self.m_resultItem[2]:showExtra(self.m_curFeatureData.p_contents)
                self.m_request = false
            end
        end)

    end

end
function GoldExpressBonusGameLayer:checkNeedReset()
    local sumNum = #self.m_curFeatureData.p_chose
    if sumNum < 3 or self.m_curFeatureData.p_status == "CLOSED" then
        return true
    end
    return false
end


function GoldExpressBonusGameLayer:sortNetData( data)
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

function GoldExpressBonusGameLayer:featureResultCallFun(param)
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

function GoldExpressBonusGameLayer:onEnter()
    gLobalSoundManager:setBackgroundMusicVolume(0)

    self.m_soundBg = gLobalSoundManager:playSound("GoldExpressSounds/sound_GoldExpress_bonusGameBg.mp3",true)


    BaseGame.onEnter(self)
end

function GoldExpressBonusGameLayer:onExit()
    gLobalSoundManager:setBackgroundMusicVolume(1)


    if self.m_soundBg then
        gLobalSoundManager:stopAudio(self.m_soundBg)
    end
    scheduler.unschedulesByTargetName("GoldExpress_BonusGame")
    BaseGame.onExit(self)
end

return GoldExpressBonusGameLayer