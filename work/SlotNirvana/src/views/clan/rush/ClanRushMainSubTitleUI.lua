--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-20 11:44:37
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-20 11:45:03
FilePath: /SlotNirvana/src/views/clan/rush/ClanRushMainSubTitleUI.lua
Description: 公会rush主弹板 副标题
--]]
local ClanRushMainSubTitleUI = class("ClanRushMainSubTitleUI", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanRushMainSubTitleUI:initDatas(_taskData)
    ClanRushMainSubTitleUI.super.initDatas(self)

    self.m_taskData = _taskData
end

function ClanRushMainSubTitleUI:initCsbNodes()
    self.m_nodeTitle_act = self:findChild("node_act")
    self.m_nodeTitle_quest = self:findChild("node_quest")
    self.m_nodeTitle_chip = self:findChild("node_chip")
end

function ClanRushMainSubTitleUI:initUI()
    ClanRushMainSubTitleUI.super.initUI(self)

    self:initTaskIconUI()
    self:initTaskSubTitleUI() 
end

-- 任务类型icon
function ClanRushMainSubTitleUI:initTaskIconUI()
    local spIcon = self:findChild("sp_taskIcon")
    local imgPath = self.m_taskData:getTaskIconPath()
    -- util_changeTexture(spIcon, imgPath) 
    ClanManager:changeTeamRushTaskIcon(spIcon, imgPath)
end

-- 任务subTile显隐
function ClanRushMainSubTitleUI:initTaskSubTitleUI()
    local taskType = self.m_taskData:getTaskType()
    self.m_nodeTitle_act:setVisible(taskType == ClanConfig.RushTaskType.ACT)
    self.m_nodeTitle_quest:setVisible(taskType == ClanConfig.RushTaskType.QUEST)
    self.m_nodeTitle_chip:setVisible(taskType == ClanConfig.RushTaskType.CHIP)
end

function ClanRushMainSubTitleUI:getCsbName()
    return "Club/csd/Rush/node_rush_main_subTitle.csb"
end

return ClanRushMainSubTitleUI