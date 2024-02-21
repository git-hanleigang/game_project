---
--smy
--2018年4月26日
--AZTECBonusGame.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local AZTECBonusGame = class("AZTECBonusGame",BaseGame )
AZTECBonusGame.m_mainClass = nil
AZTECBonusGame.m_currJackpot = nil
AZTECBonusGame.m_totalSelected = nil
AZTECBonusGame.m_totalDeleted = nil

local DELETE_JACKPOT_ARRAY = {"Mini", "Minor", "Major"}

local ALL_JACKPOT_ARRAY = {"Mini", "Minor", "Major", "Maxi", "Grand", "Super"}


function AZTECBonusGame:initUI(data)

    self.m_isShowTournament = true

    self:createCsbNode("AZTEC/AZTECBonusGame.csb",true)
    -- self.m_csbNode:setPosition(display.cx, display.cy)
    self.m_isBonusCollect=true
    -- TODO 输入自己初始化逻辑

    local words, act = util_csbCreate("AZTEC_BonusGame_wenzi.csb")
    self:findChild("words"):addChild(words)
    util_csbPlayForKey(act, "idle", true)

    self.m_vecItem = {}
    local itemTag = 1
    local index = 1
    while true do
        local node = self:findChild("Node_" .. index )
        if node ~= nil then
            local item = util_createView("CodeAZTECSrc.AZTECBonusItem", index)
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
    self.m_vecChooseItems = {}

end

function AZTECBonusGame:clickItemCallFunc(item)
    if self.m_bClickFlag == false then
        return 
    end
    self:runCsbAction("idle")
    gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_click_coin.mp3")
    self.m_bClickFlag = false
    self.m_currClickItem = item
    item:setClickEnabled(false)
    self:sendData(item:getTag())
    
end

function AZTECBonusGame:onEnter()
    BaseGame.onEnter(self)
end
function AZTECBonusGame:onExit()
    scheduler.unschedulesByTargetName("AZTEC_AZTECBonusGame")
    BaseGame.onExit(self)

    -- gLobalSoundManager:stopBgMusic()
end

function AZTECBonusGame:initViewData(callBackFun,mainClass)
    self:runCsbAction("animation0", false, function ()
        self.m_bClickFlag = true
        self:runCsbAction("idle2", true)
        mainClass:runCsbAction("idle1", true)
        gLobalSoundManager:playBgMusic( "AZTECSounds/music_AZTEC_bonus_game_bgm.mp3")
    end)

    for i = 1, #self.m_vecItem, 1 do 
        self.m_vecItem[i]:showFly()
    end

    self.m_mainClass = mainClass
    self.m_callFunc = callBackFun
    self.m_totalSelected = 0
    self.m_totalDeleted = 0
    self:addJackpotBar()
    -- self:sendStartGame()
    -- gLobalSoundManager:playSound("AZTECSounds/sound_despicablewolf_enter_fs.mp3")
    
end

--默认按钮监听回调
function AZTECBonusGame:clickItem(func)
    performWithDelay(self, function()
        self.m_jackpotNode:updateBonusIcon(self.m_currJackpot, #self.m_vecChooseItems[self.m_currJackpot], true)
    end, 0.5)
    self.m_currClickItem:showResult(self.m_currJackpot, function()
        self:clickCallBack()
    end, func)
    
end

function AZTECBonusGame:clickCallBack()
    if self.m_currJackpot == "Super" then
        self.m_totalDeleted = self.m_totalDeleted + 1
        local jackpot = DELETE_JACKPOT_ARRAY[self.m_totalDeleted]
        local vecPos = self.m_featureData.p_bonus.extra[jackpot]
        if self.m_vecChooseItems[jackpot] ~= nil then
            for i = 1, #self.m_vecChooseItems[jackpot], 1 do 
                self.m_vecChooseItems[jackpot][i]:showDelete(jackpot)
            end
        end
        for i = 1, #vecPos, 1 do 
            local item = self.m_vecItem[vecPos[i]] 
            item:runDelete(jackpot)
            if self.m_vecChooseItems[jackpot] == nil then 
                self.m_vecChooseItems[jackpot] = {}
            end
            self.m_vecChooseItems[jackpot][#self.m_vecChooseItems[jackpot] + 1] = item 
        end
        self.m_totalSelected = self.m_totalSelected + #vecPos
        performWithDelay(self, function()
            self:deleteJackpot(jackpot)
        end, 1.5)
    else
        if self.m_bGameOver ~= true then
            self.m_bClickFlag = true
        end
    end
end

function AZTECBonusGame:deleteJackpot(jackpot)
    self.m_currClickItem:showSuper(function()
        self.m_bClickFlag = true
    end)
    local beginPos = self.m_currClickItem:getParent():convertToWorldSpace(cc.p(self.m_currClickItem:getPosition()))
    beginPos = self.m_mainClass:convertToNodeSpace(beginPos)
    local endNode = self.m_jackpotNode:findChild("Bg_"..jackpot)
    local endPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    endPos = self.m_mainClass:convertToNodeSpace(endPos)

    local distance = cc.pGetDistance(beginPos, endPos)
    local scale = distance / 900
    local height = endPos.y - beginPos.y
    local angle = math.deg(math.asin(height / distance ))
    local line, act = util_csbCreate("AZTEC_Bonusxiaochu_trail.csb")
    self.m_mainClass:addChild(line, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT + 1)
    line:setPosition(beginPos)
    line:setScaleX(scale)
    if endPos.x < beginPos.x then
        line:setRotation(angle - 180)
    else
        line:setRotation(-angle)
    end
    gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_super_line.mp3")
    util_csbPlayForKey(act, "animation0", false, function()
        self.m_jackpotNode:updateBonusIcon(DELETE_JACKPOT_ARRAY[self.m_totalDeleted], nil, nil, true)
        self.m_jackpotNode:toAction(DELETE_JACKPOT_ARRAY[self.m_totalDeleted], false, function ()
            self.m_jackpotNode:toAction("idle"..DELETE_JACKPOT_ARRAY[self.m_totalDeleted], true)
        end)
        line:removeFromParent()
    end)

    -- for i = 1, #self.m_vecChooseItems[jackpot], 1 do 
    --     self.m_vecChooseItems[jackpot][i]:showDelete(jackpot)
    -- end
end

function AZTECBonusGame:resetView(featureData,callBackFun, mainClass)
    gLobalSoundManager:playBgMusic( "AZTECSounds/music_AZTEC_bonus_game_bgm.mp3")
    self:runCsbAction("idle", false, function ()
        self.m_bClickFlag = true
    end)
    self.m_mainClass = mainClass
    self.m_callFunc = callBackFun

    local content = featureData.p_bonus.content
    local choose = featureData.p_bonus.choose
    local delete = featureData.p_bonus.extra
    self.m_totalSelected = #content
    self.m_totalDeleted = 0

    for i = 1, self.m_totalSelected, 1 do
        local item = self.m_vecItem[choose[i]]
        local result = content[i]
        item:showSelected(result)
        if self.m_vecChooseItems[result] == nil then
            self.m_vecChooseItems[result] = {}
        end
        self.m_vecChooseItems[result][#self.m_vecChooseItems[result] + 1] = item
    end

    for key, value in pairs(delete) do
        self.m_totalDeleted = self.m_totalDeleted + 1
        local jackpot = key
        for i = 1, #self.m_vecChooseItems[jackpot], 1 do
            local item = self.m_vecChooseItems[jackpot][i]
            item:showDelete(jackpot)
        end 
    end

    if self.m_totalSelected == nil or self.m_totalSelected == 0 then
        self:runCsbAction("idle2", true)
    end
    self:addJackpotBar()
    if self.m_totalSelected > 0 then
        for i = 1, self.m_totalSelected, 1 do
            local result = content[i]
            if result ~= "Super" then
                self.m_jackpotNode:updateBonusIcon(result, #self.m_vecChooseItems[result])
            end
        end
    end
    if self.m_totalDeleted > 0 then
        for key, value in pairs(delete) do
            self.m_jackpotNode:updateBonusIcon(key, nil, nil, true)
        end
    end
end

function AZTECBonusGame:addJackpotBar()
    self.m_jackpotNode = util_createView("CodeAZTECSrc.AZTECJackPotBarView")
    self.m_jackpotNode:initMachine(self.m_mainClass)
    self:findChild("Node_jackpot"):addChild(self.m_jackpotNode)
    if self.m_totalDeleted > 0 then
        self.m_jackpotNode:toAction("idle"..DELETE_JACKPOT_ARRAY[self.m_totalDeleted], true)
    end
    self.m_jackpotNode:addBonusIcon()
end

--数据发送
function AZTECBonusGame:sendData(pos)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        
        messageData={msg = MessageDataType.MSG_BONUS_SELECT , data = pos, jackpot = self.m_mainClass.m_jackpotList, betLevel = self.m_mainClass.m_iBetLevel} -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,true)
    
end

function AZTECBonusGame:recvBaseData(featureData)
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

        self:clickItem(function()
            gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_bonus_reward.mp3")
            for j = 1, #self.m_vecChooseItems[self.m_currJackpot], 1 do
                local item = self.m_vecChooseItems[self.m_currJackpot][j]
                item:showReward(self.m_currJackpot)
            end

            for i = 1, #ALL_JACKPOT_ARRAY, 1 do
                local jackpot = ALL_JACKPOT_ARRAY[i]
                if jackpot ~= self.m_currJackpot and self.m_vecChooseItems[jackpot] ~= nil then
                    for j = 1, #self.m_vecChooseItems[jackpot], 1 do
                        local item = self.m_vecChooseItems[jackpot][j]
                        item:showDelete(jackpot)
                    end
                end
            end

            local vecPos = featureData.p_bonus.extra.otherPosition
            local vecResult = featureData.p_bonus.extra.otherOption
            for i = 1, #vecPos, 1 do
                self.m_vecItem[vecPos[i]]:runDelete(vecResult[i])
            end 
            performWithDelay(self, function()
                if self.m_callFunc ~= nil then
                    self.m_callFunc(self.m_totleWimnCoins, self.m_currJackpot)
                end
            end, 3)
        end)
        self.m_bGameOver = true
    else
        self:clickItem()
    end
    
end

--弹出结算界面前展示其他宝箱数据
function AZTECBonusGame:showOther()
    
end

--开始结束流程
function AZTECBonusGame:gameOver()
    
end

--弹出结算奖励

function AZTECBonusGame:sortNetData( data)
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

function AZTECBonusGame:featureResultCallFun(param)
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
            self.m_totalSelected = self.m_totalSelected + 1
            self.m_currJackpot = data.bonus.content[self.m_totalSelected]
            if self.m_vecChooseItems[self.m_currJackpot] == nil then 
                self.m_vecChooseItems[self.m_currJackpot] = {}
            end
            self.m_vecChooseItems[self.m_currJackpot][#self.m_vecChooseItems[self.m_currJackpot] + 1] = self.m_currClickItem
            self.m_featureData:parseFeatureData(data)
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
return AZTECBonusGame