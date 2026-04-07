import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Math;
import Toybox.Timer;

// --- 1. ENTRY POINT ---
class DecisioninjaApp extends Application.AppBase {
    var binaryMode = 0;      
    var diceCount = 1;       
    var diceType = 6;        

    function initialize() { AppBase.initialize(); }

    function getInitialView() {
        var menu = new WatchUi.Menu2({:title=>"Decisioninja"});
        // Descrizioni generiche come richiesto
        menu.addItem(new WatchUi.MenuItem("Binary", "Pick between two", "id_binary", {:icon => new BinaryIcon()}));
        menu.addItem(new WatchUi.MenuItem("Dice", "Roll the dice", "id_dice", {:icon => new DiceIcon()}));
        menu.addItem(new WatchUi.MenuItem("Pointer", "Random direction", "id_pointer", {:icon => new PointerIcon()}));
        menu.addItem(new WatchUi.MenuItem("Settings", "Configure app", "id_settings", {:icon => new SettingsIcon()}));
        
        return [ menu, new MyMenuDelegate(self) ];
    }

    function getBinLabel() {
        var labels = ["YES / NO", "LEFT / RIGHT", "HEADS / TAILS"];
        return labels[binaryMode];
    }
}

// --- 2. DELEGATE MENU PRINCIPALE ---
class MyMenuDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    function initialize(a) { Menu2InputDelegate.initialize(); app = a; }

    function onSelect(item) {
        var id = item.getId();
        if (id.equals("id_binary")) {
            var bView = new BinaryView(app.binaryMode);
            WatchUi.pushView(bView, new BinaryDelegate(bView), WatchUi.SLIDE_LEFT);
        } else if (id.equals("id_dice")) {
            var dView = new DiceView(app);
            WatchUi.pushView(dView, new DiceDelegate(dView), WatchUi.SLIDE_LEFT);
        } else if (id.equals("id_pointer")) {
            var pView = new PointerView();
            WatchUi.pushView(pView, new PointerDelegate(pView), WatchUi.SLIDE_LEFT);
        } else if (id.equals("id_settings")) {
            var sMenu = new WatchUi.Menu2({:title=>"Settings"});
            // Icona gear applicata a tutte le voci del menu settings
            sMenu.addItem(new WatchUi.MenuItem("Binary Mode", app.getBinLabel(), "set_bin", {:icon => new SettingsIcon()}));
            sMenu.addItem(new WatchUi.MenuItem("Dice Count", app.diceCount.toString() + " Dice", "set_count", {:icon => new SettingsIcon()}));
            sMenu.addItem(new WatchUi.MenuItem("Dice Type", "D" + app.diceType.toString(), "set_type", {:icon => new SettingsIcon()}));
            WatchUi.pushView(sMenu, new SettingsDelegate(app), WatchUi.SLIDE_UP);
        }
    }
    function onBack() { System.exit(); }
}

// --- 3. DELEGATE SETTINGS ---
class SettingsDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    function initialize(a) { Menu2InputDelegate.initialize(); app = a; }

    function onSelect(item) {
        var id = item.getId();
        var subMenu = new WatchUi.Menu2({:title=>item.getLabel()});
        if (id.equals("set_bin")) {
            subMenu.addItem(new WatchUi.MenuItem("YES / NO", "", 0, {:icon => new SettingsIcon()}));
            subMenu.addItem(new WatchUi.MenuItem("LEFT / RIGHT", "", 1, {:icon => new SettingsIcon()}));
            subMenu.addItem(new WatchUi.MenuItem("HEADS / TAILS", "", 2, {:icon => new SettingsIcon()}));
        } else if (id.equals("set_count")) {
            subMenu.addItem(new WatchUi.MenuItem("1 Die", "", 1, {:icon => new SettingsIcon()}));
            subMenu.addItem(new WatchUi.MenuItem("2 Dice", "", 2, {:icon => new SettingsIcon()}));
        } else if (id.equals("set_type")) {
            var types = [4, 6, 8, 10, 12, 20];
            for(var i=0; i<types.size(); i++) {
                subMenu.addItem(new WatchUi.MenuItem("D" + types[i], "", types[i], {:icon => new SettingsIcon()}));
            }
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

// --- 4. VISTA BINARY ---
class BinaryView extends WatchUi.View {
    var resultText = "???";
    var isSpinning = false;
    var myTimer;
    var mode;

    function initialize(m) {
        View.initialize();
        myTimer = new Timer.Timer();
        mode = m;
        generateDecision();
    }

    function generateDecision() {
        isSpinning = true;
        resultText = "---";
        WatchUi.requestUpdate();
        myTimer.start(method(:onTimerEnd), 750, false);
    }

    function onTimerEnd() {
        var rand = Math.rand() % 2;
        if (mode == 0) { resultText = (rand == 0) ? "YES" : "NO"; }
        else if (mode == 1) { resultText = (rand == 0) ? "LEFT" : "RIGHT"; }
        else { resultText = (rand == 0) ? "HEADS" : "TAILS"; }
        isSpinning = false;
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
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, "THINKING...", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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

// --- 5. VISTA DADI ---
class DiceView extends WatchUi.View {
    var diceValues = [0, 0];
    var isSpinning = false;
    var myTimer;
    var app;

    function initialize(a) {
        View.initialize();
        app = a;
        myTimer = new Timer.Timer();
        rollDice();
    }

    function rollDice() {
        isSpinning = true;
        WatchUi.requestUpdate();
        myTimer.start(method(:onTimerEnd), 800, false);
    }

    function onTimerEnd() {
        diceValues[0] = (Math.rand() % app.diceType) + 1;
        diceValues[1] = (Math.rand() % app.diceType) + 1;
        isSpinning = false;
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
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM, "ROLLING...", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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

// --- 6. VISTA PUNTATORE ---
class PointerView extends WatchUi.View {
    var angle = 0;
    var isSpinning = false;
    var myTimer;

    function initialize() {
        View.initialize();
        myTimer = new Timer.Timer();
        spin();
    }

    function spin() {
        isSpinning = true;
        WatchUi.requestUpdate();
        myTimer.start(method(:onTimerEnd), 600, false);
    }

    function onTimerEnd() {
        angle = Math.rand() % 360;
        isSpinning = false;
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
            dc.drawText(cx, cy, Graphics.FONT_MEDIUM, "SCANNING...", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var rad = (angle - 90) * (Math.PI / 180);
            var length = 35; 
            var px = cx + length * Math.cos(rad);
            var py = cy + length * Math.sin(rad);
            var baseWidth = 12;
            var bx1 = cx + baseWidth * Math.cos(rad + Math.PI/2);
            var by1 = cy + baseWidth * Math.sin(rad + Math.PI/2);
            var bx2 = cx + baseWidth * Math.cos(rad - Math.PI/2);
            var by2 = cy + baseWidth * Math.sin(rad - Math.PI/2);

            dc.fillPolygon([[px, py], [bx1, by1], [bx2, by2]]);
            dc.drawText(cx, dc.getHeight() - 35, Graphics.FONT_XTINY, "GPS TO RETRY", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class PointerDelegate extends WatchUi.BehaviorDelegate {
    var view;
    function initialize(v) { BehaviorDelegate.initialize(); view = v; }
    function onSelect() { if (!view.isSpinning) { view.spin(); } return true; }
}

// --- 7. ICONE ---
class BinaryIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); dc.setPenWidth(4);
        var cx = dc.getWidth()/2; var cy = dc.getHeight()/2;
        dc.drawLine(cx, cy + 12, cx, cy); dc.drawLine(cx, cy, cx - 12, cy - 12); dc.drawLine(cx, cy, cx + 12, cy - 12);
    }
}

class DiceIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); dc.setPenWidth(3);
        dc.drawRectangle(dc.getWidth()/2 - 10, dc.getHeight()/2 - 10, 20, 20);
        dc.fillCircle(dc.getWidth()/2, dc.getHeight()/2, 3);
    }
}

class PointerIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); dc.setPenWidth(3);
        dc.drawCircle(dc.getWidth()/2, dc.getHeight()/2, 18);
        dc.fillPolygon([[dc.getWidth()/2, dc.getHeight()/2 - 14], [dc.getWidth()/2 - 5, dc.getHeight()/2], [dc.getWidth()/2 + 5, dc.getHeight()/2]]);
    }
}

class SettingsIcon extends WatchUi.Drawable {
    function initialize() { Drawable.initialize({}); }
    function draw(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); dc.setPenWidth(2);
        var cx = dc.getWidth()/2; var cy = dc.getHeight()/2;
        dc.drawCircle(cx, cy, 10); dc.drawCircle(cx, cy, 3);
        for (var i = 0; i < 8; i++) {
            var ang = i * Math.PI / 4;
            dc.drawLine(cx + 8 * Math.cos(ang), cy + 8 * Math.sin(ang), cx + 12 * Math.cos(ang), cy + 12 * Math.sin(ang));
        }
    }
}