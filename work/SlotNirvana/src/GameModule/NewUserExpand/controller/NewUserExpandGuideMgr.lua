--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-22 10:46:40
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-22 10:46:57
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/controller/NewUserExpandGuideMgr.lua
Description: 扩圈系统引导
--]]
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local NewUserExpandGuideMgr = class("NewUserExpandGuideMgr", GameGuideCtrl)

function NewUserExpandGuideMgr:ctor()
    NewUserExpandGuideMgr.super.ctor(self)
    self:setRefName(G_REF.NewUserExpand)

    self:onRegist(G_REF.NewUserExpand)
end

-- 注册引导模块
function NewUserExpandGuideMgr:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    local NewUserExpandGuideData = util_require("GameModule.NewUserExpand.model.NewUserExpandGuideData")
    self:initGuideDatas(NewUserExpandGuideData)
    NewUserExpandGuideMgr.super.onRegist(self)
end

function NewUserExpandGuideMgr:onRemove()
    self:stopGuide()
end

-- 加载引导记录数据
function NewUserExpandGuideMgr:reloadGuideRecords()
    local guideTheme = self:getGuideTheme()
    local strData = gLobalDataManager:getStringByField(guideTheme, "{}")
    local tbData = cjson.decode(strData)

    NewUserExpandGuideMgr.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function NewUserExpandGuideMgr:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    gLobalDataManager:setStringByField(guideTheme, strRecords)
    -- printInfo("save %s guide record!!", guideTheme)
end

return NewUserExpandGuideMgr
