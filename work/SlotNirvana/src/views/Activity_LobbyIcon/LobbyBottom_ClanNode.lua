--[[
Author: cxc
Date: 2021-03-04 14:27:11
LastEditTime: 2021-07-27 12:07:33
LastEditors: Please set LastEditors
Description: 公会入口
FilePath: /SlotNirvana/Dynamic/Activity_LobbyNode/LobbyBottom_ClanNode.lua
--]]
local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_ClanNode = class("LobbyBottom_ClanNode", BaseLobbyNodeUI)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = require("data.clanData.ClanConfig")
-- 建立聊天服务器连接 拉取聊天信息
-- local ChatManager = util_require("manager.System.ChatManager"):getInstance()

function LobbyBottom_ClanNode:initUI(data)
    local csbName = "Activity_LobbyIconRes/LobbyBottomClubNode.csb"
    self:createCsbNode(csbName)

    self:initView()
    self:updateRedPoints()

    -- 为了小红点 请求下申请列表
    ClanManager:requestClanApplyList()

    -- 常量表控制是否开启
    if not globalData.constantData.CLAN_OPEN_SIGN then
        self:showCommingSoon()
    end
end

function LobbyBottom_ClanNode:updateView()
    LobbyBottom_ClanNode.super.updateView(self)

    self.m_timeBg:setVisible(false)
    self.m_lockIocn:setVisible(false)
    self.btnFunc:setOpacity(255)

    if not globalData.constantData.CLAN_OPEN_SIGN then
        self:showCommingSoon()
    end
end

function LobbyBottom_ClanNode:clickLobbyNode()
    -- 检查过 弹板队列再点击
    if gLobalPopViewManager.checkIsHadCheckPop and not gLobalPopViewManager:checkIsHadCheckPop() then
        return
    end
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

    -- 是否支持此版本
    if not ClanManager:checkSupportAppVersion(true) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        return
    end

    self.m_bClick = true
    ClanManager:sendClanInfo(
        function()
            if not tolua.isnull(self) then
                self:openLayerSuccess()
            end
        end
    )
end

function LobbyBottom_ClanNode:enterClanSystem()
    if not self.m_bClick then
        return
    end
    self.m_bClick = false

    ClanManager:enterClanSystem()
end

function LobbyBottom_ClanNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_ClanNode:getBottomName()
    return "TEAM"
end

function LobbyBottom_ClanNode:getDownLoadKey()
    return "Club_res"
end

function LobbyBottom_ClanNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/logo_club.png"
end

function LobbyBottom_ClanNode:getProcessBgOffset()
    return 0.2, 0.9
end

-- 显示红点
function LobbyBottom_ClanNode:updateRedPoints()
    if self.m_spRedPoint and self.m_labelActivityNums then
        if not self.timerAction then
            self.timerAction = schedule(self, handler(self, self.updateRedPoints), 1)
        end

        local num = ClanManager:getLobbyBottomNum()
        if num > 0 then
            if num > 99 then
                num = "99+"
            end
            self.m_spRedPoint:setVisible(true)
            self.m_labelActivityNums:setString(num)
            util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
        else
            self.m_spRedPoint:setVisible(false)
        end
    end
end

-- 获取 开启等级
function LobbyBottom_ClanNode:getSysOpenLv()
    return globalData.constantData.CLAN_OPEN_LEVEL
end

-- 注册事件
function LobbyBottom_ClanNode:registerListener()
    LobbyBottom_ClanNode.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "enterClanSystem", ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA)
    gLobalNoticManager:addObserver(self, "enterClanSystem", ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA_FAILD)
end

--下载结束回调
function LobbyBottom_ClanNode:endProcessFunc()
    LobbyBottom_ClanNode.super.endProcessFunc(self)

    local bPopPointsReward = ClanManager:checkShowTaskReward()
    if bPopPointsReward then
        ClanManager:requestTaskReward()
    end
end

return LobbyBottom_ClanNode
