---
--xcyy
--2018年5月23日
--AZTECJackpotBonusIcon.lua

local AZTECJackpotBonusIcon = class("AZTECJackpotBonusIcon",util_require("base.BaseView"))

local ALL_JACKPOT_ARRAY = {"Mini", "Minor", "Major", "Maxi", "Grand"}
function AZTECJackpotBonusIcon:initUI(data)

    self:createCsbNode("AZTEC_jackpot_jinbi.csb")

    self:runCsbAction("idle") -- 播放时间线
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
    for i = 1, #ALL_JACKPOT_ARRAY, 1 do
        if data ~= ALL_JACKPOT_ARRAY[i] then
            self:findChild("Node_"..ALL_JACKPOT_ARRAY[i]):setVisible(false)
        end
    end
end

function AZTECJackpotBonusIcon:showIdle(index)
    self:runCsbAction("idle"..index) 
end

function AZTECJackpotBonusIcon:showAnimation(index)
    self:runCsbAction("actionframe"..index) 
end

function AZTECJackpotBonusIcon:showGrayIdle()
    self:runCsbAction("idleLast") 
end

function AZTECJackpotBonusIcon:onEnter()
 
end

function AZTECJackpotBonusIcon:onExit()
 
end


return AZTECJackpotBonusIcon