
local GoldenGhostFreeSpinStart = class("GoldenGhostFreeSpinStart", util_require("base.BaseView"))

function GoldenGhostFreeSpinStart:initUI()
    self:createCsbNode("GoldenGhost/FreeSpinStart.csb")
    self:runCsbAction("start",false,function ( ... )
        -- body
        self:runCsbAction("idle",true)
        -- self.touch = self:findChild("touch")
        -- self:addClick(self.touch)
    end)
    self.startBtn = self:findChild("Button_1")
    self:addClick(self.startBtn)
end

function GoldenGhostFreeSpinStart:updateUI()
    performWithDelay(self,function ( ... )
        -- body
        self:clickFunc()
    end,2)
end

function GoldenGhostFreeSpinStart:setExtraInfo(machine, callBack)
    self.m_machine = machine
    self.callBack = callBack
    -- self:updateUI()
end

function GoldenGhostFreeSpinStart:clickFunc(sender)
    if sender == self.startBtn then
        self.startBtn:setEnabled(false)
        -- sender:setEnabled(false)
        self:runCsbAction("over",false,function ( ... )
            -- body
            if self.callBack ~= nil then
                self.callBack(0)
            end
            self:removeFromParent()
        end)
    end
end

return GoldenGhostFreeSpinStart