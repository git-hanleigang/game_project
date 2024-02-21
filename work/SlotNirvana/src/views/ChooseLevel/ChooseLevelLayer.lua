---
-- 关卡Bet选择界面
--
local ChooseLevelLayer = class("ChooseLevelLayer", util_require("base.BaseView"))

local MAX_LOOP_FUNC_COUNT = 200
local TIP_COUNT = 2 -- 提示node最大数
local CONCAT_STR_LIST = {"", "_new"}

function ChooseLevelLayer:ctor()
    ChooseLevelLayer.super.ctor(self)

    self.m_siteType = nil
    self.m_siteName = nil
    self.m_gameType = nil

    self.m_levelImgPathN = ""
    self.m_levelImgPathH = ""
end

function ChooseLevelLayer:setSiteType(siteType)
    self.m_siteType = siteType
end

function ChooseLevelLayer:getSiteType()
    return self.m_siteType
end

function ChooseLevelLayer:setSiteName(siteName)
    self.m_siteName = siteName
end

function ChooseLevelLayer:getSiteName()
    return self.m_siteName
end

function ChooseLevelLayer:setGameType(gameType)
    self.m_gameType = gameType
end

function ChooseLevelLayer:getGameType()
    return self.m_gameType
end

function ChooseLevelLayer:initUI(_levelId, _bHideArrowBtn)
    self:createCsbNode("BetChoice/BetChoice_Mainlayer.csb")

    self.m_canTouch = false -- 是否可以触控
    self.m_bHideArrowBtn = _bHideArrowBtn -- 是否显示箭头
    self.m_loopCount = 0 -- 递归找level
    self.m_tipNodeList = {}

    -- 添加一个黑色底板
    self:maskShow(0)

    -- UI适配
    self:setUIAdaptScale()

    -- 是否显示 箭头按钮
    self:initArrowBtnState()

    -- 是否该开启 高倍场
    self.m_bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
    -- 高倍场按钮state（要有高倍场 都有高倍场 init一次就OK了）
    for i = 1, #CONCAT_STR_LIST do
        self:updateHightBtnState(CONCAT_STR_LIST[i])
    end

    -- 所有的关卡数据
    self.m_curIdx = self:getLevelInfoIdx(_levelId)
    self.m_allLevelList = globalData.slotRunData:getNormalMachineEntryDatas() --所有的数据(根据高赔偿是否开启来抉择)
    self.m_bClickHight = self.m_bOpenDeluxe -- 选择的是普通页签还是高倍场页签
    if self.m_bOpenDeluxe then
        -- 高倍场是否开启
        self.m_allLevelList = globalData.slotRunData:getHighMachineEntryDatas()
    end

    -- cur level
    self.m_curLevelImgVNormal = self:findChild("sp_level_normal") -- 普通场imgView
    self.m_curLevelImgVHigh = self:findChild("sp_level_high") -- 高倍场imgView
    self.m_curLevelImgVNormal:ignoreContentAdaptWithSize(true)
    self.m_curLevelImgVHigh:ignoreContentAdaptWithSize(true)
    -- new level
    self.m_newLevelImgVNormal = self:findChild("sp_level_normal_new")
    self.m_newLevelImgVHigh = self:findChild("sp_level_high_new")
    self.m_newLevelImgVNormal:ignoreContentAdaptWithSize(true)
    self.m_newLevelImgVHigh:ignoreContentAdaptWithSize(true)
    
    self:updateCurData(_levelId)
    self:updateLevelImgView(self.m_curLevelInfo.p_levelName)
    -- 更新热玩玩家UI
    self:updateHotPlayersUI(self.m_normalLevelInfo)
    self.m_btnadd = self:findChild("btn_addf")
    self.m_btnremove = self:findChild("btn_rmovef")
    self.node_action = self:findChild("ef_xin")
    if self.m_btnadd then
        self.m_btnadd:setVisible(false)
        self.m_btnremove:setVisible(false)
        self.node_action:setVisible(false)
        self:initCollectLevel(_levelId)
    end
end

function ChooseLevelLayer:initCollectLevel(_levelId)
    self.m_levelId = _levelId
    if G_GetMgr(G_REF.CollectLevel) and G_GetMgr(G_REF.CollectLevel):getData() then
        local status = G_GetMgr(G_REF.CollectLevel):getLevelById(_levelId)
        if status then
            self.m_btnremove:setVisible(true)
            self:setGameType("collect")
        else
            self.m_btnadd:setVisible(true)
            self:setGameType("noCollect")
        end
        self.m_act = util_createAnimation("BetChoice/BetChoice_Mainlayer_ef_xin.csb")
        self.node_action:addChild(self.m_act)
    end
end

function ChooseLevelLayer:upDateFavter(_levelId)
    local nodebtn = self:findChild("node_btn")
    if not nodebtn then
        return
    end
    self.m_levelId = _levelId
    if G_GetMgr(G_REF.CollectLevel) and G_GetMgr(G_REF.CollectLevel):getData() then
        local status = G_GetMgr(G_REF.CollectLevel):getLevelById(_levelId)
        if status then
            self.m_btnremove:setVisible(true)
            self.m_btnadd:setVisible(false)
            self:setGameType("collect")
        else
            self.m_btnremove:setVisible(false)
            self.m_btnadd:setVisible(true)
            self:setGameType("noCollect")
        end
    end
end

-- 设置内容的 缩放值
function ChooseLevelLayer:setLevelNodesScale(scale)
    -- 关卡
    for i, _cantatStr in ipairs(CONCAT_STR_LIST) do
        local nodeCurContent = self:findChild("nodeLevels" .. _cantatStr)
        local nodeNormal = nodeCurContent:getChildByName("node_normal")
        local nodeHigh = nodeCurContent:getChildByName("node_highroller")
        nodeNormal:setScale(scale)
        nodeHigh:setScale(scale)
    end
    -- 箭头
    local nodeArrow = self:findChild("node_arrow")
    local children = nodeArrow:getChildren()
    for i, node in ipairs(children) do
        node:setScale(scale)
    end
end

-- UI适配
function ChooseLevelLayer:setUIAdaptScale()
    local scale = display.width / CC_DESIGN_RESOLUTION.width
    self.m_csbNode:setScale(scale)
    -- 帘子适配到 高度与屏幕一样
    local spCurtainL = self:findChild("sp_lianzi_right_0")
    local spCurtainR = self:findChild("sp_lianzi_right")
    spCurtainL:setScale(spCurtainL:getScale() / scale)
    spCurtainR:setScale(spCurtainR:getScale() / scale)

    local tempHeight = display.height
    local heightSub = (1 - scale) * tempHeight * (1 / scale)
    self.m_heightSub = heightSub

    print("heightSub-------------",heightSub)

    -- 边界
    local borderMoveY = heightSub
    local nodeBorder = self:findChild("node_border")
    local nodeBorderPos = cc.p(nodeBorder:getPosition())
    nodeBorder:move(nodeBorderPos.x, nodeBorderPos.y + borderMoveY)

    -- 内容
    local contentMoveY = 0.5 * heightSub
    if scale > 1 then
        contentMoveY = borderMoveY
        self:setLevelNodesScale(1 / scale)
    end
    local nodeContent = self:findChild("node_content")
    local nodeContentPos = cc.p(nodeContent:getPosition())
    nodeContent:move(nodeContentPos.x, nodeContentPos.y + contentMoveY)

    
    -- 箭头
    local arrowMoveY = 0.5 * heightSub
    local nodeArrow = self:findChild("node_arrow")
    local nodeArrowPos = cc.p(nodeArrow:getPosition())
    nodeArrow:move(nodeArrowPos.x, nodeArrowPos.y + arrowMoveY)

    -- 更新热玩玩家UI
    local nodeHotPlayers = self:findChild("node_hotPlayers")
    nodeHotPlayers:setScale(1/scale)

    -- 底板隐藏
    local spBottomBgL = self:findChild("sp_diban_left")
    local spBottomBgR = self:findChild("sp_diban_right")
    spBottomBgL:setVisible(false)
    spBottomBgR:setVisible(false)
    local nodebtn = self:findChild("node_btn")
    if nodebtn then
        local nodebtnPos = cc.p(nodebtn:getPosition())
        if self.m_heightSub > 0 then
            self.m_nodepos = cc.p(nodebtnPos.x, nodebtnPos.y)
        else
            self.m_nodepos = cc.p(nodebtnPos.x, nodebtnPos.y - self.m_heightSub/2 + 10)
        end
        self:setBtnPos()
        --nodebtn:setVisible(false)
    end

    
end

function ChooseLevelLayer:setBtnPos()
    local nodebtn = self:findChild("node_btn")
    if nodebtn then
        nodebtn:move(self.m_nodepos)
        nodebtn:setVisible(true)
    end
end

-- 箭头显隐
function ChooseLevelLayer:initArrowBtnState()
    if not self.m_bHideArrowBtn then
        return
    end

    local nodeArrow = self:findChild("node_arrow")

    nodeArrow:setVisible(false)
end

-- 高倍场的按钮 显示状态
function ChooseLevelLayer:updateHightBtnState(_cantatStr)
    _cantatStr = _cantatStr or ""
    local spLock = self:findChild("sp_lock" .. _cantatStr)
    spLock:setVisible(not self.m_bOpenDeluxe)

    local curImgViewH = self:findChild("sp_level_high" .. _cantatStr)
    local color = self.m_bOpenDeluxe and 255 or 100
    curImgViewH:setColor(cc.c3b(color, color, color))

    local efHigh = self:findChild("ef_title" .. _cantatStr)
    efHigh:setVisible(self.m_bOpenDeluxe)

    if self.m_bOpenDeluxe then
        local csbAct = util_actCreate("BetChoice/BetChoice_Mainlayer_ef_title.csb")
        if csbAct then
            efHigh:runAction(csbAct)
            util_csbPlayForKey(csbAct, "idle", true)
        end
        return
    end

    if #self.m_tipNodeList > TIP_COUNT then
        return
    end

    local nodeTip = self:findChild("sp_bubble" .. _cantatStr)
    local highTipNode = util_createView("views/ChooseLevel/ChooseLevelHighTip")
    highTipNode:addTo(nodeTip)
    table.insert(self.m_tipNodeList, highTipNode)
end

-- 改变高倍场气泡状态
function ChooseLevelLayer:changeHighTipNodeState()
    for i = 1, TIP_COUNT do
        local tipNode = self.m_tipNodeList[i]
        if tolua.isnull(tipNode) then
            return
        end

        tipNode:changeShowState()
    end
end

-- 当前关卡的所有数据
function ChooseLevelLayer:updateCurData(_levelId)
    -- 普通场和 高倍场的 关卡id
    self.m_normalLevelId = self:exchangeLevelId("1", _levelId)
    self.m_highLevelId = self:exchangeLevelId("2", _levelId)

    -- 获取当前 levelid对应的 信息 和 所在集合的idx
    self.m_normalLevelInfo = self:getLevelInfo(self.m_normalLevelId)
    self.m_highLevelInfo = self:getLevelInfo(self.m_highLevelId)

    -- 当前显示的 关卡数据
    self:updateCurLevelInfo()
end

-- 更新关卡图
function ChooseLevelLayer:updateLevelImgView(_levelName, _bNew)
    self.m_levelImgPathN = globalData.GameConfig:getLevelIconPath(_levelName, LEVEL_ICON_TYPE.SMALL)
    self.m_levelImgPathH = globalData.GameConfig:getLevelIconPath(_levelName, LEVEL_ICON_TYPE.SMALL)

    local imgViewNormal = self.m_curLevelImgVNormal
    local imgViewHigh = self.m_curLevelImgVHigh
    if _bNew then
        imgViewNormal = self.m_newLevelImgVNormal
        imgViewHigh = self.m_newLevelImgVHigh
    end
    util_changeTexture(imgViewNormal, self.m_levelImgPathN)
    util_changeTexture(imgViewHigh, self.m_levelImgPathH)
end

-- 当前显示的 关卡数据
function ChooseLevelLayer:updateCurLevelInfo()
    if self.m_bClickHight then
        self.m_curLevelInfo = self.m_highLevelInfo
        return
    end
    self.m_curLevelInfo = self.m_normalLevelInfo
end

-- 切换当前 关卡 信息
function ChooseLevelLayer:changeCurLevelInfo(_bNext, _newCustomLevelInfo)
    if _newCustomLevelInfo.levelIdx then
        self.m_curIdx = _newCustomLevelInfo.levelIdx
    else
        self.m_curIdx = self:getNewLevelIdx(self.m_curIdx, _bNext)
    end


    local levelInfo = _newCustomLevelInfo.levelInfo
    if not levelInfo then
        levelInfo = self.m_allLevelList[self.m_curIdx]
    end
    self:updateCurData(levelInfo.p_id)
    self:updateLevelImgView(levelInfo.p_levelName)
end

-- level 按下状态
function ChooseLevelLayer:updateAllLevelNodePressSate(_bTouch, _bHigh)
    for i = 1, #CONCAT_STR_LIST do
        self:updateSingleLevelNodePressSate(CONCAT_STR_LIST[i], _bTouch, _bHigh)
    end
end

-- level 按下状态 single
function ChooseLevelLayer:updateSingleLevelNodePressSate(_cantatStr, _bTouch, _bHigh)
    local nodeCurContent = self:findChild("nodeLevels" .. _cantatStr)

    if tolua.isnull(nodeCurContent) then
        return
    end

    local nodeNormal = nodeCurContent:getChildByName("node_normal")
    local nodeHigh = nodeCurContent:getChildByName("node_highroller")
    local efHigh = self:findChild("ef_title" .. _cantatStr)

    local color = 255
    if _bTouch then
        color = 127
    end
    if _bHigh then
        nodeNormal:setColor(cc.c3b(255, 255, 255))
        nodeHigh:setColor(cc.c3b(color, color, color))
        efHigh:setVisible(color == 255)
    else
        nodeNormal:setColor(cc.c3b(color, color, color))
        nodeHigh:setColor(cc.c3b(255, 255, 255))
    end
end

-- 更新 新节点 的 关卡图
function ChooseLevelLayer:updateNewLevelInfo(_bNext)
    -- 上一关 信息
    local levelIdx = self:getNewLevelIdx(self.m_curIdx, _bNext)
    local levelInfo = self.m_allLevelList[levelIdx]
    if not levelInfo then
        return {}
    end

    self:updateLevelImgView(levelInfo.p_levelName, true)

    local newInfo = {}
    newInfo.levelIdx = levelIdx
    newInfo.levelInfo = levelInfo
    return newInfo
end

-- 更新热玩玩家UI
function ChooseLevelLayer:createHotPlayersUI()
    local parent = self:findChild("node_hotPlayers")
    self.m_hotPlayersView = util_createView("views.ChooseLevel.SlotHotPlayerListUI", self.m_csbNode:getScale())
    parent:addChild(self.m_hotPlayersView)
    util_setCascadeOpacityEnabledRescursion(parent, true)
end
function ChooseLevelLayer:updateHotPlayersUI(_levelInfo)
    if not self.m_hotPlayersView then
        self:createHotPlayersUI()
    end

    if not _levelInfo then
        return
    end

    local normalLevelId = self:exchangeLevelId("1", _levelInfo.p_id)
    local normalLevelInfo = self:getLevelInfo(normalLevelId)

    if not normalLevelInfo then
        return
    end

    self.m_hotPlayersView:updatePlayersUI(normalLevelInfo.p_name)
end

-- 切换关卡 动画
function ChooseLevelLayer:playChangeLevelAct(_bNext)
    if self.m_bHideArrowBtn then
        return
    end

    local actName = _bNext and "right" or "left"
    self.m_canTouch = false

    -- 更新 新关卡节点UI
    local newCustomLevelInfo = self:updateNewLevelInfo(_bNext)
    self:updateHotPlayersUI(newCustomLevelInfo.levelInfo)
    self:runCsbAction(
        actName,
        false,
        function()
            self.m_canTouch = true
            self:changeCurLevelInfo(_bNext, newCustomLevelInfo)
            --self:setBtnPos()
            self:upDateFavter(tonumber(self.m_normalLevelId))
        end,
        60
    )
end

function ChooseLevelLayer:onEnter()
    self:runCsbAction(
        "actionframe",
        false,
        function()
            if tolua.isnull(self) then
                return
            end
            self.m_canTouch = true
            self:runCsbAction("idle")
            self:setBtnPos()
        end,
        60
    )

    -- 高倍场到期结束
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 是否该开启 高倍场
            self.m_bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
            -- 高倍场按钮state（要有高倍场 都有高倍场 init一次就OK了）
            for i = 1, #CONCAT_STR_LIST do
                self:updateHightBtnState(CONCAT_STR_LIST[i])
            end
        end,
        ViewEventType.NOTIFY_DELUXECLUB_OVER
    )
end

function ChooseLevelLayer:onExit()
    if self.m_levelImgPathN ~= "" then
        display.removeImage(self.m_levelImgPathN)
        self.m_levelImgPathN = ""
    end
    if self.m_levelImgPathH ~= "" then
        display.removeImage(self.m_levelImgPathH)
        self.m_levelImgPathH = ""
    end
    ChooseLevelLayer.super.onExit(self)
end

function ChooseLevelLayer:onKeyBack()
    self:closeUI()
end

function ChooseLevelLayer:closeUI()
    if not self.m_canTouch then
        return
    end
    self.m_canTouch = false
    local nodebtn = self:findChild("node_btn")
    if nodebtn then
        nodebtn:setVisible(false)
    end
    self:runCsbAction(
        "over",
        false,
        function()
            self:removeSelf()
        end,
        60
    )
    util_setCascadeOpacityEnabledRescursion(self:findChild("node_hotPlayers"), true)
end

--点击监听
function ChooseLevelLayer:clickStartFunc(sender)
    local name = sender:getName()
    if name == "btn_touch" then
        local touchPos = sender:getTouchBeganPosition()

        local bTouchInsideN = self:checkoutTouchedInLevelNods(touchPos)
        local bTouchInsideH = self:checkoutTouchedInLevelNods(touchPos, true)
        if bTouchInsideN then
            -- 普通场
            self:updateAllLevelNodePressSate(true)
        elseif bTouchInsideH then
            -- 高倍场
            self:updateAllLevelNodePressSate(true, true)
        end
    end
end

--结束监听
function ChooseLevelLayer:clickEndFunc(sender)
    local name = sender:getName()
    if name ~= "btn_touch" then
        return
    end

    self:updateAllLevelNodePressSate(false)
    self:updateAllLevelNodePressSate(false, true)

    local beginPos = sender:getTouchBeganPosition()
    local endPos = sender:getTouchEndPosition()
    local offx = endPos.x - beginPos.x
    if offx < -100 then
        -- next
        self:playChangeLevelAct(true)
    elseif offx > 100 then
        -- pre
        self:playChangeLevelAct()
    elseif math.abs(offx) <= 20 then
        local bTouchInsideN = self:checkoutTouchedInLevelNods(beginPos)
        local bTouchInsideH = self:checkoutTouchedInLevelNods(beginPos, true)

        if bTouchInsideN then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

            -- 普通场
            self.m_bClickHight = false
            self:updateCurLevelInfo()
            util_nextFrameFunc(
                function()
                    if tolua.isnull(self) then
                        return
                    end
                    if self.enterLevel then
                        -- bugly有人 attempt to call method 'enterLevel' (a nil value)
                        self:enterLevel()
                    end
                end
            )
        elseif bTouchInsideH then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

            -- 高倍场
            self.m_bClickHight = true
            self:updateCurLevelInfo()
            util_nextFrameFunc(
                function()
                    if tolua.isnull(self) then
                        return
                    end
                    if self.enterLevel then
                        -- bugly有人 attempt to call method 'enterLevel' (a nil value)
                        self:enterLevel()
                    end
                end
            )
        end
    end
end

function ChooseLevelLayer:clickFunc(sender)
    if not self.m_canTouch then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
  
    if name == "btn_close" then
        sender:setEnabled(false)
        self:closeUI()
    elseif name == "btn_jiantou_left" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:playChangeLevelAct(false)
    elseif name == "btn_jiantou_right" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:playChangeLevelAct(true)
    elseif name == "btn_addf" then
        --添加收藏
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:playNodeAction()
        local _callback = function(_type)
            if tolua.isnull(self) then
                return
            end
            self.m_btnadd:setVisible(false)
            self.m_btnremove:setVisible(true)
        end
        G_GetMgr(G_REF.CollectLevel):sendAddListReq(self.m_levelId,_callback)
    elseif name == "btn_rmovef" then
        --删除收藏
        --self:playNodeAction()
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local _callback = function(_type)
            if tolua.isnull(self) then
                return
            end
            self.m_btnadd:setVisible(true)
            self.m_btnremove:setVisible(false)
        end
        G_GetMgr(G_REF.CollectLevel):sendRemoveListReq(self.m_levelId,_callback)
    end
end

function ChooseLevelLayer:playNodeAction()
    if not self.m_upda then
        self.m_upda = true
        self.node_action:setVisible(true)
        self.m_act:playAction("start",false,function()
            self.m_upda = false
            self.node_action:setVisible(false)
        end)
    end
end

-- 是否是高倍场的关卡id
function ChooseLevelLayer:isDeluxeLevelId(_levelId)
    if not _levelId then
        return
    end

    local idStr = tostring(_levelId)
    local type = string.sub(idStr, 1, 1)
    return tonumber(type) == 2
end

-- 获取当前 关卡所在idx
function ChooseLevelLayer:getLevelInfoIdx(_levelId)
    local bDeluxe = self:isDeluxeLevelId(_levelId)

    local levelInfoList = globalData.slotRunData:getNormalMachineEntryDatas()
    if bDeluxe then
        levelInfoList = globalData.slotRunData:getHighMachineEntryDatas()
    end
    for i = 1, #levelInfoList do
        local info = levelInfoList[i]
        if tonumber(info.p_id) == tonumber(_levelId) then
            return i
        end
    end

    return 1
end

function ChooseLevelLayer:getLevelInfo(_levelId)
    local bDeluxe = self:isDeluxeLevelId(_levelId)

    local levelInfoList = globalData.slotRunData:getNormalMachineEntryDatas()
    if bDeluxe then
        levelInfoList = globalData.slotRunData:getHighMachineEntryDatas()
    end
    for i = 1, #levelInfoList do
        local info = levelInfoList[i]
        if tonumber(info.p_id) == tonumber(_levelId) then
            return info
        end
    end

    return {}
end

-- 改变 levelid  普通场以 1 开头， 高倍场以 2 开头
function ChooseLevelLayer:exchangeLevelId(_preStr, _levelId)
    local idStr = tostring(_levelId)
    local subIdStr = string.sub(idStr, 2)
    return _preStr .. subIdStr
end

function ChooseLevelLayer:getLevelIsOpen(_chooseIdx)
    local levelInfo = self.m_allLevelList[_chooseIdx]
    if not levelInfo then
        return false
    end

    --根据app版本检测关卡是否可以进入
    if not gLobalViewManager:checkEnterLevelForApp(levelInfo.p_id) then
        return false
    end

    --敬请期待
    local levelName = levelInfo.p_levelName
    if levelName == "CommingSoon" then
        return false
    end

    --维护中
    local maintain = levelInfo.p_maintain
    if maintain then
        return false
    end

    --当前版本不支持
    local levelVersion = levelInfo.p_levelVersion
    if levelVersion then
        local fieldValue = util_getUpdateVersionCode(false)
        local curVersion = tonumber(fieldValue)

        if curVersion < tonumber(levelVersion) then
            return false
        end
    end

    --未解锁
    local curLevel = globalData.userRunData.levelNum
    local openLevel = levelInfo.p_openLevel
    if tonumber(curLevel) < tonumber(openLevel) then
        return false
    end

    -- 资源是否下载了 0未下载 1已下载未更新 2已下载已更新
    local notifyName = util_getFileName(levelInfo.p_csbName)
    local bDownLoading = globalDynamicDLControl:checkDownloading(notifyName)
    if bDownLoading then
        return false
    end

    return true
end

-- 切换关卡 获取新关卡信息
function ChooseLevelLayer:getNewLevelIdx(_baseIdx, _bNext)
    if self.m_loopCount > MAX_LOOP_FUNC_COUNT then
        self.m_loopCount = 0
        return self.m_curIdx
    end
    self.m_loopCount = self.m_loopCount + 1

    local levelIdx = _baseIdx
    if _bNext then
        levelIdx = levelIdx + 1
    else
        levelIdx = levelIdx - 1
    end

    if levelIdx < 1 then
        levelIdx = #self.m_allLevelList
    elseif levelIdx > #self.m_allLevelList then
        levelIdx = 1
    end

    local bOpen = self:getLevelIsOpen(levelIdx)
    if not bOpen then
        return self:getNewLevelIdx(levelIdx, _bNext)
    end

    self.m_loopCount = 0
    return levelIdx
end

-- 进入关卡
function ChooseLevelLayer:enterLevel()
    if self.m_bClickHight and not self.m_bOpenDeluxe then
        self:changeHighTipNodeState()
        return
    end

    if not self.m_curLevelInfo or not next(self.m_curLevelInfo) then
        return
    end
    
    local siteType = self:getSiteType()
    if not siteType then
        if globalData.deluexeClubData:getDeluexeClubStatus() and self.m_curLevelInfo.p_highBetFlag then
            siteType = "HightArea"
        else
            siteType = "RegularArea"
        end
    end

    --下载入口记录
    if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL then
        if globalData.deluexeClubData:getDeluexeClubStatus() and self.m_curLevelInfo.p_highBetFlag then
            gLobalSendDataManager:getLogGameLevelDL():setDownloadInfo(self.m_curLevelInfo.p_levelName, {type = "Hight"})
        end
    end
    -- gLobalSendDataManager:getLogSlots():setEnterLevelSiteType(siteType)
    -- gLobalSendDataManager:getLogSlots():setEnterLevelName(self.m_curLevelInfo.p_levelName, self.m_curLevelInfo.p_name)
    -- gLobalViewManager:gotoSceneByType(SceneType.Scene_Game)
    gLobalViewManager:gotoSlotsScene(self.m_curLevelInfo, siteType, nil, self:getGameType())
end

-- 是否点击到的 关卡 节点上
function ChooseLevelLayer:checkoutTouchedInLevelNods(_touchPos, _bHigh)
    local curLevelNode = self:findChild("sp_normalmachine")
    local newLevelNode = self:findChild("sp_normalmachine_new")
    if _bHigh then
        curLevelNode = self:findChild("sp_highrollermachine")
        newLevelNode = self:findChild("sp_highrollermachine_new")
    end

    local bCur = self:checkoutTouched(curLevelNode, _touchPos)
    local bNew = self:checkoutTouched(newLevelNode, _touchPos)

    return bCur or bNew
end

-- 是否点击到的 node 中
function ChooseLevelLayer:checkoutTouched(_node, _touchPos)
    if tolua.isnull(_node) then
        return
    end

    local bVisible = _node:isVisible()
    if not bVisible then
        return
    end

    local boxRect = _node:getBoundingBox()
    local localPos = _node:getParent():convertToNodeSpace(_touchPos)
    local bTouchInside = cc.rectContainsPoint(boxRect, localPos)

    return bTouchInside
end

return ChooseLevelLayer
