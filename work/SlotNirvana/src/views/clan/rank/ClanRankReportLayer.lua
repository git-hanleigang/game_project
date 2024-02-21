--[[
Author: cxc
Date: 2022-02-25 11:26:13
LastEditTime: 2022-02-25 11:27:56
LastEditors: cxc
Description: 公会排行榜 排行榜结算后 段位变化
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankReportLayer.lua
--]]
local ClanRankReportLayer = class("ClanRankReportLayer", BaseLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = require("data.clanData.ClanConfig")

function ClanRankReportLayer:ctor()
    ClanRankReportLayer.super.ctor(self)
    self:setPauseSlotsEnabled(true) 

    self:setExtendData("ClanRankReportLayer")
    self:setLandscapeCsbName("Club/csd/RANK/Club_RankReport.csb")

    ClanManager:resetBenifitList()
    ClanManager:sendResetPopReprotSign()
end

function ClanRankReportLayer:initDatas(_selfRankInfo, _callBack)
    ClanRankReportLayer.super.initDatas(self)

    self.m_selfRankInfo = _selfRankInfo
    self.m_divisionCType = ClanConfig.RankUpDownEnum.UNCHANGED
    if _selfRankInfo.division > _selfRankInfo.lastDivision then
        self.m_divisionCType = ClanConfig.RankUpDownEnum.UP
    elseif _selfRankInfo.division < _selfRankInfo.lastDivision then
        self.m_divisionCType = ClanConfig.RankUpDownEnum.DOWN
    end 

    self.m_callBack = _callBack
end

function ClanRankReportLayer:initCsbNodes()
    ClanRankReportLayer.super.initCsbNodes(self)

    self.m_btnGo = self:findChild("btn_go")
    self.m_btnClose = self:findChild("btn_close")
    self.m_btnGo:setVisible(false)
    self.m_btnClose:setVisible(false)
end

function ClanRankReportLayer:initView()
    -- 背景
    self:initBgUI()
    -- 段位UI
    self:initRankUI()
    -- 段位变化提示UI显隐
    self:initDivisionChangeTipUI()
    -- 权益UI
    self:initBenifitUI()
end

-- 背景
function ClanRankReportLayer:initBgUI()
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

-- 段位UI
function ClanRankReportLayer:initRankUI()
    local spPreIcon = self:findChild("sp_rank_icon_pre")  --上赛季段位图
    local lbPreId = self:findChild("lb_rank_id_pre")  --上赛季段位图 文本
    local iconPath = ClanManager:getRankDivisionIconPath(self.m_selfRankInfo.lastDivision)
    util_changeTexture(spPreIcon, iconPath)
    local descStr = ClanManager:getRankDivisionDesc(self.m_selfRankInfo.lastDivision)
    lbPreId:setString(descStr)

    local spCurIcon = self:findChild("sp_rank_icon_cur")  --当前赛季段位图
    local lbCurId = self:findChild("lb_rank_id_cur")  --当前赛季段位图 文本
    local iconPath = ClanManager:getRankDivisionIconPath(self.m_selfRankInfo.division)
    util_changeTexture(spCurIcon, iconPath)
    local descStr = ClanManager:getRankDivisionDesc(self.m_selfRankInfo.division)
    lbCurId:setString(descStr)
end

-- 段位变化提示UI显隐
function ClanRankReportLayer:initDivisionChangeTipUI()
    local spTipUp       = self:findChild("sp_moves_1_pre")
    local spTipUnchange = self:findChild("sp_moves_2_pre")
    local spTipDowm     = self:findChild("sp_moves_3_pre")
    spTipUp:setVisible(self.m_divisionCType == ClanConfig.RankUpDownEnum.UP)
    spTipUnchange:setVisible(self.m_divisionCType == ClanConfig.RankUpDownEnum.UNCHANGED)
    spTipDowm:setVisible(self.m_divisionCType == ClanConfig.RankUpDownEnum.DOWN)
end

-- 权益UI
function ClanRankReportLayer:initBenifitUI()
    -- 当前赛季图
    local spCurIcon = self:findChild("sp_Rank_icon")  --当前赛季段位图
    local spCurDesc = self:findChild("sp_Rank_id")  --当前赛季段位图 文本图
    local iconPath = ClanManager:getRankDivisionIconPath(self.m_selfRankInfo.division)
    util_changeTexture(spCurIcon, iconPath)
    local descPath = ClanManager:getRankDivisionDescPath(self.m_selfRankInfo.division)
    util_changeTexture(spCurId, descPath)

    -- 权益
    local benifitData = self.m_selfRankInfo.benifitData
    local rateList = {
        benifitData:getBoxRate(), -- 宝箱
        benifitData:getGemsRate(), -- gem
        benifitData:getCoinsRate(), -- 金币
        benifitData:getCardRateHour(), -- 集卡
    }
    local parentIdx = 1
    for i=1, #rateList  do
        local rate = rateList[i]
        local parent = self:findChild("Node_quanyi" .. parentIdx)
        if rate > 0 and parent then
            local view = util_createView("views.clan.rank.ClanRankReportCell", i, rate)
            parent:addChild(view)
            parentIdx = parentIdx + 1
        end
    end
end

function ClanRankReportLayer:onShowedCallFunc()
    -- 弹出后播放动效
    self:playRankChangeAct()
end

-- 弹出后播放动效
function ClanRankReportLayer:playRankChangeAct()
    if self.m_divisionCType == ClanConfig.RankUpDownEnum.UNCHANGED then
        performWithDelay(self, function()
            -- 隐藏段位UI显示权益UI
            self:runCsbAction("start", false, function()
                performWithDelay(self, function()
                    self.m_btnClose:setVisible(true)
                end, 2)
                self:runCsbAction("idle", true)
                self.m_btnGo:setVisible(true)
            end, 60)

        end, 1)
        return
    end

    local actName = "down"
    if self.m_divisionCType == ClanConfig.RankUpDownEnum.UP then
        actName = "up"
        gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.RANK_REPORT_UP)
    end
    self:runCsbAction(actName, false, function()
        -- 隐藏段位UI显示权益UI
        self:runCsbAction("start", false, function()
            performWithDelay(self, function()
                self.m_btnClose:setVisible(true)
            end, 2)
            self:runCsbAction("idle", true)
            self.m_btnGo:setVisible(true)
        end, 60)

    end, 60)
end

function ClanRankReportLayer:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_go" then
        local closeBack = function()
            local view = ClanManager:enterClanSystem() 
            if view then
                view:setOverFunc(self.m_callBack)
            elseif self.m_callBack then
                self.m_callBack()
            end
        end

        self:closeUI(closeBack)
    elseif name == "btn_close" then
        local closeBack = function()
            if self.m_callBack then
                self.m_callBack()
            end
        end
        self:closeUI(closeBack)
    end
    gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig() -- 商城公会权益发生变化
end

return ClanRankReportLayer