--[[
    公共jackpot
]]
require("activities.Activity_CommonJackpot.config.CommonJackpotCfg")
local CJDragMoveCtrl = util_require("activities.Activity_CommonJackpot.controller.CJDragMoveCtrl")
local CJJackpotPoolCtrl = import(".CJJackpotPoolCtrl")
local CommonJackpotMgr = class("CommonJackpotMgr", BaseActivityControl)
function CommonJackpotMgr:ctor()
    CommonJackpotMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.CommonJackpot)

    self.m_isRequesting = false

    if CommonJackpotCfg.TEST_MODE == true then
        self:parseData(CommonJackpotCfg.TEST_ENTER, "TEST")
    else
        -- 进入关卡消息回调
        gLobalNoticManager:addObserver(
            self,
            function(target, params)
                local isSuc = params[1]
                local resultData = params[2]
                local levelName = params[3]
                -- 去除关卡的判断
                if isSuc == true then
                    local levelsTable = cjson.decode(resultData.result)
                    local data = self:getRunningData()
                    if data and self:isRecmdJackpotLevel(levelName) then 
                        if levelsTable and levelsTable.gameConfig and levelsTable.gameConfig.jillionJackpot ~= nil then
                            self:parseData(levelsTable.gameConfig.jillionJackpot, "enterLevel", levelName)
    
                            -- 有了数据开始创建入口
                            self:initEntryLayer()
    
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFI_CJ_DATA_CHANGED, {source = "enterLevel", levelName = levelName})
                        else
                            print("进入关卡，缺少服务器数据，levelName is " .. levelName)
                            util_sendToSplunkMsg("CommonJackpot", "DataError:enterLevel, jillionJackpot is null, levelName is " .. levelName)
                        end
                    end
                end
             end,
            ViewEventType.NOTIFY_GETGAMESTATUS
        )

        -- SPIN后数据解析
        -- 关卡spin消息回调
        gLobalNoticManager:addObserver(
            self,
            function(target, params)
                if params[1] == true then
                    local spinData = params[2]
                    if spinData and spinData.action == "SPIN" and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                        if globalData.slotRunData.machineData ~= nil then
                            local data = self:getRunningData()
                            if data and self:isRecmdJackpotLevel(globalData.slotRunData.machineData.p_name) then
                                if spinData.jillionJackpot ~= nil then
                                    self:parseData(spinData.jillionJackpot, "spin")
                                    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_CJ_DATA_CHANGED, {source = "spin"})
                                end
                            end
                        end
                    end
                end
            end,
            ViewEventType.NOTIFY_GET_SPINRESULT
        )
    end
    self.m_poolCtr = CJJackpotPoolCtrl:create()
    self.m_poolCtr:init()
end

function CommonJackpotMgr:getPoolCtr()
    return self.m_poolCtr
end

function CommonJackpotMgr:parseData(_netData, _source, _levelName)
    if not _netData then
        return
    end
    local data = self:getRunningData()
    if not data then
        return
    end
    if _source == "spin" then
        data:parseSpinData(_netData)
    elseif _source == "enterLevel" then
        data:parseEnterLevelData(_netData, _levelName)
    end
end

-- 检查数据完整性
function CommonJackpotMgr:isLevelEffective()
    -- 活动是否开启判断
    local data = self:getRunningData()
    if not data then
        return false
    end
    -- 关卡的数据是否完整
    if not data:isEnterLevelEffective() then
        return false
    end

    -- 判断关卡是否是公共jackpot关卡
    if not self:isRecmdJackpotLevel(globalData.slotRunData.machineData.p_name) then
        return false
    end

    return true
end

-- 解析常量配置
function CommonJackpotMgr:getLobbyJackpot()
    local curLv = globalData.userRunData.levelNum
    local cfgs = globalData.constantData.COMMON_JACKPOT
    if cfgs and #cfgs > 0 then
        for i = 1, #cfgs do
            local cfg = cfgs[i]
            if curLv >= cfg.minLv and curLv <= cfg.maxLv then
                return cfg.base, cfg.add
            end
        end
    end
    return nil, nil
end

function CommonJackpotMgr:getMachineJackpot(_levelName)
    local data = self:getRunningData()
    if data then
        local poolData = data:getPoolByName(_levelName)
        if poolData then
            return poolData:getValue(), poolData:getOffset()
        end
    end
    return nil, nil
end

-- 没有最大值，一直涨，下次数据来了，重新计算
function CommonJackpotMgr:getJackpotValue(_levelName, _lobby)
    local _poolKey
    local initValue, offset
    if _lobby == true then
        initValue, offset = self:getLobbyJackpot()
        _poolKey = CommonJackpotCfg.POOL_KEY.Lobby
    else
        initValue, offset = self:getMachineJackpot(_levelName)
        _poolKey = _levelName
    end
    local coins = 0
    if initValue and offset then
        local syncTime = self.m_poolCtr:getSyncTime(_poolKey)
        local addTimes = math.floor(syncTime / CommonJackpotCfg.JACKPOT_FRAME)
        coins = initValue + addTimes * offset
    -- print("----syncTime, addTimes, coins----", syncTime, initValue, addTimes, offset, coins)
    end
    return coins
end

-- -- 获取jackpot关卡推荐组数据
-- function CommonJackpotMgr:getRecmdJackpotData()
--     local LevelRecmdData = require("views.lobby.LevelRecmd.LevelRecmdData")
--     local _, recmdData = LevelRecmdData:getInstance():getRecmdInfoByGroup("Jillion")
--     return recmdData
-- end

-- function CommonJackpotMgr:getRecmdJackpotLevelInfos()
--     local recmdData = self:getRecmdJackpotData()
--     if recmdData then
--         local _levelInfos = recmdData.levelInfos
--         return _levelInfos
--     end
--     return {}
-- end

-- function CommonJackpotMgr:getRecmdJackpotLevelNames()
--     local recmdData = self:getRecmdJackpotData()
--     if recmdData then
--         local _levelNames = recmdData:getLevelNames()
--         return _levelNames
--     end
--     return {}
-- end

-- _levelName:服务器中使用的名字
function CommonJackpotMgr:isRecmdJackpotLevel(_levelName)
    if not _levelName then
        return false
    end
    -- 放弃使用关卡推荐组中的关卡名字配置
    -- local levelNames = self:getRecmdJackpotLevelNames()
    -- 优化：最新为数值配置在常量表中
    local levelNames = globalData.constantData.COMMON_JACKPOT_GAME_NAMES
    if levelNames and #levelNames > 0 then
        for i = 1, #levelNames do
            if levelNames[i] == _levelName then
                return true
            end
            if levelNames[i] .. "_H" == _levelName then
                return true
            end
        end
    end
    return false
end

function CommonJackpotMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("CJMainLayer") ~= nil then
        return nil
    end
    local view = util_createView("Activity.CommonJackpot.Game.CJMainLayer")
    view:setName("CJMainLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 主游戏界面中打开的规则
function CommonJackpotMgr:showInfoLayer()
    if gLobalViewManager:getViewByName("CJMainInfoLayer") ~= nil then
        return nil
    end
    local view = util_createView("Activity.CommonJackpot.Game.CJMainInfoLayer")
    view:setName("CJMainInfoLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CommonJackpotMgr:showRewardLayer(_over,_index)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("CJRewardLayer") ~= nil then
        return nil
    end
    local view = util_createView("Activity.CommonJackpot.Game.CJRewardLayer", _over,_index)
    view:setName("CJRewardLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CommonJackpotMgr:createGuideNode(_index)
    return util_createView("Activity.CommonJackpot.Guide.CJGuideNode", _index)
end

-- 公共jackpot在关卡的标题，紧贴关卡上UI底部的节点
function CommonJackpotMgr:createTitleNode(_levelName)
    if not self:isCanShowLayer() then
        return nil
    end

    if not self.m_slotTitleNode then
        self.m_slotTitleNode = util_createView("Activity.CommonJackpot.LevelTitle.CJTitleNode")
    -- addExitListenerNode(
    --     self.m_slotTitleNode,
    --     function()
    --         self:clearTitleNode()
    --     end
    -- )
    end
    return self.m_slotTitleNode
end

function CommonJackpotMgr:clearTitleNode()
    self.m_slotTitleNode = nil
end

function CommonJackpotMgr:initEntryLayer()
    local parentNode = gLobalViewManager:getViewLayer():getParent()
    local zOrder = GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5
    if not tolua.isnull(self.m_entryNode) then
        self.m_entryNode:removeFromParent()
    end
    -- 清空
    self:clearEntryNode()
    if tolua.isnull(parentNode) then
        return
    end
    -- 创建节点
    local entry = self:createEntryNode()
    if entry then
        parentNode:addChild(entry, zOrder)
        local entrySize = self:getEntryNodeSize()
        local offsetX = 10
        local offsetY = 100
        local posx = display.width - entrySize.width / 2 - offsetX
        local posy = display.height / 2 + offsetY
        entry:setPosition(cc.p(posx, posy))
        self.m_entryNode = entry
        -- addExitListenerNode(
        --     self.m_entryNode,
        --     function()
        --         self:clearEntryNode()
        --     end
        -- )
        CJDragMoveCtrl:setParentNode(entry, entrySize)
        CJDragMoveCtrl:createDragLayer()
    end
end

function CommonJackpotMgr:clearEntryNode()
    self.m_entryNode = nil
end

function CommonJackpotMgr:getEntryNodePos()
    return cc.p(self.m_entryNode:getPosition())
end

-- 分离了主体资源和loading资源后，要添加资源下载判断
function CommonJackpotMgr:isDownloadLobbyRes()
    return self:isDownloadLoadingRes()
end

-- 公共jackpot主游戏在关卡的入口
function CommonJackpotMgr:createEntryNode(_levelName)
    if not self:isCanShowLayer() then
        return nil
    end
    return util_createView("Activity.CommonJackpot.LevelEntry.CJEntryNode")
end

function CommonJackpotMgr:getEntryNodeSize()
    return cc.size(190, 235)
end

-- _startWorldPos:飞行的起点，必须是世界坐标系
function CommonJackpotMgr:playEntryFlyAction(_startWorldPos, _over)
    if not self:isCanShowLayer() or not self.m_entryNode then
        if _flyOver then
            _flyOver()
        end
        return nil
    end
    self:playSlotLight(
        _startWorldPos,
        function()
            -- 刷新入口界面
            if self.m_entryNode then
                self.m_entryNode:pubPlayShake()
            end
            if _over then
                _over()
            end
        end
    )
end

-- respin后播放飞向入口的动效
-- _startWorldPos:飞行的起点，世界坐标系
function CommonJackpotMgr:playSlotLight(_startWorldPos, _flyOver)
    local flyNode = util_createView("Activity.CommonJackpot.LevelEntry.CJEntryFlyNode")
    gLobalViewManager:getViewLayer():addChild(flyNode, ViewZorder.ZORDER_SPECIAL)
    flyNode:setName("CJEntryFlyNode")
    flyNode:setPosition(cc.p(_startWorldPos.x, _startWorldPos.y))
    flyNode:playStart(
        function()
            if not tolua.isnull(flyNode) then
                flyNode:removeFromParent()
            end
        end
    )
    util_performWithDelay(
        self.m_entryNode,
        function()
            self:flyToEntry(_startWorldPos, _flyOver)
        end,
        35 / 60
    )
end

-- 开始飞行
function CommonJackpotMgr:flyToEntry(_startWorldPos, _flyOver)
    local flyParticle = cc.ParticleSystemQuad:create("Activity/CommonJackpot/other/lizi/TR_shouji_trail.plist")
    gLobalViewManager:getViewLayer():addChild(flyParticle, ViewZorder.ZORDER_SPECIAL)
    flyParticle:setName("CJEntryFlyParticle")
    flyParticle:setScale(2)
    flyParticle:setPosition(cc.p(_startWorldPos.x, _startWorldPos.y))
    -- 动作列表
    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(0.5, self:getEntryNodePos())
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if _flyOver then
                _flyOver()
            end
            -- 播放爆炸
            local boom = util_createAnimation("Activity/CommonJackpot/csd/Jackpot/CommonJackpot_Entry_lizibaozha.csb")
            gLobalViewManager:getViewLayer():addChild(boom, ViewZorder.ZORDER_SPECIAL)
            boom:setName("CJEntryBoom")
            boom:setPosition(self:getEntryNodePos())
            boom:playAction(
                "start",
                false,
                function()
                    if not tolua.isnull(boom) then
                        boom:removeFromParent()
                    end
                end,
                60
            )
            -- 飞到后等会再移除，保留光散开的效果
            util_performWithDelay(
                self.m_entryNode,
                function()
                    if not tolua.isnull(flyParticle) then
                        flyParticle:removeFromParent()
                    end
                end,
                0.3
            )
        end
    )
    flyParticle:runAction(cc.Sequence:create(actionList))
end

-- 标题上打开的规则界面
function CommonJackpotMgr:showTitleInfoLayer()
    if gLobalViewManager:getViewByName("CJTitleInfoLayer") ~= nil then
        return nil
    end
    local view = util_createView("Activity.CommonJackpot.LevelTitle.CJTitleInfoLayer")
    view:setName("CJTitleInfoLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CommonJackpotMgr:requestStart(_key, _levelName)
    local function successFunc(_result)
        local data = self:getRunningData()
        if data then
            -- start请求后做一些数据存储和更新
            data:parsePlayData(_result)
            -- 清空当前档位的respin赢钱列表
            data:clearCurLevelWinAmount()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFI_CJ_REQUEST_START_RESULT, {isSuc = true})
        end
    end
    local function failureFunc()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_CJ_REQUEST_START_RESULT, {isSuc = false})
        gLobalViewManager:showReConnect()
    end
    G_GetNetModel(NetType.CommonJackpot):requestStart(_key, _levelName, successFunc, failureFunc)
end

function CommonJackpotMgr:checkGuide()
    -- 判断是否有数据
    local runningData = self:getRunningData()
    if not runningData then
        return false
    end
    -- 判断是否有资源
    if not self:isCanShowLayer() then
        return false
    end
    -- 判断关卡是否是公共jackpot关卡
    if not self:isRecmdJackpotLevel(globalData.slotRunData.machineData.p_name) then
        return false
    end
    if not CommonJackpotCfg.TEST_GUIDE then
        local guideId = gLobalDataManager:getNumberByField("CommonJackpot_guide_" .. globalData.userRunData.uid, 0)
        if guideId > 0 then
            return false
        end
    end
    return true
end

function CommonJackpotMgr:startGuide(_isGameTop)
    local guideId = -1
    if CommonJackpotCfg.TEST_GUIDE then
        if _isGameTop then
            self.m_guideId = 0
        end
        guideId = self.m_guideId
    else
        guideId = gLobalDataManager:getNumberByField("CommonJackpot_guide_" .. globalData.userRunData.uid, 0)
    end
    if guideId == 0 then
        if not self.m_slotTitleNode then
            return
        end
        if CommonJackpotCfg.TEST_GUIDE then
            self.m_guideId = self.m_guideId + 1
        else
            gLobalDataManager:setNumberByField("CommonJackpot_guide_" .. globalData.userRunData.uid, 1)
        end
        local mask =
            self:createLayout(
            function()
                self:stopGuide()
            end
        )
        self.m_slotTitleParent = self.m_slotTitleNode:getParent()
        self.m_slotTitleZorder = self.m_slotTitleNode:getLocalZOrder()
        self.m_slotTitleScale = self.m_slotTitleNode:getScale()
        local worldPos = self.m_slotTitleNode:getParent():convertToWorldSpace(cc.p(self.m_slotTitleNode:getPosition()))
        local localPos = mask:convertToNodeSpace(worldPos)
        util_changeNodeParent(mask, self.m_slotTitleNode, 1)
        self.m_slotTitleNode:setPosition(localPos)
        self.m_slotTitleNode:setScale(self.m_slotTitleScale)
        self.m_slotTitleNode:setTitleLight(true)

        local view = self:createGuideNode(1)
        view:setName("Guide")
        view:setScale(self.m_slotTitleScale)
        view:setPosition(cc.p(200, -300))
        self.m_slotTitleNode:addChild(view)
    elseif guideId == 1 then
        if not self.m_entryNode then
            return
        end
        if CommonJackpotCfg.TEST_GUIDE then
            self.m_guideId = self.m_guideId + 1
        else
            gLobalDataManager:setNumberByField("CommonJackpot_guide_" .. globalData.userRunData.uid, 2)
        end
        local mask = self:createLayout()
        self.m_entryParent = self.m_entryNode:getParent()
        self.m_entryZorder = self.m_entryNode:getLocalZOrder()
        self.m_entryScale = self.m_entryNode:getScale()
        local worldPos = self.m_entryNode:getParent():convertToWorldSpace(cc.p(self.m_entryNode:getPosition()))
        local localPos = mask:convertToNodeSpace(worldPos)
        util_changeNodeParent(mask, self.m_entryNode, 1)
        self.m_entryNode:setPosition(localPos)
        self.m_entryNode:setScale(self.m_entryScale)
        local view = self:createGuideNode(2)
        view:setName("Guide")
        view:setScale(self.m_entryScale)
        view:setPosition(cc.p(-150, 200))
        self.m_entryNode:addChild(view)
        self.m_entryNode:initSpine(true)
    end
end

function CommonJackpotMgr:stopGuide()
    local mask = gLobalViewManager:getViewLayer():getChildByName("commonjackpot_guide_touch")
    if mask then
        local function callFunc()
            local guideId = -1
            if CommonJackpotCfg.TEST_GUIDE then
                guideId = self.m_guideId
            else
                guideId = gLobalDataManager:getNumberByField("CommonJackpot_guide_" .. globalData.userRunData.uid, 0)
            end
            if guideId == 1 then
                local worldPos = self.m_slotTitleNode:getParent():convertToWorldSpace(cc.p(self.m_slotTitleNode:getPosition()))
                local localPos = self.m_slotTitleParent:convertToNodeSpace(worldPos)
                util_changeNodeParent(self.m_slotTitleParent, self.m_slotTitleNode, self.m_slotTitleZorder)
                self.m_slotTitleNode:setPosition(localPos)
                self.m_slotTitleNode:setScale(self.m_slotTitleScale)
                self.m_slotTitleNode:setTitleLight(false)
                self.m_slotTitleNode:removeChildByName("Guide")
            elseif guideId == 2 then
                local worldPos = self.m_entryNode:getParent():convertToWorldSpace(cc.p(self.m_entryNode:getPosition()))
                local localPos = self.m_entryParent:convertToNodeSpace(worldPos)
                util_changeNodeParent(self.m_entryParent, self.m_entryNode, self.m_entryZorder)
                self.m_entryNode:setPosition(localPos)
                self.m_entryNode:setScale(self.m_entryScale)
                self.m_entryNode:removeChildByName("Guide")
                self.m_entryNode:initSpine(false)
            end
            if not tolua.isnull(mask) then
                mask:removeFromParent()
            end
            self:startGuide()
        end
        mask:runAction(cc.Sequence:create(cc.FadeOut:create(0.3), cc.CallFunc:create(callFunc)))
    end
end

function CommonJackpotMgr:createLayout(_ClickFunc)
    local parentNode = gLobalViewManager:getViewLayer()
    local zorder = ViewZorder.ZORDER_GUIDE

    local tLayout = ccui.Layout:create()
    parentNode:addChild(tLayout, zorder)
    tLayout:setName("commonjackpot_guide_touch")
    tLayout:setAnchorPoint(cc.p(0.5, 0.5))
    tLayout:setContentSize(cc.size(display.width, display.height))
    tLayout:setPosition(cc.p(display.width / 2, display.height / 2))
    -- tLayout:setPosition(cc.p(0, 0))
    tLayout:setClippingEnabled(false)
    tLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    tLayout:setBackGroundColor(cc.c3b(0, 0, 0))
    tLayout:setBackGroundColorOpacity(190)
    tLayout:setTouchEnabled(true)
    tLayout:setSwallowTouches(true)
    if _ClickFunc then
        tLayout:addTouchEventListener(
            function()
                _ClickFunc()
            end
        )
    end
    -- 时间结束
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.CommonJackpot then
                local mask = gLobalViewManager:getViewLayer():getChildByName("commonjackpot_guide_touch")
                if not tolua.isnull(mask) then
                    mask:removeFromParent()
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
    tLayout:registerScriptHandler(
        function(tag)
            if tLayout == nil then
                return
            end
            if "exit" == tag then
                gLobalNoticManager:removeAllObservers(tLayout)
            end
        end
    )
    return tLayout
end

-- 切换bet是否显示气泡
function CommonJackpotMgr:isCanShowBetBubble()
    if not CommonJackpotMgr.super.isCanShowBetBubble(self) then
        return false
    end    
    -- 判断是否有数据
    local runningData = self:getRunningData()
    if not runningData then
        return false
    end
    if not runningData:getCurBetLevelData() then
        return false
    end
    -- 判断是否有资源
    if not self:isCanShowLayer() then
        return false
    end
    if not (globalData.slotRunData and globalData.slotRunData.machineData) then
        return false
    end
    -- 判断关卡是否是公共jackpot关卡
    if not self:isRecmdJackpotLevel(globalData.slotRunData.machineData.p_name) then
        return false
    end
    return true
end

function CommonJackpotMgr:getBetBubblePath(_refName)
    return "Activity/CommonJackpot/LevelBet/CJBetTipNode"
end


return CommonJackpotMgr
