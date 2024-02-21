--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-05-09
--
local ShopItem = require "data.baseDatas.ShopItem"
local FindProcessAward = require "data.baseDatas.FindProcessAward"
local FindResult = class("FindResult")
FindResult.p_findNum = nil          --收集个数
FindResult.p_maxNum = nil           --最大收集个数
FindResult.p_roundFindNum = nil     --本轮收集个数
FindResult.p_roundMaxNum = nil      --本轮最大收集个数
FindResult.p_wellDoneCoins = nil    --welldone金币
FindResult.p_biggerCoins = nil      --本轮最大的奖励金币
FindResult.p_extraCoins = nil       --额外获得金币
FindResult.p_shopItems = nil        --本轮完成后获得的商品
FindResult.p_round = nil            --轮次
FindResult.p_processAward = nil     --达到某一个领奖进度

FindResult.p_newAndNum = 0           --本轮新增数量
function FindResult:ctor()

end

function FindResult:parseData(data)
      self.p_findNum = data.findNum
      self.p_maxNum = data.maxNum
      if self.p_roundFindNum ~= nil then
            self.p_newAndNum = data.roundFindNum -  self.p_roundFindNum
            if self.p_newAndNum < 0 then
                  self.p_newAndNum = 0
            end
      end
      self.p_roundFindNum = data.roundFindNum
      self.p_roundMaxNum = data.roundMaxNum
      self.p_wellDoneCoins = tonumber(data.wellDoneCoins)
      self.p_biggerCoins = tonumber(data.biggerCoins)
      self.p_extraCoins = tonumber(data.extraCoins)

      --本轮完成后获得的商品
      if data.shopItems ~= nil and data.shopItems ~= "" then
            local d = data.shopItems
            if d ~= nil and #d > 0 then
                  self.p_shopItems = {}
                  for i=1,#d do
                        local shopItem = ShopItem:create()
                        shopItem:parseData(d[i])
                        self.p_shopItems[#self.p_shopItems+1] = shopItem
                  end
            end
      end
      
      self.p_round = data.round

      if data.processAward ~= nil and data.processAward ~= "" then
            local d = data.processAward
            if d ~= nil and #d > 0 then
                  self.p_processAward = {}
                  for i=1,#d do
                        local processAwardItem = FindProcessAward:create()
                        processAwardItem:parseData(d[i])
                        self.p_processAward[#self.p_processAward+1] = processAwardItem
                  end
                  -- log日志
                  -- if #self.p_processAward > 0 then
                  --       self:handleProcessLog()
                  -- end
            end
      end
end

function FindResult:handleTaskRewardLog()
      local totalTaskCoins = self.p_wellDoneCoins + self.p_extraCoins
      gLobalSendDataManager:getLogFindActivity():sendFindAwardLog("TaskReward", {coins = totalTaskCoins})
end

function FindResult:handleProcessLog()
      if self.p_processAward and #self.p_processAward > 0 then
            for i=1,#self.p_processAward do
                  local fprocessAward = self.p_processAward[i]
                  if fprocessAward.p_collect then
                        local totalCoins = nil
                        local itemId = nil
                        local itemNum = nil
                        local itemType = nil
                        if fprocessAward.p_coins > 0 then
                              totalCoins = fprocessAward.p_coins
                        end
                        if fprocessAward.p_shopItems and #fprocessAward.p_shopItems > 0 then
                              itemId = fprocessAward.p_shopItems[1].p_id
                              itemNum = fprocessAward.p_shopItems[1].p_num
                              itemType = fprocessAward.p_shopItems[1].p_type
                        end
                        gLobalSendDataManager:getLogFindActivity():sendFindAwardLog("ReWard", {currentPro = fprocessAward.p_process, coins = totalCoins, id = itemId, num = itemNum, type = itemType})
                  end
            end
      end
end

return  FindResult