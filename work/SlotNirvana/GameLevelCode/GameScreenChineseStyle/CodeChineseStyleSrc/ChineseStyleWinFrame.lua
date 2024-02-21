---
--island
--2018年6月5日
--ChineseStyleWinFrame.lua

local ChineseStyleWinFrame = class("ChineseStyleWinFrame", util_require("base.BaseView"))

function ChineseStyleWinFrame:initUI(data)

    local resourceFilename="Socre_ChineseStyle_Chip_Light.csb"
    self:createCsbNode(resourceFilename)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
end

function ChineseStyleWinFrame:updateLeftCount(num)
    self:findChild("m_lb_num"):setString(num)    
    if num == 3 then
        gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_lightning_count_3.mp3") 
        self:runCsbAction("3show")        
    end
end


function ChineseStyleWinFrame:onEnter()
    self:runCsbAction("freespinum")
    -- body
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function ChineseStyleWinFrame:setFadeInAction()
    self.m_csbNode:runAction(cc.FadeIn:create(1))
end

---
-- 显示收集赢钱效果和数量
--
function ChineseStyleWinFrame:showCollectCoin(winCoin)

    self:runCsbAction("jiesuan")        
    self:findChild("m_lb_coin"):setString(winCoin)

end


--
--
--
function ChineseStyleWinFrame:showCollectWin()
    self:runCsbAction("showin")
end


function ChineseStyleWinFrame:onExit()

end


return ChineseStyleWinFrame