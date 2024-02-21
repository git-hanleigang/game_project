--[[
Author: cxc
Date: 2021-06-29 15:48:07
LastEditTime: 2021-07-01 21:23:50
LastEditors: Please set LastEditors
Description: 新手quest 轮播图
FilePath: /SlotNirvana/src/views/lobby/LevelNewUserPassSlideNode.lua
--]]
local LevelNewUserPassSlideNode = class("LevelNewUserPassSlideNode", BaseView)

function LevelNewUserPassSlideNode:initUI()
    self:createCsbNode("Icons/NewPassVegasNewSlide.csb")
    self:runCsbAction("idle", true, nil, 60)
end

--点击回调
function LevelNewUserPassSlideNode:MyclickFunc()
    self:clickLayer()
end

function LevelNewUserPassSlideNode:clickLayer(name)
    --gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "lobbyCarousel")
    performWithDelay(
        self,
        function()
            gLobalSendDataManager:getLogQuestNewUserActivity():sendQuestEntrySite("lobbyCarousel")
            G_GetMgr(ACTIVITY_REF.NewPass):showLoadingView()
        end,
        0.2
    )
end

return LevelNewUserPassSlideNode
