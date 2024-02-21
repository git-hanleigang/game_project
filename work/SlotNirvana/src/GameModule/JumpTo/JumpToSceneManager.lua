--[[
Author: cxc
Date: 2022-03-25 17:08:10
LastEditTime: 2022-03-25 17:08:12
LastEditors: cxc
Description: 跳转功能 场景 mgr
FilePath: /SlotNirvana/src/GameModule/JumpTo/JumpToSceneManager.lua
--]]
local JumpToSceneManager = class("JumpToSceneManager")
-- if GD.SceneType = {
--     Scene_Logon = 1, -- 登录
--     Scene_Lobby = 2, -- 大厅
--     Scene_Game = 3, -- 游戏 slots
--     Scene_Quest = 4,
--     Scene_LAUNCH = 5, -- 进入大厅或游戏时的 loading 界面
--     Scene_CoinPusher = 6 -- CoinPusher场景
-- }
function JumpToSceneManager:jumpToFeature(_info, _params)
    if not _info then
        return
    end

    local subType = _info[2]
    if gLobalViewManager:getCurSceneType() == subType then
        return
    end

    -- gLobalViewManager:gotoSceneByType(subType)
end

return JumpToSceneManager
