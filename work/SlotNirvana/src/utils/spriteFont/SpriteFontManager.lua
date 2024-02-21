--[[
Author: cxc
Date: 2021-12-07 15:31:46
LastEditTime: 2021-12-07 16:36:47
LastEditors: your name
Description: 自定义字体Node 管理类
FilePath: /SlotNirvana/src/utils/spriteFont/SpriteFontManager.lua
--]]
local CCNumberNodeAtlas = require("utils.spriteFont.CCNumberNodeAtlas")
local CCFntNode = require("utils.spriteFont.CCFntNode")
local SpriteFontManager = class("SpriteFontManager")

function SpriteFontManager:getInstance()
    if not self._instance then
        self._instance = SpriteFontManager.new()
    end
    return self._instance
end

------------------------------ 艺术字转换 ------------------------------
function SpriteFontManager:_createNumbrNodeAtlas(_textAtlas, _frameName, _itemWidth, _itemHeight, _startChar)
    if tolua.type(_textAtlas) ~= "ccui.TextAtlas" then
        printError("type label --> ccui.TextAtlas")
        return
    end

    if not _frameName or not _itemWidth or not _itemHeight or not _startChar then  
        -- cocostudio中看控件自定义数据 propertyStr示例 "spriteFrameName=shuzibiaoqian03.png,itemWidth=17,itemHeight=24,startChar=0"
        local propertyStr = _textAtlas:getComponent("ComExtensionData"):getCustomProperty()
        if _textAtlas["getPropertyStr"] then
            propertyStr = _textAtlas:getPropertyStr()  
        end

        _frameName  = string.match(propertyStr, "spriteFrameName=(.+).png")
        _itemWidth  = string.match(propertyStr, "itemWidth=(%d+)")
        _itemHeight  = string.match(propertyStr, "itemHeight=(%d+)")
        _startChar  = string.match(propertyStr, "startChar=([%w%./])")

        if _frameName then
            _frameName = _frameName .. ".png"
        end

    end

    if _frameName and _itemWidth and _itemHeight and _startChar then
        local node = CCNumberNodeAtlas:create(_frameName, _itemWidth, _itemHeight, _startChar)
        node:setAnchorPoint(_textAtlas:getAnchorPoint())
        node:setString(_textAtlas:getString())
        return node
    end
    
    printError("_createNumbrNodeAtlas---params----", _frameName, _itemWidth, _itemHeight, _startChar)
    return nil
end

--[[
 @description: 将ccui.TextAtlas文本转换为自定义的CCNumberNodeAtlas节点
 @param _textAtlas  ccui.TextAtlas
 @param _frameName  合图中spriteFrameName
 @param _itemWidth  单个字符的宽度
 @param _itemHeight  单个字符的高度
 @param _startChar  字库中开始的字符
 @return 成功 CCNumberNodeAtlas 失败 传入的 TextAtlas
 --]]
function SpriteFontManager:convertTextAlatsToNumbrNodeAtlas(_textAtlas, _frameName, _itemWidth, _itemHeight, _startChar)
    local lb = _textAtlas
    xpcall(
        function()
            lb = self:_createNumbrNodeAtlas(_textAtlas, _frameName, _itemWidth, _itemHeight, _startChar) 
            if lb then
                lb:addTo(_textAtlas:getParent())
                lb:setScale(_textAtlas:getScale())
                lb:setPosition(_textAtlas:getPosition())
                lb:setVisible(_textAtlas:isVisible())
                _textAtlas:setVisible(false)
                return
            end

            lb = _textAtlas
            print("error:can not create custom number node atlas, please check!!!")
        end,
        function()
            print("error:-----convertTextAlatsToNumbrNodeAtlas----------")
            lb = _textAtlas
        end
    )

    return lb 
end

------------------------------ 艺术字转换 ------------------------------


------------------------------ BMFont字转换 ------------------------------
function SpriteFontManager:_createNodeBMFont(_textBMFont, _fontUrl)
    if tolua.type(_textBMFont) ~= "ccui.TextBMFont" then
        printError("type label --> ccui.TextBMFont")
        return
    end

    if not _fontUrl then  
        -- cocostudio中看控件自定义数据 propertyStr示例 "fontUrl=font/whiteball.fnt"
        local propertyStr = _textBMFont:getComponent("ComExtensionData"):getCustomProperty()
        if _textBMFont["getPropertyStr"] then
            propertyStr = _textBMFont:getPropertyStr()  
        end

        _fontUrl  = string.match(propertyStr, "fontUrl=(.+).fnt")
        if _fontUrl then
            _fontUrl = _fontUrl .. ".fnt"
        end

    end

    if _fontUrl then
        local node = CCFntNode:create(_fontUrl)
        node:setAnchorPoint(_textBMFont:getAnchorPoint())
        node:setString(_textBMFont:getString())
        return node
    end
    
    printError("_createNodeBMFont---params----", _fontUrl)
    return nil
end

 --[[
 @description: 将ccui.TextBMFont文本转换为自定义的CCFntNode节点
 @param _textBMFont  ccui.TextBMFont
 @param _fontUrl 字体的路径
 @return 成功 CCFntNode 失败 传入的 TextBMFont
 --]]
function SpriteFontManager:convertTextBMFontToNodeBMFont(_textBMFont, _fontUrl)
    local lb = _textBMFont
    xpcall(
        function()
            lb = self:_createNodeBMFont(_textBMFont, _fontUrl) 
            if lb then
                lb:addTo(_textBMFont:getParent())
                lb:setScale(_textBMFont:getScale())
                lb:setPosition(_textBMFont:getPosition())
                lb:setAnchorPoint(_textBMFont:getAnchorPoint())
                lb:setVisible(_textBMFont:isVisible())
                _textBMFont:setVisible(false)
                return
            end

            lb = _textBMFont
            print("error:can not create custom number node bmfont, please check!!!")
        end,
        function()
            print("error:-----convertTextBMFontToNodeBMFont----------")
            lb = _textBMFont
        end
    )

    return lb 
end
------------------------------ BMFont字转换 ------------------------------

return SpriteFontManager