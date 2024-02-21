---
--island
--2018年6月5日
--BlackFridayRespinBerView.lua

local BlackFridayRespinBerView = class("BlackFridayRespinBerView", util_require("base.BaseView"))
BlackFridayRespinBerView.m_liangNum = {}

function BlackFridayRespinBerView:initUI(params)

    self.m_machine = params.machine

    local resourceFilename="BlackFriday_respin_bar.csb"
    self:createCsbNode(resourceFilename)
    
    for nodeNum = 1, 3 do
        self.m_liangNum[nodeNum] = util_createAnimation("BlackFriday_respin_bar_num.csb")
        self:findChild("Node_"..nodeNum):addChild(self.m_liangNum[nodeNum])
        for zi_Num = 1, 3 do
            self.m_liangNum[nodeNum]:findChild("zi_"..zi_Num):setVisible(false)
        end
        self.m_liangNum[nodeNum]:findChild("zi_"..nodeNum):setVisible(true)
        self.m_liangNum[nodeNum]:setVisible(false)
    end
end

-- 更新respin次数
function BlackFridayRespinBerView:updateLeftCount(num,isLiang)

    for nodeNum = 1, 3 do
        self.m_liangNum[nodeNum]:setVisible(false)
    end
    self:findChild("Node_4"):setVisible(true)
    self:findChild("Node_5"):setVisible(false)

    if num >= 3 then
        self.m_liangNum[3]:setVisible(true)
        if isLiang then
            self:runCsbAction("actionframe",false)
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_respin_num_update)
        end
    else
        if num == 0 then
            return
        end
        self.m_liangNum[num]:setVisible(true)
    end
end

-- 次数为0 之后 显示不一样的UI
function BlackFridayRespinBerView:showReSpinBerUI( )
    self:findChild("Node_4"):setVisible(false)
    self:findChild("Node_5"):setVisible(true)
end

function BlackFridayRespinBerView:onEnter()
    BlackFridayRespinBerView.super.onEnter(self)
end

function BlackFridayRespinBerView:onExit()
    BlackFridayRespinBerView.super.onExit(self)
end


return BlackFridayRespinBerView