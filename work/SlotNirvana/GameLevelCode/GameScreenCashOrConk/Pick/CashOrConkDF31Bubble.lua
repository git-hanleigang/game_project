local BaseView = require "base.BaseView"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

local CashOrConkDF31Bubble = class("CashOrConkDF31Bubble",BaseView)

local hash_randc2c = {
    "hong","lan","lv"
}

local hash_randc2c2 = {
    "zise","lanse","lvse"
}

function CashOrConkDF31Bubble:initUI(data)
    self._delegate = data.delegate
    
    self:createCsbNode("CashOrConk_DF31_xuanxiang.csb")
    self:addClick(self:findChild("touch"))
    local rand_color = math.random(1,3)
    self._rand_color = rand_color
    for i=1,3 do
        self:findChild("qiqiu"..i):setVisible(rand_color == i)
        self:findChild("qiqiu"..i.."_zha"):setVisible(false)
    end

    for i,v in ipairs(hash_randc2c2) do
        self:findChild("zg_"..v):setVisible(false)
    end
end

function CashOrConkDF31Bubble:playBoom(data)
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_21)
    self:findChild("touch"):setTouchEnabled(false)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    self:setLocalZOrder(0xffff)
    self._is_boomed = true
    self:findChild("qiqiu"..self._rand_color.."_zha"):show()
    self:findChild("zg_"..hash_randc2c2[self._rand_color]):show()
    self:runCsbAction("actionframe_dj")
    self:stopAllActions()
    self:runAction(cc.Sequence:create(
        cc.DelayTime:create(4/60),
        cc.CallFunc:create(function()
            if math.random(1,10) >= 9 then
                gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_44)
            end
            local node_particle = util_createAnimation("CashOrConk_tuoweilizi.csb")
            local particle = node_particle:findChild("Node_"..hash_randc2c[self._rand_color])
            for i,v in ipairs(hash_randc2c) do
                node_particle:findChild("Node_"..v):setVisible(self._rand_color == i)
            end
            for i=1,2 do
                particle:getChildByName("Particle_"..i):resetSystem()
                particle:getChildByName("Particle_"..i):setPositionType(0)
                particle:getChildByName("Particle_"..i):setDuration(-1)
            end
            local targetNode = self._delegate._machine:findChild("Node_top")
            targetNode:addChild(node_particle)
        
            local wp1 = self:convertToWorldSpace(cc.p(0,0))
            local np1 = targetNode:convertToNodeSpace(cc.p(wp1))
        
            local node_reward = self._delegate._machine._node_reward
            local wp2 = node_reward:convertToWorldSpace(cc.p(0,0))
            local np2 = targetNode:convertToNodeSpace(cc.p(wp2))
        
            np1.x = np1.x 
            np1.y = np1.y
            node_particle:setPosition(cc.p(np1))
            node_particle:runAction(cc.Sequence:create(
                cc.MoveTo:create(27/60,np2),
                cc.CallFunc:create(function()
                    for i=1,2 do
                        particle:getChildByName("Particle_"..i):stopSystem()
                    end
                    local addCoins = 0
                    if type(data) == "string" then
                        addCoins = node_reward._curCoinCount * tonumber(data) - node_reward._curCoinCount
                    else
                        addCoins = data * totalBet
                    end
                    node_reward:playAddCoins(addCoins)
                    self._delegate._machine._npc:playAnim("actionframe5",false)
                end),
                cc.DelayTime:create(1.7),
                cc.CallFunc:create(function()
                    node_particle:removeFromParent()
                end)
            ))
        end)
    ))

    local list_node = {"jine","chengbei","caijin"}
    for i,v in ipairs(list_node) do
        self:findChild(v):hide()
    end
    if type(data) == "string" then
        self:findChild("chengbei"):show()
        self:findChild("beishu"):setString("X"..data)
    else
        self:findChild("jine"):show()
        self:findChild("m_lb_coins"):setString(util_formatCoinsLN(data*totalBet, 3))
    end
end

function CashOrConkDF31Bubble:clickFunc(sender)
    if self._delegate._blockClick or self._is_boomed then
        return
    end

    if self._delegate:getWaitListCnt() >= 10 then
        return
    end

    self:setLocalZOrder(0xffff)

    self:stopAllActions()

    local name = sender:getName()
    local tag = sender:getTag()

    self._delegate:addWaitList(self)
    self._delegate:sendData(1)

end


return CashOrConkDF31Bubble