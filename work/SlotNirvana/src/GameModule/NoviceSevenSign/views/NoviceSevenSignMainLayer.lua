--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-14 12:26:16
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-14 14:25:18
FilePath: /SlotNirvana/src/GameModule/NoviceSevenSign/views/NoviceSevenSignMainLayer.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local NoviceSevenSignMainLayer = class("NoviceSevenSignMainLayer", BaseLayer)
local NoviceSevenSignConfig = util_require("GameModule.NoviceSevenSign.config.NoviceSevenSignConfig")

function NoviceSevenSignMainLayer:initDatas()
    NoviceSevenSignMainLayer.super.initDatas(self)

    self._data = G_GetMgr(G_REF.NoviceSevenSign):getRunningData()
    self._dayViewList = {}
    self._bubbleViewList = {}
    self:setLandscapeCsbName("DailyBonusNoviceResV2/csd/Activity_DailyBonusMain.csb")
    self:setName("NoviceSevenSignMainLayer")
end

function NoviceSevenSignMainLayer:initView()
    -- 每天 UI
    self:initDayCellUI()
end

-- 每天 UI
function NoviceSevenSignMainLayer:initDayCellUI()
    local dayList = self._data:getDayList()
    if #dayList ~= 7 then
        return
    end

    self._dayViewList = {}
    for i=1, 7 do
        local parent = self:findChild("node_day" .. i)
        local cell = util_createView("GameModule.NoviceSevenSign.views.NoviceSevenSignDayUI", dayList[i])
        parent:addChild(cell)
        table.insert(self._dayViewList, cell)
    end
end

function NoviceSevenSignMainLayer:updateTime()
    -- 有领奖弹板 弹板关了在加测
    if gLobalViewManager:getViewByName("NoviceSevenSignRewardLayer") then
        return
    end

    if self._data:isRunning() then
        self:checkSignCollect()
    end
end

function NoviceSevenSignMainLayer:onShowedCallFunc()
    NoviceSevenSignMainLayer.super.onShowedCallFunc(self)

    self:checkSignCollect()
    self._scheduler = schedule(self, util_node_handler(self, self.updateTime), 1)
    self:runCsbAction("idle", true) 
end

function NoviceSevenSignMainLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        if self._data:checkCanCollect() then
            return
        end

        self:closeUI()
    end
end

-- 监测 是否 有可领取
function NoviceSevenSignMainLayer:checkSignCollect()
    if not self._data:isRunning() then
        return
    end

    for _, v in pairs(self._dayViewList) do
        v:checkSendCollectReq()
    end
end

-- 领取成功
function NoviceSevenSignMainLayer:onRecieveCollectedReqEvt(_receiveData)
    for _, v in pairs(self._dayViewList) do
        v:onRecieveCollectedReqEvt(_receiveData)
    end
end
function NoviceSevenSignMainLayer:onFlyColDayMultiEvt(_receiveData)
    local dayView
    for _, v in pairs(self._dayViewList) do
        local status = v:getStatus()
        if status == NoviceSevenSignConfig.DAY_STATUS.UNLOCK then
            dayView = v
            break
        end
    end

    if not dayView then
        return
    end

    -- 播放 签到天的 领奖动画
    dayView:onFlyColDayMultiEvt()
    if dayView:getDay() == 7 then
        -- 第7天 不用收集 倍数
        return
    end

    -- 粒子
    local startPosW = dayView:getFlyPosWorld()
    local endPosW = self._dayViewList[7]:getFlyPosWorld()
    local efView = util_createView("GameModule.NoviceSevenSign.views.NoviceSevenSignFlyEfUI")
    self:addChild(efView)
    efView:playFlyAct(startPosW, endPosW, function()
        -- 更新 第7 天的 倍数
        local dayData = self._data:getDayData(7)
        local multi = dayData:getMultiple()
        self._dayViewList[7]:updateMultiUI(multi)
        self._dayViewList[7]:playGainMultiAct()
    end)
end

--监听
function NoviceSevenSignMainLayer:registerListener()
    NoviceSevenSignMainLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onRecieveCollectedReqEvt", NoviceSevenSignConfig.EVENT_NAME.ONRECIEVE_COLLECT_NOVICE_SIGN_DAY_REWARD)
    gLobalNoticManager:addObserver(self, "onFlyColDayMultiEvt", NoviceSevenSignConfig.EVENT_NAME.NOTIFY_COLLECT_NOVICE_SENVEN_SIGN_DAY_MULTI) -- 收集签到到天 倍数
end

function NoviceSevenSignMainLayer:clearScheduler()
    if self._scheduler then
        self:stopAction(self._scheduler)
        self._scheduler = nil
    end
end

function NoviceSevenSignMainLayer:closeUI()
    if self.bClose then
        return
    end
    self.bClose = true

self:clearScheduler()
    NoviceSevenSignMainLayer.super.closeUI(self)
end

function NoviceSevenSignMainLayer:showGiftBubbleView(_posW, _day)
    local bExit = false
    for k, _bubbleView in pairs(self._bubbleViewList) do
        if not tolua.isnull(_bubbleView) then
            local bCurDay = _day == _bubbleView:getDay()
            if bCurDay then
                bExit = true
            end
            _bubbleView:hideTip(not bCurDay)
        end
    end

    if bExit then
        return
    end
    self._bubbleViewList = {}
    local parent = self:findChild("node_dayParent")
    local bubbleView = util_createView("GameModule.NoviceSevenSign.views.NoviceSevenSignDayGiftBubbleUI", _day)
    local posL = parent:convertToNodeSpaceAR(_posW)
    bubbleView:move(posL)
    parent:addChild(bubbleView)
    table.insert(self._bubbleViewList, bubbleView)
    bubbleView:showTip()  
end

return NoviceSevenSignMainLayer