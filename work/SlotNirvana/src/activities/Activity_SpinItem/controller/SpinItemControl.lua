--[[
    spin送道具
]]
local SpinItemControl = class("SpinItemControl", BaseActivityControl)

function SpinItemControl:ctor()
    SpinItemControl.super.ctor(self)

    self:setRefName(ACTIVITY_REF.SpinItem)
end

function SpinItemControl:getEntryName()
    return self:getThemeName()
end

function SpinItemControl:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    local themeName = self:getThemeName()
    if gLobalViewManager:getViewByExtendData(themeName) == nil then
        local view = util_createView("Activity." .. themeName)
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end

    return view
end

function SpinItemControl:parseSlotata(_data)
    local data = self:getRunningData()
    if data then
        data:parseSlotata(_data)
    end
end

function SpinItemControl:getSlotData()
    local data = self:getRunningData()
    if data then
        return data:getSlotData()
    else
        return 0, 0
    end
end

function SpinItemControl:clearSlotData()
    local data = self:getRunningData()
    if data then
        data:clearSlotData()
    end
end

function SpinItemControl:getMinBet()
    local data = self:getRunningData()
    if data then
        return data:getMinBet()
    end
end

function SpinItemControl:getLevelLogoRes()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return nil
    end
    local themeName = self:getThemeName()
    if globalData.slotRunData.isPortrait then
        return "Activity/" .. themeName .. "/ui_slot/SpinItem_icon2.png"
    else
        return "Activity/" .. themeName .. "/ui_slot/SpinItem_icon.png"
    end
end

function SpinItemControl:getLevelLogoNode()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return nil
    end
    local themeName = self:getThemeName()
    local node, act = util_csbCreate("Activity/" .. themeName .. "/SpinItem_Icon.csb")

    if node then
        if globalData.slotRunData.isPortrait then
            node:getChildByName("sp_heng"):setVisible(false)
        else
            node:getChildByName("sp_shu"):setVisible(false)
        end
    end
    return node, act
end

function SpinItemControl:getLevelHeipingNode()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return nil
    end
    local themeName = self:getThemeName()
    local node, act = util_csbCreate("Activity/" .. themeName .. "/SpinItem_heiping.csb")
    return node, act, 105
end

function SpinItemControl:getEntryModule()
    local bShow = false
    local machineData = globalData.slotRunData.machineData
    if machineData then
        local name = machineData.p_name
        local data = self:getRunningData()
        local nameList = data:getNameList()
        for i, v in ipairs(nameList) do
            if v == name or v .. "_H" == name then
                bShow = true
                break
            end
        end
    end
    if bShow then
        return SpinItemControl.super.getEntryModule(self)
    else
        return ""
    end
end

return SpinItemControl
