---
--xcyy
--2018年5月23日
--CleosCoffersView.lua
local PublicConfig = require "CleosCoffersPublicConfig"
local CleosCoffersView = class("CleosCoffersView",util_require("Levels.BaseLevelDialog"))


function CleosCoffersView:initUI()

    self:createCsbNode("xxxx/xxxxxxx.csb")

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

end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CleosCoffersView:initSpineUI()
    
end




return CleosCoffersView