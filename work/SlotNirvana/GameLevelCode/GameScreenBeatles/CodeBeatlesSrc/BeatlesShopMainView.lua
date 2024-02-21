---
--xcyy
--2018年5月23日
--BeatlesShopMainView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseGame = util_require("base.BaseGame")
local BeatlesShopMainView = class("BeatlesShopMainView",BaseGame )
local BeatlesBaseData = require "CodeBeatlesSrc.BeatlesBaseData"

BeatlesShopMainView.m_machine = nil
BeatlesShopMainView.m_clickPos = nil --点击位置
BeatlesShopMainView.m_buyPlayNum = nil
BeatlesShopMainView.m_buyMinimumPlayNumLimit = nil -- 默认最少购买次数
BeatlesShopMainView.roleSpine = {}
BeatlesShopMainView.isPlay_fankui2 = true -- 判断是否播放玩 反馈2
BeatlesShopMainView.freeNumPrice = 0
BeatlesShopMainView.isPlayJiaoSe = false -- 是否正在播放角色4，5的特殊idle

function BeatlesShopMainView:initUI(machine)
    self.m_machine = machine

    self:createCsbNode("Beatles/BeatlesShop.csb")

    self:addClick(self:findChild("Button_reset"))
    self:addClick(self:findChild("Button_play"))
    -- 注册加次数减次数按钮
    for i=1,6 do
        self:addClick(self:findChild("Button_minus"..i))
        self:addClick(self:findChild("Button_plus"..i))
    end
    self:addClick(self:findChild("Button_1"))

    self.shopSpine = util_spineCreate("BeatlesShop", true, true)
    self:findChild("spine"):addChild(self.shopSpine) 

    self.fankui2 = util_createAnimation("Beatles/BeatlesShop_fankui2.csb")
    self:findChild("fankui2"):addChild(self.fankui2)

    self.fankui3 = util_createAnimation("Beatles/BeatlesShop_fankui3.csb")
    self:findChild("fankui3"):addChild(self.fankui3)

    self:resetLimitData()

    --5个角色
    for i=1,5 do
        self.roleSpine[i] = util_spineCreate("BeatleBeat_juese_"..i, true, true)
        util_spinePlay(self.roleSpine[i], "idleframe9", true)
    end
    
    self:findChild("Node_multiplier"):addChild(self.roleSpine[1]) 
    self:findChild("Node_ExtraLines"):addChild(self.roleSpine[2]) 
    self:findChild("Node_SymbolReplaced"):addChild(self.roleSpine[3]) 
    self:findChild("Node_WildReels"):addChild(self.roleSpine[4]) 
    self:findChild("Node_WildsAdded"):addChild(self.roleSpine[5]) 
end

--默认按钮监听回调
function BeatlesShopMainView:clickFunc(_sender)
    local name = _sender:getName()
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData

    if name == "Button_reset" then-- 重置次数
        gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_shop_reset.mp3")
        BeatlesBaseData:getInstance():setDataByKey("shopNum", {1,0,0,0,0,0})
        self:resetLimitData()
        self:resetShopNum()
    elseif name == "Button_play" then -- 购买
        if selfMakeData.store.coins < self:getAllNumOfPrice() then
            if self.isPlay_fankui2 then
                self.isPlay_fankui2 = false
                self.fankui2:playAction("actionframe", false, function()
                    self.isPlay_fankui2 = true
                end)
            end
        else
            gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_shop_buildPlay.mp3")
            local newFreeRoleId = {}
            for i,num in ipairs(self.m_buyPlayNum) do
                if i ~= 1 and num > 0 then
                    table.insert(newFreeRoleId, i-1)
                end
            end
            if #newFreeRoleId > 0 then
                self:playRoleVoice(newFreeRoleId[math.random(1, #newFreeRoleId)])
            end
            self:findChild("Button_play"):setTouchEnabled(false)
            for i=1,5 do
                util_spinePlay(self.roleSpine[i], "idleframe9", true)
            end
            
            self:sendData()
            self.fankui3:playAction("actionframe", false)
        end
        
    elseif name == "Button_minus1" then -- FREE减1
        self:reduceNum(1)
    elseif name == "Button_plus1" then -- FREE加1
        self:addNum(1)
    elseif name == "Button_minus2" then -- 成倍减1
        self:reduceNum(2)
    elseif name == "Button_plus2" then -- 成倍加1
        self:addNum(2)
    elseif name == "Button_minus3" then -- 加线减1
        self:reduceNum(3)
    elseif name == "Button_plus3" then -- 加线加1
        self:addNum(3)
    elseif name == "Button_minus4" then -- 随机wid减1
        self:reduceNum(4)
    elseif name == "Button_plus4" then -- 随机wid加1
        self:addNum(4)
    elseif name == "Button_minus5" then -- 整列wild减1
        self:reduceNum(5)
    elseif name == "Button_plus5" then -- 整列wild加1
        self:addNum(5)
    elseif name == "Button_minus6" then -- 加wild 减1
        self:reduceNum(6)
    elseif name == "Button_plus6" then -- 加wild 加1
        self:addNum(6)
    elseif name == "Button_1" then
        self.m_machine:showOpenOrCloseShop(false)
    end
end

-- 重置商店所you的次数
function BeatlesShopMainView:resetShopNum( )
    if not self.m_machine.m_runSpinResultData.p_selfMakeData or not self.m_machine.m_runSpinResultData.p_selfMakeData.store.storeData then
        self.m_machine.m_runSpinResultData.p_selfMakeData = {}
        self.m_machine.m_runSpinResultData.p_selfMakeData.store = {}
        self.m_machine.m_runSpinResultData.p_selfMakeData.store.storeData = {}
        self.m_machine.m_runSpinResultData.p_selfMakeData.store.storeData = BeatlesBaseData:getInstance():getDataByKey("storeData")
        self.m_machine.m_runSpinResultData.p_selfMakeData.store.coins = 0
    end
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local storeData = selfMakeData and selfMakeData.store.storeData or nil
    local freeBuyNum = self.m_buyMinimumPlayNumLimit[1] -- 默认free购买次数
    self.freeNumPrice = storeData.sum_price[1][freeBuyNum]
    for i=1,6 do
        self:findChild("m_lb_nums"..i):setString(self.m_buyMinimumPlayNumLimit[i])
        self:findChild("m_lb_coins"..i):setString(util_formatCoins(storeData.sum_price[i][freeBuyNum],50))
        self:updateLabelSizeSelf(self:findChild("m_lb_coins"..i), 104)
        if i == 1 then
            self:findChild("m_lb_nums_buy"..i):setString(self.m_buyMinimumPlayNumLimit[i])
        end

        if i ~= 1 then
            self:findChild("FeatureTimes"..i):setString(0)
            self:findChild("m_lb_coins"..i):setString(0)
            util_spinePlay(self.roleSpine[i-1], "idleframe9", true)
        end
        self:findChild("Button_minus"..i):setBright(false)
        self:findChild("Button_minus"..i):setTouchEnabled(false)

        self:findChild("Button_plus"..i):setBright(true)
        self:findChild("Button_plus"..i):setTouchEnabled(true)
    end
    self:findChild("m_lb_coins_play"):setString(util_formatCoins(storeData.sum_price[1][freeBuyNum],50))
    self:findChild("m_lb_coins_self"):setString(util_formatCoins(selfMakeData.store.coins,50))
    self:updateLabelSizeSelf(self:findChild("m_lb_coins_play"), 126)
    self:updateLabelSizeSelf(self:findChild("m_lb_coins_self"), 126)

    -- 重置一下free次数的 按钮相关 因为默认free有次数
    self:setBtnState(1)
    self:findChild("Button_play"):setTouchEnabled(true)

    self:showBuyButton()
end

-- 判断购买按钮
function BeatlesShopMainView:showBuyButton( )
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local storeData = selfMakeData and selfMakeData.store.storeData or nil
     -- 判断购买按钮
     if selfMakeData.store.coins < self:getAllNumOfPrice() then
        self:findChild("Button_play"):setBright(false)
        -- self:findChild("m_lb_coins_play"):setColor(cc.c3b(191, 191, 191))
        -- util_setSpriteGray(self:findChild("coins_buy_play"))
    else
        self:findChild("Button_play"):setBright(true)
        self:findChild("Button_play"):setTouchEnabled(true)
        -- self:findChild("m_lb_coins_play"):setColor(cc.c3b(255, 255, 255))
        -- util_clearSpriteGray(self:findChild("coins_buy_play"))
    end
end

function BeatlesShopMainView:updateLabelSizeSelf(node, sizeWidth)
    local info1={label=node,sx=1,sy=1}
    self:updateLabelSize(info1,sizeWidth)
end

--角色4 角色5想加权重最大的时候 两个都播放特殊idle
function BeatlesShopMainView:isPlayJiaoSeIdle( )
    if self.m_buyPlayNum[5] ~= 0 and self.m_buyPlayNum[6] ~= 0 then
        if (self.m_buyPlayNum[5] * 3 + self.m_buyPlayNum[6]) >= 15 then
            util_spinePlay(self.roleSpine[4], "idleframe9_2", true)
            util_spinePlay(self.roleSpine[5], "idleframe9_2", true)
            self:playRoleVoice(4)
            self:playRoleVoice(5)
            self.isPlayJiaoSe = true
        end
    end
end

--停止播放角色4 角色5 特殊idle
function BeatlesShopMainView:isStopJiaoSeIdle( )
    if self.isPlayJiaoSe then
        if (self.m_buyPlayNum[5] * 3 + self.m_buyPlayNum[6]) < 15 then
            util_spinePlay(self.roleSpine[4], "idleframe9", true)
            util_spinePlay(self.roleSpine[5], "idleframe9", true)
            self.isPlayJiaoSe = false
        end
    end
end

-- 增加次数
-- 参数为默认类型 界面从左到右 1-6
function BeatlesShopMainView:addNum(_type)
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local storeData = selfMakeData and selfMakeData.store.storeData or nil

    if self.m_buyPlayNum[_type] >= storeData.bonusLimit[_type] then
        return
    else
        self.m_buyPlayNum[_type] = self.m_buyPlayNum[_type] + 1
        if self.m_buyPlayNum[_type] >= storeData.bonusLimit[_type] and _type > 1 then
            util_spinePlay(self.roleSpine[_type-1], "idleframe9_2", true)
            self:playRoleVoice(_type-1)
            -- util_spineEndCallFunc(self.roleSpine[_type-1], "idleframe9_2", function()
                    
            --     util_spinePlay(self.roleSpine[_type-1], "idleframe9", true)
            -- end)
        end
    end
    self:isPlayJiaoSeIdle()
    gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_shop_addOrReduce.mp3")

    if _type == 1 then
        self:findChild("m_lb_nums_buy".._type):setString(self.m_buyPlayNum[_type])
    elseif _type == 2 then
        self:findChild("FeatureTimes".._type):setString(storeData.buy_num["bonusType"..(_type-1)][self.m_buyPlayNum[_type]+1].."X")
    else
        self:findChild("FeatureTimes".._type):setString(storeData.buy_num["bonusType"..(_type-1)][self.m_buyPlayNum[_type]+1])
    end

    self:findChild("m_lb_nums".._type):setString(self.m_buyPlayNum[_type])

    -- 按钮状态
    self:setBtnState(_type)

    if _type > 1 then
        self:findChild("m_lb_coins".._type):setString(util_formatCoins(storeData.sum_price[_type][self.m_buyPlayNum[_type]],50))

        self.freeNumPrice = self:getFreeNumPrice()
        self:findChild("m_lb_coins1"):setString(util_formatCoins(self.freeNumPrice,50))
        self:updateLabelSizeSelf(self:findChild("m_lb_coins1"), 95)
        self:updateLabelSizeSelf(self:findChild("m_lb_coins".._type), 104)
    else
        self.freeNumPrice = self:getFreeNumPrice()
        self:findChild("m_lb_coins1"):setString(util_formatCoins(self.freeNumPrice,50))
        self:updateLabelSizeSelf(self:findChild("m_lb_coins".._type), 95)
    end
    
    self:findChild("m_lb_coins_play"):setString(util_formatCoins(self:getAllNumOfPrice(),50))
    self:updateLabelSizeSelf(self:findChild("m_lb_coins_play"), 126)

    self:showBuyButton()
end

-- 减少次数
-- 参数为默认类型 界面从左到右 1-6
function BeatlesShopMainView:reduceNum(_type)
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local storeData = selfMakeData and selfMakeData.store.storeData or nil

    if self.m_buyPlayNum[_type] <= self.m_buyMinimumPlayNumLimit[_type] then
        return
    else
        self.m_buyPlayNum[_type] = self.m_buyPlayNum[_type] - 1
        --避免减次数的时候 一直切换
        if self.m_buyPlayNum[_type] == storeData.bonusLimit[_type] - 1 then
            util_spinePlay(self.roleSpine[_type-1], "idleframe9", true)
        end
    end

    self:isStopJiaoSeIdle()
    gLobalSoundManager:playSound("BeatlesSounds/Sound_Beatles_shop_addOrReduce.mp3")

    if _type == 1 then
        self:findChild("m_lb_nums_buy".._type):setString(self.m_buyPlayNum[_type])
    elseif _type == 2 then
        self:findChild("FeatureTimes".._type):setString(self.m_buyPlayNum[_type] == 0 and "0" or storeData.buy_num["bonusType"..(_type-1)][self.m_buyPlayNum[_type]+1].."X")
    else
        self:findChild("FeatureTimes".._type):setString(self.m_buyPlayNum[_type] == 0 and 0 or storeData.buy_num["bonusType"..(_type-1)][self.m_buyPlayNum[_type]+1])
    end

    self:findChild("m_lb_nums".._type):setString(self.m_buyPlayNum[_type])

    -- 按钮状态
    self:setBtnState(_type)

    if _type > 1 then
        self:findChild("m_lb_coins".._type):setString(util_formatCoins(storeData.sum_price[_type][self.m_buyPlayNum[_type]] or 0,50))

        self.freeNumPrice = self:getFreeNumPrice()
        self:findChild("m_lb_coins1"):setString(util_formatCoins(self.freeNumPrice,50))
        self:updateLabelSizeSelf(self:findChild("m_lb_coins1"), 95)
        self:updateLabelSizeSelf(self:findChild("m_lb_coins".._type), 104)
    else
        self.freeNumPrice = self:getFreeNumPrice()
        self:findChild("m_lb_coins1"):setString(util_formatCoins(self.freeNumPrice,50))
        self:updateLabelSizeSelf(self:findChild("m_lb_coins".._type), 95)
    end

    self:findChild("m_lb_coins_play"):setString(util_formatCoins(self:getAllNumOfPrice(),50))
    self:updateLabelSizeSelf(self:findChild("m_lb_coins_play"), 126)

    self:showBuyButton()
end

-- 总价钱
function BeatlesShopMainView:getAllNumOfPrice( )
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local storeData = selfMakeData and selfMakeData.store.storeData or nil
    local allPrice = self.freeNumPrice

    for i=2,6 do
        if self.m_buyPlayNum[i] ~= 0 then
            allPrice = allPrice + storeData.sum_price[i][self.m_buyPlayNum[i]]
        end
    end
    
    return allPrice
end

-- 设置按钮 状态
function BeatlesShopMainView:setBtnState(_type)
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local storeData = selfMakeData and selfMakeData.store.storeData or nil
    local allPoint = 0 --服务器给的每种次数都有权重 每次加次数 计算总权重 和服务器给的极限权重比较 判断是否还可以加次数

    self:findChild("Button_minus".._type):setBright(true)
    self:findChild("Button_minus".._type):setTouchEnabled(true)
    self:findChild("Button_plus".._type):setBright(true)
    self:findChild("Button_plus".._type):setTouchEnabled(true)

    if self.m_buyPlayNum[_type] <= self.m_buyMinimumPlayNumLimit[_type] then
        self:findChild("Button_minus".._type):setBright(false)
        self:findChild("Button_minus".._type):setTouchEnabled(false)
    end

    if self.m_buyPlayNum[_type] >= storeData.bonusLimit[_type] then
        self:findChild("Button_plus".._type):setBright(false)
        self:findChild("Button_plus".._type):setTouchEnabled(false)
    end

    -- 后两个需要特殊处理 分别有各自的权重 想加不能超过30
    for i=5,6 do
        allPoint = allPoint + storeData.bonusPoint[i] * self.m_buyPlayNum[i]
    end

    for i=5,6 do
        if (storeData.maxPoint - allPoint) >= storeData.bonusPoint[i] then
            self:findChild("Button_plus"..i):setBright(true)
            self:findChild("Button_plus"..i):setTouchEnabled(true)
        else
            self:findChild("Button_plus"..i):setBright(false)
            self:findChild("Button_plus"..i):setTouchEnabled(false)
        end
    end

    -- 如果购买次数的权重大于最大 随机wild的次数重置为0
    if allPoint >= storeData.maxPoint then
        self.m_buyPlayNum[4] = 0

        self:findChild("m_lb_nums4"):setString(0)
        self:findChild("FeatureTimes4"):setString(0)
        util_spinePlay(self.roleSpine[3], "idleframe9", true)

        -- self:findChild("m_lb_nums_buy4"):setString(0)
        self:findChild("m_lb_coins4"):setString(0)
        self:findChild("m_lb_coins_play"):setString(util_formatCoins(self:getAllNumOfPrice(),50))
        self:updateLabelSizeSelf(self:findChild("m_lb_coins_play"), 126)

        self:findChild("Button_plus4"):setBright(false)
        self:findChild("Button_plus4"):setTouchEnabled(false)
        self:findChild("Button_minus4"):setBright(false)
        self:findChild("Button_minus4"):setTouchEnabled(false)
    else
        if self.m_buyPlayNum[4] >= storeData.bonusLimit[4] then
            self:findChild("Button_plus4"):setBright(false)
            self:findChild("Button_plus4"):setTouchEnabled(false)
            self:findChild("Button_minus4"):setBright(true)
            self:findChild("Button_minus4"):setTouchEnabled(true)
        elseif self.m_buyPlayNum[4] <= 0 then
            self:findChild("Button_plus4"):setBright(true)
            self:findChild("Button_plus4"):setTouchEnabled(true)
            self:findChild("Button_minus4"):setBright(false)
            self:findChild("Button_minus4"):setTouchEnabled(false)
        else
            self:findChild("Button_plus4"):setBright(true)
            self:findChild("Button_plus4"):setTouchEnabled(true)
            self:findChild("Button_minus4"):setBright(true)
            self:findChild("Button_minus4"):setTouchEnabled(true)
        end
    end

    self:showTips(self.m_buyPlayNum )
end

function BeatlesShopMainView:onEnter()
    BaseGame.onEnter(self)
    
end

function BeatlesShopMainView:onExit()
    scheduler.unschedulesByTargetName("BeatlesShopMainView")
    BaseGame.onExit(self)

end

function BeatlesShopMainView:setEndCall( func)
    self.m_bonusEndCall = func
end

-- 重置默认数据
function BeatlesShopMainView:resetLimitData( )
    self.m_buyPlayNum = BeatlesBaseData:getInstance():getDataByKey("shopNum")
    self.m_buyMinimumPlayNumLimit = {1,0,0,0,0,0}
end

-- 刚打开商店的时候 显示
function BeatlesShopMainView:openShopShow( )
    if not self.m_machine.m_runSpinResultData.p_selfMakeData or not self.m_machine.m_runSpinResultData.p_selfMakeData.store.storeData then
        self.m_machine.m_runSpinResultData.p_selfMakeData = {}
        self.m_machine.m_runSpinResultData.p_selfMakeData.store = {}
        self.m_machine.m_runSpinResultData.p_selfMakeData.store.storeData = {}
        self.m_machine.m_runSpinResultData.p_selfMakeData.store.storeData = BeatlesBaseData:getInstance():getDataByKey("storeData")
        self.m_machine.m_runSpinResultData.p_selfMakeData.store.coins = 0
    end
    
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local storeData = selfMakeData and selfMakeData.store.storeData or nil

    for i=1,6 do
        self:findChild("m_lb_nums"..i):setString(self.m_buyPlayNum[i])
        
        if i == 1 then
            self:findChild("m_lb_nums_buy"..i):setString(self.m_buyPlayNum[i])
            self.freeNumPrice = self:getFreeNumPrice()
            self:findChild("m_lb_coins"..i):setString(util_formatCoins(self.freeNumPrice,50))
        else
            self:findChild("m_lb_coins"..i):setString(util_formatCoins(self.m_buyPlayNum[i] == 0 and 0 or storeData.sum_price[i][self.m_buyPlayNum[i]],50))
            if i == 2 then
                self:findChild("FeatureTimes"..i):setString(self.m_buyPlayNum[i] == 0 and 0 or storeData.buy_num["bonusType"..(i-1)][self.m_buyPlayNum[i]+1].."X")
            else
                self:findChild("FeatureTimes"..i):setString(storeData.buy_num["bonusType"..(i-1)][self.m_buyPlayNum[i]+1])
            end
        end
        self:updateLabelSizeSelf(self:findChild("m_lb_coins"..i), 104)

        -- 按钮状态
        self:setBtnState(i)
    end
    self:findChild("m_lb_coins_play"):setString(util_formatCoins(self:getAllNumOfPrice(),50))
    self:findChild("m_lb_coins_self"):setString(util_formatCoins(selfMakeData.store.coins,50))
    self:updateLabelSizeSelf(self:findChild("m_lb_coins_play"), 126)
    self:updateLabelSizeSelf(self:findChild("m_lb_coins_self"), 126)
    
    self:showBuyButton()
end

--数据发送
function BeatlesShopMainView:sendData()
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SPECIAL, data = {pageIndex = self.m_buyPlayNum, pageCellIndex = 5, selectSuperFree = self:getAllNumOfPrice()}}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)

end

--数据接收
function BeatlesShopMainView:recvBaseData(featureData)
    
    if self.m_bonusEndCall then
        if self.m_machine.m_spine_num == 10 then
            self.m_machine:clearCurMusicBg()
        end
        local chooseIndexList = {}
        -- 自己处理保存一下 选择的玩法
        for i,v in ipairs(self.m_buyPlayNum) do
            if i ~= 1 then
                chooseIndexList[i-1] = v
            end
        end
        BeatlesBaseData:getInstance():setDataByKey("choose_index", chooseIndexList)
        -- self.m_machine:showOpenOrCloseShop(false)
        self.m_bonusEndCall()

        self:resetLimitData()
    end

end

--开始结束流程
function BeatlesShopMainView:gameOver(isContinue)

end

--弹出结算奖励
function BeatlesShopMainView:showReward()

end

function BeatlesShopMainView:featureResultCallFun(param)
    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            dump(spinData.result, "featureResultCallFun data", 3)
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            self.m_totleWimnCoins = spinData.result.winAmount
            print("赢取的总钱数为=" .. self.m_totleWimnCoins)
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            if spinData.action == "SPECIAL" then
                self.m_spinDataResult = spinData.result

                self.m_machine.m_runSpinResultData:parseResultData(spinData.result,self.m_machine.m_lineDataPool)

                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(self.m_featureData)
            elseif self.m_isBonusCollect then
                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(self.m_featureData)
            else
                dump(spinData.result, "featureResult action" .. spinData.action, 3)
            end
        else
            -- 处理消息请求错误情况
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
    end 
end

--服务器提供的算法 计算free次数的单价
function BeatlesShopMainView:getFreeNumPrice( )
    local charNum = tostring(self.m_buyPlayNum[4]) .. tostring(self.m_buyPlayNum[5]) .. tostring(self.m_buyPlayNum[6])
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local storeData = selfMakeData and selfMakeData.store.storeData or nil 
    local freeNumPrice = 0 --freenum的价钱 
    local allPriceOld = 0 -- 总价钱

    if storeData then
        local baseData = 0
        for char,num in pairs(storeData.coin_base) do
            if charNum == char then
                baseData = num
                break
            end
        end
        local mulNum = self.m_buyPlayNum[2] == 0 and 1 or storeData.buy_num["bonusType1"][self.m_buyPlayNum[2]+1]
        local lineNum = self.m_buyPlayNum[3] == 0 and 0 or storeData.buy_num["bonusType2"][self.m_buyPlayNum[3]+1]
        freeNumPrice = baseData * self.m_buyPlayNum[1] * mulNum * (30 + lineNum) / 30

        for i=2,6 do
            if self.m_buyPlayNum[i] ~= 0 then
                allPriceOld = allPriceOld + storeData.sum_price[i][self.m_buyPlayNum[i]]
            end
        end
    end

    if freeNumPrice >= 800000 then
        freeNumPrice = freeNumPrice * 0.8 - allPriceOld
        if freeNumPrice <= 0 then
            freeNumPrice = 300
        end
    else
        freeNumPrice = freeNumPrice - allPriceOld
        if freeNumPrice <= 0 then
            freeNumPrice = 300
        end
    end

    return (freeNumPrice % 100) <= 50 and math.floor(freeNumPrice / 100) * 100 or (math.floor(freeNumPrice / 100)+1) * 100 
end

function BeatlesShopMainView:showTips(levels )
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local storeData = selfMakeData and selfMakeData.store.storeData or nil

    local tipsNum = 0
    local tipsTable = {}
    for i,v in ipairs(levels) do
        if i > 1 and v > 0 then
            tipsNum = tipsNum + 1
            table.insert(tipsTable, i-1)
        end
    end

    for i=1,5 do
        self:findChild(i.."kinds"):setVisible(false)
    end
    if tipsNum == 0 then
        self:findChild("1kinds"):setVisible(true)
        self:findChild("tip1_1"):removeAllChildren()
        self:findChild("tip1_1"):addChild(util_createAnimation("Beatles_shop_FeatureInfo0.csb"))

    else
        self:findChild(tipsNum.."kinds"):setVisible(true)
        for index, id in ipairs(tipsTable) do
            local tipsNode = util_createAnimation("Beatles_shop_FeatureInfo"..id..".csb")
            self:findChild("tip"..tipsNum.."_"..index):removeAllChildren()
            self:findChild("tip"..tipsNum.."_"..index):addChild(tipsNode)
            if id == 1 then
                tipsNode:findChild("m_lb_nums"):setString(storeData.buy_num["bonusType"..id][self.m_buyPlayNum[id+1]+1].."X")
                
            else
                tipsNode:findChild("m_lb_nums"):setString(storeData.buy_num["bonusType"..id][self.m_buyPlayNum[id+1]+1])
            end
        end
    end
end

function BeatlesShopMainView:playRoleVoice(m_index)
    local randomId = math.random(1,4)
    local sound_voice = string.format("BeatlesSounds/Sound_Beatles_role%d_voice%d.mp3", m_index, randomId)
    gLobalSoundManager:playSound(sound_voice)
end
return BeatlesShopMainView