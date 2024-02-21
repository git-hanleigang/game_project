---
--island
--2018年4月12日
--PiggyLegendTreasureFreeBossGuoChangView.lua
local PiggyLegendTreasureFreeBossGuoChangView = class("PiggyLegendTreasureFreeBossGuoChangView", util_require("Levels.BaseLevelDialog"))


function PiggyLegendTreasureFreeBossGuoChangView:initUI(data)
    
    local resourceFilename = "PiggyLegendTreasure/BossGuoChang.csb"
    self:createCsbNode(resourceFilename)

    self.boss2GuoChang = util_spineCreate("Socre_PiggyLegendTreasure_boss2", true, true) 
    self:findChild("Node_2"):addChild(self.boss2GuoChang)

    self:initViewData()
end

function PiggyLegendTreasureFreeBossGuoChangView:initViewData()
    
    util_spinePlay(self.boss2GuoChang,"buling",false)
    
end

function PiggyLegendTreasureFreeBossGuoChangView:closeSpineView()
    performWithDelay(self,function()      -- 下一帧 remove spine 不然会崩溃
        self:removeFromParent()
    end,0.0)
end

function PiggyLegendTreasureFreeBossGuoChangView:onEnter()

    PiggyLegendTreasureFreeBossGuoChangView.super.onEnter(self)
end

function PiggyLegendTreasureFreeBossGuoChangView:onExit()

    PiggyLegendTreasureFreeBossGuoChangView.super.onExit(self)

end

return PiggyLegendTreasureFreeBossGuoChangView

