--[[
    弹版管理
    time:2019-08-21 20:23:47
]]
-- 弹框点位定义
GD.PopViewPos = {
    -- PopPos_FirstLogin = "1",
    -- PopPos_ReturnHall = "2",
    -- PopPos_CloseStore = "3",
    -- PopPos_SpinNoMoney = "4",
    -- 点击促销
    -- PopPos_ClickSale = "5",
    -- 点击Hot
    -- PopPos_ClickHot = "6",
    -- 升级
    PopPos_LevelUp = "7"
    -- 轮播页
    -- PopPos_Carousel = "8",
    -- Spin结果
    -- PopPos_SpinResult = "9",
    -- 购买金币(获得金币之后的弹板)
    -- PopPos_BuyCoins = "10",
    -- 支付成功（内购成功，获得金币之前）
    -- PopPos_IAP = "11"
}

import(".PopRule")
import(".PopProgramMgr")
local PopPosInfo = import(".data.PopPosInfo")
local PopLimitInfo = import(".data.PopLimitInfo")
local PopUpInfo = import(".data.PopUpInfo")
local PopQueue = import(".PopQueue")
local PushViewManager = class("PushViewManager")

function PushViewManager:getInstance()
    if not self._instance then
        self._instance = PushViewManager.new()
    end
    return self._instance
end

function PushViewManager:ctor()
    -- 弹板点位配置
    self.m_popPosCfg = {}
    --弹板信息配置--
    self.m_popViewCfg = {}
    -- self.m_popEndCallBack = nil --本次弹版结束后回调--
    -- self.m_curShowList = {} --本次弹版列表--
    -- self.m_curShowView = nil --当前弹版--

    -- 弹板队列表
    self.m_tbQueues = {}
    -- 当前弹板队列
    self.m_curQueue = nil

    -- 互斥表
    self.m_excludeList = {}
    -- 冷却时间
    self.m_cooldownList = {}

    -- 处理事件
    -- 处理下一个弹板
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.m_curQueue then
                self.m_curQueue:nextPopView()
            end
        end,
        ViewEventType.NOTIFY_NEXT_POP_VIEW
    )

    -- 结束弹板
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:finishPopView()
        end,
        ViewEventType.NOTIFY_FINISH_POP_VIEW
    )

    -- 活动超时
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local _programName = params.name
            if self.m_curQueue then
                self.m_curQueue:removeShowView(_programName)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

-- ============================================
function PushViewManager:parsePopUpData(tData)
    self:parsePopPosData(tData.popupPosRules)
    self:parsePopLimitData(tData.levelPopups)
    self:parsePopViewData(tData.newPopupRules)
end

-- 解析弹板点位数据
function PushViewManager:parsePopPosData(tData)
    tData = tData or {}
    self.m_popPosCfg = {}

    for i = 1, #tData do
        local _data = tData[i]
        local _posInfo = PopPosInfo:create()
        _posInfo:parseData(_data)

        self.m_popPosCfg[_posInfo:getPosId()] = _posInfo
    end
end

-- 解析弹板限制条件数据
function PushViewManager:parsePopLimitData(tData)
    tData = tData or {}
    for i = 1, #tData do
        local _data = tData[i]
        local _limitInfo = PopLimitInfo:create()
        _limitInfo:parseData(_data)

        local _posInfo = self.m_popPosCfg[_limitInfo:getPosId()]
        if _posInfo then
            _posInfo:addPopLimit(_limitInfo)
        end
    end

    -- 筛选优先级排序
    for key, value in pairs(self.m_popPosCfg) do
        value:sortPopLimits()
    end
end

-- 解析弹板数据 --
function PushViewManager:parsePopViewData(tData)
    assert(tData, "The var must't be nil")
    tData = tData or {}
    self.m_popViewCfg = {}
    for i = 1, #tData do
        local _data = tData[i]
        local _popUpInfo = PopUpInfo:create()
        _popUpInfo:parseData(_data)
        local _posId = _popUpInfo:getPosId()
        local _popUpId = _popUpInfo:getPopUpId()
        if not self.m_popViewCfg["" .. _posId] then
            self.m_popViewCfg["" .. _posId] = {}
        end

        self.m_popViewCfg["" .. _posId][_popUpId] = _popUpInfo

        -- 根据筛选权重排序
        -- table.sort(
        --     popUpList,
        --     function(a, b)
        --         return tonumber(a.filtOrder) > tonumber(b.filtOrder)
        --     end
        -- )
        -- tData[i].popupConfig = popUpList

        -- self.m_popViewCfg[posType] = tData[i]
    end
end
-- ===================================================
-- 获得点位所有弹板限制条件
function PushViewManager:getPopLimitList()
    if not self.m_popPosCfg[posType] then
        return nil
    end
    return self.m_popPosCfg[posType]:getPopLimitList()
end

-- 获取弹版列表 --
function PushViewManager:getPopUpCfg(posType)
    if not self.m_popViewCfg[posType] then
        return nil
    end
    return self.m_popViewCfg[posType]
end

-- 获得弹板信息
function PushViewManager:getPopUpInfo(popUpId, posType)
    local _popList = self:getPopUpCfg(posType)
    if _popList then
        return _popList[popUpId]
    else
        return nil
    end
end

-- 所有弹窗结束后续推送 --
function PushViewManager:finishPopView()
    -- self.m_curShowList = {}
    -- self.m_curShowView = nil
    -- if self.m_popEndCallBack then
    --     self.m_popEndCallBack()
    --     self.m_popEndCallBack = nil
    -- end
    if self.m_curQueue then
        self.m_curQueue:finishPopView()
    end
end

-- 获得当前弹框队列
function PushViewManager:getCurPopQueue()
    return self.m_curQueue
end

-- 根据点位显示弹框 供外部调用 --
function PushViewManager:showView(posType, callBack)
    -- 原来弹窗队列还在执行，就继续
    -- if #self.m_curShowList > 0 then
    --     self:nextPopView()
    --     return
    -- end
    -- if self.m_curQueue:nextPopView() then
    --     return
    -- end

    -- -- 设置弹版完成后回调 --
    -- self:setEndCallBack(callBack)

    -- 计算弹出列表
    local _curShowList, _excludeList = self:calculatePopList(posType)
    self:showViewLogic(_curShowList, _excludeList, callBack)
end

-- 显示自定义弹板队列
function PushViewManager:showUserDefaultView(posType, userData, callBack)
    local _excludeList = {}
    local _curShowList = {}
    local tempList = self:getPopUpCfg(posType)
    for i = 1, #userData do
        local popName = userData[i]
        for j = 1, #tempList do
            local info = tempList[j]
            if popName == info.programName and self:checkCanShow(info, self.m_excludeList) then
                table.insert(_curShowList, info)
            end
        end
    end
    self:showViewLogic(_curShowList, _excludeList, callBack)
end

-- 判断模块是否会触发
function PushViewManager:isProgramWillTrigger(posType, popStepName)
    local _curShowList, _ = self:calculatePopList(posType)
    for i = 1, #_curShowList do
        local popInfo = _curShowList[i]
        if popInfo:getRefName() == popStepName then
            return true
        end
    end
    return false
end

-- 模块弹框是否已经触发
function PushViewManager:isPopTrigger(popupName)
    -- if not self.m_curQueue then
    --     return false
    -- else
    --     self.m_curQueue:isPopTrigger(programName)
    -- end
    for i = 1, #self.m_tbQueues do
        local _Queue = self.m_tbQueues[i]
        if _Queue then
            local isTrigger = _Queue:isPopTrigger(popupName)
            if isTrigger then
                return true
            end
        end
    end
    return false
end

-- 开启弹出逻辑 --
function PushViewManager:showViewLogic(_curShowList, _excludeList, callBack)
    -- 计算弹出列表
    if _curShowList and #_curShowList > 0 then
        self.m_excludeList = _excludeList

        -- 弹板cd
        -- for i = 1, #_curShowList do
        --     local popUpInfo = _curShowList[i]
        --     -- 更新cd时间
        --     local _cooldown = popUpInfo.coolDown
        --     if _cooldown > 0 then
        --         self.m_cooldownList[popUpInfo.programName] = TimeManager:getServerTime() + _cooldown * 60
        --     end
        -- end

        -- 创建弹框队列
        local popQueue = PopQueue:create()

        popQueue:setPopQueue(
            _curShowList,
            function()
                -- 移除当前队列
                self:removeCurQueue()
                local oldCount = #self.m_tbQueues
                -- 队列结束要先移除队列，再执行结束回调函数，否则会死循环
                if callBack then
                    callBack()
                end

                local newCount = #self.m_tbQueues
                if newCount == oldCount and oldCount > 0 then
                    -- 没有新弹板队列，执行上一个弹板队列
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEXT_POP_VIEW)
                end
            end
        )
        -- 添加到队列表
        table.insert(self.m_tbQueues, popQueue)
        self.m_curQueue = popQueue

        self.m_curQueue:nextPopView()
    else
        if callBack then
            callBack()
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEXT_POP_VIEW)
    end

    -- if not self.m_curShowList or #self.m_curShowList == 0 then
    --     self:nextPopView()
    --     return
    -- end

    -- self:nextPopView()
end

--[[
    @desc: 移除当前队列
    author:{author}
    time:2019-11-14 17:08:33
    @return:
]]
function PushViewManager:removeCurQueue()
    local count = #self.m_tbQueues
    table.remove(self.m_tbQueues, count)

    if next(self.m_tbQueues) then
        count = #self.m_tbQueues
        self.m_curQueue = self.m_tbQueues[count]
        printInfo("上一个弹板队列结束，切换下一个队列！")
    else
        self.m_curQueue = nil
    end
end

-- 计算弹框列表
function PushViewManager:calculatePopList(posType)
    local popPosConfig = self.m_popPosCfg[posType]
    if not popPosConfig then
        return {}, {}
    end

    -- 等级判断
    local curLv = globalData.userRunData.levelNum
    local isSucc = popPosConfig:checkLvRule(curLv)
    if not isSucc then
        return {}, {}
    end

    -- 检测点位弹版列表 --
    local _limitList = popPosConfig:getPopLimitList()

    if _limitList == nil or #_limitList <= 0 then
        return {}, {}
    end

    --最多显示几个弹窗
    local maxCount = popPosConfig:getMaxCount()
    -- 互斥表
    local _excludeList = {}
    -- 当前要显示的列表
    local _curShowList = {}
    --将需要显示的弹窗加入队列
    local _count = 0
    for i = 1, #_limitList do
        if _count < maxCount then
            local _popUpInfo = nil
            local _limitInfo = _limitList[i]
            if _limitInfo then
                _popUpInfo = self:getPopUpInfo(_limitInfo:getPopUpId(), _limitInfo:getPosId())
            end

            -- 筛选弹框
            if self:checkCanShow(_popUpInfo, _limitInfo, _excludeList) then
                _curShowList[#_curShowList + 1] = _popUpInfo
                _count = _count + 1
                -- 加入排斥表
                local _checkName = _popUpInfo:getCheckName()
                if _checkName and _checkName ~= "" then
                    _excludeList[_checkName] = 1
                end
            end
        end
    end

    if #_curShowList > 1 then
        --按照弹出优先级排序 --
        table.sort(
            _curShowList,
            function(a, b)
                return tonumber(a:getPopOrder()) > tonumber(b:getPopOrder())
            end
        )
    end

    return _curShowList, _excludeList
end

-- vType 这个位置最多弹几个框 --
function PushViewManager:getShowViewCount(posType)
    local tPopConfig = self.m_popPosCfg[posType]
    if tPopConfig then
        return tPopConfig:getMaxCount()
    end

    return 0
end

-- 检查是否可以弹出
function PushViewManager:checkCanShow(popUpInfo, limitInfo, excludeList)
    if not popUpInfo or not limitInfo then
        return false
    end

    -- 检测排斥
    if excludeList[popUpInfo:getRefName()] then
        return false
    end
    -- 是否开启
    if not popUpInfo:isOpen() then
        return false
    end

    -- 等级判断
    local curLv = globalData.userRunData.levelNum
    local isSucc = limitInfo:checkLevelRule(curLv)
    if not isSucc then
        return false
    end

    -- 时间判断
    local _timestamp = globalData.userRunData.p_serverTime
    local isSucc2 = limitInfo:checkDateRule(_timestamp)
    if not isSucc2 then
        return false
    end

    -- 判断CD  当弹板本身有CD才检测
    -- if popUpInfo.coolDown > 0 then
    --     local _cooldownTime = self.m_cooldownList[popUpInfo.programName]
    --     if _cooldownTime and _cooldownTime > TimeManager:getServerTime() then
    --         return false
    --     end
    -- end

    -- 是否已经触发了
    if self:isPopTrigger(popUpInfo:getPopupName()) then
        return false
    end

    -- 判断facebook用户限制

    -- 判断是活动属性
    local isAlive = PopRule:checkProgramPopRule(popUpInfo)
    if not isAlive then
        return false
    end

    return true
end

GD.PushViewManager = PushViewManager:getInstance()
