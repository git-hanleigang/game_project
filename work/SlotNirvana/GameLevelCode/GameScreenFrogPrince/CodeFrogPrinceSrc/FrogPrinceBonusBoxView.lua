---
--xhkj
--2018年6月11日
--FrogPrinceBonusBoxView.lua

local FrogPrinceBonusBoxView = class("FrogPrinceBonusBoxView", util_require("base.BaseView"))
FrogPrinceBonusBoxView.boxVec = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
function FrogPrinceBonusBoxView:initUI(data)
    self:createCsbNode("FrogPrince_BonusGameBox.csb")
    self:InitBoxView()
    self.m_clickFlag = false
end

function FrogPrinceBonusBoxView:InitBoxView()
  
    self.m_boxVec = {}
    for i, v in ipairs(self.boxVec) do
        local node = self:findChild("Node_" .. i)
        local data = {}
        data._value = v
        local box = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusBox", data)
        local pos = cc.p(node:getPosition())
        box:setScale(0.6)
        self:findChild("Node_28"):addChild(box)
        box:setTag(i)
        box:setPosition(pos)
        table.insert(self.m_boxVec, box)
        box:runCsbAction("idle3")
    end
end

function FrogPrinceBonusBoxView:createBigToSmallSymbol()
    local data = {}
    data._value = "I"
    local box = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusBox", data)
    box:setScale(4.8)
    return box
end
--获取位置对应的字母
function FrogPrinceBonusBoxView:getValueByPos(pos)
    return self.boxVec[pos]
end

function FrogPrinceBonusBoxView:showOpenBoxNum(num)
    for i = 1, num - 1 do
        local box = self.m_boxVec[i]
        box:runCsbAction("idleframe1")
    end
end

function FrogPrinceBonusBoxView:setCollectBox(num, _OpenFlag)
    if _OpenFlag == false then
        local strName = self:getValueByPos(num)
        local moveBox = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusOpenView")
        local lab1 = moveBox:findChild("m_lb_coins_1")
        local lab2 = moveBox:findChild("m_lb_coins_2")
        lab1:setString(strName)
        lab2:setString(strName)
        self:findChild("Node_28"):addChild(moveBox)
        -- local spos = cc.p(moveBox:getPosition())
       
        local root =  self.m_parent.m_machine.m_machineNode:getChildByName("root")
        if root then
            local scale = root:getScale()
            moveBox:setScale(scale)
            local bonusNode = self.m_parent.m_machine.m_machineNode:getChildByName("bonusNode")
            local posWorld = self.m_parent.m_machine.m_machineNode:convertToWorldSpace(cc.p(bonusNode:getPosition()))
            local startPos = self:findChild("Node_28"):convertToNodeSpace(posWorld)
            moveBox:setPosition(startPos)
        end

        -- local slotParent = node:getParent()
        -- local posWorld = slotParent:convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
        -- local startPos = self:findChild("FrogPrince_baoxiang"):convertToNodeSpace(cc.p(posWorld.x, posWorld.y))

        local pos = cc.p(self:findChild("Node_" .. num):getPosition())
        local moveto = cc.MoveTo:create(0.66, pos)
        local scaleto = cc.ScaleTo:create(0.66, 0.22*0.75)
        local spw = cc.Spawn:create(moveto, scaleto)
        moveBox:runCsbAction("animation0",false)
        local movetoFunc =
            cc.CallFunc:create(
            function()
                local box = self.m_boxVec[num]
                box:runCsbAction("idleframe1")
                moveBox:removeFromParent()
                if self.m_parent.m_machine:isTriggerBonusGame() then
                    self.m_clickFlag = false
                    performWithDelay(
                        self,
                        function()
                            gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_sound_tip1_qi.mp3")
                            self:runCsbAction(
                                "over",
                                false,
                                function()
                                    self.m_parent:hideBoxView()
                                end
                            )
                        end,
                        1
                    )
                else
                    performWithDelay(
                        self,
                        function()
                            if self.m_clickFlag == true then
                                self.m_clickFlag = false
                                self.m_parent:hideBoxView()
                            end
                        end,
                        3
                    )
                    self.m_clickFlag = true
                end
            end
        )
        local seq = cc.Sequence:create(spw, movetoFunc)
        moveBox:runAction(seq)
    else
        for i = 1, num do
            local box = self.m_boxVec[i]
            box:runCsbAction("idleframe1")
        end
        self.m_clickFlag = true
    end
end

function FrogPrinceBonusBoxView:onEnter()
end

function FrogPrinceBonusBoxView:setParent(parent)
    self.m_parent = parent
end

function FrogPrinceBonusBoxView:onExit()
    
end

function FrogPrinceBonusBoxView:setClickFlag(_bflag)
    self.m_clickFlag = _bflag
end

function FrogPrinceBonusBoxView:clickFunc(sender)

    if self.m_clickFlag == false then
        return
    end
    self.m_clickFlag = false
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local name = sender:getName()
    if name == "Button" then
        -- self:runCsbAction(
        --     "over",
        --     false,
        --     function()
        self:stopAllActions()
        self.m_parent:hideBoxView()
    --     end
    -- )
    end
end

return FrogPrinceBonusBoxView
