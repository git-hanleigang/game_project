System.register(["__unresolved_0", "cc", "__unresolved_1", "__unresolved_2"], function (_export, _context) {
  "use strict";

  var _reporterNs, _cclegacy, __checkObsolete__, __checkObsoleteInNamespace__, _decorator, Component, Node, Singleton, symbolNode, _dec, _dec2, _class, _class2, _descriptor, _crd, ccclass, property, reelRoll;

  function _initializerDefineProperty(target, property, descriptor, context) { if (!descriptor) return; Object.defineProperty(target, property, { enumerable: descriptor.enumerable, configurable: descriptor.configurable, writable: descriptor.writable, value: descriptor.initializer ? descriptor.initializer.call(context) : void 0 }); }

  function _applyDecoratedDescriptor(target, property, decorators, descriptor, context) { var desc = {}; Object.keys(descriptor).forEach(function (key) { desc[key] = descriptor[key]; }); desc.enumerable = !!desc.enumerable; desc.configurable = !!desc.configurable; if ('value' in desc || desc.initializer) { desc.writable = true; } desc = decorators.slice().reverse().reduce(function (desc, decorator) { return decorator(target, property, desc) || desc; }, desc); if (context && desc.initializer !== void 0) { desc.value = desc.initializer ? desc.initializer.call(context) : void 0; desc.initializer = undefined; } if (desc.initializer === void 0) { Object.defineProperty(target, property, desc); desc = null; } return desc; }

  function _initializerWarningHelper(descriptor, context) { throw new Error('Decorating class property failed. Please ensure that ' + 'transform-class-properties is enabled and runs after the decorators transform.'); }

  function _reportPossibleCrUseOfSingleton(extras) {
    _reporterNs.report("Singleton", "./Singleton", _context.meta, extras);
  }

  function _reportPossibleCrUseOfsymbolNode(extras) {
    _reporterNs.report("symbolNode", "./symbolNode", _context.meta, extras);
  }

  return {
    setters: [function (_unresolved_) {
      _reporterNs = _unresolved_;
    }, function (_cc) {
      _cclegacy = _cc.cclegacy;
      __checkObsolete__ = _cc.__checkObsolete__;
      __checkObsoleteInNamespace__ = _cc.__checkObsoleteInNamespace__;
      _decorator = _cc._decorator;
      Component = _cc.Component;
      Node = _cc.Node;
    }, function (_unresolved_2) {
      Singleton = _unresolved_2.default;
    }, function (_unresolved_3) {
      symbolNode = _unresolved_3.symbolNode;
    }],
    execute: function () {
      _crd = true;

      _cclegacy._RF.push({}, "858abUChTBNHaP6k9Bvm8dt", "reelRoll", undefined);

      __checkObsolete__(['_decorator', 'Component', 'EditBox', 'Node', 'UITransform']);

      ({
        ccclass,
        property
      } = _decorator);

      _export("reelRoll", reelRoll = (_dec = ccclass('reelRoll'), _dec2 = property(Number), _dec(_class = (_class2 = class reelRoll extends Component {
        constructor() {
          super(...arguments);
          this.singleton = (_crd && Singleton === void 0 ? (_reportPossibleCrUseOfSingleton({
            error: Error()
          }), Singleton) : Singleton).getInstance();
          this.symbolList = [];
          this.currMoveLength = 0;
          this.reelRowNum = 0;
          this.colNum = null;
          // 行配置
          this.rollStates = false;
          this.quickStop = false;
          this.rollSymbolTypes = [];
          this.rollPoint = 0;
          // 滚动指针
          this.rollListLength = null;

          // 滚动指针
          _initializerDefineProperty(this, "curColIndex", _descriptor, this);

          this.symbolHeight = 160;
        }

        start() {
          this.colNum = this.singleton.reelColAndRow.length;
          this.reelRowNum = this.singleton.reelColAndRow[this.curColIndex];
          this.rollSymbolTypes = this.singleton.rollList[this.curColIndex];
          this.rollPoint = 0;
          this.rollListLength = this.rollSymbolTypes.length;
          this.initReel();
        }

        update(deltaTime) {}

        initReel() {
          for (var iRow = 1; iRow < this.reelRowNum; iRow++) {
            var addNode = this.getUnActiveSymbol(iRow);
            var symbolType = this.getSmbolType();

            if (addNode != null) {
              addNode.active = true;
            } else {// addNode = this.cr
            }
          }
        }

        createSymbolNode(symbolType, iRow) {
          var newNode = new Node();
          this.node.addChild(newNode); // let uiTra = newNode.addComponent(UITransform)
          // uiTra.anchorX = 0.5
          // uiTra.anchorY = 0 

          var script = newNode.addComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
            error: Error()
          }), symbolNode) : symbolNode);
          script.init();
          return newNode;
        }

        updateSymbolNodeInfo(node, iRow, symbolType) {
          // node.setSiblingIndex(symbolType)
          var script = node.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
            error: Error()
          }), symbolNode) : symbolNode);
          script.iRow = iRow;
          script.symbolType = symbolType; // script.removePosY = -this.sy
        }

        getSmbolType() {
          var symbolType = this.rollSymbolTypes[this.rollPoint];
          this.rollPoint = this.rollPoint + 1;

          if (this.rollPoint >= this.rollListLength) {
            this.rollPoint = 0;
          }

          return symbolType;
        }

        getUnActiveSymbol(row) {
          var symbolListLength = this.symbolList.length;

          for (var index = 0; index < symbolListLength; index++) {
            var node = this.symbolList[index];

            if (node.active == false) {
              return node;
            }
          }

          return null;
        }

        beginReel() {
          this.currMoveLength = 0;
          this.rollStates = true;
          this.quickStop = false;
        }

        stopReel() {
          this.rollStates = false;
        }

      }, (_descriptor = _applyDecoratedDescriptor(_class2.prototype, "curColIndex", [_dec2], {
        configurable: true,
        enumerable: true,
        writable: true,
        initializer: function initializer() {
          return 0;
        }
      })), _class2)) || _class));

      _cclegacy._RF.pop();

      _crd = false;
    }
  };
});
//# sourceMappingURL=1a91d5ab8a372380da118295ec14708e7a4888df.js.map