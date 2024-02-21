--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-10-27 22:38:49
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-10-27 22:39:13
FilePath: /SlotNirvana/src/views/clan/baseInfo/region/ClanRegionCell.lua
Description: 国家地区 cell
--]]
local ClanRegionCell = class("ClanRegionCell", BaseView)

function ClanRegionCell:getCsbName()
    return "Club/csd/ClubEstablish/Club_Create_team_Info_Country.csb"
end

function ClanRegionCell:initCsbNodes()
    self.m_layoutName = self:findChild("layout_desc")
    self.m_lbName = self:findChild("lb_desc")
end

function ClanRegionCell:updateUI(_name)
    self.m_lbName:setString(_name or "")
    self.m_name = _name
end

function ClanRegionCell:swingWord()
    util_wordSwing(self.m_lbName, 1, self.m_layoutName, 1, 30, 1)
end

function ClanRegionCell:stopSwing()
    self.m_lbName:stopAllActions()
    self.m_lbName:setPositionX(0)
end

function ClanRegionCell:getData()
    return self.m_name 
end

return ClanRegionCell