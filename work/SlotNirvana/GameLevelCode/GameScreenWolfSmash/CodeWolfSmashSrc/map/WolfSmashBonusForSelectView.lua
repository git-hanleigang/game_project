---
--xcyy
--2018年5月23日
--WolfSmashBonusForSelectView.lua

local WolfSmashBonusForSelectView = class("WolfSmashBonusForSelectView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WolfSmashPublicConfig"

function WolfSmashBonusForSelectView:initUI(machine,index)

    self:createCsbNode("WolfSmash_tanban_pig.csb")
    self.m_machine = machine
    self.multiple = 0
    self.pigIndex = index
    self:addClick(self:findChild("Panel_1")) -- 非按钮节点得手动绑定监听
    self.m_Click = true
    self.pigSpine = nil

end

function WolfSmashBonusForSelectView:addPigSpine(pigSpine)
    self.pigSpine = pigSpine
    self:findChild("Node_1"):addChild(pigSpine)
end

function WolfSmashBonusForSelectView:setMultiple(multiple)
    self.multiple = multiple
end

function WolfSmashBonusForSelectView:setClick(isClick)
    self.m_Click = isClick
end

function WolfSmashBonusForSelectView:setIdle()
    if self.pigSpine then
        util_spinePlay(self.pigSpine, "idleframe2", true)
    end
    
end

function WolfSmashBonusForSelectView:showClickEffect()
    self.m_Click = false
        if self.multiple ~= 0 then
            self.m_machine:showClickBottomEnabled(3,true)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_free_select_clickPig)
            self.m_machine:setCurClickType(4)
            if self.pigSpine then
                util_spinePlay(self.pigSpine, "shouji", false)
            end
            self.m_machine.selectList[#self.m_machine.selectList + 1] = self.multiple
            self.m_machine.curClickIndex = self.m_machine.curClickIndex + 1
            local curIndex = self.m_machine.curClickIndex
            --记录当前点击的下标
            self.m_machine.curClickIndexList[#self.m_machine.curClickIndexList + 1] = self.pigIndex
            local startPos = util_convertToNodeSpace(self.pigSpine,self.m_machine)
            self.m_machine:FlyParticle(startPos,function ()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_free_select_clickPig_fankui)
                self.m_machine:clickPigForMapShow(curIndex,self.multiple,self.pigIndex)
                if self.m_machine.curClickIndex == self.m_machine.totalClickIndex then
                    -- self.m_machine:setPlayBottom(true)
                    self.m_machine:showClickBottomEnabled(2,true)
                end
            end)
            
        end
end

--默认按钮监听回调
function WolfSmashBonusForSelectView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self.m_Click then
        return
    end

    if name == "Panel_1" then
        self:showClickEffect()
    end
end


return WolfSmashBonusForSelectView