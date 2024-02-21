---
--xcyy
--2018年5月23日
--CandyBingoLittleBetView.lua

local CandyBingoLittleBetView = class("CandyBingoLittleBetView",util_require("base.BaseView"))


function CandyBingoLittleBetView:initUI()

    self:createCsbNode("CandyBingo_BetView5.csb")
    
    

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


function CandyBingoLittleBetView:onEnter()
 

end

function CandyBingoLittleBetView:updateScatterImg(level )

    local lizi = self:findChild("bet_lizi")
    if lizi then
        lizi:resetSystem()
    end
    

    self:runCsbAction("bet_tanchu")

    if level == 0 then
        self:findChild("scatter_1"):setVisible(true)
        self:findChild("scatter_2"):setVisible(false)
        self:findChild("scatter_3"):setVisible(false)
        self:findChild("BitmapFontLabel_1"):setString("6-18")
        
    elseif level == 1 then
        self:findChild("scatter_1"):setVisible(false)
        self:findChild("scatter_2"):setVisible(true)
        self:findChild("scatter_3"):setVisible(false)
        self:findChild("BitmapFontLabel_1"):setString("8-24")
    else
        self:findChild("scatter_1"):setVisible(false)
        self:findChild("scatter_2"):setVisible(false)
        self:findChild("scatter_3"):setVisible(true)
        self:findChild("BitmapFontLabel_1"):setString("10-30")
    end
end

function CandyBingoLittleBetView:onExit()
 
end



return CandyBingoLittleBetView