---
--xcyy
--2018年5月23日
--AliceMagicHat.lua

local AliceMagicHat = class("AliceMagicHat",util_require("base.BaseView"))

local SYMBOL_IMAGE_NAME = 
{
    "#Symbol/Alice_H1_x.png",
    "#Symbol/Alice_H2_x.png",
    "#Symbol/Alice_H3_x.png",
    "#Symbol/Alice_M1_x.png",
    "#Symbol/Alice_M2_x.png",
    "#Symbol/Alice_M3_x.png",
    "#Symbol/Alice_M4_x.png",
    "#Symbol/Alice_L1_x.png",
    "#Symbol/Alice_L2_x.png",
    "#Symbol/Alice_L3_x.png",
    "#Symbol/Alice_L4_x.png"
}
function AliceMagicHat:initUI()

    self:createCsbNode("Alice_Wild_maozi.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
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
    -- self:runCsbAction("idleframe")
end


function AliceMagicHat:onEnter()
 
    
end

function AliceMagicHat:showMagicAnimation(index, callback)
    local frame = display.newSpriteFrame(SYMBOL_IMAGE_NAME[index + 1])
    if frame then
        self:findChild("result"):setSpriteFrame(frame)
    end

    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("over", false, function()
            self:runCsbAction("idleframe", true)
        end)
        if callback ~= nil then
            callback()
        end
    end)
    
end

function AliceMagicHat:hideSymbol(callback)
    -- self:runCsbAction("over", false, function()
        if callback ~= nil then
            callback()
        end
    -- end)
end

function AliceMagicHat:onExit()
 
end



return AliceMagicHat