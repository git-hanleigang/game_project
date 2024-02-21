--[[
Author: cxc
Date: 2021-07-27 18:04:52
LastEditTime: 2021-07-27 19:43:12
LastEditors: your name
Description: 公会任务 已完成 奖励面板
FilePath: /SlotNirvana/src/views/clan/taskReward/ClanTaskRewardDonePanel.lua
--]]
local BaseRotateLayer = util_require("base.BaseRotateLayer")
local ClanTaskRewardDonePanel = class("ClanTaskRewardDonePanel", BaseRotateLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")

function ClanTaskRewardDonePanel:ctor()
    ClanTaskRewardDonePanel.super.ctor(self)

    self.m_rewards = {} --奖励

    self:setHideLobbyEnabled(true)
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName("Club/csd/Rewards/ClubReward_success.csb")
end

function ClanTaskRewardDonePanel:initDatas(_rewards)
    ClanTaskRewardDonePanel.super.initDatas(self)
    self.m_rewards = _rewards or {}
end

function ClanTaskRewardDonePanel:initUI(_rewards)
    ClanTaskRewardDonePanel.super.initUI(self)

    local clanData = ClanManager:getClanData() 
    -- 背景
    self:initBgUI()

    -- title
    local points = clanData:getMyPoints()
    local curStep = 1
    local taskData = clanData:getTaskData()
    if taskData then
        curStep = taskData.curStep
    end
    local titleStr = string.format("You earned %d team points to win the %d level chest", tonumber(points), tonumber(curStep))
    local lbTitle = self:findChild("lb_titel2")
    lbTitle:setString(titleStr)

    -- 宝箱
    local box = util_createView("views.clan.taskReward.ClanTaskBoxReward", curStep, true)
    if box and curStep == 6 then
        box:setScale(0.8)
    end
    local parentBox = self:findChild("baoxiang")
    box:addTo(parentBox)
    util_setCascadeOpacityEnabledRescursion(parentBox, true)
    self.m_box = box

    -- 公会点数信息
    local totalPoints = taskData.total or 0
    local lbPoint = self:findChild("lb_teampoint_cur")
    local lbNextPoint = self:findChild("lb_teampoint_next")
    lbPoint:setString(util_getFromatMoneyStr(totalPoints))
    lbNextPoint:setString(util_getFromatMoneyStr(totalPoints))

    gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.TASK_DONE)
end

-- 背景
function ClanTaskRewardDonePanel:initBgUI()
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

function ClanTaskRewardDonePanel:onShowedCallFunc()
    ClanTaskRewardDonePanel.super.onShowedCallFunc(self)
    
    self.m_bTap = true
    self:runCsbAction("actionframe", false, function()
        if self.m_box then
            self.m_box:playKeyAni(function()
                self.m_bTap = false
            end)
        end
    end, 60)
end

function ClanTaskRewardDonePanel:clickFunc(sender)
    local name = sender:getName()

    if self.m_bTap then
        return
    end

    self.m_bTap = true
    if self.m_box then
        gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.TASK_BOX_UNLOCK)
        self:runCsbAction("open")
        self:findChild("sp_tap"):setVisible(false)
        self.m_box:playUnlockAni(handler(self, self.popInfoPanel))
    else
        self:closeUI()
    end
end

function ClanTaskRewardDonePanel:popInfoPanel()
    if gLobalViewManager:getViewByExtendData("ClanTaskRewardDoneInfoPanel") then
        return
    end
    
    local view = util_createFindView("views/clan/taskReward/ClanTaskRewardDoneInfoPanel", self.m_rewards)
    view:setViewOverFunc(function()
        self:closeUI()
    end)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    -- 隐藏宝箱
    local parentBox = self:findChild("baoxiang")
    parentBox:setVisible(false)
end

function ClanTaskRewardDonePanel:closeUI()
    ClanTaskRewardDonePanel.super.closeUI(self, self.m_closeUICb)
end

function ClanTaskRewardDonePanel:setViewOverFunc(_cb)
    self.m_closeUICb = _cb
end

return ClanTaskRewardDonePanel 