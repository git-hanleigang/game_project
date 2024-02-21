
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local ShopBuckGuideMgr = class("ShopBuckGuideMgr", GameGuideCtrl)

-- 引导开关
local TestGuideSwitch = true
-- 引导记录开关（不记录则每次重新登陆后进入都会有引导）
local TestGuideRecordSwitch = true

function ShopBuckGuideMgr:ctor()
    ShopBuckGuideMgr.super.ctor(self)
    self:setRefName(G_REF.ShopBuck)

    self:setMaskLua("GameModule.ShopBuck.views.guide.BuckGuideMaskLayer")
end

-- 注册引导模块
function ShopBuckGuideMgr:onRegist()
    self:setGuideTheme(G_REF.ShopBuck)
    local shopBuckGuideData = require("GameModule.ShopBuck.model.ShopBuckGuideData")
    self:initGuideDatas(shopBuckGuideData)
    ShopBuckGuideMgr.super.onRegist(self)
end

function ShopBuckGuideMgr:getSaveDataKey()
    return "ShopBuckGuideData_" .. globalData.userRunData.uid
end

-- 加载引导记录数据
function ShopBuckGuideMgr:reloadGuideRecords()
    if not TestGuideRecordSwitch then
        return
    end
    local strData = "{}"
    local key = self:getSaveDataKey()
    strData = gLobalDataManager:getStringByField(key, "{}")
    local tbData = cjson.decode(strData)
    ShopBuckGuideMgr.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function ShopBuckGuideMgr:saveGuideRecord()
    if TestGuideMode then
        return
    end
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    local key = self:getSaveDataKey()
    gLobalDataManager:setStringByField(key, strRecords)
end

function ShopBuckGuideMgr:getUDefGuideNode(layer, key)
    if key == "s002" then
        -- 提高金币页签，不穿透
        return layer:getUpCoinNode()
    elseif key == "t002" then
        -- 提高金币页签，不穿透
        return layer:getUpCoinNode()
    elseif key == "s003" then
        -- 提高cell上的付费按钮，不穿透
        return layer:getUpCellBtnNode()
    elseif key == "t003" then
        return layer:getUpCellBtnNode()
    elseif key == "s2001" then
        return layer:getUpCellGuide()
    elseif key == "s2002" then
        return layer:getUpCellGuide()          
    elseif key == "t2001" then
        return layer:getUpCellGuide()
    elseif key == "t2002" then
        return layer:getUpCellGuide()    
    end
    -- if key == "s002"  then
    --     return layer:getChapterByIndex(1)
    -- elseif key == "s0031"  then
    --     local guideNodes = layer:getGuideNodes()
    --     if guideNodes then
    --         return guideNodes["jewel"]
    --     end
    -- elseif key == "s0032"  then
    --     local guideNodes = layer:getGuideNodes()
    --     if guideNodes then
    --         local slateNodes = guideNodes["slate"]
    --         if slateNodes and #slateNodes > 0 then
    --             return slateNodes[1]
    --         end
    --     end
    -- elseif key == "s0033"  then
    --     local guideNodes = layer:getGuideNodes()
    --     if guideNodes then
    --         local slateNodes = guideNodes["slate"]
    --         if slateNodes and #slateNodes > 0 then
    --             return slateNodes[2]
    --         end
    --     end
    -- elseif key == "s0034"  then
    --     local guideNodes = layer:getGuideNodes()
    --     if guideNodes then
    --         local slateNodes = guideNodes["slate"]
    --         if slateNodes and #slateNodes > 0 then
    --             return slateNodes[3]
    --         end
    --     end
    -- elseif key == "s0035"  then
    --     local guideNodes = layer:getGuideNodes()
    --     if guideNodes then
    --         return guideNodes["hammer"]
    --     end
    -- elseif key == "s005" then
    --     return layer:getSlateGuideNumNode()
    -- end
end

-- 触发引导
function ShopBuckGuideMgr:triggerGuide(view, guideName, themeName)
    if not TestGuideSwitch then
        return false
    end
    return ShopBuckGuideMgr.super.triggerGuide(self, view, guideName, themeName)
end

function ShopBuckGuideMgr:triggerGuideAction(callFunc, view, curStepInfo, guideName)
    if callFunc then
        callFunc()
    end
end

return ShopBuckGuideMgr
