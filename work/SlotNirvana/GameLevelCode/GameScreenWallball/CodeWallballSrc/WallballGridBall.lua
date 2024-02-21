---
--xcyy
--2018年5月23日
--WallballGridBall.lua

local WallballGridBall = class("WallballGridBall",util_require("base.BaseView"))


function WallballGridBall:initUI(data)

    self:createCsbNode(data)
    self.isMultis = false
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self:showIdle()
end

function WallballGridBall:showIdle()
    self:runCsbAction("idle") -- 播放时间线
end

function WallballGridBall:crashAnim(mutiples)
    if self.isMultis then
        gLobalSoundManager:playSound("WallballSounds/sound_Wallball_multiple.mp3")
        self:findChild("labMultip"):setString(mutiples.."x")
        
        self:runCsbAction("actionframe", false,function()
            self:runCsbAction("idle2", true)
        end) -- 播放时间线
        performWithDelay(self,function()
            gLobalSoundManager:playSound("WallballSounds/sound_Wallball_switch_multiple.mp3")
        end,1)
    else
        self:runCsbAction("actionframe", true) -- 播放时间线
    end
    
end

function WallballGridBall:onEnter()

end

function WallballGridBall:onExit()
 
end

return WallballGridBall