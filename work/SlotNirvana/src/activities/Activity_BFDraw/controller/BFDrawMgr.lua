--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-03 16:59:51
]]
local BFDrawNet = require("activities.Activity_BFDraw.net.BFDrawNet")
local BFDrawMgr = class(" BFDrawMgr", BaseActivityControl)

-- 构造函数
function BFDrawMgr:ctor()
    BFDrawMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.BFDraw)
    self.m_BFDrawNet = BFDrawNet:getInstance()
end

function BFDrawMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function BFDrawMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function BFDrawMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

function BFDrawMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local refName = self:getRefName()
    local themeName = self:getThemeName(refName)
    local uiView = util_createView(themeName .. "/" .. themeName .. "MainLayer")
    if uiView then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

-- 颜料选择
function BFDrawMgr:requestDraw(_spin)
    self.m_BFDrawNet:requestDraw(_spin)
end

-- 黑五瓜分大奖领奖界面
function BFDrawMgr:showRewardLayer(themeName, coins, poolIndex, userCoins)
    
    
    -- local refName = self:getRefName()
    -- local themeName = self:getThemeName(refName)
    -- themeName 由邮件传过来
    -- 放到Inbox下了
                                --  InBox/Activity_BFCarnivalCollectLayer.lua
    local uiView = util_createView("InBox/Activity_BFCarnivalCollectLayer", coins, poolIndex, userCoins)
    if uiView then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

-- 黑五瓜分大奖宣传图界面
-- function BFDrawMgr:showPopLayer(popInfo, callback)
--     if not self:isCanShowPop() then
--         return nil
--     end

--     if popInfo and popInfo.clickFlag then
--         local refName = self:getRefName()
--         local themeName = self:getThemeName(refName)
--         local uiView = util_createView(themeName .. "/" .. themeName)
--         if uiView then
--             gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
--         end
--         return uiView   
--     end
--     return nil
-- end

-- 存本地
function BFDrawMgr:saveCGTime()
    -- local curTime = util_getCurrnetTime()
    local data = self:getData()
    local timeExpireAt = 0
    if data then
        timeExpireAt = data:getExpireAt()
    end
    gLobalDataManager:setNumberByField("BFCarnivalCGTime_" .. timeExpireAt , 1)
end

-- 是否显示CG
function BFDrawMgr:isPlayCG()
    local data = self:getData()
    local timeExpireAt = 0
    if data then
        timeExpireAt = data:getExpireAt()
    end
    local lastTime = gLobalDataManager:getNumberByField("BFCarnivalCGTime_" .. timeExpireAt, 0)
    if lastTime == 0 then
        return true
    end
    -- -- 是否跨天
    -- local oldSecs = lastTime
    -- local newSecs = util_getCurrnetTime()
    -- -- 服务器时间戳转本地时间
    -- local oldTM = util_UTC2TZ(oldSecs, -8)
    -- local newTM = util_UTC2TZ(newSecs, -8)
    -- if oldTM.day ~= newTM.day then
    --     return true
    -- end
    return false
end

return BFDrawMgr
