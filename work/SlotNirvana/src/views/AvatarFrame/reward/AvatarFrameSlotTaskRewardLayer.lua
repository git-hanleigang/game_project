--[[
Author: cxc
Date: 2022-04-22 17:32:26
LastEditTime: 2022-04-22 17:32:27
LastEditors: cxc
Description: 头像框 任务 奖励 弹板
FilePath: /SlotNirvana/src/views/AvatarFrame/reward/AvatarFrameSlotTaskRewardLayer.lua
--]]
local AvatarFrameSlotTaskRewardLayer = class("AvatarFrameSlotTaskRewardLayer", BaseLayer)
local AvatarFrameConfig = util_require("GameModule.Avatar.config.AvatarFrameConfig")

function AvatarFrameSlotTaskRewardLayer:ctor(_callFunc)
    AvatarFrameSlotTaskRewardLayer.super.ctor(self)

    self:setPauseSlotsEnabled(true) 
    self:setHideActionEnabled(false)
    self:setExtendData("AvatarFrameSlotTaskRewardLayer")
    self:setLandscapeCsbName("Activity/csb/Frame_reward1.csb")
    self:setPortraitCsbName("Activity/csb/Frame_reward_vertical1.csb")
end

function AvatarFrameSlotTaskRewardLayer:initDatas(_slotId)
    AvatarFrameSlotTaskRewardLayer.super.initDatas(self)

    local data = G_GetMgr(G_REF.AvatarFrame):getData()
    data:resetSlotTaskCompleteList(_slotId) -- 重置任务状态 
    local sltoTaskData = data:getSlotTaskBySlotId(_slotId)
    if not sltoTaskData then
        return
    end
    self.m_taskData = sltoTaskData:getCurCompleteTaskData()
end

function AvatarFrameSlotTaskRewardLayer:initView()
    -- 头像框等级 
    local lbFrameLv = self:findChild("txt_desc1")
    local desc = self.m_taskData:getFrameLevelDesc()
    lbFrameLv:setString( string.upper(desc) .. " FRAME")
    -- 头像框 在哪个关卡获得描述
    local lbGameName = self:findChild("txt_desc2")
    local gameName = self.m_taskData:getSlotGameName()
    lbGameName:setString(string.format("IN %s UNLOCKED!", string.upper(gameName)))
end

function AvatarFrameSlotTaskRewardLayer:playShowAction()
    AvatarFrameSlotTaskRewardLayer.super.playShowAction(self, "start")
    gLobalSoundManager:playSound(AvatarFrameConfig.SOUND_ENUM.SLOT_TASK_COMPLETE_SHOW)
end

function AvatarFrameSlotTaskRewardLayer:onShowedCallFunc()
    AvatarFrameSlotTaskRewardLayer.super.onShowedCallFunc(self)
    self:runCsbAction("idle", false, handler(self, self.showSlotTaskRewardInfoLayer), 60)
end

function AvatarFrameSlotTaskRewardLayer:showSlotTaskRewardInfoLayer()
    local cb = function()
        if not self.m_taskData then
            return
        end
        
        local view = util_createView("views.AvatarFrame.reward.AvatarFrameSlotTaskRewardInfoLayer", self.m_taskData)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)    
    end
    self:closeUI(cb)
end

return AvatarFrameSlotTaskRewardLayer