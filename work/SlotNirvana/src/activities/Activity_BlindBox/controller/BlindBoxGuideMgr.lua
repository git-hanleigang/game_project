--[[

]]

local BlindBoxGuideData = require("activities.Activity_BlindBox.model.BlindBoxGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local BlindBoxGuideMgr = class("BlindBoxGuideMgr", GameGuideCtrl)

function BlindBoxGuideMgr:ctor()
    BlindBoxGuideMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.BlindBox)
end

-- 注册引导模块
function BlindBoxGuideMgr:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(BlindBoxGuideData)
    BlindBoxGuideMgr.super.onRegist(self)
end

function BlindBoxGuideMgr:onRemove()
    self:stopGuide()
end

-- 加载引导记录数据
function BlindBoxGuideMgr:reloadGuideRecords()
    local guideTheme = self:getGuideTheme()
    local strData = gLobalDataManager:getStringByField(guideTheme, "{}") 
    local taData = util_cjsonDecode(strData) or {}
    BlindBoxGuideMgr.super.reloadGuideRecords(self, taData)
end

-- 引导记录数据存盘
function BlindBoxGuideMgr:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    gLobalDataManager:setStringByField(guideTheme, strRecords)
end

function BlindBoxGuideMgr:updateTipView(tipNode, tipInfo)
    -- tipNode:updateUI(tipInfo.m_tipId)
end

return BlindBoxGuideMgr
