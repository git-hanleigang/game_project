---
--xcyy
--2018年5月23日
--FishManiaFishToyView.lua

local FishManiaFishToyView = class("FishManiaFishToyView",util_require("base.BaseView"))

FishManiaFishToyView.m_viewId       = nil

function FishManiaFishToyView:initUI(_viewId,_machine)

    self.m_viewId       = _viewId
    self.m_machine      = _machine
    self.m_fishItemId   = globalMachineController.p_fishManiaPlayConfig.FishItemId

    self:createCsbNode("FishToy/FishMania_wu".. _viewId .. ".csb")

    self.m_fishToys = {}
end
function FishManiaFishToyView:initFishToys()
    if # self.m_fishToys > 0 then
        return
    end

    local prefixStr = ""
    if self.m_viewId ~= self.m_fishItemId.CustomId then
        -- 初始化非自定义鱼缸
        prefixStr = "node_"
    else
        -- 初始化自定义鱼缸
        prefixStr = "yugang_3_"
    end
    
    local p_shopData = globalMachineController.p_fishManiaShopData
    local allPageData = p_shopData:getshopPageData( )
    local pageData = p_shopData:getShopDataByIndex(self.m_viewId) or {}
    local maxCount = #pageData

    for commodityIndex=1,maxCount do

        local parNode = self:findChild(string.format("%s%d", prefixStr, commodityIndex)) 
        if parNode then
            local commodityId = p_shopData:getCommodityId(self.m_viewId, commodityIndex)
            local commodityType = string.format("%d", commodityId-1)
            local pos = cc.p(parNode:getPosition())
            local initData = {
                machine = self.m_machine,
                shopIndex = self.m_viewId,
                commodityIndex = commodityIndex,
                commodityId = commodityId,
                startPos = pos,
            }
            local fishToy = util_createView("CodeFishManiaSrc.ShopFishToy.FishManiaFishToy",initData)
            self:addChild(fishToy)
            fishToy:upDateOrder()

            self.m_fishToys[commodityIndex] = fishToy
        end

    end
end


function FishManiaFishToyView:onExit()
    gLobalNoticManager:removeAllObservers(self)
    FishManiaFishToyView.super.onExit(self)
end


function FishManiaFishToyView:upDateFishToyVisible()
    local p_shopData = globalMachineController.p_fishManiaShopData
    -- local shopData = p_shopData:getShopDataByIndex(self.m_viewId)

    local isBuy = false
    for _index,_fishToy in pairs(self.m_fishToys) do
        local state = p_shopData:getCommodityState(self.m_viewId, _fishToy.m_initData.commodityId)

        _fishToy:setVisible(1==state)
        --更新装饰品的移动状态
        if 1==state then
            _fishToy:playFishToyMoveAction()
        else
            _fishToy:clearHandler()
        end

    end
end

return FishManiaFishToyView