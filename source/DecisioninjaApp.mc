import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Math;
import Toybox.Timer;
import Toybox.Attention; 

// --- 1. ENTRY POINT ---
class DecisioninjaApp extends Application.AppBase {
    var binaryMode = 0;      
    var diceCount = 1;       
    var diceType = 6;        
    var vibrationEnabled = true; 

    function initialize() { AppBase.initialize(); }

    function getInitialView() {
        var menu = new WatchUi.Menu2({:title=>"Decisioninja"});
        menu.addItem(new WatchUi.MenuItem("Binary", "Pick between two", "id_binary", {:icon => new BinaryIcon()}));
        menu.addItem(new WatchUi.MenuItem("Dice", "Roll the dice", "id_dice", {:icon => new DiceIcon()}));
        menu.addItem(new WatchUi.MenuItem("Pointer", "Random direction", "id_pointer", {:icon => new PointerIcon()}));
        menu.addItem(new WatchUi.MenuItem("Settings", "Configure app", "id_settings", {:icon => new GearIcon()}));
        return [ menu, new MyMenuDelegate(self) ];
    }

    function getBinLabel() {
        var labels = ["YES / NO", "LEFT / RIGHT", "HEADS / TAILS"];
        return labels[binaryMode];
    }

    function triggerVibe() {
        if (vibrationEnabled && Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 100)]);
        }
    }
}

// --- 2. MAIN MENU DELEGATE ---
class MyMenuDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    function initialize(a) { Menu2InputDelegate.initialize(); app = a; }

    function onSelect(item) {
        var id = item.getId();
        if (id.equals("id_binary")) {
            var bView = new BinaryView(app);
            WatchUi.pushView(bView, new BinaryDelegate(bView), WatchUi.SLIDE_LEFT);
        } else if (id.equals("id_dice")) {
            var dView = new DiceView(app);
            WatchUi.pushView(dView, new DiceDelegate(dView), WatchUi.SLIDE_LEFT);
        } else if (id.equals("id_pointer")) {
            var pView = new PointerView(app);
            WatchUi.pushView(pView, new PointerDelegate(pView), WatchUi.SLIDE_LEFT);
        } else if (id.equals("id_settings")) {
            var sMenu = new WatchUi.Menu2({:title=>"Settings"});
            sMenu.addItem(new WatchUi.MenuItem("Binary Mode", app.getBinLabel(), "set_bin", {:icon => new GearIcon()}));
            sMenu.addItem(new WatchUi.MenuItem("Dice Count", app.diceCount.toString() + " Dice", "set_count", {:icon => new GearIcon()}));
            sMenu.addItem(new WatchUi.MenuItem("Dice Type", "D" + app.diceType.toString(), "set_type", {:icon => new GearIcon()}));
            sMenu.addItem(new WatchUi.ToggleMenuItem("Vibration", {:enabled=>"ON", :disabled=>"OFF"}, "set_vibe", app.vibrationEnabled, {:icon => new GearIcon()}));
            WatchUi.pushView(sMenu, new SettingsDelegate(app), WatchUi.SLIDE_UP);
        }
    }
    function onBack() { System.exit(); }
}

// --- 3. SETTINGS DELEGATE ---
class SettingsDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    function initialize(a) { Menu2InputDelegate.initialize(); app = a; }

    function onSelect(item) {
        var id = item.getId();
        if (id.equals("set_vibe")) {
            if (item instanceof WatchUi.ToggleMenuItem) { app.vibrationEnabled = item.isEnabled(); }
            return;
        }
        var subMenu = new WatchUi.Menu2({:title=>item.getLabel()});
        if (id.equals("set_bin")) {
            subMenu.addItem(new WatchUi.MenuItem("YES / NO", "", 0, {:icon => new GearIcon()}));
            subMenu.addItem(new WatchUi.MenuItem("LEFT / RIGHT", "", 1, {:icon => new GearIcon()}));
            subMenu.addItem(new WatchUi.MenuItem("HEADS / TAILS", "", 2, {:icon => new GearIcon()}));
        } else if (id.equals("set_count")) {
            subMenu.addItem(new WatchUi.MenuItem("1 Die", "", 1, {:icon => new GearIcon()}));
            subMenu.addItem(new WatchUi.MenuItem("2 Dice", "", 2, {:icon => new GearIcon()}));
        } else if (id.equals("set_type")) {
            var types = [4, 6, 8, 10, 12, 20];
            for(var i=0; i<types.size(); i++) { subMenu.addItem(new WatchUi.MenuItem("D" + types[i], "", types[i], {:icon => new GearIcon()})); }
        }
        WatchUi.pushView(subMenu, new ApplySettingsDelegate(app, id, item), WatchUi.SLIDE_LEFT);
    }
}

class ApplySettingsDelegate extends WatchUi.Menu2InputDelegate {
    var app; var type; var settingItem;
    function initialize(a, t, sItem) { Menu2InputDelegate.initialize(); app = a; type = t; settingItem = sItem; }
    function onSelect(item) {
        var val = item.getId();
        if (type.equals("set_bin")) { app.binaryMode = val; settingItem.setSubLabel(app.getBinLabel()); }
        else if (type.equals("set_count")) { app.diceCount = val; settingItem.setSubLabel(val.toString() + " Dice"); }
        else if (type.equals("set_type")) { app.diceType = val; settingItem.setSubLabel("D" + val.toString()); }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

// --- 4. BINARY VIEW ---
class BinaryView extends WatchUi.View {
    var resultText = "???";
    var isSpinning = false;
    var myTimer;
    var app;

    function initialize(a) { View.initialize(); app = a; myTimer = new Timer.Timer(); generateDecision(); }

    function generateDecision() {
        isSpinning = true;
        resultText = "---";
        myTimer.start(method(:onTimerEnd), 1200, false);
        WatchUi.requestUpdate();
    }

    function onTimerEnd() {
        var rand = Math.rand() % 2;
        if (app.binaryMode == 0) { resultText = (rand == 0) ? "YES" : "NO"; }
        else if (app.binaryMode == 1) { resultText = (rand == 0) ? "LEFT" : "RIGHT"; }
        else { resultText = (rand == 0) ? "HEADS" : "TAILS"; }
        isSpinning = false;
        app.triggerVibe();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(242, 38, 28); 
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(242, 38, Graphics.FONT_XTINY, isSpinning ? ".." : "BI", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (isSpinning) {
            var dots = ["", ".", "..", "..."][(System.getTimer() / 250) % 4];
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, "DECIDING" + dots, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            WatchUi.requestUpdate(); // Keeps the animation moving
        } else {
            dc.drawText(dc.getWidth() / 2, 45, Graphics.FONT_XTINY, "DECISION:", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 + 5, Graphics.FONT_NUMBER_THAI_HOT, resultText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() - 35, Graphics.FONT_XTINY, "GPS TO RETRY", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class BinaryDelegate extends WatchUi.BehaviorDelegate {
    var view;
    function initialize(v) { BehaviorDelegate.initialize(); view = v; }
    function onSelect() { if (!view.isSpinning) { view.generateDecision(); } return true; }
}

// --- 5. DICE VIEW ---
class DiceView extends WatchUi.View {
    var diceValues = [0, 0];
    var isSpinning = false;
    var myTimer;
    var app;

    function initialize(a) { View.initialize(); app = a; myTimer = new Timer.Timer(); rollDice(); }

    function rollDice() {
        isSpinning = true;
        WatchUi.requestUpdate();
        myTimer.start(method(:onTimerEnd), 1200, false);
    }

    function onTimerEnd() {
        diceValues[0] = (Math.rand() % app.diceType) + 1;
        diceValues[1] = (Math.rand() % app.diceType) + 1;
        isSpinning = false;
        app.triggerVibe();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(242, 38, 28);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(242, 38, Graphics.FONT_XTINY, "D" + app.diceType, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (isSpinning) {
            var dots = ["", ".", "..", "..."][(System.getTimer() / 250) % 4];
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, "CASTING" + dots, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            WatchUi.requestUpdate();
        } else {
            var cx = dc.getWidth() / 2;
            var cy = dc.getHeight() / 2;
            dc.setPenWidth(3);
            if (app.diceCount == 1) {
                dc.drawRoundedRectangle(cx - 35, cy - 35, 70, 70, 8);
                dc.drawText(cx, cy, Graphics.FONT_NUMBER_THAI_HOT, diceValues[0].toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.drawRoundedRectangle(cx - 55, cy - 40, 50, 50, 5);
                dc.drawText(cx - 30, cy - 15, Graphics.FONT_NUMBER_MEDIUM, diceValues[0].toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.drawRoundedRectangle(cx + 5, cy - 10, 50, 50, 5);
                dc.drawText(cx + 30, cy + 15, Graphics.FONT_NUMBER_MEDIUM, diceValues[1].toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            dc.drawText(dc.getWidth() / 2, dc.getHeight() - 35, Graphics.FONT_XTINY, "GPS TO RETRY", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class DiceDelegate extends WatchUi.BehaviorDelegate {
    var view;
    function initialize(v) { BehaviorDelegate.initialize(); view = v; }
    function onSelect() { if (!view.isSpinning) { view.rollDice(); } return true; }
}

// --- 6. POINTER VIEW ---
class PointerView extends WatchUi.View {
    var angle = 0;
    var isSpinning = false;
    var myTimer;
    var app;

    function initialize(a) { View.initialize(); app = a; myTimer = new Timer.Timer(); spin(); }

    function spin() {
        isSpinning = true;
        WatchUi.requestUpdate();
        myTimer.start(method(:onTimerEnd), 1200, false);
    }

    function onTimerEnd() {
        angle = Math.rand() % 360;
        isSpinning = false;
        app.triggerVibe();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(242, 38, 28); 
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(242, 38, Graphics.FONT_XTINY, "DIR", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        if (isSpinning) {
            var dots = ["", ".", "..", "..."][(System.getTimer() / 250) % 4];
            dc.drawText(cx, cy, Graphics.FONT_MEDIUM, "POINTING" + dots, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            WatchUi.requestUpdate();
        } else {
            var rad = (angle - 90) * (Math.PI / 180);
            var startOffset = 5, shaftLength = 20, headLength = 15, shaftWidth = 6, headWidth = 18;
            var startX = cx + startOffset * Math.cos(rad);
            var startY = cy + startOffset * Math.sin(rad);
            var shaftEndX = cx + (startOffset + shaftLength) * Math.cos(rad);
            var shaftEndY = cy + (startOffset + shaftLength) * Math.sin(rad);
            var tipX = cx + (startOffset + shaftLength + headLength) * Math.cos(rad);
            var tipY = cy + (startOffset + shaftLength + headLength) * Math.sin(rad);

            dc.setPenWidth(shaftWidth);
            dc.drawLine(startX, startY, shaftEndX, shaftEndY);
            var angleOrtho = rad + (Math.PI / 2); 
            var hX1 = shaftEndX + (headWidth / 2) * Math.cos(angleOrtho), hY1 = shaftEndY + (headWidth / 2) * Math.sin(angleOrtho);
            var hX2 = shaftEndX - (headWidth / 2) * Math.cos(angleOrtho), hY2 = shaftEndY - (headWidth / 2) * Math.sin(angleOrtho);
            dc.fillPolygon([[tipX, tipY], [hX1, hY1], [hX2, hY2]]);
            dc.drawText(cx, dc.getHeight() - 35, Graphics.FONT_XTINY, "GPS TO RETRY", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class PointerDelegate extends WatchUi.BehaviorDelegate {
    var view;
    function initialize(v) { BehaviorDelegate.initialize(); view = v; }
    function onSelect() { if (!view.isSpinning) { view.spin(); } return true; }
}

// --- 7. HAND-DRAWN ICONS ---
class BinaryIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); dc.setPenWidth(2);
        var cx = dc.getWidth() / 2; var cy = dc.getHeight() / 2;
        dc.drawLine(cx, cy - 12, cx, cy + 12);
        dc.drawLine(cx - 10, cy + 8, cx - 6, cy - 8); dc.drawLine(cx - 2, cy + 8, cx - 6, cy - 8);
        dc.drawLine(cx + 3, cy - 8, cx + 3, cy + 8);
        dc.drawArc(cx + 3, cy - 4, 4, Graphics.ARC_CLOCKWISE, 90, 270);
    }
}

class DiceIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        var cx = dc.getWidth() / 2; var cy = dc.getHeight() / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cx - 14, cy - 14, 28, 28, 4);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.fillCircle(cx, cy, 3);
        dc.fillCircle(cx - 8, cy - 8, 2); dc.fillCircle(cx + 8, cy + 8, 2);
    }
}

class PointerIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); dc.setPenWidth(3);
        dc.drawCircle(dc.getWidth()/2, dc.getHeight()/2, 16);
        dc.fillPolygon([[dc.getWidth()/2, dc.getHeight()/2 - 12], [dc.getWidth()/2 - 5, dc.getHeight()/2], [dc.getWidth()/2 + 5, dc.getHeight()/2]]);
    }
}

class GearIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var cx = dc.getWidth() / 2, cy = dc.getHeight() / 2, r = 12; 
        dc.fillPolygon([[cx-r/2, cy-r], [cx+r/2, cy-r], [cx+r, cy], [cx+r/2, cy+r], [cx-r/2, cy+r], [cx-r, cy]]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.fillCircle(cx, cy, 4);
    }
}