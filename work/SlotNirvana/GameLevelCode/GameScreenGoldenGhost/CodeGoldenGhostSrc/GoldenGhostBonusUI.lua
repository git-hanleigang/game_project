local GoldenGhostBonusUI = class("GoldenGhostBonusUI", util_require("base.BaseView"))

local CodeGameScreenGoldenGhostMachine = util_require("CodeGameScreenGoldenGhostMachine")

function GoldenGhostBonusUI:onExit()
    
end

function GoldenGhostBonusUI:initUI()
    self.selectedFlag = false

    self:createCsbNode("GoldenGhost_Choose2.csb")
    -- 改为用spine表现，将spine挂在到cocos内
    self.m_spine = util_spineCreate("GoldenGhost_Choose2",true,true)
    self:findChild("Node_1"):addChild(self.m_spine)

    self.btnBonus = self:findChild("btnBonus")
    self.btnFreeGames = self:findChild("btnFreeGames")

    self:runCsbAction(
        "start",
        false,
        function()
            if not self.selectedFlag then
                self:runCsbAction("idle", true)
                self:setButtonEnabled(true)
            end
        end
    )

    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
    gLobalSoundManager:playSound(levelConfig.Sound_Bonus_Select_Start)


    util_spinePlay(self.m_spine, "start", false)
    util_spineEndCallFunc( self.m_spine,"start",function()
        if not self.selectedFlag then
            util_spinePlay(self.m_spine, "idle", true)

        end
    end)
end

function GoldenGhostBonusUI:setExtraInfo(machine, callBack)
    self.m_machine = machine
    self.callBack = callBack
    self:updateUI()
end

function GoldenGhostBonusUI:updateUI()

end

function GoldenGhostBonusUI:setButtonEnabled(flag)
    self.btnBonus:setEnabled(flag)
    self.btnFreeGames:setEnabled(flag)
end

function GoldenGhostBonusUI:clickFunc(sender)
    local name = sender:getName()

    local actionIndex = name == "btnBonus" and 1 or 2
    local actionName = string.format("actionframe%d", actionIndex)
    local idleName = string.format("idle%d", actionIndex)

    if name == "btnBonus" then
        self.selectedFlag = true
        self:setButtonEnabled(false)

        -- self:runCsbAction("actionframe1",false,
        -- function()
        --         if self.callBack ~= nil then
        --             self.callBack(1)
        --         end
        -- end)
        
        
        util_spinePlay(self.m_spine, actionName, false)
        util_spineEndCallFunc( self.m_spine,actionName,function()
            util_spinePlay(self.m_spine, idleName, true)

            if self.callBack ~= nil then
                self.callBack(1)
            end
        end)
    elseif name == "btnFreeGames" then
        self.selectedFlag = true
        self:setButtonEnabled(false)

        -- self:runCsbAction("actionframe2",false,
        -- function()
        --     if self.callBack ~= nil then
        --         self.callBack(0)
        --     end
        -- end)

        util_spinePlay(self.m_spine, actionName, false)
        util_spineEndCallFunc( self.m_spine, actionName,function()
            util_spinePlay(self.m_spine, idleName, true)

            if self.callBack ~= nil then
                self.callBack(0)
            end
        end)
    end

    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
    gLobalSoundManager:playSound(levelConfig.Sound_Bonus_Select_Click)
end

function GoldenGhostBonusUI:playCloseAnim()
    self:removeFromParent()
end


return GoldenGhostBonusUI
