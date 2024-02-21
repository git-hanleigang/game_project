---
--smy
--2018年4月26日
--SpacePupBonusPickView.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "SpacePupPublicConfig"
local SpacePupBonusPickView = class("SpacePupBonusPickView",BaseGame )

SpacePupBonusPickView.m_isOver = false

function SpacePupBonusPickView:initUI(machine)
    self:createCsbNode("SpacePup/Pick.csb")

    self.m_machine = machine

    self:initData()

    self:runCsbAction("idleframe", true)

    self.m_winView = util_createView("CodeSpacePupSrc.SpacePupPickSrc.SpacePupBonusPickWinView")
    self.m_machine:addChild(self.m_winView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_winView:setVisible(false)

    for i=1, self.m_starTotalCount do
        self.m_starNodeAni[i] = util_createView("CodeSpacePupSrc.SpacePupPickSrc.SpacePupBonusStarItemBall",self, i)
        self.m_textNodeAni[i] = util_createView("CodeSpacePupSrc.SpacePupPickSrc.SpacePupBonusStarItemCoins",self, i)
        self:findChild("Node_coins_"..i):addChild(self.m_textNodeAni[i])
        self:findChild("Node_star_"..i):addChild(self.m_starNodeAni[i])
        self.m_textNodeAni[i]:setVisible(false)
    end

    self.m_winnerNode = util_createAnimation("SpacePup_winner.csb")
    self:findChild("Node_winer"):addChild(self.m_winnerNode)

    self.m_pickNode = util_createAnimation("SpacePup_pickbar.csb")
    self:findChild("Node_pick"):addChild(self.m_pickNode)

    self.m_liziNode = self:findChild("Node_lizi")

    self.m_winCoinsText = self.m_winnerNode:findChild("m_lb_coins")

    self.m_pickText = self.m_pickNode:findChild("m_lb_num")
    self.m_pickTextLight = self.m_pickNode:findChild("m_lb_num_0")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function SpacePupBonusPickView:initData()
    --1-16索引对应的星球
    self.m_starBallConfig = {1, 1, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 6, 6, 7, 8}
    self.m_starTypeCount = 8
    self.m_starTotalCount = 16
    self.m_starNodeAni = {}
    self.m_textNodeAni = {}
    self.m_leftPickCount = 10
    self.m_randomGroup = {
        [1] = {1, 3, 6, 9},
        [2] = {2, 4, 8, 14},
        [3] = {5, 7, 11, 16},
        [4] = {10, 12, 13, 15}
    }

    --发送过程中不允许再次点击
    self.m_isClick = true

    --选完后当前的数据
    self.m_curPicaData = nil
    --选完后的数据
    self.m_pickSelectData = nil
    --最后剩余没点的数据
    self.m_pickOtherData = nil
end

function SpacePupBonusPickView:resetDate()
    self.m_totalWinCoins = 0
    self.m_serverTotalWinCoins = 0
    self.m_isClick = true

    for i=1, self.m_starTotalCount do
        local starType = self.m_starBallConfig[i]
        for j=1, self.m_starTypeCount do
            local node = self.m_starNodeAni[i]:findChild("Node_"..j)
            if j == starType then
                node:setVisible(true)
            else
                node:setVisible(false)
            end
        end

        self.m_starNodeAni[i]:initViewAni()
        self.m_textNodeAni[i]:initViewAni()
        self.m_textNodeAni[i]:setVisible(false)
        self.m_starNodeAni[i]:setClickState(true)
    end

    for i=1, self.m_starTotalCount do
        for k, group in pairs(self.m_randomGroup) do
            for j=1, #group do
                if i == group[j] then
                    performWithDelay(self.m_scWaitNode, function()
                        self.m_starNodeAni[i]:initViewAni()
                    end, 10/60*k)
                end
            end
        end
    end
end

function SpacePupBonusPickView:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function SpacePupBonusPickView:onEnter()
    SpacePupBonusPickView.super.onEnter(self)
end

function SpacePupBonusPickView:onExit()
    SpacePupBonusPickView.super.onExit(self)
end

function SpacePupBonusPickView:refreshView(_endCallFunc)
    self.endCallFunc = _endCallFunc
    --初始化界面
    self:resetDate()
end

function SpacePupBonusPickView:refreshPickData(_extra, _onEnter)
    local extra = _extra
    local onEnter = _onEnter
    self.m_leftPickCount = extra.pickLeftTimes
    self.m_curPicaData = extra.curPickSelects
    self.m_pickSelectData = extra.pickSelects
    self.m_pickOtherData = extra.pickOthers
    self.m_isClick = true
    local winAmount = self.m_machine.m_runSpinResultData.p_winAmount
    if self.m_leftPickCount == 0 and winAmount then
        self.m_serverTotalWinCoins = winAmount
        for i=1, self.m_starTotalCount do
            self.m_starNodeAni[i]:setClickState(false)
        end
    end
    self:refreshPick(onEnter)
end

function SpacePupBonusPickView:refreshPick(_onEnter)
    local onEnter = _onEnter

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local avgBet = selfData.avgBet or 0
    local curPickCount = self.m_leftPickCount
    local curPicaData = self.m_curPicaData
    if not onEnter then
        gLobalSoundManager:playSound(PublicConfig.Music_PickStar_FeedBack)
        local curClickPos = tonumber(curPicaData.pos)
        local curPickType = curPicaData.type
        self.m_starNodeAni[curClickPos]:setClickState(false)
        if curPickType == "Multiple" then
            self:refreshRemainPicks()
            local mul = tonumber(curPicaData.value)
            local pickCoins = avgBet * mul
            self.m_starNodeAni[curClickPos]:refreshView(onEnter, "coins")

            self.m_textNodeAni[curClickPos]:setVisible(true)
            self.m_textNodeAni[curClickPos]:refreshView(onEnter, "coins", pickCoins, curPickCount)
        else
            self:refreshRemainPicks(true)
            local pickCount = tonumber(curPicaData.value)
            self.m_starNodeAni[curClickPos]:refreshView(onEnter, "pick")

            self.m_textNodeAni[curClickPos]:setVisible(true)
            self.m_textNodeAni[curClickPos]:refreshView(onEnter, "pick", pickCount, curPickCount)
        end
    else
        --刷新全部的状态
        self:refreshAllStarState(onEnter)
        self:refreshWinCoins()
        self:refreshRemainPicks()
    end
end

function SpacePupBonusPickView:refreshAllStarState(_onEnter)
    local onEnter = _onEnter
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local avgBet = selfData.avgBet or 0
    if self.m_pickSelectData then
        for k, v in pairs(self.m_pickSelectData) do
            local pos = tonumber(v.pos)
            local starType = v.type
            self.m_starNodeAni[pos]:setClickState(false)
            --自定义 1：金币；2：pick
            if starType == "Multiple" then
                local mul = tonumber(v.value)
                local pickCoins = avgBet * mul
                self.m_starNodeAni[pos]:refreshView(onEnter, "coins")
                self.m_totalWinCoins = self.m_totalWinCoins + pickCoins

                self.m_textNodeAni[pos]:setVisible(true)
                self.m_textNodeAni[pos]:refreshView(onEnter, "coins", pickCoins)
            else
                local pickCount = tonumber(v.value)
                self.m_starNodeAni[pos]:refreshView(onEnter, "pick")

                self.m_textNodeAni[pos]:setVisible(true)
                self.m_textNodeAni[pos]:refreshView(onEnter, "pick", pickCount)
            end
        end
    end
end

function SpacePupBonusPickView:flyParticleToCoins(_curIndex, _pickCoins, _curPickCount)
    local curIndex = _curIndex
    local pickCoins = _pickCoins
    local curPickCount = _curPickCount

    --粒子飞行
    local delayTime = 0.3
    local startPos = util_convertToNodeSpace(self:findChild("Node_coins_"..curIndex), self.m_liziNode)
    local endPos = util_convertToNodeSpace(self.m_winnerNode, self.m_liziNode)

    local flyNode = util_createAnimation("SpacePup_pickstar_coin_lizi.csb")
    flyNode:setPosition(startPos.x, startPos.y)
    self.m_liziNode:addChild(flyNode)

    local particle = flyNode:findChild("Particle_1")
    particle:setPositionType(0)
    particle:setDuration(-1)
    particle:resetSystem()
    
    gLobalSoundManager:playSound(PublicConfig.Music_PickStar_CollectCoins)
    util_playMoveToAction(flyNode, delayTime, endPos,function()
        gLobalSoundManager:playSound(PublicConfig.Music_PickStar_CollectFeedBack)
        particle:stopSystem()
        self.m_totalWinCoins = self.m_totalWinCoins + pickCoins
        self:refreshWinCoins()
        self.m_winnerNode:runCsbAction("actionframe", false, function()
            self:judgeIsOverGame(curPickCount)
        end)
        performWithDelay(self.m_scWaitNode, function()
            flyNode:removeFromParent()
        end, 0.5)
    end)
end

function SpacePupBonusPickView:isCanTouch()
    if self.m_leftPickCount and self.m_leftPickCount > 0 and self.m_isClick then
        return true
    end
    return false
end

function SpacePupBonusPickView:judgeIsOverGame(_curPickCount)
    local curPickCount = _curPickCount
    local delayTime = 60/30 --延时2s
    if curPickCount == 0 then
        --所有位置
        local tblTotalData = {}
        for i=1, 16 do
            table.insert(tblTotalData, i)
        end
        --筛除已有的位置
        if self.m_pickSelectData then
            for k, v in pairs(self.m_pickSelectData) do
                local pos = tonumber(v.pos)
                for j=1, #tblTotalData do
                    local existPos = tblTotalData[j]
                    if existPos == pos then
                        table.remove(tblTotalData, j)
                        break
                    end
                end
            end
        end

        --剩余的位置随机匹配奖励
        if self.m_pickOtherData and #self.m_pickOtherData > 0 then
            local totalBet = globalData.slotRunData:getCurTotalBet()
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local avgBet = 0
            if selfData and selfData.avgBet then
                avgBet = selfData.avgBet
            end
            for k, v in pairs(self.m_pickOtherData) do
                local randomPos = tblTotalData[k]
                local starType = v.type
                if randomPos then
                    if starType == "Multiple" then
                        local mul = tonumber(v.value)
                        local pickCoins = avgBet * mul
                        self.m_starNodeAni[randomPos]:playDarkAni()
                        self.m_textNodeAni[randomPos]:setVisible(true)
                        self.m_textNodeAni[randomPos]:playDarkAni("coins", pickCoins)
                    else
                        local pickCount = tonumber(v.value)
                        self.m_starNodeAni[randomPos]:playDarkAni()
                        self.m_textNodeAni[randomPos]:setVisible(true)
                        self.m_textNodeAni[randomPos]:playDarkAni("pick", pickCount)
                    end
                end
            end
            performWithDelay(self.m_scWaitNode, function()
                self:pickGameOver()
            end, 15/60+delayTime)
        else
            performWithDelay(self.m_scWaitNode, function()
                self:pickGameOver()
            end, delayTime)
        end
    end
end

function SpacePupBonusPickView:pickGameOver()
    self.m_winView:setVisible(true)
    if self.m_serverTotalWinCoins and self.m_serverTotalWinCoins > 0 then
        self.m_totalWinCoins = self.m_serverTotalWinCoins
        self:refreshWinCoins()
    end
    
    local cutSceneFunc = function()
        self.m_machine:bonusPickGameOver(self.m_totalWinCoins, self.endCallFunc, function()
            self:hideSelf()
        end)
    end
    
    globalMachineController:playBgmAndResume(PublicConfig.Music_Pick_OverStart, 4, 0, 1)
    self.m_machine:clearCurMusicBg()
    self.m_winView:refreshRewardType(self.m_totalWinCoins, cutSceneFunc)
    self.m_winView:runCsbAction("start",false, function()
        self.m_winView:setClickState(true)
        self.m_winView:runCsbAction("idle", true)
    end)
end

--数据接收
--选择次数返回的数据
function SpacePupBonusPickView:recvBaseData(featureData)

    local bonusdata = featureData.p_bonus or {}

    if bonusdata.extra and bonusdata.extra.pickPhase == "PICK_REWARD" then
        self:refreshPickData(bonusdata.extra)
    end
end

function SpacePupBonusPickView:refreshWinCoins()
    if self.m_totalWinCoins == 0 then
        self.m_winCoinsText:setString("")
    else
        self.m_winCoinsText:setString(util_formatCoins(self.m_totalWinCoins,50))
    end
    self:updateLabelSize({label=self.m_winCoinsText,sx=0.45,sy=0.45},677)
end

function SpacePupBonusPickView:refreshRemainPicks(_isPick)
    local isPick = _isPick
    if self.m_leftPickCount <= 2 and self.m_leftPickCount ~= 0 then
        if isPick then
            self.m_pickNode:runCsbAction("actionframe", false, function()
                self.m_pickNode:runCsbAction("idle", true)
            end)
        else
            self.m_pickNode:runCsbAction("idle", true)
        end
    else
        if isPick then
            gLobalSoundManager:playSound(PublicConfig.Music_PickStar_AddTimes)
            self.m_pickNode:runCsbAction("actionframe", false, function()
                self.m_pickNode:runCsbAction("idleframe", true)
            end)
        else
            self.m_pickNode:runCsbAction("idleframe", true)
        end
    end
    self.m_pickText:setString(self.m_leftPickCount)
    self.m_pickTextLight:setString(self.m_leftPickCount)
end

--数据发送(选择次数)
function SpacePupBonusPickView:sendData(pos)
    self.m_isClick = false
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    local strPos = tostring(pos)
    --PICK_REWARD
    local sendData = {"PICK_REWARD", strPos}
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT , data= sendData , mermaidVersion = 0 } 
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--[[
    接受网络回调
]]

function SpacePupBonusPickView:featureResultCallFun(param)
    if self:isVisible() and param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_runSpinResultData = spinData.result
            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData()
        else
            -- dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

function SpacePupBonusPickView:hideSelf()
    self:setVisible(false)
end

return SpacePupBonusPickView
