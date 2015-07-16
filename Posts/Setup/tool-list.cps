// vim: set ft=javascript:
/**
  Copyright (C) 2015 Greg Jurman.
  Some code segments are (C) 2012-2015 Autodesk Inc.

  Tool sheet configuration.
*/

description = "Tool Sheet (Mustache.JS)";
vendor = "Greg Jurman";
vendorUrl = "http://www.github.com/gregjurman/";
legal = "Copyright (C) 2015 Greg Jurman";
certificationLevel = 2;

capabilities = CAPABILITY_SETUP_SHEET;
extension = "html";
mimetype = "text/html";
setCodePage("utf-8");

allowMachineChangeOnSection = true;


properties = {
  showToolImage: true, // specifies that the tool image should be shown
  showRapidDistance: true,
  rapidFeed: 5000 // the rapid traversal feed
};

var feedFormat = createFormat({decimals:(unit == MM ? 0 : 2)});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3});
var angleFormat = createFormat({decimals:0, scale:DEG});
var pitchFormat = createFormat({decimals:3});

// presentation formats
var spatialFormat = createFormat({decimals:3});
var percentageFormat = createFormat({decimals:1, forceDecimal:true, scale:100});
var timeFormat = createFormat({decimals:2});
var taperFormat = angleFormat; // share format

var zRanges = {};

function formatCycleTime(cycleTime) {
  cycleTime = cycleTime + 0.5; // round up
  var seconds = cycleTime % 60 | 0;
  var minutes = ((cycleTime - seconds)/60 | 0) % 60;
  var hours = (cycleTime - minutes * 60 - seconds)/(60 * 60) | 0;
  if (hours > 0) {
    return subst(localize("%1h:%2m:%3s"), hours, minutes, seconds);
  } else if (minutes > 0) {
    return subst(localize("%1m:%2s"), minutes, seconds);
  } else {
    return subst(localize("%1s"), seconds);
  }
}

function onSection() {
  skipRemainingSection();
}

function onComment(text) {
}

function wrapTool(i, t) {
      var maximumFeed = 0;
      var maximumSpindleSpeed = 0;
      var cuttingDistance = 0;
      var rapidDistance = 0;
      var cycleTime = 0;
      for (var j = 0; j < getNumberOfSections(); ++j) {
        var section = getSection(j);
        if (section.getTool().number == t.number) {
          maximumFeed = Math.max(maximumFeed, section.getMaximumFeedrate());
          maximumSpindleSpeed = Math.max(maximumSpindleSpeed, section.getMaximumSpindleSpeed());
          cuttingDistance += section.getCuttingDistance();
          rapidDistance += section.getRapidDistance();
          cycleTime += section.getCycleTime();
        }
      }
      if (properties.rapidFeed > 0) {
        cycleTime += rapidDistance/properties.rapidFeed * 60;
      }

  return {
    "id": i,
    "number": toolFormat.format(t.number),
    "offset": {
        "diameter": toolFormat.format(t.diameterOffset),
        "length": toolFormat.format(t.lengthOffset)
    },
    "type": getToolTypeName(t.type),
    "diameter": spatialFormat.format(t.diameter),
    "corner_radius": spatialFormat.format(t.cornerRadius),
    "taper": taperFormat.format(t.taperAngle),
    "is_drill": t.isDrill(),
    "length": spatialFormat.format(t.bodyLength),
    "flutes": t.numberOfFlutes,
    "material": getMaterialName(t.material),
    "comment": t.comment,
    "vendor": t.vendor,
    "min_z": spatialFormat.format(zRanges[t.number].getMinimum()),
    "max_feed": feedFormat.format(maximumFeed),
    "max_rpm": rpmFormat.format(maximumSpindleSpeed),
    "cut_dist": spatialFormat.format(cuttingDistance),
    "rapid_dist": spatialFormat.format(rapidDistance),
    "cycle_time": formatCycleTime(cycleTime)
  };
}

function generateToolList() {
  tools = getToolTable();
  ttable = [];
  for (var i = 0; i < tools.getNumberOfTools(); ++i) {
    ttable.push(wrapTool(i, tools.getTool(i)));
  }
  return ttable;
}

function generateToolImage(tool) {
  var toolRenderer = createToolRenderer();
  if (toolRenderer) {
    toolRenderer.setBackgroundColor(new Color(1, 1, 1));
    toolRenderer.setFluteColor(new Color(25.0/255, 25.0/255, 200.0/255));
    toolRenderer.setShoulderColor(new Color(25.0/255, 150.0/255, 25.0/255));
    toolRenderer.setShaftColor(new Color(140.0/255, 140.0/255, 0.0));
  }
  if (toolRenderer && properties.showToolImage) {
        var path = "tool" + tool.number + ".png";
        var width = 100;
        var height = 133;
        toolRenderer.exportAs(path, "image/png", tool, width, height);
        return path;
  }
}

function generateToolImages(t) {
  tools = getToolTable();
  for (var i = 0; i < t.length; i++) {
    t[i]['image'] = generateToolImage(tools.getTool(t[i]['id']));
    //warning(JSON.stringify(t[i]));
  }
}

function onClose() {
  include("mustache.min.js"); // Load mustache.js

  if (is3D()) {
    var numberOfSections = getNumberOfSections();
    for (var i = 0; i < numberOfSections; ++i) {
      var section = getSection(i);
      var zRange = section.getGlobalZRange();
      var tool = section.getTool();
      if (zRanges[tool.number]) {
        zRanges[tool.number].expandToRange(zRange);
      } else {
        zRanges[tool.number] = zRange;
      }
    }
  }

  var template = loadText("template-tool-list.txt", "utf-8");
  var t = generateToolList();
  if (properties.showToolImage) {
    generateToolImages(t);
  }

  write(Mustache.render(template, {'tools': t}));
}
