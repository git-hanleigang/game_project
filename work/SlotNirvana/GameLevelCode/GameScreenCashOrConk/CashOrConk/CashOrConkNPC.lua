local CashOrConkNPC = class("CashOrConkNPC",util_require("base.BaseView"))

function CashOrConkNPC:initUI(data)
    local spine = util_spineCreate("Socre_CashOrConk_juese",true,true)
    self._spine = spine
    self:addChild(self._spine)
    self:playAnim("idle",true)

    local animBubble = util_createAnimation("CashOrConk_qipaokuang.csb")
    data.machine:findChild("qipaokuang"):addChild(animBubble)
    self._animBubble = animBubble

    self:playBaseNormal()
end

function CashOrConkNPC:showBubbleNode(hashNode)
    for k,v in pairs(self._animBubble:findChild("Node_13"):getChildren()) do
        local name = v:getName()
        v:setVisible(hashNode[name] ~= nil)
    end
end

function CashOrConkNPC:playBaseNormal()
    return self:playDFNromal("0")
end

function CashOrConkNPC:playBaseBigWin()
    self:playAnim("actionframe",false)
    self._animBubble:stopAllActions()
    self:showBubbleNode({
        ["base_teshu"] = true
    })
    local action = cc.Sequence:create(
        cc.CallFunc:create(function()
            self._animBubble:playAction("auto",false)
            self._animBubble:findChild("daying"):show()
            self._animBubble:findChild("duobonus"):hide()
            self._animBubble:findChild("chuwanfa"):hide()
            self._animBubble:findChild("caijiangli"):hide()
        end),
        cc.DelayTime:create(4 + 220/60),
        cc.CallFunc:create(function()
            self:playBaseNormal()
        end)
    )

    self._animBubble:runAction(action)

    return action
end

local hash_state2node = {
    ["0"]   = "base_classic",
    ["1_2"] = "DF12_classic",
    ["2_1"] = "DF21_classic",
    ["2_2"] = "DF22_classic",
    ["3_1"] = "DF31_classic",
    ["3_2"] = "DF32_classic",
}
function CashOrConkNPC:playDFNromal(state)
    self._animBubble:stopAllActions()

    local name_node = hash_state2node[state]

    self:showBubbleNode({
        [name_node] = true
    })

    local list_node = {}
    for k,v in pairs(self._animBubble:findChild(name_node):getChildren()) do
        list_node[#list_node + 1] = v:getName()
    end

    local funcShowIndex = function(index)
        for i,v in ipairs(list_node) do
            self._animBubble:findChild(v):setVisible(i == index)
        end
    end
    local actions = {}

    for i=1,#list_node do
        local action = cc.Sequence:create(
            cc.CallFunc:create(function()
                self._animBubble:playAction("auto",false)
                funcShowIndex(i)
            end),
            cc.DelayTime:create(4 + 220/60)
        )
        actions[#actions + 1] = action
    end
    

    action = cc.RepeatForever:create(cc.Sequence:create(actions))

    self._animBubble:runAction(action)

    return action
end


local hash_special_state2node = {
    ["0"]   = "base_teshu",
    ["1_2"] = "DF12_teshu",
    ["2_2"] = "DF22_teshu",
    ["3_2"] = "DF32_teshu",
}
function CashOrConkNPC:playDFSpecial(state,node_name_show)
    self._animBubble:stopAllActions()

    local node_name = hash_special_state2node[state]

    self:showBubbleNode({
        [node_name] = true
    })

    for k,v in pairs(self._animBubble:findChild(node_name):getChildren()) do
        v:setVisible(v:getName() == node_name_show)
    end

    local actions = {}

    for i=1,1 do
        local action = cc.Sequence:create(
            cc.CallFunc:create(function()
                self._animBubble:playAction("auto",false)
            end),
            cc.DelayTime:create(4 + 220/60),
            cc.CallFunc:create(function()
                self:playDFNromal(state)
            end)
        )
        actions[#actions + 1] = action
    end
    

    action = cc.RepeatForever:create(cc.Sequence:create(actions))

    self._animBubble:runAction(action)

    return action
end

function CashOrConkNPC:playAnim(name,loop,func)
    util_spinePlayAction(self._spine, name, loop, function()
        if func then
            func()
        else
            self:playAnim("idle",true)
        end
    end)
end

return CashOrConkNPC