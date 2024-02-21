---
--xcyy
--2018年5月23日
--WallballReelBall.lua

local WallballReelBall = class("WallballReelBall",util_require("base.BaseView"))

local BALL_NAME = 
{
    replaceSignal777 = "Wallball_board_add3str_1.csb",
    replaceSignal77 = "Wallball_board_add2str_1.csb",
    multiple = "Wallball_board_multiwins_1.csb",
    wholeColumn = "Wallball_board_wildstack_1.csb",
    Grand = "Wallball_board_Grand_1.csb",
    Minor = "Wallball_board_Minor_1.csb",
    Major = "Wallball_board_Major_1.csb",
    addFreeSpin = "Wallball_board_2spin_1.csb"
}

function WallballReelBall:initUI(data)

    self:createCsbNode(BALL_NAME[data])

    -- self:runCsbAction("actionframe", true) -- 播放时间线
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
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idleframe", true) -- 播放时间线
    end) 
end

function WallballReelBall:changeAim(func)
    self:runCsbAction("over", false, function()
        if func ~= nil then
            func()
        end
        self:removeFromParent() -- 播放时间线
    end) 
end

function WallballReelBall:onEnter()

end

function WallballReelBall:onExit()
 
end

function WallballReelBall:setMultipNum(num)
    self:findChild("labMultip"):setString(num.."x")
end

function WallballReelBall:showIdle()
    self:runCsbAction("idle1")
end

--默认按钮监听回调
function WallballReelBall:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return WallballReelBall