---
--island
--2017年8月28日
--Christmas2021GameMachineBG..lua

local Christmas2021GameMachineBG = class("Christmas2021GameMachineBG.", util_require("views.gameviews.GameMachineBG"))

Christmas2021GameMachineBG.m_ccbClassName = nil -- 
Christmas2021GameMachineBG.m_ccbNode = nil -- 
---
-- 初始化BG
-- @param moduleName string 模块名字
-- 
function Christmas2021GameMachineBG:initBgByModuleName(moduleName,isLoop)
    if not isLoop then
        isLoop= false
    end
    self.m_ccbClassName = string.format("GameScreen%sBg",moduleName)
    local resourceFilename=string.format("%s/GameScreen%sBg.csb",moduleName,moduleName)
    self:createCsbNode(resourceFilename,false)
    self:runCsbAction("normal", isLoop)   
end

return Christmas2021GameMachineBG