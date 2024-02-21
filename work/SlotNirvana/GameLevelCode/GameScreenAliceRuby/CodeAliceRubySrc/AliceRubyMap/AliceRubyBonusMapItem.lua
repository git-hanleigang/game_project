local AliceRubyBonusMapItem = class("AliceRubyBonusMapItem", util_require("base.BaseView"))
-- 构造函数
function AliceRubyBonusMapItem:initUI(data)
    local resourceFilename = "AliceRuby_Map_xiaoguan.csb"
    self:createCsbNode(resourceFilename)
end

function AliceRubyBonusMapItem:idle()
    self:runCsbAction("idle", true)
end

function AliceRubyBonusMapItem:showParticle()

end

function AliceRubyBonusMapItem:click(func,LitterGameWin)
    gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_mapSmall_win.mp3")
    self:findChild("m_lb_coin"):setString(util_formatCoins(LitterGameWin,3))
    self:runCsbAction("actionframe", false, function()
        if func then
            performWithDelay(self, function()
                if func ~= nil then
                    func()
                end
            end, 0.5)
        end
    end)
end

function AliceRubyBonusMapItem:completed()
    self:runCsbAction("idle2", true)
end

function AliceRubyBonusMapItem:onEnter()

end

function AliceRubyBonusMapItem:onExit()

end

return AliceRubyBonusMapItem