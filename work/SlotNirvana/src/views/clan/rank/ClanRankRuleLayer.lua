--[[
Author:cxc
Date: 2022-02-25 11:13:53
LastEditTime: 2022-02-25 11:13:54
LastEditors:cxc
Description: 公会排行榜规则 面板
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankRuleLayer.lua
--]]
local ClanRankRuleLayer = class("ClanRankRuleLayer", BaseLayer)

function ClanRankRuleLayer:ctor()
    ClanRankRuleLayer.super.ctor(self)
    self:setPauseSlotsEnabled(true) 
    self:setKeyBackEnabled(true) 

    self:setExtendData("ClanRankRuleLayer")
    self:setLandscapeCsbName("Club/csd/RANK/Club_RankRule.csb")
end

function ClanRankRuleLayer:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_close" then
        self:closeUI()
    end
end

return ClanRankRuleLayer