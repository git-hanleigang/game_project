System.register(["cc"], function (_export, _context) {
  "use strict";

  var _cclegacy, __checkObsolete__, __checkObsoleteInNamespace__, _decorator, Component, resources, Sprite, SpriteFrame, _dec, _class, _crd, ccclass, property, symbolNode;

  return {
    setters: [function (_cc) {
      _cclegacy = _cc.cclegacy;
      __checkObsolete__ = _cc.__checkObsolete__;
      __checkObsoleteInNamespace__ = _cc.__checkObsoleteInNamespace__;
      _decorator = _cc._decorator;
      Component = _cc.Component;
      resources = _cc.resources;
      Sprite = _cc.Sprite;
      SpriteFrame = _cc.SpriteFrame;
    }],
    execute: function () {
      _crd = true;

      _cclegacy._RF.push({}, "83f48Q+Kg5E9KVqJQrbCyBD", "symbolNode", undefined);

      __checkObsolete__(['_decorator', 'Component', 'Node', 'resources', 'Sprite', 'SpriteFrame']);

      ({
        ccclass,
        property
      } = _decorator);

      _export("symbolNode", symbolNode = (_dec = ccclass('symbolNode'), _dec(_class = class symbolNode extends Component {
        constructor(...args) {
          super(...args);
          this.symbolType = 0;
          this.sprite = null;
          this.iRow = 0;
          this.iCol = 0;
          this.removePosY = 0;
        }

        init() {
          this.node.addComponent(Sprite);
        }

        start() {
          let aa = 0;
        }

        changeSymbolNode(symbolType) {
          let img = this.node.getComponent(Sprite);
          let path = "symbolRes/" + String(symbolType) + "/spriteFrame";
          resources.load(path, SpriteFrame, (err, spriteFrame) => {
            this.node.getComponent(Sprite).spriteFrame = spriteFrame;
          });
        }

      }) || _class));

      _cclegacy._RF.pop();

      _crd = false;
    }
  };
});
//# sourceMappingURL=c15812889a3797919f559fa8be473e51ecbd5782.js.map