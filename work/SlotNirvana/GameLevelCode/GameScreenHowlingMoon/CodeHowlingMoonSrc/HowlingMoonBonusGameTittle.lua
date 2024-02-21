---
--xhkj
--2018年6月11日
--HowlingMoonBonusGameTittle.lua

local HowlingMoonBonusGameTittle = class("HowlingMoonBonusGameTittle", util_require("base.BaseView"))

function HowlingMoonBonusGameTittle:initUI(data)

    local resourceFilename="Socre_HowlingMoon_FreeGame.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("actionframe")
    
    -- self.m_particle = self:findChild("Particle_1")
    -- self.m_particle1 = self:findChild("Particle_1_0")
    -- self.m_particle:setPositionType(1)
    -- self.m_particle1:setPositionType(1)

end


function HowlingMoonBonusGameTittle:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)


    gLobalNoticManager:addObserver(self,function(params,num)  -- 改变 freespin count显示
        self:changeFreeSpinByCountOutLine(params,num)
    end,ViewEventType.CHANGE_OUTLINE_FREE_SPIN_NUM)

    -- body
   util_setCascadeOpacityEnabledRescursion(self,true)
end

---
-- 重连更新freespin 剩余次数
--
function HowlingMoonBonusGameTittle:changeFreeSpinByCountOutLine(params,changeNum)
    if changeNum and type(changeNum) == "number" then
        if globalData.slotRunData.totalFreeSpinCount == changeNum then
            return
        end
        local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount - changeNum
        local totalFsCount = globalData.slotRunData.totalFreeSpinCount
        self:updateFreespinCount(leftFsCount,totalFsCount)
    end
end

---
-- 更新freespin 剩余次数
--
function HowlingMoonBonusGameTittle:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示respin剩余次数
function HowlingMoonBonusGameTittle:updataRespinTimes( curtimes ,isfirst)
    if curtimes == 3  then
        if not isfirst then
            gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_spin_respin_to3.mp3")
        end
        self:toAction(false)
    elseif curtimes == 2 then
        self:norAction(false)
    elseif curtimes == 1 then
        self:norAction(false)
    elseif curtimes == 0 then
        self:lastAction(false)
    end
    self:updateTimes( curtimes )
    self:findChild("BitmapFontLabel_1"):setString("RESPIN REMAINING")
    self:findChild("BitmapFontLabel_1"):setPositionX(17)
    
end
-- 更新并显示FreeSpin剩余次数
function HowlingMoonBonusGameTittle:updateFreespinCount( curtimes,totaltimes )
    
    self:norAction(false)
    if curtimes == totaltimes then
       --  self:lastAction(false)
    end
    self:updateTimes( "" )
    local totalnum =  totaltimes or ""
    local curnum =  curtimes or ""
    self:findChild("BitmapFontLabel_1"):setString(curnum.."  OF  "..totalnum.."  FREE SPINS")
    self:findChild("BitmapFontLabel_1"):setPositionX(0)
    
end

function HowlingMoonBonusGameTittle:updateTimes( curtimes )
    
    --self:updateLabelSize({label=self:findChild("lab_cur_time"),sx=0.8,sy=0.8},590)
    
    
    self:findChild("lab_cur_time"):setString(curtimes)

end

function HowlingMoonBonusGameTittle:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function HowlingMoonBonusGameTittle:initMachine(machine)
    self.m_machine = machine
end

function HowlingMoonBonusGameTittle:toAction( isloop,func )
    self:runCsbAction("actionframe",isloop,func)
end

-- 普通计数状态
function HowlingMoonBonusGameTittle:norAction( isloop,func )
    self:runCsbAction("animation0",isloop,func)
end

-- 最后一次计数状态
function HowlingMoonBonusGameTittle:lastAction(isloop,func )
    self:runCsbAction("animation1",isloop,func)   
end

-- 完成状态
function HowlingMoonBonusGameTittle:overAction(isloop,func )
    self:runCsbAction("animation2",isloop,func)   
end

return HowlingMoonBonusGameTittle