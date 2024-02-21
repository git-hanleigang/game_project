local AliceRubyBonusMapBigLevel = class("AliceRubyBonusMapBigLevel", util_require("base.BaseView"))

local maxImgNum_3Reel = 15
local maxImgNum_4Reel = 20
AliceRubyBonusMapBigLevel.m_maxImgNum = 20

-- 构造函数
local DESCRIBE_LAYER_WIDTH = 212
function AliceRubyBonusMapBigLevel:initUI(data)

    self:createCsbNode("AliceRuby_Map_daguan.csb")

    self:initLockWild( data.info.fixPos )

    self:idle()
    
end

function AliceRubyBonusMapBigLevel:initLockWild( fixPos )
    
    for i=1,self.m_maxImgNum do
        local img = self:findChild("Alice_wild_img_" .. i - 1) 
        if img then
            img:setVisible(false)
        end
    end

    for i=1,#fixPos do
        local img = self:findChild("Alice_wild_img_" .. fixPos[i]) 
        if img then
            img:setVisible(true)
        end
    end

end

function AliceRubyBonusMapBigLevel:idle()
    self:runCsbAction("idle", true)
end

function AliceRubyBonusMapBigLevel:click(func,LitterGameWin)
    gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_mapBig_win.mp3")
    self:runCsbAction("actionframe", false, function()
        if func ~= nil then
            func()
        end
    end)
end



function AliceRubyBonusMapBigLevel:completed()
    self:runCsbAction("idle2")
end

function AliceRubyBonusMapBigLevel:onEnter()

end

function AliceRubyBonusMapBigLevel:onExit()

end

return AliceRubyBonusMapBigLevel