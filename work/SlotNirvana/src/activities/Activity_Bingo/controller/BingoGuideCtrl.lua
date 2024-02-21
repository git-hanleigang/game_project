--[[

    time:2022-09-01 11:38:28
]]
local BingoGuideData = require("activities.Activity_Bingo.model.BingoGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local BingoGuideCtrl = class("BingoGuideCtrl", GameGuideCtrl)

function BingoGuideCtrl:ctor()
    BingoGuideCtrl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Bingo)
    -- self:setGuideData(BingoGuideData)
end

-- 注册引导模块
function BingoGuideCtrl:onRegist(guideTheme)
    -- if guideTheme ~= BingoGuideData.guideTheme then
    --     return
    -- end
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(BingoGuideData)
    BingoGuideCtrl.super.onRegist(self)
end

function BingoGuideCtrl:onRemove()
    self:stopGuide()
end

-- 加载引导记录数据
function BingoGuideCtrl:reloadGuideRecords()
    local strData = "{}"
    local bingoData = G_GetMgr(ACTIVITY_REF.Bingo):getRunningData()
    if bingoData then
        strData = bingoData:getGuideData()
    end
    local tbData = cjson.decode(strData)

    BingoGuideCtrl.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function BingoGuideCtrl:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    G_GetMgr(ACTIVITY_REF.Bingo):setSaveData(strRecords)
    -- gLobalDataManager:setStringByField(guideTheme, strRecords)
    -- printInfo("save %s guide record!!", guideTheme)
end

return BingoGuideCtrl
