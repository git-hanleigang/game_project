local StarryXmasBonusMapBigLevel = class("StarryXmasBonusMapBigLevel", util_require("base.BaseView"))

local maxImgNum_3Reel = 15
local maxImgNum_4Reel = 20
StarryXmasBonusMapBigLevel.m_maxImgNum = 20

-- 构造函数
local DESCRIBE_LAYER_WIDTH = 212
function StarryXmasBonusMapBigLevel:initUI(data)

    self:createCsbNode("StarryXmas_daguan.csb")

    self:initLockWild( data.info.fixPos )

    self:idle()

    self:findChild("m_lb_num_0"):setString(data.info.triggerTimes)
    
end

function StarryXmasBonusMapBigLevel:initLockWild( fixPos )
    
    for i=1,self.m_maxImgNum do
        local img = self:findChild("wild_img_" .. i - 1) 
        if img then
            img:setVisible(false)
        end
    end

    for i=1,#fixPos do
        local img = self:findChild("wild_img_" .. fixPos[i]) 
        if img then
            img:setVisible(true)
        end
    end

end

function StarryXmasBonusMapBigLevel:idle()
    self:runCsbAction("idleframe", true)
end

function StarryXmasBonusMapBigLevel:idle1()
    self:runCsbAction("idleframe1", true)
end

function StarryXmasBonusMapBigLevel:click(func,LitterGameWin)

    self:runCsbAction("actionframe", false, function()
        if func ~= nil then
            func()
        end
    end)
end



function StarryXmasBonusMapBigLevel:completed()
    self:runCsbAction("idle")
end

function StarryXmasBonusMapBigLevel:onEnter()

end

function StarryXmasBonusMapBigLevel:onExit()

end

return StarryXmasBonusMapBigLevel