--[[
Author: cxc
Date: 2021-07-27 11:20:17
LastEditTime: 2021-07-27 11:20:17
LastEditors: Please set LastEditors
Description: 公会任务 未完成 点数换金币 面板
FilePath: /SlotNirvana/src/views/clan/ClanTaskRewardUndonePanel.lua
--]]
local BaseRotateLayer = util_require("base.BaseRotateLayer")
local ClanTaskRewardUndonePanel = class("ClanTaskRewardUndonePanel", BaseRotateLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")

function ClanTaskRewardUndonePanel:ctor()
    ClanTaskRewardUndonePanel.super.ctor(self)

    self.m_rewards = {} --奖励
    self.m_clanData = clone(ClanManager:getClanData())
    self.m_curStep = 1

    self:setHideLobbyEnabled(true)
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName("Club/csd/Rewards/ClubReward_fail.csb")
end

function ClanTaskRewardUndonePanel:initDatas(_rewards)
    ClanTaskRewardUndonePanel.super.initDatas(self)
    self.m_rewards = _rewards or {}
end

function ClanTaskRewardUndonePanel:initUI(_rewards)
    ClanTaskRewardUndonePanel.super.initUI(self)

    -- 背景
    self:initBgUI()
    
    local curStep = 1
    local taskData = self.m_clanData:getTaskData()
    if taskData then
        curStep = taskData.curStep
    end
    self.m_curStep = curStep

    -- 宝箱
    local box = util_createView("views.clan.taskReward.ClanTaskBoxReward", curStep)
    local parentBox = self:findChild("Node_ClubReward_box")
    box:addTo(parentBox)
    performWithDelay(self, function()
        box:playHideAni(handler(self, self.popInfoPanel))
    end, 2)

    gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.TASK_UNDONE)
end

-- 背景
function ClanTaskRewardUndonePanel:initBgUI()
    local bgLeft = self:findChild("sp_bg")
    local bgRight = self:findChild("sp_bg_0")
    local bgSize = bgLeft:getContentSize()
    local scale = self:getUIScalePro()
    if scale == 1 and display.width > bgSize.width*2 then
        bgLeft:setScale(display.width * 0.5 / bgSize.width)
        bgRight:setScale(display.width * 0.5 / bgSize.width)
    else
        bgLeft:setScale(1 / scale)
        bgRight:setScale(1 / scale)
    end
end

function ClanTaskRewardUndonePanel:popInfoPanel()
    if gLobalViewManager:getViewByExtendData("ClanTaskRewardUndonInfoPanel") then
        return
    end

    local view = util_createFindView("views/clan/taskReward/ClanTaskRewardUndonInfoPanel", self.m_rewards, self.m_curStep, self.m_clanData)
    view:setViewOverFunc(function()
        self:closeUI()
    end)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function ClanTaskRewardUndonePanel:closeUI()
    ClanTaskRewardUndonePanel.super.closeUI(self, self.m_closeUICb)
end

function ClanTaskRewardUndonePanel:setViewOverFunc(_cb)
    self.m_closeUICb = _cb
end

return ClanTaskRewardUndonePanel 