---
--island
--2018年6月5日
--CrazyBombWinFrame.lua

local CrazyBombWinFrame = class("CrazyBombWinFrame", util_require("base.BaseView"))

function CrazyBombWinFrame:initUI(data)

    local resourceFilename="CrazyBomb/CrazyBomb_RespinTimes.csb"
    self:createCsbNode(resourceFilename)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)
end

function CrazyBombWinFrame:updateLeftCount(num)
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
    --     gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_lightning_count_3.mp3") 
    --     self:runCsbAction("spinsremaining")        
    -- end
end


function CrazyBombWinFrame:onEnter()
    -- self:runCsbAction("freespinum")
    -- body
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function CrazyBombWinFrame:setFadeInAction()
    self:runCsbAction("spinsremaining_start")
end

function CrazyBombWinFrame:setFadeOutAction()
    self:runCsbAction("lastspin_over")
end

---
-- 显示收集赢钱效果和数量
--
function CrazyBombWinFrame:showCollectCoin(winCoin)

    self:runCsbAction("link_tip",false,function()
        self:runCsbAction("jiesuan",true)
    end)                    

    self:findChild("m_lb_coin"):setString(winCoin)

end


function CrazyBombWinFrame:showCollectWin()
    self:runCsbAction("showin")
end


function CrazyBombWinFrame:onExit()

end


return CrazyBombWinFrame