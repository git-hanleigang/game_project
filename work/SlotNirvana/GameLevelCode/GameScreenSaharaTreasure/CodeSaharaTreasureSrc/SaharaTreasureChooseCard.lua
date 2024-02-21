---
--xcyy
--2018年5月23日
--SaharaTreasureChooseCard.lua

local SaharaTreasureChooseCard = class("SaharaTreasureChooseCard",util_require("base.BaseView"))


function SaharaTreasureChooseCard:initUI(data)

    self:createCsbNode("SaharaTreasure_ka.csb")

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
    self.m_collectNum = 0
    local index = 1
    while true do
        local card = self:findChild("ka"..index)
        if card ~= nil then
            if index ~= data then
                card:setVisible(false)
            end
        else
            break
        end
        index = index + 1
    end

end

function SaharaTreasureChooseCard:collectAnim(func)
    self.m_collectNum = self.m_collectNum + 1
    local diamond = util_createView("CodeSaharaTreasureSrc.SaharaTreasureChooseDiamond")
    local parent = self:findChild("zuan"..self.m_collectNum)
    parent:addChild(diamond)
    diamond:runAnimation("fankui", false, function()
        if func ~= nil then
            func()
        end
    end)
    if self.m_collectNum == 2 then
        self:runCsbAction("yugao", true)
    end
end

function SaharaTreasureChooseCard:collectOver(isChoose)
    if isChoose == true then
        self:runCsbAction("idleframe")
    else
        self:runCsbAction("yahei")
    end
    
end

function SaharaTreasureChooseCard:onEnter()

end

function SaharaTreasureChooseCard:onExit()
 
end

--默认按钮监听回调
function SaharaTreasureChooseCard:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return SaharaTreasureChooseCard