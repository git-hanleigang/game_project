--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-27 12:17:25
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-27 12:17:47
FilePath: /SlotNirvana/src/views/clan/rush/ClanRushProgressUI.lua
Description: 工会rush 进度条
--]]
local ClanRushProgressUI = class("ClanRushProgressUI", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRushProgressUI:initDatas(_taskData, _taskTotalCount)
    ClanRushProgressUI.super.initDatas(self)

    self.m_taskData = _taskData
    self.m_taskTotalCount = _taskTotalCount
end

function ClanRushProgressUI:initUI()
    ClanRushProgressUI.super.initUI(self)

    -- 任务 阶段
    self:initSeqUI()
    -- 任务 进度
    self:initProgUI()
    -- 任务 图标
    self:initIconUI()
    -- 任务 奖励图标
    self:initGiftIconUI()
    -- 任务 奖励气泡
    self:initBubbleUI()
end

-- 初始化节点
function ClanRushProgressUI:initCsbNodes()
    self.m_lbTaskIdx = self:findChild("txt_taskIdx")
    self.m_spTaskIcon = self:findChild("sp_taskIcon")
    self.m_spProg = self:findChild("img_progress")
    self.m_lbProg = self:findChild("txt_progress")
    self.m_nodeBubble = self:findChild("node_bubble")

    self.m_spProgSize = self.m_spProg:getContentSize()
end

function ClanRushProgressUI:getCsbName()
    return "Club/csd/Rush/node_progress.csb"
end

-- 任务 阶段
function ClanRushProgressUI:initSeqUI()
    local curIdx = self.m_taskData:getTaskIdx()
    self.m_lbTaskIdx:setString(curIdx .. "/" .. self.m_taskTotalCount)
end
-- 任务 进度
function ClanRushProgressUI:initProgUI()
    local curCount = self.m_taskData:getCurCount()
    local needCount = self.m_taskData:getNeedCount()
    self.m_lbProg:setString(curCount .. "/" .. needCount)

    local progress = 0
    if needCount > 0 then
        progress = curCount / needCount
    end
    self.m_spProg:setContentSize(self.m_spProgSize.width * progress, self.m_spProgSize.height)
end
-- 任务 图标
function ClanRushProgressUI:initIconUI()
    local imgPath = self.m_taskData:getTaskIconPath()
    -- util_changeTexture(self.m_spTaskIcon, imgPath) 
    ClanManager:changeTeamRushTaskIcon(self.m_spTaskIcon, imgPath)
end
-- 任务 奖励图标
function ClanRushProgressUI:initGiftIconUI()
    if not self.m_giftView then
        local nodeGift = self:findChild("node_gift")
        self.m_giftView = util_createView("views.clan.rush.ClanRushTaskGiftUI")
        nodeGift:addChild(self.m_giftView)
    end
    local curIdx = self.m_taskData:getTaskIdx()
    local bFinish = self.m_taskData:checkTaskFinish()
    self.m_giftView:updateUI(curIdx, bFinish)
end
-- 任务 奖励气泡
function ClanRushProgressUI:initBubbleUI()
    local view = util_createView("views.clan.rush.ClanRushRewardBubble", self.m_taskData)
    self.m_nodeBubble:addChild(view)
    self.m_bubbleView = view
end

function ClanRushProgressUI:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_click" and self.m_bubbleView then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_bubbleView:switchBubbleVisible()
    elseif name == "btn_taskIcon" then
        local taskType = self.m_taskData:getTaskType()
        local actName = self.m_taskData:getTaskActName()
        ClanManager:rushTaskJumpToOtherFeature(taskType, actName)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.RUSH_TASK_JUMP_TO_OTHER_FEATURE)
    end
end

return ClanRushProgressUI