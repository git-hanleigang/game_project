--转盘上奖励节点
local QuestNewWheelItemNode = class("QuestNewWheelItemNode", util_require("base.BaseView"))

function QuestNewWheelItemNode:initDatas(data)
    self.m_data = data.item_data
    self.m_type = data.type or "4"
    self.m_unlock = not not data.unlock
end

function QuestNewWheelItemNode:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewWheelItemNode .. self.m_type .. ".csb"
end

function QuestNewWheelItemNode:initUI()
    self:createCsbNode(self:getCsbName())
    self:runCsbAction("idle", true)
    self:initView()
end

function QuestNewWheelItemNode:refreshByData(data)
    self.m_data = data
    self.m_index = data.p_id
    self:initView()
end

function QuestNewWheelItemNode:initCsbNodes()
    self.m_node_Coin = self:findChild("Node_1") 
    self.m_lb_shuzi = self:findChild("lb_shuzi") 

    self.m_node_arrow = self:findChild("node_arrow") 

    self.m_node_jackpot= self:findChild("node_jackpot") 
end

function QuestNewWheelItemNode:initView()
    if self.m_data:getCoins() > 0 then
        self.m_lb_shuzi:setString(util_formatCoins(self.m_data:getCoins(), 4))
    end
    self:refreshType()
end

function QuestNewWheelItemNode:refreshType()
    if self.m_data:getType() == "Coin" or self.m_data:getType() == "Item"  then
        self:runCsbAction("reward", true)
    elseif self.m_data:getType() == "Minor" or self.m_data:getType() == "Major" or self.m_data:getType() == "Grand"  then
        self:runCsbAction("jackpot", true) 
    elseif self.m_data:getType() == "Pointer" then
        if self.m_unlock then
            self:runCsbAction("arrow", true)
        else
            self:runCsbAction("reward", true)
        end
    end
end

function QuestNewWheelItemNode:doChangeToArrow(callBack)
    if self.m_data:isWillChangeToPointer() then
        self.m_data:clearRememberData()
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_WheelChangetToPointer)
        self:runCsbAction("start", false,function ()
            self:runCsbAction("arrow", true)
            if callBack then
                callBack()
            end
        end)
    else
        if callBack then
            callBack()
        end
    end
end


return QuestNewWheelItemNode
