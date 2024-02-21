--[[
    第二货币抽奖
]]

local GemMayWinNet = require("activities.Activity_GemMayWin.net.GemMayWinNet")
local GemMayWinMgr = class("GemMayWinMgr", BaseActivityControl)

function GemMayWinMgr:ctor()
    GemMayWinMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.GemMayWin)
    self.m_net = GemMayWinNet:getInstance()
end

function GemMayWinMgr:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end
    local theme = self:getThemeName()
    local view = util_createView(theme..".Activity."..theme, _data)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function GemMayWinMgr:shwoInfoLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local theme = self:getThemeName()
    if gLobalViewManager:getViewByExtendData(theme.."Info") == nil then
        local view = util_createView(theme..".Activity."..theme.."Info", _data)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function GemMayWinMgr:shwoConfirmLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end
    local theme = self:getThemeName()
    if gLobalViewManager:getViewByExtendData(theme.."Confirm") == nil then
        local view = util_createView(theme..".Activity."..theme.."Confirm", _data)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function GemMayWinMgr:shwoCollectLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end
    local theme = self:getThemeName()
    if gLobalViewManager:getViewByExtendData(theme.."Collect") == nil then
        local view = util_createView(theme..".Activity."..theme.."Collect", _data)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function GemMayWinMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function GemMayWinMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function GemMayWinMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function GemMayWinMgr:gemMayWinSpin()
    self.m_net:gemMayWinSpin()
end

return GemMayWinMgr
