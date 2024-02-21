-- Created by jfwang on 2019-05-21.
-- QuestNewUserCell
--

local QuestCell = require("baseQuestCode.cell.QuestCell")
local QuestNewUserCell = class("QuestNewUserCell", QuestCell)

local CELL_STATE = {
    LOCKED = "LOCKED", -- 锁定
    UNLOCK = "UNLOCK", -- 解锁
    PLAYING = "PLAYING", -- 开启中
    FINISHED = "FINISHED", -- 完结未结算
    REWARD = "REWARD", -- 奖励已领取
    COMPLETE = "COMPLETE" -- 关卡完成
}

function QuestNewUserCell:getCsbNodePath()
    return QUEST_RES_PATH.QuestCell
end

function QuestNewUserCell:initDatas(data)
    --阶段序号
    self.m_curPhase = data.phase
    --关卡序号
    self.m_curStage = data.stage
    --唯一标示
    self.m_index = data.index

    --当前关卡数据
    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not act_data then
        return
    end
    self.m_data = act_data:getStageData(self.m_curPhase, self.m_curStage)
    self.m_info = globalData.slotRunData:getLevelInfoById(self.m_data.p_gameId)
end

function QuestNewUserCell:getIndex()
    return self.m_index
end

function QuestNewUserCell:initUI()
    self:createCsbNode(self:getCsbNodePath())

    self:initView()
    self:initInfo()
    self:initState()
end

function QuestNewUserCell:initView()
    if self.m_data == nil then
        return
    end

    self:updateQuestIcon()
end

function QuestNewUserCell:initCsbNodes()
    self.m_logoNode = self:findChild("logo")
    self.m_logoNode1 = self:findChild("logo1")

    local btn_click = self:findChild("btn_click")
    if btn_click then
        self:addClick(btn_click)
        btn_click:setSwallowTouches(false)
    end
end

-- 获得Spine资源名称
function QuestNewUserCell:getSpineFileName(levelName, prefixName)
    prefixName = prefixName or ""
    local fileName = prefixName .. "_level_spine_" .. levelName
    if globalData.GameConfig:checkLevelGroupA(levelName) then
        -- 是AB Test的 A 组
        fileName = fileName .. "_abtest"
    end
    return fileName
end

-- 获得Spin资源信息
function QuestNewUserCell:getSpineFileInfo(levelName, prefixName)
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

function QuestNewUserCell:updateQuestIcon()
    --关卡头像
    local levelName = globalData.slotRunData:getLevelName(self.m_data.p_gameId)
    if levelName then
        local level_icon = self:showSpine(levelName)
        local bMoveY
        if not level_icon then
            level_icon = self:showSprite(levelName)
            bMoveY = true -- cashlink_Small_loading图上边有留白，位置不对
        end
        if level_icon then
            if self.m_sp_cell then
                level_icon:setColor(self.m_sp_cell:getColor())
            end
            level_icon:setName("level_icon")
            self.m_logoNode:removeChildByName("level_icon")
            self.m_logoNode:addChild(level_icon)
            self.m_sp_cell = level_icon
            self.m_sp_cell:setPositionY(bMoveY and 20 or 0)
            -- self.m_sp_cell:setScale(0.8)
        end
    end
end

function QuestNewUserCell:showSpine(levelName)
    local spine = nil
    local isExist, spinepath, spineTexture = self:getSpineFileInfo(levelName, LEVEL_ICON_TYPE.SMALL)
    if isExist then
        spine = util_spineCreate(spinepath, true, true, 1)
        if spine then
            util_spinePlay(spine, "actionframe", true)
        end
    end
    return spine
end

function QuestNewUserCell:showSprite(levelName)
    local p_sprite = nil

    local loading_path = "newIcons/Order/cashlink_Small_loading.png" -- 矩形图
    p_sprite = util_createSprite(loading_path)
    local notifyName = util_getFileName(self.m_info.p_csbName)
    if globalDynamicDLControl:checkDownloading(notifyName) then
        --注册下载通知
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                if not tolua.isnull(self) then
                    self:updateQuestIcon()
                end
            end,
            notifyName
        )
    end
    return p_sprite
end

function QuestNewUserCell:isRewarded()
    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not act_data then
        return true
    end
    if act_data:getPhaseIdx() == self.m_curPhase and act_data:getStageIdx() == self.m_curStage and self:getCellState() == CELL_STATE.FINISHED then
        return false
    end
    return true
end

function QuestNewUserCell:showFinished()
    if self:isRewarded() then
        self:changeState(CELL_STATE.COMPLETE)
    else
        self:changeState(CELL_STATE.REWARD)
    end
end

function QuestNewUserCell:showOnRewarded()
    local data_record = clone(self.m_data)
    data_record.phase_idx = self.m_curPhase
    data_record.stage_idx = self.m_curStage
    data_record.m_index = self.m_index
    G_GetMgr(ACTIVITY_REF.Quest):setRecordRewardData(data_record)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not tolua.isnull(self) then
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE)
                self:onMsgRewarded(params)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE
    )

    gLobalSendDataManager:getNetWorkFeature():sendActionQuestNewUserNextStage()
end

function QuestNewUserCell:onMsgRewarded(bl_success)
    if not bl_success then
        return
    end

    gLobalNoticManager:addObserver(
        self,
        function()
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_QUEST_CLOSEBOX_NEXTSTAGE)
            self:changeState(CELL_STATE.REWARD)
        end,
        ViewEventType.NOTIFY_QUEST_CLOSEBOX_NEXTSTAGE
    )

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_CELL_REWARD)
end

function QuestNewUserCell:clicked()
    return self.m_clicked
end

function QuestNewUserCell:setClicked(bl_clicked)
    if self.m_clicked == bl_clicked then
        return
    end
    if bl_clicked then
        if self.click_delay then
            self:stopAction(self.click_delay)
            self.click_delay = nil
        end
        self.click_delay =
            util_performWithDelay(
            self,
            function()
                if not tolua.isnull(self) then
                    self.click_delay = nil
                    self.m_clicked = false
                end
            end,
            0.5
        )
    end
    self.m_clicked = bl_clicked
end

function QuestNewUserCell:clickFunc(sender)
    if self:clicked() then
        return
    end

    local name = sender:getName()
    if name == "btn_click" then
        self:setClicked(true)
        self:onTouchClick(true)
    end
end

--新手引导
function QuestNewUserCell:checkGuide()
    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if act_data and act_data.p_expireAt then
        --轮盘引导
        local isWheelGuide = gLobalDataManager:getBoolByField("quest_wheelGuide" .. act_data.p_expireAt, true)
        if isWheelGuide then
            return true
        end
    end
    return false
end

return QuestNewUserCell
