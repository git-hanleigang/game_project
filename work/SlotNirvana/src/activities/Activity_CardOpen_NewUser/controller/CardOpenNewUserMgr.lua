--[[
    新手期集卡开启宣传
]]
local CardOpenNewUserMgr = class("CardOpenNewUserMgr", BaseActivityControl)

function CardOpenNewUserMgr:ctor()
    CardOpenNewUserMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CardOpenNewUser)
end

-- 缓存在mgr，不放入data中，不受新手期结束的影响
function CardOpenNewUserMgr:setNoviceCardSimpleInfo(_simpleInfo)
    if not _simpleInfo then
        return
    end

    local showData = self:getHallSlideShowData()
    if showData then
       showData:parseNoviceCardSimpData(_simpleInfo)
    end
end
function CardOpenNewUserMgr:getHallSlideShowData()
    if self._hallSlideShowData then
        return self._hallSlideShowData
    end

    self._hallSlideShowData = util_require("activities.Activity_CardOpen_NewUser.model.CardOpenNewUserHallSlideShowData"):create()
    return self._hallSlideShowData
end

-- 是否可以显示 自定义轮播
function CardOpenNewUserMgr:canShowCustomSlide()
    local bRunningAndDLOver = self:isCanShowLobbyLayer()
    if not bRunningAndDLOver then
        return false
    end

    local showData = self:getHallSlideShowData()
    if not showData then
        return false
    end

    local popupControl = PopUpManager:getPopupControlData(self:getRunningData())
    if popupControl and popupControl.p_slidShow == 1 then
        return showData:checkEnabled()
    end

    return false
end

-- 是否可以显示 自定义展示
function CardOpenNewUserMgr:canShowCustomHall()
    local bRunningAndDLOver = self:isCanShowLobbyLayer()
    if not bRunningAndDLOver then
        return false
    end

    local showData = self:getHallSlideShowData()
    if not showData then
        return false
    end

    local popupControl = PopUpManager:getPopupControlData(self:getRunningData())
    if popupControl and popupControl.p_hallShow == 1 then
        return showData:checkEnabled()
    end

    return false
end

function CardOpenNewUserMgr:showMainLayer(_params, _over)
    local function callFunc()
        if _over then
            _over()
        end
    end
    if gLobalViewManager:getViewByName("Activity_CardOpen_NewUser") then
        callFunc()
        return
    end
    local data = self:getRunningData()
    if not data then
        callFunc()
        return
    end
    if not self:isDownloadRes() then
        callFunc()
        return
    end
    local view = util_createView("Activity.Activity_CardOpen_NewUser", _params, callFunc)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    else
        callFunc()
    end
    return view
end

-- 轮播展示 系统手动创建(排序规则不一样， 不能由活动配置统一创建)
function CardOpenNewUserMgr:isCanShowSlide()
    return false
end
function CardOpenNewUserMgr:isCanShowHall()
    return false
end

return CardOpenNewUserMgr
