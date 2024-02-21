---
--island
--2018年6月5日
--LinkFishFireworks.lua
local LinkFishJackPotNum = class("LinkFishJackPotNum", util_require("base.BaseView"))

LinkFishJackPotNum.m_nowNum = 0
function LinkFishJackPotNum:initUI(data)
    self.m_machine = data.machine
    local resourceFilename="Socre_LinkFish_Top_collect.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idleframe", true)

end

function LinkFishJackPotNum:updateCollectNum(num)     
    self.m_nowNum = num
    self:findChild("x_0_0"):setString(num)

    local status = self.m_machine.m_jackpot_status
    self:findChild("super"):setVisible(status == "Super")
    self:findChild("mega"):setVisible(status == "Mega")
    self:findChild("grand"):setVisible(status == "Normal")
end

function LinkFishJackPotNum:getCollectNowNum()
    return self.m_nowNum
end

function LinkFishJackPotNum:onEnter()
    
end


function LinkFishJackPotNum:onExit()

end

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return LinkFishJackPotNum