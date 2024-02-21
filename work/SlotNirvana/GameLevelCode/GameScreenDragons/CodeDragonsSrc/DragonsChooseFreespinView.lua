---
--xcyy
--2018年5月23日
--DragonsChooseFreespinView.lua

local BaseGame = util_require("base.BaseGame")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local DragonsChooseFreespinView = class("DragonsChooseFreespinView", BaseGame)
DragonsChooseFreespinView.freespinData1 = {{5, 10, 15, 30}, {8, 8, 10, 15}, {10, 5, 8, 10}, {15, 3, 5, 8}, {20, 2, 3, 5}}
DragonsChooseFreespinView.freespinData2 = {{20, 2, 3, 5}, {15, 3, 5, 8}, {10, 5, 8, 10}, {8, 8, 10, 15}, {5, 10, 15, 30}}

function DragonsChooseFreespinView:initUI()
    self:createCsbNode("Dragons_ChooseFree.csb")
    self:initFreespinView()
    self.m_touchFlag = false
    local node = self:findChild("Node")
    self.m_loop = false
    self.m_randomNum = 1
    self.m_updataAction =
        schedule(
        node,
        function()
            if self.m_loop == false then
                return
            end
            self:playBonusBuling()
        end,
        1
    )
end

-- function DragonsChooseFreespinView:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function DragonsChooseFreespinView:playBonusBuling()
    -- local tag = xcyy.SlotsUtil:getArc4Random() % 6 + 1
    --     while true do
    --         tag = xcyy.SlotsUtil:getArc4Random() % 6 + 1
    --         if self.m_randomNum ~= tag then
    --             self.m_randomNum = tag
    --             break
    --         end
    --     end
    if self.m_randomNum > 6 then
        self.m_randomNum = 1
    end
    tag = self.m_randomNum
    for i = 1, 6 do
        local viewType = self.m_chooseTypeView[i]
        viewType:showTypeBg(false)
    end
    local viewType = self.m_chooseTypeView[tag]
    viewType:showTypeBg(true)
    self.m_randomNum = self.m_randomNum + 1
end

function DragonsChooseFreespinView:chooseFreeSpinType(clickPos)
    if self.m_touchFlag == false then
        return
    end
    self.m_machine:stopMusicBg()
    self.m_touchFlag = false
    self.m_loop = false
    self.m_choosePos = clickPos
    for i = 1, 6 do
        local viewType = self.m_chooseTypeView[i]
        if _type == i then
            -- viewType:runCsbAction("actionframe",false)
        else
            viewType:runCsbAction("yahei", false)
        end
    end
    for i = 1, 6 do
        local viewType = self.m_chooseTypeView[i]
        viewType:showTypeBg(false)
    end
    self:sendData(clickPos)
end

function DragonsChooseFreespinView:initFreespinView()
    self.m_chooseTypeView = {}
    local tag = 4
    for i = 1, 6 do
        local data = {}
        data._type = i
        local viewType = util_createView("CodeDragonsSrc.DragonsChooseTypeView", data)
        self:findChild("Node_" .. i):addChild(viewType)
        viewType:setParent(self)
        viewType:setClickPos(tag)
        table.insert(self.m_chooseTypeView, viewType)
        if i == 6 then
            viewType:setClickPos(5)
        end
        tag = tag - 1
    end
end

function DragonsChooseFreespinView:showFreespinView()
    self.m_touchFlag = true
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    self.m_machine:playChooseMusicBg()
    if selfData and selfData.extraSpinTimes then
        local times = selfData.extraSpinTimes
        self.m_loop = true
        for i = 1, 5 do
            local viewType = self.m_chooseTypeView[i]
            local data = {}
            data[1] = self.freespinData2[i][1] + times
            data[2] = self.freespinData2[i][2]
            data[3] = self.freespinData2[i][3]
            data[4] = self.freespinData2[i][4]
            viewType:setViewData(data)
        end
    end
end

function DragonsChooseFreespinView:playAddExtraEffect()
    self.m_touchFlag = false
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local times = selfData.extraSpinTimes
    for i = 1, 5 do
        performWithDelay(
            self,
            function()
                local viewType = self.m_chooseTypeView[i]
                local num = self.freespinData2[i][1] + times
                viewType:playChangeNumEffect(num)
                self.m_machine:playExtraFreeSpinEffect()
            end,
            i / 3
        )
    end
    performWithDelay(
        self,
        function()
            self.m_machine:playChooseMusicBg()
            self.m_machine:removeExtraFreeSpinEffect()
            self.m_touchFlag = true
            self.m_loop = true
        end,
        2.5
    )
end

function DragonsChooseFreespinView:playChooseFreespinEffect(_type, _times)
    if self.m_choosePos == 5 then
        local viewType = self.m_chooseTypeView[6]
        local data = self.freespinData1[_type + 1]
        viewType:getParent():setLocalZOrder(100)
        local data2 = {}
        data2[1] = _times
        data2[2] = data[2]
        data2[3] = data[3]
        data2[4] = data[4]
        viewType:setViewData(data2)
        gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_mystery.mp3")
        viewType:runCsbAction(
            "gundong",
            false,
            function()
                gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_choose.mp3")
                viewType:runCsbAction(
                    "actionframe",
                    false,
                    function()
                        self.m_func()
                    end
                )
            end
        )
    else
        for i = 1, 5 do
            local viewType = self.m_chooseTypeView[i]
            local clickPos = viewType:getClickPos()
            if clickPos == _type then
                viewType:getParent():setLocalZOrder(100)
                gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_choose.mp3")
                viewType:runCsbAction(
                    "actionframe",
                    false,
                    function()
                        self.m_func()
                    end
                )
            end
        end
    end
end

function DragonsChooseFreespinView:setMachine(machine)
    self.m_machine = machine
end

function DragonsChooseFreespinView:onExit()
    gLobalNoticManager:removeAllObservers(self)
    if self.m_updataAction then
        local node = self:findChild("Node")
        node:stopAction(self.m_updataAction)
        self.m_updataAction = nil
    end
end

--默认按钮监听回调
function DragonsChooseFreespinView:clickFunc(sender)
end

--数据发送
function DragonsChooseFreespinView:sendData(pos)
    self.m_action = self.ACTION_SEND
    self.m_isBonusCollect = true
    local httpSendMgr = SendDataManager:getInstance()

    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, clickPos = pos}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, true)
end

function DragonsChooseFreespinView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        if spinData.action == "FEATURE" then
            self.m_spinDataResult = spinData.result
            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            -- self.m_featureData = self.m_featureData
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end
function DragonsChooseFreespinView:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action = self.ACTION_RECV
    if featureData.p_status == "START" then
        self:startGameCallFunc()
        return
    end
    self.m_featureData = featureData
    if featureData.p_status == "CLOSED" then
        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_bsWinCoins, GameEffect.EFFECT_BONUS})
    else
        local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
        if selfData then
            --extraSpinTimes
            local _type = selfData.freespinType --返回的类型
            local _times = selfData.freespinTotalTimes --总次数
            -- local selectType = selfData.select      --选择的类型
            self:playChooseFreespinEffect(_type, _times)
        end
    end
end

function DragonsChooseFreespinView:setChooseFreespinCall(_func)
    self.m_func = function()
        if _func then
            _func()
        end
    end
end

return DragonsChooseFreespinView
