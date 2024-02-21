---
--xcyy
--2018年5月23日
--MayanMysteryRespinMulBar.lua
local MayanMysteryRespinMulBar = class("MayanMysteryRespinMulBar",util_require("base.BaseView"))

local RESPIN_TOTALNUM = 5
function MayanMysteryRespinMulBar:initUI()

    self:createCsbNode("MayanMystery_respin_mul_bar.csb")
    self:runCsbAction("idle", true)
    self:reset()
end

function MayanMysteryRespinMulBar:reset()
    self._bdeffes = {}
    for index = 1, 5 do
        local spin = self:findChild(tostring(index))
        spin:setVisible(false)
    
        local spine = util_createAnimation("MayanMystery_respin_mul_bar_tx.csb")
        self:findChild("Node_tx0"..index):addChild(spine)
        spine:setVisible(false)

        self._bdeffes[index] = spine
    end
    self._lastCount = 0
end
  
function MayanMysteryRespinMulBar:onEnter()
end

function MayanMysteryRespinMulBar:onExit()
end
  
function MayanMysteryRespinMulBar:updataRespinCount(_count, _isPlay)
    if _count > 5 then
        _count = 5
    end
    for index = 1, 5 do
        local spin = self:findChild(tostring(index))
        spin:setVisible(index == _count)
    end

    if _count > 0 and _isPlay then
        self._bdeffes[_count]:setVisible(true)
        self._bdeffes[_count]:runCsbAction("actionframe", false, function()
            self._bdeffes[_count]:setVisible(false)
        end)
    end
end
  

return MayanMysteryRespinMulBar