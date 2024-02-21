--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-20 14:39:37
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-20 14:58:44
FilePath: /SlotNirvana/src/views/clan/rush/ClanRushMainSubTitleUI.lua
Description: 公会rush主弹板 下个任务开启提示
--]]
local ClanRushTaskReportLayer = class("ClanRushTaskReportLayer", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRushTaskReportLayer:initDatas(_rushData)
    ClanRushTaskReportLayer.super.initDatas(self)

    self.m_bSelfJoinPreTask = _rushData:isJoinPreTask() 

    self:setExtendData("ClanRushTaskReportLayer")
    self:setLandscapeCsbName("Club/csd/Rush/Rush_Report.csb")
end

function ClanRushTaskReportLayer:initCsbNodes()
    self.m_lbDescJoin = self:findChild("lb_sec_join")
    self.m_lbDescNoJoin = self:findChild("lb_sec_no_join")
end

function ClanRushTaskReportLayer:initView()
    -- 上个任务提示 有没有参与
    self.m_lbDescJoin:setVisible(self.m_bSelfJoinPreTask)
    self.m_lbDescNoJoin:setVisible(not self.m_bSelfJoinPreTask)
end

function ClanRushTaskReportLayer:onShowedCallFunc()
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end, 60)
end

function ClanRushTaskReportLayer:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_next" then
        self:closeUI()
    end
end

return ClanRushTaskReportLayer