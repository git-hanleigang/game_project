--[[
Author: cxc
Date: 2021-02-07 15:06:41
LastEditTime: 2021-03-13 01:06:39
LastEditors: Please set LastEditors
Description: 公会 统一的 提示弹板
FilePath: /SlotNirvana/src/views/clan/ClanCommonTipPanel.lua
--]]
local ClanCommonTipPanel = class("ClanCommonTipPanel", BaseLayer)
local ClanConfig = require("data.clanData.ClanConfig")

function ClanCommonTipPanel:ctor()
    ClanCommonTipPanel.super.ctor(self)

    self:setExtendData("ClanCommonTipPanel")

    -- self:setShownAsPortrait(globalData.slotRunData:isMachinePortrait())
    self:setLandscapeCsbName("Club/csd/Tanban/ClubErrorLayer.csb")

    self:addClickSound({"btn_no", "btn_cancel", "btn_yes", "btn_ok", "btn_leave"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

function ClanCommonTipPanel:initUI(_params)
    ClanCommonTipPanel.super.initUI(self)

    -- 标题
    local titleName = _params.title or ""
    local nodeTitle = self:findChild("node_title")
    for i, node in ipairs(nodeTitle:getChildren()) do
        local name = node:getName()
        node:setVisible(name == titleName)
    end

    -- 提示内容
    local content = _params.content or ""
    local lbContent= self:findChild("lb_content")
    lbContent:setString(content)
    util_AutoLine(lbContent, content, 670, true)
    self:dealCustomUI(_params)
    
    -- btn
    local bShowCancel = _params.bShowCancel
    local btnConfirm = self:findChild("btn_yes")
    local btnCancel = self:findChild("btn_no")
    local btnOk = self:findChild("btn_ok")
    btnConfirm:setVisible(bShowCancel)
    btnCancel:setVisible(bShowCancel)
    btnOk:setVisible(not bShowCancel)

    -- new (离开公会按钮特殊)
    local btnLeave = self:findChild("btn_leave")
    local btnLeaveCancel = self:findChild("btn_cancel")
    btnLeave:setVisible(false)
    btnLeaveCancel:setVisible(false)
    if _params.bLeaveClanType then
        btnConfirm:setVisible(false)
        btnCancel:setVisible(false)
        btnLeave:setVisible(true)
        btnLeaveCancel:setVisible(true)
    end
end

-- 设置确定按钮回调方法
function ClanCommonTipPanel:setConfirmCB(_cb)
    self.m_confirmCB = _cb
end

-- 设置取消按钮回调方法
function ClanCommonTipPanel:setCancelCB(_cb)
    self.m_cancelCB = _cb
end

function ClanCommonTipPanel:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_close" or name == "btn_no" or name == "btn_cancel" then
        -- 关闭按钮
        self:closeUI(self.m_cancelCB)
    elseif name == "btn_yes" or name == "btn_ok" or name == "btn_leave" then
        -- 确定按钮
        self:closeUI(self.m_confirmCB)
    end
end

function ClanCommonTipPanel:dealCustomUI(_params)
    local nodeCustom = self:findChild("node_custom")
    nodeCustom:setVisible(false)
    
    if not _params.type then
        return
    end

    local lbContent= self:findChild("lb_content")
    lbContent:setVisible(false)
    nodeCustom:setVisible(true)

    for i, node in ipairs(nodeCustom:getChildren()) do
        node:setVisible(false)
    end
    if _params.type == "KICK_OFF_USER" then
        local ui = self:findChild("node_kickoff")
        ui:setVisible(true)
        local lbStr = self:findChild("lb_user")
        lbStr:setString(_params.content or "")
        util_scaleCoinLabGameLayerFromBgWidth(lbStr, 200)
    end
end

-- 注册事件
function ClanCommonTipPanel:registerListener(  )
    ClanCommonTipPanel.super.registerListener(self)
    
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.KICKED_OFF_TEAM) -- 被踢了
end

return ClanCommonTipPanel