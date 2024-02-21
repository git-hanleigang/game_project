
local AlbumRaceNewChipsMgr = class("AlbumRaceNewChipsMgr", BaseActivityControl)
function AlbumRaceNewChipsMgr:ctor()
    AlbumRaceNewChipsMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.AlbumRaceNewChips)
end


function AlbumRaceNewChipsMgr:showInfoLayer()
    if not self:isCanShowLayer() then
        return false
    end
    if gLobalViewManager:getViewByExtendData("Activity_AlbumRaceNewChipsInfoLayer") == nil then
        local view = util_createView("Activity.Activity_AlbumRaceNewChipsInfoLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
        return view
    end
    return nil
end


return AlbumRaceNewChipsMgr
