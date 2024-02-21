---
--island
--2017年8月28日
--CodeGameScreenJungleKingpinMachineBg.lua

local CodeGameScreenJungleKingpinMachineBg = class("CodeGameScreenJungleKingpinMachineBg", util_require("views.gameviews.GameMachineBG"))

CodeGameScreenJungleKingpinMachineBg.m_ccbClassName = nil --
CodeGameScreenJungleKingpinMachineBg.m_ccbNode = nil --
---
-- 初始化BG
-- @param moduleName string 模块名字
--
function CodeGameScreenJungleKingpinMachineBg:initBgByModuleName(moduleName, isLoop)
    if not isLoop then
        isLoop = false
    end
    self.m_ccbClassName = string.format("GameScreen%sBg", moduleName)
    local resourceFilename = string.format("%s/GameScreen%sBg.csb", moduleName, moduleName)
    self:createCsbNode(resourceFilename, true)
    self:runCsbAction("normal", isLoop)
end

function CodeGameScreenJungleKingpinMachineBg:getUIScalePro()
    return 0.5
end

function CodeGameScreenJungleKingpinMachineBg:onEnter()
    -- body
    printInfo("xcyy : %s", "CodeGameScreenJungleKingpinMachineBg:onEnter")
    gLobalNoticManager:addObserver(
        self,
        function(MainClass, params, isForver, func)
            self:changeBGAnim(params)
        end,
        ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG
    )

    gLobalNoticManager:addObserver(
        self,
        function(MainClass, params)
            MainClass:setVisible(false)
        end,
        ViewEventType.NOTIFY_ENTER_BONUS_GAME
    )

    gLobalNoticManager:addObserver(
        self,
        function(MainClass, params)
            MainClass:setVisible(true)
        end,
        ViewEventType.NOTIFY_EXIT_BONUS_GAME
    )
end
--
function CodeGameScreenJungleKingpinMachineBg:changeBGAnim(params)
    if type(params) == "string" then
        self:runCsbAction(params)
    elseif type(params) == "table" then
        self:runCsbAction(params[1], params[2], params[3])
    end
end

function CodeGameScreenJungleKingpinMachineBg:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return CodeGameScreenJungleKingpinMachineBg
