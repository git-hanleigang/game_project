
local CollectCell = class("CollectCell", BaseView)
local LevelRecmdData = require("views.lobby.LevelRecmd.LevelRecmdData")

function CollectCell:initUI()
    self:createCsbNode("CollectionLevel/csd/Activity_CollectionLevel_Cell.csb")
    self:initView()
end

function CollectCell:initView()
    self.m_scale = self:getUIScalePro()
    local root = self:findChild("root")
    root:setScale((1/self.m_scale)*1.1)
    self.m_contents = self:findChild("bg")
    self.m_contents:ignoreContentAdaptWithSize(true) -- imageView忽略大小适配，不然关卡图变形了
    self.m_label_comson = self:findChild("label_comson")
    self.m_node_spine = self:findChild("node_spine")
    local btn_enter = self:findChild("btn_enter")
    btn_enter:setSwallowTouches(false)
end

-- 更新锁状态
function CollectCell:updateLockState(_bClick)
    if not self.m_lockNode then
        return
    end

    local bOpen = self:checkGameLevelOpen()
    if bOpen then
        self.m_lockNode:setVisible(false)
        return
    end

    local actName = _bClick and "suo" or "suo2"
    local cb
    if _bClick then
        self:addBlackLayer()
        cb = function()
            self:clearBlackLayer()
            self.m_lockNode:playAction("suo2")
        end
    end
    self.m_lockNode:setVisible(true)
    self.m_lockNode:playAction(actName, false, cb, 60)
end

function CollectCell:updataCell(_data)
    if not _data.levelname then
        return
    end
    self.m_contents:setVisible(true)
    self.solt_id = _data.levelname
    local leveinfo = globalData.slotRunData:getLevelInfoById(_data.levelname)
    if leveinfo then
        self.m_label_comson:setVisible(false)
        self:initNoSpinLogo(leveinfo.p_levelName)
        self:initSpineFileInfo(leveinfo.p_levelName)
        if not self:checkGameLevelOpen() then
            self:initUnlock()
        end
    end
end

function CollectCell:initUnlock()
    --锁
    local parent = self:findChild("node_lock")
    self.m_lockNode = util_createAnimation("newIcons/Level_kongjian/Level_suo_small.csb")
    parent:addChild(self.m_lockNode, 1)
    self.m_lockNode:playAction("suo2")
    local levelOpenLv = 1
    local machineData = globalData.slotRunData:getLevelInfoById(self.solt_id)
    if machineData then
        levelOpenLv = tonumber(machineData.p_openLevel) or 1
    end
    if self.m_lockNode then
        local m_lb_level = self.m_lockNode:findChild("m_lb_level")
        if m_lb_level then
            m_lb_level:setString("LEVEL  " .. levelOpenLv)
        end
    end
end

function CollectCell:addBlackLayer()
    self.m_node_spine:setColor(cc.c3b(100, 100, 100))
end
--移除遮罩
function CollectCell:clearBlackLayer()
    self.m_node_spine:setColor(cc.c3b(255, 255, 255))
end

--检测是否解锁
function CollectCell:playClickUnLockAction()
    if not self.m_lockNode then
        return
    end
    if self.m_isPlayUnLock then
        return
    end
    self.m_isPlayUnLock = true
    self:addBlackLayer()
    self.m_lockNode:playAction("suo")
    local time = 1
    performWithDelay(
        self,
        function()
            self.m_lockNode:playAction("fromlevel_over")
        end,
        time
    )
    performWithDelay(
        self,
        function()
            self.m_isPlayUnLock = false
            self:clearBlackLayer()
        end,
        time + 0.3
    )
end
--设置锁
function CollectCell:showlock()
    if self.m_lockNode then
        self.m_lockNode:setVisible(true)
    end
end
--隐藏锁
function CollectCell:hidelock()
    if self.m_lockNode then
        self.m_lockNode:setVisible(false)
    end
end

function CollectCell:initSpineFileInfo(levelName)
    self.m_isExist, self.m_spinepath, self.m_spineTexture = self:getSpinFileInfo(levelName, "small")
    if self.m_isExist then
        local spineNode = util_spineCreate(self.m_spinepath, true, true, 1)
        self.m_node_spine:addChild(spineNode)
        spineNode:setPosition(0,0)
        self.m_contents:setVisible(false)
        local bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
        if bOpenDeluxe then
            util_spinePlay(spineNode, "deluxeActionframe", true)
        else
            util_spinePlay(spineNode, "actionframe", true)
        end
    end
end

-- 初始化非Spin资源logo
function CollectCell:initNoSpinLogo(_name)
    local path = nil
    if _name == "CommingSoon" then
        return
    end
    local _bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
    if _bOpenDeluxe then
        path = globalData.GameConfig:getLevelIconPath(_name, LEVEL_ICON_TYPE.DELUXE)
    else
        path = globalData.GameConfig:getLevelIconPath(_name, LEVEL_ICON_TYPE.SMALL)
    end
    util_changeTexture(self.m_contents, path)
end

-- 获得Spin资源信息
function CollectCell:getSpinFileInfo(levelName, prefixName)
    local spineName = self:getSpineFileName(levelName, prefixName)
    local spinepath = "LevelNodeSpine/" .. spineName
    local spinePngName = self:getSpineFileName(levelName, "common")
    local spinePngPath = "LevelNodeSpine/" .. spinePngName
    local spineTexture = spinePngPath .. ".png"
    local pngFullPath = CCFileUtils:sharedFileUtils():fullPathForFilename(spineTexture)
    local isPngExist = CCFileUtils:sharedFileUtils():isFileExist(pngFullPath)
    if not isPngExist then
        spineTexture = spinepath .. ".png"
    end

    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(spinepath .. ".skel")
    local isExist = CCFileUtils:sharedFileUtils():isFileExist(fileNamePath)
    if not isExist then
        return false, "", ""
    else
        return true, spinepath, spineTexture
    end
end

-- 获得Spine资源名称
function CollectCell:getSpineFileName(levelName, prefixName)
    prefixName = prefixName or ""
    local fileName = prefixName .. "_level_spine_" .. levelName
    if globalData.GameConfig:checkLevelGroupA(levelName) then
        -- 是AB Test的 A 组
        fileName = fileName .. "_abtest"
    end
    return fileName
end

function CollectCell:clickCell()
    if not self.solt_id then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local bOpen = self:checkGameLevelOpen()
    if not bOpen then
        self:playClickUnLockAction()
        return
    end
    --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECTLEVEL_CLOSE)
    if gLobalViewManager:isLobbyView() then
        self:showChooseLevelLayer()
    elseif gLobalViewManager:isLevelView() then
        self:gotoOtherGameScene()
    end
end

--是否解锁
function CollectCell:checkGameLevelOpen()
    local machineData = globalData.slotRunData:getLevelInfoById(self.solt_id)
    local isUnlock = false
    -- 判断是否在解锁等级的关卡分类中
    -- local LevelRecmdData = require("views.lobby.LevelRecmd.LevelRecmdData")
    if LevelRecmdData then
        isUnlock = isUnlock or LevelRecmdData:getInstance():isLevelUnlock(machineData.p_name)
    end

    -- AllGamesUnlockedData 活动判断
    isUnlock = isUnlock or G_GetMgr(ACTIVITY_REF.AllGamesUnlocked):isRunning()
    local levelOpenLv = tonumber(machineData.p_openLevel) or 1
    local curLevel = globalData.userRunData.levelNum
    isUnlock = isUnlock or (curLevel >= levelOpenLv)

    return isUnlock
end

-- 大厅打开 关卡选择页面
function CollectCell:showChooseLevelLayer()  

    if globalData.GameConfig:checkChooseBetOpen() then
        -- 打开 选择level界面
        local view = util_createView("views.ChooseLevel.ChooseLevelLayer", self.solt_id)
        if view then
            view:setSiteType("likePage")
            view:setSiteName("likePage")
        end
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    else
        gLobalViewManager:lobbyGotoGameScene(self.solt_id)
    end
end

-- 关卡跳转关卡
function CollectCell:gotoOtherGameScene()
    local curMachineData = globalData.slotRunData.machineData
    if not curMachineData then
        return
    end

    local gotoGameId = self.solt_id
    if curMachineData:isHightMachine() then
        gotoGameId = "2" .. string.sub(tostring(gotoGameId) or "", 2)
    end

    performWithDelay(display:getRunningScene(), function()
        gLobalViewManager:gotoSceneByLevelId(gotoGameId)
    end, 0.3)
end

-- -- 检查关卡是否开启
-- function CollectCell:checkGameLevelOpen()
--     local machineData = globalData.slotRunData:getLevelInfoById(self.solt_id)
--     local curLv = globalData.userRunData.levelNum
--     local levelOpenLv = tonumber(machineData.p_openLevel) or 1
--     local bOpen = false
--     if machineData and curLv >= levelOpenLv then
--         bOpen = true
--     end

--     return bOpen
-- end

function CollectCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_enter" then
        if self.solt_id then
            self:clickCell()
        else
            --点击去说明界面
            G_GetMgr(G_REF.CollectLevel):showRuleLayer()
        end
    end
end

return CollectCell