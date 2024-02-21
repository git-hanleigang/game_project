---
--Cocos2dx 相关的所有工具函数
--ios fix
--递归暂停传入节点
function GD.util_pause_node_recursion(node)
    node:pause()
    local children = node:getChildren()
    for k, v in pairs(children) do
        util_pause_node_recursion(v)
    end
end

---
--递归恢复暂停，传入节点
function GD.util_resume_node_recursion(node)
    node:resume()
    local children = node:getChildren()
    for k, v in pairs(children) do
        util_resume_node_recursion(v)
    end
end

---
--将节点屏幕居中
function GD.util_centerNode(node)
    node:setPosition(display.width * 0.5, display.height * 0.5)
end

---
--创建WinSize大小的RenderTexture
function GD.util_createRenderTextureScreen()
    return cc.RenderTexture:create(display.width, display.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, 35056)
end

function GD.util_setCascadeOpacityEnabledRescursion(node, enabled)
    node:setCascadeOpacityEnabled(enabled)
    local childs = node:getChildren()
    for i = 1, #childs do
        util_setCascadeOpacityEnabledRescursion(childs[i], enabled)
    end
end

function GD.util_setCascadeColorEnabledRescursion(node, enabled)
    node:setCascadeColorEnabled(enabled)
    local childs = node:getChildren()
    for i = 1, #childs do
        util_setCascadeColorEnabledRescursion(childs[i], enabled)
    end
end

function GD.util_setChildNodeOpacity(node, opacity)
    node:setOpacity(opacity)
    for k, v in ipairs(node:getChildren()) do
        util_setChildNodeOpacity(v, opacity)
    end
end

function GD.util_nodeFadeIn(node, time, starOpacity, endOpacity, t, callBack)
    t = t or {}
    local opacity = endOpacity or node:getOpacity()
    t[node] = opacity
    node:setOpacity(math.floor(starOpacity or 0))
    local actionList = {cc.FadeTo:create(time, opacity)}
    if callBack ~= nil then
        table.insert(actionList, cc.CallFunc:create(callBack))
    end
    node:runAction(cc.Sequence:create(actionList))
    for k, v in ipairs(node:getChildren()) do
        util_nodeFadeIn(v, time, starOpacity, endOpacity, t, nil)
    end
end

---
--获取动画
--@param fileName string 文件名共同前缀
--@param isTwoNumber bool false:后缀名从1开始，例如 LoadingIcon1.png  true:后缀从01开始，例如 LoadingIcon01.png
--@param frames int 总帧数
--@param start int 起始帧  不传递默认是1
--@param frameRate int 帧频（默认1./24）
function GD.util_getAnimation(fileName, isTwoNumber, frames, start, frameRate)
    local anim = cc.Animation:create()

    start = start or 1

    for i = 0, frames - 1 do
        if start + i > frames then
            break
        end

        local fullFileName = nil
        if isTwoNumber then
            fullFileName = string.format("%s%02d.png", fileName, start + i)
        else
            fullFileName = string.format("%s%d.png", fileName, start + i)
        end

        --        local spframe = cc.SpriteFrameCache:getInstance():getSpriteFrame(fullFileName )  -- 用这种方式比较严格的要求资源必须提前加载
        anim:addSpriteFrameWithFile(fullFileName)
    end
    if frameRate == nil then
        frameRate = 1. / 24
    end
    anim:setDelayPerUnit(frameRate)
    anim:setRestoreOriginalFrame(true)

    return anim
end

-- num 传入一个数字
-- return 这关数是多少位数
function GD.util_Places(num, count)
    if count == nil then
        count = 1
    end
    num = math.floor(num / 10)
    if num > 0 then
        count = count + 1
        count = util_Places(num, count)
    end
    return count
end

-- 针对超过T单位很多大数的封装
-- 显示规则以T为基础单位顺延: 1KT 1BTT 1TTT ... 
-- obligateF:小数保留位数
-- _coinsParms:参数太多，第一位可以传表，以对象的方式传输；或者以之前的规则（直接传金币）都可以
function GD.util_formatCoinsLN(_coinsParms, _obligate, notCut, normal, noRounding, useRealObligate, keepRoundType, obligateF)
    local obligate = tonumber(_obligate or 50)
    local coins
    if type(_coinsParms) == "table" and not iskindof(_coinsParms, "LongNumber") then
        coins = _coinsParms.coins
        obligate = _coinsParms.obligate
        notCut = _coinsParms.notCut
        normal = _coinsParms.normal
        noRounding = _coinsParms.noRounding
        useRealObligate = _coinsParms.useRealObligate
        keepRoundType = _coinsParms.keepRoundType
        obligateF = _coinsParms.obligateF
    else
        coins = _coinsParms
    end

    local lNum = toLongNumber(coins)
    local lstr = tostring(lNum)
    local strLen = string.len(lstr)

    if strLen <= obligate then
        lstr = util_formatCoins(lstr,obligate, notCut, normal, noRounding, useRealObligate, keepRoundType)
    else
        local limit_N = 3
        local index_N = 0
        while true do
            if strLen > obligate  then
                index_N = index_N + 1
                local charStr = string.sub(lstr,1,strLen - limit_N)
                lstr = charStr
                strLen = string.len(lstr) 
            else
                break
            end 
        end
        local realStr = util_formatCoins(lstr,obligate, notCut, normal, noRounding, useRealObligate, keepRoundType)

        -- 小数点后的位数
        if strLen < obligate and obligateF and obligateF > 0 then
            local tempStr = tostring(lNum)
            local pointStr = string.sub(tempStr,strLen+1,strLen + obligateF)
            local pointNum = tonumber(pointStr)
            if pointNum > 0 then
                realStr = realStr .. "." .. pointStr
            end
        end
        
        local unitList = {"K","M","B","T"}
        local unitStr = ""
        local unitLevel = 0
        local unitCureList = {}
        local index = 1
        for i=1,index_N do
            if index > #unitList then
                index = 1
            end
            if index == 1 and not unitCureList[#unitCureList + 1] then
                unitCureList[#unitCureList + 1] = {}
            end
            table.insert(unitCureList[#unitCureList],unitList[index]) 
            index = index + 1
        end

        for i=1,#unitCureList do
            unitStr = unitCureList[i][#unitCureList[i]] .. unitStr 
        end
        lstr = realStr .. unitStr
    end

    return lstr
end

--[[
    将文字转化为竖向显示
]]
function GD:formatVerticalCoins(coinsStr)
    local len = string.len(coinsStr)
    local str = ""
    --将文字转换为纵向显示
    for index = 1,len do
        local char = string.sub(coinsStr,index,index)
        str = str..char.."\n"
    end
    return str
end

-- util_formatCoins(数值,限制大小,是否添加分隔符','}
-- obligate:保留位数 限制大小  notCut=true（不添加分隔符','）
-- noRounding:不四舍五入
-- 向下取整0.99等于0
--useRealObligate:是否真实使用截取字符串，一些关卡显示目前会默认保留1位小数，但是任务描述显示缺少一位数值
-- util_formatCoins(999999.99,2)      输出结果 = 0.9M    --限制2位数
-- util_formatCoins(999999.99,4)      输出结果 = 999.9K  --限制4位数
-- util_formatCoins(999999.99,6)      输出结果 = 999,999 --限制6位数
-- util_formatCoins(999999.99,6,true) 输出结果 = 999999  --不添加分隔符
-- util_formatCoins(999999.99,7)      输出结果 = 999,999 --限制7位数

function GD.util_formatCoins(coins, obligate, notCut, normal, noRounding, useRealObligate, keepRoundType, _isSupportUnitQ, _unitStr)
    local obK = math.pow(10, 3)
    -- if type(coins) ~= "number" and (not iskindof(coins, "LongNumber")) then
    --     return coins
    -- end
    if coins == nil then
        -- util_sendToSplunkMsg("coinsError", "formatCoins error!!!!")
        return ""
    end
    if type(coins) == "string" or iskindof(coins, "LongNumber") then
        -- 判断是否存在 ','和'.'，有则是已经格式化好的
        coins = "" .. coins
        local s, e = string.find(coins, '[$,.KMBTQ]')
        if coins == "" or s then
            return coins
        end
    end

    coins = toLongNumber(coins)

    -- 未指定限制位数 显示全部（50够长了）
    if (tonumber(obligate) or 0)  == 0 then
        obligate = 50
    end

    --是否添加分割符
    local isCut = true
    if notCut then
        isCut = false
    end

    _unitStr = _unitStr or ""

    local str_coins = nil
    -- coins = tonumber(coins + 0.01)
    -- local nCoins = math.floor(coins)
    -- local count = math.floor(math.log10(nCoins)) + 1
    -- release_print("formatCoins:" .. tostring(coins))
    local _temp = string.format("%.3f", "" .. coins)
    local _tb = string.split(_temp, ".")
    local nCoins = _tb[1]
    local count = string.len(nCoins)
    if count <= obligate then
        str_coins = util_cutCoins(nCoins, isCut, nil, noRounding, keepRoundType)
    else
        if count < 3 then
            str_coins = util_cutCoins(nCoins / obK, isCut, nil, noRounding, keepRoundType) .. _unitStr .. "K"
        else
            local tCoins = nCoins
            local tNum = 0
            local units = {"K", "M", "B", "T"}
            if _isSupportUnitQ then
                units = {"K", "M", "B", "T", "Q"}
            end
            local cell = 1000
            local index = 0
            while (1) do
                index = index + 1
                if index > #units then
                    return util_cutCoins(tCoins, isCut, nil, noRounding, keepRoundType) .. _unitStr .. units[#units]
                end
                tNum = tCoins % cell
                tCoins = tCoins / cell
                local num = math.floor(math.log10(tCoins)) + 1
                if num <= obligate then
                    --应该保留的小数位
                    local floatNum = obligate - num
                    if normal then
                        return util_cutCoins(tCoins, isCut, floatNum, noRounding, keepRoundType) .. _unitStr .. units[index]
                    end
                    if not useRealObligate then
                        --保留1位小数
                        if num == 1 and floatNum > 0 then
                            floatNum = 1
                        else
                            --正常模式不保留小数
                            floatNum = 0
                        end
                    end
                    return util_cutCoins(tCoins, isCut, floatNum, noRounding, keepRoundType) .. _unitStr .. units[index]
                end
            end
        end
    end
    return str_coins
end
-- 这个方法是个有问题的方法  不要用
-- util_formatCoins(数值,限制大小,是否添加分隔符','}
-- obligate:保留位数 限制大小  notCut=true（不添加分隔符','）
-- noRounding:不四舍五入
-- 向下取整0.99等于0
-- util_formatCoins(999999.99,2)      输出结果 = 0.9M    --限制2位数
-- util_formatCoins(999999.99,4)      输出结果 = 999.9K  --限制4位数
-- util_formatCoins(999999.99,6)      输出结果 = 999,999 --限制6位数
-- util_formatCoins(999999.99,6,true) 输出结果 = 999999  --不添加分隔符
-- util_formatCoins(999999.99,7)      输出结果 = 999,999 --限制7位数
function GD.util_formatCoins_Extend(coins, obligate, notCut, normal, noRounding, roundType)
    local obK = math.pow(10, 3)
    if type(coins) ~= "number" then
        return coins
    end
    --不需要限制的直接返回
    if obligate < 1 then
        return coins
    end
    local roundInner = function(num)
        if not roundType then
            return num
        end
        local str = num .. ""
        local strList = util_string_split(str, ".")
        if #strList > 1 then
            local temp = tonumber(strList[2]) / 10
            local nextValue = 0
            if roundType == 0 then -- 四舍五入
                nextValue = math.round(temp)
            elseif roundType == 1 then -- 向上取整
                nextValue = math.ceil(temp)
            elseif roundType == 2 then -- 向下取整
                nextValue = math.floor(temp)
            end
            return tonumber(strList[1]) + nextValue
        end
        return tonumber(strList[1])
    end

    --是否添加分割符
    local isCut = true
    if notCut then
        isCut = false
    end

    local str_coins = nil
    coins = tonumber(coins + 0.00001)
    local nCoins = math.floor(coins)
    local count = math.floor(math.log10(nCoins)) + 1
    if count <= obligate then
        str_coins = util_cutCoins(nCoins, isCut, nil, noRounding)
    else
        if count < 3 then
            str_coins = util_cutCoins(nCoins / obK, isCut, nil, noRounding) .. "K"
        else
            local tCoins = nCoins
            local tNum = 0
            local units = {"K", "M", "B", "T"}
            local cell = 1000
            local index = 0
            while (1) do
                index = index + 1
                if index > 4 then
                    return roundInner(util_cutCoins(tCoins, isCut, nil, noRounding)) .. units[4]
                end
                tNum = tCoins % cell
                tCoins = tCoins / cell
                local num = math.floor(math.log10(tCoins)) + 1
                if num <= obligate then
                    --应该保留的小数位
                    local floatNum = obligate - num
                    if normal then
                        return roundInner(util_cutCoins(tCoins, isCut, floatNum, noRounding)) .. units[index]
                    end
                    --保留1位小数
                    if num == 1 and floatNum > 0 then
                        floatNum = 1
                    else
                        --正常模式不保留小数
                        floatNum = 0
                    end
                    return roundInner(util_cutCoins(tCoins, isCut, floatNum, noRounding)) .. units[index]
                end
            end
        end
    end
    return str_coins
end

--兼容老版本
function GD.util_coinsLimitLen(coins, obligate, notCut)
    return util_formatCoins(coins, obligate, notCut)
end

-- obligateF:小数保留位数
-- noRounding: 不四舍五入 xx
function GD.util_cutCoins(coins, isCut, obligateF, noRounding, keepRoundType)
    -- coins = toLongNumber(coins)
    local _temp = string.format("%f", coins)
    local _tb = string.split(_temp, ".")
    -- local nCoins = math.floor(coins)
    local nCoins = toLongNumber(_tb[1]) - 0
    local fCoins = coins - nCoins
    local strF = ""
    -- 计算小数预留位
    if obligateF and obligateF ~= 0 then
        fCoins = util_keepFloatNum(fCoins, obligateF, noRounding, keepRoundType)
        -- nCoins = math.floor(nCoins + fCoins + 0.000001)
        nCoins = nCoins + math.floor(fCoins + 0.000001)
        strF = string.sub(fCoins .. "", 2, 2 + obligateF)
    end
    if not isCut then
        return nCoins .. strF
    end
    -- 添加分隔符
    if false then
        local count = math.floor(math.log10(nCoins)) + 1
        local obK = math.pow(10, 3)
        local obM = math.pow(10, 6)
        local obG = math.pow(10, 9)
        local obT = math.pow(10, 12)
        if count <= 3 then
            return nCoins .. strF
        elseif count <= 6 then
            local s1 = math.floor(nCoins / obK)
            local s2 = nCoins % obK
            return string.format("%d,%03d%s", s1, s2, strF)
        elseif count <= 9 then
            local s1 = math.floor(nCoins / obM) % obK
            local s2 = math.floor(nCoins / obK) % obK
            local s3 = math.floor(nCoins) % obK
            return string.format("%d,%03d,%03d%s", s1, s2, s3, strF)
        elseif count <= 12 then
            local s1 = math.floor(nCoins / obG) % obK
            local s2 = math.floor(nCoins / obM) % obK
            local s3 = math.floor(nCoins / obK) % obK
            local s4 = math.floor(nCoins) % obK
            return string.format("%d,%03d,%03d,%03d%s", s1, s2, s3, s4, strF)
        else
            local s1 = math.floor(nCoins / obT)
            local s2 = math.floor(nCoins / obG) % obK
            local s3 = math.floor(nCoins / obM) % obK
            local s4 = math.floor(nCoins / obK) % obK
            local s5 = math.floor(nCoins) % obK

            return string.format("%s,%03d,%03d,%03d,%03d%s", util_formatMoneyStr(s1), s2, s3, s4, s5, strF)
        end
    else
        local strCoins = "" .. nCoins
        local len = string.len(strCoins)
        local count = math.ceil(len / 3)
        local strTotal = string.format("%s", strF)
        for i = 1, count do
            local idx = i * 3
            if i < count then
                local _s = (len - i*3)
                local _e = (len - (i-1)*3)
                local _str = string.sub(strCoins, _s+1, _e)
                local temp = string.format(",%03d", _str)
                strTotal = temp .. strTotal
            else
                local _e = (len - (i-1)*3)
                local _str = string.sub(strCoins, 1, _e)
                -- local temp = string.format("%d", _str)
                local temp = ""
                local ok, value = pcall(
                    function()
                        return string.format("%d", _str)
                    end
                )
                if ok then
                    temp = value
                else
                    util_sendToSplunkMsg("LongNumber", "LongNumber error!!value:"..tostring(value).."\n|_str:" .. tostring(_str) .. "|_e:" .. tostring(_e) .. "|strCoins:"..tostring(strCoins))
                end
                strTotal = temp .. strTotal
            end
        end
        return strTotal
    end
end

--小数保留位数
function GD.util_keepFloatNum(value, num, noRounding, keepRoundType)
    local pow = math.pow(10, num)
    local offsetVal = 0.0000001
    if keepRoundType == 0 then -- 四舍五入
        value = math.round((value * pow) + offsetVal) / pow
    elseif keepRoundType == 1 then -- 向上取整
        value = math.ceil((value * pow) + offsetVal) / pow
    else 
        -- 默认向下取整
        value = math.floor((value * pow) + offsetVal) / pow
    end
    return value
end
--清理光效
function GD.util_clearLight(node)
    if not node then
        return
    end
    if node._light then
        node._light:removeSelf()
        node._light = nil
    end
end
--添加光效 结点 闪烁速度  顺序
function GD.util_toLight(node, speed, zorder, delayTime)
    if not node then
        return
    end
    local data
    local fx
    local fy

    if tolua.type(node) == "sp.SkeletonAnimation" then
        return
    end
    if tolua.type(node) == "cc.Sprite" then
        data = node:getTexture()
        fx = node:isFlippedX()
        fy = node:isFlippedY()
    else
        print("tolua.type(node)=" .. tolua.type(node))
        local new_node = node:getVirtualRenderer()
        if new_node then
            local new_Sprite = new_node:getSprite()
            if new_Sprite then
                data = new_Sprite:getTexture()
                fx = new_Sprite:isFlippedX()
                fy = new_Sprite:isFlippedY()
            end
        end
    end
    if not data then
        return
    end
    if not zorder then
        zorder = 1
    end
    if not speed then
        speed = 1
    end
    if not delayTime then
        delayTime = 3
    end

    local sp_light = util_createSprite(data)
    sp_light:setBlendFunc({src = 770, dst = 1})
    node:addChild(sp_light, zorder)
    sp_light:setFlippedX(fx)
    sp_light:setFlippedY(fy)
    sp_light:setPosition(node:getContentSize().width / 2, node:getContentSize().height / 2)
    sp_light:setOpacity(0)
    local seq = cc.Sequence:create(cc.DelayTime:create(delayTime), cc.FadeIn:create(speed), cc.FadeOut:create(speed))
    local req = cc.RepeatForever:create(seq)
    sp_light:runAction(req)
    node._light = sp_light
end

function GD.util_loadPlistFile(plistFileName)
    if plistFileName == nil or plistFileName == "" then
        return
    end
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames(plistFileName)
end

--图片裁切加动画流光node底图 clippath 裁切区域  animateNode流光动画
function GD.util_Animateflash(node, clipPath, animateNode, maskScale)
    local clip_node = cc.ClippingNode:create()
    local mask = util_createSprite(clipPath)
    if maskScale and maskScale > 0 then
        mask:setScale(maskScale)
    end
    clip_node:setAlphaThreshold(0)
    clip_node:setStencil(mask)
    node:addChild(clip_node)
    local w, h = node:getContentSize().width / 2, node:getContentSize().height / 2
    -- clip_node:setPosition(100,200)
    clip_node:addChild(animateNode)
    --animateNode:setPosition(0,30)
    return clip_node
end

--图片加流光
--baseSprite需要加流光的底图    clipSprite裁切显示区域图片最好是纯色
--flashSprite扫光图片,         delayLoopTime 循环间隔时间
--例子
-- local mask = display.newSprite("testMask.png")
-- local flash = display.newSprite("testflash.png")
-- util_flash(self.m_testSprite,mask,flash)
function GD.util_flash(baseSprite, clipSprite, flashSprite, delayLoopTime)
    if not baseSprite then
        return
    end
    if not delayLoopTime then
        delayLoopTime = 1
    end

    local clip_node = cc.ClippingNode:create()
    clip_node:setAlphaThreshold(0.9)
    clip_node:setStencil(clipSprite)
    baseSprite:addChild(clip_node)

    local w, h = baseSprite:getContentSize().width * 0.5, baseSprite:getContentSize().height * 0.5
    clip_node:setPosition(w, h)
    clip_node:addChild(flashSprite)

    flashSprite:setPosition(-w * 3, 0)
    -- flashSprite:setBlendFunc(770,1)

    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(3, cc.p(w * 3, 0))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            flashSprite:setPosition(-w * 3, -h * 3)
        end
    )
    actionList[#actionList + 1] = cc.DelayTime:create(delayLoopTime)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            flashSprite:setPosition(-w * 3, 0)
        end
    )
    local seq = cc.Sequence:create(actionList)
    flashSprite:runAction(cc.RepeatForever:create(seq))

    return clip_node
end

--layer设置touch
local Layer = cc.LayerColor
function Layer:onTouch(callback, isMultiTouches, swallowTouches)
    if type(isMultiTouches) ~= "boolean" then
        isMultiTouches = false
    end
    if type(swallowTouches) ~= "boolean" then
        swallowTouches = false
    end

    self:registerScriptTouchHandler(
        function(state, ...)
            local args = {...}
            local event = {name = state}
            if isMultiTouches then
                args = args[1]
                local points = {}
                for i = 1, #args, 3 do
                    local x, y, id = args[i], args[i + 1], args[i + 2]
                    points[id] = {x = x, y = y, id = id}
                end
                event.points = points
            else
                event.x = args[1]
                event.y = args[2]
            end
            return callback(event)
        end,
        isMultiTouches,
        0,
        swallowTouches
    )
    self:setTouchEnabled(true)
    return self
end
--遮罩layer
function GD.util_newMaskLayer(isTouch)
    local layer = cc.LayerColor:create(cc.c3b(0, 0, 0), display.width, display.height)
    layer:setOpacity(190)
    layer:setScale(15)
    if not isTouch then
        layer:onTouch(
            function()
                return true
            end,
            false,
            true
        )
    end
    return layer
end

---
-- 根据背景宽度对显示金币的label 进行缩放，
--
function GD.util_scaleCoinLabGameLayerFromBgWidth(lab, bgWidth, scale) --256
    if scale == nil then
        scale = 1
    end
    local width = lab:getContentSize().width
    if width > bgWidth then
        scale = bgWidth / width * scale
    end

    if lab.mulNode then
        lab.mulNode:setScale(scale)
    else
        lab:setScale(scale)
    end

    return scale
end

--数字跳动 startValue初始值，endValue结束值,addValue增加值,spendTime跳动间隔时间吗，formatValueutil_formatCoins根据util_formatCoins格式化,char符号
--label._newNumValue=记录的num数值
function GD.util_jumpNum(label, startValue, endValue, addValue, spendTime, formatValue, char, endChar, callBack, perCallBack)
    util_jumpNumExtra(label, startValue, endValue, addValue, spendTime, util_formatCoins, formatValue, char, endChar, callBack, perCallBack)
end

--数字跳动 startValue初始值，endValue结束值,addValue增加值,spendTime跳动间隔时间吗，formatValueutil_formatCoins根据util_formatCoins格式化,char符号
--label._newNumValue=记录的num数值
function GD.util_jumpNumLN(label, startValue, endValue, addValue, spendTime, formatValue, char, endChar, callBack, perCallBack)
    util_jumpNumExtra(label, startValue, endValue, addValue, spendTime, util_formatCoinsLN, formatValue, char, endChar, callBack, perCallBack)
end

function GD.util_jumpNumExtra(label, startValue, endValue, addValue, spendTime, formatFunc, formatValue, char, endChar, callBack, perCallBack)
    if not label then
        return
    end
    label:unscheduleUpdate()

    local _cur = toLongNumber(0)
    _cur:setNum(startValue)
    local _tar = toLongNumber(0)
    _tar:setNum(endValue)
    local _add = toLongNumber(0)
    _add:setNum(addValue)
    local _now = toLongNumber(0)
    _now:setNum(startValue)

    spendTime = spendTime or 1/60

    if not char then
        char = ""
    end
    if not endChar then
        endChar = ""
    end
    formatFunc = formatFunc or util_formatCoins
    if formatValue then
        label._newNumValue = _now
        label:setString(char .. formatFunc(_now, formatValue[1], formatValue[2], formatValue[3]) .. endChar)
    else
        label._newNumValue = _now
        label:setString(char .. _now .. endChar)
    end

    if toLongNumber(_cur) >= toLongNumber(_tar) then
        if callBack then
            callBack()
        end
        return
    end

    local dtVal = toLongNumber(0)
    local iVal = toLongNumber(0)
    local function update(dt)
        if toLongNumber(_now) >= toLongNumber(_tar) then
            _now:setNum(_tar)
            label:unscheduleUpdate()
            if formatValue then
                label._newNumValue = _now
                label:setString(char .. formatFunc(_now, formatValue[1], formatValue[2], formatValue[3]) .. endChar)
            else
                label._newNumValue = _now
                label:setString(char .. _now .. endChar)
            end
            if callBack ~= nil then
                callBack()
            end
            return
        end
        local dtAdd = _add * (dt * 1000)
        dtVal:setNum(dtVal + (dtAdd * (1/spendTime))) -- 将除法改为乘法，LongNumber除以小数会变为0
        iVal:setNum(dtVal)
        dtVal:setNum(dtVal - iVal)

        -- 大数没有小数点，这里得保证必加最小单位1
        if toLongNumber(iVal / 1000) <= toLongNumber(0) then
            _now:setNum(_now + 1)
        else
            _now:setNum(_now + iVal / 1000)
        end
        if toLongNumber(_now) >= toLongNumber(_tar) then --处理滚动超过最大值的问题
            _now:setNum(_tar)
        end
        if formatValue then
            label._newNumValue = _now
            label:setString(char .. formatFunc(_now, formatValue[1], formatValue[2], formatValue[3]) .. endChar)
        else
            label._newNumValue = _now
            label:setString(char .. _now .. endChar)
        end
        if perCallBack ~= nil then
            perCallBack()
        end
    end
    label:onUpdate(update)
end

function GD.util_cutDownNum(label, startValue, endValue, addValue, spendTime, formatValue, char, endChar, callBack, perCallBack)
    if not label then
        return
    end
    label:unscheduleUpdate()
    local curValue = startValue

    if not char then
        char = ""
    end
    if not endChar then
        endChar = ""
    end
    if formatValue then
        label._newNumValue = curValue
        label:setString(char .. util_formatCoins(curValue, formatValue[1], formatValue[2], formatValue[3]) .. endChar)
    else
        label._newNumValue = curValue
        label:setString(char .. curValue .. endChar)
    end

    if startValue <= endValue then
        if callBack then
            callBack()
        end
        return
    end

    -- label._curTime=0
    local function update(dt)
        if curValue <= endValue then
            curValue = endValue
            label:unscheduleUpdate()
            if formatValue then
                label._newNumValue = curValue
                label:setString(char .. util_formatCoins(curValue, formatValue[1], formatValue[2], formatValue[3]) .. endChar)
            else
                label._newNumValue = curValue
                label:setString(char .. curValue .. endChar)
            end
            if callBack ~= nil then
                callBack()
            end
            return
        end
        -- label._curTime=label._curTime+dt
        -- if label._curTime >= spendTime then
        --     label._curTime=0
        curValue = curValue + addValue * dt / spendTime
        curValue = math.max(curValue, 0)
        if formatValue then
            label._newNumValue = curValue
            label:setString(char .. util_formatCoins(math.ceil(curValue), formatValue[1], formatValue[2], formatValue[3]) .. endChar)
        else
            label._newNumValue = curValue
            label:setString(char .. math.ceil(curValue) .. endChar)
        end
        if perCallBack ~= nil then
            perCallBack()
        end
    end
    label:onUpdate(update)
end

function GD.util_schedule(node, callback, delay)
    local delay = cc.DelayTime:create(delay)
    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
    local action = cc.RepeatForever:create(sequence)
    node:runAction(action)
    return action
end

function GD.util_performWithDelay(node, callback, delay)
    local delay = cc.DelayTime:create(delay)
    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
    node:runAction(sequence)
    return sequence
end
--下一帧执行方法
function GD.util_nextFrameFunc(callback, delayTime)
    if not delayTime then
        delayTime = 0
    end
    local scheduler = cc.Director:getInstance():getScheduler()
    local schedulerID = nil
    schedulerID =
        scheduler:scheduleScriptFunc(
        function()
            scheduler:unscheduleScriptEntry(schedulerID)
            if callback then
                callback()
            end
        end,
        delayTime,
        false
    )
end

--[[
    @desc: 调用继承父类的函数，这个可以用在自定义类继承了cocos 类之后使用，
    例如重写了setVisible 函数
    time:2019-04-02 15:34:46
    --@table:
	--@methodName:
    @return:
]]
function GD.util_getSuperMethod(table, methodName)
    local mt = getmetatable(table)
    local method = nil
    while mt and not method do
        method = mt[methodName]
        if not method then
            local index = mt.__index
            if index and type(index) == "function" then
                method = index(mt, methodName)
            elseif index and type(index) == "table" then
                method = index[methodName]
            end
        end
        mt = getmetatable(mt)
    end
    return method
end

--------spine
local ResCacheMgr = nil
--[[
    @desc: 创建spine动画
    @path:spine路径
	@isBlend:是否混合
	@isBinary:是否二进制文件
	@cleanType: 清理方式 1:退出系统后清理| 2:移除后自动清理
    @return:
]]
function GD.util_spineCreate(path, isBlend, isBinary, cleanType)
    release_print("util_spineCreate = " .. tostring(path))
    local _spine = util_createSpine(path, path, isBlend, isBinary, cleanType)
    if _spine then
        release_print("util_spineCreate END path=" .. path)
    end
    return _spine
end

function GD.util_createSpine(skel, atlas, isBlend, isBinary, cleanType)
    cleanType = cleanType or 0

    local ok, spNode =
        pcall(
        function()
            local _spNode
            local _pathAtlas =  tostring(atlas) .. ".atlas"
            if isBinary then
                _spNode = sp.SkeletonAnimation:createWithBinaryFile(skel .. ".skel", _pathAtlas)
            else
                _spNode = sp.SkeletonAnimation:create(skel .. ".json", _pathAtlas)
            end
            return _spNode
        end
    )
    if not ok then
        local sendErrMsg = string.format('util_spineCreate - load resouce node from file failed!! skel:%s, atlas:%s', skel, atlas)
        -- assert(spNode, sendErrMsg)
        __G__TRACKBACK__(sendErrMsg)
        return nil
    end

    if isBlend then
        spNode:setBlendFunc({src = 770, dst = 1})
    end
    if not ResCacheMgr then
        ResCacheMgr = require("GameInit.ResCacheMgr.ResCacheMgr")
    end
    if cleanType == 1 or cleanType == 2 then
        -- 添加到资源管理器中
        ResCacheMgr:getInstance():insertSpineInfo(atlas, skel, isBinary) 

        spNode:registerScriptHandler(
            function(eventType)
                if eventType == "cleanup" then
                    if cleanType == 1 or cleanType == 2 then
                        -- 处理引用计数
                        ResCacheMgr:getInstance():removeRes(atlas)
                    end

                    if cleanType == 2 then
                        util_nextFrameFunc(
                            function()
                                -- remove 后就清理
                                ResCacheMgr:getInstance():cleanupRes(atlas)
                            end
                        )
                    end
                end
            end
        )
    end
    return spNode
end

-- spine连续播放
function GD.util_spineAddPlay(spNode, key, isLoop)
    if not spNode then
        return
    end
    spNode:addAnimation(0, key, isLoop)
end

--spine动作混合
function GD.util_spineMix(spNode, key1, key2, time)
    if not spNode then
        return
    end
    --设置动画混合，第一个参数是 当前动画，第二参数是下一个动画，第三个参数是从当前动画过度到下一个动画所需时间
    spNode:setMix(key1, key2, time)
end

function GD.util_spineCreateDifferentPath(filePath, pngPath, isBlend, isBinary, cleanType)
    release_print("util_spineCreateDifferentPath = " .. tostring(filePath))
    if pngPath == "nil" or pngPath == nil then
        pngPath = filePath
    end
    local _spine = util_createSpine(filePath, pngPath, isBlend, isBinary, cleanType)
    if _spine then
        release_print("util_spineCreateDifferentPath END path="..filePath)
    end
    return _spine
end

-- spine 帧事件
function GD.util_spineFrameEvent(spNode, actkey, eventname, func)
    if not spNode then
        return
    end

    spNode:registerSpineEventHandler(
        function(event) --通过registerSpineEventHandler这个方法注册
            if event.animation == actkey then --根据动作名来区分
                if event.eventData.name == eventname then --根据帧事件来区分
                    if func then
                        func()
                    end
                end
            end
        end,
        sp.EventType.ANIMATION_EVENT
    )
end

-- spine 帧事件
function GD.util_spineFrameEventAndRemove(spNode, actkey, eventname, func)
    if not spNode then
        return
    end

    spNode:registerSpineEventHandler(
        function(event) --通过registerSpineEventHandler这个方法注册
            if event.animation == actkey then --根据动作名来区分
                spNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
                if event.eventData.name == eventname then --根据帧事件来区分
                    if func then
                        func()
                    end
                end
            end
        end,
        sp.EventType.ANIMATION_EVENT
    )
end

--[[
    @desc: 重置spine播放状态
]]
function GD.util_spineResetAnim( _spineNode )
    _spineNode:resetAnimation()
end

-- 播放spine 动画 --
function GD.util_spinePlayAction(spNode, key, isLoop,func)
    util_spinePlay(spNode, key, isLoop)
    if func then
        util_spineEndCallFunc(spNode, key,func)
    end
end

function GD.util_spinePlay(spNode, key, isLoop)
    if not spNode then
        return
    end
    spNode:setAnimation(0, key, isLoop)
end

--[[
    播放spine动作后移除spine
]]
function GD.util_spinePlayAndRemove(spNode,key,func)
    if tolua.isnull(spNode) then
        return 0
    end

    util_spinePlay(spNode,key)
    util_spineEndCallFunc(spNode,key,function()
        if type(func) == "function" then
            func()
        end
        if not tolua.isnull(spNode) then
            spNode:setVisible(false)
            performWithDelay(spNode,function()
                if not tolua.isnull(spNode) then
                    spNode:removeFromParent()
                end
            end,0.1)
        end
    end)

    local aniTime = spNode:getAnimationDurationTime(key)
    return aniTime
end

function GD.util_spineSetUpdateFlag(spNode, flag)
    if spNode ~= nil then
        local platform = device.platform
        if platform == "ios" or platform == "mac" then
            if util_isSupportVersion("1.7.4") then
                spNode:setUpdateFlag(flag)
            end
        elseif platform == "android" then
            if util_isSupportVersion("1.6.6") then
                spNode:setUpdateFlag(flag)
            end
        end
    end
end

function GD.util_spineGetUpdateFlag(spNode)
    local flag = true
    if spNode ~= nil then
        local platform = device.platform
        if platform == "ios" or platform == "mac" then
            if util_isSupportVersion("1.7.4") then
                flag = spNode:getUpdateFlag()
            end
        elseif platform == "android" then
            if util_isSupportVersion("1.6.6") then
                flag = spNode:getUpdateFlag()
            end
        end
    end
    return flag
end

function GD.util_spineEndCallFunc(spNode, key, func)
    if not spNode then
        return
    end
    spNode:registerSpineEventHandler(
        function(event)
            if event.animation == key then
                spNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
                if func then
                    func()
                end
            end
        end,
        sp.EventType.ANIMATION_COMPLETE
    )
end

function GD.util_spineFrameCallFunc(spNode, key, frameKey, func, funcEnd)
    if not spNode then
        return
    end
    spNode:registerSpineEventHandler(
        function(event)
            if event.eventData.name == frameKey then
                spNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
                if func then
                    func()
                end
            end
        end,
        sp.EventType.ANIMATION_EVENT
    )

    if funcEnd ~= nil then
        util_spineEndCallFunc(spNode, key, funcEnd)
    end
end

--绑定Spine骨骼节点
function GD.util_spinePushBindNode(spNode, slotName, bindNode)
    local _parent = bindNode:getParent()
    local isRetain = false
    if not tolua.isnull(_parent) then
        bindNode:retain()
        bindNode:removeFromParent(false)
        isRetain = true
    end

    if device.platform == "android" then
        if util_isSupportVersion("1.6.0") then
            bindNode.removeFromParent = function()
                print("spine绑定不需要处理remove")
            end
        end
    elseif device.platform == "ios" then
        if util_isSupportVersion("1.6.8") then
            bindNode.removeFromParent = function()
                print("spine绑定不需要处理remove")
            end
        end
    end
    spNode:pushBindNode(slotName, bindNode)
    if isRetain then
        bindNode:release()
    end
end

--  spine挂载
--  思路：获得骨骼的位置实时刷新targetNode来达到节点跟随，
--  _targetNode: 可以是Spine也可以是Node
--  _parentSp: 必须是spine
function GD.util_bindNode(_parentSp,_boneName, _targetNode,_order,_tag,_updateRot)
    if not util_isSupportVersion("1.8.8", "ios") and not util_isSupportVersion("1.8.3", "android") and not util_isSupportVersion("1.8.0", "mac") then
        return
    end

    local parentSp ,targetNode,actionId,updateRot = _parentSp,_targetNode,nil,_updateRot

    local stopDt = function(_dTNode,_updateNode,_actionId)
        if tolua.isnull(_updateNode) or not _updateNode:getParent() then
            _dTNode:stopAction(_actionId)
            return true
        end
        if not tolua.isnull(_dTNode) and not _dTNode:getParent() then
            _dTNode:stopAction(_actionId)
            return true
        end
    end

    local setTarNodeInfo = function()
        local slotInfo =  parentSp:findBone(_boneName)
        local pos = cc.p(slotInfo.X ,slotInfo.Y)
        targetNode:setPosition(cc.p(pos.x ,pos.y))
        targetNode:setScaleX(slotInfo.ScaleX)
        targetNode:setScaleY(slotInfo.ScaleY)
        if updateRot then
            targetNode:setRotation(- slotInfo.RotX)
        end
    end
    if _order then
        targetNode:setLocalZOrder(_order)
    end
    if _tag then
        targetNode:setTag(_tag)
    end
    parentSp:addChild(targetNode)
    setTarNodeInfo()

    actionId = schedule(parentSp,function()
        if stopDt(parentSp,targetNode,actionId) then
            -- print("停止刷新")
        else
            setTarNodeInfo()
        end

    end,1/60)

end

--设置Spine绑定节点信息
function GD.util_spineSetBindNodeInfo(spNode, bindNode, releativeParentFlag, zOrder, offsetX, offsetY, scaleX, scaleY, rotation, opacity)
    releativeParentFlag = releativeParentFlag or false
    zOrder = zOrder or 0
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    scaleX = scaleX or 1
    scaleY = scaleY or 1
    rotation = rotation or 0
    opacity = opacity or 255
    local platform = device.platform
    if platform == "ios" or platform == "mac" then
        if util_isSupportVersion("1.7.2") then
            spNode:setBindNodeInfo(bindNode, releativeParentFlag, zOrder, offsetX, offsetY, scaleX, scaleY, rotation, opacity)
        else
            spNode:setBindNodeInfo(bindNode, zOrder, offsetX, offsetY, scaleX, scaleY, rotation, opacity)
        end
    elseif platform == "android" then
        if util_isSupportVersion("1.6.4") then
            spNode:setBindNodeInfo(bindNode, releativeParentFlag, zOrder, offsetX, offsetY, scaleX, scaleY, rotation, opacity)
        else
            spNode:setBindNodeInfo(bindNode, zOrder, offsetX, offsetY, scaleX, scaleY, rotation, opacity)
        end
    end
end

--删除Spine绑定节点
function GD.util_spineRemoveBindNode(spNode, bindNode)
    spNode:removeBindNode(bindNode)
end

--删除Spine骨骼上绑定的所有节点
function GD.util_spineRemoveSlotBindNode(spNode, slotName)
    spNode:removeSlotBindNode(slotName)
end

--删除Spine所有绑定节点
function GD.util_spineClearBindNode(spNode)
    spNode:clearBindNode()
end

--改变Spine骨骼节点
function GD.util_spineChangeBindNode(spNode, slotName, bindNode)
    bindNode:retain()
    util_spineRemoveBindNode(spNode, bindNode)
    util_spinePushBindNode(spNode, slotName, bindNode)
    bindNode:release()
end
-----------csb
local lastCsbFilePath = ""
--创建csb
function GD.util_csbCreate(resourceFilename, isLog)
    --传入参数有问题
    if not resourceFilename then
        print("util_csbCreate path= nil")
        release_print("util_csbCreate path= nil")
        return
    end
    --开始创建时打印路径
    if isLog and lastCsbFilePath ~= resourceFilename then
        if device.platform == "mac" then
            printInfo("util_csbCreate path=" .. resourceFilename)
        else
            release_print("util_csbCreate path=" .. resourceFilename)
        end
    end
    --csb资源存在问题打印
    local csbNode = cc.CSLoader:createNodeWithVisibleSize(resourceFilename)
    if not csbNode then
        --清除本地MD5
        util_checkClearCsbMd5(resourceFilename)
        --输出错误文件log
        util_printCsbErrorLog(resourceFilename)
    end
    --断言后台报错
    assert(csbNode, string.format('util_csbCreate - load resouce node from file "%s" failed', resourceFilename))
    local csbAct = util_actCreate(resourceFilename)
    if csbAct then
        csbNode:runAction(csbAct)
    end
    --结束创建时打印路径
    if isLog and lastCsbFilePath ~= resourceFilename  then
        if device.platform == "mac" then
            printInfo("util_csbCreate path=" .. resourceFilename .. " === end == ")
        else
            release_print("util_csbCreate path=" .. resourceFilename .. " === end == ")
        end
    end

    lastCsbFilePath = resourceFilename

    return csbNode, csbAct
end

function GD.util_actCreate(resourceFilename)
    return cc.CSLoader:createTimeline(resourceFilename)
end

function GD.util_csbScale(node, scale)
    if not node then
        return
    end

    local root = node:getChildByName("root")
    if root then
        root:setScale(scale)
    end
    local boomNode = node:getChildByName("boomNode")
    if boomNode then
        boomNode:setScale(scale)
    end
end

function GD.util_getCsbScale(node)
    local root = node:getChildByName("root")
    if root then
        return root:getScale()
    end
    local boomNode = node:getChildByName("boomNode")
    if boomNode then
        return boomNode:getScale()
    end
    return node:getScale()
end

function GD.util_csbRotation(node, rotation)
    local root = node:getChildByName("root")
    if root then
        root:setRotation(rotation)
    end

    local boomNode = node:getChildByName("boomNode")
    if boomNode then
        boomNode:setRotation(rotation)
    end
end

--根据时间线播放动画
function GD.util_csbPlayForKey(csbAct, key, loop, func, fps)
    if tolua.isnull(csbAct) or not key then
        print("not csbAct or not key  ")
        if func then
            util_csbEndCallFunc(csbAct, key, func, fps)
        end
        return
    end

    if loop then
        loop = true
    else
        loop = false
    end

    if util_csbActionExists(csbAct, key) then
        csbAct:play(key, loop)
    end

    if func then
        util_csbEndCallFunc(csbAct, key, func, fps)
    end
end

--重置csbAction
function GD.util_resetCsbAction(csbAct)
    if tolua.isnull(csbAct) then
        return
    end
    local tagetNode = csbAct:getTarget()
    csbAct:retain()
    tagetNode:stopAllActions()
    tagetNode:runAction(csbAct)
    csbAct:release()
end

--结束回调
function GD.util_csbEndCallFunc(csbAct, key, func, fps)
    if tolua.isnull(csbAct) then
        if func then
            func()
        end
        return
    end
    if func then
        local time = util_csbGetAnimTimes(csbAct, key, fps)
        if csbAct:getTarget() and time > 0 then
            util_performWithDelay(csbAct:getTarget(), func, time)
        else
            if func then
                func()
            end
        end
    end
end

--根据时间线循坏播放动画
function GD.util_csbPlayForKeyForeverFun(csbAct, key, loop, func, fps)
    if tolua.isnull(csbAct) or not key then
        print("not csbAct or not key  ")
        if func then
            util_csbEndCallForeverFun(csbAct, key, func, fps)
        end
        return
    end

    if loop then
        loop = true
    else
        loop = false
    end

    if util_csbActionExists(csbAct, key) then
        csbAct:play(key, loop)
    end

    if func then
        util_csbEndCallForeverFun(csbAct, key, func, fps)
    end
end

--结束回调
function GD.util_csbEndCallForeverFun(csbAct, key, func, fps)
    if tolua.isnull(csbAct) then
        if func then
            func()
        end
        return
    end
    if func then
        local time = util_csbGetAnimTimes(csbAct, key, fps)
        if csbAct:getTarget() and time > 0 then
            util_schedule(csbAct:getTarget(), func, time)
        else
            if func then
                func()
            end
        end
    end
end

--根据帧区间播放
function GD.util_csbPlayForIndex(csbAct, startIndex, endIndex, loop, func, fps)
    if tolua.isnull(csbAct) or not startIndex or not endIndex then
        if func then
            util_csbEndIndexCallFunc(csbAct, func, fps)
        end
        return
    end
    if loop then
        loop = true
    else
        loop = false
    end
    csbAct:gotoFrameAndPlay(startIndex, endIndex, loop)
    if func then
        util_csbEndIndexCallFunc(csbAct, func, fps)
    end
end
--结束回调
function GD.util_csbEndIndexCallFunc(csbAct, func, fps)
    if tolua.isnull(csbAct) then
        if func then
            func()
        end
        return
    end
    if func then
        local time = util_csbGetDuration(csbAct, fps)
        if csbAct:getTarget() and time > 0 then
            util_performWithDelay(csbAct:getTarget(), func, time)
        else
            if func then
                func()
            end
        end
    end
end
--获取当前播放动画播放时间
function GD.util_csbGetDuration(csbAct, fps)
    if not fps then
        local actionRate = csbAct:getTimeSpeed()
        fps = math.floor(60 * actionRate)
    end

    local frameTime = csbAct:getCurrentFrame() - csbAct:getStartFrame()
    if not frameTime or frameTime < 0 or frameTime > 9999 then
        frameTime = 0
    end
    local time = frameTime / fps
    return time
end
--获取动画总时间
function GD.util_csbGetAnimTimes(csbAct, key, fps)
    if not fps then
        local actionRate = csbAct:getTimeSpeed()
        fps = math.floor(60 * actionRate)
    end
    local info = util_csbGetInfo(csbAct, key)
    local frameTime = 0
    if info and info.endIndex and info.startIndex then
        frameTime = info.endIndex - info.startIndex
    end
    if not frameTime or frameTime < 0 or frameTime > 9999 then
        frameTime = 0
    end
    local time = frameTime / fps
    return time
end

--[[
    获取关键帧时间
]]
function GD.util_csbGetAnimKeyFrameTimes(csbAct, key, keyFrameIndex, fps)
    if not fps then
        fps = 30
    end
    local frameTime = keyFrameIndex - csbAct:getStartFrame()
    if not frameTime or frameTime < 0 or frameTime > 9999 then
        frameTime = 0
    end
    local time = frameTime / fps
    return time
end

--获取某一个动画的状态key动画名字
--例如info={startIndex=0,endIndex=120,name=key}
function GD.util_csbGetInfo(csbAct, key)
    if not key or not util_csbActionExists(csbAct, key) then
        return {startIndex = 0, endIndex = 0, name = "error"}
    end
    local info = csbAct:getAnimationInfo(key)
    return info
end

function GD.util_csbActionExists(csbAct, key, cname)
    if not key or tolua.isnull(csbAct) then
        cname = cname or ""
        if util_sendToSplunkMsg ~= nil and cname ~= "" then
            util_sendToSplunkMsg("CsbActionNotExit", "" .. cname .. " animation is not exist!!")
        end
        return false
    end

    return csbAct:IsAnimationInfoExists(key)
end

--停止在某一帧
function GD.util_csbPauseForIndex(csbAct, index)
    if tolua.isnull(csbAct) then
        return
    end
    csbAct:gotoFrameAndPause(index)
end
--根据名称寻找节点
function GD.util_getChildByName(root, name)
    if not root then
        return
    end

    if root:getName() == name then
        return root
    else
        -- print("root:getName()="..root:getName())
    end

    local child_list = root:getChildren()
    for k, node in pairs(child_list) do
        local newNode = util_getChildByName(node, name)
        if newNode then
            return newNode
        end
    end
end
--引用 isUpdata是否强制刷新
function GD.util_require(file, isUpdata)
    if isUpdata then
        package.loaded[file] = nil
    end
    local newTable = require(file)
    return newTable
end

function GD.util_pcallRequire(file)
    local _ok, _module =
        pcall(
        function()
            return require(file)
        end
    )
    if _ok then
        return _module
    else
        if util_sendToSplunkMsg ~= nil then
            local sendErrMsg = "require file " .. tostring(file) .. " error!!"
            sendErrMsg = sendErrMsg .. "\n" .. tostring(debug.traceback())
            util_sendToSplunkMsg("luaError", sendErrMsg)
        end
        if isMac() then
            assert(nil, "" .. _module)
        end
        return nil
    end
end

function GD.util_pcallCreate(file)
    local _module = util_pcallRequire(file)
    if _module then
        return _module:create()
    else
        return nil
    end
end

--创建
function GD.util_createView(file, ...)
    local element = nil 
    if type(file) == "string" then
        element = util_require(file):create(...)
    elseif type(file) == "table" then
        element = file:create(...)
    else
        return nil
    end
    if element.initData_ then
        element:initData_(...)
    end
    return element
    -- 多继承存在问题添加init方法
    -- return util_require(file):create(...)
end

--先查找有对应的lua文件，再创建
function GD.util_createFindView(file, ...)
    assert(file, "create find file is nil!!!")
    --判断文件是否存在
    if cc.FileUtils:getInstance():isFileExist(file .. ".lua") or cc.FileUtils:getInstance():isFileExist(file .. ".luac") then
        local fileName, count = string.gsub(file, "/", ".")
        local element = util_require(fileName):create(...)
        if element.initData_ then
            element:initData_(...)
        end

        return element
    end

    return nil
end

--是否存在该文件 -用于资源判断
function GD.util_IsFileExist(fileName)
    if cc.FileUtils:getInstance():isFileExist(fileName) then
        return true
    end

    return false
end

function GD.util_getRequireFile(filePath)
    if util_IsFileExist(filePath .. ".lua") or util_IsFileExist(filePath .. ".luac") then
        local fileName, count = string.gsub(filePath, "/", ".")
        local requireFile = require(fileName)
        return requireFile
    end

    return nil
end

function GD.util_createAnimation(csb_path, isAutoScale)
    local animation = util_createView("base.BaseAnimation", csb_path, isAutoScale)
    return animation
end

function GD.util_setCsbVisible(node, flag)
    if not node or not node.setVisible then
        return
    end
    if flag then
        node:setVisible(true)
    else
        node:pause()
        node:setVisible(false)
    end
end

function GD.util_setPositionPercent(node, rate)
    local root = node:getChildByName("root")
    if root then
        root:setPositionNormalized(cc.p(0.5, rate))
    end
end

--图片置灰
function GD.util_setSpriteGray(sp)
    local vertShaderByteArray =
        "\n" ..
        "attribute vec4 a_position; \n" ..
            "attribute vec2 a_texCoord; \n" ..
                "attribute vec4 a_color; \n" ..
                    "#ifdef GL_ES  \n" ..
                        "varying mediump vec4 v_fragmentColor;\n" ..
                            "varying mediump vec2 v_texCoord;\n" ..
                                "#else                      \n" ..
                                    "varying vec4 v_fragmentColor; \n" ..
                                        "varying vec2 v_texCoord;  \n" ..
                                            "#endif    \n" ..
                                                "void main() \n" .. "{\n" .. "gl_Position = CC_PMatrix * a_position; \n" .. "v_fragmentColor = a_color;\n" .. "v_texCoord = a_texCoord;\n" .. "}"

    local flagShaderByteArray =
        "#ifdef GL_ES \n" ..
        "precision mediump float; \n" ..
            "#endif \n" ..
                "varying vec4 v_fragmentColor; \n" ..
                    "varying vec2 v_texCoord; \n" ..
                        "void main(void) \n" ..
                            "{ \n" .. "vec4 c = texture2D(CC_Texture0, v_texCoord); \n" .. "float gray = 0.2*c.r + 0.7*c.g + 0.1*c.b;\n" .. "gl_FragColor = vec4(gray,gray,gray,c.a); \n" .. "}"

    -- 创建Shader并缓存 --
    local shader = cc.GLProgramCache:getInstance():getGLProgram("GrayShader")
    if shader == nil then
        shader = cc.GLProgram:createWithByteArrays(vertShaderByteArray, flagShaderByteArray)
        cc.GLProgramCache:getInstance():addGLProgram(shader, "GrayShader")
    end
    local glProgramState = cc.GLProgramState:create(shader)
    sp:setGLProgramState(glProgramState)
end

--清理手机缓存
function GD.util_removeAllLocalData()
    if device.platform == "mac" or DEBUG ~= 2 then
        return
    end
    local path = cc.UserDefault:getXMLFilePath()
    local directoryPath = string.gsub(path, "/UserDefault.xml", "/")
    release_print("-----------------------util_removeAllLocalData directoryPath = " .. directoryPath)
    release_print("-----------------------util_removeAllLocalData writablePath = " .. device.writablePath)
    cc.FileUtils:getInstance():removeDirectory(directoryPath)
    cc.FileUtils:getInstance():removeDirectory(device.writablePath)
    cc.FileUtils:getInstance():purgeCachedEntries()
    gLobalDataManager:deleteAllValues()
    cc.FileUtils:getInstance():createDirectory(device.writablePath)
    -- 整包版本
    local appVersion = util_getAppVersionCode()
    gLobalDataManager:setVersion("appVer", tostring(appVersion))
    -- 退出FB登录
    if globalFaceBookManager:getFbLoginStatus() then
        globalFaceBookManager:fbLogOut()
    end
end

--重启
function GD.util_restartGame(callback, isForce)
    release_print("util_restartGame--removeAllTextures")
    -- cc.Director:getInstance():getTextureCache():removeAllTextures()
    -- cc.FileUtils:getInstance():purgeCachedEntries()
    release_print("util_restartGame--stop all download!!!")
    util_stopAllDownloadThread()
    -- 清理下载回调
    local dlCallFunc = function()
    end
    xcyy.HandlerIF:registerDownloadHandler(dlCallFunc, dlCallFunc, dlCallFunc, dlCallFunc)

    if gLobalNoticManager ~= nil then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESTART_GAME_CLEAR)
    end

    if globalMachineController then
        -- 清理关卡逻辑
        globalMachineController:onExit()
    end

    local callFunc = function()
        if gLobalViewManager then 
            if gLobalViewManager.addLoadingSceneBlock then
                gLobalViewManager:addLoadingSceneBlock()
            end
            gLobalViewManager:releaseViewLayer()
        end

        release_print("util_restartGame--restart")

        if gLobalRemoveDir and gLobalRemoveDir ~= "" then
            release_print(gLobalRemoveDir)
        end

        if globalPlatformManager and globalPlatformManager.rebootGame then
            globalPlatformManager:rebootGame(callback)
        else
            if callback then
                callback()
            end
            if scheduler.unscheduleGlobalAll then
                scheduler.unscheduleGlobalAll()
            end
            xcyy.SlotsUtil:restartGame()
        end
    end

    if gLobalViewManager:isLogonView() or isForce then
        callFunc()
    else
        release_print("util_restartGame--goto Scene_Logon")
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Logon, callFunc)
    end
end

--停止下载指定url
function GD.util_stopAllDownloadThreadByURL(url)
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios" or platform == "mac" then
        supportVersion = "1.6.8"
    elseif platform == "android" then
        supportVersion = "1.6.0"
    end
    if util_isSupportVersion(supportVersion) then
        xcyy.XCDownloadManager:stopDownloadByKey(url)
    end
end

--停止所有下载信息回调
function GD.util_stopAllDownloadThread()
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios" or platform == "mac" then
        supportVersion = "1.6.8"
    elseif platform == "android" then
        supportVersion = "1.6.0"
    end
    if util_isSupportVersion(supportVersion) then
        xcyy.XCDownloadManager:stopAllDownload()
    end
end

--获取app版本号
function GD.util_getAppVersionCode()
    if device.platform == "ios" or device.platform == "android" then
        if not APP_VERSION_CODE then
            GD.APP_VERSION_CODE = globalPlatformManager:getSystemVersion()
            local minVer = util_convertAppCodeToNumber("1.2.8")
            local curVer = util_convertAppCodeToNumber(APP_VERSION_CODE)
            release_print("AppVersionCode 1= " .. curVer)
            if curVer < minVer then
                if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
                    curVer = gLobalDataManager:getVersion("appVer")
                else
                    curVer = gLobalDataManager:getStringByField("appVersionCode")
                end
                release_print("AppVersionCode 2= " .. curVer)
            end
        end
    end
    if device.platform == "mac" then
        -- APP_VERSION_CODE = gLobalDataManager:getStringByField("appVersionCode")
        APP_VERSION_CODE = xcyy.GameBridgeLua:getAppVersionCode()
    end
    -- release_print("AppVersionCode 3= " .. APP_VERSION_CODE)
    return APP_VERSION_CODE
end

-- 热更版本号
GD.UPDATE_VERSION_CODE = 0
--获取热更新版本号
function GD.util_getUpdateVersionCode(flag)
    local packageUpdateVersion = tonumber(xcyy.GameBridgeLua:getPackageUpdateVersion())
    if UPDATE_VERSION_CODE < packageUpdateVersion then
        if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
            UPDATE_VERSION_CODE = gLobalDataManager:getLastUpdateVer()
        else
            UPDATE_VERSION_CODE = gLobalDataManager:getNumberByField("lastUpdateVersion", packageUpdateVersion)
        end
    end
    return UPDATE_VERSION_CODE
end
--获取热更新版本号
function GD.util_saveUpdateVersionCode(code)
    -- 修改本地最新版本号
    UPDATE_VERSION_CODE = code
    if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
        gLobalDataManager:setVersion("lastUpdateVer", tostring(code))
    else
        gLobalDataManager:setNumberByField("lastUpdateVersion", code, true)
    end
end
--版本是否支持
function GD.util_isSupportVersion(minVersion, platform)
    if platform and device.platform ~= platform then
        return false
    end
    local version = util_getAppVersionCode()
    local minVer = util_convertAppCodeToNumber(minVersion)
    local curVer = util_convertAppCodeToNumber(version)
    if curVer >= minVer then
        return true
    end
    return false
end

--根据content大小创建按钮监听
function util_makeTouch(contentSprite, name)
    local touch = ccui.Layout:create()
    touch:setName(name)
    touch:setTag(10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(false)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize(contentSprite:getContentSize())
    touch:setClippingEnabled(false)
    touch:setBackGroundColorOpacity(0)
    return touch
end

--清除搜索路径
function GD.util_clearSearchPaths()
    local newSearchPaths = {}
    newSearchPaths[#newSearchPaths + 1] = device.writablePath
    newSearchPaths[#newSearchPaths + 1] = device.writablePath .. "src"
    newSearchPaths[#newSearchPaths + 1] = device.writablePath .. "res"
    newSearchPaths[#newSearchPaths + 1] = "src"
    newSearchPaths[#newSearchPaths + 1] = "res"
    ccs.ActionTimelineCache:getInstance():purge()
    cc.FileUtils:getInstance():setSearchPaths(newSearchPaths)
end

--图片还原
function GD.util_clearSpriteGray(sp)
    local vertShaderByteArray =
        "\n" ..
        "attribute vec4 a_position; \n" ..
            "attribute vec2 a_texCoord; \n" ..
                "attribute vec4 a_color; \n" ..
                    "#ifdef GL_ES  \n" ..
                        "varying mediump vec4 v_fragmentColor;\n" ..
                            "varying mediump vec2 v_texCoord;\n" ..
                                "#else                      \n" ..
                                    "varying vec4 v_fragmentColor; \n" ..
                                        "varying vec2 v_texCoord;  \n" ..
                                            "#endif    \n" ..
                                                "void main() \n" .. "{\n" .. "gl_Position = CC_PMatrix * a_position; \n" .. "v_fragmentColor = a_color;\n" .. "v_texCoord = a_texCoord;\n" .. "}"

    local flagShaderByteArray =
        "#ifdef GL_ES \n" ..
        "precision mediump float; \n" ..
            "#endif \n" .. "varying vec4 v_fragmentColor; \n" .. "varying vec2 v_texCoord; \n" .. "void main(void) \n" .. "{ \n" .. "gl_FragColor = texture2D(CC_Texture0, v_texCoord); \n" .. "}"

    -- 创建Shader并缓存 --
    local shader = cc.GLProgramCache:getInstance():getGLProgram("ClearGrayShader")
    if shader == nil then
        shader = cc.GLProgram:createWithByteArrays(vertShaderByteArray, flagShaderByteArray)
        cc.GLProgramCache:getInstance():addGLProgram(shader, "ClearGrayShader")
    end
    local glProgramState = cc.GLProgramState:create(shader)
    sp:setGLProgramState(glProgramState)
end

function GD.util_shaderFlash(sp)
    local vertShaderByteArray =
        [[
        attribute vec4 a_position;
        attribute vec2 a_texCoord;
        attribute vec4 a_color;
        varying vec2 v_texCoord;
        varying vec4 v_fragmentColor;
        void main()
        {
            gl_Position = CC_PMatrix * a_position;
            v_fragmentColor = a_color;
            v_texCoord = a_texCoord;
        }
    ]]

    local flagShaderByteArray =
        [[
#ifdef GL_ES
precision mediump float;
#endif
varying vec2 v_texCoord;
uniform float sys_time;
void main()
{
    vec4 src_color = texture2D(CC_Texture0, v_texCoord).rgba;
    float width = 0.2;
    float start = sys_time * 1.2;
    float strength = 0.1;
    float offset = 0.3;

    if( v_texCoord.x < (start - offset * v_texCoord.y) &&  v_texCoord.x > (start - offset * v_texCoord.y - width))
    {
        vec3 improve = strength * vec3(255, 255, 255);
        vec3 result = improve * vec3( src_color.r, src_color.g, src_color.b);
        gl_FragColor = vec4(result, src_color.a);

    } else {
        gl_FragColor = src_color;
    }
}
]]
    local glProgram = cc.GLProgram:createWithByteArrays(vertShaderByteArray, flagShaderByteArray)
    sp:setGLProgram(glProgram)
    if sp.shaderAct then
        sp.shaderAct:stop()
    end
    sp._glProgram = glProgram
    sp._time = 0
    sp._sin = 0
    sp._delayIndex = math.random(10, 30)
    sp.shaderAct =
        schedule(
        sp,
        function()
            if sp._delayIndex > 0 then
                sp._delayIndex = sp._delayIndex - 1
                return
            end
            sp._time = sp._time + 0.1
            glProgram:use()
            local glProgram_state = cc.GLProgramState:getOrCreateWithGLProgram(glProgram)
            glProgram_state:setUniformFloat("sys_time", sp._sin)
            sp._sin = math.sin(sp._time)
            if sp._sin > 0.99 then
                sp._sin = 0
                sp._time = 0
                sp._delayIndex = 20
                glProgram_state:setUniformFloat("sys_time", sp._sin)
                glProgram:use()
            end
        end,
        0.05
    )
end

-- flash by a mask texture  : tm --
function GD.util_SpFlash(pBaseSp, pMaskImageName, fRunSpeed, fInterval)
    local vertShaderByteArray =
        [[
        attribute vec4 a_position;
        attribute vec2 a_texCoord;
        attribute vec4 a_color;
        varying vec2 v_texCoord;

        void main()
        {
            gl_Position = CC_PMatrix * a_position;
            v_texCoord = a_texCoord;
        }
    ]]

    local flagShaderByteArray =
        [[
        #ifdef GL_ES
        precision mediump float;
        #endif
        varying vec2 v_texCoord;

        uniform float min_uv;
        uniform float max_uv;
        uniform sampler2D t_mask;

        void main()
        {
            vec4 src_color = texture2D(CC_Texture0, v_texCoord);

            vec2 maskUV = vec2(-1,-1);

            if( v_texCoord.x >= min_uv && v_texCoord.x <= max_uv )
            {
                maskUV.x = (v_texCoord.x - min_uv) / ( max_uv - min_uv );
                maskUV.y = v_texCoord.y;
            }

            if( maskUV.x >= 0.0 )
            {
                vec4 maskColor = texture2D( t_mask , maskUV );
                gl_FragColor   = src_color + maskColor * src_color.a;
            }
            else
            {
                gl_FragColor = src_color;
            }
        }
    ]]

    assert(pBaseSp, "I want to set a flash for a sprite ,but the sprite is nil")
    -- 创建Shader并缓存 --
    local shader = cc.GLProgramCache:getInstance():getGLProgram("FlashShader")
    if shader == nil then
        shader = cc.GLProgram:createWithByteArrays(vertShaderByteArray, flagShaderByteArray)
        cc.GLProgramCache:getInstance():addGLProgram(shader, "FlashShader")
    end

    local glProgramState = cc.GLProgramState:create(shader)
    pBaseSp:setGLProgramState(glProgramState)

    local maskImg = cc.Director:getInstance():getTextureCache():addImage(pMaskImageName)
    assert(maskImg, "I want to set a flash for a sprite ,but the mask image is nil")
    glProgramState:setUniformTexture("t_mask", maskImg)

    -- 获取Size --
    local baseSize = pBaseSp:getContentSize()
    local flashSize = maskImg:getContentSize()
    local startX = 0 - flashSize.width
    local endX = baseSize.width + flashSize.width
    local curX = baseSize.width / 2 --startX
    local curInterval = 0
    local dt = 1 / 60

    pBaseSp.startFlash = function(pSender, fSpeed, fInterval)
        pBaseSp:stopFlash()
        pBaseSp.actionHandler =
            schedule(
            pBaseSp,
            function()
                if curX >= endX then
                    curInterval = curInterval + dt
                    if curInterval > fInterval then
                        curInterval = 0
                        curX = startX
                    end
                    return
                end

                local minUV = (curX - flashSize.width / 2) / baseSize.width
                local maxUV = (curX + flashSize.width / 2) / baseSize.width

                glProgramState:setUniformFloat("min_uv", minUV)
                glProgramState:setUniformFloat("max_uv", maxUV)

                curX = curX + fSpeed * dt
            end,
            dt
        )
    end

    -- local minUV = ( curX - flashSize.width/2 ) / baseSize.width
    -- local maxUV = ( curX + flashSize.width/2 ) / baseSize.width
    -- glProgramState:setUniformFloat( "min_uv" , minUV )
    -- glProgramState:setUniformFloat( "max_uv" , maxUV )

    pBaseSp.stopFlash = function()
        if pBaseSp.actionHandler ~= nil then
            pBaseSp.actionHandler:stop()
            pBaseSp.actionHandler = nil
        end
    end

    pBaseSp:startFlash(fRunSpeed, fInterval)
end

function GD.util_findChildByNameTraverse(root, targetnameList, idx)
    local node = nil
    local targetname = targetnameList[idx]
    if nil == targetname then
        return root
    end
    local childs = root:getChildren()
    for i = 1, #childs do
        local name = childs[i]:getName()
        if targetname == name then
            node = childs[i]
            break
        end
    end
    if nil ~= node then
        return GD.util_findChildByNameTraverse(node, targetnameList, idx + 1)
    else
        return node
    end
end

---自定义播放骨骼动画 起帧_sf,末帧_ef,是否循环_isLoop
function GD.mGotoFrameAndPlay(_body, _bodyAction, _sf, _ef, _isLoop)
    _bodyAction.sFrame = _sf
    _bodyAction.eFrame = _ef
    _bodyAction:gotoFrameAndPlay(_sf, _ef, _isLoop)
end

function GD.createBoneBody(_texture, _sf, _ef) --_texture  骨骼动画文件路径 *.csb格式
    local body = cc.CSLoader:createNode(_texture)
    local bodyAction = cc.CSLoader:createTimeline(_texture)
    --    bodyAction:setTimeSpeed(0.5) --设置执行动画速度

    bodyAction.sFrame = _sf --执行动作的开始帧和结尾帧index
    bodyAction.eFrame = _ef
    body:runAction(bodyAction)

    return body, bodyAction
end
--创建精灵兼容合图非合图方式
function GD.util_createSprite(path, bAsync)
    if not path or path == "" then
        return
    end
    local SpriteFrameCache = cc.SpriteFrameCache:getInstance()
    local bgFrame = SpriteFrameCache:getSpriteFrame(path)
    if bgFrame then
        local sp = cc.Sprite:createWithSpriteFrame(bgFrame)
        return sp
    else
        local sp = cc.Sprite:create()
        if cc.FileUtils:getInstance():isFileExist(path) then -- or DEBUG==2
            if not bAsync then
                sp:setTexture(path)
            else
                display.loadImage(path, function()
                    if not tolua.isnull(sp) then
                        sp:setTexture(path)
                    end
                end)
            end
        else
            release_print("util_createSprite error path = " .. path)
            print("util_createSprite error path = " .. path)
        end
        return sp
    end
end

--修改纹理兼容合图非合图方式 sprite和imageView
function GD.util_changeTexture(targetSp, path, bAsync)
    if not targetSp or tolua.isnull(targetSp) then
        return
    end
    if not path or path == "" then
        return
    end
    local SpriteFrameCache = cc.SpriteFrameCache:getInstance()
    local bgFrame = SpriteFrameCache:getSpriteFrame(path)
    if tolua.type(targetSp) == "cc.Sprite" then
        if bgFrame then
            targetSp:setSpriteFrame(bgFrame)
            return true
        else
            if cc.FileUtils:getInstance():isFileExist(path) then --or DEBUG==2 then
                if not bAsync then
                    targetSp:setTexture(path)
                else
                    display.loadImage(path, function()
                        if not tolua.isnull(targetSp) then
                            targetSp:setTexture(path)
                        end
                    end)
                end
                return true
            else
                release_print("util_changeTexture error path = " .. path)
                print("util_changeTexture error path = " .. path)
                return false
            end
        end
    end
    if tolua.type(targetSp) == "ccui.ImageView" then
        if bgFrame then
            targetSp:loadTexture(path, UI_TEX_TYPE_PLIST)
            return true
        else
            if cc.FileUtils:getInstance():isFileExist(path) then --or DEBUG==2 then
                targetSp:loadTexture(path)
                return true
            else
                release_print("util_changeTexture error path = " .. path)
                print("util_changeTexture error path = " .. path)
                return false
            end
        end
    end
end

--截取屏幕作为纹理创建sprite (！！不能在onExit, onClear方法里调用)
function GD.util_createTargetScreenSprite(targetNode, rect, scale)
    local rt = cc.RenderTexture:create(display.width, display.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, gl.DEPTH24_STENCIL8_OES)
    rt:begin()
    if targetNode then
        targetNode:visit()
    else
        cc.Director:getInstance():getRunningScene():visit()
    end
    rt:endToLua()

    local pSprite = nil
    if rect ~= nil then
        local sprTarget = cc.Sprite:createWithTexture(rt:getSprite():getTexture(), rect, false)
        sprTarget:setFlippedY(true)
        sprTarget:setAnchorPoint(0, 0)
        local targetSize = sprTarget:getContentSize()
        if type(scale) == "number" then
            sprTarget:setScale(scale)
            targetSize.width = targetSize.width * scale
            targetSize.height = targetSize.height * scale
        end
        rt = cc.RenderTexture:create(targetSize.width, targetSize.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, gl.DEPTH24_STENCIL8_OES)
        rt:begin()
        sprTarget:visit()
        rt:endToLua()
    end

    pSprite = cc.Sprite:createWithTexture(rt:getSprite():getTexture())
    pSprite:setFlippedY(true)

    return pSprite, rt
end

--截取指定node纹理保存到文件中
function GD.util_saveNodeTextureToFile(node, size, fileName, callBack)
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios" or platform == "mac" then
        supportVersion = "1.6.8"
    elseif platform == "android" then
        supportVersion = "1.6.0"
    end
    if util_isSupportVersion(supportVersion) then
        local width = size ~= nil and size.width or display.width
        local height = size ~= nil and size.height or display.height
        local rt = cc.RenderTexture:create(width, height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, gl.DEPTH24_STENCIL8_OES)
        rt:begin()
        node:visit()
        rt:endToLua()
        --callBack(fullPath)
        rt:saveToFileLua(fileName, true, callBack)
        return rt
    else
        return nil
    end
end

--心跳动画 重复放大-缩小
function GD.util_heartBeat(node, time, range)
    if node == nil then
        return
    end

    local req = cc.RepeatForever:create(cc.Sequence:create(cc.ScaleTo:create(time, 1 + range), cc.ScaleTo:create(time, 1)))
    node:runAction(req)
end

--生成排版坐标
function GD.util_TypeSettingWidth(width, interval, count)
    local posList = {}
    if count < 1 then
        return posList
    end

    local num1, num2 = math.modf(count / 2)
    local tempInterval = 0
    if num2 ~= 0 then
        -- 奇数
        tempInterval = (width + interval) / 2
    end

    for i = 1, count do
        local posX = 0
        if i <= num1 then
            posX = -((num1 - (i - 1)) * (width + interval) + tempInterval)
        elseif i > num1 then
            local temp = num1
            if num2 ~= 0 then
                temp = num1 + 1
            end

            if num2 ~= 0 and i == num1 + 1 then
                posX = (i - temp) * (width + interval)
            else
                posX = ((i - temp) * (width + interval) + tempInterval)
            end
        end

        posList[#posList + 1] = posX
    end

    return posList
end
--创建商店道具 data道具数据
function GD.util_createShopBPNode(data)
    --vip没有传icon
    if data and data.p_id == 10002 then
        data.p_icon = "Vip"
    end
    if data and data.p_icon ~= nil and data.p_icon ~= "" then
        local path = "PBRes/ItemUI/item_shop/Shop_" .. data.p_icon .. ".csb"
        if util_IsFileExist(path) then
            local item = util_createView("PBCode2.ShopPBNode", data)
            return item
        end
    end
end

--根据shopData创建物品项
function GD.util_createItemByShopData(data)
    local pngName = nil
    if data and data.p_icon ~= nil and data.p_icon ~= "" then
        pngName = data.p_icon
    end
    --vip没有传icon
    if data and data.p_id == 10002 then
        data.p_icon = "Vip"
    end

    local propNode = util_createShopBPNode(data)
    if propNode == nil then
        local pngPath = data.p_type == "Buff" and "Shop_Res/ui/" .. pngName .. ".png" or string.format("Card_Icon/%s.png", pngName)
        propNode = util_createSprite(pngPath)
    end
    return propNode
end

function GD.util_playMoveToAction(node, time, pos, callback, type)
    local actionList = {}
    if type == "easyInOut" then
        actionList[#actionList + 1] = cc.EaseInOut:create(cc.MoveTo:create(time, pos), 1)
    elseif type == "easyIn" then
        actionList[#actionList + 1] = cc.EaseIn:create(cc.MoveTo:create(time, pos), 1)
    else
        actionList[#actionList + 1] = cc.MoveTo:create(time, pos)
    end

    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
        end
    )
    local seq = cc.Sequence:create(actionList)
    node:runAction(seq)
end

function GD.util_playMoveByAction(node, time, pos, callback, type)
    local actionList = {}
    if type == "easyInOut" then
        actionList[#actionList + 1] = cc.EaseInOut:create(cc.MoveBy:create(time, pos), 1)
    else
        actionList[#actionList + 1] = cc.MoveBy:create(time, pos)
    end

    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
        end
    )
    local seq = cc.Sequence:create(actionList)
    node:runAction(seq)
end

function GD.util_playScaleToAction(node, time, scale, callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.ScaleTo:create(time, scale)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
        end
    )
    local seq = cc.Sequence:create(actionList)
    node:runAction(seq)
end
function GD.util_playFadeOutAction(node, time, callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.FadeOut:create(time)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
        end
    )
    local seq = cc.Sequence:create(actionList)
    util_setCascadeOpacityEnabledRescursion(node, true)
    node:runAction(seq)
end
function GD.util_playFadeInAction(node, time, callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.FadeIn:create(time)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
        end
    )
    local seq = cc.Sequence:create(actionList)
    util_setCascadeOpacityEnabledRescursion(node, true)
    node:runAction(seq)
end

function GD.util_getNodeCount(node)
    local count = 1
    for k, v in ipairs(node:getChildren()) do
        count = count + util_getNodeCount(v)
    end
    return count
end

--关卡背景适配方案
function GD.util_adaptBgScale(node)
    local deviceWidth, deviceHeight = display.width, display.height
    local nodeContentSize = node:getContentSize()
    local nodeWidth, nodeHeight = nodeContentSize.width, nodeContentSize.height
    local scaleX, scaleY = deviceWidth / nodeWidth, deviceHeight / nodeHeight
    node:setScale(globalData.slotRunData.isPortrait and scaleY or scaleX)
end

function GD.util_getAdaptDesignScale()
    local deviceWidth, deviceHeight = display.width, display.height
    local designWidth, designHeight = CC_DESIGN_RESOLUTION.width, CC_DESIGN_RESOLUTION.height
    local scaleX, scaleY = deviceWidth / designWidth, deviceHeight / designHeight
    return math.min(scaleX, scaleY)
end

function GD.util_getAdaptDeviceScale()
    local deviceWidth, deviceHeight = display.sizeInPixels.width, display.sizeInPixels.height
    local desightWidth, designHeight = CC_DESIGN_RESOLUTION.width, CC_DESIGN_RESOLUTION.height
    local scaleX, scaleY = deviceWidth / desightWidth, deviceHeight / designHeight
    return math.min(scaleX, scaleY)
end

function GD.util_changeNodeParent(newParent, node, zOrder)
    if (not tolua.isnull(newParent)) and (not tolua.isnull(node)) then
        node:retain()
        node:removeFromParent(false)
        newParent:addChild(node, zOrder or 0)
        node:release()
    else
        if tolua.isnull(newParent) then
            sendBuglyLuaException("util_changeNodeParent:newParent is nill!!")
        elseif tolua.isnull(node) then
            sendBuglyLuaException("util_changeNodeParent:node is nill!!")
        end
        return node
    end
end

--顶上下边缘缩放值
function GD.util_getAdaptNode(node)
    if not node then
        return
    end
    local designScale = CC_DESIGN_RESOLUTION.width / CC_DESIGN_RESOLUTION.height
    local deviceScale = display.width / display.height
    local disHeight = math.max(1, globalData.slotRunData.isPortrait and deviceScale / designScale or designScale / deviceScale)
    node:setPositionY(node:getPositionY() * disHeight)
end
--适配横屏
function GD.util_adaptLandscape(node)
    local scaleWidth = display.width / DESIGN_SIZE.width
    local scaleHeight = display.height / DESIGN_SIZE.height
    local scale = scaleHeight / scaleWidth
    scale = math.min(scale, 1)
    util_csbScale(node, scale)
end

--适配竖屏
function GD.util_adaptPortrait(node)
    local scaleWidth = display.width / DESIGN_SIZE.height
    local scaleHeight = display.height / DESIGN_SIZE.width
    util_csbScale(node, math.min(math.min(scaleWidth, scaleHeight), 1))
end

--竖版适配横屏
--竖版UI适配竖版关卡
function GD.util_portraitAdaptLandscape(node)
    if globalData.slotRunData.isPortrait == true then
        util_adaptLandscape(node)
        return true
    end
    return false
end

--竖版适配竖屏
--竖版UI适配横版关卡
function GD.util_portraitAdaptPortrait(node)
    if globalData.slotRunData.isPortrait == true then
        util_adaptPortrait(node)
        return true
    end
    return false
end

--旋转适配横屏
function GD.util_rotateToLandscape(node)
    if globalData.slotRunData.isPortrait == true then
        util_csbRotation(node, 90)
        node.preRotateScale = node:getScale()
        util_portraitAdaptLandscape(node)
        return true
    end
    return false
end

--还原旋转后的缩放UI
function GD.util_rotateToBack(node)
    util_csbRotation(node, 0)
    util_csbScale(node, node.preRotateScale or util_getCsbScale(node))
end

function GD.util_getConvertNodePos(oldNode, newNode)
    if not oldNode or not newNode then
        return cc.p(0, 0)
    end
    local worldPos = oldNode:convertToWorldSpace(cc.p(0, 0))
    local pos = newNode:getParent():convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    return pos
end

--获取图片的大小
function GD.util_getSpriteSize(path)
    local sprite = util_createSprite(path)
    return sprite:getContentSize()
end

--[[
UI居中对齐
util_alignCenter(
{
    {node = self.node1},
    {node = self.node2,alignX = 5,alignY = 1},
    {node = self.node3,alignX = 10},
    {node = self.node4,alignX = 10,size = cc.size(100,100)},
    {node = self.node5,alignX = 10,anchor = cc.p(0,1) }
    {node = self.node6,alignX = 10,scale = 1 }
})
node:节点
alignX:x间距
alignY:y间距
beginY:定位Y轴坐标，默认用第一个图标Y坐标
maxLen:指定最大长度(补充的参数) 当总长度超过指定最大长度时，会主动缩小每个控件的大小 -- 张伟
]]
function GD.util_alignCenter(uiList, beginY, maxLen)
    local totalWidth = 0
    local posX, posY = 0, 0
    for k, v in ipairs(uiList) do
        local alignX = v.alignX or 0
        local alignY = v.alignY or 0
        local node = v.node
        local nodeSize = v.size or node:getContentSize()
        local nodeScale = v.scale or node:getScale()
        totalWidth = totalWidth + alignX + nodeSize.width * nodeScale
        if beginY then
            posY = beginY
        elseif k == 1 then
            posX, posY = node:getPosition()
            posY = posY + alignY
        end
    end
    local scale = 1
    if maxLen and maxLen < totalWidth then
        scale = maxLen / totalWidth
        totalWidth = maxLen
    end
    posX = -totalWidth / 2
    for k, v in ipairs(uiList) do
        local alignX = v.alignX or 0
        local alignY = v.alignY or 0
        local node = v.node
        local nodeSize = v.size or node:getContentSize()
        local nodeAnchor = v.anchor or node:getAnchorPoint()
        local nodeScale = v.scale or node:getScale()
        posX = posX + alignX * scale + nodeAnchor.x * nodeSize.width * nodeScale * scale
        if k > 1 then
            local preInfo = uiList[k - 1]
            local preNode = preInfo.node
            local preAlignX = preInfo.alignX or 0
            local preNodeSize = preInfo.size or preNode:getContentSize()
            local preNodeAnchor = preInfo.anchor or preNode:getAnchorPoint()
            local preNodeScale = preInfo.scale or preNode:getScale()
            posX = posX + preAlignX * scale + (1 - preNodeAnchor.x) * preNodeSize.width * preNodeScale * scale
        end
        node:setPosition(posX, posY + alignY)
        node:setScale(nodeScale * scale)
    end

    return totalWidth
end

--[[
UI左对齐
util_alignLeft(
{
    {node = self.node1},
    {node = self.node2,alignX = 5,alignY = 1},
    {node = self.node3,alignX = 10},
    {node = self.node4,alignX = 10,size = cc.size(100,100)},
    {node = self.node5,alignX = 10,anchor = cc.p(0,1)}
}
)
node:节点
alignX:x间距
alignY:y间距
]]
function GD.util_alignLeft(uiList)
    local totalWidth = 0
    local posX, posY = 0, 0
    for k, v in ipairs(uiList) do
        local alignX = v.alignX or 0
        local alignY = v.alignY or 0
        local node = v.node
        local nodeSize = v.size or node:getContentSize()
        local nodeAnchor = v.anchor or node:getAnchorPoint()
        local nodeScale = node:getScale()
        posX = posX + alignX + nodeAnchor.x * nodeSize.width * nodeScale
        if k > 1 then
            local preInfo = uiList[k - 1]
            local preNode = preInfo.node
            local preAlignX = preInfo.alignX or 0
            local preNodeSize = preInfo.size or preNode:getContentSize()
            local preNodeAnchor = preInfo.anchor or preNode:getAnchorPoint()
            local preNodeScale = preNode:getScale()
            posX = posX + preAlignX + (1 - preNodeAnchor.x) * preNodeSize.width * preNodeScale
        end
        node:setPosition(posX + alignX, posY + alignY)
    end
end

function GD.util_setProcessBarPercentAnim(processBar, time, desValue, callBack)
    local function stopAction(bar)
        if bar.animCallBack ~= nil then
            bar.animCallBack()
        end
        if bar.processAction ~= nil then
            bar:stopAction(bar.processAction)
            bar.processAction = nil
        end
    end
    stopAction(processBar)
    local curPercent = processBar:getPercent()
    local addValue = (desValue - curPercent) / 60 / time
    local function update()
        curPercent = curPercent + addValue
        curPercent = curPercent > 0 and curPercent or 0
        curPercent = curPercent <= 100 and curPercent or 100
        processBar:setPercent(curPercent)
        if math.abs(curPercent - desValue) <= math.abs(addValue) then
            processBar:setPercent(desValue)
            stopAction(processBar)
        end
    end
    processBar.processAction = schedule(processBar, update, 1 / 60)
    processBar.animCallBack = callBack
    update()
end

function GD.util_resumeCoroutine(cor)
    if cor ~= nil then
        if coroutine.status(cor) ~= "dead" then
            local flag, msg = coroutine.resume(cor)
            if not flag then
                __G__TRACKBACK__(msg)
            end
        end
    end
end

--添加下载节点
function GD.util_addDownLoadingNode(downLoadNode, downLoadKey, processPath)
    if downLoadNode ~= nil and globalDynamicDLControl:checkDownloading(downLoadKey) then
        local percent = globalDynamicDLControl:getPercentForKey(downLoadKey)
        local lockBg = util_createSprite(processPath)
        if not lockBg then
            release_print("lockBg -- " .. downLoadKey .. " -- util_addDownLoadingNode = " .. (processPath or ""))
            return nil, nil
        end
        downLoadNode:addChild(lockBg)
        lockBg:setColor(cc.c3b(80, 80, 80))

        local processBg = util_createSprite(processPath)
        if not processBg then
            release_print("processBg -- " .. downLoadKey .. " -- util_addDownLoadingNode = " .. (processPath or ""))
            return nil, nil
        end
        local processTimer = cc.ProgressTimer:create(processBg)
        processTimer:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
        processTimer:setAnchorPoint(0.5, 0.5)
        processTimer:setPosition(0, 0)
        downLoadNode:addChild(processTimer, 1)
        processTimer:setPercentage(math.ceil(percent * 100))
        return lockBg, processTimer
    end
    return nil, nil
end

-- 添加下载节点 （新版 带 动画的）
function GD.util_addDownLoadingNodeNew(_downLoadNode, _downLoadKey, _processPath)
    if not tolua.isnull(_downLoadNode) and globalDynamicDLControl:checkDownloading(_downLoadKey) then
        -- 遮罩 背景
        local spLockBg = util_createSprite(_processPath)
        if not spLockBg then
            release_print("spLockBg -- " .. _downLoadKey .. " -- util_addDownLoadingNodeNew = " .. (_processPath or ""))
            return nil, nil
        end
        spLockBg:setColor(cc.c3b(0, 0, 0))
        spLockBg:setOpacity(150)
        spLockBg:addTo(_downLoadNode)
        local bgSize = spLockBg:getContentSize()
        local whRatio = bgSize.width / bgSize.height
        local minRadius = 0.2
        local maxRadius = 0.5
        local progTShowSize = minRadius * bgSize.width * 1.6 -- 留0.2的空白间距
        if whRatio > 1 then
            maxRadius = maxRadius * whRatio
            progTShowSize = minRadius * bgSize.height * 1.6
        elseif whRatio < 1 then
            maxRadius = maxRadius / whRatio
        end

        -- 给遮罩添加 扣洞shader
        local shader = cc.GLProgram:createWithFilenames("ProgressTimer/download_circle.vsh", "ProgressTimer/download_circle.fsh")
        local programState = cc.GLProgramState:create(shader)
        programState:setUniformFloat("wh_ratio", whRatio) -- 宽高比
        programState:setUniformFloat("hole_radius", minRadius) -- 扣洞的半径
        spLockBg:setGLProgramState(programState)
        spLockBg.playShowSourceAct = function()
            -- 播放 显示 背景动画
            if tolua.isnull(spLockBg) then
                return
            end

            local updateDt = function()
                if not spLockBg.recordTime then
                    spLockBg.recordTime = 0
                end
                if spLockBg.recordTime >= 1 then
                    spLockBg:removeSelf()
                    return
                end
                spLockBg.recordTime = spLockBg.recordTime + 2/60
                local holeRadius = minRadius + (maxRadius - minRadius) * spLockBg.recordTime / (0.5)
                programState:setUniformFloat("hole_radius", holeRadius ) -- 扣洞的半径
            end
            updateDt()
            util_schedule(spLockBg, updateDt, 2/60)
        end

        -- 进度 转圈
        local percent = globalDynamicDLControl:getPercentForKey(_downLoadKey)
        percent = math.ceil(percent * 100)
        local spProgTimer = util_createSprite("ProgressTimer/bg_circle_mask.png")
        local progTSize = spProgTimer:getContentSize()
        spProgTimer:setColor(cc.c3b(0, 0, 0))
        spProgTimer:setOpacity(150)
        local progTimer = cc.ProgressTimer:create(spProgTimer)
        progTimer:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
        progTimer:setScaleX(-progTShowSize / progTSize.width)
        progTimer:setScaleY(progTShowSize / progTSize.width)
        progTimer:setPercentage(math.min(95, 100 - percent)) -- 镜像反着来 (不要全黑留5%让玩家以为下载)
        progTimer:addTo(_downLoadNode)
        return spLockBg, progTimer
    end

    return nil, nil
end

--link提示 图标晃动
function GD.util_linkTipAction(spLink)
    if not spLink then
        return
    end
    local actionList = {}
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, 5)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, -5)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, 4)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, -4)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, 3)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, -1.5)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, 0)
    actionList[#actionList + 1] = cc.DelayTime:create(5)
    local sequence = cc.Sequence:create(actionList)
    local action = cc.RepeatForever:create(sequence)
    spLink:runAction(action)
end

function GD.setDefaultTextureType(texType, condFunc)
    if (condFunc == nil or condFunc()) then
        if util_isLow_endMachine() then
            print("setDefaultTextureType:", texType)
            if texType == "RGBA4444" then
                cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444)
            elseif texType == "RGBA8888" then
                cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)
            end
        end
    end
end

--[[
    @desc: 获得节点在滚动轴的位置
    author:{author}
    time:2020-07-08 11:09:45
    --@mainclass:
	--@col: 列
	--@row: 行
    @return:
]]
function GD.util_getPosByColAndRow(mainclass, col, row)
    local posX = mainclass.m_SlotNodeW
    local posY = (row - 0.5) * mainclass.m_SlotNodeH
    return cc.p(posX, posY)
end

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function GD.util_getOneGameReelsTarSpPos(mainclass, index)
    local getNodePosByColAndRow = function(row, col)
        local reelNode = mainclass:findChild("sp_reel_" .. (col - 1))

        local posX, posY = reelNode:getPosition()

        posX = posX + mainclass.m_SlotNodeW * 0.5
        posY = posY + (row - 0.5) * mainclass.m_SlotNodeH

        return cc.p(posX, posY)
    end

    local fixPos = mainclass:getRowAndColByPos(index)
    local targSpPos = getNodePosByColAndRow(fixPos.iX, fixPos.iY)

    return targSpPos
end

function GD.util_deep_copytablle(orig)
    local copy
    if type(orig) == "table" then
        --   setmetatable(copy, deep_copy(getmetatable(orig)))
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deep_copy(orig_key)] = deep_copy(orig_value)
        end
    else
        copy = orig
    end
    return copy
end

function GD.util_afterDrawCallBack(callBack)
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    local listener = nil
    local function afterDrawCallBack(eventName)
        eventDispatcher:removeEventListener(listener)
        if callBack ~= nil then
            callBack()
        end
    end
    listener = cc.EventListenerCustom:create("director_after_draw", afterDrawCallBack)
    eventDispatcher:addEventListenerWithFixedPriority(listener, 1)
    return listener
end

function GD.util_getSafeAreaInfoList()
    local ret = {}
    local oriState = 0
    if device.platform == "ios" then
        oriState = xcyy.GameBridgeLua:getOrientationStatus()
        
        local safeAreaInfo = xcyy.GameBridgeLua:getSafeAreaInfo()
        if safeAreaInfo ~= nil and string.len(safeAreaInfo) > 0 then
            --{上边界，下边界，左边界，右边界}
            ret = string.split(safeAreaInfo, ",")
        end
    end
    return ret, oriState
end

function GD.util_getBangScreenHeight()
    local bangHeight = 0
    local areaInfoList, oriState = util_getSafeAreaInfoList()
    if #areaInfoList > 0 then
        local height = 0
        if not oriState then
            if globalData.slotRunData.isPortrait then
                height = tonumber(areaInfoList[1])
            else
                height = tonumber(areaInfoList[3])
            end
        else
            if oriState == "1" or oriState == "2" then
                height = tonumber(areaInfoList[1])
            else
                height = tonumber(areaInfoList[3])
            end
        end
        if height > 0 then
            height = height - 10
        end
        bangHeight = height * 2
    end
    return bangHeight
end

function GD.util_getSaveAreaBottomHeight()
    local bottomHeight = 0
    local areaInfoList = util_getSafeAreaInfoList()
    if #areaInfoList > 0 then
        bottomHeight = tonumber(areaInfoList[2])
    end
    return bottomHeight
end

-- 获取两点之前的角度
function GD.util_getAngleByPos(p1, p2)
    local p = {}
    p.x = p2.x - p1.x
    p.y = p2.y - p1.y

    local r = math.atan2(p.y, p.x) * 180 / math.pi
    print("夹角[-180 - 180]:", r)
    return r
end
-- 向量与y轴的夹角
function GD.util_getDegreesByPos(startPos, endPos)
    local p = {}
    p.x = endPos.x - startPos.x
    p.y = endPos.y - startPos.y

    local r = math.atan2(p.x, p.y) * 180 / math.pi
    -- print("夹角[-180 - 180]:", r)
    return r
end
function GD.getFileExt(path)
    local revPath = string.reverse(path)
    local revExtIndex = string.find(revPath, "%.")
    local resExt = nil
    if revExtIndex ~= -1 then
        resExt = string.sub(path, string.len(path) - revExtIndex + 2)
    end
    return resExt
end

-- 圆上随意的三个点，获得圆心和半径
function GD.util_getCircleInfo(px1, px2, px3)
    local x1, y1, x2, y2, x3, y3
    local a, b, c, g, e, f
    x1 = px1.x
    y1 = px1.y
    x2 = px2.x
    y2 = px2.y
    x3 = px3.x
    y3 = px3.y
    e = 2 * (x2 - x1)
    f = 2 * (y2 - y1)
    g = x2 * x2 - x1 * x1 + y2 * y2 - y1 * y1
    a = 2 * (x3 - x2)
    b = 2 * (y3 - y2)
    c = x3 * x3 - x2 * x2 + y3 * y3 - y2 * y2
    local centerX = (g * b - c * f) / (e * b - a * f)
    local centerY = (a * g - c * e) / (a * f - b * e)
    local circleR = math.sqrt((centerX - x1) * (centerX - x1) + (centerY - y1) * (centerY - y1))
    return cc.p(centerX, centerY), circleR
end

-- 圆点坐标：(x0,y0)
-- 半径：r
-- 角度：a0
-- 则圆上任一点为：（x1,y1）
-- x1   =   x0   +   r   *   cos(ao   *   3.14   /180   )
-- y1   =   y0   +   r   *   sin(ao   *   3.14   /180   )
function GD.util_getCirclePointPos(centerX, centerY, R, angle)
    local x, y = nil, nil
    x = centerX + R * math.cos(angle * 3.14 / 180)
    y = centerY + R * math.sin(angle * 3.14 / 180)
    return x, y
end

--创建进度条
function GD.util_createSlider(bgPath, progressPath, sliderPath, valueChangeFunc)
    local slider = ccui.Slider:create()
    slider:setTouchEnabled(true)
    slider:loadBarTexture(bgPath)
    slider:loadProgressBarTexture(progressPath)
    slider:loadSlidBallTextures(sliderPath)
    --滑动监听
    local function sliderEvent(sender, eventType)
        if eventType == ccui.SliderEventType.percentChanged then
            if valueChangeFunc then
                valueChangeFunc(sender)
            end
        end
    end
    slider:addEventListenerSlider(sliderEvent)
    return slider
end

function GD.addExitListenerNode(parentNode, exitCallBack)
    if parentNode ~= nil then
        local node = cc.Node:create()
        node:registerScriptHandler(
            function(eventType)
                if eventType == "exit" then
                    if exitCallBack ~= nil then
                        exitCallBack()
                    end
                end
            end
        )
        parentNode:addChild(node)
    end
end

function GD.addCleanupListenerNode(parentNode, cleanupCallBack)
    if parentNode ~= nil then
        local node = cc.Node:create()
        node:registerScriptHandler(
            function(eventType)
                if eventType == "cleanup" then
                    if cleanupCallBack ~= nil then
                        cleanupCallBack()
                    end
                end
            end
        )
        parentNode:addChild(node)
    end
end

-- 给继承于 UIWeiget控件的node 添加监听
function GD.util_addNodeClick(node, param)
    assert(node, " !! node is nil !! ")
    assert(node.setTouchEnabled, " !! node.setTouchEnabled is nil !! ")
    node:setTouchEnabled(true)
    local callBack = function(event)
        if event.name == "began" then
            -- node:setScale(0.95)
            if param.beganCallBack then
                param.beganCallBack()
            end
        elseif event.name == "moved" then
            if param.moveCallBack then
                param.moveCallBack()
            end
        elseif event.name == "ended" then
            -- node:setScale(1)
            if param.endCallBack then
                param.endCallBack()
            end
        elseif event.name == "cancelled" then
            if param.cancelCallBack then
                param.cancelCallBack()
            end
        -- node:setScale(1)
        end
    end
    node:onTouch(callBack)
end

--[[
    @desc: 获得X轴居中布局的节点坐标表
    author:{author}
    time:2019-08-20 20:54:57
    --@count: 节点数量
	--@space: 节点间隔距离
	--@centerPos: 中间位置坐标  默认：0，0
    @return: 坐标值的表
]]
function GD.util_layoutCenterPosX(count, space, centerPos)
    local tbPos = {}
    space = space or 120
    centerPos = centerPos or cc.p(0, 0)
    local frontX = centerPos.x - (count - 1) * space / 2
    for i = 1, count do
        tbPos[i] = cc.p(frontX + (i - 1) * space, centerPos.y)
    end
    return tbPos
end

--[[
    @desc: 富文本 支持文字图片  动画
    author:{author}
    time:2020-07-23 15:49:16
    --@param:
    @return:
]]
--demo
-- {
--     list = {
--         {type = 1,color = cc.WHITE,opacity = 255, str = "This color is white. ",font = "Helvetica",fontSize=20,flag=2},
--         {type = 2,color = cc.WHITE,opacity = 255,url = "Activity/MainUI/funIcon/system_2002.png"}
--         {type = 3,color = cc.WHITE,opacity = 255,url = "Activity/MainUI/funIcon/system_2002.png"}
--         {type = 4,color = cc.WHITE,opacity = 255, str = "This color is white. ",fontUrl = "Helvetica"},字体
--     }
--     size = cc.size(120, 100)
--     alignment = 0 --0左  1 居中  2 右对齐
-- }
function GD.util_createRichText(param)
    local richText = ccui.RichText:create()
    richText:ignoreContentAdaptWithSize(false)
    if param.size then
        richText:setContentSize(param.size)
    end
    if param.alignmentH then
        richText:setHorizontalAlignment(param.alignmentH)
    end
    if param.alignmentV then
    -- richText:setVerticalAlignment(param.alignmentV)
    end
    for i = 1, #param.list do
        local temp = param.list[i]
        if temp.type == 1 then -- 文字
            local re1 = ccui.RichElementText:create(i, temp.color, temp.opacity, temp.str, temp.font, temp.fontSize, temp.flag, temp.url or "", temp.outlineColor or cc.WHITE, temp.outlineSize or -1)
            richText:pushBackElement(re1)
        elseif temp.type == 2 then --图片
            local re2 = ccui.RichElementImage:create(i, temp.color, temp.opacity, temp.url)
            richText:pushBackElement(re2)
        elseif temp.type == 3 then --动画
            -- ccs.armatureDataManager.addArmatureFileInfo("res/cocosui/100/100.ExportJson")
            -- local pAr = ccs.Armature.create("100");
            -- pAr.getAnimation().play("Animation1");
            -- local recustom = ccui.RichElementCustomNode:create(1, cc.color.WHITE, 255, pAr)
        elseif temp.type == 4 then
            local txt = ccui.TextBMFont:create()
            txt:setColor(temp.color)
            txt:setFntFile(temp.fontUrl)
            txt:setString(temp.str)
            local recustom = ccui.RichElementCustomNode:create(i, temp.color, 255, txt)
            richText:pushBackElement(recustom)
        end
    end
    return richText
end

--[[--
    使用条件：
        将fnt放在一个带裁切的layer下，layer锚点必须(0, 0.5)，锚点x必须为0
        并且设置fnt的锚点(0, 0.5)和位置(0, 50%)
    swingType: 1:左右摆动 2: 左右摆动字小于框居中
    clipLayer: fntNode的父类裁切面板
    startTime: 显示出来后，延时一段时间再去左右摆动
    moveSpeed: 移动速度，暂定30像素/s
    stayTime: 摆动到最左边或者最右边后，停留的时间
    customSize: 自定义大小
    noFullCenter: 未填满时居中显示
]]
function GD.util_wordSwing(fntNode, swingType, clipLayer, startTime, moveSpeed, stayTime, customSize, noFullCenter)
    if not fntNode then
        return
    end
    fntNode = fntNode.mulNode or fntNode
    fntNode:stopAllActionsByTag(999) -- cxc 2022年06月23日12:11:33 移除旧的在加新的
    local fntSize = customSize or fntNode:getContentSize()
    local fntScale = fntNode:getScale()
    local clipSize = clipLayer:getContentSize()
    local clipScale = clipLayer:getScale()
    if swingType == 1 then
        if fntSize.width * fntScale <= clipSize.width * clipScale then
            if noFullCenter then
                fntNode:setAnchorPoint(0, 0.5)
                fntNode:setPosition(cc.p((clipSize.width - fntSize.width * fntScale) / 2, clipSize.height * 0.5))
            else
                fntNode:setPositionX(0)
            end
            return
        end
    elseif swingType == 2 then
        if fntSize.width * fntScale <= clipSize.width * clipScale then
            fntNode:setPositionX((clipSize.width * clipScale - fntSize.width * fntScale) * 0.5)
            return
        end
    end
    moveSpeed = moveSpeed or 30

    -- 设置fnt的锚点(0, 0.5)和位置(0, 50%)
    fntNode:setAnchorPoint(0, 0.5)
    fntNode:setPosition(cc.p(0, clipSize.height * 0.5))

    local fntCurPos = cc.p(0, clipSize.height * 0.5) -- cc.p(fntNode:getPosition())
    local moveDis = math.ceil(fntSize.width * fntScale - clipSize.width * clipScale)
    local moveTime = math.ceil(moveDis / moveSpeed)

    local startPos = cc.p(fntCurPos.x, fntCurPos.y)
    local endPos = cc.p(fntCurPos.x - moveDis, fntCurPos.y)

    -- 动作
    local startDelay = cc.DelayTime:create(startTime)
    local callFunc =
        cc.CallFunc:create(
        function()
            -- RepeatForever如果放入Sequence中，必须用CallFunc实现，否则不执行
            local moveToLeft = cc.MoveTo:create(moveTime, endPos)
            local moveToRight = cc.MoveTo:create(moveTime, startPos)
            local stayDelay = cc.DelayTime:create(stayTime)
            local repeatFunc = cc.RepeatForever:create(cc.Sequence:create(moveToLeft, stayDelay, moveToRight, stayDelay))
            repeatFunc:setTag(999)
            fntNode:runAction(repeatFunc)
        end
    )
    local seq = cc.Sequence:create(startDelay, callFunc)
    seq:setTag(999)
    fntNode:runAction(seq)
end
--创建buff倒计时显示逻辑
function GD.util_createBuffLeftTime(leftTime, pos)
    local url = "PBRes/ItemUI/item_shop/ShopBuffTime.csb"
    if cc.FileUtils:getInstance():isFileExist(url) then
        local leftTimeCsb = util_createAnimation("PBRes/ItemUI/item_shop/ShopBuffTime.csb")
        if leftTimeCsb then
            local lb_leftTime = leftTimeCsb:findChild("lb_leftTime")
            if lb_leftTime then
                lb_leftTime:setString(leftTime)
            end
            leftTimeCsb:setPosition(pos)
            return leftTimeCsb
        end
    end
    return nil
end
--把秒转为小时分钟秒
function GD.util_switchSecondsToHSM(leftTime)
    local countDown = tonumber(leftTime)
    local result = nil
    if countDown >= 6000 then -- 大于100分钟 显示成小时
        result = math.floor(countDown / 3600 + 0.0001) .. "H"
    elseif countDown >= 60 then --大于1分钟 显示成分钟
        if countDown >= 120 then
            result = math.floor(countDown / 60 + 0.0001) .. "MINS"
        else
            result = math.floor(countDown / 60 + 0.0001) .. "MIN"
        end
    else --小于60秒显示显示成秒
        result = countDown .. "S"
    end
    return result
end

-- 在m_slotParents 数据初始化之后创建轮子遮罩层,
-- 若_parent == nil 在bigreel之下
-- 可以实现特殊图标亮，normal图标暗
function GD.util_createReelMaskColorLayers(_mainClass, _zorder, _c3b, _opacity, _parent)
    local colorLayers = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    for i = 1, #_mainClass.m_slotParents do
        local parentData = _mainClass.m_slotParents[i]

        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = _mainClass:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)

        local node = cc.Node:create()
        if _parent then
            _parent:addChild(node, _zorder)
        else
            parentData.slotParent:getParent():addChild(node, _zorder)
        end

        local slotParentNode_1 = cc.LayerColor:create(_c3b)
        slotParentNode_1:setOpacity(_opacity)
        slotParentNode_1:setContentSize(reelSize.width, reelSize.height)
        slotParentNode_1:setName("Clayer")
        
        if _parent then
            local slotParentPos = cc.p(parentData.slotParent:getPosition())
            local worldPos = parentData.slotParent:getParent():convertToWorldSpace(cc.p(slotParentPos.x + reelSize.width * 0.5, slotParentPos.y))
            local pos = _parent:convertToNodeSpace(worldPos)

            slotParentNode_1:setPosition(pos)
        else
            slotParentNode_1:setPositionX(reelSize.width * 0.5)
        end

        node:addChild(slotParentNode_1)
        table.insert(colorLayers, node)

        node:setVisible(false)
    end

    return colorLayers
end
-- 删除掉无用的搜索路径
function GD.util_removeSearchPath(moduleName)
    local searchPaths = cc.FileUtils:getInstance():getSearchPaths()
    local newSearchPaths = {}
    for i = 1, #searchPaths do
        local value = searchPaths[i]
        if string.find(value, moduleName) == nil then
            newSearchPaths[#newSearchPaths + 1] = value
        end
    end
    ccs.ActionTimelineCache:getInstance():purge()
    cc.FileUtils:getInstance():setSearchPaths(newSearchPaths)
end

--[[
    执行动作列表
]]
function GD.util_runAnimations(aniList)
    local actionManager = require("Levels.ActionManager").new()
    actionManager:runAnimations(aniList)
end

--[[
    转化节点坐标
]]
function GD.util_convertToNodeSpace(targetNode, parentNode)
    if not targetNode or not parentNode then
        return cc.p(0, 0)
    end
    local worldPos = targetNode:getParent():convertToWorldSpace(cc.p(targetNode:getPosition()))
    local pos = parentNode:convertToNodeSpace(worldPos)
    return pos
end
--[[
    @desc: 修改小块的层级
    author:{author}
    time:2020-07-08 11:09:45
    --@mainclass:
	--@_type: symbolType
    @return:
]]
function GD.util_setSymbolToClipReel(_MainClass, _iCol, _iRow, _type, _zorder)
    local targSp = _MainClass:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = _MainClass:getPosReelIdx(_iRow, _iCol)
        local pos = util_getOneGameReelsTarSpPos(_MainClass, index)
        local showOrder = _MainClass:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeSelf(false)
        _MainClass.m_clipParent:addChild(targSp, _zorder + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

--[[
    获取头像管理单例
]]
function GD.util_getHeadManager()
    local headManager = G_GetMgr(G_REF.Avatar)
    return headManager
end

--[[
    设置头像
]]
function GD.util_setHead(_headNode, _fId, _headId, _robotHeadName, _bSquare, _bFBFromCache)
    local parentNodeSize = _headNode:getContentSize()
    -- 默认头像框
    local headId = _headId
    if (not _fId or _fId == "") and (not _headId or tostring(_headId) == "0" or tostring(_headId) == "") then
        headId = 1
    end
    local node, sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(_fId, headId, _robotHeadName, _bSquare, parentNodeSize, _bFBFromCache)
    if node then
        node:setPosition(cc.p(parentNodeSize.width / 2, parentNodeSize.height / 2))
        _headNode:addChild(node)
    end
end

--[[
    倒计时
]]
function GD.util_countDownBySecond(node, time, perFunc, endFunc)
    local delay = 0
    local curTime = 0
    --刷帧
    node:onUpdate(
        function(dt)
            delay = delay + dt
            if delay < 1 then
                return
            end

            delay = 0

            curTime = curTime + 1

            --每秒回调
            if type(perFunc) == "function" then
                perFunc()
            end
            --结束回调
            if curTime >= time then
                node:unscheduleUpdate()
                if type(endFunc) == "function" then
                    endFunc()
                end
            end
        end
    )
end

--[[
    @desc: 修改小块到BaseParent的层级
    author:{author}
    time:2020-07-08 11:09:45
    --@mainclass:
	--@_type: symbolType
    @return:
]]
function GD.util_setClipReelSymbolToBaseParent(_MainClass, _node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = _MainClass:getChangeRespinOrder(_node)
    local posX, posY = _node:getPosition()
    local worldPos = _node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = _MainClass:getReelParent(_node.p_cloumnIndex):convertToNodeSpace(worldPos)
    _node.m_symbolTag = SYMBOL_NODE_TAG
    _node.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
    _node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    _node.m_isLastSymbol = false
    _node.m_bRunEndTarge = false
    local columnData = _MainClass.m_reelColDatas[_node.p_cloumnIndex]
    _node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    _MainClass:changeBaseParent(_node)
    _node:setPosition(nodePos)
    return _node
end

-- textfield 转换 editbox
function GD.util_convertTextFiledToEditBox(_textField, _bgImgName, _handlerFunc, _inputModel)
    if tolua.isnull(_textField) then
        return
    end
    _textField:setVisible(false)

    _bgImgName = _bgImgName or "UserInformation/ui/nil.png"

    local placeHolder = _textField:getPlaceHolder()
    local placeHolderColor = _textField:getPlaceHolderColor()
    local size = _textField:getContentSize()
    local parent = _textField:getParent()
    local fontSize = _textField:getFontSize()
    local fontName = _textField:getFontName()
    -- local fontColor = _textField:getTextColor()
    local maxLength = _textField:getMaxLength()

    local editBox = cc.EditBox:create(size, _bgImgName)
    editBox:addTo(parent)
    editBox:setPosition(_textField:getPosition())
    editBox:setAnchorPoint(_textField:getAnchorPoint())
    editBox:setPlaceHolder(placeHolder)
    editBox:setPlaceholderFontColor(placeHolderColor)
    editBox:setPlaceholderFontSize(fontSize)

    editBox:setFontSize(fontSize)
    editBox:setFontName(fontName)
    editBox:setFontColor(cc.c3b(255, 255, 255))
    if maxLength > 0 then
        editBox:setMaxLength(maxLength)
    end

    editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    editBox:setInputFlag(cc.EDITBOX_INPUT_FLAG_SENSITIVE)
    if not _inputModel then
        _inputModel = cc.EDITBOX_INPUT_MODE_SINGLELINE
    end
    editBox:setInputMode(_inputModel)

    if _handlerFunc then
        editBox:registerScriptEditBoxHandler(_handlerFunc)
    end

    return editBox
end

--修复热更异常，删除本地热更目录src和res，并重置包体版本号
function GD.util_fixHotUpdate(exitFlag)
    local callback = function()
        local writePath = device.writablePath
        local srcWritePath = writePath .. "src/"
        local resWritePath = writePath .. "res/"

        local isRemoved = false
        if cc.FileUtils:getInstance():isDirectoryExist(srcWritePath) then
            cc.FileUtils:getInstance():removeDirectory(srcWritePath)
            isRemoved = true
        end

        if cc.FileUtils:getInstance():isDirectoryExist(resWritePath) then
            cc.FileUtils:getInstance():removeDirectory(resWritePath)
            isRemoved = true
        end

        cc.FileUtils:getInstance():purgeCachedEntries()

        if isRemoved then
            if not gLobalRemoveDir then
                GD.gLobalRemoveDir = ""
            end

            gLobalRemoveDir = gLobalRemoveDir .. ("util_fixHotUpdate|" .. util_getUpdateVersionCode() .. "|")
        end

        local packageUpdateVersion = xcyy.GameBridgeLua:getPackageUpdateVersion()
        util_saveUpdateVersionCode(packageUpdateVersion)
        gLobalDataManager:delValueByField("ReStartGameStatus")
    end

    if exitFlag then
        callback()
        os.exit(0)
    else
        util_restartGame(callback)
    end
end

--[[
    创建弧形星星队列[从左到右]
    TODO:所有的node大小都必须一样，否则此方法需要优化不同尺寸的情况
    公式：
    已知圆心坐标，半径，角度，求圆上的点坐标
    x1 = x + _radius * cos(_angle * math.pi / 180)
    y1 = y + _radius * sin(_angle * math.pi / 180)    
]]
function GD.util_alignCircle(_nodeList, _centerX, _centerY, _radius, _intervalAngle, _centerAngle)
    if not _nodeList or (_nodeList and #_nodeList == 0) then
        return
    end
    -- 圆心 (_centerX, _centerY)
    -- 半径 _radius
    -- 夹角 _intervalAngle [控制node之间的距离]
    -- 居中角度 _centerAngle [如果中间node在圆顶那么角度是90，如果中间node在圆最右那么角度是0]
    local _nodeNum = #_nodeList
    local startAngle = _centerAngle + (_nodeNum - 1) * _intervalAngle / 2
    local startRotate = -1 * (_nodeNum - 1) * _intervalAngle / 2
    for i = 1, #_nodeList do
        local _node = _nodeList[i]
        local nodeAngle = startAngle - _intervalAngle * (i - 1)
        local radian = math.rad(nodeAngle)
        local x1 = _centerX + _radius * math.cos(radian)
        local y1 = _centerY + _radius * math.sin(radian)
        _node:setPosition(x1, y1)
        local nodeRotate = startRotate + _intervalAngle * (i - 1)
        _node:setRotation(nodeRotate)
    end
end

--[[--
    阿拉伯数字 英文缩写
]]
function GD.util_switchNumber(_number, _isSpace)
    -- if _isSpace then
    -- end
    local switchStr = ""
    if _number == 11 or _number == 12 or _number == 13 then
        switchStr = _number .. "TH"
    else
        local _lastNum = string.sub(tostring(_number), -1)
        _lastNum = tonumber(_lastNum)
        if _lastNum == 1 then
            switchStr = _number .. "ST"
        elseif _lastNum == 2 then
            switchStr = _number .. "ND"
        elseif _lastNum == 3 then
            switchStr = _number .. "RD"
        else
            switchStr = _number .. "TH"
        end
    end
    return switchStr
end

-- 获得纹理宽高
function GD.getSpriteWH(path)
    local sprite = cc.Sprite:create(path)
    if not sprite then
        local a = 0
    end
    local texture = sprite:getTexture()
    return texture:getPixelsWide(), texture:getPixelsHigh()
end

--[[
    创建一个刮刮乐图层

    参数说明
    {
        sp_reward,      --需要刮出来的奖励精灵
        sp_bg,          --需要刮开的图层
        size,           --需要刮开的区域大小
        pos,            --涂层位置
        onTouch,        --触摸回调
        startFunc,      --开始刮开
        callBack        --刮开结束回调
    }
]]
function GD.util_createGuaGuaLeLayer(params)
    local sp_reward = params.sp_reward --需要刮出来的奖励精灵
    local sp_bg = params.sp_bg --需要刮开的图层
    local rewardSize = params.size --需要刮开的区域大小
    local callBack = params.callBack
    local pos = params.pos
    if not pos then
        pos = cc.p(display.width / 2, display.height / 2)
    end
    if not rewardSize then
        local size = sp_bg:getContentSize()
        rewardSize = CCSizeMake(size.width / 2 * sp_bg:getScaleX(), size.height / 2 * sp_bg:getScaleY())
    end

    --设置需要刮开的关键区域点
    local pointsInfo = {
        {
            isTrigger = false,
            point = cc.p(pos.x - rewardSize.width / 2, pos.y - rewardSize.height / 2)
        },
        {
            isTrigger = false,
            point = cc.p(pos.x + rewardSize.width / 2, pos.y - rewardSize.height / 2)
        },
        {
            isTrigger = false,
            point = cc.p(pos.x, pos.y)
        },
        {
            isTrigger = false,
            point = cc.p(pos.x - rewardSize.width / 2, pos.y + rewardSize.height / 2)
        },
        {
            isTrigger = false,
            point = cc.p(pos.x + rewardSize.width / 2, pos.y + rewardSize.height / 2)
        }
    }

    local layer = cc.Layer:create()
    layer:registerScriptHandler(
        function(tag)
            if "enter" == tag then
            elseif "exit" == tag then
                if not tolua.isnull(layer.m_brush) then
                    layer.m_brush:release()
                end
            end
        end
    )

    sp_reward:setAnchorPoint(cc.p(0.5, 0.5))
    sp_reward:setPosition(pos)
    layer:addChild(sp_reward)

    --创建笔刷
    -- local pinfo = cc.AutoPolygon:generatePolygon("Card_Icon/card_wild.png")
    -- local brush = cc.Sprite:create(pinfo)
    local brush = cc.DrawNode:create()
    brush:drawSolidCircle(cc.p(0, 0), 30, 0, 47, cc.c4f(1, 0, 0, 0))
    -- layer:addChild(brush)
    layer.m_brush = brush
    brush:retain()

    local render = cc.RenderTexture:create(display.width, display.height)
    render:setPosition(cc.p(display.width / 2, display.height / 2))
    layer:addChild(render)
    -- render:retain()

    sp_bg:setAnchorPoint(cc.p(0.5, 0.5))
    sp_bg:setPosition(pos)

    local bgSize = sp_bg:getContentSize()
    layer.m_bgSize = bgSize
    layer.m_pos = pos

    render:begin()
    sp_bg:visit()
    render:endToLua()

    layer.touchFunc = function(obj, event)
        if type(params.onTouch) == "function" then
            params.onTouch(obj, event)
        end

        if event.name == "moved" or event.name == "began" then
            --安全判定
            if not brush then
                release_print("GuaGuaLe brush is nil")
                if type(callBack) == "function" then
                    render:setVisible(false)
                    callBack()
                end
                return
            end
            brush:setPosition(event.x, event.y)
            print("刷子位置:x = " .. event.x .. ",y = " .. event.y)

            if pos.x - bgSize.width / 2 <= event.x and pos.x + bgSize.width / 2 >= event.x and pos.y - bgSize.height / 2 <= event.y and pos.y + bgSize.height / 2 >= event.y then
                if type(params.startFunc) == "function" then
                    params.startFunc()
                    params.startFunc = nil
                end
            end

            --判断关键点是否被刮开
            for key, pointInfo in ipairs(pointsInfo) do
                if not pointInfo.isTrigger and pointInfo.point.x >= event.x - 30 and pointInfo.point.x <= event.x + 30 and pointInfo.point.y >= event.y - 30 and pointInfo.point.y <= event.y + 30 then
                    pointInfo.isTrigger = true
                    print("关键点" .. key .. "被刮开")
                end
            end
            -- 设置混合模式
            local blendFunc = {GL_ONE, GL_ZERO}
            brush:setBlendFunc(blendFunc)

            -- 将橡皮擦的像素渲染到画布上，与原来的像素进行混合
            render:begin()
            brush:visit()
            render:endToLua()
        elseif event.name == "ended" then
            --判断是否大部分被刮开
            local triggerCount = 0
            for key, pointInfo in ipairs(pointsInfo) do
                if pointInfo.isTrigger then
                    triggerCount = triggerCount + 1
                end
            end
            --刮开的关键点大于3个且中心点被刮开,直接开奖
            if triggerCount >= 3 and pointsInfo[3].isTrigger then
                if type(callBack) == "function" then
                    print("刮奖结束")
                    render:setVisible(false)
                    callBack()
                end
            end
        end
        return true
    end

    layer:onTouch(handler(nil, layer.touchFunc))

    return layer
end

--[[
    根据路径移动

    routeList = { --路径列表
        {
            startPos,   --起点位置
            endPos,     --终点位置
            speed,      --移动速度
            spcialAct,  --特殊动作
            isSlowly,   --是否慢放
            slowlyRate, --慢放比率
            delayFuncTime,--开始回调后延迟一定时间调用延时回调
            startFunc,  --开始移动前回调
            endFunc,    --结束回调
            delayFunc,  --延时回调
        }
    }
]]
function GD.util_moveByRouteList(actionNode, routeList)
    if not routeList or #routeList == 0 then
        return
    end

    local actionList = {}
    for index = 1, #routeList do
        local data = routeList[index]

        local startAction =
            cc.CallFunc:create(
            function()
                --慢放
                if data.isSlowly then
                    local slowlyRate = data.slowlyRate or 0.07
                    cc.Director:getInstance():getScheduler():setTimeScale(globalData.timeScale * slowlyRate)
                end

                if type(data.startFunc) == "function" then
                    data.startFunc()
                end
            end
        )
        actionList[#actionList + 1] = startAction

        local spawnList = {}

        if data.delayFuncTime then
            spawnList[#spawnList + 1] =
                cc.Sequence:create(
                {
                    cc.DelayTime:create(data.delayFuncTime),
                    cc.CallFunc:create(
                        function()
                            if type(data.delayFunc) then
                                data.delayFunc()
                            end
                        end
                    )
                }
            )
        end

        --特殊动作
        if data.spcialAct then
            spawnList[#spawnList + 1] = data.spcialAct
        else
            local time = 0.2
            --如果传入了速度则计算移动时间
            if data.speed then
                local distance = cc.pGetDistance(data.startPos, data.endPos)
                time = distance / data.speed
            end
            local moveTo = cc.MoveTo:create(time, data.endPos)
            spawnList[#spawnList + 1] = moveTo
        end

        actionList[#actionList + 1] = cc.Spawn:create(spawnList)

        local endAction =
            cc.CallFunc:create(
            function()
                cc.Director:getInstance():getScheduler():setTimeScale(globalData.timeScale)
                if type(data.endFunc) == "function" then
                    data.endFunc()
                end
            end
        )
        actionList[#actionList + 1] = endAction
    end

    local seq = cc.Sequence:create(actionList)

    actionNode:runAction(seq)
end

--- 递归设置symbol小块节点引用计数
-- _isRecursion 是否递归
function GD.util_resetChildReferenceCount(_node)
    if tolua.isnull(_node) then
        return
    end

    local relNodeFunc = function(_relNode)
        local count = _relNode:getReferenceCountEx()
        if count > 1 then
            if type(_relNode.isSlotsNode) == "function" and _relNode:isSlotsNode() then
                if _relNode.clear ~= nil then
                    _relNode:clear()
                end
                _relNode:stopAllActions()
                _relNode:release()
            end
        end
    end

    local children = _node:getChildren()
    -- util_printLog("当前节点上子节点数" .. #children, true)
    for k, vNode in pairs(children) do
        relNodeFunc(vNode)
    end

    relNodeFunc(_node)
end

function GD.util_fadeOutNode(node, time, callBack)
    for k, v in ipairs(node:getChildren()) do
        util_fadeOutNode(v, time, nil)
    end
    local actionList = {}
    local fadeout = cc.FadeOut:create(time)
    table.insert(actionList, fadeout)
    if callBack ~= nil then
        table.insert(actionList, cc.CallFunc:create(callBack))
    end
    node:runAction(cc.Sequence:create(actionList))
end

-- 获取当前是否已经跨天 需要传入要判断的时间
function GD.util_getTimeIsNewDay(_oldTime)
    local newTime = globalData.userRunData.p_serverTime
    local oldSecs = (math.floor(_oldTime / 1000))
    local newSecs = (math.floor(newTime / 1000))
    -- 服务器时间戳转本地时间
    local oldTM = os.date("!*t", (oldSecs - 8 * 3600))
    local newTM = os.date("!*t", (newSecs - 8 * 3600))

    if oldTM.day ~= newTM.day then
        return true
    end
    return false
end

--[[
    @desc:  UIEditbox_ios 触发的键盘 返回的键盘rect。 
            坐标使用的是ios的坐标系
        ----------------------- 数值 test（pad） -----------------------
        1. 正常show   0.25   （0 768）(1024 0) -> (0 360) (1024 408)
        1. 正常hide   0.25    (0 360) (1024 408) ->（0 768）(1024 408)
        2. 最小show   0.25    (0 0) (0 0) -> (274 340) (334 355.5)
        2. 最小move   0.25    (274 340.5) (334 355.5) - > (0 0) (0 0)
        2. 最小hide   0.25    (123 390) (334 308) - > (0 0) (0 0)
        3. 分屏show   0.25 （0 768 1024 353） ——> (0 370 1024 271)
        3. 分屏hide   0.25 （0 370 1024 271） ——> (0 768 1024 271)
        4. 正常 to 最小   0  （0 0 0 0） -》 （123.5 391 334 308）
        4. 最小 to 正常   0  （0 0 0 0） -》 (0 360) (1024 408)
        5. 正常 to 分屏   0  （0 0 0 0） -》 （0 641 1024 271）
        5. 分屏 to 正常   0  （0 0 0 0） -》 （0 360 1024 408）
        ----------------------- 数值 test -----------------------
]]
function GD.nativeCallLuaFuncKeyboardChangeFrame(_jsonStr)
    if type(_jsonStr) ~= "string" then
        return
    end
    GD.KeyBoardChangeFrameInfo = json.decode(_jsonStr)

    local curScene = display:getRunningScene()
    local lb = curScene:getChildByName("keyBoardDDlabel")
    if not lb then
        return
    end

    -- 测试文本 宽度
    local lbWidth = display.width
    if KeyBoardChangeFrameInfo["end"].width > 0 then
        lbWidth = KeyBoardChangeFrameInfo["end"].width
    elseif KeyBoardChangeFrameInfo["begin"].width > 0 then
        lbWidth = KeyBoardChangeFrameInfo["begin"].width
    end
    util_AutoLine(lb, _jsonStr, lbWidth)

    -- 测试文本 pos
    if KeyBoardChangeFrameInfo["end"].width == 0 and KeyBoardChangeFrameInfo["end"].height == 0 then
        -- 2. 最小move  2. 最小hide
        return
    end
    local posY = display.height - KeyBoardChangeFrameInfo["end"].y
    if KeyBoardChangeFrameInfo["end"].width >= display.width and math.abs(posY - KeyBoardChangeFrameInfo["end"].height) > 10 then
        -- 正常 to 分屏   0  （0 0 0 0） -》 （0 641 1024 271）
        posY = posY + KeyBoardChangeFrameInfo["end"].height
    end
    lb:setPosition(cc.p(KeyBoardChangeFrameInfo["end"].x, posY))
end

--[[
    @desc: ios 键盘显示隐藏  节点移动
    --@_duration: 键盘动画 时间
	--@_distance: 键盘移动距离 Y
	--@_moveNode: 移动的节点
	--@_sourceY:  移动的节点 原始posY
]]
function GD.util_keyboardChangeMove(_duration, _distance, _moveNode, _sourceY)
    if not _duration or not _distance then
        return
    end

    local viewNode = _moveNode or display:getRunningScene()
    viewNode:stopActionByTag(99)
    local posY = _sourceY or 0
    if _distance > 0 then
        posY = posY + _distance
    end

    local updateScenePosY = function()
        viewNode:setPositionY(posY)
    end
    if _duration > 0 then
        local moveTo = cc.MoveTo:create(_duration, cc.p(0, posY))
        local callFunc = cc.CallFunc:create(updateScenePosY)
        local sequence = cc.Sequence:create(moveTo, callFunc)
        sequence:setTag(99)
        viewNode:runAction(sequence)
    else
        updateScenePosY()
    end

    GD.KeyBoardChangeFrameInfo = nil
end

-- 字体底/暗部阴影
function GD.util_enableLabelBottomShadow(_label, _bottomShadowColor, _offsetSize)
    local bFlag = false
    if device.platform == "ios" then
        bFlag = util_isSupportVersion("1.6.9")
    elseif device.platform == "android" then
        bFlag = util_isSupportVersion("1.6.1")
    elseif device.platform == "mac" then
        bFlag = util_isSupportVersion("1.6.9")
    end

    if not _label or not _bottomShadowColor then
        bFlag = false
    end

    if bFlag then
        local offsetSize = _offsetSize or cc.size(0, -1)
        _label:enableBottomShadow(_bottomShadowColor, offsetSize)
    end
end

-- 字体开启渐变（底部颜色，顶部颜色）
function GD.util_enableLabelGradientColor(_label, _bottomColor, _topColor)
    local bFlag = false
    if device.platform == "ios" then
        bFlag = util_isSupportVersion("1.6.9")
    elseif device.platform == "android" then
        bFlag = util_isSupportVersion("1.6.1")
    elseif device.platform == "mac" then
        bFlag = util_isSupportVersion("1.6.9")
    end

    if not _label or not _bottomColor or not _topColor then
        bFlag = false
    end

    if bFlag then
        _label:enableGradientColor(_bottomColor, _topColor)
    end
end

-- 默认颜色渐变
function GD.util_LabelDefaultGradientColor(_label)
    local bFlag = false
    if device.platform == "ios" then
        bFlag = util_isSupportVersion("1.6.9")
    elseif device.platform == "android" then
        bFlag = util_isSupportVersion("1.6.1")
    elseif device.platform == "mac" then
        bFlag = util_isSupportVersion("1.6.9")
    end

    if not _label then
        bFlag = false
    end

    if bFlag then
        _label:enableShadow(cc.c3b(180, 64, 100), cc.size(0, -2))
        _label:enableGradientColor(cc.c3b(255, 198, 0), cc.c3b(255, 252, 31))
        _label:enableBottomShadow(cc.c3b(104, 27, 131), cc.size(0, -1))
    end
end

-- 字体禁用渐变
function GD.util_disableLabelGradientColor(_label)
    local bFlag = false
    if device.platform == "ios" then
        bFlag = util_isSupportVersion("1.6.9")
    elseif device.platform == "android" then
        bFlag = util_isSupportVersion("1.6.1")
    elseif device.platform == "mac" then
        bFlag = util_isSupportVersion("1.6.9")
    end

    if not _label then
        bFlag = false
    end

    if bFlag then
        _label:disableEffect(LABEL_EFFECT.SHADOW)
        _label:disableEffect(LABEL_EFFECT.BOTTOMSHADOW)
        _label:disableGradientColor()
    end
end

--[[
    @desc: 将传入的字符串金币数裁剪掉小数点 "." 重新拼接
    author:csc
    time:2022-01-24 14:37:50
    --@_str: 金币数 
    @return:例如  6.4M -> 6M 
]]
function GD.util_strSplitMoneyUnit(_str)
    local unit = string.match(_str, "[A-Za-z]")
    local splitStr = string.split(_str, ".")
    if #splitStr <= 1 then
        return _str
    end
    return splitStr[1] .. unit
end

--[[
    @desc: 判断当前设备分辨率是否为Pad屏
    author:ZKK 
]]
function GD.util_isPadDevice()
    local result = false
    local rate = display.width / display.height
    if globalData.slotRunData.isPortrait then
        rate = display.height / display.width
    end
    if rate < 1.34 then
        result = true
    end
    return result
end

--[[
    @desc: 判断当前设备是否为低端机
    author:ZKK 
]]
function GD.util_isLow_endMachine(isAds)
    local _limitMem = util_lowMemLimit(isAds)
    if _limitMem > 0 then
        return xcyy.GameBridgeLua:getDeviceMemory() <= _limitMem
    else
        return false
    end
end

-- 低内存设备阈值
function GD.util_lowMemLimit(isAds)
    local limit = 0
    local platform = device.platform
    if platform == "android" then
        if isAds then
            limit = 2048
        else
            limit = 3072
        end
    elseif platform == "ios" then
        if isAds then
            limit = 1536
        else
            limit = 2048
        end
    end
    return limit
end

--[[
    @desc: 时间格式转为时间戳
    author:xhb
]]
function GD.util_dataToTimeStamp(dataStr)
    local result = -1
    local tempTable = {}

    if dataStr == nil then
        print("传递进来的日期时间参数不合法")
    elseif type(dataStr) == "string" then
        dataStr = (dataStr:gsub("^%s*(.-)%s*$", "%1"))
        for v in string.gmatch(dataStr, "%d+") do
            tempTable[#tempTable + 1] = v
        end
    elseif type(dataStr) == "table" then
        tempTable = dataStr
    else
        print("传递进来的日期时间参数不合法")
    end

    result =
        os.time(
        {
            day = tonumber(tempTable[3]),
            month = tonumber(tempTable[2]),
            year = tonumber(tempTable[1]),
            hour = tonumber(tempTable[4]),
            min = tonumber(tempTable[5]),
            sec = tonumber(tempTable[6])
        }
    )
    return result
end

--[[
    @desc: 移动根节点动作(拉伸镜头效果)
    params = {
        moveNode = ,--要移动节点
        targetNode = ,--目标位置节点
        parentNode = ,--移动节点的父节点
        time = ,--移动时间
        scale = ,--缩放倍数
        actionType = ,  --动作类型(由慢至快，再由快至慢) 1正弦变化 2指数变化 3EaseCubicActionOut 默认正弦变化
        func = ,--回调函数
    }
]]
function GD.util_moveRootNodeAction(params)
    local moveNode = params.moveNode
    local targetNode = params.targetNode
    local parentNode = params.parentNode
    local time = params.time
    local scale = params.scale
    local actionType = params.actionType or 1
    local func = params.func

    local curScale = moveNode:getScale()

    --当前位置
    local curPos = cc.p(moveNode:getPosition())
    --目标位置
    local targetPos = util_convertToNodeSpace(targetNode, parentNode)

    local endPos = cc.p(-targetPos.x, -targetPos.y)
    if curScale ~= scale then
        endPos.x = endPos.x * scale
        endPos.y = endPos.y * scale
    end
    if endPos.x + curPos.x > display.width * scale / 2 then
        endPos.x = display.width * scale / 2 - curPos.x
    elseif endPos.x + curPos.x < -display.width * scale / 2 then
        endPos.x = -display.width * scale / 2 - curPos.x
    end

    if endPos.y + curPos.y > display.height * scale / 2 then
        endPos.y = display.height * scale / 2 - curPos.y
    elseif endPos.y + curPos.y < -display.height * scale / 2 then
        endPos.y = -display.height * scale / 2 - curPos.y
    end

    local spawn =
        cc.Spawn:create(
        {
            cc.MoveBy:create(time, endPos),
            cc.ScaleTo:create(time, scale)
        }
    )
    moveNode:stopAllActions()

    local action
    if actionType == 1 then
        action = cc.EaseSineInOut:create(spawn)
    elseif actionType == 2 then
        action = cc.EaseExponentialInOut:create(spawn)
    else
        action = cc.EaseCubicActionOut:create(spawn)
    end

    local seq =
        cc.Sequence:create(
        action,
        cc.CallFunc:create(
            function()
                if type(func) == "function" then
                    func()
                end
            end
        )
    )
    moveNode:runAction(seq)
end

--[[
    @desc: 裁切圆形头像
    author:xhb 
]]
function GD.util_CllipNode(_sp, _size, _bClip)
    if _bClip == nil then
        _bClip = true
    end

    local shader = cc.GLProgram:createWithFilenames("UserInformation/cube_map2.vsh", "UserInformation/cube_map2.fsh")
    local programState = cc.GLProgramState:create(shader)
    local size1 = cc.size(_size.width / 2, _size.height / 2)
    programState:setUniformVec2("resolution", cc.p(_size.width, _size.height))
    programState:setUniformVec2("circleCenter", cc.p(size1.width, size1.height))
    programState:setUniformFloat("radius", math.min(_size.width, _size.height) / 2)
    programState:setUniformInt("clipFlag", _bClip and 1 or 0)
    _sp:setGLProgramState(programState)
end


--[[
    @desc: 裁切圆形头像
    author:xhb 
]]
function GD.util_CllipNodeNew(_sp,_size,_bClip,_index)
    if _bClip == nil then
        _bClip = false
    end

    local spf = _sp:getSpriteFrame()
    
    local shader = cc.GLProgram:createWithFilenames("UserInformation/cube_map.vsh", "UserInformation/cube_map.fsh")
    local programState = cc.GLProgramState:create(shader)
    local size1 = cc.size(_size.width/2,_size.height/2)
    programState:setUniformVec2("resolution", cc.p(_size.width,_size.height))
    programState:setUniformVec2("circleCenter", cc.p(size1.width,size1.height))
    programState:setUniformFloat("radius", math.min(_size.width, _size.height) / 2)
    programState:setUniformInt("clipFlag", _bClip and 1 or 0)

    --散图不要动坐标
    if _bClip then
        local bSize,cSize,origin = util_GetPlist("userinfo/ui_head/UserHeadPlist.plist","userinfo/ui_head/UserInfo_touxiang_".._index..".png")
        local min, max = util_Caculate(bSize,cSize,origin)
        programState:setUniformVec4("u_uvMin", min)
        programState:setUniformVec4("u_uvMax", max)
    end
   

    _sp:setGLProgramState(programState)


end

function GD.util_Caculate(bSize,cSize,origin )
    local minx, maxx, miny, maxy


    minx = origin.x/bSize.x
    maxx = (origin.x+cSize.x)/bSize.x
    maxy = (origin.y + cSize.y)/bSize.y
    miny = origin.y/bSize.y
    return cc.p(minx, miny), cc.p(maxx, maxy)

end

--读取plist文件 _path plist路径，key 
function GD.util_GetPlist(_path,_pngname)
    local full_map = nil
    if gLobalPlistMap and gLobalPlistMap[_path] ~= nil then
        full_map = gLobalPlistMap[_path]
    else
        local full_path = cc.FileUtils:getInstance():fullPathForFilename(_path)
        full_map = cc.FileUtils:getInstance():getValueMapFromFile(full_path)
        gLobalPlistMap[_path] = full_map
    end
    local bSize = cc.p(full_map["texture"].width,full_map["texture"].height)
    local frames_map = full_map["frames"]
    --dump(frames_map)
    local temp_str = frames_map[_pngname]["frame"]
    temp_str = string.gsub(temp_str,"{","[")
    temp_str = string.gsub(temp_str,"}","]")
    local temp_data = cjson.decode(temp_str)
    local cSize = cc.p(temp_data[2][1],temp_data[2][2])
    local origin = cc.p(temp_data[1][1],temp_data[1][2])
    return bSize,cSize,origin
end

function GD.util_createRewardBgEffect()
    local effectUI = util_createAnimation("CommonEffect/csb/CommonEffect_xzg1.csb")
    if effectUI then
        util_setCascadeOpacityEnabledRescursion(effectUI, true)
        return effectUI
    end
end

--震动
function GD.util_shakeNode(_shakeNode,_sx,_sy,_time)
    local changePosY = _sx
    local changePosX = _sy
    local actionList = {}
    local oldPos = cc.p(_shakeNode:getPosition())
    local count = _time * 10/2
    for i = 1, count do
        actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
        actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
        actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x - changePosX, oldPos.y + changePosY))
        actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
        actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
        actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
    end

    local seq = cc.Sequence:create(actionList)
    _shakeNode:runAction(seq)
end


--
-- 测试：跳过大厅流程直接进入指定关卡
--
function GD.util_TestGotoLevel()
    if DEBUG == 2 and CC_IS_TEST_LEVEL_ID  then
        gLobalViewManager:lobbyGotoLevelSceneByLevelId(CC_IS_TEST_LEVEL_ID)
    end
end


-- gridNode
--[[
    @desc: 
    author:{author}
    time:2023-06-29 11:00:41
    --@_grid3d:cc.Grid3D
	--@pos1:cc.p(x,y)
	--@pos2:vec3_table {x=,y=,z=} 
    @return: 是否执行成功
]]
function GD.util_Grid3D_setVertex(_grid3d,_pos1,_pos2)
    if _grid3d.setVertex then
        _grid3d:setVertex(_pos1 , _pos2);
    end
end
--[[
    @desc: 
    author:{author}
    time:2023-06-29 11:03:58
    --@_grid3d:cc.Grid3D
	--@pos1: cc.p(x,y) 
    @return:vec3_table {x=,y=,z=} 
]]
function GD.util_Grid3D_getVertex(_grid3d,_pos1)
    if _grid3d.getVertex then
        return _grid3d:getVertex(_pos1);
    else
        -- 版本兼容,返回默认值
        return {["x"]=0,["y"]=0,["z"]=0} 
    end
end

--[[
    @desc: 
    author:{author}
    time:2023-06-29 11:02:43
    --@_grid3d:cc.Grid3D
	--@pos1: cc.p(x,y)
    @return:vec3_table {x=,y=,z=} 
]]
function GD.util_Grid3D_getOriginalVertex(_grid3d,_pos1)
    if _grid3d.getOriginalVertex then
        return _grid3d:getOriginalVertex(_pos1);
    else
        -- 版本兼容,返回默认值
        return {["x"]=0,["y"]=0,["z"]=0} 
    end 
end

function GD.util_isNaN(_number)
    if _number ~= nil and type(_number) == "number" and _number ~= _number then
        return true
    end
    return false
end
--[[
    暂停spine动画的方法，对应恢复在util_resumStoppingSpine
    _spine : 需要暂停的spine
    _callBack:触发暂停后的回调
    _actionName : 指定暂停的动画名字，如果不传，调用该函数，表示里面暂停；
                   如果传入，需要再传入_frame参数表示多少帧暂停，以每帧1/30s为基准
    _frame : 执行动画_actionName 之后多少帧暂停
]]--
function GD.util_stopSpineAtFrame(_spine,_callBack,_actionName,_frame)
    if not _spine or tolua.isnull(_spine) then
        return
    end

    if _actionName and _spine:findAnimation(_actionName) then
        if not _frame or _frame <= 0 then
            return
        end

        local actionNameEndTime = _spine:getAnimationDurationTime(_actionName)
        local time = _frame / 30
        if time > actionNameEndTime then
            time = actionNameEndTime - 0.01
        end
        performWithDelay(_spine,function()
            if _spine and not tolua.isnull(_spine) then
                _spine:setTimeScale(0)
            end
            if _callBack then
                _callBack()
            end
        end,time)
    else
        _spine:setTimeScale(0)
        if _callBack then
            _callBack()
        end
    end
end

--恢复暂停spine的方法，_timeScale默认不传
function GD.util_resumStoppingSpine(_spine,_timeScale)
    if not _spine or tolua.isnull(_spine) then
        return
    end

    if _spine:getTimeScale() ~= 0 then
        return
    end
    local timeScale = _timeScale or 1
    _spine:setTimeScale(timeScale)
end

--[[跳到指定帧执行动画
    --该方法涉及到强制渲染，避免每帧调用
    _spine spine
    _actionName 动画名字
    _frame 指定跳到的帧
    _visitParams : 非常关键，因为要强制刷新，可能会出现节点层级问题，一般传{self}，除非还不正确，就按照spine加的父节点依次传入
    _isloop : 是否循环
    _callBack : 执行完动画后的回调，该方法在循环中没用
]]--
function GD.util_playSpineActionByFrame(_spine,_actionName,_frame,_visitParams,_isloop,_callBack)
    if not _spine or tolua.isnull(_spine) then
        return
    end

    if _actionName and _spine:findAnimation(_actionName) then
        local frameTime = _frame / 30
        local actionNameEndTime = _spine:getAnimationDurationTime(_actionName)
        if frameTime >= actionNameEndTime then
            frameTime = actionNameEndTime
        elseif frameTime <= 0 then
            frameTime = 1 / 30
        end
        util_spinePlay(_spine,_actionName,_isloop)
        if not _isloop then
            util_spineEndCallFunc(_spine,_actionName,function()
                if _callBack then
                    _callBack()
                end
            end)
        end
        _spine:update(frameTime)
        _spine:visit()
        for i = 1,#_visitParams do
            if _visitParams[i] and not tolua.isnull(_visitParams[i]) then
                _visitParams[i]:visit()
            end
        end
    end
end

--随机排序
function GD.util_randomTable(tab)
    if type(tab) ~= "table" then
        return
    end
    local resultTab = {}
    while #tab > 0 do
        local randIdx = math.random(1,#tab)
        if tab[randIdx] ~= nil then
            local value = tab[randIdx]
            table.insert(resultTab,value)
            table.remove(tab,randIdx)
        end
    end
    return resultTab
end

--[[
    图片模糊
    _sp:要模糊的精灵
    _blurRadius:半径 - 默认1
    _sampleNum:步长 - 默认2
    _resolution:范围 - 默认100，100
]]--
function GD.util_spriteBlur(_sp, _blurRadius, _sampleNum, _resolution)
    if not _sp then
        return
    end
    
    local vertShaderByteArray = [[
        attribute vec4 a_position; 
        attribute vec2 a_texCoord; 
        attribute vec4 a_color; 
        #ifdef GL_ES  
        varying lowp vec4 v_fragmentColor;
        varying mediump vec2 v_texCoord;
        #else                      
        varying vec4 v_fragmentColor; 
        varying vec2 v_texCoord;  
        #endif    
        void main() 
        {
            gl_Position = CC_PMatrix * a_position; 
            v_fragmentColor = a_color;
            v_texCoord = a_texCoord;
        }
    ]]

    local flagShaderByteArray = [[
        #ifdef GL_ES
        precision mediump float;
        #endif

        varying vec4 v_fragmentColor;
        varying vec2 v_texCoord;

        uniform vec2 resolution;
        uniform float blurRadius;
        uniform float sampleNum;

        vec4 blur(vec2);

        void main(void)
        {
            vec4 col = blur(v_texCoord); //* v_fragmentColor.rgb;
            gl_FragColor = vec4(col) * v_fragmentColor;
        }

        vec4 blur(vec2 p)
        {
            if (blurRadius > 0.0 && sampleNum > 1.0)
            {
                vec4 col = vec4(0);
                vec2 unit = 1.0 / resolution.xy;
                
                float r = blurRadius;
                float sampleStep = r / sampleNum;
                
                float count = 0.0;
                
                for(float x = -r; x < r; x += sampleStep)
                {
                    for(float y = -r; y < r; y += sampleStep)
                    {
                        float weight = (r - abs(x)) * (r - abs(y));
                        col += texture2D(CC_Texture0, p + vec2(x * unit.x, y * unit.y)) * weight;
                        count += weight;
                    }
                }
                
                return col / count;
            }
            
            return texture2D(CC_Texture0, p);
        }
    ]]

    local shader = cc.GLProgram:createWithByteArrays(vertShaderByteArray, flagShaderByteArray)
    local glProgramState = cc.GLProgramState:create(shader)
    glProgramState:setUniformFloat("blurRadius", _blurRadius or 1);
    glProgramState:setUniformFloat("sampleNum", _sampleNum or 2);
    glProgramState:setUniformVec2("resolution", _resolution or cc.p(100, 100));
    _sp:setGLProgram(shader)
    _sp:setGLProgramState(glProgramState)
end

-- 取消spine监听回调
function GD.util_cancelSpineEventHandler(_spineNode)
    if tolua.isnull(_spineNode) then
        return
    end
    _spineNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
    _spineNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
end
