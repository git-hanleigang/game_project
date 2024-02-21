--[[
Author: cxc
Date: 2021-11-26 19:07:02
LastEditTime: 2021-11-27 14:58:37
LastEditors: your name
Description: 乐透功能入口
FilePath: /SlotNirvana/src/views/Activity_LobbyIcon/LobbyBottom_LotteryNode.lua
--]]
local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_LotteryNode = class("LobbyBottom_LotteryNode", BaseLobbyNodeUI)

function LobbyBottom_LotteryNode:initUI(data)
    local csbName = "Activity_LobbyIconRes/LobbyBottom_LotteryNode.csb"
    self:createCsbNode(csbName)

    self:initView()

    -- 常量表控制是否开启
    if not globalData.constantData.LOTTERY_OPEN_SIGN then
        self:showCommingSoon()
    end
end

function LobbyBottom_LotteryNode:updateView()
    LobbyBottom_LotteryNode.super.updateView(self)

    self.m_timeBg:setVisible(false)
    self.m_lockIocn:setVisible(false)
    self.btnFunc:setOpacity(255)
end

function LobbyBottom_LotteryNode:clickLobbyNode()
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    if self.m_commingSoon then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    if globalDynamicDLControl:checkDownloading(self:getDownLoadKey()) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    G_GetMgr(G_REF.Lottery):showMainLayer()

    self:openLayerSuccess()
end

function LobbyBottom_LotteryNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_LotteryNode:getBottomName()
    return "LOTTERY"
end

function LobbyBottom_LotteryNode:getDownLoadKey()
    return "Lottery"
end

function LobbyBottom_LotteryNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/Lottery.png"
end

function LobbyBottom_LotteryNode:getProcessBgOffset()
    return 0, 0
end

-- 获取 开启等级
function LobbyBottom_LotteryNode:getSysOpenLv()
    return globalData.constantData.LOTTERY_OPEN_LEVEL
end

return LobbyBottom_LotteryNode
