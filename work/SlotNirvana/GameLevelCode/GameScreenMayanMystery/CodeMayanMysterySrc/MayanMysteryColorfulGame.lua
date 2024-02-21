---
--xcyy
--2018年5月23日
--MayanMysteryColorfulGame.lua
--多福多彩(带网络回调,可断线重连)
--[[
    使用方式

    --在调用showView之前需重置界面显示
    local endFunc = function()
    
    end
    self.m_colorfulGameView:resetView(self.m_initFeatureData,endFunc)
    self.m_colorfulGameView:showView()

    --断线重连时,需在主类实现以下方法
    function CodeCodeGameScreenMayanMysteryMachine:initFeatureInfo(spinData,featureData)
        --若服务器返回数据中没有status字段必须要求服务器加上,触发时可不返回
        if featureData.p_bonus and featureData.p_bonus.status == "OPEN" then
            self:addBonusEffect()
        end
    end

    --添加bonus事件
    function CodeCodeGameScreenMayanMysteryMachine:addBonusEffect( )
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        -- 添加bonus effect
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})

    end
]]
local PublicConfig = require "MayanMysteryPublicConfig"
local SendDataManager = require "network.SendDataManager"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local MayanMysteryColorfulGame = class("MayanMysteryColorfulGame",util_require("Levels.BaseLevelDialog"))

MayanMysteryColorfulGame.m_endFunc = nil     --结束回调
MayanMysteryColorfulGame.m_isWaiting = false --是否等待网络消息回来
MayanMysteryColorfulGame.m_featureData = nil --网络消息返回的数据
MayanMysteryColorfulGame.m_serverWinCoins = 0   --赢钱数

local ITEM_COUNT = 6          --可点击道具数量
local PICK_TYPE = {"Double","UPGRADE"}

-- 构造函数
function MayanMysteryColorfulGame:ctor(params)
    MayanMysteryColorfulGame.super.ctor(self,params)
    self.m_featureData = SpinFeatureData.new()
    self.m_left_item_counts = {}
    self.m_featureBonusData = {}
    self.m_jinBiNode = {}
end

function MayanMysteryColorfulGame:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("MayanMystery/DfdcScreen.csb")

    --jackpot
    self.m_jackpotBar = util_createView("CodeMayanMysterySrc.MayanMysteryColofulJackPotBar",{machine = self.m_machine})
    self:findChild("Node_Jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:showJackpot(false)

    --tips
    self.m_tipsNode = util_createAnimation("MayanMystery_dfdc_wenan.csb")
    self:findChild("Node_wenan"):addChild(self.m_tipsNode)
    self.m_tipsNode:findChild("Node_pick1"):setVisible(true)

    -- 小过场
    self.m_smallGuoChang = util_spineCreate("MayanMystery_juese",false,true)
    self:findChild("Node_bg"):addChild(self.m_smallGuoChang)
    self.m_smallGuoChang:setVisible(false)

    --定时节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    --所有道具数组
    self.m_items = {}
    for index = 1, ITEM_COUNT do
        local parentNode = self:findChild("Node_wanfa_"..index)
        local item = util_createView("CodeMayanMysterySrc.MayanMysteryColorfulItem",{
            parentView = self,
            itemID = index
        })

        if parentNode then
            parentNode:addChild(item)
        else
            self:addChild(item)
        end
        self.m_items[index] = item
    end

    -- 12个金币 不可点击
    for index = 1, 12 do
        self.m_jinBiNode[index] = util_spineCreate("MayanMystery_pick", true, true)
        self:findChild("Node_"..index):addChild(self.m_jinBiNode[index])
        util_spinePlay(self.m_jinBiNode[index], "pick2_idle", true)
    end
    
end

function MayanMysteryColorfulGame:onEnter()
    MayanMysteryColorfulGame.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(self, params)
        self:featureResultCallFun(params)
    end,
    ViewEventType.NOTIFY_GET_SPINRESULT)
end

--[[
    开启定时idle
]]
function MayanMysteryColorfulGame:startIdleAni()
    local unClickdItems = self:getUnClickeItem()
    --每次随机控制1个摆动
    for index = 1,1 do
        if #unClickdItems > 0 then
            local randIndex = math.random(1,#unClickdItems)
            local item = unClickdItems[randIndex]
            if not tolua.isnull(item) then
                item:runShakeAni()
            end
            table.remove(unClickdItems,randIndex)
        end
    end
    performWithDelay(self.m_scheduleNode,function()
        self:startIdleAni()
    end, 2)
end

--[[
    停止定时idle
]]
function MayanMysteryColorfulGame:stopIdleAni()
    self.m_scheduleNode:stopAllActions()
end

--[[
    获取还未点击位置
]]
function MayanMysteryColorfulGame:getUnClickeItem()
    local unClickdItems = {}
    for k,item in pairs(self.m_items) do
        if not item.m_isClicked then
            unClickdItems[#unClickdItems + 1] = item
        end
    end

    return unClickdItems
end

--[[
    设置bonus数据
]]
function MayanMysteryColorfulGame:setBonusData(featureData,endFunc)
    --解析数据(触发时传进来的数据为空)
    if featureData then
        if featureData.p_data and featureData.p_data.selfData and featureData.p_data.selfData.bonus then
            self.m_featureBonusData = featureData.p_data.selfData.bonus
        end
    else
        self.m_featureBonusData = {}
    end
    
    self.m_endFunc = endFunc
    --当前是否结束
    self.m_isEnd = false
    --重置收集剩余数量(需根据当前断线重连的具体数据进行计算)
    local rewardList = self:getCurClickRewardList()
    for index, Type in pairs(PICK_TYPE) do
        self.m_left_item_counts[Type] = 3 - rewardList[Type]
    end
end

--[[
    重置界面显示
]]
function MayanMysteryColorfulGame:resetView(featureData,endFunc)
    self:setBonusData(featureData,endFunc)

    --重置jackpot显示及已点击的位置显示(需根据当前断线重连的具体数据进行显示)
    local rewardList = self:getCurClickRewardList()
    for index,item in ipairs(self.m_items) do
        local rewardType = self:getRewardByItemId(item:getItemID())
        item:resetStatus(rewardType)
    end

    -- 12个金币 不可点击
    for index = 1, 12 do
        util_spinePlay(self.m_jinBiNode[index], "pick2_idle", true)
    end
end

--[[
    显示界面(执行start时间线)
]]
function MayanMysteryColorfulGame:showView(func)
    self:setVisible(true)
    self:runCsbAction("start",false,function()
        self:startIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
    self.m_tipsNode:runCsbAction("show")
    self.m_jackpotBar:playEpicShowEffect()
end

--[[
    隐藏界面(执行over时间线)
]]
function MayanMysteryColorfulGame:hideView(func)
    self:runCsbAction("over",false,function()
        self:setVisible(false)
        if type(func) == "funciton" then
            func()
        end
    end)
    
end

--[[
    点击道具回调
]]
function MayanMysteryColorfulGame:clickItem(clickItem)
    if self.m_isEnd or self.m_isWaiting then
        return
    end

    --防止连续点击
    self.m_isWaiting = true

    self.m_curClickItem = clickItem

    self:sendData(clickItem:getItemID())
end

--[[
    显示点击结果
]]
function MayanMysteryColorfulGame:showClickResult()
    --获取当前点击的的奖励
    local rewardType = self:getRewardByItemId(self.m_curClickItem:getItemID())
    --减少剩余奖励数量
    self.m_left_item_counts[rewardType] = self.m_left_item_counts[rewardType] - 1

    --刷新点击位置的道具显示
    if not self.m_isEnd then
        self.m_curClickItem:showRewardAni(rewardType)
    else
        --停止idle定时器
        self:stopIdleAni()
        --游戏结束
        self.m_curClickItem:showRewardAni(rewardType,function()
            --显示其他未点击的位置的奖励
            self:showUnClickItemReward()

            --显示中奖动效
            self:showHitJackpotAni(rewardType, function()
                self:playPickChangeEffect(function()
                    self:playChangeGuoChangEffect(function()
                        self:setVisible(false)
                        if type(self.m_endFunc) == "function" then
                            self.m_endFunc(self.m_featureData.p_data)
                        end
                    end)
                end)
            end)
        end)
    end
end

--[[
    显示中奖动效
]]
function MayanMysteryColorfulGame:showHitJackpotAni(winType, func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_colorFul_win)

    for index = 1,#self.m_items do
        local item = self.m_items[index]
        --未中奖的压黑
        if not item:isSameType(winType) then
            item:runDarkAni()
        else
            item:getRewardAni()
            item:getParent():setLocalZOrder(10)
        end
    end

    --结果多展示一会(延迟为中奖时间时间线长度+0.5s)
    performWithDelay(self,function()
        if type(func) == "function" then
            func()
        end
    end,2)
end

--[[
    播放pick 转换动画
]]
function MayanMysteryColorfulGame:playPickChangeEffect(func)
    for index = 1, 12 do
        util_spinePlay(self.m_jinBiNode[index], "pick2_switch", false)
        util_spineEndCallFunc(self.m_jinBiNode[index], "pick2_switch", function()
            util_spinePlay(self.m_jinBiNode[index], "idle", true)
        end)
    end
    performWithDelay(self,function()
        if type(func) == "function" then
            func()
        end
    end,37/30)
end

--[[
    当前结束 切换到下个界面
]]
function MayanMysteryColorfulGame:playChangeGuoChangEffect(_func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_colorFul_to_bonusGame)

    self.m_smallGuoChang:setVisible(true)
    util_spinePlay(self.m_smallGuoChang, "actionframe_open", false)
    util_spineEndCallFunc(self.m_smallGuoChang, "actionframe_open", function()
        self.m_smallGuoChang:setVisible(false)
        if type(_func) == "function" then
            _func()
        end
    end)

    self:runCsbAction("switch", false, function()
        for index = 1,#self.m_items do
            local item = self.m_items[index]
            item:getParent():setLocalZOrder(1)
        end
    end)
    self.m_jackpotBar:playEpicOverEffect()
end

--[[
    显示未点击位置的奖励
]]
function MayanMysteryColorfulGame:showUnClickItemReward()
    local leftReward = {}
    --计算还没有点出来的jackpot
    for rewardType,count in pairs(self.m_left_item_counts) do
        for iCount = 1,count do
            leftReward[#leftReward + 1] = rewardType
        end
    end

    --打乱数组
    randomShuffle(leftReward)

    local unClickItems = self:getUnClickeItem()
    for index = 1,#leftReward do
        local rewardType = leftReward[index]
        local item = unClickItems[index]
        item:setJackpotTypeShow(rewardType, false)
    end
end

--[[
    获取剩余的奖励数量
]]
function MayanMysteryColorfulGame:getLeftRewrdCount(rewardType)
    return self.m_left_item_counts[rewardType] or 3
end

------------------------------------网络数据相关------------------------------------------------------------
--[[
    数据发送
]]
function MayanMysteryColorfulGame:sendData(clickPos)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_colorFul_click)

    local httpSendMgr = SendDataManager:getInstance()
    -- -- 拼接数据，data对应发给服务器的select字段
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT, data = clickPos-1}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--[[
    解析返回的数据
]]
function MayanMysteryColorfulGame:featureResultCallFun(param)
    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            local userMoneyInfo = param[3]
            --防止其他类型消息传到这里
            if spinData.action == "FEATURE" and not self.m_isEnd then
                self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
                --bonus中需要带回status字段才会有最新钱数回来
                globalData.userRunData:setCoins(userMoneyInfo.resultCoins) 
                globalData.slotRunData.lastWinCoin = spinData.result.winAmount
                self.m_featureData:parseFeatureData(spinData.result)
                
                if self.m_featureData.p_data and self.m_featureData.p_data.selfData and self.m_featureData.p_data.selfData.bonus then
                    self.m_featureBonusData = self.m_featureData.p_data.selfData.bonus
                end

                self:recvBaseData(self.m_featureData)
            end
        else
            gLobalViewManager:showReConnect(true)
        end
    end
end

--[[
    网络消息返回
]]
function MayanMysteryColorfulGame:recvBaseData(featureData)
    self.m_isWaiting = false
    --游戏结束
    if featureData.p_data and featureData.p_data.bonus and featureData.p_data.bonus.extra and not featureData.p_data.bonus.extra.introFinished then
        self.m_isEnd = true
    end

    --显示点击的结果
    self:showClickResult()
end

--[[
    获取当前的奖励
]]
function MayanMysteryColorfulGame:getRewardByItemId(itemID)
    --从m_featureData中获取本次点击的奖励
    local reward = ""
    if self.m_featureBonusData and self.m_featureBonusData.pickindex then
        for index, pickindex in ipairs(self.m_featureBonusData.pickindex) do
            if itemID == (pickindex + 1) and self.m_featureBonusData.process then
                reward = self.m_featureBonusData.process[index]
                break
            end
        end
    end

    return reward
end

--[[
    获取当前已点击的奖励列表
]]
function MayanMysteryColorfulGame:getCurClickRewardList()
    local rewardList = {}
    
    if self.m_featureBonusData and self.m_featureBonusData.result then
        for _type, _nums in pairs(self.m_featureBonusData.result) do
            rewardList[tostring(_type)] = _nums
        end
    else
        for index, Type in ipairs(PICK_TYPE) do
            --此处数据应为服务器数据
            rewardList[Type] = 0
        end
    end

    return rewardList
end

------------------------------------网络数据相关  end------------------------------------------------------------


return MayanMysteryColorfulGame