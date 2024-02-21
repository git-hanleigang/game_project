--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-07 18:05:30
]]
local GrandPrizeMgr = class("GrandPrizeMgr", BaseActivityControl)

function GrandPrizeMgr:ctor()
    GrandPrizeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.GrandPrize)
end

function GrandPrizeMgr:showRewardLayer(_rewardData, _callBack)
    local themeName = self:getThemeName()
    local luaName = themeName .. "RewardLayer"
    if gLobalViewManager:getViewByExtendData(luaName) ~= nil then
        if _callBack then
            _callBack()
        end
        return
    end
    local view = util_createView("Activity." .. luaName, _rewardData, _callBack)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

return GrandPrizeMgr
