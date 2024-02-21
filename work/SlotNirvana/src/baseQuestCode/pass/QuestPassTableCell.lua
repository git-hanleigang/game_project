--[[
    
]]
local QuestPassTableCell = class("QuestPassTableCell", BaseView)

function QuestPassTableCell:getCsbName()
    return QUEST_RES_PATH.QuestPassTableCell
end

function QuestPassTableCell:initCsbNodes()
    self.m_node_tag = self:findChild("node_tag")
    self.m_node_free = self:findChild("node_free")
    self.m_node_ticket = self:findChild("node_ticket")
    self.m_node_safebox = self:findChild("node_safebox")
    self.m_node_cell = self:findChild("node_cell")
end

function QuestPassTableCell:initDatas(_layer)
    self.m_passLayer = _layer
end

function QuestPassTableCell:loadDataUi(_data, _idx)
    self.m_data = _data
    self.m_index = _idx
    if _data then
        if self.m_freeReward then
            self.m_freeReward:removeFromParent()
            self.m_freeReward = nil
        end

        if self.m_payReward then
            self.m_payReward:removeFromParent()
            self.m_payReward = nil
        end

        if self.m_boxReward then
            self.m_boxReward:removeFromParent()
            self.m_boxReward = nil
        end

        if _data.occupied then
            if self.m_node_tag then
                self.m_node_tag:setVisible(true)
            end
            if self.m_node_cell then
                self.m_node_cell:setVisible(false)
            end
            return
        end

        if _data.free then
            if self.m_node_tag then
                self.m_node_tag:setVisible(false)
            end
            if self.m_node_cell then
                self.m_node_cell:setVisible(true)
            end
            self.m_freeReward = util_createView(QUEST_CODE_PATH.QuestPassRewardNode, _data, "free", self.m_passLayer)
            self.m_freeReward:addTo(self.m_node_free)
        end

        if _data.pay then
            if self.m_node_tag then
                self.m_node_tag:setVisible(false)
            end
            if self.m_node_cell then
                self.m_node_cell:setVisible(true)
            end
            self.m_payReward = util_createView(QUEST_CODE_PATH.QuestPassRewardNode, _data, "pay", self.m_passLayer)
            self.m_payReward:addTo(self.m_node_ticket)
        end

        if _data.box then
            if self.m_node_tag then
                self.m_node_tag:setVisible(false)
            end
            if self.m_node_cell then
                self.m_node_cell:setVisible(true)
            end
            self.m_boxReward = util_createView(QUEST_CODE_PATH.QuestPassRewardBox, _data, self.m_passLayer)
            self.m_node_safebox:addChild(self.m_boxReward)
            return
        end
    end
end

function QuestPassTableCell:getCellByLevel(_boxType, _level)
    local node = nil
    if _boxType == "free" then
        if self.m_freeReward and self.m_freeReward:isCellByLevel(_level) then
            node = self.m_freeReward
        end
    elseif _boxType == "pay" then
        if self.m_payReward and self.m_payReward:isCellByLevel(_level) then
            node = self.m_payReward
        end
    elseif _boxType == "safeBox" then
        -- if self.m_boxView and self.m_boxView:isCellByLevel(_level) then
        --     node = self.m_boxView
        -- end
    end
    return node
end

return QuestPassTableCell