--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-06-15 14:50:50
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-15 14:51:01
FilePath: /SlotNirvana/src/activities/Activity_Quest/views/QuestLobbyBtmBigActEfUI.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local QuestLobbyBtmBigActEfUI = class("QuestLobbyBtmBigActEfUI", BaseView)
local BottomExtraMgr = require("manager.System.BottomExtraMgr")

function QuestLobbyBtmBigActEfUI:getCsbName()
    return "Activity_LobbyIconRes/Activity_CommonRefresh.csb"
end

function QuestLobbyBtmBigActEfUI:initUI()
    QuestLobbyBtmBigActEfUI.super.initUI(self)

    self.m_bPlayUnlockAni = true
    -- 普通quest node
    self:initBigActUI()
end

-- 普通quest node
function QuestLobbyBtmBigActEfUI:initBigActUI()
    local bigActData, bComingSoon = BottomExtraMgr:getInstance():checkCurrShowActivityNode()
    if not bigActData then
        self.m_bPlayUnlockAni = false
        return
    end
    local view = gLobalActivityManager:InitLobbyNode(bigActData.activityName, bComingSoon)
    local parent = self:findChild("node_bigAct")
    parent:addChild(view)

    -- 入口显示的名字
    local viewShowName = view:getBottomName()
    local lbTip = self:findChild("lb_tip")
    local newStr = string.format(lbTip:getString(), viewShowName)
    lbTip:setString(newStr)
    
    self.m_bPlayUnlockAni = not bComingSoon
end

function QuestLobbyBtmBigActEfUI:playUnlock(_cb)
    _cb =  _cb or function()    end
    if not self.m_bPlayUnlockAni then
        _cb()
        return 
    end

    self:runCsbAction("start", false, function()
        _cb()
        self:runCsbAction("show")
    end, 60)
end

function QuestLobbyBtmBigActEfUI:checkCanGuide()
    return self.m_bPlayUnlockAni
end

return QuestLobbyBtmBigActEfUI