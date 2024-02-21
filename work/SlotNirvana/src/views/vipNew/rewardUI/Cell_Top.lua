--[[--
    listcell中的第一行
]]
local Cell_Top = class("Cell_Top", BaseView)
function Cell_Top:getCsbName()
    return "VipNew/csd/rewardUI/Cell_Top.csb"
end

function Cell_Top:initDatas(_cellIndex)
    self.m_cellIndex = _cellIndex
end

function Cell_Top:initCsbNodes()
    self.m_spIcon = self:findChild("sp_icon")
    self.m_spName = self:findChild("sp_name")
    self.m_nodeFlag = self:findChild("node_flag")
end

function Cell_Top:initUI()
    Cell_Top.super.initUI(self)

    local vipData = self:getVipData(self.m_cellIndex)
    if not vipData then
        return
    end
    -- icon
    local iconPath = VipConfig.logo_small .. vipData.levelIndex .. ".png"
    util_changeTexture(self.m_spIcon, iconPath)
    -- name
    local namePath = VipConfig.name_middle .. vipData.levelIndex .. ".png"
    util_changeTexture(self.m_spName, namePath)
    -- flag
    --local isFlag, vipLevel = self:isFlag()
    -- if isFlag and vipLevel == self.m_cellIndex then
    --     local flagNode = util_createView("views.vipNew.rewardUI.CellFlag")
    --     self.m_nodeFlag:addChild(flagNode)
    --     flagNode:updateFlag("upgraded")
    -- end
end

function Cell_Top:getVipData(_vipLevel)
    local data = G_GetMgr(G_REF.Vip):getData()
    if not data then
        return
    end
    local vipData = data:getVipLevelInfo(_vipLevel)
    -- assert(vipData ~= nil, "VipData is nil")
    return vipData
end

function Cell_Top:isFlag()
    local data = G_GetMgr(G_REF.Vip):getData()
    if not data then
        return
    end
    local vipLevel = globalData.userRunData.vipLevel
    local VipBoostData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if VipBoostData and VipBoostData:isOpenBoost() then
        local nextData = data:getVipLevelInfo(vipLevel + VipBoostData.p_extraVipLevel) --获取下一个等级的VIP数据
        if nextData then
            return true, nextData.levelIndex
        end
    end
    return false
end

return Cell_Top
