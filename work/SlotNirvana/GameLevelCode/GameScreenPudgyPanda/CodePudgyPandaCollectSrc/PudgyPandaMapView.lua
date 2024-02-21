---
--xcyy
--PudgyPandaMapView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaMapView = class("PudgyPandaMapView",BaseGame)

PudgyPandaMapView.m_totalLen = 800
PudgyPandaMapView.m_isClick = false
PudgyPandaMapView.m_collectRatio = {3, 4, 5} --三种free在进度条上的收集比例

function PudgyPandaMapView:initUI(_machine)

    self:createCsbNode("PudgyPanda/CollectMap.csb")

    self.m_machine = _machine

    self.m_titleSpine = util_spineCreate("PudgyPanda_FGstartTB",true,true)
    self:findChild("Node_title5_idle"):addChild(self.m_titleSpine)
    util_spinePlay(self.m_titleSpine, "title5_idle", true)

    self.m_mapItemNodeAni = {}
    for i=1, 3 do
        self.m_mapItemNodeAni[i] = util_createView("CodePudgyPandaCollectSrc.PudgyPandaMapItem", self.m_machine, self, i)
        self:findChild("Node_FreeType"):addChild(self.m_mapItemNodeAni[i])
    end

    -- 收集进度
    self.m_nodeProcess = self:findChild("Node_Process")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function PudgyPandaMapView:onEnter()
    PudgyPandaMapView.super.onEnter(self)
end

function PudgyPandaMapView:onExit()
    PudgyPandaMapView.super.onExit(self)
end

function PudgyPandaMapView:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

--默认按钮监听回调
function PudgyPandaMapView:clickFunc(sender)
    local name = sender:getName()

    if name == "Button" and self:isCanTouch() then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_PudgyPanda_click)
        self:hideSelf()
    end
end

-- 设置初始位置和初始进度
function PudgyPandaMapView:initProcess(_curCollectNum)
    local curCollectNum = _curCollectNum
    self.collectTotalNum = self.m_machine.m_baseCollectConfig[3]
    self.intervalLen = {}
    -- 收集一个的长度（像素）
    for i=1, 3 do
        local totalLen = self.m_totalLen / (self.m_collectRatio[1] + self.m_collectRatio[2] + self.m_collectRatio[3]) * self.m_collectRatio[i]
        if i == 1 then
            self.intervalLen[i] = totalLen / self.m_machine.m_baseCollectConfig[i]
        else
            self.intervalLen[i] = totalLen / (self.m_machine.m_baseCollectConfig[i] - self.m_machine.m_baseCollectConfig[i-1])
        end
    end

    -- 收集一个的长度（像素）（用于三种free标志的位置）特殊
    local varLen = {}
    for i=1, 3 do
        local totalLen = (self.m_totalLen * 0.67) / (self.m_collectRatio[1] + self.m_collectRatio[2] + self.m_collectRatio[3]) * self.m_collectRatio[i]
        if i == 1 then
            varLen[i] = totalLen / self.m_machine.m_baseCollectConfig[i]
        else
            varLen[i] = totalLen / (self.m_machine.m_baseCollectConfig[i] - self.m_machine.m_baseCollectConfig[i-1])
        end
    end

    for i=1, 3 do
        -- 根据总长度算出freeGame、superGame、megaGame所在的位置
        local freeTypePosX = 0
        freeTypePosX = freeTypePosX + varLen[1] * self.m_machine.m_baseCollectConfig[1]
        if i > 1 then
            for index = 2, i do
                freeTypePosX = freeTypePosX + varLen[index] * (self.m_machine.m_baseCollectConfig[index] - self.m_machine.m_baseCollectConfig[index-1])
            end
        end
        self.m_mapItemNodeAni[i]:setPositionX(freeTypePosX)
    end

    -- 收集的进度
    self:setCurProcess(curCollectNum, true)
end

function PudgyPandaMapView:showMap(_curProcess)
    self.m_curProcess = _curProcess

    self:setCurProcess(_curProcess)
    self:setCilckState(false)
    self:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_CollectBar_ShowStart)
    self:runCsbAction("start",false, function()
        self:runCsbAction("idle",true)
        self:setCilckState(true)
    end)
end

-- 设置当前进度
function PudgyPandaMapView:setCurProcess(_curCollectNum)
    local curCollectNum = _curCollectNum
    local curPosX = 0
    if curCollectNum <= self.m_machine.m_baseCollectConfig[1] then
        curPosX = curCollectNum * self.intervalLen[1]
    elseif curCollectNum <= self.m_machine.m_baseCollectConfig[2] then
        curPosX = self.m_machine.m_baseCollectConfig[1] * self.intervalLen[1] + (curCollectNum - self.m_machine.m_baseCollectConfig[1]) * self.intervalLen[2]
    else
        curPosX = self.m_machine.m_baseCollectConfig[1] * self.intervalLen[1] + (self.m_machine.m_baseCollectConfig[2] - self.m_machine.m_baseCollectConfig[1]) * self.intervalLen[2]
        + (curCollectNum - self.m_machine.m_baseCollectConfig[2]) * self.intervalLen[3]
    end
    self.m_nodeProcess:setPositionX(curPosX)

    -- 判断当前进度是否已经解锁
    for i=1, 3 do
        if curCollectNum >= self.m_machine.m_baseCollectConfig[i] then
            self.m_mapItemNodeAni[i]:setUnLock(i)
        else
            self.m_mapItemNodeAni[i]:setIdle()
        end
    end
end

function PudgyPandaMapView:sendFreeTypeData(_selectIndex)
    self:setCilckState(false)
    self:sendData(_selectIndex)
end

function PudgyPandaMapView:sendData(_selectIndex)
    local selectIndex = _selectIndex
    local httpSendMgr = SendDataManager:getInstance()
    print("发送的类型索引是-" .. selectIndex)
    -- local messageData={msg=MessageDataType.MSG_BONUS_SELECT, data = selectIndex}
    local messageData={msg=MessageDataType.MSG_BONUS_SPECIAL, choose = selectIndex}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function PudgyPandaMapView:receiveData()
    self.m_machine:addPlayEffect()
    self:hideSelf(true)
end

function PudgyPandaMapView:featureResultCallFun(param)
    if self:isVisible() and param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "SPECIAL" then
            self.m_runSpinResultData = spinData.result
            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)
            self.m_featureData:parseFeatureData(spinData.result)
            self:receiveData()
            -- self:recvBaseData(isSuperFreeGame)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            -- self:recvBaseData()
        else
            -- dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

function PudgyPandaMapView:setCilckState(_isClick)
    self.m_isClick = _isClick
end

function PudgyPandaMapView:isCanTouch()
    return self.m_isClick
end

function PudgyPandaMapView:hideSelf(_isReceive)
    for i=1, 3 do
        self.m_mapItemNodeAni[i]:setCilckState(false) 
    end
    self:setCilckState(false)
    self.m_machine.m_collectView:setCilckState(true)
    local isReceive = _isReceive
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_CollectBar_ShowOver)
    self:runCsbAction("over",false, function()
        if isReceive then
            self.m_machine:playGameEffect()
        end
        self:setVisible(false)
    end)
end

return PudgyPandaMapView
