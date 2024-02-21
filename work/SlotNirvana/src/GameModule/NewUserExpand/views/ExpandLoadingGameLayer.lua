--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-04-28 16:50:13
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-04-28 16:50:23
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/ExpandLoadingGameLayer.lua
Description: 扩圈下载 loading 界面
--]]
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local ExpandLoadingGameLayer = class("ExpandLoadingGameLayer", BaseActivityMainLayer)

function ExpandLoadingGameLayer:initDatas(_downloadKey)
    ExpandLoadingGameLayer.super.initDatas(self)

    self.m_downloadKey = _downloadKey
    self.m_percent = 0
    self.m_loadingTime = os.time()

    self:setPortraitCsbName("NewUser_Expend/Activity/csd/NewUser_Loading.csb")
    self:setPauseSlotsEnabled(true)
    self:setHideLobbyEnabled(true)
    self:setExtendData("ExpandLoadingGameLayer")
    self:setName("ExpandLoadingGameLayer")
end

function ExpandLoadingGameLayer:initCsbNodes()
    self.m_progBar = self:findChild("LoadingBar_1")
    self.m_lbProg = self:findChild("lb_bar")

    self.m_spBg = self:findChild("sp_bg")
end

function ExpandLoadingGameLayer:initView()
    -- 下载进度
    local percent = globalDynamicDLControl:getPercentForKey(self.m_downloadKey)
    percent = math.max(percent, 0)
    self:updateLoadingBarPro(percent)

    -- 小游戏 loading背景
    util_changeTexture(self.m_spBg, string.format("NewUser_Expend/Activity/ui/Loading/Loading_%s.jpg", self.m_downloadKey))
end

-- 下载进度 更新
function ExpandLoadingGameLayer:onDownloadPercentEvt(_percent)
    local percent = math.max(_percent, 0)

    self:updateLoadingBarPro(percent)
end

-- 下载完成 进入小游戏
function ExpandLoadingGameLayer:onDownloadCompleteEvt(_percent)
    local percent = math.max(_percent, 0)

    self:updateLoadingBarPro(percent)
    self:checkDownloadComplete()
end

function ExpandLoadingGameLayer:updateLoadingBarPro(_percent)
    print("cxc------", _percent)
    local percent = math.min(_percent, 1) * 100
    if percent < self.m_percent then
        return
    end
    self.m_percent = percent
    self.m_progBar:setPercent(percent)
    self.m_lbProg:setString(string.format("%d%%", percent))
end

-- 检查是否下载完成
function ExpandLoadingGameLayer:checkDownloadComplete()
    local gameMgr = G_GetMgr(self.m_downloadKey)
    if not gameMgr:isDownloadRes() then
        return
    end

    self:updateLoadingBarPro(1)

    -- 界面loading耗时
    self.m_loadingTime = os.time() - self.m_loadingTime
    G_GetMgr(G_REF.NewUserExpand):getLogObj():sendExpandLoadingLog(self.m_loadingTime)

    -- 去小游戏界面
    self:closeUI()
end

function ExpandLoadingGameLayer:closeUI()
    local cb = function()
        -- 去小游戏主界面
        local gameMgr = G_GetMgr(self.m_downloadKey)
        gameMgr:showMainLayer()
    end

    ExpandLoadingGameLayer.super.closeUI(self, cb)
end

-- 界面是否横屏
function ExpandLoadingGameLayer:isLandscape()
    return false
end

function ExpandLoadingGameLayer:registerListener()
    ExpandLoadingGameLayer.super.registerListener(self)
    
    self:checkDownloadComplete()
    gLobalNoticManager:addObserver(self, "onDownloadPercentEvt", "DL_Percent" .. self.m_downloadKey)
    gLobalNoticManager:addObserver(self, "onDownloadCompleteEvt", "DL_Complete" .. self.m_downloadKey)
end

return ExpandLoadingGameLayer