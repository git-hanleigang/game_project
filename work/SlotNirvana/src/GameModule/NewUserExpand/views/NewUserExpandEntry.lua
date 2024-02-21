--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-06 15:02:36
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-06 15:03:12
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/NewUserExpandEntry.lua
Description: 扩圈系统入口
--]]
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local NewUserExpandEntry = class("NewUserExpandEntry", BaseView)

function NewUserExpandEntry:initDatas()
    NewUserExpandEntry.super.initDatas(self)

    self.m_actNameList_idle = {"idle_slots", "idle_puzzle", "idle_colLevels"}
    self.m_actNameList_ani = {"slots", "puzzle", "colLevels"}
    self.m_chooseType = G_GetMgr(G_REF.NewUserExpand):getCurLobbyStyle()
    self.m_bColLelvesOpen = G_GetMgr(G_REF.CollectLevel):checkColLevelsOpen()
    self:setName("NewUserExpandEntry")
end

function NewUserExpandEntry:getCsbName()
    if self.m_bColLelvesOpen then
        return "NewUser_Expend/Activity/csd/NewUser_Entry_2.csb"
    end
    return "NewUser_Expend/Activity/csd/NewUser_Entry.csb"
end

function NewUserExpandEntry:initUI()
    NewUserExpandEntry.super.initUI(self)

    -- 更新标签显隐
    self:updateTagVisible()
    -- 按钮状态
    self:updateBtnEnabled()
end

function NewUserExpandEntry:onEnter()
    NewUserExpandEntry.super.onEnter(self)

    performWithDelay(self, function()
        self:dealGuideLogic()
    end, 0.51)
    gLobalNoticManager:addObserver(self, "onCompleteGuideUnlockChapterEvt", NewUserExpandConfig.EVENT_NAME.NOTIFY_CHECK_GUIDE_EXPAND_ENTRY)
    gLobalNoticManager:addObserver(self, "onColLevelCloseEvt", ViewEventType.NOTIFY_COLLECTLEVEL_CLOSE)
end

-- 更新标签显隐
function NewUserExpandEntry:updateTagVisible(_bAni)
    local actName = self.m_actNameList_idle[self.m_chooseType]
    local cb
    -- if _bAni then
    --     actName = self.m_actNameList_ani[self.m_chooseType]
    --     cb = function()
    --         self:updateTagVisible()
    --     end
    -- end
    self:runCsbAction(actName, false, cb, 60)
end

-- 按钮状态
function NewUserExpandEntry:updateBtnEnabled()
    local btnSlots = self:findChild("btn_slots")
    local btnPuzzle = self:findChild("btn_puzzle")

    btnSlots:setEnabled(self.m_chooseType ~= NewUserExpandConfig.LOBBY_TYPE.SLOTS)
    btnPuzzle:setEnabled(self.m_chooseType ~= NewUserExpandConfig.LOBBY_TYPE.PUZZLE)
    if self.m_bColLelvesOpen then
        local btnColLevels = self:findChild("btn_colLevels")
        btnColLevels:setEnabled(self.m_chooseType ~= NewUserExpandConfig.LOBBY_TYPE.COL_LEVELS)
    end
end

function NewUserExpandEntry:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_slots" then
        self.m_chooseType = NewUserExpandConfig.LOBBY_TYPE.SLOTS
    elseif name == "btn_puzzle" then
        self.m_chooseType = NewUserExpandConfig.LOBBY_TYPE.PUZZLE
        gLobalNoticManager:postNotification(NewUserExpandConfig.EVENT_NAME.NOTIFY_CHECK_REFRESH_TASK_STATE)
    elseif name == "btn_colLevels" then
        self.m_chooseType = NewUserExpandConfig.LOBBY_TYPE.COL_LEVELS
    end

    self:onClickEvt()
end

function NewUserExpandEntry:dealGuideLogic()
    -- 用户自己激活的 扩圈系统引导 进入扩圈
    if G_GetMgr(G_REF.NewUserExpand):checkIsClientActiveType() then
        if self.m_chooseType == NewUserExpandConfig.LOBBY_TYPE.PUZZLE then
            return
        end
        
        G_GetMgr(G_REF.NewUserExpand):getGuide():triggerGuide(self, "ExpandEntryClickGuide", G_REF.NewUserExpand)
        G_GetMgr(G_REF.NewUserExpand):getLogObj():sendExpandGuideLog("ExpandEntryClickGuide")
    elseif G_GetMgr(G_REF.NewUserExpand):checkIsServerActiveType() then
        -- 用户登录前 就激活了 扩圈系统 完成一系列关卡后 引导进入 slot大厅
        if G_GetMgr(G_REF.NewUserExpand):checkUserHadClickEntry() or self.m_chooseType ~= NewUserExpandConfig.LOBBY_TYPE.PUZZLE then
            return
        end
        
        -- 引导 4  引导解锁障碍物完成 后 引导 扩圈入口到slots
        if not G_GetMgr(G_REF.NewUserExpand):getGuide():isCanTriggerGuide("EnterExpandMainMissionUnlock", G_REF.NewUserExpand) then
            G_GetMgr(G_REF.NewUserExpand):getGuide():triggerGuide(self, "EnterExpandMainPlayEntryTag", G_REF.NewUserExpand)
            G_GetMgr(G_REF.NewUserExpand):getLogObj():sendExpandGuideLog("EnterExpandMainPlayEntryTag")
            self:runCsbAction("idle_guide", true)
        end

    end
end

function NewUserExpandEntry:onCompleteGuideUnlockChapterEvt(_bCloseGuideEntryTag)
    if _bCloseGuideEntryTag then
        -- 引导 扩圈入口到slots 重新播动画
        self:updateTagVisible()
    end
    -- 引导 4  引导解锁障碍物完成 后 引导 扩圈入口到slots
    self:dealGuideLogic()
end

-- 收藏关卡操作 切换到slot页签
function NewUserExpandEntry:onColLevelCloseEvt()
    self.m_chooseType = NewUserExpandConfig.LOBBY_TYPE.SLOTS
    self:onClickEvt()
end

function NewUserExpandEntry:onClickEvt()
    self:updateTagVisible(true)
    self:updateBtnEnabled()
    G_GetMgr(G_REF.NewUserExpand):setCurLobbyStyle(self.m_chooseType)
    G_GetMgr(G_REF.NewUserExpand):getLogObj():sendExpandClickEntryLog()
    gLobalNoticManager:postNotification(NewUserExpandConfig.EVENT_NAME.UPDATE_LOBBY_VIEW_EXPAND_TYPE, self.m_chooseType)
end
return NewUserExpandEntry