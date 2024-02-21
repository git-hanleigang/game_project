---
--island
--2018年6月5日
--GoldenPigWinFrame.lua

local GoldenPigWinFrame = class("GoldenPigWinFrame", util_require("base.BaseView"))

function GoldenPigWinFrame:initUI(data)

    local resourceFilename="GoldenPig_RespinTimes.csb"
    self:createCsbNode(resourceFilename)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
end

function GoldenPigWinFrame:updateLeftCount(num)
    if num == 0 then
        self:runCsbAction("lastspin_start")
    else
        if num == 1 then
            self:runCsbAction("spinsremaining2")
        end
        self:findChild("lab_respin_num"):setString(num)    
    end
    
    -- self:runCsbAction("spinsremaining")
    -- if num == 3 then
    --     gLobalSoundManager:playSound("GoldenPigSounds/music_GoldenPig_lightning_count_3.mp3") 
    --     self:runCsbAction("spinsremaining")        
    -- end
end


function GoldenPigWinFrame:onEnter()
    -- self:runCsbAction("freespinum")
    -- body
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function GoldenPigWinFrame:setFadeInAction()
    self:runCsbAction("spinsremaining_start")
end

function GoldenPigWinFrame:setFadeOutAction()
    self:runCsbAction("lastspin_over")
end

---
-- 显示收集赢钱效果和数量
--
function GoldenPigWinFrame:showCollectCoin(winCoin)

    self:runCsbAction("link_tip",false,function()
        self:runCsbAction("jiesuan",true)
    end)                    

    self:findChild("m_lb_coin"):setString(winCoin)

end


function GoldenPigWinFrame:showCollectWin()
    self:runCsbAction("showin")
end


function GoldenPigWinFrame:onExit()

end


return GoldenPigWinFrame