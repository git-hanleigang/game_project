---
--xcyy
--2018年5月23日
--BeerGirlCollectTimesBarView.lua

local BeerGirlCollectTimesBarView = class("BeerGirlCollectTimesBarView",util_require("base.BaseView"))


function BeerGirlCollectTimesBarView:initUI()

    self:createCsbNode("BeerGirl_tishi.csb")

    self:runCsbAction("idleframe") -- 播放时间线

    self:updateTimes("0","10")

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


function BeerGirlCollectTimesBarView:onEnter()
 

end

function BeerGirlCollectTimesBarView:updateTimes(leftTimes,totalTimes)
    
    if leftTimes == 10 then
        self:runCsbAction("idleframe1",false,function (  )
            self.m_csbOwner["BitmapFontLabel_1"]:setString(leftTimes)
            self.m_csbOwner["BitmapFontLabel_1_0"]:setString(totalTimes)
            self:runCsbAction("actionframe")
        end)
    else
        self.m_csbOwner["BitmapFontLabel_1"]:setString(leftTimes)
        self.m_csbOwner["BitmapFontLabel_1_0"]:setString(totalTimes)
        self:runCsbAction("actionframe")
    end
    
end

function BeerGirlCollectTimesBarView:onExit()
 
end

--默认按钮监听回调
function BeerGirlCollectTimesBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return BeerGirlCollectTimesBarView