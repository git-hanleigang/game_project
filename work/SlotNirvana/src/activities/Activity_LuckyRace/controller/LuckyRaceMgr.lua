--[[
    单人限时比赛
]]
local LuckyRaceMgr = class("LuckyRaceMgr", BaseActivityControl)
local LuckyRaceNet = require("activities.Activity_LuckyRace.net.LuckyRaceNet")
-- LuckyRaceCfg配置的初始化，*****一定不能删除*****
local LuckyRaceCfg = require("activities.Activity_LuckyRace.config.LuckyRaceCfg")

function LuckyRaceMgr:ctor()
    LuckyRaceMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckyRace)
    self.m_net = LuckyRaceNet:getInstance()
end

function LuckyRaceMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName .. "HallNode"
end

function LuckyRaceMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName .. "SlideNode"
end

function LuckyRaceMgr:getPopPath(popName)
    return popName .. "/LuckyRaceMainLayer"
end

function LuckyRaceMgr:getEntryPath(entryName)
    return entryName .. "/LuckyRaceEntryNodeCode/LuckyRaceEntryNode"
end

-- 促销入口
function LuckyRaceMgr:getSaleNodeModule()
    return "Activity_LuckyRace.LuckyRacePromotionNode"
end

--[[
    解析spin返回数据
    addPoints = 1 -- 增加积分
    totalPoints = 2 -- 总积分
    rankList = 5 -- 排行榜列表
    rank = 6 -- 排名
    refreshPart = 7 -- true刷新部分数据, false刷新全部数据
    winType = 8 -- 赢钱类型 "Spin" or 大赢
    5，6 数据只有在自己排名有变化后才会返回
]]
function LuckyRaceMgr:parseLuckyRaceSpinData(_data)
    if not _data then
        return
    end
    local data = self:getRunningData()
    if not data then
        return
    end
    if _data.refreshPart then
        data:parseSpinData(_data)
        if _data.winType == "Spin" and _data.totalPoints < data:getMaxPoints() then
            self:onShowFlyPoint()
        end
    else
        data:parseData(_data)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_DATA_UPDATE)
    end
end

-- 心跳中 返回的 数据
function LuckyRaceMgr:parseHeartBeatData(_heartJsonData)
    local data = self:getRunningData()
    if not _heartJsonData or not data then
        return
    end

    data:parseHeartBeatData(_heartJsonData)
    local bCurRoundCanPlay = data:checkCurRoundCanPlay()
    if bCurRoundCanPlay then
        return
    end

    local curTime = util_getCurrnetTime()
    local startConfirmTime = data:getStartResponseTime()
    local endConfirmTime = data:getRoomStartTime()
    if curTime >= startConfirmTime and curTime <= (endConfirmTime - 10) then
        -- 激活本轮比赛游戏
        self:showOpenLayer()
    end
end

-- 领奖界面关闭 删除左边条入口 and 主界面关闭
function LuckyRaceMgr:removeFromEntryNode()
    local entryNode = gLobalActivityManager:getEntryNode(ACTIVITY_REF.LuckyRace)
    if entryNode and entryNode.removeFromEntryNode then
        entryNode:removeFromEntryNode()
    end
    local mainLayer = gLobalViewManager:getViewByExtendData("LuckyRaceMainLayer")
    if mainLayer and mainLayer.closeUI then
        mainLayer:closeUI()
    end
end

-- 检测开启左边条入口
function LuckyRaceMgr:checkOpenEntry()
    local data = self:getRunningData()
    if data then
        if not gLobalViewManager:isLevelView() then
            return
        end
        if data:checkCurRoundCanPlay() and data:checkIsInRaceTime() and not data:getCollected() then
            if not gLobalActivityManager:IsCreateEnd(ACTIVITY_REF.LuckyRace) then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_DATA_UPDATE)
            end
        end
    end
end

-- 请求单人限时比赛数据
function LuckyRaceMgr:requestLuckyRaceInfo(_successCallFunc, _failedCallFunc)
    local successFunc = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_DATA_REFRESH, {isSuc = true})
        -- 刷新排名信息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_RANK_UPDATE)
        if _successCallFunc then
            _successCallFunc()
        end
    end

    local failedCallFunc = function(errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_DATA_REFRESH, {errorCode = errorCode, errorData = errorData})
        if _failedCallFunc then
            _failedCallFunc()
        end
    end
    self.m_net:requestLuckyRaceInfo(successFunc, failedCallFunc)
end

-- 请求收集奖励
function LuckyRaceMgr:requestCollectReward(_params)
    local params = _params or {}
    local successFunc = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_COLLECT_REWARD, {isSuc = true, myRank = params.myRank or 0})
    end

    local failedCallFunc = function(errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_COLLECT_REWARD, {errorCode = errorCode, errorData = errorData})
    end
    self.m_net:requestCollectReward(successFunc, failedCallFunc)
end

-- 激活本轮比赛游戏
function LuckyRaceMgr:requestActiveCurRaceRound(_params)
    local params = _params or {}
    local successFunc = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_CUR_ROUND_ACTIVE) -- 本轮比赛手动激活成功
    end

    local failedCallFunc = function(errorCode, errorData)
    end
    self.m_net:requestActiveCurRaceRound(successFunc, failedCallFunc)
end

function LuckyRaceMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local data = self:getRunningData()
    local bCurRoundCanPlay = data:checkCurRoundCanPlay()
    if not bCurRoundCanPlay then
        return
    end

    if gLobalViewManager:getViewByExtendData("LuckyRaceMainLayer") then
        return nil
    end

    local enterViewFunc = function()
        local uiView = util_createView("Activity_LuckyRace.LuckyRaceMainLayer", _params)
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end
    self:requestLuckyRaceInfo(enterViewFunc)
    return true
end

-- 关卡中spin后检测是否弹出主界面
function LuckyRaceMgr:checkOnShowMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("LuckyRaceMainLayer") then
        return nil
    end

    local data = self:getRunningData()
    local curTime = util_getCurrnetTime()
    if not data:checkCurRoundCanPlay() then
        return nil
    end

    -- 时间没到 不弹
    -- 积分没超过房间最大积分 不弹
    -- 领过奖 不弹
    if (data:getRoomEndTime() >= curTime and not data:isOverMaxPoints()) or data:getCollected() then
        return nil
    end

    local uiView = util_createView("Activity_LuckyRace.LuckyRaceMainLayer", _params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function LuckyRaceMgr:showRuleLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("LuckyRaceRuleLayer") then
        return nil
    end

    local uiView = util_createView("Activity_LuckyRace.LuckyRaceRuleLayer", _params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function LuckyRaceMgr:showRewardLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("LuckyRaceRewardLayer") then
        return nil
    end

    local uiView = util_createView("Activity_LuckyRace.LuckyRaceRewardLayer", _params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function LuckyRaceMgr:showOpenLayer(_params)
    if not self:isCanShowLayer() then
        return false
    end
    if gLobalViewManager:getViewByExtendData("LuckyRaceOpenLayer") then
        return false
    end

    -- 房间都没了
    local data = self:getRunningData()
    local roomEndTime = data:getRoomEndTime()
    if util_getCurrnetTime() > roomEndTime then
        return false
    end

    if not self:checkIsFirstPopupOpenLayer() then
        return false
    end

    local uiView = util_createView("Activity_LuckyRace.LuckyRaceOpenLayer", _params)
    if uiView then
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

-- 检查开启新房间
function LuckyRaceMgr:checkIsFirstPopupOpenLayer()
    local data = self:getRunningData()
    local isShow = false
    if not data then
        return isShow
    end
    local key = "LuckyRaceIsFirstPopupOpenLayer" .. data:getExpireAt() .. data:getRound()
    local isFrist = gLobalDataManager:getBoolByField(key, false)
    if isFrist then
        isShow = false
    else
        isShow = true
        gLobalDataManager:setBoolByField(key, true)
    end
    return isShow
end

-- ************************************** 促销部分 ************************************** --
function LuckyRaceMgr:showPromotionLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("LuckyRacePromotionLayer") then
        return nil
    end

    local uiView = util_createView("Activity_LuckyRace.LuckyRacePromotionLayer", _params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function LuckyRaceMgr:buyLuckyRaceBuff()
    -- 检测宝石是否满足条件
    if self:checkGem() then
        self:requestBuyPromotionBuff()
    else
        self:openGemStore("btn_buy")
    end
end

function LuckyRaceMgr:checkGem()
    local needGems = 0
    local data = self:getRunningData()
    if data then
        local saleData = data:getSaleData()
        if saleData then
            needGems = saleData.gems or 0
        end
    end
    return globalData.userRunData.gemNum >= needGems
end

function LuckyRaceMgr:openGemStore(openBtnName)
    local params = {shopPageIndex = 2, dotKeyType = openBtnName, dotUrlType = DotUrlType.UrlName, dotIsPrep = false}
    local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
    if view then
        view.buyShop = true
    end
end

-- 请求购买促销
function LuckyRaceMgr:requestBuyPromotionBuff()
    local successFunc = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_BUY_BUFF, {isSuc = true})
    end

    local failedCallFunc = function(errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_BUY_BUFF, {errorCode = errorCode, errorData = errorData})
    end
    self.m_net:requestBuyPromotionBuff(successFunc, failedCallFunc)
end

-- ************************************** spin获得积分动画 ************************************** --
-- 显示飞奖杯效果
function LuckyRaceMgr:onShowFlyPoint()
    local activityData = self:getRunningData()
    if activityData then
        if not self:isCanShowLayer() then
            return false
        end
        local addPoints = activityData:getAddPoints()
        if not addPoints or addPoints <= 0 then
            return false
        end
        -- 获取要飞到的坐标
        local _node = gLobalActivityManager:getEntryNode(ACTIVITY_REF.LuckyRace)
        if not _node then
            return false
        end

        local flyDesPos = _node:getFlyDesPos()
        local openState = _node:getEntryNodeOpenState()

        local _isVisible = gLobalActivityManager:getEntryNodeVisible(ACTIVITY_REF.LuckyRace)
        if not _isVisible or openState then
            -- 隐藏图标的时候使用箭头坐标
            flyDesPos = gLobalActivityManager:getEntryArrowWorldPos()
        end

        if not flyDesPos then
            return false
        end

        activityData:setAddPoints(0)
        self:playGainPointAction(addPoints, flyDesPos)

        return true
    else
        return false
    end
end

function LuckyRaceMgr:playGainPointAction(addPoints, desPos)
    if not addPoints or not desPos then
        return
    end

    local _flyPoint = util_createView("Activity_LuckyRace.LuckyRacePointNode")
    _flyPoint:updateView(addPoints)

    local startPos = globalData.bingoCollectPos or cc.p(display.width / 2, display.height / 2)
    gLobalViewManager.p_ViewLayer:addChild(_flyPoint, ViewZorder.ZORDER_SPECIAL)
    startPos = gLobalViewManager.p_ViewLayer:convertToNodeSpace(startPos)
    _flyPoint:setPosition(startPos)

    local desNodePos = gLobalViewManager.p_ViewLayer:convertToNodeSpace(desPos)
    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(60 / 60)
    actList[#actList + 1] = self:runEffectMoveAction(startPos, desNodePos)
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            if _flyPoint then
                _flyPoint:closeUI()
            end
            -- 刷新排名信息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_RACE_RANK_UPDATE)
        end
    )
    local seq = cc.Sequence:create(actList)
    _flyPoint:runAction(seq)

    _flyPoint:playPointAction()
end

function LuckyRaceMgr:runEffectMoveAction(startPos, endPos)
    local moveTime = 1
    -- 随机一个区域
    local off_1 = math.random(1, 200)
    local off_2 = math.random(1, 100)

    -- 这里给曲线匹配一个方向(相当于给原曲线做了一个轴对称的反转)
    local x_param = (endPos.x - startPos.x) / math.abs(endPos.x - startPos.x)
    local y_param = (endPos.y - startPos.y) / math.abs(endPos.y - startPos.y)
    -- 位移
    local control_1 = cc.p(startPos.x + 60 * x_param, startPos.y + (200 + off_1) * y_param)
    local control_2 = cc.p(endPos.x - 200 * x_param, endPos.y - (100 + off_2) * y_param)
    local bezierTo = cc.BezierTo:create(moveTime, {control_1, control_2, endPos})
    local ease = cc.EaseSineInOut:create(bezierTo)
    return ease
end

return LuckyRaceMgr
