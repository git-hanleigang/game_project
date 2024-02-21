
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")

local ApolloMapMainView = class("ApolloMapMainView",BaseGame )

ApolloMapMainView.TOWN_QIN = 2
ApolloMapMainView.TOWN_JIAN = 7
ApolloMapMainView.TOWN_GEZI = 13
ApolloMapMainView.TOWN_PALACE = 20

ApolloMapMainView.TOP_ZORDER = 50

ApolloMapMainView.BIG_LEVEL_ADD_Y = 44

ApolloMapMainView.MAX_INDEX = 19 -- 最后一个位置不用创建

ApolloMapMainView.m_click = false

function ApolloMapMainView:initUI(machine)
    self.m_machine = machine

    self:createCsbNode("Apollo/BonusGameGame_1.csb")

    self.MAX_INDEX = 19
    self:initLittleUINode()

    self:addClick(self:findChild("click"))

    self.m_tipApollo = util_createAnimation("Apollo_zhizhen.csb")
    self:findChild("zhizhen_node"):addChild(self.m_tipApollo,1000)
    self.m_tipApollo:setVisible(false)
    self.m_tipApollo:setPosition(0,0)
    self.m_tipApollo:runCsbAction("idleframe",true)

    --添加触发特效
    self["effect_"..self.TOWN_QIN] = util_createAnimation("Apollo/BonusGameGame_map_chufa.csb")
    self:findChild("Node_chufa_0"):addChild(self["effect_"..self.TOWN_QIN])

    self["effect_"..self.TOWN_JIAN] = util_createAnimation("Apollo/BonusGameGame_map_chufa.csb")
    self:findChild("Node_chufa_1"):addChild(self["effect_"..self.TOWN_JIAN])

    self["effect_"..self.TOWN_GEZI] = util_createAnimation("Apollo/BonusGameGame_map_chufa.csb")
    self:findChild("Node_chufa_2"):addChild(self["effect_"..self.TOWN_GEZI])

    self["effect_"..self.TOWN_PALACE] = util_createAnimation("Apollo/BonusGameGame_map_chufa_0.csb")
    self:findChild("Node_chufa_3"):addChild(self["effect_"..self.TOWN_PALACE])
end

function ApolloMapMainView:sortUiDianZOrder()
    for i=1,self.MAX_INDEX do
        local xiaojinbi = self:findChild("xiaojinbi_"..i)
        if xiaojinbi then
            xiaojinbi:setLocalZOrder(i)
        end
    end

    local zhizhen_node = self:findChild("zhizhen_node")
    if zhizhen_node then
        zhizhen_node:setLocalZOrder(self.MAX_INDEX + 1)
    end

    local zhizhen = self:findChild("zhizhen")
    if zhizhen then
        zhizhen:setLocalZOrder(self.MAX_INDEX + 2)
    end
end

function ApolloMapMainView:showMap( _isBonus , _func )
    self:sortUiDianZOrder()

    self:runCsbAction("idleframe")
    self:setVisible(true)

    if _isBonus then
        -- bonus触发不允许点击
        self.m_click = true
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            self:sendData() -- 服务器请求消息
            waitNode:removeFromParent()
        end,1)
    else
        self.m_click = false
        self:findChild("click"):setVisible(true)
    end
    self.m_endCall = _func
end

function ApolloMapMainView:runPointAni( _node , _name , _loop ,_func )
    if  _node.m_isSpine then
        util_spinePlay(_node,_name,_loop)
        if not _loop then
            util_spineEndCallFunc(_node,_name,_func)
        end
    else
        _node:runCsbAction(_name,_loop,_func,60)
    end
end

function ApolloMapMainView:updateLittleUINodeAct( _nodePos )
    -- _nodePos 真实有效位置是从位置1开始
    -- node m_jinbi_ 有效位置是从0开始的

    local pointIndex = nil

    for i=1,self.MAX_INDEX do
        local uiIndex = i
        local node = self["m_jinbi_"..uiIndex]
        self:runPointAni( node , "idleframe"  )
        if i <= _nodePos then
            if not node.m_isSpine then
                self:runPointAni( node , "idleframe1" )
            end
            if i == self.TOWN_QIN or i == self.TOWN_JIAN or i  == self.TOWN_GEZI then
                self:findChild("Apollo_map_gou"..i):setVisible(true)
                self:findChild("chengbei_"..i):setVisible(false)
            end
            if i == _nodePos then
                pointIndex = i
            end
        else
            if i == self.TOWN_QIN or i == self.TOWN_JIAN or i  == self.TOWN_GEZI then
                self:findChild("Apollo_map_gou"..i):setVisible(false)
                self:findChild("chengbei_"..i):setVisible(true)
            end
        end
    end

    self.m_tipApollo:setVisible(true)

    local pos = nil

    if pointIndex then
        pos = cc.p(self["m_jinbi_"..pointIndex ]:getParent():getPosition())
        if pointIndex == self.TOWN_QIN or pointIndex == self.TOWN_JIAN or pointIndex  == self.TOWN_GEZI then
            pos = cc.p(pos.x,pos.y + self.BIG_LEVEL_ADD_Y )
        end
    else
        pos = cc.p(self:findChild("zhizhen"):getPosition())
    end

    self:findChild("zhizhen_node"):setPosition(pos)
end

function ApolloMapMainView:getCsbName( _index )
    local name = nil
    local isSpine = false

    if _index == self.TOWN_QIN then
        name = "Apollo_map_xiaojinbi"
        isSpine = false
    elseif _index == self.TOWN_JIAN then
        name = "Apollo_map_xiaojinbi"
        isSpine = false
    elseif _index == self.TOWN_GEZI then
        name = "Apollo_map_xiaojinbi"
        isSpine = false
    else
        name = "Apollo_map_xiaojinbi"
    end

    return name,isSpine

end

function ApolloMapMainView:initLittleUINode()
    for i = 1,self.MAX_INDEX do
        local uiIndex = i
        local csbName,isSpine = self:getCsbName( uiIndex)
        local fatherNodeName = "xiaojinbi_" .. uiIndex

        if isSpine then
            self["m_jinbi_"..uiIndex] = util_spineCreate(csbName,true,true)
            self["m_jinbi_"..uiIndex].m_isSpine = isSpine
        else
            self["m_jinbi_"..uiIndex] = util_createAnimation(csbName..".csb")
            self["m_jinbi_"..uiIndex].m_isSpine = isSpine
        end

        self:findChild(fatherNodeName):addChild(self["m_jinbi_"..uiIndex])
    end
end

function ApolloMapMainView:onEnter()
    ApolloMapMainView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:closeSelfChooseOneEnd()
    end,"ApolloMapMainView_closeSelfChooseOneEnd")
end

function ApolloMapMainView:onExit()
    ApolloMapMainView.super.onExit(self)
end

function ApolloMapMainView:closeUi( _func )
    self:setVisible(false)
    self.m_tipApollo:setVisible(false)

    if _func then
        _func()
    end
end

--默认按钮监听回调
function ApolloMapMainView:clickFunc(_sender)
    local name = _sender:getName()
    local tag = _sender:getTag()

    if self.m_click then
        return
    end

    self.m_click = true

    if name == "click" then
        self.m_machine:showMapGuoChang(function ()
            self:closeUi( function()
                self.m_machine:clearCurMusicBg()
                self.m_machine:resetMusicBg(true)
                self.m_machine:removeSoundHandler() -- 移除监听
                self.m_machine:reelsDownDelaySetMusicBGVolume()
            end)
        end,function ()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end)
    end
end

function ApolloMapMainView:QiuBiTeJump( _pos,_func)
    local time = 0.37
    local actionList = {}
    actionList[#actionList + 1] = cc.JumpTo:create(time,_pos,60,1)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if _func then
            _func()
        end
    end)
    local sq = cc.Sequence:create(actionList)
    self:findChild("zhizhen_node"):runAction(sq)
    gLobalSoundManager:playSound("ApolloSounds/music_Apollo_zhizhentiao.mp3",false)
end

function ApolloMapMainView:beginLittleUiQiuBiTeAct(_nodePos,_func )
    self.m_tipApollo:setVisible(true)
    local endPos = cc.p(self:findChild("xiaojinbi_" .. _nodePos):getPosition())
    if _nodePos == self.TOWN_QIN or _nodePos == self.TOWN_JIAN or _nodePos  == self.TOWN_GEZI then
        endPos = cc.p(endPos.x,endPos.y + self.BIG_LEVEL_ADD_Y )
    end

    self:QiuBiTeJump( endPos,function()
        if _func then
            _func()
        end
    end)
end


--[[
    +++++++++++++
    触发游戏时向服务器请求数据
]]

--数据发送
function ApolloMapMainView:sendData()
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil
    if self.m_isBonusCollect then
        messageData={msg = MessageDataType.MSG_BONUS_COLLECT , data = self.m_collectDataList}
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end
function ApolloMapMainView:featureResultCallFun(param)
    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_totleWimnCoins = spinData.result.winAmount
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

            if spinData.action == "FEATURE" then
                self.m_featureData:parseFeatureData(spinData.result)
                self.m_spinDataResult = spinData.result

                self.m_machine:SpinResultParseResultData( spinData)
                self:recvBaseData(self.m_featureData)
            end
        else
            -- 处理消息请求错误情况
            gLobalViewManager:showReConnect(true)
        end
    end
end

function ApolloMapMainView:checkBigLevel(_index )
    local curPos = _index
    if curPos == self.TOWN_QIN then
        return true
    elseif curPos == self.TOWN_JIAN then
        return true
    elseif curPos == self.TOWN_GEZI then
        return true
    elseif curPos == self.TOWN_PALACE then
        return true
    end

    return false
end

--数据接收 只用作一进bonus向服务器请求最终数据
function ApolloMapMainView:recvBaseData(featureData)
    self.m_action = self.ACTION_RECV

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local cellTable = selfdata.cellTable
    local bonusPosition = self.m_machine.m_bonusPosition or 0
    if bonusPosition == 0 and cellTable and #cellTable > 0 then
        -- 说明是地图最后一次的收集
        bonusPosition = 20
    end
    self:beginLittleUiQiuBiTeAct(bonusPosition,function()

        local bigLevel = self:checkBigLevel(bonusPosition )

        if bigLevel then
            local enterClickMain = function()
                 -- 大关触发 宫殿点击玩法
                self.m_machine:showBonusClickGameGuoChang(function()
                    self:closeUi()
                    self.m_machine:triggerBonusClickGame()
                end)
            end
            gLobalSoundManager:playSound("ApolloSounds/music_Apollo_bigLevelChufa.mp3",false)
            if bonusPosition == 20 then
                self["effect_"..bonusPosition]:playAction("open",false,function ()
                    self["effect_"..bonusPosition]:playAction("actionframe",false,function ()
                        enterClickMain()
                    end)
                end)
            else
                self["effect_"..bonusPosition]:playAction("actionframe",false,function ()
                    enterClickMain()
                end)
            end
        else
            -- 小关三选一
            performWithDelay(self,function ()
                gLobalNoticManager:postNotification("GameScreenApolloMachine_showChooseOneView")
            end,0.5)
        end

        if bonusPosition ~= 20 then
            -- local fatherNode = self:findChild("xiaojinbi_" .. bonusPosition)
            -- if fatherNode then
            --     fatherNode:setLocalZOrder(self.TOP_ZORDER)
            -- end

            local node = self["m_jinbi_"..bonusPosition]

            if not (bonusPosition == self.TOWN_QIN or bonusPosition == self.TOWN_JIAN or bonusPosition  == self.TOWN_GEZI)  then

                local lab = node:findChild("m_lb_coins")
                if lab then
                    lab:setString(util_formatCoins(self.m_serverWinCoins,3))
                end
            end

            self:runPointAni( node , "actionframe",false)
        end
    end )
end

function ApolloMapMainView:checkIsOver()
    local bonusStatus = self.p_status

    if bonusStatus == "CLOSED" then
        return true
    end

    return false
end

--开始结束流程
function ApolloMapMainView:gameOver(isContinue)

end

--弹出结算奖励
function ApolloMapMainView:showReward()

end

--小关结束关闭界面
function ApolloMapMainView:closeSelfChooseOneEnd()
    self:closeUi( function()
        self.m_machine:clearCurMusicBg()
        self.m_machine:resetMusicBg(true)
        self.m_machine:removeSoundHandler() -- 移除监听
        self.m_machine:reelsDownDelaySetMusicBGVolume()

        if self.m_machine.m_BonusGameOverCall then
            self.m_machine.m_BonusGameOverCall()
        end
    end )
end


return ApolloMapMainView