---
--smy
--2018年4月26日
--DwarfFairyBonusGame.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local DwarfFairyBonusGame = class("DwarfFairyBonusGame",BaseGame )
DwarfFairyBonusGame.m_mainClass = nil
DwarfFairyBonusGame.isClickNow = nil
DwarfFairyBonusGame.m_iTurnCoinNum = nil
DwarfFairyBonusGame.m_iLastCoinNum = nil
DwarfFairyBonusGame.m_iSoundID = nil
DwarfFairyBonusGame.m_bTouchFlag = nil
function DwarfFairyBonusGame:initUI()

    self.isClickNow = false
    self:createCsbNode("DwarfFairy/BonusFeture.csb")
    self.m_isBonusCollect=true

    -- self:runCsbAction("start",false,function()
        self:runCsbAction("Idlefrom",true)
        
    -- end)
    performWithDelay(self, function()
        self:addClick(self:findChild("btn"))
    end, 0.4)
    self.m_itemList = {}
    -- TODO 输入自己初始化逻辑
    self.m_bTouchFlag = true
    self.m_nodeSelected = {}
    local index = 1
    while true do
        local node = self:findChild("select_" .. index )
        if node ~= nil then
            self.m_nodeSelected[index] = node
        else
            break
        end
        index = index + 1
    end

    if display.height < 1370 then
        util_csbScale(self.m_csbNode, (display.height / 1370))
    else
        local posY = (display.height - 1370) * 0.5
        local root = self:findChild("root")
        root:setPositionY(root:getPositionY() - posY)
        self:findChild("DwarfFairy_paytable_1"):setPositionY(self:findChild("DwarfFairy_paytable_1"):getPositionY() + posY * 0.5)
        -- self:findChild("DwarfFairy_bonus_kuangsaoguang_01_1"):setPositionY(self:findChild("DwarfFairy_bonus_kuangsaoguang_01_1"):getPositionY() + posY * 0.5)
    end
    
end

function DwarfFairyBonusGame:showRewardView()

end

function DwarfFairyBonusGame:onEnter()
    BaseGame.onEnter(self)
end
function DwarfFairyBonusGame:onExit()
    scheduler.unschedulesByTargetName("DwarfFairy_BonusGame")
    BaseGame.onExit(self)

    -- gLobalSoundManager:stopBgMusic()
end

function DwarfFairyBonusGame:clickFunc(sender)
    if self.m_bTouchFlag == false then
        return
    end
    self.m_bTouchFlag = false
    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_click.mp3")
    self:runCsbAction("click", false, function()
        self:sendData()
    end)
end

-------------------子类继承-------------------
--处理数据 子类可以继承改写
--:calculateData(featureData)
--子类调用
--:getZoomScale(width)获取缩放比例
--:isTouch()item是否可以点击
--:sendStep(pos)item点击回调函数
--.m_otherTime=1      --其他宝箱展示时间
--.m_rewardTime=3     --结算界面弹出时间

function DwarfFairyBonusGame:initViewData(callBackFun, gameSecen)
    self:initData()
    self.m_callFunc = callBackFun
    self.m_gameSecen = gameSecen

    self.m_itemList[5]:runAnimation("idle2")
    table.remove(self.m_itemList, 5)
    self.m_iTurnCoinNum = 1
    self.m_iLastCoinNum = self.m_iTurnCoinNum
    -- gLobalSoundManager:playSound("DwarfFairySounds/sound_despicablewolf_enter_fs.mp3")
    -- self.m_currentMusicId = gLobalSoundManager:playBgMusic( "DwarfFairySounds/music_despicablewolf_bonus_bg.mp3")
    self:addSelectEffect()
end


function DwarfFairyBonusGame:resetView(featureData, callBackFun, gameSecen)

    self:initData()
    self.m_callFunc = callBackFun
    self.m_gameSecen = gameSecen
    self:runCsbAction("Idlefrom",true)
    self.m_iTurnCoinNum = #featureData.p_chose
    local vecChoose = featureData.p_chose
    for i = 1, self.m_iTurnCoinNum, 1 do
        local index = vecChoose[i]
        
        
    end
    for i = #self.m_itemList, 1, -1 do
        local item = self.m_itemList[i]
        for j = 1, #vecChoose, 1 do
            local index = vecChoose[j]
            if vecChoose[j] == item:getTag() then
                self.m_itemList[index]:runAnimation("idle2")
                table.remove(self.m_itemList, index)
                break
            end
        end
    end
    self.m_iLastCoinNum = self.m_iTurnCoinNum
    self:addSelectEffect()
end

function DwarfFairyBonusGame:initData()
    self:initItem()
end

function DwarfFairyBonusGame:initItem()
    
    for i = 1, 9 do 
        print("init item %d" , i)
        local item = util_createView("CodeDwarfFairySrc.DwarfFairyBonusItem")
        self.m_csbOwner["coin1_"..i]:addChild(item)
        item:setTag(i)
        self.m_itemList[i] = item
    end
end

function DwarfFairyBonusGame:addSelectEffect()
    if self.m_iLastCoinNum ~= self.m_iTurnCoinNum then
        self.m_nodeSelected[self.m_iLastCoinNum]:removeAllChildren()
        self.m_iLastCoinNum = self.m_iTurnCoinNum
    end
    local selectEffect, act = util_csbCreate("BonusFeture_zhongjiang.csb")
    if self.m_iTurnCoinNum == 9 then
        util_csbPlayForKey(act, "actionframe", true)
    else
        util_csbPlayForKey(act, "actionframe2", true)
    end
    
    self.m_nodeSelected[self.m_iTurnCoinNum]:addChild(selectEffect)
end

function DwarfFairyBonusGame:turnItems()
    if not self.m_choseData then
        return
    end
    local totalTime = 0
    local delayTime = 0.2
    local index = 1
    local soundTime = 0
    for i = #self.m_itemList, 1, -1 do
        local item = self.m_itemList[i]
        local callback = nil
        local isTurn = false
        for j = 1, #self.m_choseData, 1 do
            if self.m_choseData[j] == item:getTag() then
                item:setTurnID(index)
                index = index + 1
                isTurn = true
                break
            end
        end
        local waitTime = (i - 1) * delayTime
        item:startTurn(waitTime, isTurn)
        totalTime = math.max( totalTime, waitTime + 3)
        if isTurn == true then
            totalTime = math.max( totalTime, waitTime + 4.3)
            table.remove(self.m_itemList, i) 
        end
        soundTime = waitTime + 3
    end
    self.m_iSoundID = gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_coin_rotate.mp3", false)
    performWithDelay(self,function (  )
        if self.m_iSoundID ~= nil then
            self.m_iSoundID = nil
        end
    end,5)

    if soundTime + 0.6 < 5 then
        performWithDelay(self, function()
            if self.m_iSoundID ~= nil then
                gLobalSoundManager:stopAudio(self.m_iSoundID)
                self.m_iSoundID = nil
            end
        end, soundTime + 0.6)
    end
    performWithDelay(self, function()
        self.m_iTurnCoinNum = #self.m_choseData
        if self.m_featureData.p_status ~= "CLOSED" or #self.m_choseData == 9 then
            self:addSelectEffect()
        end
    end, totalTime)

    if self.m_featureData.p_status == "CLOSED" or #self.m_choseData == 9 then
        totalTime = totalTime + 2.5
    end
    performWithDelay(self, function()
        
        if self.m_featureData.p_status == "CLOSED" or #self.m_choseData == 9 then
            self:showReward()
        else
            self:sendData()
        end
        
    end, totalTime)
end

--数据发送
function DwarfFairyBonusGame:sendData(pos)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        
        messageData = { msg= nil , data = nil } -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
    
end


--弹出结算奖励
function DwarfFairyBonusGame:showReward()
    -- gLobalSoundManager:stopAudio(self.m_currentMusicId)
    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_pop_window.mp3")

    local ownerlist={}
    ownerlist["m_lb_coins"] = util_formatCoins(self.m_rewardCoin, 30)
    local view = self.m_gameSecen:showDialog(BaseDialog.DIALOG_TYPE_BONUS_OVER,ownerlist,function()
        self.m_callFunc()
        performWithDelay(self, function()
            self:removeFromParent()
        end, 0.6)
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.55,sy=0.55},1110)
end


function DwarfFairyBonusGame:uploadCoins(featureData)
    
end

--数据接收
function DwarfFairyBonusGame:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end
    
    self.m_choseData = featureData.p_chose
    self.p_status = featureData.p_status

    if not self.m_choseData then
        self.m_choseData = {}
        release_print("DwarfFairy Bonus玩法服务器返回选择数据为空")
    end

    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{featureData.p_bonusWinAmount, GameEffect.EFFECT_BONUS})
    else
        
    end
    self:turnItems()
end

function DwarfFairyBonusGame:sortNetData( data)
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

function DwarfFairyBonusGame:featureResultCallFun(param)
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
            self:recvBaseData(self.m_featureData)
            if self.m_featureData.p_status == "CLOSED" then
                self.m_rewardCoin = data.extra.coins[#self.m_featureData.p_chose]
            end
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
return DwarfFairyBonusGame