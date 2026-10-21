# GameMaker Flex Panels: Programmer’s Quick Reference

Flex Panels calculate the size and position of a tree of rectangular nodes using Yoga’s flexbox layout rules. The GML Flex Panel API returns layout data; your code uses that data to draw UI or position instances. The separate Room Editor UI Layer workflow can include visual elements.

The GML API arrived in GameMaker 2024.8. UI Layers were introduced in 2024.13. Check the manual for the exact functions and properties supported by your installed runtime.

## Runtime workflow

1. Create a root node and its children with `flexpanel_create_node()` or create nodes and attach them with `flexpanel_node_insert_child()`.
2. Calculate layout for the coordinate space you will use.
3. Read positions with `flexpanel_node_layout_get_position()`.
4. Recalculate after changing styles/tree structure or when the available canvas size changes.
5. Delete nodes when finished; Flex Panel nodes are not garbage-collected automatically.

```gml
// Create event: a full-GUI canvas with an inventory panel anchored bottom-left.
ui_root = flexpanel_create_node({
    width: "100%",
    height: "100%",
    nodes: [
        {
            name: "inventory",
            position: "absolute",
            left: 20,
            bottom: 20,
            width: 400,
            height: 80,
            flexDirection: "row",
            justifyContent: "center",
            alignItems: "center",
            gapColumn: 8,
            padding: 8
        }
    ]
});

var _inventory = flexpanel_node_get_child(ui_root, "inventory");
for (var i = 0; i < 5; ++i) {
    var _slot = flexpanel_create_node({
        name: "slot_" + string(i),
        width: 50,
        height: 50,
        flexGrow: 0,
        flexShrink: 0
    });
    flexpanel_node_insert_child(_inventory, _slot, i);
}

// Layout coordinates here match the Draw GUI coordinate space.
ui_gui_w = display_get_gui_width();
ui_gui_h = display_get_gui_height();
flexpanel_calculate_layout(ui_root, ui_gui_w, ui_gui_h, flexpanel_direction.LTR);
```

Recalculate when the GUI size changes. Also recalculate after changing styles or adding/removing nodes, before reading positions again.

```gml
// Step event
var _w = display_get_gui_width();
var _h = display_get_gui_height();
if (_w != ui_gui_w || _h != ui_gui_h) {
    ui_gui_w = _w;
    ui_gui_h = _h;
    flexpanel_calculate_layout(ui_root, ui_gui_w, ui_gui_h, flexpanel_direction.LTR);
}
```

```gml
// Draw GUI event: render each inventory slot from its calculated rectangle.
var _inventory = flexpanel_node_get_child(ui_root, "inventory");
var _count = flexpanel_node_get_num_children(_inventory);
for (var i = 0; i < _count; ++i) {
    var _slot = flexpanel_node_get_child(_inventory, i);
    var _p = flexpanel_node_layout_get_position(_slot, false); // absolute position
    draw_set_color(c_darkgray);
    draw_rectangle(_p.left, _p.top, _p.left + _p.width, _p.top + _p.height, false);
    draw_set_color(c_white);
    draw_rectangle(_p.left, _p.top, _p.left + _p.width, _p.top + _p.height, true);
}
```

```gml
// Clean Up event
flexpanel_delete_node(ui_root, true); // recursively deletes the tree
```

## Common properties

Properties can be passed in the node struct/JSON or set later with `flexpanel_node_style_set_*` functions. Dimensions and spacing use pixels unless the value is a percentage string such as `"50%"`.

| Need | Properties | Notes |
|---|---|---|
| Size | `width`, `height`, `minWidth`, `maxWidth`, `minHeight`, `maxHeight`, `aspectRatio` | `width`/`height` may be `"auto"`, a number, or percentage. |
| Flow | `flexDirection`, `flexWrap`, `flex`, `flexGrow`, `flexShrink`, `flexBasis` | `row`/`column` select the main axis. |
| Alignment | `justifyContent`, `alignItems`, `alignSelf`, `alignContent` | `justifyContent` aligns on the main axis; `alignItems` on the cross axis. |
| Spacing | `padding`, `paddingLeft`…; `margin`, `marginLeft`…; `gap`, `gapRow`, `gapColumn` | Padding is inside a node; margin is outside it; gap separates children. |
| Position | `position`, `left`, `right`, `top`, `bottom` | `position: "absolute"` removes the node from normal flow. Insets accept numbers or percentages. |
| Layout | `display`, `direction` | `display: "none"` excludes a node from layout. `direction` is `"ltr"` or `"rtl"`. |

See the manual for the accepted values/defaults of each property. Struct/JSON property names are camelCase; styling function names use underscores, e.g. `flexpanel_node_style_set_flex_direction()`.

## Core API

| Function | Purpose |
|---|---|
| `flexpanel_create_node([struct_or_json])` | Create a node/tree. |
| `flexpanel_node_insert_child(parent, child, index)` | Insert a child at a zero-based index. |
| `flexpanel_node_get_child(node, index_or_name)` | Get a direct child by index, or recursively search by name. Returns `undefined` when absent. |
| `flexpanel_node_remove_child(parent, child)` | Detach a child; it does not delete it. |
| `flexpanel_node_remove_all_children(node)` | Detach all children. |
| `flexpanel_calculate_layout(root, width, height, direction, [dirty])` | Calculate the tree against the target canvas. Direction is required: `flexpanel_direction.LTR` or `.RTL`. |
| `flexpanel_node_layout_get_position(node, [relative])` | Read `{left, top, width, height, ...}` after calculation. `false` requests absolute positions. |
| `flexpanel_delete_node(node, [recursive])` | Delete a node; pass `true` to delete descendants too. |
| `flexpanel_node_set_name(node, name)` / `flexpanel_node_get_name(node)` | Set or get a node name. |

## Practical notes

- The dimensions passed to `flexpanel_calculate_layout()` define the root’s layout canvas. Use the same coordinate system when consuming positions: GUI dimensions for Draw GUI, room dimensions for room-space drawing, or the dimensions of a custom UI region.
- Calculate at least once before querying positions; otherwise positions are zero.
- A style or tree change makes prior results stale. Recalculate before using them. Avoid recalculating every frame if nothing changed.
- `flexpanel_node_layout_get_position(node)` returns parent-relative coordinates by default. Pass `false` when drawing/placing against the whole canvas.
- Removing a node only detaches it. Delete detached nodes when they are no longer needed.
- Flex Panels do not provide hit testing, clipping, controls, or custom drawing in the GML API. Use the calculated rectangles to implement those parts.
- For Room Editor UI Layers, use the UI Layer workflow and runtime documentation; do not assume a `layer_get_flexpanel_node()` function exists. The GML node API and editor-authored UI are related layout tools, but their runtime integration is different.

## References

- [GameMaker Manual: Flex Panels](https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Flex_Panels/Flex_Panels.htm)
- [Flex Panel Struct Members](https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Flex_Panels/Flex_Panels_Styling.htm)
- [Flex Panel Functions](https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Flex_Panels/Function_Reference/section_index.htm)
- [GameMaker Manual: UI Layers](https://manual.gamemaker.io/monthly/en/Quick_Start_Guide/UI_Layers.htm)
- [GameMaker 2024.8 release notes](https://releases.gamemaker.io/release-notes/2024/8)
- [GameMaker 2024.14 update notes](https://gamemaker.io/en/blog/release-2024-14)
