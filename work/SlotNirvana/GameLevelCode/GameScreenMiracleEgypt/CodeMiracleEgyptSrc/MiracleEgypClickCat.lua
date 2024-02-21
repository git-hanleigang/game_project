--
-- 猫点击
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgypClickCat = class("MiracleEgypClickCat", util_require("base.BaseView"))

function MiracleEgypClickCat:initUI( machine )

    self:createCsbNode("Spine_clickcat.csb")

    self.m_machine = machine

    self:addClick(self:findChild("catBtn"))
end

--结束监听
function MiracleEgypClickCat:clickEndFunc(sender)

    if sender then
        local name = sender:getName()
        if name == "catBtn" then

            -- gLobalSoundManager:playSound("MiracleEgyptSounds/MiracleEgypt_BlackCat_Click.mp3")
            

            if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                -- local betCoin = self.m_machine:getBetCpins()
                -- if betCoin >= self.m_machine.m_BetChooseGear then
                --     print("啥也不干")
                -- else
                    print("弹框")
                    self.m_machine:handleBetChoseView(1,nil )
                    
                -- end
            end
            
        end
    end
end

return  MiracleEgypClickCat