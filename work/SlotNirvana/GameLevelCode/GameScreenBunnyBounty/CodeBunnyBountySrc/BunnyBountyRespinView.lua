---
--xcyy
--2018年5月23日
--BunnyBountyRespinView.lua
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyRespinView = class("BunnyBountyRespinView",util_require("Levels.BaseReel.BaseRespinView"))

function BunnyBountyRespinView:ctor(params)
    BunnyBountyRespinView.super.ctor(self,params)
end

--[[
    设置respinNode是否显示
]]
function BunnyBountyRespinView:setRespinNodeShow(isShow)

    for index,respinNode in pairs(self.m_respinNodes) do
        respinNode:setSymbolShow(isShow)
    end
end

--[[
    单格停止
]]
function BunnyBountyRespinView:runNodeEnd(symbolNode,info)
    BunnyBountyRespinView.super.runNodeEnd(self,symbolNode,info)
end

--[[
    播放图标落地音效
]]
function BunnyBountyRespinView:playSymbolDownSound(symbolType)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_link2_down)
end

---获取所有参与结算节点
function BunnyBountyRespinView:getAllCleaningNode()

    --从 从上到下 左到右(respinNodes默认的排序本身就是如此,按顺序依次取出来就好了)
    local cleaningNodes = {}
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode:getLockSymbolNode()
        if symbolNode and symbolNode.p_symbolType and self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
            cleaningNodes[#cleaningNodes + 1] = symbolNode
        end
    end
    return cleaningNodes
end

return BunnyBountyRespinView