--[[
    
]]

local RoutineSaleTurntable = class("RoutineSaleTurntable", BaseView)

function RoutineSaleTurntable:getCsbName()
    return "Sale_New/csb/main/SaleMain_turntable.csb"
end

function RoutineSaleTurntable:initUI()
    RoutineSaleTurntable.super.initUI(self)
    
    self.m_data = G_GetMgr(G_REF.RoutineSale):getRunningData()
    self.m_curPro = self.m_data:getWheelCurPro()
    self.m_totalPro = self.m_data:getWheelAllPro()
    self.m_wheelChunk = self.m_data:getWheelChunk()
    


    for i = 1, self.m_totalPro do
        local node = self:findChild("sp_sector_" .. i)
        if node then
            local info = self.m_wheelChunk[i] or {}
            local index = info.p_index or 1
            node:setVisible(i <= self.m_curPro)
            util_changeTexture(node, "Sale_New/ui/main/ui_main_prize_sector" ..  index .. ".png")
        end
    end

    self:runCsbAction("idle2", true)
end

function RoutineSaleTurntable:getPosAndRotate()
    local index = self.m_curPro + 1
    index = index >= self.m_totalPro and self.m_totalPro or index
    local sp_sector = self:findChild("sp_sector_" .. index)
    local x, y = sp_sector:getPosition()
    local worldPos = sp_sector:getParent():convertToWorldSpace(cc.p(x, y))
    local content = sp_sector:getContentSize()
    local rotate = {0, 120, -120}
    
    return worldPos, rotate[index], content
end

function RoutineSaleTurntable:playIdle()
    self:runCsbAction("idle", true)
end

function RoutineSaleTurntable:updateView()
    self.m_curPro = self.m_curPro + 1

    for i = 1, self.m_totalPro do
        local node = self:findChild("sp_sector_" .. i)
        if node then
            node:setVisible(i <= self.m_curPro)
        end
    end
end

return RoutineSaleTurntable