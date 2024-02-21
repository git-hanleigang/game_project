--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-05 11:36:44
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-05 11:40:32
FilePath: /SlotNirvana/src/views/levelup/LVUpRewardListUI.lua
Description: 升级弹板 奖励道具 详情列表
--]]
local LVUpRewardListUI = class("LVUpRewardListUI", BaseView)

function LVUpRewardListUI:getCsbName()
    return "LevelUp_new/LevelUpLayer_item.csb"
end

function LVUpRewardListUI:initCsbNodes()
    LVUpRewardListUI.super.initCsbNodes(self)

    self.m_node_btn1 = self:findChild("node_btn1")
    self.m_node_btn2 = self:findChild("node_btn2")
end
    
function LVUpRewardListUI:initUI(_mainView)
    LVUpRewardListUI.super.initUI(self)

    self._mainView = _mainView

    -- 道具
    self:initItemListUI()
    self:setVisible(false)
end

function LVUpRewardListUI:initItemListUI()
    local rewardList = self._mainView:getRewardList()
    local levelOrderList = self._mainView:getLevelOrderList()

    --奖励道具
    for i = 1, 4 do
        local node_item = self:findChild("node_item" .. i)
        if node_item and levelOrderList[i] and levelOrderList[i].p_name then
            local name = LEVEL_REWARD_ENMU[levelOrderList[i].p_name]
            if name then
                local item = util_createView("views.levelup.LevelUpRewardItem", name, rewardList[name])
                node_item:addChild(item)
            end
        end
    end
end

function LVUpRewardListUI:hideDoubleBtn(_flag)
    self.m_node_btn2:setVisible(_flag)
    self.m_node_btn1:setVisible(not _flag)
end

function LVUpRewardListUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        self._mainView:closeUI()
    elseif name == "btn_doubleCoins" then
        sender:setTouchEnabled(false)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:logADClick()
        gLobalAdsControl:playRewardVideo(PushViewPosType.LevelUp)
    end
end

function LVUpRewardListUI:logADClick()
    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.LevelUp)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.LevelUp)
    gLobalSendDataManager:getLogAds():setOpenType("TapOpen")
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.LevelUp}, nil, "click")
end

function LVUpRewardListUI:getFlyCoinsPosWorld()
    local refNode = self:findChild("node_btn_act1")
    return refNode:convertToWorldSpace(cc.p(0, 0))
end 

function LVUpRewardListUI:playShowAct()
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end, 60)
end

function LVUpRewardListUI:getShowActTime()
    if not self.m_csbAct then
        return  0
    end
    local time = util_csbGetAnimTimes(self.m_csbAct, "start", 60)
    return time or 70 / 60
end

return LVUpRewardListUI