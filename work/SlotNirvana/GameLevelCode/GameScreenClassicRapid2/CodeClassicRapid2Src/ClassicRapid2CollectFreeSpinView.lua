---
--xcyy
--2018年5月23日
--ClassicRapid2CollectFreeSpinView.lua

local ClassicRapid2CollectFreeSpinView = class("ClassicRapid2CollectFreeSpinView",util_require("base.BaseView"))
ClassicRapid2CollectFreeSpinView.m_machine = nil

function ClassicRapid2CollectFreeSpinView:initUI()

    self:createCsbNode("ClassicRapid2_jindu.csb")
    self:runCsbAction("idle",true)
    self:initLittleNode()
    self:addClick(self:findChild("btn1"))
end

function ClassicRapid2CollectFreeSpinView:hideTip()
    if self.m_isClick then
        self.m_isClick = false
        self:runCsbAction("over",false,function()
            if not self.m_isClick then
                self:runCsbAction("idle",true)
            end
        end)
    end
end
function ClassicRapid2CollectFreeSpinView:clickFunc(sender)
    if self.m_isClick then
        self.m_isClick = false
        self:runCsbAction("over",false,function()
            if not self.m_isClick then
                self:runCsbAction("idle",true)
            end
        end)
    else
        gLobalSoundManager:playSound("ClassicRapid2Sounds/sound_classicRapid_click_bonusBar2.mp3")
        self.m_isClick = true
        self:runCsbAction("start",false,function()
            if self.m_isClick then
                self:runCsbAction("idle2",true)
            end
        end)
    end
end

function ClassicRapid2CollectFreeSpinView:onEnter()


end

function ClassicRapid2CollectFreeSpinView:onExit()

end

function ClassicRapid2CollectFreeSpinView:initMachine(machine)
    self.m_machine = machine
end

function ClassicRapid2CollectFreeSpinView:initLittleNode(  )
    for i=1,10 do
        local node = self:findChild("jinku"..i)
        local barname = "littleView"..i
        self[barname] = util_createView("CodeClassicRapid2Src.ClassicRapid2CollectLittleView",i)
        node:addChild(self[barname])
        -- self[barname]:runCsbAction("hide")
        self[barname]:setVisible(false)
    end
end

function ClassicRapid2CollectFreeSpinView:updateOneLittleNode( index,isAdd)
    local barname = "littleView"..index
    if self[barname] then
        -- self[barname]:runCsbAction("show")
        -- self[barname]:setVisible(true)
        self[barname]:playShowAnimation(isAdd)
    end
end


function ClassicRapid2CollectFreeSpinView:hideAllLittleNode( )
    for i=1,10 do
        local barname = "littleView"..i
        if self[barname] then
            self[barname]:setVisible(false)
        end
    end
end
-- ClassicRapid2CollectFreeSpinView.m_curSpinCount = 0
function ClassicRapid2CollectFreeSpinView:updateBarVisible(isAdd)

    if self.m_machine == nil then
        return
    end

    local selfMakeData =  self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfMakeData then

        local freeSpinCount = selfMakeData.freeSpinCount
        -- if self.m_curSpinCount ~= freeSpinCount then

            if freeSpinCount and freeSpinCount > 0 then
                if isAdd then
                    self:updateOneLittleNode(freeSpinCount,isAdd)
                else
                    for i=1,10 do
                        if i <= freeSpinCount then
                            self:updateOneLittleNode(i)
                        end
                    end
                end

            end
        -- end
    end

end



return ClassicRapid2CollectFreeSpinView