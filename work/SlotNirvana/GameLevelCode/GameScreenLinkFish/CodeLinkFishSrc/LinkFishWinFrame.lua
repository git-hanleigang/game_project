---
--island
--2018年6月5日
--LinkFishWinFrame.lua

local LinkFishWinFrame = class("LinkFishWinFrame", util_require("base.BaseView"))

LinkFishWinFrame.m_respinNum = 0

function LinkFishWinFrame:initUI(data)

    local resourceFilename="Socre_LinkFish_Chip_Light.csb"
    self:createCsbNode(resourceFilename)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
end

function LinkFishWinFrame:updateLeftCount(num)
    if self.m_respinNum == num and num == 3 then
        return
    end
    self.m_respinNum = num
    self:findChild("m_lb_num"):setString(num)    
    if num == 3 then
        gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_lightning_count_3.mp3") 
        self:runCsbAction("3show")        
    end
end


function LinkFishWinFrame:onEnter()
    self:runCsbAction("freespinum")
    -- body
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function LinkFishWinFrame:setFadeInAction()
    self.m_csbNode:runAction(cc.FadeIn:create(1))
end

---
-- 显示收集赢钱效果和数量
--
function LinkFishWinFrame:showCollectCoin(winCoin)

    self:runCsbAction("link_tip",false,function()
        self:runCsbAction("jiesuan",true)
    end)                    

    self:findChild("m_lb_coin"):setString(winCoin)

end


function LinkFishWinFrame:showCollectWin()
    self:runCsbAction("showin")
end


function LinkFishWinFrame:onExit()

end


return LinkFishWinFrame