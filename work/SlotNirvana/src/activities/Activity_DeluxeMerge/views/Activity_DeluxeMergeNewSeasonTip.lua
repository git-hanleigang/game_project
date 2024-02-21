--[[
Author: cxc
Date: 2021-12-15 10:40:39
LastEditTime: 2021-12-15 10:40:50
LastEditors: your name
Description: 合成新赛季 邮箱内点击 提示弹板
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/views/Activity_DeluxeMergeNewSeasonTip.lua
--]]
local Activity_DeluxeMergeNewSeasonTip = class("Activity_DeluxeMergeNewSeasonTip", BaseLayer)

function Activity_DeluxeMergeNewSeasonTip:ctor()
    Activity_DeluxeMergeNewSeasonTip.super.ctor(self)

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("InBox/Merge_pouchSource.csb")
end

function Activity_DeluxeMergeNewSeasonTip:initCsbNodes()
    self.m_lbSeason = self:findChild("txt_season_count")
end

function Activity_DeluxeMergeNewSeasonTip:initView()
    -- 赛季 lb
    if self.m_lbSeason then
        local actData = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):getRunningData()
        if actData then
            local curSeason = actData:getCurSeason() 
            self.m_lbSeason:setString(curSeason)
        end
    end
end

function Activity_DeluxeMergeNewSeasonTip:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_ok" then
        -- layer里的got it按钮，点击关闭弹板即可
        self:closeUI()
    elseif name == "btn_close" then
        self:closeUI()
    end 
end

return Activity_DeluxeMergeNewSeasonTip
