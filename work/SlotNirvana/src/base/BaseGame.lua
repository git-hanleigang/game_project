---
--smy
--2018年4月23日
--BaseGame.lua

local BaseView = require "base.BaseView"
local SendDataManager = require "network.SendDataManager"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local BaseGame = class("BaseGame", BaseView)

--服务器数据状态
BaseGame.ACTION_NONE = -1 --未初始化阶段
BaseGame.ACTION_ILDE = 0 --待机阶段
BaseGame.ACTION_SEND = 1 --发送消息阶段
BaseGame.ACTION_RECV = 2 --接受数据阶段
BaseGame.ACTION_OVER = 3 --停止阶段

BaseGame.m_isLocalData = nil
--是否使用本地数据
BaseGame.m_featureData = nil
--服务器返回数据
BaseGame.p_contents = nil --宝箱真实数据
BaseGame.p_chose = nil --用户选择结果
BaseGame.p_status = nil --状态
BaseGame.m_pos = nil --用户点击位置信息
BaseGame.m_posIndex = nil --当前展示位置信息
BaseGame.m_action = nil --服务器数据状态
BaseGame.m_otherTime = nil --结算时其他宝箱显示时间
BaseGame.m_rewardTime = nil --结算界面弹出时间
BaseGame.m_isContinue = nil --是否是断线重连操作
BaseGame.m_isBonusCollect = nil --是否为收集小游戏

BaseGame.m_isShowTournament = nil -- 是否显示Tournament

-- 构造函数
function BaseGame:ctor()
    BaseView.ctor(self)
    self.m_featureData = SpinFeatureData.new()
    self:initBaseData()
end

function BaseGame:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:featureResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end
end
function BaseGame:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)

    scheduler.unschedulesByTargetName("BaseGame")

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_VIEW_VISIBLE, {true})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOURNAME_VISIBLE, {true})
end
function BaseGame:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
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
    end
end

--------------------------- BASEGAME---------------------------
--是否可点击状态判断
function BaseGame:isTouch()
    -- print(self.ACTION_NONE.."jkjkjkjkj  "..self.ACTION_OVER.."  "..self.m_action)
    return self.m_action ~= self.ACTION_NONE and self.m_action ~= self.ACTION_OVER
end
--是否结束游戏
function BaseGame:isGameOver()
    return self.p_status == "CLOSED"
end
--初始化父类数据
function BaseGame:initBaseData()
    self.m_serverWinCoins = 0
    self.m_machine = nil
    self.p_contents = nil -- 例如两种选择
    self.p_chose = nil -- 选择的是第几个，
    self.p_status = nil -- 状态
    self.m_pos = {} -- 点击的位置信息
    self.m_posIndex = 0
    self.m_action = self.ACTION_NONE --正在执行的动作
    self.m_otherTime = 1 --其他宝箱展示时间
    self.m_rewardTime = 3 --结算界面弹出时间

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_VIEW_VISIBLE, {false})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_TOURNAMENT_VIEW_SHOW, false)
end
function BaseGame:clearPosInfo()
end
function BaseGame:clearBaseData()
    self.m_machine = nil
    self.p_contents = nil -- 例如两种选择
    self.p_chose = nil -- 选择的是第几个，
    self.p_status = nil -- 状态
    self.m_pos = nil -- 点击的位置信息
    self.m_posIndex = nil
    self.m_action = nil --正在执行的动作
    self.m_otherTime = nil --其他宝箱展示时间
    self.m_rewardTime = nil --结算界面弹出时间
end
--点击start 按钮
function BaseGame:sendStartGame()
    --只有未初始化可以发送start消息
    if self.m_action == self.ACTION_NONE then
        self:sendData()
    end
end
--start按钮回调
function BaseGame:startGameCallFunc()
    --游戏开启的标志
    self.m_action = self.ACTION_ILDE
end
--断线重连
function BaseGame:continueGame(featureData)
    -- featureData=featureData.result
    dump(featureData, "featureData-continueGame", 3)
    self.m_isContinue = true
    self.p_contents = featureData.p_contents
    self.p_chose = featureData.p_chose
    self.p_status = featureData.p_status

    if featureData.p_status == "START" then
        self.m_isContinue = false
        self:continueGameCallFunc()
        return
    end

    if featureData.p_status == "CLOSED" then
        for k, pos in ipairs(self.p_chose) do
            self.m_pos[k] = pos + 1
        end
        self.p_status = "OPEN"
        for index, pos in ipairs(self.p_chose) do
            if index == #self.p_chose then
                self.p_status = "CLOSED"
            end
            self:calculateData(self.p_contents[index])
        end
        self.p_status = "CLOSED"
        self.m_isContinue = false
        -- self:continueGameCallFunc()
        self:gameOver()
        return
    end

    if featureData.p_status == "OPEN" then
        for k, pos in ipairs(self.p_chose) do
            self.m_pos[k] = pos + 1
        end
        self.p_status = "OPEN"
        for index, pos in ipairs(self.p_chose) do
            self:calculateData(self.p_contents[index])
        end
        self.m_isContinue = false
        self:continueGameCallFunc()
        return
    end

    for _, pos in ipairs(self.p_chose) do
        self.m_pos[#self.m_pos + 1] = pos + 1
    end
    for _, selectData in ipairs(self.p_contents) do
        self:calculateData(selectData)
    end
    self.m_isContinue = false
    self:continueGameCallFunc()
end
--完成断线重连
function BaseGame:continueGameCallFunc()
    --游戏开启的标志
    self.m_action = self.ACTION_ILDE
end

--消息请求，子类item点击回调
function BaseGame:sendStep(pos)
    if not pos then
        pos = -1
    end
    self.m_pos[#self.m_pos + 1] = pos -- 点击的位置信息
    self:nextStep()
end
--循环判断下一条消息
function BaseGame:nextStep()
    -- release_print(self.m_pos, "self.m_posIndex=="..self.m_posIndex, 3)
    -- release_print("m_action="..self.m_action)
    -- release_print(self.p_contents, "self.p_contents", 3)
    -- release_print(self.p_chose, "self.p_chose", 3)
    if #self.m_pos <= self.m_posIndex then
        return
    end
    if self.m_action ~= self.ACTION_ILDE then
        return
    end
    self.m_posIndex = self.m_posIndex + 1
    self:sendData(self.m_pos[self.m_posIndex])
end
--数据处理完成下一步条件判断
function BaseGame:overStep()
    if self.m_action ~= self.ACTION_RECV then
        return
    end
    if self:isGameOver() then
        self.m_action = self.ACTION_OVER
        self:gameOver()
    else
        self.m_action = self.ACTION_ILDE
        self:nextStep()
    end
end

--使用本地数据
function BaseGame:getLoaclData()
    self.m_machine:parseFeatureData()
    return self.m_machine.m_featureData
end
--使用本地数据需要获取machine
function BaseGame:enableLocalData(machine)
    self.m_machine = machine
    self.m_isLocalData = true
end

--数据发送
function BaseGame:sendData(pos)
    self.m_action = self.ACTION_SEND
    if self.m_isLocalData then
        -- end, 0.5,"BaseGame")
        -- scheduler.performWithDelayGlobal(function()
        self:recvBaseData(self:getLoaclData())
    else
        local httpSendMgr = SendDataManager:getInstance()
        -- 拼接 collect 数据， jackpot 数据
        local messageData = nil
        if self.m_isBonusCollect then
            messageData = {msg = MessageDataType.MSG_BONUS_COLLECT, data = self.m_collectDataList}
        end
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
    end
end

--数据接收
function BaseGame:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action = self.ACTION_RECV
    if featureData.p_status == "START" then
        self:startGameCallFunc()
        return
    end
    --数据赋值
    self.p_contents = featureData.p_contents
    self.p_chose = featureData.p_chose
    self.p_status = featureData.p_status

    --父类计算出当前用户选择的数据
    local selectData = self:getSelectData(featureData)
    --计算数据
    self:calculateData(selectData)

    if featureData.p_status == "CLOSED" then
        self:uploadCoins(featureData)

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {featureData.p_bonusWinAmount, GameEffect.EFFECT_BONUS})
    end
end
--结算上传金币信息
function BaseGame:uploadCoins(featureData)
    --TODO 添加服务器消息返回时 钱的添加处理
    print("self.m_serverWinCoins=" .. self.m_serverWinCoins)
end

--处理数据 子类可以继承改写
function BaseGame:getSelectData(featureData)
    --获得选择的数据
    local selectData = nil
    if self:isGameOver() then
        local index = self.p_chose[#self.p_chose] + 1
        selectData = self.p_contents[index]

        -- 适配新的bnous游戏数据读取
        if not selectData then
            selectData = self.p_contents[#self.p_chose]
        end
    else
        selectData = self.p_contents[#self.p_contents]
    end
    return selectData
end

--处理数据
function BaseGame:calculateData(selectData)
    if self.m_isContinue == true then
        -- body
        self.m_posIndex = self.m_posIndex + 1
    end

    --交给子类计算其他数据
    self:recvData(selectData, self:isGameOver())
    --交给子类显示数据
    self:showStep(self.m_pos[self.m_posIndex], selectData)
    --借宿步骤判断下一步
    self:overStep()
end

--开始结束流程
function BaseGame:gameOver(isContinue)
    --默认1秒后弹出其他箱子内容，子类实现
    scheduler.performWithDelayGlobal(
        function()
            self:showOther(isContinue)
        end,
        self.m_otherTime
    )
    --默认3秒后弹出结算面板，子类实现
    scheduler.performWithDelayGlobal(
        function()
            self:showReward(isContinue)
        end,
        self.m_rewardTime
    )
end

--------------------子类继承-------------------
--处理数据 子类可以继承改写
--:calculateData(featureData)
--子类调用
--:getZoomScale(width)获取缩放比例
--:isTouch()item是否可以点击
--:sendStep(pos)item点击回调函数
--.m_otherTime=1      --其他宝箱展示时间
--.m_rewardTime=3     --结算界面弹出时间

--初始化数据  参数子类初始化时自定义
function BaseGame:initViewData()
    --默认3秒后发送start请求
    scheduler.performWithDelayGlobal(
        function()
            self:sendStartGame()
        end,
        3
    )
end

--处理服务器数据
function BaseGame:recvData(selectData, isReward)
    --奖励计算

    if isReward then
    --这里添加结算奖励
    end
end

--服务器数据展示(宝箱奖励展示)
function BaseGame:showStep(pos, selectData)
    --如果是断线重连省略一些飞行动画直接显示结果
    if self.m_isContinue then
    end
end

--弹出结算界面前展示其他宝箱数据
function BaseGame:showOther()
end
--弹出结算奖励
function BaseGame:showReward()
end
------------------------------------------------
return BaseGame
