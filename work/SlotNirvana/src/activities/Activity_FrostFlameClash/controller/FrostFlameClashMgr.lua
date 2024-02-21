--[[
    单人限时比赛
]]
local FrostFlameClashMgr = class("FrostFlameClashMgr", BaseActivityControl)
local FrostFlameClashNet = require("activities.Activity_FrostFlameClash.net.FrostFlameClashNet")

function FrostFlameClashMgr:ctor()
    FrostFlameClashMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FrostFlameClash)
    self.m_net = FrostFlameClashNet:getInstance()
    self.m_is1o1Game = false
end

function FrostFlameClashMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName .. "HallNode"
end

function FrostFlameClashMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName .. "SlideNode"
end

function FrostFlameClashMgr:getPopPath(popName)
    return popName .. "/FrostFlameClashMainLayer"
end

function FrostFlameClashMgr:getEntryPath(entryName)
    return entryName .. "/FrostFlameClashEntryNodeCode/FrostFlameClashEntryNode"
end

-- 促销入口
function FrostFlameClashMgr:getSaleNodeModule()
    return "Activity_FrostFlameClash.FrostFlameClashPromotionNode"
end

-- 切换bet是否显示气泡
function FrostFlameClashMgr:isCanShowBetBubble()
    if not FrostFlameClashMgr.super.isCanShowBetBubble(self) then
        return false
    end    
    -- 判断是否有资源和数据
    if not self:isCanShowLayer() then
        return false
    end
    if not self:getIs1v1Game() then
        return false
    end
    local data = self:getRunningData()
    if not data:isGaming() then -- 不在游戏阶段
        return false
    end
    local rivalInfo = data:getRivalInfo()
    if table.nums(rivalInfo) <= 0 then -- 没有对手信息
        return false
    end
    local signPointCoins = data:getSignPointCoins()
    if signPointCoins <= 0 then -- 房间金币
        return false
    end
    return true
end

function FrostFlameClashMgr:getBetBubblePath(_refName)
    return "FrostFlameClashCode/BetBubble/FrostFlameClashBetBubble"
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
function FrostFlameClashMgr:parseFrostFlameClashSpinData(_data)
    if not _data then
        return
    end
    local data = self:getRunningData()
    if not data then
        return
    end
    data:parseData(_data)
    if self:checkGameTopNode() and data.p_addPoints > 0 then
        self:onShowFlyPoint()
    end
end

function FrostFlameClashMgr:checkGameTopNode()
    if not self:isCanShowLayer() then
        return false
    end
    local data = self:getRunningData()
    if not data then
        return false
    end
    if data:isCannotDoReady() then
        return false
    end
    if not self:getIs1v1Game() then
        return false
    end
    return true
end

-- 紧贴关卡上UI底部的节点
function FrostFlameClashMgr:createGameTopNode()
    if not self:getIs1v1Game() then
        return
    end
    if tolua.isnull(self.m_gameTopNode) then
        local topNode = util_createView("FrostFlameClashCode.Level.FrostFlameClash_LevelMain")
        topNode:setName("FrostFlameClash_LevelMain")
        self.m_gameTopNode = topNode
        addExitListenerNode(
            topNode,
            function()
                self.m_gameTopNode = nil
            end
        )
    end
    return self.m_gameTopNode
end

function FrostFlameClashMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local data = self:getRunningData()
    if not data then
        return
    end

    if gLobalViewManager:getViewByExtendData("FrostFlameClashMainLayer") then
        return nil
    end

    local uiView = util_createView("FrostFlameClashCode.MainUI.FrostFlameClashMainLayer", _params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)

    return true
end


function FrostFlameClashMgr:showBattleResultLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local data = self:getRunningData()
    local isWillShowResultLayer = data:isWillShowResultLayer()
    if not isWillShowResultLayer then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("FrostFlameClashResultLayer") then
        return nil
    end
    local view_path = "FrostFlameClashCode.Reward.FrostFlameClashRewardWinLayer"
    if data:getWinOrLose() == 2 then
        view_path = "FrostFlameClashCode.Reward.FrostFlameClashRewardLoseLayer"
    end

    local uiView = util_createView(view_path)
    if uiView then
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end

    return uiView
end



function FrostFlameClashMgr:showGameStartLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("FrostFlameClash_LevelBattleStartLayer") then
        return nil
    end

    local uiView = util_createView("FrostFlameClashCode.Level.FrostFlameClash_LevelBattleStartLayer")
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function FrostFlameClashMgr:showRuleLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("FrostFlameClashRuleLayer") then
        return nil
    end

    local uiView = util_createView("FrostFlameClashCode.Rule.FrostFlameClashRuleLayer", _params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function FrostFlameClashMgr:showRewardLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("FrostFlameClashRewardLayer") then
        return nil
    end

    local uiView = util_createView("Activity_FrostFlameClash.FrostFlameClashRewardLayer", _params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function FrostFlameClashMgr:showOpenLayer(_params)
    if not self:isCanShowLayer() then
        return false
    end
    if gLobalViewManager:getViewByExtendData("FrostFlameClashOpenLayer") then
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

    local uiView = util_createView("Activity_FrostFlameClash.FrostFlameClashOpenLayer", _params)
    if uiView then
        self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

-- 检查开启新房间
function FrostFlameClashMgr:checkIsFirstPopupOpenLayer()
    local data = self:getRunningData()
    local isShow = false
    if not data then
        return isShow
    end
    local key = "FrostFlameClashIsFirstPopupOpenLayer" .. data:getExpireAt() .. data:getRound()
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
function FrostFlameClashMgr:showPromotionLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("FrostFlameClashPromotionLayer") then
        return nil
    end

    local uiView = util_createView("Activity_FrostFlameClash.FrostFlameClashPromotionLayer", _params)
    self:showLayer(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function FrostFlameClashMgr:buyFrostFlameClashBuff()
    -- 检测宝石是否满足条件
    if self:checkGem() then
        self:requestBuyPromotionBuff()
    else
        self:openGemStore("btn_buy")
    end
end

function FrostFlameClashMgr:checkGem()
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

function FrostFlameClashMgr:openGemStore(openBtnName)
    local params = {shopPageIndex = 2, dotKeyType = openBtnName, dotUrlType = DotUrlType.UrlName, dotIsPrep = false}
    local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
    if view then
        view.buyShop = true
    end
end

---------------------------------------------------网络数据相关-----------------------------------------------------------------

-- 请求单人限时比赛数据
function FrostFlameClashMgr:requestRefreshFrostFlameClashInfo(isForEnterGame)
    if self.m_isRequestNet then
        return
    end

    local data = self:getRunningData()
    if not data then
        return
    end
    data:setIsForEnterGame(isForEnterGame)
    self.m_isRequestNet = true
    local successFunc = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FROSTFLAMECLASH_DATA_REFRESH, {isSuc = true})
        if isForEnterGame then
            data:setIsForEnterGame(false)
        end
        self.m_isRequestNet = false
    end

    local failedCallFunc = function(errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FROSTFLAMECLASH_DATA_REFRESH, {errorCode = errorCode, errorData = errorData})
        self.m_isRequestNet = false
        if isForEnterGame then
            data:setIsForEnterGame(false)
        end
    end
    self.m_net:requestRefreshFrostFlameClashInfo(successFunc, failedCallFunc)
end

-- 请求收集奖励
function FrostFlameClashMgr:requestCollectReward(_params)
    local params = _params or {}
    local successFunc = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FROSTFLAMECLASH_COLLECT_REWARD, {isSuc = true})
    end

    local failedCallFunc = function(errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FROSTFLAMECLASH_COLLECT_REWARD, {isSuc = false})
    end
    self.m_net:requestCollectReward(successFunc, failedCallFunc)
end

-- 膨胀消耗1v1比赛失败保留净胜
function FrostFlameClashMgr:requestFlameClashFailedRetain(_params)
    local params = _params or {}
    local successFunc = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FROSTFLAMECLASH_FAILED_RETAIN) -- 本轮比赛手动激活成功
    end

    local failedCallFunc = function(errorCode, errorData)
    end
    self.m_net:requestFlameClashFailedRetain(successFunc, failedCallFunc)
end

-- 膨胀消耗1v1比赛 领取累计胜场奖励
function FrostFlameClashMgr:requestFlameClashStageReward(_params)
    local params = _params or {}
    local stageData = params.stageData or {}
    local arguments = {stage = stageData.stage}
    local successFunc = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FROSTFLAMECLASH_STAGE_REWARD, {stageData = params.stageData}) -- 本轮比赛手动激活成功
    end

    local failedCallFunc = function(errorCode, errorData)
    end
    self.m_net:requestFlameClashStageReward(arguments, successFunc, failedCallFunc)
end

---------------------------------------------------动画收起展开相关--------------------------------------------------
function FrostFlameClashMgr:setIsDoingUnfoldOrFoldAct(isDoing)
    self.m_isDoingAct = isDoing
end

function FrostFlameClashMgr:isDoingUnfoldOrFoldAct()
    return self.m_isDoingAct
end

------------------------------------------------------------------------------------------------------------------
-- ************************************** spin获得积分动画 ************************************** --
-- 显示飞奖杯效果
function FrostFlameClashMgr:onShowFlyPoint()
    local activityData = self:getRunningData()
    if activityData and (not tolua.isnull(self.m_gameTopNode)) then
        if not self:isCanShowLayer() then
            return false
        end
        local addPoints = activityData:getAddPoints()
        if not addPoints or addPoints <= 0 then
            return false
        end
        activityData:clearAddPoints()
        local isCanShow,flyDesPos = self.m_gameTopNode:getFlyDesPos()
        if not isCanShow then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FROSTFLAMECLASH_FLYPOINTS_OVER)
            return false
        end
        self:playGainPointAction(addPoints, flyDesPos)
        return true
    else
        return false
    end
end

function FrostFlameClashMgr:playGainPointAction(addPoints, desPos)
    if not addPoints or not desPos then
        return
    end

    gLobalSoundManager:playSound("Activity_FrostFlameClash/Activity/sound/FFClash_point_fly.mp3")
    local _flyPoint = util_createView("FrostFlameClashCode.Level.FrostFlameClash_LevelFlyPointNode")
    _flyPoint:updateView(addPoints)

    local startPos = globalData.bingoCollectPos or cc.p(display.width / 2, display.height / 2)
    gLobalViewManager.p_ViewLayer:addChild(_flyPoint, ViewZorder.ZORDER_SPECIAL)
    startPos = gLobalViewManager.p_ViewLayer:convertToNodeSpace(startPos)
    _flyPoint:setPosition(startPos)

    local desNodePos = gLobalViewManager.p_ViewLayer:convertToNodeSpace(desPos)
    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(22 / 60)
    actList[#actList + 1] = self:runEffectMoveAction(startPos, desNodePos)
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            if _flyPoint then
                _flyPoint:closeUI()
            end
            -- 刷新信息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FROSTFLAMECLASH_FLYPOINTS_OVER)
        end
    )
    local seq = cc.Sequence:create(actList)
    _flyPoint:runAction(seq)

    _flyPoint:playPointAction()
end

function FrostFlameClashMgr:runEffectMoveAction(startPos, endPos)
    local moveTime = 44/60
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



-- 开关 (传的必须是字符类型"true" or "false")
function FrostFlameClashMgr:setFrostFlameClashSwitch(_val)
    local data = self:getRunningData()
    if data then
        local endTime = data:getExpireAt()
        gLobalDataManager:setStringByField("FrostFlameClash" .. endTime, _val)
    end
end

-- 开关"true" or "false"（在关卡中spin是否掉落点数） 服务器那边规定必须是字符类型不能是布尔类型
function FrostFlameClashMgr:getFrostFlameClashSwitch()
    local data = self:getRunningData()
    if data then
        local endTime = data:getExpireAt()
        return gLobalDataManager:getStringByField("FrostFlameClash" .. endTime, "true")
    end
    return nil
end

-- 开关 是否是开着的
function FrostFlameClashMgr:getIsFrostFlameClashSwitchOn()
    local minzSwitch = self:getFrostFlameClashSwitch()
    if minzSwitch and minzSwitch == "true" then
        return true
    end
    return false
end

function FrostFlameClashMgr:registerListener()
    -- 进入关卡消息回调
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local isSuc = params[1]
            local resultData = params[2]
            if isSuc == true and resultData then
                local resultList = cjson.decode(resultData.result)
                self.m_is1o1Game = resultList.flameClashGame or false
                -- if self.m_is1o1Game then
                --     gLobalActivityManager:showActivityEntryNode()
                -- end
            end
        end,
        ViewEventType.NOTIFY_GETGAMESTATUS
    )
end

-- 是否是掉落minz点数的关卡
function FrostFlameClashMgr:getIs1v1Game()
    local machineData = globalData.slotRunData.machineData
    if machineData and machineData.getFrostFlameClashGame then
        local is1o1Game = machineData:getFrostFlameClashGame()
        return is1o1Game
    end
    return self.m_is1o1Game
end

return FrostFlameClashMgr
