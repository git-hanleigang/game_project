--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-19 17:24:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-19 17:32:57
FilePath: /SlotNirvana/src/GameModule/NoviceSevenSign/views/NoviceSevenSignDayUI.lua
Description: 新手期 7日签到V2 dayUI
--]]
local NoviceSevenSignDayUI = class("NoviceSevenSignDayUI", BaseView)
local NoviceSevenSignConfig = util_require("GameModule.NoviceSevenSign.config.NoviceSevenSignConfig")

function NoviceSevenSignDayUI:initDatas(_dayData)
    NoviceSevenSignDayUI.super.initDatas(self)

    self._dayData = _dayData
    self._day = self._dayData:getDay()
end

function NoviceSevenSignDayUI:getCsbName()
    return string.format("DailyBonusNoviceResV2/csd/Day%s.csb", self._day)
end

function NoviceSevenSignDayUI:initUI()
    NoviceSevenSignDayUI.super.initUI(self)

    -- 奖励倍数
    self:initMultiLbUI()
    -- 礼包
    self:initGiftUI()
    -- 状态
    self:initStatus()
end

-- 奖励倍数
function NoviceSevenSignDayUI:initMultiLbUI()
    if self._day == 7 then
        local parent = self:findChild("node_baodian")
        self._gainMultiAct = util_createAnimation("DailyBonusNoviceResV2/csd/node_baodian.csb")
        parent:addChild(self._gainMultiAct)
        self._gainMultiAct:setVisible(false)
    end
    local multi = self._dayData:getMultiple() 
    self:updateMultiUI(multi)
end
function NoviceSevenSignDayUI:updateMultiUI(_multi)
    _multi = _multi or self._dayData:getMultiple() 
    local lbMulti = self:findChild("lb_multipler")
    lbMulti:setString("+" .. _multi)
end

-- 礼包
function NoviceSevenSignDayUI:initGiftUI()
    local parent = self:findChild("node_gift")
    local giftView = util_createView("GameModule.NoviceSevenSign.views.NoviceSevenSignDayGiftUI", self._dayData)
    parent:addChild(giftView)
    self._giftView = giftView
end

-- 状态
function NoviceSevenSignDayUI:initStatus()
    local status = self._dayData:getStatus()
    self:updateStatus(status)
end
function NoviceSevenSignDayUI:updateStatus(status)
    local actName = ""
    local bLoop = false
    local cb
    if status == NoviceSevenSignConfig.DAY_STATUS.LOCK then
        actName = "idle"
        bLoop = true
        if self._dayData:checkMissed() then
            actName = "idle3"
            bLoop = false
        end
    elseif status == NoviceSevenSignConfig.DAY_STATUS.UNLOCK then
        actName = "idle2"
        bLoop = true
    elseif status == NoviceSevenSignConfig.DAY_STATUS.COLLECTED then
        actName = "idle4"
    elseif status == NoviceSevenSignConfig.DAY_STATUS.TO_UNLOCK then
        actName = "idle"
        bLoop = false
        cb = function()
            self:updateStatus(NoviceSevenSignConfig.DAY_STATUS.UNLOCK)
        end
    elseif status == NoviceSevenSignConfig.DAY_STATUS.GO_COLLECT then
        actName = "dagou"
        bLoop = false
        cb = function()
            self:updateStatus(NoviceSevenSignConfig.DAY_STATUS.COLLECTED)
        end
    end
    self._status = status
    self:runCsbAction(actName, bLoop, cb, 60)
end

function NoviceSevenSignDayUI:getStatus()
    return self._status
end
function NoviceSevenSignDayUI:getDay()
    return self._day
end

-- 检查 这天是否可领取
function NoviceSevenSignDayUI:checkSendCollectReq()
    if self._bCollecting then
        return
    end
    if self._status == NoviceSevenSignConfig.DAY_STATUS.LOCK then
        if self._dayData:checkUnlock() then
            self:updateStatus(NoviceSevenSignConfig.DAY_STATUS.TO_UNLOCK)
        end
    elseif self._status == NoviceSevenSignConfig.DAY_STATUS.UNLOCK then
        G_GetMgr(G_REF.NoviceSevenSign):sendCollectReq()
    end
end

-- 领取成功
function NoviceSevenSignDayUI:onRecieveCollectedReqEvt(_receiveData)
    if self._status ~= NoviceSevenSignConfig.DAY_STATUS.UNLOCK then
        return
    end

    self._bCollecting = true
    self._receiveData = _receiveData
    self._giftView:playFlyAct(_receiveData)
end

-- 收集签到到天 倍数
function NoviceSevenSignDayUI:onFlyColDayMultiEvt()
    if self._status ~= NoviceSevenSignConfig.DAY_STATUS.UNLOCK then
        return
    end

    if self._day == 7 then
        self:updateStatus(NoviceSevenSignConfig.DAY_STATUS.GO_COLLECT)
        return
    end

    -- 不是第7天 飞粒子到 第7天倍数上
    self:runCsbAction("fly_lizi", false, function()
        self:updateStatus(NoviceSevenSignConfig.DAY_STATUS.GO_COLLECT)
    end, 60)
end

-- 获取倍数的世界坐标
function NoviceSevenSignDayUI:getFlyPosWorld()
    local lbMulti = self:findChild("lb_multipler")
    return lbMulti:convertToWorldSpaceAR(cc.p(0, 0))
end

-- 获得倍数 动画
function NoviceSevenSignDayUI:playGainMultiAct()
    if self._gainMultiAct then
        self._gainMultiAct:setVisible(true)
        self._gainMultiAct:playAction("start", false, function()
            self._gainMultiAct:setVisible(false)
        end, 60)
    end
end
return NoviceSevenSignDayUI