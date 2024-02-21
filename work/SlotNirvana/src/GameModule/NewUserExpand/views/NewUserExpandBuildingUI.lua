--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-08 16:52:36
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-08 16:52:55
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/NewUserExpandBuildingUI.lua
Description: 扩圈系统 地图建筑物
--]]
local NewUserExpandBuildingUI = class("NewUserExpandBuildingUI", BaseView)

function NewUserExpandBuildingUI:initDatas(_buidType)
    NewUserExpandBuildingUI.super.initDatas(self)

    -- 建筑物type
    self.m_buidType = _buidType
end

function NewUserExpandBuildingUI:getCsbName()
    return string.format("NewUser_Expend/Activity/csd/Build/NewUser_Build_%s.csb", self.m_buidType)
end

function NewUserExpandBuildingUI:initCsbNodes()
    self.m_spBuild = self:findChild("sp_Build")
    self.m_size = self.m_spBuild:getContentSize()
end

function NewUserExpandBuildingUI:onEnter()
    self.m_bEnter = true
end

function NewUserExpandBuildingUI:updateVisible()
    if not self.m_bEnter then
        return
    end
    local posSelf = self.m_spBuild:convertToWorldSpace(cc.p(0, 0))
    local sizeSelf = self.m_size
    local bVisible = cc.rectIntersectsRect(cc.rect(0, 0, display.width, display.height), cc.rect(posSelf.x, posSelf.y, sizeSelf.width, sizeSelf.height))
    self:setVisible(bVisible)
end

return NewUserExpandBuildingUI