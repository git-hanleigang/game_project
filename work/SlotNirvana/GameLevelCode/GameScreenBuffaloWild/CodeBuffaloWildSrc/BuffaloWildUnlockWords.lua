---
--xcyy
--2018年5月23日
--BuffaloWildUnlockWords.lua

local BuffaloWildUnlockWords = class("BuffaloWildUnlockWords",util_require("base.BaseView"))


function BuffaloWildUnlockWords:initUI(data)

    self:createCsbNode("BuffaloWild_bonus_FreeGames_1.csb")

    self:runCsbAction("idle") -- 播放时间线
    self:findChild("wheel_num"):setString(data.wheelNum) 
    self:findChild("collect_num"):setString(data.collectNum)
end


function BuffaloWildUnlockWords:onEnter()
 

end

function BuffaloWildUnlockWords:onExit()
 
end

return BuffaloWildUnlockWords